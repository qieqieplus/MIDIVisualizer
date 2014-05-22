//******************************************************************************
//
// MIDITrail / MTGridBoxLive
//
// ライブモニタ用グリッドボックス描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// グリッドボックスを描画する。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"


//******************************************************************************
// ライブモニタ用グリッドボックス描画クラス
//******************************************************************************
class MTGridBoxLive
{
public:
	
	//コンストラクタ／デストラクタ
	MTGridBoxLive(void);
	virtual ~MTGridBoxLive(void);
	
	//生成
	int Create(OGLDevice* pOGLDevice, NSString* pSceneName);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
private:
	
	OGLPrimitive m_Primitive;
	MTNoteDesign m_NoteDesign;
	bool m_isVisible;
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3C MTGRIDBOXLIVE_VERTEX;
	//struct MTGRIDBOX_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//};
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreateVertexOfGrid(
			MTGRIDBOXLIVE_VERTEX* pVertex,
			unsigned long* pIbIndex
		);
	
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	
};


