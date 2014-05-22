//******************************************************************************
//
// MIDITrail / MTNoteRain
//
// ノートレイン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// ノートレインを描画する。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"
#import "MTNotePitchBend.h"
#import "MTPianoKeyboardDesign.h"
#import "MTMachTime.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//最大発音ノート描画数
#define MTNOTERAIN_MAX_ACTIVENOTE_NUM  (100)

// TODO: 最大発音ノート描画数を可変にする
//   事前にシーケンスデータの最大同時発音数を調査しておけば
//   確保するバッファサイズを変更できる
//   現状でもバッファサイズは初期化時点で動的に変更可能である

//******************************************************************************
// ノートレイン描画クラス
//******************************************************************************
class MTNoteRain
{
public:
	
	//コンストラクタ／デストラクタ
	MTNoteRain(void);
	virtual ~MTNoteRain(void);
	
	//生成
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pSceneName,
			SMSeqData* pSeqData,
			MTNotePitchBend* pNotePitchBend
		);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, float rollAngle);
	
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
	
	//スキップ状態
	void SetSkipStatus(bool isSkipping);

private:
	
	//発音ノート情報構造体
	struct NoteStatus {
		bool isActive;
		unsigned long index;
		uint64_t startTime;
	};
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3C MTNOTERAIN_VERTEX;
	//struct MTNOTERAIN_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD       c;	//ディフューズ色
	//};
	
private:
	
	//ノートデザイン
	MTNoteDesign m_NoteDesign;
	
	//キーボードデザイン
	MTPianoKeyboardDesign m_KeyboardDesign;
	
	//ノートリスト
	SMNoteList m_NoteList;
	
	//全ノートレイン
	OGLPrimitive m_PrimitiveAllNotes;
	
	//発音中ノートボックス
	unsigned long m_CurTickTime;
	unsigned long m_CurNoteIndex;
	NoteStatus* m_pNoteStatus;
	float m_CurPos;
	
	//スキップ状態
	bool m_isSkipping;
	
	//ピッチベンド情報
	MTNotePitchBend* m_pNotePitchBend;
	
	//Mach時間
	MTMachTime m_MachTime;
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreateAllNoteRain(OGLDevice* pOGLDevice);
	int _CreateVertexOfNote(
				SMNote note,
				MTNOTERAIN_VERTEX* pVertex,
				unsigned long vertexOffset,
				unsigned long* pIndex
			);
	int _CreateNoteStatus();
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	int _TransformActiveNotes(OGLDevice* pOGLDevice);
	int _UpdateStatusOfActiveNotes(OGLDevice* pOGLDevice);
	int _UpdateActiveNotes(OGLDevice* pOGLDevice);
	int _UpdateVertexOfNote(
				unsigned long index,
				bool isEnablePitchBendShift = false
			);
	
};


