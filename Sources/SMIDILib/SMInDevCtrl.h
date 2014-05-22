//******************************************************************************
//
// Simple MIDI Library / SMInDevCtrl
//
// MIDI入力デバイス制御クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <CoreMIDI/CoreMIDI.h>
#import <list>
#import "SMDevInfo.h"
#import "SMEvent.h"

#pragma warning(disable:4251)


//******************************************************************************
// パラメータ定義
//******************************************************************************
//MIDIイベント読み込みコールバック関数
typedef int (*SMInReadCallBack)(SMEvent* pEvent, void* pUserParam);


//******************************************************************************
// MIDI入力デバイス制御クラス
//******************************************************************************
class SMInDevCtrl
{
public:
	
	//コンストラクタ／デストラクタ
	SMInDevCtrl(void);
	virtual ~SMInDevCtrl(void);
	
	//初期化
	int Initialize();
	
	//デバイス数取得
	unsigned long GetDevNum();
	
	//デバイス表示名称取得
	NSString* GetDevDisplayName(unsigned long index);
	
	//デバイス識別名取得
	NSString* GetDevIdName(unsigned long index);
	
	//メーカー名取得
	NSString* GetManufacturerName(unsigned long index);
	
	//オンライン状態取得
	bool IsOnline(unsigned long index);
	
	//ポート対応デバイス登録
	int SetDevForPort(NSString* pIdName);
	
	//MIDIイベント読み込みコールバック関数登録
	void SetInReadCallBack(SMInReadCallBack pCallBack, void* pUserParam);
	
	//全デバイスのオープン／クローズ
	int OpenPortDev();
	int ClosePortDev();
	
	//ポート情報クリア
	int ClearPortInfo();
	
private:
	
	//ポート情報構造隊
	typedef struct {
		BOOL isExist;
		MIDIEndpointRef endpointRef;
		MIDIPortRef portRef;
	} SMPortInfo;
	
private:
	
	//入力デバイスリスト
	typedef std::list<SMDevInfo*> SMInDevList;
	typedef std::list<SMDevInfo*>::iterator SMInDevListItr;
	SMInDevList m_InDevList;
	
	//ポート情報
	SMPortInfo m_PortInfo;
	
	//MIDIクライアント
	MIDIClientRef m_ClientRef;
	
	//コールバック関数
	SMInReadCallBack m_pInReadCallBack;
	void* m_pCallBackUserParam;
	
	//パケット解析系
	bool m_isContinueSysEx;
	
	int _InitDevList();
	int _CheckDev(ItemCount index);
	int _CheckEnt(ItemCount index, MIDIDeviceRef devRef);
	int _CheckEnd(MIDIEndpointRef endpointRef);
	
	int _InitDevListWithVitualSrc();
	int _CheckSrc(MIDIEndpointRef endpointRef);
	
	static void _InReadCallBack(
					const MIDIPacketList *pPakcetList,
					void* pReadProcRefCon,
					void* pSrcConnRefCon
				);
	void _InReadProc(const MIDIPacket* pPakcet);
	int _InReadProcSysEx(
				const MIDIPacket* pPacket,
				bool* pIsContinueSysEx,
				SMEvent* pEvent
			);
	unsigned long _GetMIDIMsgSize(unsigned char status);
	unsigned long _GetSysMsgSize(unsigned char status);
	
};

#pragma warning(default:4251)


