//******************************************************************************
//
// MIDITrail / MTDynamicCaption
//
// 動的キャプション描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTDynamicCaption.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTDynamicCaption::MTDynamicCaption(void)
{
	m_Chars[0] = '\0';
	m_CaptionSize = 0;
	m_Color = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTDynamicCaption::~MTDynamicCaption(void)
{
	Release();
}

//******************************************************************************
// フォントタイル生成
//******************************************************************************
int MTDynamicCaption::Create(
		OGLDevice* pOGLDevice,
		NSString* pFontName,
		float fontSize,
		const char* pCharacters,
		unsigned long captionSize
   )
{
	int result = 0;
	
	Release();
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	if ((pFontName == NULL) || (fontSize == 0)) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	if ((pCharacters == NULL) ||(captionSize == 0)) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	m_CaptionSize = captionSize;
	
	//テクスチャ生成
	result = _CreateTexture(pOGLDevice, pFontName, fontSize, pCharacters);
	if (result != 0) goto EXIT;
	
	//タイルの頂点を生成する
	result = _CreateVertex(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// テクスチャサイズ取得
//******************************************************************************
void MTDynamicCaption::GetTextureSize(
		unsigned long* pHeight,
		unsigned long* pWidth
	)
{
	m_FontTexture.GetTextureSize(pHeight, pWidth);
}

//******************************************************************************
// 文字列設定
//******************************************************************************
int MTDynamicCaption::SetString(
		char* pStr
	)
{
	int result = 0;
	unsigned long i = 0;
	OGLVECTOR2 v0, v1, v2, v3;
	MTDYNAMICCAPTION_VERTEX* pVertex = NULL;
	
	if (pStr == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	for (i= 0; i < 6*m_CaptionSize; i++) {
		pVertex[i].t = OGLVECTOR2(0.0f, 0.0f);
	}
	for (i= 0; i < m_CaptionSize; i++) {
		if (pStr[i] == '\0') break;
		
		result = _GetTextureUV(pStr[i], &v0, &v1, &v2, &v3);
		if (result != 0) goto EXIT;
		
		// 0+--+1
		//  | /|
		//  |/ |
		// 2+--+3
		pVertex[6*i+0].t = v0;
		pVertex[6*i+1].t = v1;
		pVertex[6*i+2].t = v2;
		pVertex[6*i+3].t = v2;
		pVertex[6*i+4].t = v1;
		pVertex[6*i+5].t = v3;
	}
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 文字列設定
//******************************************************************************
void MTDynamicCaption::SetColor(
		OGLCOLOR color
	)
{
	m_Color = color;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTDynamicCaption::Draw(
		OGLDevice* pOGLDevice,
		float x,
		float y,
		float magRate
	)
{
	int result = 0;
	MTDYNAMICCAPTION_VERTEX* pVertex = NULL;
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
void MTDynamicCaption::Release()
{
	m_Primitive.Release();
	m_FontTexture.Clear();
}

//******************************************************************************
// テクスチャ生成
//******************************************************************************
int MTDynamicCaption::_CreateTexture(
		OGLDevice* pOGLDevice,
		NSString* pFontName,
		float fontSize,
		const char* pCharacters
	)
{
	int result = 0;
	OGLCOLOR color = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
	bool isForceFixedPitch = true;
	NSString* pStr = nil;
	
	//タイル文字一覧を格納
	if ((strlen(pCharacters)+1) > MTDYNAMICCAPTION_MAX_CHARS) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	strcpy(m_Chars, pCharacters);
	
	//フォント設定：固定ピッチ強制
	result = m_FontTexture.SetFont(pFontName, fontSize, color, isForceFixedPitch);
	if (result != 0) goto EXIT;
	
	//タイル文字一覧テクスチャ作成
	pStr = [NSString stringWithCString:pCharacters encoding:NSASCIIStringEncoding];
	result = m_FontTexture.CreateTexture(pOGLDevice, pStr);
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// フォントタイル頂点生成
//******************************************************************************
int MTDynamicCaption::_CreateVertex(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long i = 0;
	MTDYNAMICCAPTION_VERTEX* pVertex = NULL;
	
	//プリミティブ初期化
	result = m_Primitive.Initialize(
					sizeof(MTDYNAMICCAPTION_VERTEX),	//頂点サイズ
					_GetFVFFormat(),		//頂点FVFフォーマット
					GL_TRIANGLES			//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	result = m_Primitive.CreateVertexBuffer(pOGLDevice, 6*m_CaptionSize);
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
	
	for (i = 0; i < 6*m_CaptionSize; i++) {
		//各頂点のディフューズ色
		pVertex[i].c = m_Color;
		//各頂点のテクスチャ座標
		pVertex[i].t = OGLVECTOR2(0.0f, 0.0f);
	}
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// テクスチャUV座標取得
//******************************************************************************
int MTDynamicCaption::_GetTextureUV(
		char target,
		OGLVECTOR2* pV0,
		OGLVECTOR2* pV1,
		OGLVECTOR2* pV2,
		OGLVECTOR2* pV3
	)
{
	int result = 0;
	bool isFound = false;
	unsigned long i = 0;
	unsigned long charsNum = 0;
	float fontNo = 0;
	float fontWidth = 0.0f;
	
	charsNum = strlen(m_Chars);
	for (i = 0; i < charsNum; i++) {
		if (m_Chars[i] == target) {
			isFound = true;
			fontNo = (float)i;
			break;
		}
	}
	
	fontWidth = 1.0f / (float)charsNum;
	
	//見つかった場合は該当する文字のUV座標を設定
	if (isFound) {
		//左上
		pV0->x = 1.0f * fontNo / (float)charsNum;
		pV0->y = 0.0f;
		//右上
		pV1->x = 1.0f * (fontNo + 1.0f) / (float)charsNum;
		pV1->y = 0.0f;
		//左下
		pV2->x = 1.0f * fontNo / (float)charsNum;
		pV2->y = 1.0f;
		//右下
		pV3->x = 1.0f * (fontNo + 1.0f) / (float)charsNum;
		pV3->y = 1.0f;
	}
	//見つからない場合はテクスチャ無効とする
	else {
		//左上
		pV0->x = 0.0f;
		pV0->y = 0.0f;
		//右上
		pV1->x = 0.0f;
		pV1->y = 0.0f;
		//左下
		pV2->x = 0.0f;
		pV2->y = 0.0f;
		//右下
		pV3->x = 0.0f;
		pV3->y = 0.0f;
	}
	
	return result;
}

//******************************************************************************
// 頂点位置設定
//******************************************************************************
void MTDynamicCaption::_SetVertexPosition(
		MTDYNAMICCAPTION_VERTEX* pVertex,
		float x,
		float y,
		float magRate
	)
{
	unsigned long i = 0;
	unsigned long texHeight = 0;
	unsigned long texWidth = 0;
	unsigned long charsNum = 0;
	float height = 0.0f;
	float width = 0.0f;
	
	charsNum = strlen(m_Chars);
	
	//描画サイズ
	m_FontTexture.GetTextureSize(&texHeight, &texWidth);
	height = texHeight * magRate;
	width  = ((float)texWidth / (float)charsNum) * magRate;
	
	//頂点座標
	for (i = 0; i < m_CaptionSize; i++) {
		pVertex[i*6+0].p = OGLVECTOR3(width * (i     ), 0.0f,   0.0f);
		pVertex[i*6+1].p = OGLVECTOR3(width * (i+1.0f), 0.0f,   0.0f);
		pVertex[i*6+2].p = OGLVECTOR3(width * (i     ), height, 0.0f);
		pVertex[i*6+3].p = pVertex[i*6+2].p;
		pVertex[i*6+4].p = pVertex[i*6+1].p;
		pVertex[i*6+5].p = OGLVECTOR3(width * (i+1.0f), height, 0.0f);
	}
	
	//描画位置に移動
	for (i = 0; i < 6*m_CaptionSize; i++) {
		pVertex[i].p.x += x;
		pVertex[i].p.y += y;
	}
	
	return;
}

//******************************************************************************
// 頂点色設定
//******************************************************************************
void MTDynamicCaption::_SetVertexColor(
		MTDYNAMICCAPTION_VERTEX* pVertex,
		OGLCOLOR color
	)
{
	unsigned long i = 0;
	
	for (i = 0; i < 6*m_CaptionSize; i++) {
		pVertex[i].c = color;
	}
	
	return;
}


