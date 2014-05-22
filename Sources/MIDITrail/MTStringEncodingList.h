//******************************************************************************
//
// MIDITrail / MTStringEncodingList
//
// 文字列エンコーディングリストクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>


//******************************************************************************
// 文字列エンコーディングリストクラス
//******************************************************************************
class MTStringEncodingList
{
public:
	
	//コンストラクタ／デストラクタ
	MTStringEncodingList(void);
	virtual ~MTStringEncodingList(void);
	
	//初期化
	int Initialize();
	
	//クリア
	void Clear();
	
	//エンコーディング数取得
	unsigned long GetSize();
	
	//エンコーディング名称取得
	NSString* GetEncodingName(unsigned long index);
	
	//エンコーディングID称取得(NSStringEncoding)
	unsigned long GetEncodingId(unsigned long index);
	
private:
	
	NSMutableArray* m_pEncodingNameArray;
	NSMutableArray* m_pEncodingIdArray;
	
};


