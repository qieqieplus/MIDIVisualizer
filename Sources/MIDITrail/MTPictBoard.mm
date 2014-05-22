//******************************************************************************
//
// MIDITrail / MTPictBoard
//
// ピクチャボード描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MTPictBoard.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTPictBoard::MTPictBoard(void)
{
	m_CurTickTime = 0;
	m_isPlay = false;
	m_isEnable = true;
	m_isClipImage = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTPictBoard::~MTPictBoard(void)
{
	Release();
}

//******************************************************************************
// ピクチャボード生成
//******************************************************************************
int MTPictBoard::Create(
		OGLDevice* pD3DDevice,
		NSString* pSceneName,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	SMBarList barList;
	unsigned long vertexNum = 0;
	unsigned long indexNum = 0;
	MTPICTBOARD_VERTEX* pVertex = NULL;
	unsigned long* pIndex = NULL;
	
	Release();
	
	//ノートデザインオブジェクト初期化
	result = m_NoteDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//テクスチャ読み込み
	result = _LoadTexture(pD3DDevice, pSceneName);
	if (result != 0) goto EXIT;
	
	//プリミティブ初期化
	result = m_Primitive.Initialize(
					sizeof(MTPICTBOARD_VERTEX),	//頂点サイズ
					_GetFVFFormat(),			//頂点FVFフォーマット
					GL_TRIANGLE_STRIP			//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	vertexNum = 4;
	result = m_Primitive.CreateVertexBuffer(pD3DDevice, vertexNum);
	if (result != 0) goto EXIT;
	
	//インデックスバッファ生成
	indexNum = 4;
	result = m_Primitive.CreateIndexBuffer(pD3DDevice, indexNum);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	result = m_Primitive.LockIndex(&pIndex);
	if (result != 0) goto EXIT;
	
	//バッファに頂点とインデックスを書き込む
	result = _CreateVertexOfBoard(
					pVertex,		//頂点バッファ書き込み位置
					pIndex			//インデックスバッファ書き込み位置
				);
	if (result != 0) goto EXIT;
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	result = m_Primitive.UnlockIndex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 移動
//******************************************************************************
int MTPictBoard::Transform(
		OGLDevice* pD3DDevice,
		OGLVECTOR3 camVector,
		float rollAngle
	)
{
	int result = 0;
	float curPos = 0.0f;
	OGLVECTOR3 moveVector;
	OGLTransMatrix transMatrix;
	
	//回転
	transMatrix.RegistRotationX(rollAngle);
	
	//演奏位置
	curPos = m_NoteDesign.GetPlayPosX(m_CurTickTime);
	
	//移動
	moveVector = m_NoteDesign.GetWorldMoveVector();
	transMatrix.RegistTranslation(moveVector.x + curPos, moveVector.y, moveVector.z);
	
	//左手系(DirectX)=>右手系(OpenGL)の変換
	transMatrix.RegistScale(1.0f, 1.0f, LH2RH(1.0f));
	
	//変換行列設定
	m_Primitive.Transform(&transMatrix);
	
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTPictBoard::Draw(
		OGLDevice* pD3DDevice
	)
{
	int result = 0;
	
	if (!m_isEnable) goto EXIT;
	
	//テクスチャステージ設定
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	//  カラー演算：引数1を使用  引数1：テクスチャ
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE);
	// アルファ演算：引数1を使用  引数1：テクスチャ
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_TEXTURE);
	
	//テクスチャフィルタ
	//なし
	
	//描画
	result = m_Primitive.Draw(pD3DDevice, &m_Texture);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTPictBoard::Release()
{
	m_Primitive.Release();
	m_Texture.Release();
}

//******************************************************************************
// ピクチャボード頂点生成
//******************************************************************************
int MTPictBoard::_CreateVertexOfBoard(
		MTPICTBOARD_VERTEX* pVertex,
		unsigned long* pIndex
	)
{
	int result = 0;
	unsigned long i = 0;
	OGLVECTOR3 vectorLU;
	OGLVECTOR3 vectorRU;
	OGLVECTOR3 vectorLD;
	OGLVECTOR3 vectorRD;
	float clipAreaHeight = 0.0f;
	float clipAreaWidth = 0.0f;
	float boardHeight = 0.0f;
	float boardWidth = 0.0f;
	float chStep = 0.0f;
	
	//     +   1+----+3   +
	//    /|   / 上 /    /|gridH    y x
	//   + | 0+----+2   + |右       |/
	// 左| +   7+----+5 | +      z--+0
	//   |/    / 下 /   |/
	//   +   6+----+4   + ← 4 が原点(0,0,0)
	//        gridW
	
	//再生面頂点座標取得
	m_NoteDesign.GetPlaybackSectionVirtexPos(
			0,
			&vectorLU,
			&vectorRU,
			&vectorLD,
			&vectorRD
		);
	
	//テクスチャクリップ領域のサイズ
	clipAreaHeight = m_ClipAreaP2.y - m_ClipAreaP1.y;
	clipAreaWidth = m_ClipAreaP2.x - m_ClipAreaP1.x;
	
	//ボードのサイズ
	boardHeight = vectorLU.y - vectorLD.y;
	if (m_isClipImage) {
		boardWidth = boardHeight * (clipAreaWidth / clipAreaHeight);
	}
	else {
		boardWidth = boardHeight * ((float)m_Texture.GetWidth() / (float)m_Texture.GetHeight());
	}
	chStep = m_NoteDesign.GetChStep();
	
	//頂点座標：左の面
	pVertex[0].p = OGLVECTOR3(vectorLU.x,            vectorLU.y, vectorLU.z+chStep+0.01f); //0
	pVertex[1].p = OGLVECTOR3(vectorLU.x+boardWidth, vectorLU.y, vectorLU.z+chStep+0.01f); //1
	pVertex[2].p = OGLVECTOR3(vectorLD.x,            vectorLD.y, vectorLD.z+chStep+0.01f); //6
	pVertex[3].p = OGLVECTOR3(vectorLD.x+boardWidth, vectorLD.y, vectorLD.z+chStep+0.01f); //7
	
	//再生面との相対位置にずらす
	//  相対位置 0.0f → 画像の左端が再生面と直交する
	//  相対位置 0.5f → 画像の中央が再生面と直交する
	//  相対位置 1.0f → 画像の右端が再生面と直交する
	for (i = 0; i < 4; i++) {
		pVertex[i].p.x += -(boardWidth * m_NoteDesign.GetPictBoardRelativePos());
	}
	
	//法線
	pVertex[0].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	pVertex[1].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	pVertex[2].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	pVertex[3].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	
	//各頂点のディフューズ色
	for (i = 0; i < 4; i++) {
		pVertex[i].c = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
	}
	
	//各頂点のテクスチャ座標
	if (m_isClipImage) {
		//テクスチャ画像の一部（矩形領域）描画する場合
		pVertex[0].t = OGLVECTOR2(m_ClipAreaP1.x,	m_ClipAreaP1.y);  //左上
		pVertex[1].t = OGLVECTOR2(m_ClipAreaP2.x,	m_ClipAreaP1.y);  //右上
		pVertex[2].t = OGLVECTOR2(m_ClipAreaP1.x,	m_ClipAreaP2.y);  //左下
		pVertex[3].t = OGLVECTOR2(m_ClipAreaP2.x,	m_ClipAreaP2.y);  //右下
	}
	else {
		//テクスチャ画像全体を描画する場合
		pVertex[0].t = OGLVECTOR2(0.0f,					0.0f);
		pVertex[1].t = OGLVECTOR2(m_Texture.GetWidth(),	0.0f);
		pVertex[2].t = OGLVECTOR2(0.0f,					m_Texture.GetHeight());
		pVertex[3].t = OGLVECTOR2(m_Texture.GetWidth(),	m_Texture.GetHeight());
	}
	
	//インデックス：TRIANGLESTRIP
	pIndex[0] = 0;
	pIndex[1] = 1;
	pIndex[2] = 2;
	pIndex[3] = 3;
	
	return result;
}

//******************************************************************************
// テクスチャ画像読み込み
//******************************************************************************
int MTPictBoard::_LoadTexture(
		OGLDevice* pD3DDevice,
		NSString* pSceneName
	)
{
	int result = 0;
	NSString* pImgFilePath = nil;
	NSString* pBmpFileName = nil;
	MTConfFile confFile;
	int clipImage = 0;
	
	result = confFile.Initialize(pSceneName);
	if (result != 0) goto EXIT;
	
	//ビットマップファイル名
	result = confFile.SetCurSection(@"Bitmap");
	if (result != 0) goto EXIT;
	result = confFile.GetStr(@"Board", &pBmpFileName, MT_IMGFILE_BOARD);
	if (result != 0) goto EXIT;
	
	//描画対象領域の座標
	//  Mac OS X 10.5.8 + Mac mini (GMA 950) の環境において、任意画像サイズの
	//  テクスチャ処理(GL_TEXTURE_RECTANGLE_EXT)が正常に動作しない。
	//  本来なら 2^n 以外の画像サイズも扱えるはずだが、テクスチャが崩れて描画される。
	//  画像の幅が640pixelなら崩れないという不可解な動作をするので不具合らしい。
	//  この問題を回避するため、余白を付けて描画が崩れないサイズで画像ファイルを作成する。
	//  さらに余白を描画しないように、画像全体ではなく特定の領域だけ描画する処理を追加する。
	//  ここでは領域の座標を設定ファイルから取得する。
	result = confFile.SetCurSection(@"Board");
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"ClipImage", &clipImage, 0.0f);
	if (result != 0) goto EXIT;
	if (clipImage > 0) {
		m_isClipImage = true;
	}
	result = confFile.GetFloat(@"ClipAreaX1", &(m_ClipAreaP1.x), 0.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"ClipAreaY1", &(m_ClipAreaP1.y), 0.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"ClipAreaX2", &(m_ClipAreaP2.x), 0.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"ClipAreaY2", &(m_ClipAreaP2.y), 0.0f);
	if (result != 0) goto EXIT;
	
	//画像ファイルパス
	pImgFilePath = [NSString stringWithFormat:@"%@/%@",
									[YNPathUtil resourceDirPath], pBmpFileName];
	
	//任意画像サイズを有効化
	m_Texture.EnableRectanbleExt(true);
	
	//画像ファイル読み込み
	result = m_Texture.LoadImageFile(pImgFilePath);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// チックタイム設定
//******************************************************************************
void MTPictBoard::SetCurTickTime(
		unsigned long curTickTime
	)
{
	m_CurTickTime = curTickTime;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTPictBoard::Reset()
{
	m_CurTickTime = 0;
}

//******************************************************************************
// 演奏開始
//******************************************************************************
void MTPictBoard::OnPlayStart()
{
	m_isPlay = true;
}

//******************************************************************************
// 演奏終了
//******************************************************************************
void MTPictBoard::OnPlayEnd()
{
	m_isPlay = false;
}

//******************************************************************************
// 表示設定
//******************************************************************************
void MTPictBoard::SetEnable(
		bool isEnable
	)
{
	m_isEnable = isEnable;
}


