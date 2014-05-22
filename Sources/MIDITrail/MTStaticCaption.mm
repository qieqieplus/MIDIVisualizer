//******************************************************************************
//
// MIDITrail / MTStaticCaption
//
// 静的キャプション描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTStaticCaption.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTStaticCaption::MTStaticCaption(void)
{
	m_Color = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTStaticCaption::~MTStaticCaption(void)
{
	Release();
}

//******************************************************************************
// 静的キャプション生成
//******************************************************************************
int MTStaticCaption::Create(
		OGLDevice* pOGLDevice,
		NSString* pFontName,
		float fontSize,
		NSString* pCaption
   )
{
	int result = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	if ((pFontName == NULL) || (fontSize == 0) || (pCaption == NULL)) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	Release();
	
	//テクスチャ生成
	result = _CreateTexture(pOGLDevice, pFontName, fontSize, pCaption);
	if (result != 0) goto EXIT;
	
	//頂点を生成する
	result = _CreateVertex(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// テクスチャサイズ取得
//******************************************************************************
void MTStaticCaption::GetTextureSize(
		unsigned long* pHeight,
		unsigned long* pWidth
	)
{
	m_FontTexture.GetTextureSize(pHeight, pWidth);
}

//******************************************************************************
// 文字列設定
//******************************************************************************
void MTStaticCaption::SetColor(
		OGLCOLOR color
	)
{
	m_Color = color;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTStaticCaption::Draw(
		OGLDevice* pOGLDevice,
		float x,
		float y,
		float magRate
	)
{
	int result = 0;
	MTSTATICCAPTION_VERTEX* pVertex = NULL;
	OGLVIEWPORT viewPort;
	GLint depthFunc = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	//頂点座標設定
	_SetVertexPosition(
			pVertex,	//頂点座標配列
			x,			//描画位置x
			y,			//描画位置y
			magRate		//拡大率
		);
	
	//頂点色設定
	_SetVertexColor(pVertex, m_Color);
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
	//テクスチャステージ設定
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	//  カラー演算：引数1を使用  引数1：ポリゴン
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PRIMARY_COLOR);
	// アルファ演算：引数1を使用  引数1：テクスチャ
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_TEXTURE);
	
	//テクスチャフィルタ
	//なし
	
	//レンダリングパイプラインにマテリアルを設定
	//なし
	
	//正射影
	pOGLDevice->GetViewPort(&viewPort);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0, viewPort.width, viewPort.height, 0);
	
	//深度テストを無効化
	glGetIntegerv(GL_DEPTH_FUNC, &depthFunc);
	glDepthFunc(GL_ALWAYS);
	
	//全ボード描画
	result = m_Primitive.Draw(pOGLDevice, m_FontTexture.GetTexture());
	if (result != 0) goto EXIT;
	
	//深度テストを戻す
	glDepthFunc(depthFunc);
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTStaticCaption::Release()
{
	m_Primitive.Release();
	m_FontTexture.Clear();
}

//******************************************************************************
// テクスチャ生成
//******************************************************************************
int MTStaticCaption::_CreateTexture(
		OGLDevice* pOGLDevice,
		NSString* pFontName,
		float fontSize,
		NSString* pCaption
	)
{
	int result = 0;
	bool isForceFixedPitch = false;
	OGLCOLOR color = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
	
	//フォント設定：固定ピッチ強制
	result = m_FontTexture.SetFont(pFontName, fontSize, color, isForceFixedPitch);
	if (result != 0) goto EXIT;
	
	//タイル文字一覧テクスチャ作成
	result = m_FontTexture.CreateTexture(pOGLDevice, pCaption);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点生成
//******************************************************************************
int MTStaticCaption::_CreateVertex(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long i = 0;
	MTSTATICCAPTION_VERTEX* pVertex = NULL;
	
	//プリミティブ初期化
	result = m_Primitive.Initialize(
					sizeof(MTSTATICCAPTION_VERTEX),	//頂点サイズ
					_GetFVFFormat(),		//頂点FVFフォーマット
					GL_TRIANGLE_STRIP			//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	result = m_Primitive.CreateVertexBuffer(pOGLDevice, 4);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	//頂点座標設定
	_SetVertexPosition(
			pVertex,	//頂点座標配列
			0.0f,		//描画位置x
			0.0f,		//描画位置y
			1.0f		//拡大率
		);
	
	for (i = 0; i < 4; i++) {
		//各頂点のディフューズ色
		pVertex[i].c = m_Color;
	}
	
	//テクスチャ座標
	pVertex[0].t = OGLVECTOR2(0.0f, 0.0f);
	pVertex[1].t = OGLVECTOR2(1.0f, 0.0f);
	pVertex[2].t = OGLVECTOR2(0.0f, 1.0f);
	pVertex[3].t = OGLVECTOR2(1.0f, 1.0f);
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点位置設定
//******************************************************************************
void MTStaticCaption::_SetVertexPosition(
		MTSTATICCAPTION_VERTEX* pVertex,
		float x,
		float y,
		float magRate
	)
{
	unsigned long i = 0;
	unsigned long texHeight = 0;
	unsigned long texWidth = 0;
	float height = 0.0f;
	float width = 0.0f;
	
	//描画サイズ
	m_FontTexture.GetTextureSize(&texHeight, &texWidth);
	height = (float)texHeight * magRate;
	width  = (float)texWidth  * magRate;
	
	//頂点座標
	pVertex[0].p = OGLVECTOR3(0.0f , 0.0f,   0.0f);
	pVertex[1].p = OGLVECTOR3(width, 0.0f,   0.0f);
	pVertex[2].p = OGLVECTOR3(0.0f , height, 0.0f);
	pVertex[3].p = OGLVECTOR3(width, height, 0.0f);
	
	//描画位置に移動
	for (i = 0; i < 4; i++) {
		pVertex[i].p.x += x;
		pVertex[i].p.y += y;
	}
	
	return;
}

//******************************************************************************
// 頂点色設定
//******************************************************************************
void MTStaticCaption::_SetVertexColor(
		MTSTATICCAPTION_VERTEX* pVertex,
		OGLCOLOR color
	)
{
	unsigned long i = 0;
	
	for (i = 0; i < 4; i++) {
		pVertex[i].c = color;
	}
	
	return;
}


