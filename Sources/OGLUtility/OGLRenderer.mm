//******************************************************************************
//
// OpenGL Utility / OGLRenderer
//
// レンダラクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#include "YNBaseLib.h"
#include "OGLRenderer.h"
#include <new>


//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLRenderer::OGLRenderer()
{
	m_pOGLDevice = NULL;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLRenderer::~OGLRenderer()
{
	Terminate();
}

//******************************************************************************
// 初期化
//******************************************************************************
int OGLRenderer::Initialize(
		NSView* pView,
		OGLRedererParam rendererParam
	)
{
	int result = 0;
	NSRect baseRect;
	OGLVIEWPORT viewPort;
	
	//ディスプレイデバイス作成（ダミー）
	try {
		m_pOGLDevice = new OGLDevice();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//ディスプレイデバイス初期化
	result = m_pOGLDevice->Initialize();
	if (result != 0) goto EXIT;
	
	//ビューポート情報作成
	baseRect = [pView convertRectToBase:[pView bounds]];
	viewPort.originx = baseRect.origin.x;
	viewPort.originy = baseRect.origin.y;
	viewPort.width   = baseRect.size.width;
	viewPort.height  = baseRect.size.height;
	m_pOGLDevice->SetViewPort(viewPort);
	
	//アンチエイリアス有効化
	//  ハードウェアによって無視される場合があるため気休め程度の設定である
	//  アンチエイリアスの有効化はNSView生成時に指定するピクセルフォーマットで確定するようだ
	if (rendererParam.isEnableAntialiasing) {
		glEnable(GL_MULTISAMPLE);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイス取得
//******************************************************************************
OGLDevice* OGLRenderer::GetDevice()
{
	return m_pOGLDevice;
}

//*****************************************************************************
// シーン描画
//******************************************************************************
int OGLRenderer::RenderScene(
		OGLScene* pScene
	)
{
	int result = 0;
	OGLCOLOR bgcolor;
	
	if (pScene == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//バッファ初期化色の指定：RGBA
	bgcolor = pScene->GetBGColor();
	glClearColor(bgcolor.r, bgcolor.g, bgcolor.b, bgcolor.a);
	
	//バッファクリア：色バッファ＋深度バッファ
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	//描画
	result = pScene->Draw(m_pOGLDevice);
	if (result != 0) {
		//失敗しても描画定型処理を続行する
		YN_SHOW_ERR();
	}
	
	//描画処理終了
	//  キューに残っている全てのOpenGLコマンドをハードウェアに送信して制御を戻す
	//  コマンド実行完了まで待機したければglFinishを使う
	glFlush();
	
EXIT:;
	return result;
}

//*****************************************************************************
// 終了処理
//******************************************************************************
void OGLRenderer::Terminate()
{
	if (m_pOGLDevice != NULL) {
		m_pOGLDevice->Release();
		m_pOGLDevice = NULL;
	}
}


