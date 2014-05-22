//******************************************************************************
//
// MIDITrail / MTNoteBoxLive
//
// ライブモニタ用ノートボックス描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// ライブモニタ用ノートボックスを描画する。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"
#import "MTNotePitchBend.h"
#import "MTMachTime.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//最大発音ノート描画数
#define MTNOTEBOX_MAX_LIVENOTE_NUM  (2048)

// TODO: 最大ノート描画数を可変にする

//******************************************************************************
// ライブモニタ用ノートボックス描画クラス
//******************************************************************************
class MTNoteBoxLive
{
public:
	
	//コンストラクタ／デストラクタ
	MTNoteBoxLive(void);
	virtual ~MTNoteBoxLive(void);
	
	//生成
	int Create(
			OGLDevice* pD3DDevice,
			NSString* pSceneName,
			MTNotePitchBend* pNotePitchBend
		);
	
	//更新
	int Transform(OGLDevice* pD3DDevice, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pD3DDevice);
	
	//解放
	void Release();
	
	//リセット
	void Reset();
	
	//ノートON登録
	void SetNoteOn(
			unsigned char portNo,
			unsigned char chNo,
			unsigned char noteNo,
			unsigned char velocity
		);
	
	//ノートOFF登録
	void SetNoteOff(
			unsigned char portNo,
			unsigned char chNo,
			unsigned char noteNo
		);
	
	//全ノートOFF
	void AllNoteOff();
	void AllNoteOffOnCh(unsigned char portNo, unsigned char chNo);
	
private:
	
	//発音ノート情報構造体
	struct NoteStatus {
		bool isActive;
		unsigned char portNo;
		unsigned char chNo;
		unsigned char noteNo;
		uint64_t startTime;
		uint64_t endTime;
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
	
	//ノートボックス
	OGLPrimitive m_PrimitiveNotes;
	unsigned long m_NoteNum;
	NoteStatus* m_pNoteStatus;
	MTMachTime m_MachTime;
		
	//ピッチベンド情報
	MTNotePitchBend* m_pNotePitchBend;
	
	//ライブモニタ表示期間（ミリ秒）
	unsigned long m_LiveMonitorDisplayDuration;
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreateNoteBox(OGLDevice* pD3DDevice);
	int _CreateNoteStatus();
	
	int _CreateVertexOfNote(
			NoteStatus noteStatus,
			MTNOTEBOX_VERTEX* pVertex,
			unsigned long vertexOffset,
			unsigned long* pIbIndex,
			unsigned long curTime,
			bool isEnablePitchBend = false
		);
	unsigned long _GetVertexIndexOfNote(unsigned long index);
	
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	
	int _TransformNotes(OGLDevice* pD3DDevice);
	int _UpdateStatusOfNotes(OGLDevice* pD3DDevice);
	int _UpdateVertexOfNotes(OGLDevice* pD3DDevice);
	
	void _ClearOldestNoteStatus(unsigned long* pCleardIndex);
	
};


