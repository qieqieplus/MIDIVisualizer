//******************************************************************************
//
// MIDITrail / MTPictBoard
//
// ピクチャボード描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"


//******************************************************************************
//  ピクチャボード描画クラス
//******************************************************************************
class MTPictBoard
{
public:
	
	//コンストラクタ／デストラクタ
	MTPictBoard(void);
	virtual ~MTPictBoard(void);
	
	//生成
	int Create(OGLDevice* pD3DDevice, NSString* pSceneName, SMSeqData* pSeqData);
	
	//更新
	int Transform(OGLDevice* pD3DDevice, OGLVECTOR3 camVector, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pD3DDevice);
	
	//解放
	void Release();
	
	//演奏チックタイム登録
	void SetCurTickTime(unsigned long curTickTime);
	
	//リセット
	void Reset();
	
	//演奏開始終了
	void OnPlayStart();
	void OnPlayEnd();
	
	//表示設定
	void SetEnable(bool isEnable);
	
private:
	
	OGLPrimitive m_Primitive;
	OGLTexture m_Texture;
	unsigned long m_CurTickTime;
	bool m_isPlay;
	bool m_isEnable;
	MTNoteDesign m_NoteDesign;
	bool m_isClipImage;
	OGLVECTOR2 m_ClipAreaP1;
	OGLVECTOR2 m_ClipAreaP2;
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3CT2 MTPICTBOARD_VERTEX;
	//struct MTPICTBOARD_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//	D3DXVECTOR2 t;	//テクスチャ画像位置
	//};
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3CT2; }
	
	int _CreateVertexOfBoard(
			MTPICTBOARD_VERTEX* pVertex,
			unsigned long* pIbIndex
		);
	
	int _LoadTexture(OGLDevice* pD3DDevice, NSString* pSceneName);
	
};


