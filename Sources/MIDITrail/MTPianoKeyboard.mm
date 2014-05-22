//******************************************************************************
//
// MIDITrail / MTPianoKeyboard
//
// ピアノキーボード描画クラス
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
#import "MTPianoKeyboard.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//各キーの頂点数
#define MTPIANOKEYBOARD_KEY_WHITE_1_VERTEX_NUM  (38)
#define MTPIANOKEYBOARD_KEY_WHITE_2_VERTEX_NUM  (44)
#define MTPIANOKEYBOARD_KEY_WHITE_3_VERTEX_NUM  (38)
#define MTPIANOKEYBOARD_KEY_BLACK_VERTEX_NUM    (30)
#define MTPIANOKEYBOARD_KEY_VERTEX_NUM_MAX      MTPIANOKEYBOARD_KEY_WHITE_2_VERTEX_NUM

//各キーのインデックス数
#define MTPIANOKEYBOARD_KEY_WHITE_1_INDEX_NUM   (60)
#define MTPIANOKEYBOARD_KEY_WHITE_2_INDEX_NUM   (66)
#define MTPIANOKEYBOARD_KEY_WHITE_3_INDEX_NUM   (60)
#define MTPIANOKEYBOARD_KEY_BLACK_INDEX_NUM     (48)
#define MTPIANOKEYBOARD_KEY_INDEX_NUM_MAX       MTPIANOKEYBOARD_KEY_WHITE_2_INDEX_NUM

