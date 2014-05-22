//******************************************************************************
//
// Simple MIDI Library / SMLiveMonitor
//
// ライブモニタクラス
//
// Copyright (C) 2012 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "SMEvent.h"
#import "SMMsgQueue.h"
#import "SMMsgTransmitter.h"
#import "SMInDevCtrl.h"
#import "SMOutDevCtrlEx.h"
#import "SMEventWatcher.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************


//******************************************************************************
// ライブモニタクラス
//******************************************************************************
class SMLiveMonitor
{
public:

	//演奏状態
	enum Status {
		StatusMonitorOFF,
		StatusMonitorON
	};
	
	//コンストラクタ／デストラクタ
	SMLiveMonitor(void);
	virtual ~SMLiveMonitor(void);
	
	//初期化
	int Initialize(SMMsgQueue* pMsgQueue);
	
	//ポート対応デバイス登録
	int SetInPortDev(NSString* pIdName, bool isMIDITHRU);
	int SetOutPortDev(NSString* pIdName);
	
	//入力ポートデバイス表示名取得
	NSString* GetInPortDevDisplayName(NSString* pIdName);
	
	//モニタ開始
	int Start();
	
	//モニタ停止
	int Stop();
	
private:
	
	//演奏状態
	Status m_Status;
	SMMsgTransmitter m_MsgTrans;
	SMMsgQueue* m_pMsgQue;
	SMEventWatcher m_EventWatcher;
	
	//MIDIデバイス系
	NSString* m_pInPortDevId;
	NSString* m_pOutPortDevId;
	bool m_isMIDITHRU;
	SMInDevCtrl m_InDevCtrl;
	SMOutDevCtrlEx m_OutDevCtrl;

	//ポート制御
	void _ClearPortInfo();
	int _OpenMIDIDev();
	int _CloseMIDIDev();

	static int _InReadCallBack(SMEvent* pEvent, void* pUserParam);
	int _InReadProc(SMEvent* pEvent);
	int _InReadProcParseEvent(SMEvent* pEvent);
	int _InReadProcMIDITHRU(SMEvent* pEvent);
	int _InReadProcSendMIDIEvent(unsigned char portNo, SMEvent* pEvent);
	int _InReadProcSendSysExEvent(unsigned char portNo, SMEvent* pEvent);
	int _InReadProcSendSysMsgEvent(unsigned char portNo, SMEvent* pEvent);
	
};

