//******************************************************************************
//
// Simple MIDI Library / SMOutDevCtrl
//
// MIDI出力デバイス制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "SMOutDevCtrl.h"


//******************************************************************************
// グローバル定義
//******************************************************************************
//MIDISendSysex処理完了コールバック関数
void SysexSendcompletionProc(MIDISysexSendRequest *request);

//スレッド同期用
static NSCondition* g_pSendCompleteCondition = nil;
static int g_RefCount = 0;


//******************************************************************************
// コンストラクタ
//******************************************************************************
SMOutDevCtrl::SMOutDevCtrl(void)
{
	unsigned char portNo = 0;
	
	//ポート情報
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		m_PortInfo[portNo].isExist = NO;
		m_PortInfo[portNo].endpointRef = 0;
		m_PortInfo[portNo].portRef = 0;
	}
	
	//MIDIクライアント
	m_ClientRef = 0;
	
	//スレッド同期オブジェクト
	if (g_RefCount == 0) {
		g_pSendCompleteCondition = [[NSCondition alloc] init];
	}
	g_RefCount++;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
SMOutDevCtrl::~SMOutDevCtrl()
{
	SMDevInfo* pDevInfo = NULL;
	SMOutDevListItr itr;
	
	for (itr = m_OutDevList.begin(); itr != m_OutDevList.end(); itr++) {
		pDevInfo = *itr;
		delete pDevInfo;
	}
	m_OutDevList.clear();
	
	g_RefCount--;
	if (g_RefCount == 0) {
		[g_pSendCompleteCondition release];
	}
	MIDIClientDispose(m_ClientRef);
}

