//******************************************************************************
//
// Simple MIDI Library / SMOutDevCtrlEx
//
// 拡張MIDI出力デバイス制御クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// memo:
// MIDI出力デバイス制御クラス(SMOutDevCtrl)とApple DLS Synthesizer制御クラス
// (SMAppleDLSSynth)を統合して、MIDI出力デバイス制御クラスと同等のI/Fに集約する
// クラス。SMOutDevCtrlにはSMAppleDLSSynthを組み込まず、CoreMIDIの制御に集中
// できるようにする。

#import "SMOutDevCtrl.h"
#import "SMAppleDLSDevCtrl.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
#define SM_APPLE_DLS_DISPLAY_NAME  @"Apple DLS Music Device"
#define SM_APPLE_DLS_DEVID_NAME    @"Apple/DLS Music Device"


//******************************************************************************
// 拡張MIDI出力デバイス制御クラス
//******************************************************************************
class SMOutDevCtrlEx
{
public:
	
	//コンストラクタ／デストラクタ
	SMOutDevCtrlEx(void);
	virtual ~SMOutDevCtrlEx(void);
	
	//初期化
	int Initialize();
	
	//デバイス数取得
	unsigned long GetDevNum();
	
	//デバイス表示名称取得
	NSString* GetDevDisplayName(unsigned long index);
	
	//デバイス識別名取得
	NSString* GetDevIdName(unsigned long index);
	
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
	
	//ポート種別
	enum SMPortType {
		PortNone,			//なし
		PortAppleDLSDevice,	//AppleDLS デバイス
		PortCoreMIDIDevice	//CoreMIDI デバイス
	};
	
private:
	
	//出力デバイス制御
	SMOutDevCtrl m_OutDevCtrl;
	
	//Apple DLS デバイス制御
	SMAppleDLSDevCtrl m_AppleDLSDevCtrl;
	
	//ポート情報
	SMPortType m_PortType[SM_MIDIOUT_PORT_NUM_MAX];

};


