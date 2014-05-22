//******************************************************************************
//
// MIDITrail / MTNoteBox
//
// ノートボックス描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// ノートボックスを描画する。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"
#import "MTNotePitchBend.h"
#import "MTMachTime.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//最大発音ノート描画数
#define MTNOTEBOX_MAX_ACTIVENOTE_NUM  (100)

// TODO: 最大発音ノート描画数を可変にする
//   事前にシーケンスデータの最大同時発音数を調査しておけば
//   確保するバッファサイズを変更できる
//   現状でもバッファサイズは初期化時点で動的に変更可能である

//******************************************************************************
// ノートボックス描画クラス
//******************************************************************************
class MTNoteBox
{
public:
	
	//コンストラクタ／デストラクタ
	MTNoteBox(void);
	virtual ~MTNoteBox(void);
	
	//生成
	int Create(
			OGLDevice* pD3DDevice,
			NSString* pSceneName,
			SMSeqData* pSeqData,
			MTNotePitchBend* pNotePitchBend
		);
	
	//更新
	int Transform(OGLDevice* pD3DDevice, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pD3DDevice);
	
	//解放
	void Release();
	
	//演奏チックタイム登録
	void SetCurTickTime(unsigned long curTickTime);
	
	//リセット
	void Reset();
	
	//スキップ状態
	void SetSkipStatus(bool isSkipping);
	
private:
	
	//発音ノート情報構造体
	struct NoteStatus {
		bool isActive;
		bool isHide;
		unsigned long index;
		uint64_t startTime;
	};
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3C MTNOTEBOX_VERTEX;
	//struct MTNOTEBOX_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//};
	
private:
	
	//ノートデザイン
	MTNoteDesign m_NoteDesign;
	
	//ノートリスト
	SMNoteList m_NoteList;
	
	//全ノートボックス
	OGLPrimitive m_PrimitiveAllNotes;
	
	//発音中ノートボックス
	OGLPrimitive m_PrimitiveActiveNotes;
	unsigned long m_CurTickTime;
	unsigned long m_CurNoteIndex;
	unsigned long m_ActiveNoteNum;
	NoteStatus* m_pNoteStatus;
	MTMachTime m_MachTime;
	
	//スキップ状態
	bool m_isSkipping;
	
	//ピッチベンド情報
	MTNotePitchBend* m_pNotePitchBend;
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreateAllNoteBox(OGLDevice* pD3DDevice);
	int _CreateActiveNoteBox(OGLDevice* pD3DDevice);
	int _CreateNoteStatus();
	
	int _CreateVertexOfNote(
			SMNote note,
			MTNOTEBOX_VERTEX* pVertex,
			unsigned long vertexOffset,
			unsigned long* pIbIndex,
			unsigned long elapsedTime = 0xFFFFFFFF,
			bool isEnablePitchBend = false
		);
	unsigned long _GetVertexIndexOfNote(unsigned long index);
	
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	void _MakeMaterialForActiveNote(OGLMATERIAL* pMaterial);
	
	int _TransformActiveNotes(OGLDevice* pD3DDevice);
	int _UpdateStatusOfActiveNotes(OGLDevice* pD3DDevice);
	int _UpdateVertexOfActiveNotes(OGLDevice* pD3DDevice);
	
	int _HideNoteBox(unsigned long index);
	int _ShowNoteBox(unsigned long index);
	
};


