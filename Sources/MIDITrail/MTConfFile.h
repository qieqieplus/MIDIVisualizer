//******************************************************************************
//
// MIDITrail / MTConfFile
//
// 設定ファイルクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"


//******************************************************************************
// 設定ファイルクラス
//******************************************************************************
class MTConfFile
{
public:
	
	//コンストラクタ／デストラクタ
	MTConfFile(void);
	virtual ~MTConfFile(void);
	
	//初期化
	int Initialize(NSString* pCategory);
	
	//カレントセクション設定
	int SetCurSection(NSString* pSection);
	
	//整数値取得／登録
	int GetInt(NSString* pKey, int* pVal, int defaultVal);
	
	//浮動小数値取得／登録
	int GetFloat(NSString* pKey, float* pVal, float defaultVal);
	
	//文字列取得／登録
	int GetStr(NSString* pKey, NSString** pValPtr, NSString* pDefaultVal);
	
	//値登録系のメソッドは未実装
	//int SetInt(const TCHAR* pKey, int val);
	//int SetFloat(const TCHAR* pKey, float val);
	//int SetStr(const TCHAR* pKey, const TCHAR* pStr);
	
private:
	
	YNConfFile* m_pConfFile;
	
	//代入とコピーコンストラクタの禁止
	void operator=(const MTConfFile&);
	MTConfFile(const MTConfFile&);
	
};


