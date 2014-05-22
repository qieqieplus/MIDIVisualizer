//******************************************************************************
//
// Simple Base Library / YNINIFile
//
// INIファイルクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNINIFile.h"


@implementation YNINIFile

//******************************************************************************
// 初期化
//******************************************************************************
- (id)init
{
	[super init];
	m_Path = nil;
	m_Dictionary = nil;
	m_CurSection = nil;
	return self;
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	[m_Path release];
	[m_Dictionary release];
	[m_CurSection release];
	[super dealloc];
}

//******************************************************************************
// ファイル読み込み
//******************************************************************************
- (int)loadFile:(NSString*)path
{
	int result = 0;
	NSString* initext = nil;
	NSString* line =nil;
	NSString* str =nil;
	NSString* section =nil;
	NSString* key = nil;
	NSString* value =nil;
	NSArray* lines = nil;
	NSError* error = nil;
	NSMutableDictionary* sectionDictionary = nil;
	
	//パス保存
	[path retain];
	[m_Path release];
	m_Path = path;
	
	//辞書初期化
	[m_Dictionary release];
	m_Dictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
	
	//INIファイル全体を読み込む
	initext = [NSString stringWithContentsOfFile:path
										encoding:NSASCIIStringEncoding
										   error:&error];
	if (initext == nil) {
		result = 1;
		goto EXIT;
	}
	
	//改行単位で配列に変換
	lines = [initext componentsSeparatedByString:@"\n"];
	
	//各行を解析
	for (line in lines) {
		
		//前後の空白と改行をトリミングする
		str = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([str length] < 2) continue;
		
		//コメント行の識別
		if (([str characterAtIndex:0] == '#')
			|| ([str characterAtIndex:0] == ';')) {
			continue;
		}
		
		//セクションの識別
		if (([str characterAtIndex:0] == '[')
			&& ([str characterAtIndex:([str length]-1)] == ']')) {
			//直前セクションを保管する
			if (section != nil) {
				//同じセクションが存在すると後勝ちになる
				[m_Dictionary setObject:sectionDictionary forKey:section];
			}
			//新規セクションの開始
			section = [str substringWithRange:NSMakeRange(1, [str length]-2)];
			sectionDictionary = [NSMutableDictionary dictionaryWithCapacity:20];
			continue;
		}
		
		//キーと値の識別
		NSRange range = [str rangeOfString:@"="];
		if (range.location != NSNotFound) {
			key = [str substringWithRange:NSMakeRange(0, range.location)];
			value = [str substringWithRange:NSMakeRange(range.location+1, [str length]-range.location-1)];
			//セクションに格納
			//NSLog(@"section=[%@] key=[%@] value=[%@]", section, key, value);
			[sectionDictionary setObject:value forKey:key];
		}
	}
	//最終セクションの保管
	if (section != nil) {
		[m_Dictionary setObject:sectionDictionary forKey:section];
	}

EXIT:;
	return result;
}

//******************************************************************************
// セクション設定
//******************************************************************************
- (void)setCurSection:(NSString*)section
{
	[section retain];
	[m_CurSection release];
	m_CurSection = section;
}

//******************************************************************************
// 値取得（整数）
//******************************************************************************
- (int)intValueForKey:(NSString*)key
		 defaultValue:(int)defaultValue
{
	int value = 0;
	NSString* strvalue =nil;
	
	strvalue = [self strValueForKey:key defaultValue:[NSString stringWithFormat:@"%d", defaultValue]];
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
	
	strvalue = [self strValueForKey:key defaultValue:[NSString stringWithFormat:@"%f", defaultValue]];
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
	NSMutableDictionary *sectionDictionary = nil;
	
	sectionDictionary = [m_Dictionary objectForKey:m_CurSection];
	if (sectionDictionary != nil) {
		value = [sectionDictionary objectForKey:key];
	}
	if (value == nil) {
		value = defaultValue;
	}
	
	return value;
}


@end


