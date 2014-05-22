//******************************************************************************
//
// Simple Base Library / YNUserConf
//
// ユーザ設定クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNUserConf.h"


@implementation YNUserConf

//******************************************************************************
// 初期化
//******************************************************************************
- (id)init
{
	[super init];
	m_Category = nil;
	m_Section = nil;
	return self;
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	[m_Category release];
	[m_Section release];
	[super dealloc];
}
//******************************************************************************
// カテゴリ設定
//******************************************************************************
- (void)setCategory:(NSString*)category
{
	[category retain];
	[m_Category release];
	m_Category = category;
}

//******************************************************************************
// セクション設定
//******************************************************************************
- (void)setSection:(NSString*)section
{
	[section retain];
	[m_Section release];
	m_Section = section;
}

//******************************************************************************
// 値取得（整数）
//******************************************************************************
- (int)intValueForKey:(NSString*)key
		 defaultValue:(int)defaultValue
{
	int value = 0;
	NSString* strvalue =nil;
	
	strvalue = [self strValueForKey:key
					   defaultValue:[NSString stringWithFormat:@"%d", defaultValue]];
	value = [strvalue intValue];
		
	return value;
}

//******************************************************************************
// 値取得（浮動小数）
//******************************************************************************
- (float)floatValueForKey:(NSString*)key
			 defaultValue:(float)defaultValue
{
	float value = 0.0f;
	NSString* strvalue =nil;
	
	strvalue = [self strValueForKey:key
					   defaultValue:[NSString stringWithFormat:@"%f", defaultValue]];
	value = [strvalue floatValue];
	
	return value;
}

//******************************************************************************
// 値取得（文字列）
//******************************************************************************
- (NSString*)strValueForKey:(NSString*)key
				defaultValue:(NSString*)defaultValue
{
	NSString* value = nil;
	NSDictionary* categoryDictionary = nil;
	NSDictionary* sectionDictionary = nil;
	
	if ((m_Category == nil) ||(m_Section == nil)) {
		//カテゴリ／セクション名が未指定ならプログラムエラーであるが実装を簡素にする
		value = defaultValue;
		goto EXIT;
	}
	
	//カテゴリに対応する辞書を取り出す
	categoryDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:m_Category];
	if ((categoryDictionary == nil) || (![categoryDictionary isKindOfClass:[NSDictionary class]])) {
		//キー未登録または登録されていても辞書でないオブジェクトが登録されていた場合
		//値が取得できないのでデフォルト値を採用する
	}
	else {
		//辞書からセクションに対応する値を取り出す
		sectionDictionary = [categoryDictionary objectForKey:m_Section];
		if ((sectionDictionary == nil) || (![sectionDictionary isKindOfClass:[NSDictionary class]])) {
			//キー未登録または登録されていても辞書でないオブジェクトが登録されていた場合
			//値が取得できないのでデフォルト値を採用する
		}
		else {
			//辞書からキーに対応する値を取り出す
			value = [sectionDictionary objectForKey:key];
			if (![value isKindOfClass:[NSString class]]) {
				//文字列でないオブジェクトが登録されていた場合
				value = nil;
			}
		}
	}
	
	//値が取得できなかった場合は指定されたデフォルト値を返す
	if (value == nil) {
		value = defaultValue;
	}
	
EXIT:;
	return value;
}

//******************************************************************************
// 値登録（整数）
//******************************************************************************
- (void)setInt:(int)value forKey:(NSString*)key
{
	NSString* strvalue = nil;
	
	//整数を文字列に変換
	strvalue = [NSString stringWithFormat:@"%d", value];
	
	//セクションを更新
	[self setStr:strvalue forKey:key];
	
	return;
}

//******************************************************************************
// 値登録（浮動小数）
//******************************************************************************
- (void)setFloat:(float)value forKey:(NSString*)key
{
	NSString* strvalue = nil;
		
	//整数を文字列に変換
	strvalue = [NSString stringWithFormat:@"%f", value];
	
	//セクションを更新
	[self setStr:strvalue forKey:key];
	
	return;	
}

//******************************************************************************
// 値登録（文字列）
//******************************************************************************
- (void)setStr:(NSString*)value forKey:(NSString*)key
{
	NSUserDefaults* userDefaults = nil;
	NSDictionary* dictionary1 = nil;
	NSDictionary* dictionary2 = nil;
	NSMutableDictionary* categoryDictionary = nil;
	NSMutableDictionary* sectionDictionary = nil;
	
	if ((m_Category == nil) ||(m_Section == nil)) {
		//カテゴリ／セクション名が未指定ならプログラムエラーであるが実装を簡素にする
		goto EXIT;
	}
	
	//カテゴリに対応する辞書を取得
	userDefaults = [NSUserDefaults standardUserDefaults];
	dictionary1 = [userDefaults objectForKey:m_Category];
	if ((dictionary1 == nil) || (![dictionary1 isKindOfClass:[NSDictionary class]])) {
		//キー未登録または登録されていても辞書でないオブジェクトが登録されていた場合
		categoryDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	else {
		categoryDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary1];
	}
	
	//カテゴリの辞書からセクションに対応する辞書を取得
	dictionary2 = [categoryDictionary objectForKey:m_Section];
	if ((dictionary2 == nil) || (![dictionary2 isKindOfClass:[NSDictionary class]])) {
		//キー未登録または登録されていても辞書でないオブジェクトが登録されていた場合
		sectionDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	else {
		sectionDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary2];
	}
	
	//セクションの辞書を更新
	[sectionDictionary setObject:value forKey:key];
	//セクションの辞書をカテゴリの辞書に戻す
	[categoryDictionary setObject:sectionDictionary forKey:m_Section];
	//カテゴリの辞書をユーザ設定に戻す
	[userDefaults setObject:categoryDictionary forKey:m_Category];
	[userDefaults synchronize];
	
EXIT:;
	[categoryDictionary release];
	[sectionDictionary release];
	return;
}

@end


