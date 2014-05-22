//******************************************************************************
//
// Simple MIDI Library / SMEventSysEx
//
// SysExイベントクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// イベントクラスから派生させる設計が理想だが、newの実施回数を激増させる
// ため、スタックで処理できるデータ解析ユーティリティクラスとして実装する。

#import "SMEvent.h"


//******************************************************************************
// SysExイベントクラス
//******************************************************************************
class SMEventSysEx
{
public:
	
	//コンストラクタ／デストラクタ
	SMEventSysEx();
	virtual ~SMEventSysEx(void);
	
	//イベントアタッチ
	void Attach(SMEvent* pEvent);
	
	//MIDI出力メッセージ取得
	int GetMIDIOutLongMsg(unsigned char** pPtrMsg, unsigned long* pSize);
	
private:
	
	SMEvent* m_pEvent;
	
	//代入とコピーコンストラクタの禁止
	void operator=(const SMEventSysEx&);
	SMEventSysEx(const SMEventSysEx&);

};