//******************************************************************************
// 初期化
//******************************************************************************
int SMOutDevCtrl::Initialize()
{
	int result = 0;
	OSStatus err;
	
	//ハードウェア再スキャン
	//MIDIRestart();
	
	//ポート情報クリア
	result = ClearPortInfo();
	if (result != 0) goto EXIT;
	
	//MIDI出力デバイス一覧を作成
	//  MIDIGetNumberOfDevices, MIDIGetDevice を用いてエンドポイントを検索する
	//  ・オフラインのデバイス：○検索結果に含まれる
	//  ・仮想ポート        ：×検索結果に含まれない
	//result = _InitDevList();
	//if (result != 0) goto EXIT;
	
	//MIDI出力デバイス一覧を作成
	//  MIDIGetNumberOfDestinations, MIDIGetDestination を用いてエンドポイントを検索する
	//  ・オフラインのデバイス：×検索結果に含まれない
	//  ・仮想ポート        ：○検索結果に含まれる
	result = _InitDevListWithVitualDest();
	if (result != 0) goto EXIT;
	
	//MIDIクライアント生成
	if (m_ClientRef != 0) {
		MIDIClientDispose(m_ClientRef);
		m_ClientRef = 0;
	}
	err = MIDIClientCreate(
				CFSTR("MIDITrail Client"),	//クライアント名称
				NULL,					//MIDIシステム変更通知用コールバック関数
				NULL,					//通知オブジェクト
				&m_ClientRef			//作成されたクライアント
			);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI client create error.", 0, 0);
		goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイスリスト初期化
//******************************************************************************
int SMOutDevCtrl::_InitDevList()
{
	int result = 0;
	ItemCount devNum = 0;
	ItemCount devIndex = 0;
	SMOutDevListItr itr;
	SMDevInfo* pDevInfo = NULL;
	
	//デバイスリストクリア
	for (itr = m_OutDevList.begin(); itr != m_OutDevList.end(); itr++) {
		pDevInfo = *itr;
		delete pDevInfo;
	}
	m_OutDevList.clear();
	
	//デバイスの数
	//  プロセス起動後の初回API呼び出しで1秒以上引っかかる
	//  2回目以降は瞬時に終わる
	devNum = MIDIGetNumberOfDevices();
	
	//デバイスごとにループして出力先情報を取得する
	for (devIndex = 0; devIndex < devNum; devIndex++) {
		result = _CheckDev(devIndex);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイスリスト初期化：デバイスチェック
//******************************************************************************
int SMOutDevCtrl::_CheckDev(
		ItemCount index
	)
{
	int result = 0;
	ItemCount entNum = 0;
	ItemCount entIndex = 0;
	MIDIDeviceRef devRef = 0;
	
	//デバイス取得
	devRef = MIDIGetDevice(index);
	
	//デバイスが保有するエンティティの数
	entNum = MIDIDeviceGetNumberOfEntities(devRef);
	
	//エンティティごとにループして出力先情報を取得する
	for (entIndex = 0; entIndex < entNum; entIndex++) {
		result = _CheckEnt(entIndex, devRef);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイスリスト初期化：エンティティチェック
//******************************************************************************
int SMOutDevCtrl::_CheckEnt(
		ItemCount index,
		MIDIDeviceRef devRef
	)
{
	int result = 0;
	ItemCount destNum = 0;
	ItemCount destIndex = 0;
	MIDIEntityRef entityRef = 0;
	MIDIEndpointRef endpointRef = 0;
	
	//エンティティ取得
	entityRef = MIDIDeviceGetEntity(devRef, index);
	
	//出力先の数
	destNum= MIDIEntityGetNumberOfDestinations(entityRef);
	
	//出力先ごとにループして出力先情報を取得する
	for (destIndex = 0; destIndex < destNum; destIndex++) {
		//エンドポイント取得
		endpointRef = MIDIEntityGetDestination(entityRef, index);
		
		//エンドポイント確認
		result = _CheckEnd(endpointRef);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイスリスト初期化：エンドポイントチェック
//******************************************************************************
int SMOutDevCtrl::_CheckEnd(
		MIDIEndpointRef endpointRef
	)
{
	int result = 0;
	OSStatus err;
	CFStringRef strDisplayNameRef = NULL;
	CFStringRef strManufacturerRef = NULL;
	CFStringRef strModelRef = NULL;
	CFStringRef strNameRef = NULL;
	SInt32 isOffline = YES;
	NSString* pDisplayName = nil;
	NSString* pIdName = nil;
	NSString* pManufacturerName = nil;
	SMDevInfo* pDevInfo = NULL;
	
	//表示名称 ex. "UM-2G 1" ＜「Audio MIDI 設定」でユーザが自由に変更できる
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyDisplayName, &strDisplayNameRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	//メーカー名 ex."Roland"
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyManufacturer, &strManufacturerRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	//モデル ex. "UM-2G"
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyModel, &strModelRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	//エンドポイント名 ex. "1"
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyName, &strNameRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	
	//出力先の接続状態
	err = MIDIObjectGetIntegerProperty(endpointRef, kMIDIPropertyOffline, &isOffline);
	if (err == kMIDIUnknownProperty) {
		//プロパティが存在しない場合はオンラインとみなす
		isOffline = NO;
	}
	else if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	
	//表示名を作成：オフラインの場合は末尾に(offline)を追加する
	pDisplayName = (NSString*)strDisplayNameRef;
	if (isOffline) {
		pDisplayName = [NSString stringWithFormat:@"%@ (offline)", (NSString*)strDisplayNameRef];
	}
	
	//識別名を作成 ex. "Roland/UM-2G/1"
	pIdName = [NSString stringWithFormat:@"%@/%@/%@",
					(NSString*)strManufacturerRef,
					(NSString*)strModelRef,
					(NSString*)strNameRef];
	
	//NSLog(@"MIDI OUT Device IdName: %@", pIdName);
	
	//メーカー名
	pManufacturerName = (NSString*)strManufacturerRef;
	
	//デバイス情報の作成
	try {
		pDevInfo = new SMDevInfo();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	pDevInfo->SetDisplayName(pDisplayName);
	pDevInfo->SetIdName(pIdName);
	pDevInfo->SetManufacturerName(pManufacturerName);
	pDevInfo->SetEndpointRef(endpointRef);
	pDevInfo->SetOnline(!isOffline);
	
	//デバイスリストに登録
	m_OutDevList.push_back(pDevInfo);
	pDevInfo = NULL;
	
EXIT:;
	if (strDisplayNameRef != NULL) CFRelease(strDisplayNameRef);
	if (strManufacturerRef != NULL) CFRelease(strManufacturerRef);
	if (strModelRef != NULL) CFRelease(strModelRef);
	if (strNameRef != NULL) CFRelease(strNameRef);
	return result;
}

//******************************************************************************
// デバイスリスト初期化：オフラインデバイスなし＋仮想ポートあり
//******************************************************************************
int SMOutDevCtrl::_InitDevListWithVitualDest()
{
	int result = 0;
	ItemCount destNum = 0;
	ItemCount index = 0;
	SMOutDevListItr itr;
	SMDevInfo* pDevInfo = NULL;
	MIDIEndpointRef endpointRef = 0;
	
	//デバイスリストクリア
	for (itr = m_OutDevList.begin(); itr != m_OutDevList.end(); itr++) {
		pDevInfo = *itr;
		delete pDevInfo;
	}
	m_OutDevList.clear();
	
	//出力先ポート数の取得
	destNum = MIDIGetNumberOfDestinations();
	
	//デバイスごとにループして出力先情報を取得する
	for (index = 0; index < destNum; index++) {
		//エンドポイント取得
		endpointRef = MIDIGetDestination(index);
		
		//エンドポイント確認		
		result = _CheckDest(endpointRef);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイスリスト初期化：出力ポート確認
//******************************************************************************
int SMOutDevCtrl::_CheckDest(
		MIDIEndpointRef endpointRef
	)
{
	int result = 0;
	OSStatus err;
	CFStringRef strDisplayNameRef = NULL;
	CFStringRef strManufacturerRef = NULL;
	CFStringRef strModelRef = NULL;
	CFStringRef strNameRef = NULL;
	SInt32 isOffline = YES;
	NSString* pDisplayName = nil;
	NSString* pIdName = nil;
	NSString* pManufacturerName = nil;
	SMDevInfo* pDevInfo = NULL;
	
	//表示名称 ex. "UM-2G 1" ＜「Audio MIDI 設定」でユーザが自由に変更できる
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyDisplayName, &strDisplayNameRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	
	//メーカー名 ex."Roland"
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyManufacturer, &strManufacturerRef);
	if (err != noErr) {
		if (err == kMIDIUnknownProperty) {
			//仮想ポートの場合は取得できない場合がある
			strManufacturerRef = CFSTR("");
		}
		else {
			result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
			goto EXIT;
		}
	}
	//モデル ex. "UM-2G"
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyModel, &strModelRef);
	if (err != noErr) {
		if (err == kMIDIUnknownProperty) {
			//仮想ポートの場合は取得できない場合がある
			strModelRef = CFSTR("");
		}
		else {
			result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
			goto EXIT;
		}
	}
	//エンドポイント名 ex. "1"
	err = MIDIObjectGetStringProperty(endpointRef, kMIDIPropertyName, &strNameRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
		goto EXIT;
	}
	
	//出力先の接続状態
	err = MIDIObjectGetIntegerProperty(endpointRef, kMIDIPropertyOffline, &isOffline);
	if (err != noErr) {
		if (err == kMIDIUnknownProperty) {
			//仮想ポートの場合は取得できない場合がある
			isOffline = NO;
		}
		else {
			result = YN_SET_ERR(@"CoreMIDI API Error", err, 0);
			goto EXIT;
		}
	}
	
	//表示名を作成：オフラインの場合は末尾に(offline)を追加する
	pDisplayName = (NSString*)strDisplayNameRef;
	if (isOffline) {
		pDisplayName = [NSString stringWithFormat:@"%@ (offline)", (NSString*)strDisplayNameRef];
	}
	
	//識別名を作成 ex. "Roland/UM-2G/1"
	pIdName = [NSString stringWithFormat:@"%@/%@/%@",
			   (NSString*)strManufacturerRef,
			   (NSString*)strModelRef,
			   (NSString*)strNameRef];
	
	//NSLog(@"MIDI OUT Device IdName: %@", pIdName);
	
	//メーカー名
	pManufacturerName = (NSString*)strManufacturerRef;
	
	//デバイス情報の作成
	try {
		pDevInfo = new SMDevInfo();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	pDevInfo->SetDisplayName(pDisplayName);
	pDevInfo->SetIdName(pIdName);
	pDevInfo->SetManufacturerName(pManufacturerName);
	pDevInfo->SetEndpointRef(endpointRef);
	pDevInfo->SetOnline(!isOffline);
	
	//デバイスリストに登録
	m_OutDevList.push_back(pDevInfo);
	pDevInfo = NULL;
	
EXIT:;
	if (strDisplayNameRef != NULL) CFRelease(strDisplayNameRef);
	if (strManufacturerRef != NULL) CFRelease(strManufacturerRef);
	if (strModelRef != NULL) CFRelease(strModelRef);
	if (strNameRef != NULL) CFRelease(strNameRef);
	return result;
}

//******************************************************************************
// デバイス数取得
//******************************************************************************
unsigned long SMOutDevCtrl::GetDevNum()
{
	return m_OutDevList.size();
}

//******************************************************************************
// デバイス表示名称取得
//******************************************************************************
NSString* SMOutDevCtrl::GetDevDisplayName(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	NSString* pDisplayName = nil;
	SMOutDevListItr itr;
	
	if (index < m_OutDevList.size()) {
		itr = m_OutDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		pDisplayName = pDevInfo->GetDisplayName();
	}
	
	return pDisplayName;
}

//******************************************************************************
// デバイス識別名称取得
//******************************************************************************
NSString* SMOutDevCtrl::GetDevIdName(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	NSString* pIdName = nil;
	SMOutDevListItr itr;
	
	if (index < m_OutDevList.size()) {
		itr = m_OutDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		pIdName = pDevInfo->GetIdName();
	}
	
	return pIdName;
}

//******************************************************************************
// メーカー名取得
//******************************************************************************
NSString* SMOutDevCtrl::GetManufacturerName(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	NSString* pManufacturerName = nil;
	SMOutDevListItr itr;
	
	if (index < m_OutDevList.size()) {
		itr = m_OutDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		pManufacturerName = pDevInfo->GetManufacturerName();
	}
	
	return pManufacturerName;
}

//******************************************************************************
// オンライン状態取得
//******************************************************************************
bool SMOutDevCtrl::IsOnline(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	bool isOnline = false;
	SMOutDevListItr itr;
	
	if (index < m_OutDevList.size()) {
		itr = m_OutDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		isOnline = pDevInfo->IsOnline();
	}
	
	return isOnline;
}

//******************************************************************************
// ポートに対応するデバイスを設定
//******************************************************************************
int SMOutDevCtrl::SetDevForPort(
		unsigned char portNo,
		NSString* pIdName
	)
{
	int result = 0;
	bool isFound = false;
	SMDevInfo* pDevInfo = NULL;
	SMOutDevListItr itr;
	
	if (portNo >= SM_MIDIOUT_PORT_NUM_MAX) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//出力デバイスリストから指定デバイスを探す
	for (itr = m_OutDevList.begin(); itr != m_OutDevList.end(); itr++) {
		pDevInfo = *itr;
		
		//デバイスがオフラインであれば無視する
		if (!(pDevInfo->IsOnline())) continue;
		
		if ([pIdName isEqualToString:(pDevInfo->GetIdName())]) {
			//指定デバイスが見つかったのでポートに情報を登録する
			m_PortInfo[portNo].isExist = true;
			m_PortInfo[portNo].endpointRef = pDevInfo->GetEndpointRef();
			m_PortInfo[portNo].portRef = 0;
			isFound = true;
			break;
		}
	}
	
	//指定デバイスが見つからないかオフラインの場合は何もしない
	if (!isFound) {
		//result = YN_SET_ERR(@"Program error.", portNo, 0);
		//goto EXIT;
		NSLog(@"MIDI OUT - Device not found.");
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 全ポートに対応するデバイスを開く
//******************************************************************************
int SMOutDevCtrl::OpenPortDevAll()
{
	int result = 0;
	OSStatus err;
	unsigned char portNo = 0;
	unsigned char prevPortNo = 0;
	bool isOpen = false;
	MIDIPortRef portRef = 0;
	
	result = ClosePortDevAll();
	if (result != 0) goto EXIT;
	
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		
		//ポートが存在しなければスキップ
		if (!m_PortInfo[portNo].isExist) continue;
		
		//別のポートで同じデバイスをすでに開いている場合の対処
		isOpen = false;
		for (prevPortNo = 0; prevPortNo < portNo; prevPortNo++) {
			if (m_PortInfo[portNo].endpointRef == m_PortInfo[prevPortNo].endpointRef) {
				m_PortInfo[portNo].portRef = m_PortInfo[prevPortNo].portRef;
				isOpen = true;
				break;
			}
		}
		
		//新規にポートを開く
		if (!isOpen) {
			err = MIDIOutputPortCreate(
						m_ClientRef,		//MIDIクライアント
						CFSTR("MIDITrail Port"),	//ポート名称
						&portRef			//作成されたポート
					);
			if (err != noErr) {
				result = YN_SET_ERR(@"MIDI port open error.", 0, 0);
			}
			m_PortInfo[portNo].portRef = portRef;
		}
	}

EXIT:;
	return result;
}

//******************************************************************************
// 全ポートに対応するデバイスを閉じる
//******************************************************************************
int SMOutDevCtrl::ClosePortDevAll()
{
	int result = 0;
	OSStatus err;
	unsigned char portNo = 0;
	unsigned char nextPortNo = 0;
	
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		
		//ポートが存在しなければスキップ
		if (!m_PortInfo[portNo].isExist) continue;
		
		//ポートを開いてなければスキップ
		if (m_PortInfo[portNo].portRef == 0) continue;
		
		//ポートを閉じる
		err = MIDIPortDispose(m_PortInfo[portNo].portRef);
		if (err != noErr) {
			result = YN_SET_ERR(@"MIDI port close error.", 0, 0);
			goto EXIT;
		}
		m_PortInfo[portNo].portRef = 0;
		
		//別のポートで同じデバイスを開いている場合の対処
		for (nextPortNo = portNo+1; nextPortNo < SM_MIDIOUT_PORT_NUM_MAX; nextPortNo++) {
			if (m_PortInfo[portNo].endpointRef == m_PortInfo[nextPortNo].endpointRef) {
				m_PortInfo[nextPortNo].portRef = 0;
			}
		}
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// ポート情報クリア
//******************************************************************************
int SMOutDevCtrl::ClearPortInfo()
{
	int result = 0;
	unsigned char portNo = 0;
	
	result = ClosePortDevAll();
	if (result != 0) goto EXIT;
	
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		m_PortInfo[portNo].isExist = NO;
		m_PortInfo[portNo].endpointRef = 0;
		m_PortInfo[portNo].portRef = 0;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIデータ送信（ショートメッセージ）
//******************************************************************************
int SMOutDevCtrl::SendShortMsg(
		unsigned char portNo,
		unsigned char* pMsg,
		unsigned long size
	)
{
	int result = 0;
	OSStatus err;
	ByteCount bufSize = 1024;
	Byte packetListBuf[1024];
	MIDIPacketList* pPacketList = NULL;
	MIDIPacket* pPacket = NULL;
	
	//パラメータチェック
	if ((portNo >= SM_MIDIOUT_PORT_NUM_MAX) || (size == 0) || (size > 4)) {
		result = YN_SET_ERR(@"Program error.", portNo, size);
		goto EXIT;
	}
	
	//ポートが存在しなければ何もしない
	if (!m_PortInfo[portNo].isExist) goto EXIT;
	
	//ポートが開かれていなければエラー
	if (m_PortInfo[portNo].portRef == 0) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	
    //パケットリスト初期化
	pPacketList = (MIDIPacketList*)packetListBuf;
	pPacket = MIDIPacketListInit(pPacketList);
	if (pPacket == NULL) {
		result = YN_SET_ERR(@"Program error.", (unsigned long)pMsg, size);
		goto EXIT;
	}
	//パケットリスト作成：1パケットのみ
	//  イベント発生時刻に将来の時間を設定することにより、
	//  イベント送信処理のスケジューリングをOSに任せることが推奨されているが、
	//  下記理由により即時送信とする。（スケジューリングはアプリで実施する）
	//  よってこの送信方法はトリッキーである。
	//  (1) スケジューリングをOSに任せると動画との同期方式が変わるため修正範囲が広がる
	//  (2) Windows版の実装とできるだけ合わせることにより工数を削減する
	//  スケジューリングをアプリで行う場合は現在時刻を取得して未来の時刻を作成する必要がある
	//  MIDITimeStamp time = AudioGetCurrentHostTime();
	pPacket = MIDIPacketListAdd(
					pPacketList,	//パケットリストバッファ
					bufSize,		//バッファサイズ
					pPacket,		//現在のパケット
					0,				//イベント発生時刻：即時
					size,			//イベントデータサイズ（バイト）
					(Byte*)pMsg		//イベントデータ（ランニングステータスは許されない）
				);
	if (pPacket == NULL) {
		result = YN_SET_ERR(@"Program error.", (unsigned long)pMsg, size);
		goto EXIT;
	}
	
	//メッセージ出力
	//  出力先デバイスがオフラインであってもAPIは正常終了する
	err = MIDISend(
				m_PortInfo[portNo].portRef,
				m_PortInfo[portNo].endpointRef,
				pPacketList
			);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI OUT device output error.", (unsigned long)pMsg, size);
		goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIデータ送信（ロングメッセージ）
//******************************************************************************
int SMOutDevCtrl::SendLongMsg(
		unsigned char portNo,
		unsigned char* pMsg,
		unsigned long size
	)
{
	int result = 0;
	OSStatus err;
	MIDISysexSendRequest sysexSendReq;
	
	//パラメータチェック
	if (portNo >= SM_MIDIOUT_PORT_NUM_MAX) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	if ((pMsg == NULL) || (size == 0)) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ポートが存在しなければ何もしない
	if (!m_PortInfo[portNo].isExist) goto EXIT;
	
	//エンドポイントが開かれていなければエラー
	if (m_PortInfo[portNo].endpointRef == 0) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	
	//ポートが開かれていなければエラー
	if (m_PortInfo[portNo].portRef == 0) {
		result = YN_SET_ERR(@"Program error.", portNo, 0);
		goto EXIT;
	}
	
	//システムエクスクルーシブ要求生成
	memset(&sysexSendReq, 0, sizeof(MIDISysexSendRequest));
	//エンドポイント
	sysexSendReq.destination = m_PortInfo[portNo].endpointRef;
	//メッセージ位置
	sysexSendReq.data = (Byte*)pMsg;
	//メッセージサイズ
	sysexSendReq.bytesToSend = size;
	//送信終了時にtrueになる（利用者がtrueを設定することによって送信を中止できる）
	sysexSendReq.complete = false;
	//送信終了時のコールバック関数
	sysexSendReq.completionProc = SysexSendcompletionProc;
	//コールバック関数に渡す参照
	//  サンプルによると構造体自身のポインタを設定するのが普通のようだ
	//  API呼び出し時に自明である値をなぜわざわざ設定する必要があるのか？
	//  別の用途で使えるのだろうか？
	sysexSendReq.completionRefCon = (void*)&sysexSendReq;
	
	//メッセージ出力
	//  MIDISendSysex は MIDISend と以下の点が異なる（なぜ？）
	//    ポートを指定する必要がない
	//    送信時刻を指定できない（即時送信のみ）
	err = MIDISendSysex(&sysexSendReq);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI OUT device output error.", portNo, 0);
		goto EXIT;
	}
	
	//送信処理完了まで待ち合わせる
	[g_pSendCompleteCondition lock];
	[g_pSendCompleteCondition wait];
	[g_pSendCompleteCondition unlock];

EXIT:;
	return result;
}

//******************************************************************************
// 全ポートノートオフ
//******************************************************************************
int SMOutDevCtrl::NoteOffAll()
{
	int result = 0;
	unsigned char i = 0;
	unsigned char msg[3];
	unsigned char portNo = 0;
	
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		
		//ポートが存在しなければスキップ
		if (!m_PortInfo[portNo].isExist) continue;
		if (m_PortInfo[portNo].endpointRef == 0) continue;
		if (m_PortInfo[portNo].portRef == 0) continue;
		
		//全トラックノートオフ
		for (i = 0; i < 16; i++) {
			msg[0] = 0xB0 | i;
			msg[1] = 0x7B;
			msg[2] = 0x00;
			result = SendShortMsg(portNo, msg, 3);
			if (result != 0) goto EXIT;
		}
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDISendSysex処理完了コールバック関数
//******************************************************************************
void SysexSendcompletionProc(
		MIDISysexSendRequest *request
	)
{
	//NSLog(@"SysexSendcompletionProc");
	
	//送信完了まで待機しているシーケンサスレッドを起こす
	[g_pSendCompleteCondition lock];
	[g_pSendCompleteCondition signal];
	[g_pSendCompleteCondition unlock];
}


