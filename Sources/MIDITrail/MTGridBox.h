//******************************************************************************
//
// MIDITrail / MTGridBox
//
// グリッドボックス描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// グリッドボックスと小節線を描画する。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"


//******************************************************************************
//  グリッドボックス描画クラス
//******************************************************************************
class MTGridBox
{
public:
	
	//コンストラクタ／デストラクタ
	MTGridBox(void);
	virtual ~MTGridBox(void);
	
	//生成
	int Create(OGLDevice* pOGLDevice, NSString* pSceneName, SMSeqData* pSeqData);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
private:
	
	OGLPrimitive m_Primitive;
	unsigned long m_BarNum;
	SMPortList m_PortList;
	MTNoteDesign m_NoteDesign;
	bool m_isVisible;
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3C MTGRIDBOX_VERTEX;
	//struct MTGRIDBOX_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//};
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreateVertexOfGrid(
			MTGRIDBOX_VERTEX* pVertex,
			unsigned long* pIbIndex,
			unsigned long totalTickTime
		);
	
	int _CreateVertexOfBar(
			MTGRIDBOX_VERTEX* pVertex,
			unsigned long* pIbIndex,
			unsigned long vartexIndexOffset,
			SMBarList* pBarList
		);
	
	int _CreateVertexOfPortSplitLine(
			MTGRIDBOX_VERTEX* pVertex,
			unsigned long* pIndex,
			unsigned long vartexIndexOffset,
			unsigned long totalTickTime
		);
	
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	
};


