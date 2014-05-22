//******************************************************************************
//
// MIDITrail / MTConfFile
//
// 設定ファイルクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTParam.h"
#import "MTConfFile.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTConfFile::MTConfFile(void)
{
	m_pConfFile = nil;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTConfFile::~MTConfFile(void)
{
	[m_pConfFile release];
}

//******************************************************************************
// 初期化
//******************************************************************************
int MTConfFile::Initialize(
		NSString* pCategory
	)
{
	int result = 0;
	NSString* pFilePath = nil;
	
	//設定ファイルパス登録
	pFilePath = [NSString stringWithFormat:@"%@/%@%@%@",
					[YNPathUtil resourceDirPath], MT_CONFFILE_DIR, pCategory, @".ini"];
	
	//設定ファイル初期化
	m_pConfFile = [[YNConfFile alloc] init];
	if (m_pConfFile == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ファイル読み込み
	result = [m_pConfFile loadFile:pFilePath];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// カレントセクション設定
//******************************************************************************
int MTConfFile::SetCurSection(
		NSString* pSection
	)
{
	int result = 0;
	
	[m_pConfFile setCurSection:pSection];
	
	return result;
}

//******************************************************************************
// 整数値取得／登録
//******************************************************************************
int MTConfFile::GetInt(
		NSString* pKey,
		int* pVal,
		int defaultVal
	)
{
	int result = 0;
	
	*pVal = [m_pConfFile intValueForKey:pKey defaultValue:defaultVal];
	
	return result;
}

//******************************************************************************
// 浮動小数値取得／登録
//******************************************************************************
int MTConfFile::GetFloat(
		NSString* pKey,
		float* pVal,
		float defaultVal
	)
{
	int result = 0;
	
	*pVal = [m_pConfFile floatValueForKey:pKey defaultValue:defaultVal];
	
	return result;
}

//******************************************************************************
// 文字列取得／登録
//******************************************************************************
int MTConfFile::GetStr(
		NSString* pKey,
		NSString** pValPtr,
		NSString* pDefaultVal
	)
{
	int result = 0;
	
	*pValPtr = [m_pConfFile strValueForKey:pKey defaultValue:pDefaultVal];
	
	return result;
}