//******************************************************************************
// コンストラクタ
//******************************************************************************
MTPianoKeyboard::MTPianoKeyboard(void)
{
	m_pTexture = NULL;
	m_isTextureOwner = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTPianoKeyboard::~MTPianoKeyboard(void)
{
	Release();
}

//******************************************************************************
// 生成処理
//******************************************************************************
int MTPianoKeyboard::Create(
		OGLDevice* pOGLDevice,
		NSString* pSceneName,
		SMSeqData* pSeqData,
		OGLTexture* pTexture
	)
{
	int result = 0;
	SMTrack track;
	
	Release();
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//キーボードデザイン初期化
	result = m_KeyboardDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//テクスチャ読み込み
	if (pTexture == NULL) {
		result = _LoadTexture(pOGLDevice, pSceneName);
		if (result != 0) goto EXIT;
	}
	else {
		m_pTexture = pTexture;
	}
	
	//キーボード生成
	result = _CreateKeyboard(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// キーボード生成
//******************************************************************************
int MTPianoKeyboard::_CreateKeyboard(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	
	//バッファ情報生成
	_CreateBufInfo();
	
	//キーボード頂点生成
	result = _CreateVertexOfKeyboard(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// バッファ情報生成
//******************************************************************************
void MTPianoKeyboard::_CreateBufInfo()
{
	unsigned char noteNo = 0;
	unsigned long vertexNum = 0;
	unsigned long indexNum = 0;
	unsigned long vertexPos = 0;
	unsigned long indexPos = 0;
	
	memset(&(m_BufInfo[0]), 0, sizeof(MTBufInfo) * SM_MAX_NOTE_NUM);
	
	vertexPos = 0;
	indexPos = 0;
	
	//各キーの頂点数／インデックス数／登録位置を生成する
	for (noteNo = 0; noteNo < SM_MAX_NOTE_NUM; noteNo++) {
		switch (m_KeyboardDesign.GetKeyType(noteNo)) {
			case (MTPianoKeyboardDesign::KeyWhiteC):
			case (MTPianoKeyboardDesign::KeyWhiteF):
				vertexNum = MTPIANOKEYBOARD_KEY_WHITE_1_VERTEX_NUM;
				indexNum  = MTPIANOKEYBOARD_KEY_WHITE_1_INDEX_NUM;
				break;
			case (MTPianoKeyboardDesign::KeyWhiteD):
			case (MTPianoKeyboardDesign::KeyWhiteG):
			case (MTPianoKeyboardDesign::KeyWhiteA):
				vertexNum = MTPIANOKEYBOARD_KEY_WHITE_2_VERTEX_NUM;
				indexNum  = MTPIANOKEYBOARD_KEY_WHITE_2_INDEX_NUM;
				break;
			case (MTPianoKeyboardDesign::KeyWhiteE):
			case (MTPianoKeyboardDesign::KeyWhiteB):
				vertexNum = MTPIANOKEYBOARD_KEY_WHITE_3_VERTEX_NUM;
				indexNum  = MTPIANOKEYBOARD_KEY_WHITE_3_INDEX_NUM;
				break;
			case (MTPianoKeyboardDesign::KeyBlack):
				vertexNum = MTPIANOKEYBOARD_KEY_BLACK_VERTEX_NUM;
				indexNum  = MTPIANOKEYBOARD_KEY_BLACK_INDEX_NUM;
				break;
		}
		m_BufInfo[noteNo].vertexNum = vertexNum;
		m_BufInfo[noteNo].indexNum  = indexNum;
		m_BufInfo[noteNo].vertexPos = vertexPos;
		m_BufInfo[noteNo].indexPos  = indexPos;
		vertexPos += vertexNum;
		indexPos  += indexNum;
	}
	
	return;
}

//******************************************************************************
// キーボード頂点生成
//******************************************************************************
int MTPianoKeyboard::_CreateVertexOfKeyboard(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	unsigned long vertexNum = 0;
	unsigned long indexNum = 0;
	unsigned char noteNo = 0;
	OGLMATERIAL material;
	
	//プリミティブ初期化
	result = m_PrimitiveKeyboard.Initialize(
					sizeof(MTPIANOKEYBOARD_VERTEX),	//頂点サイズ
					_GetFVFFormat(),				//頂点FVFフォーマット
					GL_TRIANGLES					//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点とインデックスの総数
	vertexNum = 0;
	indexNum = 0;
	for (noteNo = 0; noteNo < SM_MAX_NOTE_NUM; noteNo++) {
		vertexNum += m_BufInfo[noteNo].vertexNum;
		indexNum  += m_BufInfo[noteNo].indexNum;
	}
	
	//頂点バッファ生成
	result = m_PrimitiveKeyboard.CreateVertexBuffer(pOGLDevice, vertexNum);
	if (result != 0) goto EXIT;
	
	//インデックスバッファ生成
	result = m_PrimitiveKeyboard.CreateIndexBuffer(pOGLDevice, indexNum);
	if (result != 0) goto EXIT;
	
	//バッファに頂点とインデックスを書き込む
	for (noteNo = 0; noteNo < SM_MAX_NOTE_NUM; noteNo++) {
		result = _CreateVertexOfKey(noteNo);
		if (result != 0) goto EXIT;
	}
	
	//表示範囲外のキーを隠す
	for (noteNo = 0; noteNo < SM_MAX_NOTE_NUM; noteNo++) {
		if (!(m_KeyboardDesign.IsKeyDisp(noteNo))) {
			result = _HideKey(noteNo);
			if (result != 0) goto EXIT;
		}
	}
	
	//マテリアル作成
	_MakeMaterial(&material);
	m_PrimitiveKeyboard.SetMaterial(material);
	
EXIT:;
	return result;
}

//******************************************************************************
// キーボード頂点生成
//******************************************************************************
int MTPianoKeyboard::_CreateVertexOfKey(
		unsigned char noteNo
   )
{
	int result = 0;
	MTPIANOKEYBOARD_VERTEX* pVertex = NULL;
	unsigned long* pIndex = NULL;
	unsigned long offset = 0;
	unsigned long size = 0;
	
	if (noteNo >= SM_MAX_NOTE_NUM) {
		result = YN_SET_ERR(@"Program error.", noteNo, 0);
		goto EXIT;
	}
	
	//頂点バッファのロック
	offset = m_BufInfo[noteNo].vertexPos * sizeof(MTPIANOKEYBOARD_VERTEX);
	size   = m_BufInfo[noteNo].vertexNum * sizeof(MTPIANOKEYBOARD_VERTEX);
	result = m_PrimitiveKeyboard.LockVertex((void**)&pVertex, offset, size);
	if (result != 0) goto EXIT;
	
	memset(pVertex, 0, size);
	
	//インデックスバッファのロック
	offset = m_BufInfo[noteNo].indexPos * sizeof(unsigned long);
	size   = m_BufInfo[noteNo].indexNum * sizeof(unsigned long);
	result = m_PrimitiveKeyboard.LockIndex(&pIndex, offset, size);
	if (result != 0) goto EXIT;
	
	memset(pIndex, 0, size);
	
	//頂点生成
	switch (m_KeyboardDesign.GetKeyType(noteNo)) {
		case (MTPianoKeyboardDesign::KeyWhiteC):
		case (MTPianoKeyboardDesign::KeyWhiteF):
			result = _CreateVertexOfKeyWhite1(noteNo, pVertex, pIndex);
			if (result != 0) goto EXIT;
			break;
		case (MTPianoKeyboardDesign::KeyWhiteD):
		case (MTPianoKeyboardDesign::KeyWhiteG):
		case (MTPianoKeyboardDesign::KeyWhiteA):
			result = _CreateVertexOfKeyWhite2(noteNo, pVertex, pIndex);
			if (result != 0) goto EXIT;
			break;
		case (MTPianoKeyboardDesign::KeyWhiteE):
		case (MTPianoKeyboardDesign::KeyWhiteB):
			result = _CreateVertexOfKeyWhite3(noteNo, pVertex, pIndex);
			if (result != 0) goto EXIT;
			break;
		case (MTPianoKeyboardDesign::KeyBlack):
			result = _CreateVertexOfKeyBlack(noteNo, pVertex, pIndex);
			if (result != 0) goto EXIT;
			break;
	}
	
	//頂点バッファのロック解除
	result = m_PrimitiveKeyboard.UnlockVertex();
	if (result != 0) goto EXIT;
	
	//インデックスバッファのロック解除
	result = m_PrimitiveKeyboard.UnlockIndex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// キーボード頂点生成：白鍵A
//******************************************************************************
int MTPianoKeyboard::_CreateVertexOfKeyWhite1(
		unsigned char noteNo,
		MTPIANOKEYBOARD_VERTEX* pVertex,
		unsigned long* pIndex,
		OGLCOLOR* pColor
	)
{
	int result = 0;
	unsigned long i = 0;
	float centerX       = m_KeyboardDesign.GetKeyCenterPosX(noteNo);
	float heightY       = m_KeyboardDesign.GetWhiteKeyHeight();
	float whiteKeyWidth = m_KeyboardDesign.GetWhiteKeyWidth();
	float whiteKeyLen   = m_KeyboardDesign.GetWhiteKeyLen();
	float blackKeyWidth = m_KeyboardDesign.GetBlackKeyWidth();
	float blackKeyLen   = m_KeyboardDesign.GetBlackKeyLen();
	float deltaKeyLen   = whiteKeyLen - blackKeyLen;
	float spc           = m_KeyboardDesign.GetKeySpaceSize();
	float nextCenterX   = m_KeyboardDesign.GetKeyCenterPosX(noteNo+1);
	OGLCOLOR keyColor;
	OGLVECTOR2 t0, t1, t2, t3, t4, t5, t6, t7, tsc;
	
	//白鍵カラー
	if (pColor == NULL) {
		keyColor = m_KeyboardDesign.GetWhiteKeyColor();
	}
	else {
		keyColor = *pColor;
	}
	
	//----------------------------------------------------------------
	//上の面
	//----------------------------------------------------------------
	// 6+--+5
	//  |  |
	//  |  |
	//  |  |4
	// 3+--+--+2
	//  |     |   +z
	//  |     |    |
	//  |     |    |
	// 0+-----+1   +---> +x
	//     |
	//    posX
	
	//頂点
	pVertex[0].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, 0.0f);
	pVertex[1].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, 0.0f);
	pVertex[2].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, deltaKeyLen - spc);
	pVertex[3].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, deltaKeyLen - spc);
	pVertex[4].p = OGLVECTOR3(nextCenterX - (blackKeyWidth/2.0f) - spc, heightY, deltaKeyLen - spc);
	pVertex[5].p = OGLVECTOR3(nextCenterX - (blackKeyWidth/2.0f) - spc, heightY, whiteKeyLen);
	pVertex[6].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, whiteKeyLen);
	
	if (m_KeyboardDesign.GetKeyDispRangeEnd() == noteNo) {
		pVertex[4].p = pVertex[2].p;
		pVertex[5].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f), heightY, whiteKeyLen);
	}
	
	//法線／色
	for (i = 0; i < 7; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexUP[] = { 0, 2, 1, 0, 3, 2, 3, 5, 4, 3, 6, 5 };
	for (i = 0; i < 12; i++) {
		pIndex[i] = m_BufInfo[noteNo].vertexPos + indexUP[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetWhiteKeyTexturePosTop(noteNo, &t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7);
	pVertex[0].t = t0;
	pVertex[1].t = t1;
	pVertex[2].t = t2;
	pVertex[3].t = t3;
	pVertex[4].t = t4;
	pVertex[5].t = t5;
	pVertex[6].t = t6;
	
	//----------------------------------------------------------------
	//側面 0-1
	//----------------------------------------------------------------
	// 0      1
	// 7+----+8
	//  |    |
	// 9+----+10
	
	//頂点
	pVertex[7].p  = pVertex[0].p;
	pVertex[8].p  = pVertex[1].p;
	pVertex[9].p  = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z); // 0'
	pVertex[10].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z); // 1'
	
	//法線／色
	for (i = 7; i < 11; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index01[] = { 7, 8, 9, 8, 10, 9 };
	for (i = 0; i < 6; i++) {
		pIndex[12 + i] = m_BufInfo[noteNo].vertexPos + index01[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetWhiteKeyTexturePosFront(noteNo, &t0, &t1, &t2, &t3);
	pVertex[7].t  = t0;
	pVertex[8].t  = t1;
	pVertex[9].t  = t2;
	pVertex[10].t = t3;
	
	//----------------------------------------------------------------
	//側面 1-2
	//----------------------------------------------------------------
	// 2 12+--+14
	//     |  |
	//     |  |
	// 1 11+--+13
	
	//頂点
	pVertex[11].p = pVertex[1].p;
	pVertex[12].p = pVertex[2].p;
	pVertex[13].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z);  // 1'
	pVertex[14].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	
	//法線／色
	for (i = 11; i < 15; i++) {
		pVertex[i].n = OGLVECTOR3(1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index12[] = { 11, 12, 13, 12, 14, 13 };
	for (i = 0; i < 6; i++) {
		pIndex[18 + i] = m_BufInfo[noteNo].vertexPos + index12[i];
	}
	
	//----------------------------------------------------------------
	//側面 2-4
	//----------------------------------------------------------------
	//   18+--+17
	//     |  |
	// 4 16+--+15 2
	
	//頂点
	pVertex[15].p = pVertex[2].p;
	pVertex[16].p = pVertex[4].p;
	pVertex[17].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	pVertex[18].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	
	//法線／色
	for (i = 15; i < 19; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index24[] = { 15, 16, 17, 16, 18, 17 };
	for (i = 0; i < 6; i++) {
		pIndex[24 + i] = m_BufInfo[noteNo].vertexPos + index24[i];
	}
	
	//----------------------------------------------------------------
	//側面 4-5
	//----------------------------------------------------------------
	// 5 20+--+22
	//     |  |
	//     |  |
	// 4 19+--+21
	
	//頂点
	pVertex[19].p = pVertex[4].p;
	pVertex[20].p = pVertex[5].p;
	pVertex[21].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	pVertex[22].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	
	//法線／色
	for (i = 19; i < 23; i++) {
		pVertex[i].n = OGLVECTOR3(1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index45[] = { 19, 20, 21, 20, 22, 21 };
	for (i = 0; i < 6; i++) {
		pIndex[30 + i] = m_BufInfo[noteNo].vertexPos + index45[i];
	}
	
	//----------------------------------------------------------------
	//側面 5-6
	//----------------------------------------------------------------
	//   26+--+25
	//     |  |
	// 6 24+--+23 5
	
	//頂点
	pVertex[23].p = pVertex[5].p;
	pVertex[24].p = pVertex[6].p;
	pVertex[25].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[26].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	
	//法線／色
	for (i = 23; i < 27; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index56[] = { 23, 24, 25, 24, 26, 25 };
	for (i = 0; i < 6; i++) {
		pIndex[36 + i] = m_BufInfo[noteNo].vertexPos + index56[i];
	}
	
	//----------------------------------------------------------------
	//側面 6-0
	//----------------------------------------------------------------
	// 29+--+27 6
	//   |  |
	//   |  |
	// 30+--+28 0
	
	//頂点
	pVertex[27].p = pVertex[6].p;
	pVertex[28].p = pVertex[0].p;
	pVertex[29].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	pVertex[30].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z);  // 0'
	
	//法線／色
	for (i = 27; i < 31; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index60[] = { 27, 28, 29, 28, 30, 29 };
	for (i = 0; i < 6; i++) {
		pIndex[42 + i] = m_BufInfo[noteNo].vertexPos + index60[i];
	}
	
	//----------------------------------------------------------------
	//下の面
	//----------------------------------------------------------------
	//  37 6+--+5 36
	//      |  |
	//      |  |
	//      |  |4 35
	//  34 3+--+--+2 33
	//      |     |     +z
	//      |     |      |
	//      |     |      |
	//  31 0+-----+1 32  +---> +x
	//         |
	//        posX
	
	//頂点
	pVertex[31].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z);  // 0'
	pVertex[32].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z);  // 1'
	pVertex[33].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	pVertex[34].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	pVertex[35].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	pVertex[36].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[37].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	
	//法線／色
	for (i = 31; i < 38; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, -1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexDW[] = { 31, 32, 33, 31, 33, 34, 34, 35, 36, 34, 36, 37 };
	for (i = 0; i < 12; i++) {
		pIndex[48 + i] = m_BufInfo[noteNo].vertexPos + indexDW[i];
	}
	
	//----------------------------------------------------------------
	//単一色のテクスチャ座標
	//----------------------------------------------------------------
	m_KeyboardDesign.GetWhiteKeyTexturePosSingleColor(noteNo, &tsc);
	for (i = 11; i < 38; i++) {
		pVertex[i].t = tsc;
	}
	
	return result;
}

//******************************************************************************
// キーボード頂点生成：白鍵B
//******************************************************************************
int MTPianoKeyboard::_CreateVertexOfKeyWhite2(
		unsigned char noteNo,
		MTPIANOKEYBOARD_VERTEX* pVertex,
		unsigned long* pIndex,
		OGLCOLOR* pColor
	)
{
	int result = 0;
	unsigned long i = 0;
	float centerX       = m_KeyboardDesign.GetKeyCenterPosX(noteNo);
	float heightY       = m_KeyboardDesign.GetWhiteKeyHeight();
	float whiteKeyWidth = m_KeyboardDesign.GetWhiteKeyWidth();
	float whiteKeyLen   = m_KeyboardDesign.GetWhiteKeyLen();
	float blackKeyWidth = m_KeyboardDesign.GetBlackKeyWidth();
	float blackKeyLen   = m_KeyboardDesign.GetBlackKeyLen();
	float deltaKeyLen   = whiteKeyLen - blackKeyLen;
	float spc           = m_KeyboardDesign.GetKeySpaceSize();
	float prevCenterX   = m_KeyboardDesign.GetKeyCenterPosX(noteNo-1);
	float nextCenterX   = m_KeyboardDesign.GetKeyCenterPosX(noteNo+1);
	OGLCOLOR keyColor;
	OGLVECTOR2 t0, t1, t2, t3, t4, t5, t6, t7, tsc;
	
	//白鍵カラー
	if (pColor == NULL) {
		keyColor = m_KeyboardDesign.GetWhiteKeyColor();
	}
	else {
		keyColor = *pColor;
	}
	
	//----------------------------------------------------------------
	//上の面
	//----------------------------------------------------------------
	//   6+-+5
	//    | |
	//    | |
	//   7| |4
	// 3+-+-+-+2
	//  |     |   +z
	//  |     |    |
	//  |     |    |
	// 0+-----+1   +---> +x
	//     |
	//    posX
	
	//頂点
	pVertex[0].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, 0.0f);
	pVertex[1].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, 0.0f);
	pVertex[2].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, deltaKeyLen - spc);
	pVertex[3].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, deltaKeyLen - spc);
	pVertex[4].p = OGLVECTOR3(nextCenterX - (blackKeyWidth/2.0f) - spc, heightY, deltaKeyLen - spc);
	pVertex[5].p = OGLVECTOR3(nextCenterX - (blackKeyWidth/2.0f) - spc, heightY, whiteKeyLen);
	pVertex[6].p = OGLVECTOR3(prevCenterX + (blackKeyWidth/2.0f) + spc, heightY, whiteKeyLen);
	pVertex[7].p = OGLVECTOR3(prevCenterX + (blackKeyWidth/2.0f) + spc, heightY, deltaKeyLen - spc);
	
	if (m_KeyboardDesign.GetKeyDispRangeStart() == noteNo) {
		pVertex[7].p = pVertex[3].p;
		pVertex[6].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f), heightY, whiteKeyLen);
	}
	if (m_KeyboardDesign.GetKeyDispRangeEnd() == noteNo) {
		pVertex[4].p = pVertex[2].p;
		pVertex[5].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f), heightY, whiteKeyLen);
	}
	
	//法線／色
	for (i = 0; i < 8; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexUP[] = { 0, 2, 1, 0, 3, 2, 7, 5, 4, 7, 6, 5 };
	for (i = 0; i < 12; i++) {
		pIndex[i] = m_BufInfo[noteNo].vertexPos + indexUP[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetWhiteKeyTexturePosTop(noteNo, &t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7);
	pVertex[0].t = t0;
	pVertex[1].t = t1;
	pVertex[2].t = t2;
	pVertex[3].t = t3;
	pVertex[4].t = t4;
	pVertex[5].t = t5;
	pVertex[6].t = t6;
	pVertex[7].t = t7;
	
	//----------------------------------------------------------------
	//側面 0-1
	//----------------------------------------------------------------
	//  0      1
	//  8+----+9
	//   |    |
	// 10+----+11
	
	//頂点
	pVertex[8].p  = pVertex[0].p;
	pVertex[9].p  = pVertex[1].p;
	pVertex[10].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z); // 0'
	pVertex[11].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z); // 1'
	
	//法線／色
	for (i = 8; i < 12; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index01[] = { 8, 9, 10, 9, 11, 10 };
	for (i = 0; i < 6; i++) {
		pIndex[12 + i] = m_BufInfo[noteNo].vertexPos + index01[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetWhiteKeyTexturePosFront(noteNo, &t0, &t1, &t2, &t3);
	pVertex[8].t  = t0;
	pVertex[9].t  = t1;
	pVertex[10].t = t2;
	pVertex[11].t = t3;
	
	//----------------------------------------------------------------
	//側面 1-2
	//----------------------------------------------------------------
	// 2 13+--+15
	//     |  |
	//     |  |
	// 1 12+--+14
	
	//頂点
	pVertex[12].p = pVertex[1].p;
	pVertex[13].p = pVertex[2].p;
	pVertex[14].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z);  // 1'
	pVertex[15].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	
	//法線／色
	for (i = 12; i < 16; i++) {
		pVertex[i].n = OGLVECTOR3(1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index12[] = { 12, 13, 14, 13, 15, 14 };
	for (i = 0; i < 6; i++) {
		pIndex[18 + i] = m_BufInfo[noteNo].vertexPos + index12[i];
	}
	
	//----------------------------------------------------------------
	//側面 2-3
	//----------------------------------------------------------------
	//   19+--+18
	//     |  |
	// 3 17+--+16 2
	
	//頂点
	pVertex[16].p = pVertex[2].p;
	pVertex[17].p = pVertex[3].p;
	pVertex[18].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	pVertex[19].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	
	//法線／色
	for (i = 16; i < 20; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index24[] = { 16, 17, 18, 17, 19, 18 };
	for (i = 0; i < 6; i++) {
		pIndex[24 + i] = m_BufInfo[noteNo].vertexPos + index24[i];
	}
	
	//----------------------------------------------------------------
	//側面 4-5
	//----------------------------------------------------------------
	// 5 21+--+23
	//     |  |
	//     |  |
	// 4 20+--+22
	
	//頂点
	pVertex[20].p = pVertex[4].p;
	pVertex[21].p = pVertex[5].p;
	pVertex[22].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	pVertex[23].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	
	//法線／色
	for (i = 20; i < 24; i++) {
		pVertex[i].n = OGLVECTOR3(1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index45[] = { 20, 21, 22, 21, 23, 22 };
	for (i = 0; i < 6; i++) {
		pIndex[30 + i] = m_BufInfo[noteNo].vertexPos + index45[i];
	}
	
	//----------------------------------------------------------------
	//側面 5-6
	//----------------------------------------------------------------
	//   27+--+26
	//     |  |
	// 6 25+--+24 5
	
	//頂点
	pVertex[24].p = pVertex[5].p;
	pVertex[25].p = pVertex[6].p;
	pVertex[26].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[27].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	
	//法線／色
	for (i = 24; i < 28; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index56[] = { 24, 25, 26, 25, 27, 26 };
	for (i = 0; i < 6; i++) {
		pIndex[36 + i] = m_BufInfo[noteNo].vertexPos + index56[i];
	}
	
	//----------------------------------------------------------------
	//側面 6-7
	//----------------------------------------------------------------
	// 30+--+28 6
	//   |  |
	//   |  |
	// 31+--+29 7
	
	//頂点
	pVertex[28].p = pVertex[6].p;
	pVertex[29].p = pVertex[7].p;
	pVertex[30].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	pVertex[31].p = OGLVECTOR3(pVertex[7].p.x, 0.0f, pVertex[7].p.z);  // 7'
	
	//法線／色
	for (i = 28; i < 32; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index67[] = { 28, 29, 30, 29, 31, 30 };
	for (i = 0; i < 6; i++) {
		pIndex[42 + i] = m_BufInfo[noteNo].vertexPos + index67[i];
	}
	
	//----------------------------------------------------------------
	//側面 3-0
	//----------------------------------------------------------------
	// 34+--+32 3
	//   |  |
	//   |  |
	// 35+--+33 0
	
	//頂点
	pVertex[32].p = pVertex[3].p;
	pVertex[33].p = pVertex[0].p;
	pVertex[34].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	pVertex[35].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z);  // 0'
	
	//法線／色
	for (i = 32; i < 36; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index30[] = { 32, 33, 34, 33, 35, 34 };
	for (i = 0; i < 6; i++) {
		pIndex[48 + i] = m_BufInfo[noteNo].vertexPos + index30[i];
	}
	
	//----------------------------------------------------------------
	//下の面
	//----------------------------------------------------------------
	//   42 6+-+5 41
	//       | |
	//       | |
	//   43 7| |4 40
	// 39 3+-+-+-+2 38
	//     |     |     +z
	//     |     |      |
	//     |     |      |
	// 36 0+-----+1 37  +---> +x
	//        |
	//       posX
	
	//頂点
	pVertex[36].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z);  // 0'
	pVertex[37].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z);  // 1'
	pVertex[38].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	pVertex[39].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	pVertex[40].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	pVertex[41].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[42].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	pVertex[43].p = OGLVECTOR3(pVertex[7].p.x, 0.0f, pVertex[7].p.z);  // 7'
	
	//法線／色
	for (i = 36; i < 44; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, -1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexDW[] = { 36, 37, 38, 36, 38, 39, 43, 40, 41, 43, 41, 42 };
	for (i = 0; i < 12; i++) {
		pIndex[54 + i] = m_BufInfo[noteNo].vertexPos + indexDW[i];
	}
	
	//----------------------------------------------------------------
	//単一色のテクスチャ座標
	//----------------------------------------------------------------
	m_KeyboardDesign.GetWhiteKeyTexturePosSingleColor(noteNo, &tsc);
	for (i = 12; i < 44; i++) {
		pVertex[i].t = tsc;
	}
	
	return result;
}

//******************************************************************************
// キーボード頂点生成：白鍵C
//******************************************************************************
int MTPianoKeyboard::_CreateVertexOfKeyWhite3(
		unsigned char noteNo,
		MTPIANOKEYBOARD_VERTEX* pVertex,
		unsigned long* pIndex,
		OGLCOLOR* pColor
	)
{
	int result = 0;
	unsigned long i = 0;
	float centerX       = m_KeyboardDesign.GetKeyCenterPosX(noteNo);
	float heightY       = m_KeyboardDesign.GetWhiteKeyHeight();
	float whiteKeyWidth = m_KeyboardDesign.GetWhiteKeyWidth();
	float whiteKeyLen   = m_KeyboardDesign.GetWhiteKeyLen();
	float blackKeyWidth = m_KeyboardDesign.GetBlackKeyWidth();
	float blackKeyLen   = m_KeyboardDesign.GetBlackKeyLen();
	float deltaKeyLen   = whiteKeyLen - blackKeyLen;
	float spc           = m_KeyboardDesign.GetKeySpaceSize();
	float prevCenterX   = m_KeyboardDesign.GetKeyCenterPosX(noteNo-1);
	OGLCOLOR keyColor;
	OGLVECTOR2 t0, t1, t2, t3, t4, t5, t6, t7, tsc;
	
	//白鍵カラー
	if (pColor == NULL) {
		keyColor = m_KeyboardDesign.GetWhiteKeyColor();
	}
	else {
		keyColor = *pColor;
	}
	
	//----------------------------------------------------------------
	//上の面
	//----------------------------------------------------------------
	//    5+--+4
	//     |  |
	//     |  |
	//    6|  |
	// 3+--+--+2
	//  |     |   +z
	//  |     |    |
	//  |     |    |
	// 0+-----+1   +---> +x
	//     |
	//    posX
	
	//頂点
	pVertex[0].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, 0.0f);
	pVertex[1].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, 0.0f);
	pVertex[2].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, deltaKeyLen - spc);
	pVertex[3].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f),           heightY, deltaKeyLen - spc);
	pVertex[4].p = OGLVECTOR3(centerX + (whiteKeyWidth/2.0f),           heightY, whiteKeyLen);
	pVertex[5].p = OGLVECTOR3(prevCenterX + (blackKeyWidth/2.0f) + spc, heightY, whiteKeyLen);
	pVertex[6].p = OGLVECTOR3(prevCenterX + (blackKeyWidth/2.0f) + spc, heightY, deltaKeyLen - spc);
	
	if (m_KeyboardDesign.GetKeyDispRangeStart() == noteNo) {
		pVertex[5].p = OGLVECTOR3(centerX - (whiteKeyWidth/2.0f), heightY, whiteKeyLen);
		pVertex[6].p = pVertex[3].p;
	}
	
	//法線／色
	for (i = 0; i < 7; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexUP[] = { 0, 2, 1, 0, 3, 2, 2, 6, 4, 6, 5, 4 };
	for (i = 0; i < 12; i++) {
		pIndex[i] = m_BufInfo[noteNo].vertexPos + indexUP[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetWhiteKeyTexturePosTop(noteNo, &t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7);
	pVertex[0].t = t0;
	pVertex[1].t = t1;
	pVertex[2].t = t2;
	pVertex[3].t = t3;
	pVertex[4].t = t5;
	pVertex[5].t = t6;
	pVertex[6].t = t7;
	
	//----------------------------------------------------------------
	//側面 0-1
	//----------------------------------------------------------------
	// 0      1
	// 7+----+8
	//  |    |
	// 9+----+10
	
	//頂点
	pVertex[7].p  = pVertex[0].p;
	pVertex[8].p  = pVertex[1].p;
	pVertex[9].p  = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z); // 0'
	pVertex[10].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z); // 1'
	
	//法線／色
	for (i = 7; i < 11; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index01[] = { 7, 8, 9, 8, 10, 9 };
	for (i = 0; i < 6; i++) {
		pIndex[12 + i] = m_BufInfo[noteNo].vertexPos + index01[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetWhiteKeyTexturePosFront(noteNo, &t0, &t1, &t2, &t3);
	pVertex[7].t  = t0;
	pVertex[8].t  = t1;
	pVertex[9].t  = t2;
	pVertex[10].t = t3;
	
	//----------------------------------------------------------------
	//側面 1-4
	//----------------------------------------------------------------
	// 4 12+--+14
	//     |  |
	//     |  |
	// 1 11+--+13
	
	//頂点
	pVertex[11].p = pVertex[1].p;
	pVertex[12].p = pVertex[4].p;
	pVertex[13].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z);  // 1'
	pVertex[14].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	
	//法線／色
	for (i = 11; i < 15; i++) {
		pVertex[i].n = OGLVECTOR3(1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index14[] = { 11, 12, 13, 12, 14, 13 };
	for (i = 0; i < 6; i++) {
		pIndex[18 + i] = m_BufInfo[noteNo].vertexPos + index14[i];
	}
	
	//----------------------------------------------------------------
	//側面 4-5
	//----------------------------------------------------------------
	//   18+--+17
	//     |  |
	// 5 16+--+15 4
	
	//頂点
	pVertex[15].p = pVertex[4].p;
	pVertex[16].p = pVertex[5].p;
	pVertex[17].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	pVertex[18].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	
	//法線／色
	for (i = 15; i < 19; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index45[] = { 15, 16, 17, 16, 18, 17 };
	for (i = 0; i < 6; i++) {
		pIndex[24 + i] = m_BufInfo[noteNo].vertexPos + index45[i];
	}
	
	//----------------------------------------------------------------
	//側面 5-6
	//----------------------------------------------------------------
	// 21+--+19 5
	//   |  |
	//   |  |
	// 22+--+20 6
	
	//頂点
	pVertex[19].p = pVertex[5].p;
	pVertex[20].p = pVertex[6].p;
	pVertex[21].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[22].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	
	//法線／色
	for (i = 19; i < 23; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index56[] = { 19, 20, 21, 20, 22, 21 };
	for (i = 0; i < 6; i++) {
		pIndex[30 + i] = m_BufInfo[noteNo].vertexPos + index56[i];
	}
	
	//----------------------------------------------------------------
	//側面 6-3
	//----------------------------------------------------------------
	//   26+--+25
	//     |  |
	// 3 24+--+23 6
	
	//頂点
	pVertex[23].p = pVertex[6].p;
	pVertex[24].p = pVertex[3].p;
	pVertex[25].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	pVertex[26].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	
	//法線／色
	for (i = 23; i < 27; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index63[] = { 23, 24, 25, 24, 26, 25 };
	for (i = 0; i < 6; i++) {
		pIndex[36 + i] = m_BufInfo[noteNo].vertexPos + index63[i];
	}
	
	//----------------------------------------------------------------
	//側面 3-0
	//----------------------------------------------------------------
	// 29+--+27 3
	//   |  |
	//   |  |
	// 30+--+28 0
	
	//頂点
	pVertex[27].p = pVertex[3].p;
	pVertex[28].p = pVertex[0].p;
	pVertex[29].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	pVertex[30].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z);  // 0'
	
	//法線／色
	for (i = 27; i < 31; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index30[] = { 27, 28, 29, 28, 30, 29 };
	for (i = 0; i < 6; i++) {
		pIndex[42 + i] = m_BufInfo[noteNo].vertexPos + index30[i];
	}
	
	//----------------------------------------------------------------
	//下の面
	//----------------------------------------------------------------
	//    36 5+--+4 35
	//        |  |
	//        |  |
	//    37 6|  |
	// 34 3+--+--+2 33
	//     |     |     +z
	//     |     |      |
	//     |     |      |
	// 31 0+-----+1 32  +---> +x
	//        |
	//       posX
	
	//頂点
	pVertex[31].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z);  // 0'
	pVertex[32].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z);  // 1'
	pVertex[33].p = OGLVECTOR3(pVertex[2].p.x, 0.0f, pVertex[2].p.z);  // 2'
	pVertex[34].p = OGLVECTOR3(pVertex[3].p.x, 0.0f, pVertex[3].p.z);  // 3'
	pVertex[35].p = OGLVECTOR3(pVertex[4].p.x, 0.0f, pVertex[4].p.z);  // 4'
	pVertex[36].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[37].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	
	//法線／色
	for (i = 31; i < 38; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, -1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexDW[] = { 31, 32, 33, 31, 33, 34, 33, 35, 37, 37, 35, 36 };
	for (i = 0; i < 12; i++) {
		pIndex[48 + i] = m_BufInfo[noteNo].vertexPos + indexDW[i];
	}
	
	//----------------------------------------------------------------
	//単一色のテクスチャ座標
	//----------------------------------------------------------------
	m_KeyboardDesign.GetWhiteKeyTexturePosSingleColor(noteNo, &tsc);
	for (i = 11; i < 38; i++) {
		pVertex[i].t = tsc;
	}
	
	return result;
}

//******************************************************************************
// キーボード頂点生成：黒鍵
//******************************************************************************
int MTPianoKeyboard::_CreateVertexOfKeyBlack(
		unsigned char noteNo,
		MTPIANOKEYBOARD_VERTEX* pVertex,
		unsigned long* pIndex,
		OGLCOLOR* pColor
	)
{
	int result = 0;
	unsigned long i = 0;
	float centerX        = m_KeyboardDesign.GetKeyCenterPosX(noteNo);
	float heightY        = m_KeyboardDesign.GetWhiteKeyHeight();
	float whiteKeyLen    = m_KeyboardDesign.GetWhiteKeyLen();
	float blackKeyWidth  = m_KeyboardDesign.GetBlackKeyWidth();
	float blackKeyHeight = m_KeyboardDesign.GetBlackKeyHeight();
	float blackKeyLen    = m_KeyboardDesign.GetBlackKeyLen();
	float deltaKeyLen    = whiteKeyLen - blackKeyLen;
	float blackKeySlope  = m_KeyboardDesign.GetBlackKeySlopeLen();
	OGLVECTOR3 nVector;
	OGLVECTOR3 normalizedVector;
	OGLCOLOR keyColor;
	OGLVECTOR2 t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, tsc;
	bool isColored = false;
	
	//黒鍵カラー取得
	if (pColor == NULL) {
		keyColor = m_KeyboardDesign.GetBlackKeyColor();
	}
	else {
		keyColor = *pColor;
		isColored = true;
	}
	
	//----------------------------------------------------------------
	//上の面
	//----------------------------------------------------------------
	//   6+-+5
	//    | |
	//    | |
	// 7 3+-+2 4
	//   0+-+1
	//     |   +z
	//     |    |
	//     |    |
	//   --+--  +---> +x
	//     |
	//    posX
	
	//頂点
	pVertex[0].p = OGLVECTOR3(centerX - (blackKeyWidth/2.0f), heightY,        deltaKeyLen);
	pVertex[1].p = OGLVECTOR3(centerX + (blackKeyWidth/2.0f), heightY,        deltaKeyLen);
	pVertex[2].p = OGLVECTOR3(centerX + (blackKeyWidth/2.0f), blackKeyHeight, deltaKeyLen + blackKeySlope);
	pVertex[3].p = OGLVECTOR3(centerX - (blackKeyWidth/2.0f), blackKeyHeight, deltaKeyLen + blackKeySlope);
	pVertex[4].p = pVertex[2].p;
	pVertex[5].p = OGLVECTOR3(centerX + (blackKeyWidth/2.0f), blackKeyHeight, whiteKeyLen);
	pVertex[6].p = OGLVECTOR3(centerX - (blackKeyWidth/2.0f), blackKeyHeight, whiteKeyLen);
	pVertex[7].p = pVertex[3].p;
	
	//法線／色：0-1-2-3面
	nVector = OGLVECTOR3(0.0f, 0.12f, -0.08f);
	OGLH::Vec3Normalize(&normalizedVector, &nVector);
	for (i = 0; i < 4; i++) {
		pVertex[i].n = normalizedVector;
		pVertex[i].c = keyColor;
	}
	//法線／色：4-5-6-7面
	for (i = 4; i < 8; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexUP[] = { 0, 2, 1, 0, 3, 2, 4, 7, 5, 7, 6, 5 };
	for (i = 0; i < 12; i++) {
		pIndex[i] = m_BufInfo[noteNo].vertexPos + indexUP[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetBlackKeyTexturePos(
			noteNo, &t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7, &t8, &t9, isColored
		);
	pVertex[0].t = t0;
	pVertex[1].t = t1;
	pVertex[2].t = t2;
	pVertex[3].t = t3;
	pVertex[4].t = t2;
	pVertex[5].t = t4;
	pVertex[6].t = t5;
	pVertex[7].t = t3;
	
	//----------------------------------------------------------------
	//側面 0-1
	//----------------------------------------------------------------
	//  0      1
	//  8+----+9
	//   |    |
	// 10+----+11
	
	//頂点
	pVertex[8].p  = pVertex[0].p;
	pVertex[9].p  = pVertex[1].p;
	pVertex[10].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z); // 0'
	pVertex[11].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z); // 1'
	
	//法線／色
	for (i = 8; i < 12; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index01[] = { 8, 9, 10, 9, 11, 10 };
	for (i = 0; i < 6; i++) {
		pIndex[12 + i] = m_BufInfo[noteNo].vertexPos + index01[i];
	}
	
	//各頂点のテクスチャ座標
	m_KeyboardDesign.GetBlackKeyTexturePosSingleColor(noteNo, &tsc, isColored);
	for (i = 8; i < 12; i++) {
		pVertex[i].t = tsc;
	}
	
	//----------------------------------------------------------------
	//側面 1-2-5
	//----------------------------------------------------------------
	// 5 14+--+16
	//     |  |
	//     |  |
	// 2 13+  |
	//      \ |
	// 1 12 +-+15
	
	//頂点
	pVertex[12].p  = pVertex[1].p;
	pVertex[13].p  = pVertex[2].p;
	pVertex[14].p  = pVertex[5].p;
	pVertex[15].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z); // 1'
	pVertex[16].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z); // 5'
	
	//法線／色
	for (i = 12; i < 17; i++) {
		pVertex[i].n = OGLVECTOR3(1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index125[] = { 12, 13, 15, 13, 16, 15, 13, 14, 16 };
	for (i = 0; i < 9; i++) {
		pIndex[18 + i] = m_BufInfo[noteNo].vertexPos + index125[i];
	}
	
	//各頂点のテクスチャ座標
	pVertex[12].t = t1;
	pVertex[13].t = t2;
	pVertex[14].t = t4;
	pVertex[15].t = t6;
	pVertex[16].t = t7;
	
	//----------------------------------------------------------------
	//側面 5-6
	//----------------------------------------------------------------
	//   20+--+19
	//     |  |
	// 6 18+--+17 5
	
	//頂点
	pVertex[17].p = pVertex[5].p;
	pVertex[18].p = pVertex[6].p;
	pVertex[19].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z);  // 5'
	pVertex[20].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z);  // 6'
	
	//法線／色
	for (i = 17; i < 21; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index56[] = { 17, 18, 19, 18, 20, 19 };
	for (i = 0; i < 6; i++) {
		pIndex[27 + i] = m_BufInfo[noteNo].vertexPos + index56[i];
	}
	
	//各頂点のテクスチャ座標
	for (i = 17; i < 21; i++) {
		pVertex[i].t = tsc;
	}
	
	//----------------------------------------------------------------
	//側面 6-3-0
	//----------------------------------------------------------------
	// 24+--+21 6
	//   |  |
	//   |  |
	//   |  +22 3
	//   | /
	// 25+-+23  0
	
	//頂点
	pVertex[21].p  = pVertex[6].p;
	pVertex[22].p  = pVertex[3].p;
	pVertex[23].p  = pVertex[0].p;
	pVertex[24].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z); // 6'
	pVertex[25].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z); // 0'
	
	//法線／色
	for (i = 21; i < 26; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long index630[] = { 21, 22, 24, 22, 25, 24, 22, 23, 25 };
	for (i = 0; i < 9; i++) {
		pIndex[33 + i] = m_BufInfo[noteNo].vertexPos + index630[i];
	}
	
	//各頂点のテクスチャ座標
	pVertex[21].t = t5;
	pVertex[22].t = t3;
	pVertex[23].t = t0;
	pVertex[24].t = t9;
	pVertex[25].t = t8;
	
	//----------------------------------------------------------------
	//下の面
	//----------------------------------------------------------------
	//   29 6+-+5 28
	//       | |
	//       | |
	//       | |
	//   26 0+-+1 27
	//        |      +z
	//        |       |
	//        |       |
	//      --+--     +---> +x
	//        |
	//       posX
	
	//頂点
	pVertex[26].p = OGLVECTOR3(pVertex[0].p.x, 0.0f, pVertex[0].p.z); // 0'
	pVertex[27].p = OGLVECTOR3(pVertex[1].p.x, 0.0f, pVertex[1].p.z); // 1'
	pVertex[28].p = OGLVECTOR3(pVertex[5].p.x, 0.0f, pVertex[5].p.z); // 5'
	pVertex[29].p = OGLVECTOR3(pVertex[6].p.x, 0.0f, pVertex[6].p.z); // 6'
	
	//法線／色
	for (i = 26; i < 30; i++) {
		pVertex[i].n = OGLVECTOR3(0.0f, -1.0f, 0.0f);
		pVertex[i].c = keyColor;
	}
	
	//インデックス
	unsigned long indexDW[] = { 26, 27, 28, 26, 28, 29 };
	for (i = 0; i < 6; i++) {
		pIndex[42 + i] = m_BufInfo[noteNo].vertexPos + indexDW[i];
	}
	
	//各頂点のテクスチャ座標
	for (i = 26; i < 30; i++) {
		pVertex[i].t = tsc;
	}
	
	return result;
}

//******************************************************************************
// テクスチャ画像読み込み
//******************************************************************************
int MTPianoKeyboard::_LoadTexture(
		OGLDevice* pOGLDevice,
		NSString* pSceneName
	)
{
	int result = 0;
	NSString* pImgFilePath = nil;
	NSString* pBmpFileName = nil;
	MTConfFile confFile;
	BOOL isExist = NO;
	BOOL isDirectory = NO;
	
	result = confFile.Initialize(pSceneName);
	if (result != 0) goto EXIT;
	
	//ビットマップファイル名
	result = confFile.SetCurSection(@"Bitmap");
	if (result != 0) goto EXIT;
	result = confFile.GetStr(@"Keyboard", &pBmpFileName, MT_IMGFILE_KEYBOARD);
	if (result != 0) goto EXIT;
	
	//画像ファイルパス
	pImgFilePath = [NSString stringWithFormat:@"%@/%@",
									[YNPathUtil resourceDirPath], pBmpFileName];
	
	//画像ファイルが存在しない場合は読み込みを中止する
	isExist = [[NSFileManager defaultManager] fileExistsAtPath:pImgFilePath isDirectory:&isDirectory];
	if (!isExist) {
		m_pTexture = NULL;
		goto EXIT;
	}
	
	//テクスチャオブジェクト生成
	try {
		m_pTexture = new OGLTexture();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//任意画像サイズ有効化
	m_pTexture->EnableRectanbleExt(true);
	
	//画像ファイル読み込み
	result = m_pTexture->LoadImageFile(pImgFilePath);
	if (result != 0) goto EXIT;
	
	m_isTextureOwner = true;
	
EXIT:;
	return result;
}

//******************************************************************************
// マテリアル作成
//******************************************************************************
void MTPianoKeyboard::_MakeMaterial(
		OGLMATERIAL* pMaterial
	)
{
	memset(pMaterial, 0, sizeof(OGLMATERIAL));
	
	//拡散光
	pMaterial->Diffuse.r = 1.0f;
	pMaterial->Diffuse.g = 1.0f;
	pMaterial->Diffuse.b = 1.0f;
	pMaterial->Diffuse.a = 1.0f;
	//環境光：影の色
	pMaterial->Ambient.r = 0.5f;
	pMaterial->Ambient.g = 0.5f;
	pMaterial->Ambient.b = 0.5f;
	pMaterial->Ambient.a = 1.0f;
	//鏡面反射光
	pMaterial->Specular.r = 0.2f;
	pMaterial->Specular.g = 0.2f;
	pMaterial->Specular.b = 0.2f;
	pMaterial->Specular.a = 1.0f;
	//鏡面反射光の鮮明度
	pMaterial->Power = 40.0f;
	//発光色
	pMaterial->Emissive.r = 0.0f;
	pMaterial->Emissive.g = 0.0f;
	pMaterial->Emissive.b = 0.0f;
	pMaterial->Emissive.a = 0.0f;
}

//******************************************************************************
// 移動
//******************************************************************************
int MTPianoKeyboard::Transform(
		OGLDevice* pOGLDevice,
		OGLVECTOR3 moveVector,
		float rollAngle
	)
{
	int result = 0;
	OGLTransMatrix transMatrix;
	
	//移動
	transMatrix.RegistTranslation(moveVector.x, moveVector.y, moveVector.z);
	
	//回転
	transMatrix.RegistRotationY(rollAngle);
	
	//左手系(DirectX)=>右手系(OpenGL)の変換
	transMatrix.RegistScale(1.0f, 1.0f, LH2RH(1.0f));
	
	//変換行列設定
	m_PrimitiveKeyboard.Transform(&transMatrix);
	
//EXIT:;
	return result;
}

//******************************************************************************
// キーのリセット
//******************************************************************************
int MTPianoKeyboard::ResetKey(
		unsigned char noteNo
	)
{
	int result = 0;
	float angle = 0.0f;
	
	if (noteNo >= SM_MAX_NOTE_NUM) {
		result = YN_SET_ERR(@"Program error.", noteNo, 0);
		goto EXIT;
	}
	
	_RotateKey(noteNo, angle);
	
EXIT:;
	return result;
}

//******************************************************************************
// キーの押し込み
//******************************************************************************
int MTPianoKeyboard::PushKey(
		unsigned char noteNo,
		float keyDownRate,
		unsigned long elapsedTime,
		OGLCOLOR* pNoteColor
	)
{
	int result = 0;
	float angle = 0.0f;
	OGLCOLOR color;
	
	if (noteNo >= SM_MAX_NOTE_NUM) {
		result = YN_SET_ERR(@"Program error.", noteNo, 0);
		goto EXIT;
	}
	
	angle = m_KeyboardDesign.GetKeyRotateAngle() * keyDownRate;
	
	if (keyDownRate < 1.0f) {
		//キーが下降中／上昇中の場合は色を変更せず回転させる
		_RotateKey(noteNo, angle);
	}
	else {
		//キーが押下状態の場合は色を変更して回転させる
		color = m_KeyboardDesign.GetActiveKeyColor(noteNo, elapsedTime, pNoteColor);
		_RotateKey(noteNo, angle, &color);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTPianoKeyboard::Draw(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	
	//テクスチャステージ設定
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	//  カラー演算：乗算  引数1：テクスチャ  引数2：ポリゴン
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_PRIMARY_COLOR);
	// アルファ演算：引数1を使用  引数1：ポリゴン
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_PRIMARY_COLOR);
	
	//テクスチャフィルタ
	//なし
	
	//キーボードの描画
	result = m_PrimitiveKeyboard.Draw(pOGLDevice, m_pTexture);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTPianoKeyboard::Release()
{
	m_PrimitiveKeyboard.Release();
	
	if (m_isTextureOwner && (m_pTexture != NULL)) {
		m_pTexture->Release();
		m_pTexture = NULL;
		m_isTextureOwner = false;
	}
}

//******************************************************************************
// キー回転
//******************************************************************************
int MTPianoKeyboard::_RotateKey(
		unsigned char noteNo,
		float angle,
		OGLCOLOR* pColor
	)
{
	int result = 0;
	unsigned long i = 0;
	MTPIANOKEYBOARD_VERTEX* pVertex = NULL;
	unsigned long offset = 0;
	unsigned long size = 0;
	MTPIANOKEYBOARD_VERTEX tempVertex[MTPIANOKEYBOARD_KEY_VERTEX_NUM_MAX];
	unsigned long tempIndex[MTPIANOKEYBOARD_KEY_INDEX_NUM_MAX];
	float centerY, centerZ = 0.0f;
	OGLVECTOR2 ts;
	
	if (noteNo >= SM_MAX_NOTE_NUM) {
		result = YN_SET_ERR(@"Program error.", noteNo, 0);
		goto EXIT;
	}
	
	//表示範囲外のキーなら何もしない
	if (!(m_KeyboardDesign.IsKeyDisp(noteNo))) {
		goto EXIT;
	}
	
	//回転なしの頂点を取得
	switch (m_KeyboardDesign.GetKeyType(noteNo)) {
		case (MTPianoKeyboardDesign::KeyWhiteC):
		case (MTPianoKeyboardDesign::KeyWhiteF):
			result = _CreateVertexOfKeyWhite1(noteNo, tempVertex, tempIndex, pColor);
			if (result != 0) goto EXIT;
			break;
		case (MTPianoKeyboardDesign::KeyWhiteD):
		case (MTPianoKeyboardDesign::KeyWhiteG):
		case (MTPianoKeyboardDesign::KeyWhiteA):
			result = _CreateVertexOfKeyWhite2(noteNo, tempVertex, tempIndex, pColor);
			if (result != 0) goto EXIT;
			break;
		case (MTPianoKeyboardDesign::KeyWhiteE):
		case (MTPianoKeyboardDesign::KeyWhiteB):
			result = _CreateVertexOfKeyWhite3(noteNo, tempVertex, tempIndex, pColor);
			if (result != 0) goto EXIT;
			break;
		case (MTPianoKeyboardDesign::KeyBlack):
			result = _CreateVertexOfKeyBlack(noteNo, tempVertex, tempIndex, pColor);
			if (result != 0) goto EXIT;
			break;
	}
	
	//頂点と法線の座標回転
	//
	//    |<=キャプスタンボタン   +---------+ 黒鍵盤
	//  +-+--------------+--------+---------+-----+
	//  |                |        |               | 白鍵盤
	//  +----------------@--------+-------------+-+
	//       @:支点      |<=バランスピン        |<=フロントピン
	//                   :        :               :
	//            +z<----|--------+---------------* 原点
	//                  2.36     1.50            0.00
	//
	centerY = 0.00f;
	centerZ = m_KeyboardDesign.GetKeyRotateAxisXPos();
	for (i = 0; i < m_BufInfo[noteNo].vertexNum; i++) {
		tempVertex[i].p = _RotateYZ(centerY, centerZ, tempVertex[i].p, angle);
		tempVertex[i].n = _RotateYZ(   0.0f,   0.00f, tempVertex[i].n, angle);
	}
	
	//頂点バッファのロック
	offset = m_BufInfo[noteNo].vertexPos * sizeof(MTPIANOKEYBOARD_VERTEX);
	size   = m_BufInfo[noteNo].vertexNum * sizeof(MTPIANOKEYBOARD_VERTEX);
	result = m_PrimitiveKeyboard.LockVertex((void**)&pVertex, offset, size);
	if (result != 0) goto EXIT;
	
	//回転後の頂点をコピー
	memcpy(pVertex, tempVertex, size);
	
	//頂点バッファのロック解除
	result = m_PrimitiveKeyboard.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 座標回転：YZ平面
//******************************************************************************
OGLVECTOR3 MTPianoKeyboard::_RotateYZ(
		float centerY,
		float centerZ,
		OGLVECTOR3 p1,
		float angle
	)
{
	OGLVECTOR3 p2;
	float rad = 0.0f;
	
	rad = OGLH::ToRadian(angle);
	p2.x = p1.x;
	p2.y = centerY + (sin(rad) * (p1.z - centerZ)) + (cos(rad) * (p1.y - centerY));
	p2.z = centerZ + (cos(rad) * (p1.z - centerZ)) - (sin(rad) * (p1.y - centerY));
	
	return p2;
}

//******************************************************************************
// 共有用テクスチャ取得
//******************************************************************************
OGLTexture* MTPianoKeyboard::GetTexture()
{
	return m_pTexture;
}

//******************************************************************************
// キー隠蔽
//******************************************************************************
int MTPianoKeyboard::_HideKey(
		unsigned char noteNo
	)
{
	int result = 0;
	unsigned long i = 0;
	MTPIANOKEYBOARD_VERTEX* pVertex = NULL;
	unsigned long offset = 0;
	unsigned long size = 0;

	//頂点バッファのロック
	offset = m_BufInfo[noteNo].vertexPos * sizeof(MTPIANOKEYBOARD_VERTEX);
	size   = m_BufInfo[noteNo].vertexNum * sizeof(MTPIANOKEYBOARD_VERTEX);
	result = m_PrimitiveKeyboard.LockVertex((void**)&pVertex, offset, size);
	if (result != 0) goto EXIT;

	for (i = 0; i < m_BufInfo[noteNo].vertexNum; i++) {
		pVertex[i].p = OGLVECTOR3(0.0f, 0.0f, 0.0f);
		pVertex[i].n = OGLVECTOR3(0.0f, 0.0f, 1.0f);
		pVertex[i].c = OGLCOLOR(0.0f, 0.0f, 0.0f, 0.0f); //R,G,B,A
		pVertex[i].t = OGLVECTOR2(0.0f, 0.0f);
	}

	//頂点バッファのロック解除
	result = m_PrimitiveKeyboard.UnlockVertex();
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}


