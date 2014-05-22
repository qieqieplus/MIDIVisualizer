//******************************************************************************
//
// Simple MIDI Library / SMDevInfo
//
// MIDIデバイス情報クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <CoreMIDI/CoreMIDI.h>


//******************************************************************************
// MIDIデバイス情報クラス
//******************************************************************************
class SMDevInfo
{
public:
	
	//コンストラクタ／デストラクタ
	SMDevInfo(void);
	virtual ~SMDevInfo(void);
	
	//表示名称登録
	void SetDisplayName(NSString* pDisplayName);
	
	//識別名称登録："メーカー名/モデル名/エンドポイントプロパティ名"
	void SetIdName(NSString* pIdName);
	
	//エンドポイント登録
	void SetEndpointRef(MIDIEndpointRef endpointRef);
	
	//メーカー名登録
	void SetManufacturerName(NSString* pManufacturerName);
	
	//表示名称取得
	NSString* GetDisplayName();
	
	//識別名称取得
	NSString* GetIdName();
	
	//メーカー名取得
	NSString* GetManufacturerName();
	
	//エンドポイント取得
	MIDIEndpointRef GetEndpointRef();
	
	//オンライン状態取得
	void SetOnline(bool isOnline);
	bool IsOnline();
	
private:
	
	NSString* m_pDisplayName;
	NSString* m_pIdName;
	NSString* m_pManufacturerName;
	MIDIEndpointRef m_EndpointRef;
	bool m_isOnline;
	
};


