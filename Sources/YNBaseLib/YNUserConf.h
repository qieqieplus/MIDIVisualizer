//******************************************************************************
//
// Simple Base Library / YNUserConf
//
// ユーザ設定クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>


//******************************************************************************
// ユーザー設定クラス
//******************************************************************************
@interface YNUserConf : NSObject {
	NSString* m_Category;
	NSString* m_Section;
}

//初期化
- (id)init;
//破棄
- (void)dealloc;

//カテゴリ設定
- (void)setCategory:(NSString*)category;
//セクション設定
- (void)setSection:(NSString*)section;

//値取得（整数）
- (int)intValueForKey:(NSString*)key defaultValue:(int)defaultValue;
//値取得（浮動小数）
- (float)floatValueForKey:(NSString*)key defaultValue:(float)defalutValue;
//値取得（文字列）
- (NSString*)strValueForKey:(NSString*)key defaultValue:(NSString*)defaultValue;

//値登録（整数）
- (void)setInt:(int)value forKey:(NSString*)key;
//値登録（浮動小数）
- (void)setFloat:(float)value forKey:(NSString*)key;
//値登録（文字列）
- (void)setStr:(NSString*)value forKey:(NSString*)key;

@end


