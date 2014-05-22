//******************************************************************************
//
// MIDITrail / MTSceneTitle
//
// タイトルシーン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTSceneTitle.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTSceneTitle::MTSceneTitle(void)
{
	m_CamPosZ = MTSCENETITLE_CAMERA_POSZ;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTSceneTitle::~MTSceneTitle(void)
{
}

//******************************************************************************
// 名称取得
//******************************************************************************
NSString* MTSceneTitle::GetName()
{
	return @"Title";
}

//******************************************************************************
// シーン生成
//******************************************************************************
int MTSceneTitle::Create(
		NSView* pView,
		OGLDevice* pOGLDevice,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	
	Release();
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//----------------------------------
	// カメラ
	//----------------------------------
	//カメラ初期化
	result = m_Camera.Initialize();
	if (result != 0) goto EXIT;
	
	//基本パラメータ設定
	m_Camera.SetBaseParam(
			45.0f,		//画角
			1.0f,		//Nearプレーン
			1000.0f		//Farプレーン
		);
	
	//カメラ位置設定
	m_Camera.SetPosition(
			OGLVECTOR3(0.0f, 0.0f, LH2RH(m_CamPosZ)),	//カメラ位置
			OGLVECTOR3(0.0f, 0.0f, LH2RH(0.0f)), 		//注目点
			OGLVECTOR3(0.0f, 1.0f, LH2RH(0.0f))		//カメラ上方向
		);
	
	//----------------------------------
	// ライト
	//----------------------------------
	//ライト初期化
	result = m_DirLight.Initialize();
	if (result != 0) goto EXIT;
	
	//ライト方向
	//  原点を光源としてその方向をベクトルで表現する
	m_DirLight.SetDirection(OGLVECTOR3(1.0f, -1.0f, LH2RH(2.0f)));
	
	//ライトのデバイス登録
	result = m_DirLight.SetDevice(pOGLDevice, false); //ライトなし
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// 描画オブジェクト
	//----------------------------------
	//ロゴ生成
	result = m_Logo.Create(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// レンダリングステート
	//----------------------------------
	//画面描画モード
	glDisable(GL_CULL_FACE);
	
	//Z深度比較：ON
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);  //判定方式をDirectXと同一にする
	
	//ディザリング:ON 高品質描画
	glEnable(GL_DITHER);
	
	//マルチサンプリングアンチエイリアス：有効
	//TODO: 設定必要？
	
	//レンダリングステート設定：通常のアルファ合成
	glDisable(GL_ALPHA_TEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	//シェーディングモデル：フラットシェーディング
	glShadeModel(GL_FLAT);  // or GL_SMOOTH
	
EXIT:;
	return result;
}

//******************************************************************************
// 変換処理
//******************************************************************************
int MTSceneTitle::Transform(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//カメラ位置設定
	m_CamPosZ += MTSCENETITLE_CAMERA_POSZ_DELTA;
	m_Camera.SetPosition(
			OGLVECTOR3(0.0f, 0.0f, LH2RH(m_CamPosZ)),	//カメラ位置
			OGLVECTOR3(0.0f, 0.0f, LH2RH(0.0f)), 		//注目点
			OGLVECTOR3(0.0f, 1.0f, LH2RH(0.0f))			//カメラ上方向
		);
	
	//カメラ更新
	result = m_Camera.Transform(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ロゴ更新
	result = m_Logo.Transform(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTSceneTitle::Draw(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//更新
	result = Transform(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ロゴ描画
	result = m_Logo.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 破棄
//******************************************************************************
void MTSceneTitle::Release()
{
	m_Logo.Release();
}


