//******************************************************************************
//
// MIDITrail / MTTimeIndicator
//
// タイムインジケータ描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTTimeIndicator.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTTimeIndicator::MTTimeIndicator(void)
{
	m_CurPos = 0.0f;
	m_CurTickTime = 0;
	m_isEnableLine = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTTimeIndicator::~MTTimeIndicator(void)
{
	Release();
}

//******************************************************************************
// タイムインジケータ生成
//******************************************************************************
int MTTimeIndicator::Create(
		OGLDevice* pOGLDevice,
		NSString* pSceneName,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	SMBarList barList;
	
	Release();
	
	//ノートデザインオブジェクト初期化
	result = m_NoteDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//プリミティブ生成
	result = _CreatePrimitive(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//プリミティブ生成：タイムライン
	result = _CreatePrimitiveLine(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// プリミティブ生成
//******************************************************************************
int MTTimeIndicator::_CreatePrimitive(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long vertexNum = 0;
	unsigned long indexNum = 0;
	MTTIMEINDICATOR_VERTEX* pVertex = NULL;
	unsigned long* pIndex = NULL;
	
	//プリミティブ初期化
	result = m_Primitive.Initialize(
					sizeof(MTTIMEINDICATOR_VERTEX),	//頂点サイズ
					_GetFVFFormat(),				//頂点FVFフォーマット
					GL_TRIANGLE_STRIP				//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	vertexNum = 4;
	result = m_Primitive.CreateVertexBuffer(pOGLDevice, vertexNum);
	if (result != 0) goto EXIT;
	
	//インデックスバッファ生成
	indexNum = 4;
	result = m_Primitive.CreateIndexBuffer(pOGLDevice, indexNum);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	result = m_Primitive.LockIndex(&pIndex);
	if (result != 0) goto EXIT;
	
	//バッファに頂点とインデックスを書き込む
	result = _CreateVertexOfIndicator(pVertex, pIndex);
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
// プリミティブ生成
//******************************************************************************
int MTTimeIndicator::_CreatePrimitiveLine(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long vertexNum = 0;
	MTTIMEINDICATOR_VERTEX* pVertex = NULL;
	
	//プリミティブ初期化
	result = m_PrimitiveLine.Initialize(
					sizeof(MTTIMEINDICATOR_VERTEX),	//頂点サイズ
					_GetFVFFormat(),				//頂点FVFフォーマット
					GL_LINES						//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	vertexNum = 2;
	result = m_PrimitiveLine.CreateVertexBuffer(pOGLDevice, vertexNum);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_PrimitiveLine.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	//バッファに頂点とインデックスを書き込む
	result = _CreateVertexOfIndicatorLine(pVertex);
	if (result != 0) goto EXIT;
	
	//バッファのロック解除
	result = m_PrimitiveLine.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 移動
//******************************************************************************
int MTTimeIndicator::Transform(
		OGLDevice* pOGLDevice,
		OGLVECTOR3 camVector,
		float rollAngle
	)
{
	int result = 0;
	OGLVECTOR3 moveVector;
	OGLTransMatrix transMatrix;
	
	//回転
	transMatrix.RegistRotationX(rollAngle);
	
	//演奏位置
	m_CurPos = m_NoteDesign.GetPlayPosX(m_CurTickTime);
	
	//移動行列
	moveVector = m_NoteDesign.GetWorldMoveVector();
	transMatrix.RegistTranslation(moveVector.x + m_CurPos, moveVector.y, moveVector.z);
	
	//左手系(DirectX)=>右手系(OpenGL)の変換
	transMatrix.RegistScale(1.0f, 1.0f, LH2RH(1.0f));
	
	//変換行列設定
	m_Primitive.Transform(&transMatrix);
	m_PrimitiveLine.Transform(&transMatrix);
	
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTTimeIndicator::Draw(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	if (m_isEnableLine) {
		result = m_PrimitiveLine.Draw(pOGLDevice);
		if (result != 0) goto EXIT;
	}
	else {
		result = m_Primitive.Draw(pOGLDevice);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTTimeIndicator::Release()
{
	m_Primitive.Release();
	m_PrimitiveLine.Release();
}

//******************************************************************************
// タイムインジケータ頂点生成
//******************************************************************************
int MTTimeIndicator::_CreateVertexOfIndicator(
		MTTIMEINDICATOR_VERTEX* pVertex,
		unsigned long* pIndex
	)
{
	int result = 0;
	unsigned long i;
	OGLVECTOR3 vectorLU;
	OGLVECTOR3 vectorRU;
	OGLVECTOR3 vectorLD;
	OGLVECTOR3 vectorRD;
	
	//              y x
	//  0+----+1    |/
	//   |    |  z--+0
	//   |    |
	//  2+----+3 ← 3 が原点(0,0,0)
	
	//再生面頂点座標取得
	m_NoteDesign.GetPlaybackSectionVirtexPos(
			0,
			&vectorLU,
			&vectorRU,
			&vectorLD,
			&vectorRD
		);
	
	//頂点座標
	pVertex[0].p = vectorLU;
	pVertex[1].p = vectorRU;
	pVertex[2].p = vectorLD;
	pVertex[3].p = vectorRD;
	
	//再生面の幅がゼロの場合はラインを描画する
	if (vectorLU.z == vectorRU.z) {
		m_isEnableLine = true;
	}
	
	//法線
	pVertex[0].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
	pVertex[1].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
	pVertex[2].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
	pVertex[3].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
	
	//各頂点のディフューズ色
	for (i = 0; i < 4; i++) {
		pVertex[i].c = m_NoteDesign.GetPlaybackSectionColor();
	}
	
	//インデックス：TRIANGLESTRIP
	pIndex[0] = 0;
	pIndex[1] = 1;
	pIndex[2] = 2;
	pIndex[3] = 3;
	
	return result;
}

//******************************************************************************
// タイムインジケータライン頂点生成
//******************************************************************************
int MTTimeIndicator::_CreateVertexOfIndicatorLine(
		MTTIMEINDICATOR_VERTEX* pVertex
	)
{
	int result = 0;
	unsigned long i;
	OGLVECTOR3 vectorLU;
	OGLVECTOR3 vectorRU;
	OGLVECTOR3 vectorLD;
	OGLVECTOR3 vectorRD;
	
	//              y x
	//  0+----+1    |/
	//   |    |  z--+0
	//   |    |
	//  2+----+3 ← 3 が原点(0,0,0)
	
	//再生面頂点座標取得
	m_NoteDesign.GetPlaybackSectionVirtexPos(
			0,
			&vectorLU,
			&vectorRU,
			&vectorLD,
			&vectorRD
		);
	
	//頂点座標
	pVertex[0].p = vectorLU;
	pVertex[1].p = vectorLD;
	
	//法線
	pVertex[0].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	pVertex[1].n = OGLVECTOR3(0.0f, 0.0f, -1.0f);
	
	//各頂点のディフューズ色
	for (i = 0; i < 2; i++) {
		pVertex[i].c = m_NoteDesign.GetPlaybackSectionColor();
	}
	
	return result;
}

//******************************************************************************
// チックタイム設定
//******************************************************************************
void MTTimeIndicator::SetCurTickTime(
		unsigned long curTickTime
	)
{
	m_CurTickTime = curTickTime;
	m_CurPos = m_NoteDesign.GetPlayPosX(m_CurTickTime);
}

//******************************************************************************
// リセット
//******************************************************************************
void MTTimeIndicator::Reset()
{
	m_CurTickTime = 0;
	m_CurPos = 0.0f;
}

//******************************************************************************
// 現在位置取得
//******************************************************************************
float MTTimeIndicator::GetPos()
{
	return m_CurPos;
}

//******************************************************************************
// 移動ベクトル取得
//******************************************************************************
OGLVECTOR3 MTTimeIndicator::GetMoveVector()
{
	return OGLVECTOR3(m_CurPos, 0.0f, 0.0f);
}


