//******************************************************************************
//
// Simple MIDI Library / SMOutDevCtrl
//
// MIDI出力デバイス制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// memo:
// 選択されたエンドポイントを一意に特定する方法
// ユーザが選択したエンドポイントを設定ファイルに記録する場合は「識別名称」を使用する。
// 表示名は、OSの設定「Audio MIDI設定」を使ってユーザが自由に変更できるし、
// 重複も許されるため、識別用に使うのは危険だと判断した。
// ただしこの識別方法は、全く同じデバイスが複数存在する場合に問題が起きる可能性がある。
// 同じデバイスを二つ接続したとき、仮に「メーカー名/モデル名/エンドポイントプロパティ名」
// が重複するなら、過去にユーザが選択したいたエンドポイントを取り違えるかもしれない。
// この問題は、機材がないので検証できていない。
// なお kMIDIPropertyUniqueID は、ユニークIDといいながらアプリケーション動作中に
// ころころ値が変わってしまうため、選択したデバイスを一意に特定する情報にならない。
// 「MIDIスタジオ」で機器間のケーブルを切断／接続するだけでIDが変わるようだ。

#import <CoreMIDI/CoreMIDI.h>
#import <list>
#import "SMDevInfo.h"

#pragma warning(disable:4251)


//******************************************************************************
// パラメータ定義
//******************************************************************************
//最大ポート数：A,B,C,D,E,F
#define SM_MIDIOUT_PORT_NUM_MAX   (6)


//******************************************************************************
// MIDI出力デバイス制御クラス
//******************************************************************************
class SMOutDevCtrl
{
public:
	
	//コンストラクタ／デストラクタ
	SMOutDevCtrl(void);
	virtual ~SMOutDevCtrl(void);
	
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
	int SetDevForPort(unsigned char portNo, NSString* pIdName);
	
	//全デバイスのオープン／クローズ
	int OpenPortDevAll();
	int ClosePortDevAll();
	
	//ポート情報クリア
	int ClearPortInfo();
	
	//MIDI出力メッセージ送信
	int SendShortMsg(unsigned char portNo, unsigned char* pMsg, unsigned long size);
	int SendLongMsg(unsigned char portNo, unsigned char* pMsg, unsigned long size);
	int NoteOffAll();
	
private:
	
	//ポート情報構造隊
	typedef struct {
		BOOL isExist;
		MIDIEndpointRef endpointRef;
		MIDIPortRef portRef;
	} SMPortInfo;
	
private:
	
	//出力先デバイスリスト
	typedef std::list<SMDevInfo*> SMOutDevList;
	typedef std::list<SMDevInfo*>::iterator SMOutDevListItr;
	SMOutDevList m_OutDevList;
	
	//ポート情報
	SMPortInfo m_PortInfo[SM_MIDIOUT_PORT_NUM_MAX];
	
	//MIDIクライアント
	MIDIClientRef m_ClientRef;
	
	int _InitDevList();
	int _CheckDev(ItemCount index);
	int _CheckEnt(ItemCount index, MIDIDeviceRef devRef);
	int _CheckEnd(MIDIEndpointRef endpointRef);

	int _InitDevListWithVitualDest();
	int _CheckDest(MIDIEndpointRef endpointRef);

};

#pragma warning(default:4251)


