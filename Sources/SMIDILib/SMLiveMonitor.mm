//******************************************************************************
//
// Simple MIDI Library / SMLiveMonitor
//
// ライブモニタクラス
//
// Copyright (C) 2012 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "SMLiveMonitor.h"
#import "SMEventMIDI.h"
#import "SMEventSysEx.h"
#import "SMEventSysMsg.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
SMLiveMonitor::SMLiveMonitor(void)
{	
	m_Status = StatusMonitorOFF;
	m_pMsgQue = NULL;
	m_pInPortDevId = nil;
	m_pOutPortDevId = nil;
	m_isMIDITHRU = true;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
SMLiveMonitor::~SMLiveMonitor()
{
	//ポート情報クリア
	_ClearPortInfo();
	
	//MIDIデバイスを閉じる
	_CloseMIDIDev();
}

//******************************************************************************
// 初期化
//******************************************************************************
int SMLiveMonitor::Initialize(SMMsgQueue* pMsgQueue)
{
	int result = 0;
	
	m_pMsgQue = pMsgQueue;	
	
	//MIDI出力デバイス初期化
	result = m_OutDevCtrl.Initialize();
	if (result != 0) goto EXIT;
	
	//MIDI入力デバイス初期化
	result = m_InDevCtrl.Initialize();
	if (result != 0) goto EXIT;
	
	//ポート情報クリア
	_ClearPortInfo();
	
	//イベント転送オブジェクト初期化
	result = m_MsgTrans.Initialize(pMsgQueue);
	if (result != 0) goto EXIT;
	
	//イベントウォッチャー初期化
	result = m_EventWatcher.Initialize(&m_MsgTrans);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 入力ポート対応デバイス登録
//******************************************************************************
int SMLiveMonitor::SetInPortDev(
		NSString* pIdName,
		bool isMIDITHRU
	)
{
	int result = 0;
	
	[pIdName retain];
	[m_pInPortDevId release];
	m_pInPortDevId = pIdName;
	
	m_isMIDITHRU = isMIDITHRU;
	
	return result;
}

//******************************************************************************
// 出力ポート対応デバイス登録
//******************************************************************************
int SMLiveMonitor::SetOutPortDev(NSString* pIdName)
{
	int result = 0;
	
	[pIdName retain];
	[m_pOutPortDevId release];
	m_pOutPortDevId = pIdName;
	
	return result;
}

//******************************************************************************
// 入力ポートデバイス表示名称取得
//******************************************************************************
NSString* SMLiveMonitor::GetInPortDevDisplayName(NSString* pIdName)
{
	unsigned long index = 0;
	NSString* pDisplayName = @"";
	
	if (pIdName == nil) goto EXIT;
	
	for (index = 0; index < m_InDevCtrl.GetDevNum(); index++) {
		if ([pIdName isEqualToString:(m_InDevCtrl.GetDevIdName(index))]) {
			pDisplayName = m_InDevCtrl.GetDevDisplayName(index);
			break;
		}
	}
	
EXIT:;
	return pDisplayName;
}

//******************************************************************************
// モニタ開始
//******************************************************************************
int SMLiveMonitor::Start()
{
	int result = 0;
	
	//モニタ中なら何もしない
	if (m_Status == StatusMonitorON) goto EXIT;
		
	//MIDIデバイスを開く
	result = _OpenMIDIDev();
	if (result != 0) goto EXIT;
	
	m_Status = StatusMonitorON;
	
EXIT:;
	return result;
}

//******************************************************************************
// モニタ停止
//******************************************************************************
int SMLiveMonitor::Stop()
{
	int result = 0;
	
	//全トラックノートオフ
	result = m_OutDevCtrl.NoteOffAll();
	if (result != 0) goto EXIT;
	
	//MIDIデバイスを閉じる
	result = _CloseMIDIDev();
	if (result != 0) goto EXIT;

	m_Status = StatusMonitorOFF;
	
EXIT:;
	return result;
}

//******************************************************************************
// ポート情報クリア
//******************************************************************************
void SMLiveMonitor::_ClearPortInfo()
{
	[m_pInPortDevId release];
	m_pInPortDevId = nil;
	[m_pOutPortDevId release];
	m_pOutPortDevId = nil;	
}

//******************************************************************************
// MIDIデバイスオープン
//******************************************************************************
int SMLiveMonitor::_OpenMIDIDev()
{
	int result = 0;
	
	//出力ポートのデバイスを開く
	if (m_pOutPortDevId != nil) {
		result = m_OutDevCtrl.SetDevForPort(0, m_pOutPortDevId);
		if (result != 0) goto EXIT;
	}	
	result = m_OutDevCtrl.OpenPortDevAll();
	if (result != 0) goto EXIT;
	
	//入力ポートのデバイスを開く
	if (m_pInPortDevId != nil) {
		result = m_InDevCtrl.SetDevForPort(m_pInPortDevId);
		if (result != 0) goto EXIT;
		
		//コールバック登録
		m_InDevCtrl.SetInReadCallBack(_InReadCallBack, this);
	}	
	result = m_InDevCtrl.OpenPortDev();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIデバイスクローズ
//******************************************************************************
int SMLiveMonitor::_CloseMIDIDev()
{
	int result = 0;
	
	//入力ポートのデバイスを閉じる
	result = m_InDevCtrl.ClosePortDev();
	if (result != 0) goto EXIT;
	
	//出力ポートのデバイスを閉じる
	result = m_OutDevCtrl.ClosePortDevAll();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDI IN 読み込みコールバック
//******************************************************************************
int SMLiveMonitor::_InReadCallBack(
		SMEvent* pEvent,
		void* pUserParam
	)
{
	int result = 0;
	SMLiveMonitor* pLiveMonitor = NULL;
	
	pLiveMonitor = (SMLiveMonitor*)pUserParam;
	
	if (pLiveMonitor != NULL) {
		result = pLiveMonitor->_InReadProc(pEvent);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDI IN 読み込み処理
//******************************************************************************
int SMLiveMonitor::_InReadProc(SMEvent* pEvent)
{
	int result = 0;
	
	//MIDIイベントを選別してメッセージキューに登録
	//コントロールチェンジの監視あり
	result = _InReadProcParseEvent(pEvent);
	if (result != 0) goto EXIT;
	
	//MIDI出力デバイスに出力
	result = _InReadProcMIDITHRU(pEvent);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDI IN 読み込み処理：イベント解析
//******************************************************************************
int SMLiveMonitor::_InReadProcParseEvent(SMEvent* pEvent)
{
	int result = 0;
	unsigned char portNo = 0;
	
	//イベントウォッチ
	result = m_EventWatcher.WatchEvent(portNo, pEvent);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDI IN 読み込み処理：MIDITHRU処理　
//******************************************************************************
int SMLiveMonitor::_InReadProcMIDITHRU(SMEvent* pEvent)
{
	int result = 0;
	unsigned char portNo = 0;
	
	//MIDITHRUオフならなにもしない
	if (!m_isMIDITHRU) goto EXIT;
	
	//MIDIイベント送信
	if (pEvent->GetType() == SMEvent::EventMIDI) {
		result = _InReadProcSendMIDIEvent(portNo, pEvent);
		if (result != 0) goto EXIT;
	}
	//システムエクスクルーシブ送信
	else if (pEvent->GetType() == SMEvent::EventSysEx) {
		result = _InReadProcSendSysExEvent(portNo, pEvent);
		if (result != 0) goto EXIT;
	}
	//システムメッセージ送信
	else if (pEvent->GetType() == SMEvent::EventSysMsg) {
		result = _InReadProcSendSysMsgEvent(portNo, pEvent);
		if (result != 0) goto EXIT;
	}
	
EXIT:;	
	return result;
}

//******************************************************************************
// MIDIイベント送信
//******************************************************************************
int SMLiveMonitor::_InReadProcSendMIDIEvent(
		unsigned char portNo,
		SMEvent* pEvent
	)
{
	int result = 0;
	unsigned long msg = 0;
	unsigned long size = 0;
	SMEventMIDI midiEvent;
	
	midiEvent.Attach(pEvent);
	
	//メッセージ取得
	result = midiEvent.GetMIDIOutShortMsg(&msg, &size);
	if (result != 0) goto EXIT;
	
	//メッセージ出力
	result = m_OutDevCtrl.SendShortMsg(portNo, (unsigned char*)&msg, size);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// SysExイベント送信
//******************************************************************************
int SMLiveMonitor::_InReadProcSendSysExEvent(
		unsigned char portNo,
		SMEvent* pEvent
	)
{
	int result = 0;
	unsigned char* pVarMsg = NULL;
	unsigned long size = 0;
	SMEventSysEx sysExEvent;
	
	sysExEvent.Attach(pEvent);
	
	//メッセージ取得
	sysExEvent.GetMIDIOutLongMsg(&pVarMsg, &size);
	
	//メッセージ出力：出力完了まで制御が戻らない
	result = m_OutDevCtrl.SendLongMsg(portNo, pVarMsg, size);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// SysMsgイベント送信
//******************************************************************************
int SMLiveMonitor::_InReadProcSendSysMsgEvent(
		unsigned char portNo,
		SMEvent* pEvent
	)
{
	int result = 0;
	unsigned long msg = 0;
	unsigned long size = 0;
	SMEventSysMsg sysMsgEvent;
	
	sysMsgEvent.Attach(pEvent);
	
	//メッセージ取得
	result = sysMsgEvent.GetMIDIOutShortMsg(&msg, &size);
	if (result != 0) goto EXIT;
	
	//メッセージ出力
	result = m_OutDevCtrl.SendShortMsg(portNo, (unsigned char*)&msg, size);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}



