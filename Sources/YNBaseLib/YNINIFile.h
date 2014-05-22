//******************************************************************************
//
// Simple Base Library / YNINIFile
//
// INIファイルクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// memo:
// INIファイルの操作を行うクラス。
// Windows版の開発で作成した設定ファイルをそのまま利用可能にすることを目的とする。
// 現状は参照のみに対応しており、登録／更新には対応していない。
// INIファイルの改行コードはCRLFでなければならない。

#import <Cocoa/Cocoa.h>


//******************************************************************************
// INIファイルクラス
//******************************************************************************
@interface YNINIFile : NSObject {
	NSString* m_Path;
	NSMutableDictionary* m_Dictionary;
	NSString* m_CurSection;
}

//初期化
- (id)init;
//破棄
- (void)dealloc;

//ファイル読み込み
- (int)loadFile:(NSString*)path;

//セクション設定
- (void)setCurSection:(NSString*)section;
//値取得（整数）
- (int)intValueForKey:(NSString*)key defaultValue:(int)defaultValue;
//値取得（浮動小数）
- (float)floatValueForKey:(NSString*)key defaultValue:(float)defalutValue;
//値取得（文字列）
- (NSString*)strValueForKey:(NSString*)key defaultValue:(NSString*)defaultValue;

//値登録系のメソッドは未実装
//- (void)setInt:(int)value forKey:(NSString*)key;
//- (void)setFloat:(float)value forKey:(NSString*)key;
//- (void)setStr:(NSString)value forKey:(NSString*)key;
//- (int)saveFile;

@end


