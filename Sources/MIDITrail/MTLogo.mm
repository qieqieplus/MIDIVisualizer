//******************************************************************************
//
// MIDITrail / MTLogo
//
// MIDITrail ロゴ描画クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// ポリゴンをタイル状に並べてロゴのテクスチャを貼り付ける。
// ポリゴンの色をタイルごとに更新することでロゴをグラデーションさせる。
//
//   +-++-++-++-+
//   |/||/||/||/|...
//   +-++-++-++-+
//
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTLogo.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTLogo::MTLogo(void)
{
	m_pVertex = NULL;
	m_StartTime = 0;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTLogo::~MTLogo(void)
{
	Release();
}

//******************************************************************************
// シーン生成
//******************************************************************************
int MTLogo::Create(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	Release();
	
	//テクスチャ生成
	result = _CreateTexture(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//頂点生成
	result = _CreateVertex(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//Mach時間初期化
	result = m_MachTime.Initialize();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 変換処理
//******************************************************************************
int MTLogo::Transform(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	OGLTransMatrix transMatrix;
	
	//タイトルグラデーション設定
	_SetGradationColor();
	
	//左手系(DirectX)=>右手系(OpenGL)の変換
	transMatrix.RegistScale(1.0f, 1.0f, LH2RH(1.0f));
	
	//変換行列設定
	m_Primitive.Transform(&transMatrix);
	
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTLogo::Draw(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
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
	
	//タイトル文字描画
	result = m_Primitive.Draw(pOGLDevice, m_FontTexture.GetTexture());
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 破棄
//******************************************************************************
void MTLogo::Release()
{
	m_Primitive.Release();
	m_FontTexture.Clear();
}

//******************************************************************************
// テクスチャ生成
//******************************************************************************
int MTLogo::_CreateTexture(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	OGLCOLOR color = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
	bool isForceFixedPitch = false;
	
	//フォント設定
	result = m_FontTexture.SetFont(
					MTLOGO_FONTNAME,	//フォント名称
					MTLOGO_FONTSIZE,	//フォントサイズ
					color,				//色
					isForceFixedPitch	//固定ピッチ強制
				);
	if (result != 0) goto EXIT;
	
	//タイル文字一覧テクスチャ作成
	result = m_FontTexture.CreateTexture(pOGLDevice, MTLOGO_TITLE);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// フォントタイル頂点生成
//******************************************************************************
int MTLogo::_CreateVertex(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long i = 0;
	MTLOGO_VERTEX* pVertex = NULL;
	
	//プリミティブ初期化
	result = m_Primitive.Initialize(
					sizeof(MTLOGO_VERTEX),	//頂点サイズ
					_GetFVFFormat(),		//頂点FVFフォーマット
					GL_TRIANGLES			//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	result = m_Primitive.CreateVertexBuffer(pOGLDevice, 6*MTLOGO_TILE_NUM);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	//頂点座標設定
	_SetVertexPosition(
			pVertex,		//頂点座標配列
			MTLOGO_POS_X,	//描画位置x
			MTLOGO_POS_Y,	//描画位置y
			MTLOGO_MAG		//拡大率
		);
	
	for (i = 0; i < 6*MTLOGO_TILE_NUM; i++) {
		//各頂点のディフューズ色
		pVertex[i].c = OGLCOLOR(0.0f, 0.0f, 0.0f, 1.0f); //R,G,B,A
	}
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点位置設定
//******************************************************************************
void MTLogo::_SetVertexPosition(
		MTLOGO_VERTEX* pVertex,
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
	float tileNo = 0.0f;
	
	//タイルサイズ
	m_FontTexture.GetTextureSize(&texHeight, &texWidth);
	height = texHeight * magRate;
	width  = ((float)texWidth / (float)MTLOGO_TILE_NUM) * magRate;
	
	//頂点座標：XY平面の(0, 0)を左上とする
	for (i = 0; i < MTLOGO_TILE_NUM; i++) {
		//頂点座標
		pVertex[i*6+0].p = OGLVECTOR3(width * (i     ),  0.0f,   0.0f);
		pVertex[i*6+1].p = OGLVECTOR3(width * (i+1.0f),  0.0f,   0.0f);
		pVertex[i*6+2].p = OGLVECTOR3(width * (i     ), -height, 0.0f);
		pVertex[i*6+3].p = pVertex[i*6+2].p;
		pVertex[i*6+4].p = pVertex[i*6+1].p;
		pVertex[i*6+5].p = OGLVECTOR3(width * (i+1.0f), -height, 0.0f);
		
		//テクスチャ座標
		//左上
		pVertex[i*6+0].t.x = 1.0f * tileNo / (float)MTLOGO_TILE_NUM;
		pVertex[i*6+0].t.y = 0.0f;
		//右上
		pVertex[i*6+1].t.x = 1.0f * (tileNo + 1.0f) / (float)MTLOGO_TILE_NUM;
		pVertex[i*6+1].t.y = 0.0f;
		//左下
		pVertex[i*6+2].t.x = 1.0f * tileNo / (float)MTLOGO_TILE_NUM;
		pVertex[i*6+2].t.y = 1.0f;
		//左下
		pVertex[i*6+3].t = pVertex[i*6+2].t;
		//右上
		pVertex[i*6+4].t = pVertex[i*6+1].t;
		//右下
		pVertex[i*6+5].t.x = 1.0f * (tileNo + 1.0f) / (float)MTLOGO_TILE_NUM;
		pVertex[i*6+5].t.y = 1.0f;
		
		tileNo += 1.0f;
	}
	
	//法線
	for (i = 0; i < 6*MTLOGO_TILE_NUM; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	}
	
	//指定位置に移動
	for (i = 0; i < 6*MTLOGO_TILE_NUM; i++) {
		pVertex[i].p.x += x;
		pVertex[i].p.y += y;
	}
	
	return;
}

//******************************************************************************
// グラデーション設定
//******************************************************************************
void MTLogo::_SetGradationColor()
{
	int result = 0;
	unsigned long i = 0;
	unsigned long sceneTime = 0;
	unsigned long delay = 0;
	unsigned long tileTime = 0;
	float color = 0.0f;
	MTLOGO_VERTEX* pVertex = NULL;
	MTLOGO_VERTEX* pVertexTarget = NULL;
	
	//シーン経過時間
	if (m_StartTime == 0) {
		m_StartTime = m_MachTime.GetCurTimeInMsec();
	}
	sceneTime = (unsigned long)(m_MachTime.GetCurTimeInMsec() - m_StartTime);
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	//グラデーション処理
	for (i = 0; i < MTLOGO_TILE_NUM; i++) {
		
		//タイルごとの遅延時間
		delay = i * (MTLOGO_GRADATION_TIME / MTLOGO_TILE_NUM);
		
		//タイルにとっての経過時間
		if (sceneTime < delay) {
			tileTime = 0;
		}
		else {
			tileTime = sceneTime - delay;
		}
		
		//タイルの色
		if (tileTime < MTLOGO_GRADATION_TIME) {
			//黒→白
			color = (float)tileTime / (float)MTLOGO_GRADATION_TIME;
		}
		else if (tileTime < (MTLOGO_GRADATION_TIME*2)) {
			//白→黒
			color = 1.0f - ((float)(tileTime - MTLOGO_GRADATION_TIME) / (float)MTLOGO_GRADATION_TIME);
		}
		else {
			//黒
			color = 0.0f;
		}
		
		//タイルの色を頂点に設定
		pVertexTarget = pVertex + (6*i);
		_SetTileColor(pVertexTarget, color);
	}
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return;
}

//******************************************************************************
// タイル色設定
//******************************************************************************
void MTLogo::_SetTileColor(
		MTLOGO_VERTEX* pVertex,
		float color
	)
{
	unsigned long i = 0;
	
	for (i = 0; i < 6; i++) {
		pVertex[i].c = OGLCOLOR(color, color, color, 1.0f); //R,G,B,A
	}
}


