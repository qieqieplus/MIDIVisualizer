//******************************************************************************
//
// Simple MIDI Library / SMInDevCtrl
//
// MIDI入力デバイス制御クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "SMInDevCtrl.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
SMInDevCtrl::SMInDevCtrl(void)
{	
	//ポート情報
	m_PortInfo.isExist = NO;
	m_PortInfo.endpointRef = 0;
	m_PortInfo.portRef = 0;
	
	//MIDIクライアント
	m_ClientRef = 0;
	
	//コールバック関数
	m_pInReadCallBack = NULL;
	m_pCallBackUserParam = NULL;
	
	//パケット解析系
	m_isContinueSysEx = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
SMInDevCtrl::~SMInDevCtrl()
{
	SMDevInfo* pDevInfo = NULL;
	SMInDevListItr itr;
	
	for (itr = m_InDevList.begin(); itr != m_InDevList.end(); itr++) {
		pDevInfo = *itr;
		delete pDevInfo;
	}
	m_InDevList.clear();
	
	MIDIClientDispose(m_ClientRef);
}

//******************************************************************************
// 初期化
//******************************************************************************
int SMInDevCtrl::Initialize()
{
	int result = 0;
	OSStatus err;
	
	//ハードウェア再スキャン
	//MIDIRestart();
	
	//ポート情報クリア
	result = ClearPortInfo();
	if (result != 0) goto EXIT;
	
	//MIDI入力デバイス一覧を作成
	//  MIDIGetNumberOfDevices, MIDIGetDevice を用いてエンドポイントを検索する
	//  ・オフラインのデバイス：○検索結果に含まれる
	//  ・仮想ポート        ：×検索結果に含まれない
	//result = _InitDevList();
	//if (result != 0) goto EXIT;
	
	//MIDI入力デバイス一覧を作成
	//  MIDIGetNumberOfSources, MIDIGetSource を用いてエンドポイントを検索する
	//  ・オフラインのデバイス：×検索結果に含まれない
	//  ・仮想ポート        ：○検索結果に含まれる
	result = _InitDevListWithVitualSrc();
	if (result != 0) goto EXIT;
	
	//MIDIクライアント生成
	if (m_ClientRef != 0) {
		MIDIClientDispose(m_ClientRef);
		m_ClientRef = 0;
	}
	err = MIDIClientCreate(
				CFSTR("MIDITrail Input Client"),	//クライアント名称
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
int SMInDevCtrl::_InitDevList()
{
	int result = 0;
	ItemCount devNum = 0;
	ItemCount devIndex = 0;
	SMInDevListItr itr;
	SMDevInfo* pDevInfo = NULL;
	
	//デバイスリストクリア
	for (itr = m_InDevList.begin(); itr != m_InDevList.end(); itr++) {
		pDevInfo = *itr;
		delete pDevInfo;
	}
	m_InDevList.clear();
	
	//デバイスの数
	//  プロセス起動後の初回API呼び出しで1秒以上引っかかる
	//  2回目以降は瞬時に終わる
	devNum = MIDIGetNumberOfDevices();
	
	//デバイスごとにループして入力元情報を取得する
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
int SMInDevCtrl::_CheckDev(
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
	
	//エンティティごとにループして入力元情報を取得する
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
int SMInDevCtrl::_CheckEnt(
		ItemCount index,
		MIDIDeviceRef devRef
	)
{
	int result = 0;
	ItemCount srcNum = 0;
	ItemCount srcIndex = 0;
	MIDIEntityRef entityRef = 0;
	MIDIEndpointRef endpointRef = 0;
	
	//エンティティ取得
	entityRef = MIDIDeviceGetEntity(devRef, index);
	
	//入力元の数
	srcNum= MIDIEntityGetNumberOfSources(entityRef);
	
	//入力元ごとにループして入力元情報を取得する
	for (srcIndex = 0; srcIndex < srcNum; srcIndex++) {
		//エンドポイント取得
		endpointRef = MIDIEntityGetSource(entityRef, index);
		
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
int SMInDevCtrl::_CheckEnd(
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
	
	//入力元の接続状態
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
	
	//NSLog(@"MIDI IN Device IdName: %@", pIdName);
	
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
	m_InDevList.push_back(pDevInfo);
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
int SMInDevCtrl::_InitDevListWithVitualSrc()
{
	int result = 0;
	ItemCount srcNum = 0;
	ItemCount index = 0;
	SMInDevListItr itr;
	SMDevInfo* pDevInfo = NULL;
	MIDIEndpointRef endpointRef = 0;
	
	//デバイスリストクリア
	for (itr = m_InDevList.begin(); itr != m_InDevList.end(); itr++) {
		pDevInfo = *itr;
		delete pDevInfo;
	}
	m_InDevList.clear();
	
	//入力ポート数の取得
	srcNum = MIDIGetNumberOfSources();
	
	//デバイスごとにループして入力元情報を取得する
	for (index = 0; index < srcNum; index++) {
		//エンドポイント取得
		endpointRef = MIDIGetSource(index);
		
		//エンドポイント確認
		result = _CheckSrc(endpointRef);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デバイスリスト初期化：入力ポート確認
//******************************************************************************
int SMInDevCtrl::_CheckSrc(
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
	
	//入力元の接続状態
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
	
	//NSLog(@"MIDI IN Device IdName: %@", pIdName);
	
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
	m_InDevList.push_back(pDevInfo);
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
unsigned long SMInDevCtrl::GetDevNum()
{
	return m_InDevList.size();
}

//******************************************************************************
// デバイス表示名称取得
//******************************************************************************
NSString* SMInDevCtrl::GetDevDisplayName(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	NSString* pDisplayName = nil;
	SMInDevListItr itr;
	
	if (index < m_InDevList.size()) {
		itr = m_InDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		pDisplayName = pDevInfo->GetDisplayName();
	}
	
	return pDisplayName;
}

//******************************************************************************
// デバイス識別名称取得
//******************************************************************************
NSString* SMInDevCtrl::GetDevIdName(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	NSString* pIdName = nil;
	SMInDevListItr itr;
	
	if (index < m_InDevList.size()) {
		itr = m_InDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		pIdName = pDevInfo->GetIdName();
	}
	
	return pIdName;
}

//******************************************************************************
// メーカー名取得
//******************************************************************************
NSString* SMInDevCtrl::GetManufacturerName(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	NSString* pManufacturerName = nil;
	SMInDevListItr itr;
	
	if (index < m_InDevList.size()) {
		itr = m_InDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		pManufacturerName = pDevInfo->GetManufacturerName();
	}
	
	return pManufacturerName;
}

//******************************************************************************
// オンライン状態取得
//******************************************************************************
bool SMInDevCtrl::IsOnline(
		unsigned long index
	)
{
	SMDevInfo* pDevInfo = NULL;
	bool isOnline = false;
	SMInDevListItr itr;
	
	if (index < m_InDevList.size()) {
		itr = m_InDevList.begin();
		advance(itr, index);
		pDevInfo = *itr;
		isOnline = pDevInfo->IsOnline();
	}
	
	return isOnline;
}

//******************************************************************************
// ポートに対応するデバイスを設定
//******************************************************************************
int SMInDevCtrl::SetDevForPort(
		NSString* pIdName
	)
{
	int result = 0;
	bool isFound = false;
	SMDevInfo* pDevInfo = NULL;
	SMInDevListItr itr;
	
	//入力デバイスリストから指定デバイスを探す
	for (itr = m_InDevList.begin(); itr != m_InDevList.end(); itr++) {
		pDevInfo = *itr;
		
		//デバイスがオフラインであれば無視する
		if (!(pDevInfo->IsOnline())) continue;
		
		if ([pIdName isEqualToString:(pDevInfo->GetIdName())]) {
			//指定デバイスが見つかったのでポートに情報を登録する
			m_PortInfo.isExist = true;
			m_PortInfo.endpointRef = pDevInfo->GetEndpointRef();
			m_PortInfo.portRef = 0;
			isFound = true;
			break;
		}
	}
	
	//指定デバイスが見つからないかオフラインの場合は何もしない
	if (!isFound) {
		//result = YN_SET_ERR(@"Program error.", 0, 0);
		//goto EXIT;
		NSLog(@"MIDI IN - Device not found.");
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIイベント読み込みコールバック関数登録
//******************************************************************************
void SMInDevCtrl::SetInReadCallBack(
		SMInReadCallBack pCallBack,
		void* pUserParam
	)
{
	m_pInReadCallBack = pCallBack;
	m_pCallBackUserParam = pUserParam;
}

//******************************************************************************
// ポートに対応するデバイスを開く
//******************************************************************************
int SMInDevCtrl::OpenPortDev()
{
	int result = 0;
	OSStatus err;
	MIDIPortRef portRef = 0;
	
	result = ClosePortDev();
	if (result != 0) goto EXIT;
	
	//ポートが存在しなければスキップ
	if (!m_PortInfo.isExist) goto EXIT;;
	
	m_isContinueSysEx = false;
	
	err = MIDIInputPortCreate(
				m_ClientRef,		//MIDIクライアント
				CFSTR("MIDITrail Input Port"),	//ポート名称
				_InReadCallBack,	//読み込み処理関数ポインタ
				this,				//読み込み処理関に渡す識別子 -> readProcRefCon
				&portRef			//作成されたポート
			);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI port open error.", 0, 0);
	}
	m_PortInfo.portRef = portRef;
			
	//入力元とポートを接続する
	err = MIDIPortConnectSource(
				portRef,			//ポート
				m_PortInfo.endpointRef,	//エンドポイント
				NULL				//読み込み処理関に渡す識別子 -> srcConnRefCon
			);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI port connect error.", 0, 0);
	}

EXIT:;
	return result;
}

//******************************************************************************
// ポートに対応するデバイスを閉じる
//******************************************************************************
int SMInDevCtrl::ClosePortDev()
{
	int result = 0;
	OSStatus err;
	
	//ポートが存在しなければスキップ
	if (!m_PortInfo.isExist) goto EXIT;
	
	//ポートを開いてなければスキップ
	if (m_PortInfo.portRef == 0) goto EXIT;
	
	//入力元とポートを切断する
	err = MIDIPortDisconnectSource(
				m_PortInfo.portRef,		//ポート
				m_PortInfo.endpointRef	//エンドポイント
			);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI port disconnect error.", 0, 0);
	}
	
	//ポートを閉じる
	err = MIDIPortDispose(m_PortInfo.portRef);
	if (err != noErr) {
		result = YN_SET_ERR(@"MIDI port close error.", 0, 0);
		goto EXIT;
	}
	m_PortInfo.portRef = 0;
			
EXIT:;
	return result;
}

//******************************************************************************
// ポート情報クリア
//******************************************************************************
int SMInDevCtrl::ClearPortInfo()
{
	int result = 0;
	
	result = ClosePortDev();
	if (result != 0) goto EXIT;
	
	m_PortInfo.isExist = NO;
	m_PortInfo.endpointRef = 0;
	m_PortInfo.portRef = 0;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDI IN 読み込みコールバック関数
//******************************************************************************
void SMInDevCtrl::_InReadCallBack(
		const MIDIPacketList *pPacketList,
		void* pReadProcRefCon,
		void* pSrcConnRefCon
	)
{
	int index = 0;
	const MIDIPacket* pPacket = NULL;
	SMInDevCtrl* pInDevCtrl = NULL;
	
	pInDevCtrl = (SMInDevCtrl*)pReadProcRefCon;
	pPacket = &(pPacketList->packet[0]);
	
	if (pInDevCtrl != NULL) {
		for (index = 0; index < pPacketList->numPackets; index++) {
			pInDevCtrl->_InReadProc(pPacket);
			pPacket = MIDIPacketNext(pPacket);
		}
	}
	
	return;
}

//******************************************************************************
// MIDI IN 読み込み処理
//******************************************************************************
void SMInDevCtrl::_InReadProc(const MIDIPacket* pPacket)
{
	int result = 0;
	unsigned long readPos = 0;
	unsigned long dataLength = 0;
	unsigned char status = 0;
	unsigned char* pData = NULL;
	SMEvent event;
	
	//MIDIPacket
	//  MIDITimeStamp timeStamp;
	//  UInt16 length;
	//  Byte data[256];
	//ランニングステータスは許されない
	//システムエクスクルーシブは複数パケットに分割される可能性あり
	
	//パケットからイベントデータに変換
	while (readPos < pPacket->length) {
		if (m_isContinueSysEx) {
			//パケットをまたがるシステムエクスクルーシブ読み込み中の場合
			//  システムエクスクルーシブは1パケット内で他のメッセージと混在しない
			result = _InReadProcSysEx(
							pPacket,
							&m_isContinueSysEx,
							&event
						);
			if (result != 0) goto EXIT;
			readPos = pPacket->length;
		}
		else {
			//通常のメッセージ読み込み処理
			m_isContinueSysEx = false;
			status = pPacket->data[readPos];
			readPos += 1;
			if ((status & 0xF0) != 0xF0) {
				//MIDIメッセージ
				dataLength = _GetMIDIMsgSize(status) - 1;
				if ((readPos + dataLength) > pPacket->length) {
					result = YN_SET_ERR(@"MIDI IN data error.", readPos, pPacket->length);
					goto EXIT;
				}
				pData = (unsigned char*)&(pPacket->data[readPos]);
				event.SetMIDIData(status, pData, dataLength);
				readPos += dataLength;
			}
			else {
				//システムエクスクルーシブ：システムエクスクルーシブは1パケット内で他のメッセージと混在しない
				if (status == 0xF0) {
					result = _InReadProcSysEx(
									pPacket,
									&m_isContinueSysEx,
									&event
								);
					if (result != 0) goto EXIT;
					readPos = pPacket->length;
				}
				//その他システムメッセージ：システムコモンメッセージまたはシステムリアルタイムメッセージ
				else {
					dataLength = _GetSysMsgSize(status) - 1;
					if ((readPos + dataLength) > pPacket->length) {
						result = YN_SET_ERR(@"MIDI IN data error.", readPos, pPacket->length);
						goto EXIT;
					}
					pData = (unsigned char*)&(pPacket->data[readPos]);
					event.SetSysMsgData(status, pData, dataLength);
					readPos += dataLength;
				}
			}
		}
		
		//コールバック呼び出し
		if ((m_pInReadCallBack != NULL) &&
			(event.GetType() != SMEvent::EventNone)) {
			result = m_pInReadCallBack(&event, m_pCallBackUserParam);
			if (result != 0) goto EXIT;
		}
	}
		
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// システムエクスクルーシブ読み込み処理
//******************************************************************************
int SMInDevCtrl::_InReadProcSysEx(
		const MIDIPacket* pPacket,
		bool* pIsContinueSysEx,
		SMEvent* pEvent
	)
{
	int result = 0;
	unsigned char* pData = NULL;
	
	//システムエクスクルーシブ初回読み込み
	if (!(*pIsContinueSysEx)) {
		pData = (unsigned char*)&(pPacket->data[1]);
		result = pEvent->SetSysExData(0xF0, pData, pPacket->length - 1);
		if (result != 0) goto EXIT;
	}
	//2番目以降のパケット
	else {
		pData = (unsigned char*)&(pPacket->data[0]);
		result = pEvent->SetSysExData(0xF7, pData, pPacket->length);
		if (result != 0) goto EXIT;
	}
	
	//システムエクスクルーシブの終端を確認
	if (pPacket->data[(pPacket->length)-1] == 0xF7) {
		//1パケットでシステムエクスクルーシブが閉じる
		*pIsContinueSysEx = false;
	}
	else {
		//末尾が0xF7でなければ次のパケットにデータがまたがる
		*pIsContinueSysEx = true;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIメッセージサイズ取得
//******************************************************************************
unsigned long SMInDevCtrl::_GetMIDIMsgSize(unsigned char status)
{
	unsigned long size = 0;

	switch (status & 0xF0) {
		case 0x80: size = 3; break;  //ノートオフ
		case 0x90: size = 3; break;  //ノートオン
		case 0xA0: size = 3; break;  //ポリフォニックキープレッシャー
		case 0xB0: size = 3; break;  //コントロールチェンジ
		case 0xC0: size = 2; break;  //プログラムチェンジ
		case 0xD0: size = 2; break;  //チャンネルプレッシャー
		case 0xE0: size = 3; break;  //ピッチベンド
		case 0xF0:
			size = _GetSysMsgSize(status);
			break;
	}
	
	return size;
}

//******************************************************************************
// システムメッセージサイズ取得
//******************************************************************************
unsigned long SMInDevCtrl::_GetSysMsgSize(unsigned char status)
{
	unsigned long size = 0;
	
	switch (status) {
		case 0xF0: size = 0; break;  // F0 ... F7 システムエクスクルーシブ
		case 0xF1: size = 2; break;  // F1 dd     システムコモンメッセージ：クオーターフレーム(MTC)
		case 0xF2: size = 3; break;  // F2 dl dm  システムコモンメッセージ：ソングポジションポインタ
		case 0xF3: size = 2; break;  // F3 dd     システムコモンメッセージ：ソングセレクト
		case 0xF4: size = 1; break;  // F4 未定義
		case 0xF5: size = 1; break;  // F5 未定義
		case 0xF6: size = 1; break;  // F6 システムコモンメッセージ：チューンリクエスト
		case 0xF7: size = 1; break;  // F7 エンドオブシステムエクスクルーシブ
		case 0xF8: size = 1; break;  // F8 システムリアルタイムメッセージ：タイミングクロック
		case 0xF9: size = 1; break;  // F9 未定義
		case 0xFA: size = 1; break;  // FA システムリアルタイムメッセージ：スタート
		case 0xFB: size = 1; break;  // FB システムリアルタイムメッセージ：コンティニュー
		case 0xFC: size = 1; break;  // FC システムリアルタイムメッセージ：ストップ
		case 0xFD: size = 1; break;  // FD 未定義
		case 0xFE: size = 1; break;  // FE システムリアルタイムメッセージ：アクティブセンシング
		case 0xFF: size = 1; break;  // FF システムリアルタイムメッセージ：システムリセット
	}
	
	return size;
}


