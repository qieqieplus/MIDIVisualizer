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
// 「今再生しているところ」を指し示す再生面を描画する。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"


//******************************************************************************
// タイムインジケータ描画クラス
//******************************************************************************
class MTTimeIndicator
{
public:
	
	//コンストラクタ／デストラクタ
	MTTimeIndicator(void);
	virtual ~MTTimeIndicator(void);
	
	//生成
	int Create(OGLDevice* pOGLDevice, NSString* pSceneName, SMSeqData* pSeqData);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, OGLVECTOR3 camVector, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//演奏チックタイム登録
	void SetCurTickTime(unsigned long curTickTime);
	
	//リセット
	void Reset();
	
	//現在位置取得
	float GetPos();
	
	//移動ベクトル取得
	OGLVECTOR3 GetMoveVector();
	
private:
	
	OGLPrimitive m_Primitive;
	OGLPrimitive m_PrimitiveLine;
	float m_CurPos;
	MTNoteDesign m_NoteDesign;
	bool m_isEnableLine;
	
	unsigned long m_CurTickTime;
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3C MTTIMEINDICATOR_VERTEX;
	//struct MTTIMEINDICATOR_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//};
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreatePrimitive(OGLDevice* pOGLDevice);
	int _CreatePrimitiveLine(OGLDevice* pOGLDevice);
	int _CreateVertexOfIndicator(MTTIMEINDICATOR_VERTEX* pVertex, unsigned long* pIbIndex);
	int _CreateVertexOfIndicatorLine(MTTIMEINDICATOR_VERTEX* pVertex);
	
};


