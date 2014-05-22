//******************************************************************************
//
// MIDITrail / MTPianoKeyboardCtrlLive
//
// ライブモニタ用ピアノキーボード制御クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
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
#import "MTMachTime.h"


//******************************************************************************
// ライブモニタ用ピアノキーボード制御クラス
//******************************************************************************
class MTPianoKeyboardCtrlLive
{
public:
	
	//コンストラクタ／デストラクタ
	MTPianoKeyboardCtrlLive(void);
	virtual ~MTPianoKeyboardCtrlLive(void);
	
	//生成
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pSceneName,
			MTNotePitchBend* pNotePitchBend,
			bool isSingleKeyboard
		);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//リセット
	void Reset();
	
	//表示設定
	void SetEnable(bool isEnable);
	
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
	
	//キー状態
	enum KeyStatus {
		BeforeNoteON,
		NoteON,
		AfterNoteOFF
	};
	
	//発音ノート情報構造体
	struct NoteStatus {
		bool isActive;
		uint64_t startTime;
		uint64_t endTime;
		float keyDownRate;
	};
	
private:
	
	//ノートデザイン
	MTNoteDesign m_NoteDesign;
	
	//キーボード描画オブジェクト：ポインタ配列
	MTPianoKeyboard* m_pPianoKeyboard[SM_MAX_CH_NUM];
	
	//キーボードデザイン
	MTPianoKeyboardDesign m_KeyboardDesign;
	
	//ノート状態
	NoteStatus m_NoteStatus[SM_MAX_CH_NUM][SM_MAX_NOTE_NUM];
	MTMachTime m_MachTime;
	
	//ピッチベンド情報
	MTNotePitchBend* m_pNotePitchBend;
	
	//表示可否
	bool m_isEnable;
	
	//シングルキーボードフラグ
	bool m_isSingleKeyboard;
	
	void _ClearNoteStatus();
	int _CreateKeyboards(OGLDevice* pOGLDevice, NSString* pSceneName);
	
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


