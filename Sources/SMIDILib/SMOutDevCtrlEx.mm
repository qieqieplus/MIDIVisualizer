//******************************************************************************
//
// Simple MIDI Library / SMOutDevCtrlEx
//
// 拡張MIDI出力デバイス制御クラス
//
// Copyright (C) 2010-2014 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "SMOutDevCtrlEx.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
SMOutDevCtrlEx::SMOutDevCtrlEx()
{
	unsigned char portNo = 0;
	
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		m_PortType[portNo] = PortNone;
	}
}

//******************************************************************************
// デストラクタ
//******************************************************************************
SMOutDevCtrlEx::~SMOutDevCtrlEx()
{
}

//******************************************************************************
// 初期化
//******************************************************************************
int SMOutDevCtrlEx::Initialize()
{
	int result = 0;
	
	result = ClearPortInfo();
	if (result != 0) goto EXIT;
	
	result = m_AppleDLSDevCtrl.Initialize();
	if (result != 0) goto EXIT;
	
	result = m_OutDevCtrl.Initialize();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイス数取得
//******************************************************************************
unsigned long SMOutDevCtrlEx::GetDevNum()
{
	unsigned long devNum = 0;
	
	//Apple DLSデバイスをカウントする
	devNum = 1;
	
	//CoreMIDI出力デバイス数を加算する
	devNum += m_OutDevCtrl.GetDevNum();
	
	return devNum;
}

//******************************************************************************
// デバイス表示名称取得
//******************************************************************************
NSString* SMOutDevCtrlEx::GetDevDisplayName(
		unsigned long index
	)
{
	NSString* pDisplayName = nil;
	
	if (index == 0) {
		pDisplayName = SM_APPLE_DLS_DISPLAY_NAME;
	}
	else {
		pDisplayName = m_OutDevCtrl.GetDevDisplayName(index - 1);
	}
	
	return pDisplayName;
}

//******************************************************************************
// デバイス識別名取得
//******************************************************************************
NSString* SMOutDevCtrlEx::GetDevIdName(
		unsigned long index
	)
{
	NSString* pDevIdName = nil;
	
	if (index == 0) {
		pDevIdName = SM_APPLE_DLS_DEVID_NAME;
	}
	else {
		pDevIdName = m_OutDevCtrl.GetDevIdName(index - 1);
	}
	
	return pDevIdName;
}

//******************************************************************************
// ポート対応デバイス登録
//******************************************************************************
int SMOutDevCtrlEx::SetDevForPort(
		unsigned char portNo,
		NSString* pIdName
	)
{
	int result = 0;
	
	if (portNo >= SM_MIDIOUT_PORT_NUM_MAX) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	
	if ([pIdName isEqualToString:SM_APPLE_DLS_DEVID_NAME]) {
		m_PortType[portNo] = PortAppleDLSDevice;
	}
	else {
		m_PortType[portNo] = PortCoreMIDIDevice;
		result = m_OutDevCtrl.SetDevForPort(portNo, pIdName);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 全デバイスのオープン
//******************************************************************************
int SMOutDevCtrlEx::OpenPortDevAll()
{
	int result = 0;
	
	result = m_AppleDLSDevCtrl.Open();
	if (result != 0) goto EXIT;
	
	result = m_OutDevCtrl.OpenPortDevAll();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 全デバイスのクローズ
//******************************************************************************
int SMOutDevCtrlEx::ClosePortDevAll()
{
	int result = 0;
	
	result = m_AppleDLSDevCtrl.Close();
	if (result != 0) goto EXIT;
	
	result = m_OutDevCtrl.ClosePortDevAll();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// ポート情報クリア
//******************************************************************************
int SMOutDevCtrlEx::ClearPortInfo()
{
	int result = 0;
	unsigned char portNo = 0;
	
	result = m_OutDevCtrl.ClearPortInfo();
	if (result != 0) goto EXIT;
	
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		m_PortType[portNo] = PortNone;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIデータ送信（ショートメッセージ）
//******************************************************************************
int SMOutDevCtrlEx::SendShortMsg(
		unsigned char portNo,
		unsigned char* pMsg,
		unsigned long size
	)
{
	int result = 0;
	
	if (portNo >= SM_MIDIOUT_PORT_NUM_MAX) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	
	if (m_PortType[portNo] == PortAppleDLSDevice) {
		result = m_AppleDLSDevCtrl.SendShortMsg(pMsg, size);
		if (result != 0) goto EXIT;
	}
	else if (m_PortType[portNo] == PortCoreMIDIDevice) {
		result = m_OutDevCtrl.SendShortMsg(portNo, pMsg, size);
		if (result != 0) goto EXIT;
	}
	else {
		//出力先が指定されていないポートに対するデータ送信のため無視する
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIデータ送信（ロングメッセージ）
//******************************************************************************
int SMOutDevCtrlEx::SendLongMsg(
		unsigned char portNo,
		unsigned char* pMsg,
		unsigned long size
	)
{
	int result = 0;
	
	if (portNo >= SM_MIDIOUT_PORT_NUM_MAX) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	
	if (m_PortType[portNo] == PortAppleDLSDevice) {
		result = m_AppleDLSDevCtrl.SendLongMsg(pMsg, size);
		if (result != 0) goto EXIT;
	}
	else if (m_PortType[portNo] == PortCoreMIDIDevice) {
		result = m_OutDevCtrl.SendLongMsg(portNo, pMsg, size);
		if (result != 0) goto EXIT;
	}
	else {
		//出力先が指定されていないポートに対するデータ送信のため無視する
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 全ポートノートオフ
//******************************************************************************
int SMOutDevCtrlEx::NoteOffAll()
{
	int result = 0;
	
	result = m_AppleDLSDevCtrl.NoteOffAll();
	if (result != 0) goto EXIT;
	
	result = m_OutDevCtrl.NoteOffAll();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}


