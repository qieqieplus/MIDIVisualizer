//******************************************************************************
//
// MIDITrail / MTPianoKeyboardCtrl
//
// ピアノキーボード制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 複数のピアノキーボードを管理するクラス。
// 各キーボードの配置とキーの押下状態を制御する。
// 現状は1ポート(16ch)の描画のみに対応している。
// 2ポート目以降の描画には対応していない。

#import "SMIDILib.h"
#import "MTPianoKeyboard.h"
#import "MTPianoKeyboardDesign.h"
#import "MTNotePitchBend.h"
#import "MTNoteDesign.h"


//******************************************************************************
// ピアノキーボード制御クラス
//******************************************************************************
class MTPianoKeyboardCtrl
{
public:
	
	//コンストラクタ／デストラクタ
	MTPianoKeyboardCtrl(void);
	virtual ~MTPianoKeyboardCtrl(void);
	
	//生成
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pSceneName,
			SMSeqData* pSeqData,
			MTNotePitchBend* pNotePitchBend,
			bool isSingleKeyboard
		);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//演奏チックタイム登録
	void SetCurTickTime(unsigned long curTickTime);
	
	//演奏時間設定
	void SetPlayTimeMSec(unsigned long playTimeMsec);
	
	//リセット
	void Reset();
	
	//表示設定
	void SetEnable(bool isEnable);
	
	//スキップ状態
	void SetSkipStatus(bool isSkipping);

private:
	
	//キー状態
	enum KeyStatus {
		BeforeNoteON,
		NoteON,
		AfterNoteOFF
	};
	
	//発音ノート情報構造体
	struct NoteStatus {
		bool isActive;
		KeyStatus keyStatus;
		unsigned long index;
		float keyDownRate;
	};
	
private:
	
	//ノートデザイン
	MTNoteDesign m_NoteDesign;
	
	//キーボード描画オブジェクト：ポインタ配列
	MTPianoKeyboard* m_pPianoKeyboard[SM_MAX_CH_NUM];
	
	//キーボードデザイン
	MTPianoKeyboardDesign m_KeyboardDesign;
	
	//ノートリスト
	SMNoteList m_NoteListRT;
	
	//発音中ノート管理
	unsigned long m_PlayTimeMSec;
	unsigned long m_CurTickTime;
	unsigned long m_CurNoteIndex;
	NoteStatus* m_pNoteStatus;
	float m_KeyDownRate[SM_MAX_CH_NUM][SM_MAX_NOTE_NUM];
	
	//スキップ状態
	bool m_isSkipping;
	
	//ピッチベンド情報
	MTNotePitchBend* m_pNotePitchBend;
	
	//表示可否
	bool m_isEnable;
	
	//シングルキーボードフラグ
	bool m_isSingleKeyboard;
	
	int _CreateNoteStatus();
	int _CreateKeyboards(OGLDevice* pOGLDevice, NSString* pSceneName, SMSeqData* pSeqData);
	
	int _TransformActiveNotes(OGLDevice* pOGLDevice);
	int _UpdateStatusOfActiveNotes(OGLDevice* pOGLDevice);
	int _UpdateNoteStatus(
				unsigned long playTimeMSec,
				unsigned long keyDownDuration,
				unsigned long keyUpDuration,
				SMNote note,
				NoteStatus* pNoteStatus
			);
	int _UpdateVertexOfActiveNotes(OGLDevice* pOGLDevice);
	float _GetPichBendShiftPosX(unsigned char portNo, unsigned char chNo);
	
};


