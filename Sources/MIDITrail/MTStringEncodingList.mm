//******************************************************************************
//
// MIDITrail / MTStringEncodingList
//
// 文字列エンコーディングリストクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTStringEncodingList.h"
#import "YNBaseLib.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTStringEncodingList::MTStringEncodingList(void)
{
	m_pEncodingNameArray = nil;
	m_pEncodingIdArray = nil;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTStringEncodingList::~MTStringEncodingList(void)
{
	Clear();
}

//******************************************************************************
// 初期化
//******************************************************************************
int MTStringEncodingList::Initialize()
{
	int result = 0;
	const CFStringEncoding* pId = 0;
	CFStringRef nameRef = NULL;
	unsigned long encodingId = 0;
	NSNumber* pEncodingId = nil;
	NSMutableDictionary* pDictionary = nil;
	NSArray* pSortedKeys = nil;
	NSString* pName = nil;
	
	Clear();
	
	//作業用辞書を生成
	pDictionary = [[NSMutableDictionary alloc] init];
	
	//配列を生成
	m_pEncodingNameArray = [[NSMutableArray alloc] init];
	m_pEncodingIdArray = [[NSMutableArray alloc] init];
	
	//エンコーディング一覧を取得
	pId = CFStringGetListOfAvailableEncodings();
	
	//全エンコーディングを取得
	while (*pId != kCFStringEncodingInvalidId) {
		//エンコーディングIDに対応するエンコーディング名称を取得
		nameRef = CFStringGetNameOfEncoding(*pId);
		//エンコーディングIDをNSStringEncodingに変換
		encodingId = CFStringConvertEncodingToNSStringEncoding(*pId);
		pEncodingId = [[NSNumber alloc] initWithUnsignedLong:encodingId];
		//辞書登録
		[pDictionary setObject:pEncodingId forKey:(NSString*)nameRef];
		[pEncodingId release];
		pEncodingId = nil;
		CFRelease(nameRef);
		nameRef = NULL;
		//次のエンコーディングIDへ移る
		pId++;
	}
	
	//辞書に登録されたエンコーディング名称一覧をソートして取得
	pSortedKeys = [[pDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	//ソートしたエンコーディング名称とエンコーディングIDを配列に保存
	for (pName in pSortedKeys) {
		[m_pEncodingNameArray addObject:pName];
		[m_pEncodingIdArray addObject:[pDictionary objectForKey:pName]];
	}
	
	//for (pName in m_pEncodingNameArray) {
	//	NSLog(@"name %@", pName);
	//}
	
EXIT:;
	[pDictionary release];
	return result;
}

//******************************************************************************
// エンコーディング数取得
//******************************************************************************
unsigned long MTStringEncodingList::GetSize()
{
	return [m_pEncodingNameArray count];
}

//******************************************************************************
// エンコーディング名称取得
//******************************************************************************
NSString* MTStringEncodingList::GetEncodingName(unsigned long index)
{
	NSString* pEncodingName = @"";
	
	if (index >= [m_pEncodingNameArray count]) {
		goto EXIT;
	}
	
	pEncodingName = [m_pEncodingNameArray objectAtIndex:index];
	
EXIT:;
	return pEncodingName;
}

//******************************************************************************
//エンコーディングID称取得(NSStringEncoding)
//******************************************************************************
unsigned long MTStringEncodingList::GetEncodingId(unsigned long index)
{
	unsigned long encodingId = 0;
	
	if (index >= [m_pEncodingNameArray count]) {
		goto EXIT;
	}
	
	encodingId = [[m_pEncodingIdArray objectAtIndex:index] unsignedLongValue];
	
EXIT:;
	return encodingId;
}

//******************************************************************************
// クリア
//******************************************************************************
void MTStringEncodingList::Clear()
{
	[m_pEncodingNameArray release];
	m_pEncodingNameArray = nil;
	[m_pEncodingIdArray release];
	m_pEncodingIdArray = nil;
}


