//******************************************************************************
//
// Simple MIDI Library / SMSequencer
//
// シーケンサクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <mach/mach_time.h>
#import "SMEventMIDI.h"
#import "SMEventSysEx.h"
#import "SMEventMeta.h"
#import "SMSeqData.h"
#import "SMMsgTransmitter.h"
#import "SMMsgQueue.h"
#import "SMOutDevCtrlEx.h"
#import "SMCommon.h"
#import "SMEventWatcher.h"


//******************************************************************************
// クラス宣言
//******************************************************************************
//シーケンサスレッドクラス
@class SMSequencerThread;


//******************************************************************************
// シーケンサクラス
//******************************************************************************
class SMSequencer
{
public:
	
	//演奏状態
	enum Status {
		StatusPlay,
		StatusPause,
		StatusStop
	};
	
	//ユーザ要求
	enum UserRequest {
		RequestNone,
		RequestPause,
		RequestStop,
		RequestSkip
	};
	
	//コンストラクタ／デストラクタ
	SMSequencer(void);
	virtual ~SMSequencer(void);
	
	//初期化
	int Initialize(SMMsgQueue* pMsgQueue);
	
	//ポート対応デバイス登録
	int SetPortDev(unsigned char portNo, NSString* pIdName);
	
	//シーケンスデータ登録
	int SetSeqData(SMSeqData* pSeqData);
	
	//演奏開始
	int Play();
	
	//演奏一時停止
	void Pause();
	
	//演奏再開
	int Resume();
	
	//演奏停止
	void Stop();
	
	//再生スピード設定
	void SetPlaybackSpeed(unsigned long nTimes); //n倍速
	void SetPlaySpeedRatio(unsigned long ratio); //パーセント
	
	//リワインド／スキップ移動時間設定
	void SetMovingTimeSpanInMsec(unsigned long timeSpan);
	
	//演奏位置変更
	int Skip(int relativeTimeInMsec);
	
	//演奏スレッドインターバル処理
	//  シーケンサスレッドが利用するため一般利用者は使用しないこと
	int IntervalProc(BOOL* pIsContinue);
	
	//1ミリ秒取得
	//  シーケンサスレッドが利用するため一般利用者は使用しないこと
	double GetMachMilliSecond();
	
	//ユーザ要求処理
	//  シーケンサスレッドが利用するため一般利用者は使用しないこと
	int ProcUserRequest(BOOL* pIsContinue);
	
private:
	
	//演奏状態
	Status m_Status;
	unsigned long m_PlayIndex;
	UserRequest m_UserRequest;
	SMMsgTransmitter m_MsgTrans;
	SMMsgQueue* m_pMsgQue;
	SMEventWatcher m_EventWatcher;
	
	//MIDIデバイス系
	SMOutDevCtrlEx m_OutDevCtrl;
	unsigned char m_PortNo;
	NSString* m_PortDevIdList[SM_MIDIOUT_PORT_NUM_MAX];
	
	//MIDIデータ系
	SMSeqData* m_pSeqData;
	SMTrack m_Track;
	SMEvent m_Event;
	
	//タイマー制御系
	mach_timebase_info_data_t m_TimebaseInfo;
	double m_MachMilliSecond;
	unsigned long m_TimeDivision;
	unsigned long m_Tempo;
	uint64_t m_PrevTimerTime;
	uint64_t m_CurPlayTime;
	uint64_t m_PrevEventTime;
	double m_NextEventTime;
	uint64_t m_NextNtcTime;
	unsigned long m_PrevDeltaTime;
	unsigned long m_TotalTickTime;
	unsigned long m_TotalTickTimeTemp;
	unsigned long m_PlaybackSpeed;
	double m_PlaySpeedRatio;
	
	//小節番号制御系
	unsigned long m_TickTimeOfBar;
	unsigned long m_CurBarNo;
	unsigned long m_PrevBarTickTime;
	
	//拍子記号
	unsigned long m_BeatNumerator;
	unsigned long m_BeatDenominator;
	
	//スキップ制御
	bool m_isSkipping;
	uint64_t m_SkipTargetTime;
	unsigned long m_NotesCount;
	unsigned long m_MovingTimeSpanInMsec;
	unsigned char m_CachePitchBend[SM_MAX_PORT_NUM][SM_MAX_CH_NUM][2];
	unsigned char m_CacheCC001_Modulation[SM_MAX_PORT_NUM][SM_MAX_CH_NUM];
	unsigned char m_CacheCC007_Volume[SM_MAX_PORT_NUM][SM_MAX_CH_NUM];
	unsigned char m_CacheCC010_Panpot[SM_MAX_PORT_NUM][SM_MAX_CH_NUM];
	unsigned char m_CacheCC011_Expression[SM_MAX_PORT_NUM][SM_MAX_CH_NUM];
	
	//シーケンサスレッド
	SMSequencerThread* m_pSequencerThread;
	
	//タイマーデバイス処理
	int _InitializeTimerDev();
	int _ReleaseTimerDev();
	
	//ポート制御
	void _ClearPortInfo();
	int _OpenMIDIOutDev();
	int _CloseMIDIOutDev();
	
	//再生制御
	int _InitializeParamsOnPlayStart();
	
	//時間制御
	int _UpdatePlayPosition();
	double _ConvTick2TimeNanosec(unsigned long tickTime);
	unsigned long _ConvTimeNanosec2Tick(uint64_t timeNanosec);
	uint64_t _GetCurTimeInNano();
	
	//MIDI出力処理
	int _OutputMIDIEvent(unsigned char portNo, SMEvent* pEvent);
	int _SendMIDIEvent(unsigned char portNo, SMEventMIDI* pMIDIEvent);
	int _SendSysExEvent(unsigned char portNo, SMEventSysEx* pSysExEvent);
	int _SendMetaEvent(unsigned char portNo, SMEventMeta* pMetaEvent);
	int _AllTrackNoteOff();
	
	//スキップ制御
	void _ClearMIDIEventCache();
	int _FilterMIDIEvent(unsigned char portNo, SMEventMIDI* pMIDIEvent, bool* pIsFiltered);
	int _SendMIDIEventCache();
	int _SendMIDIEventPitchBend(unsigned char portNo, unsigned char chNo, unsigned char* pPtichBend);
	int _SendMIDIEventCC(unsigned char portNo, unsigned char chNo, unsigned char ccNo, unsigned char ccValue);
	int _ProcSkip(uint64_t targetTimeInNanoSec, BOOL* pIsContinue);
	void _SlidePlaybackTime(uint64_t startPlayTime, unsigned long startTickTime, unsigned long endTickTime);
	
protected:
	
	int _OnTimer();
	
private:
	
	//代入とコピーコンストラクタの禁止
	void operator=(const SMSequencer&);
	SMSequencer(const SMSequencer&);

};

//******************************************************************************
// シーケンサスレッドクラス
//******************************************************************************
@interface SMSequencerThread : NSObject {
	SMSequencer* m_pSequencer;
}

//生成
- (id)init;

//破棄
- (void)dealloc;

//シーケンサオブジェクト登録
- (void)setSequencer:(SMSequencer*)pSequencer;

//スレッド実行
- (void)run;

@end


