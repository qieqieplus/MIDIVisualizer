//******************************************************************************
//
// Simple Base Library / YNPathUtil
//
// パスユーティリティクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>


//******************************************************************************
// パスユーティリティクラス
//******************************************************************************
@interface YNPathUtil : NSObject {
}

//プロセス実行ファイルディレクトリパス取得
//  ex. /path/to/application.app -> /path/to
+ (const NSString*)moduleDirPath;

//リソースディレクトリパス取得
//  ex. /path/to/application.app/Contents/Resources
+ (const NSString*)resourceDirPath;

//拡張子判定
//  ex. [YNPathUtil isFileExtMatch:@"/path/to/file.txt" ext:@"txt"] -> YES
+ (BOOL)isFileExtMatch:(NSString*)path ext:(NSString*)ext;

//+ (NSString*)appDataDirPath;
//+ (NSString*)tempFilePath;

@end


