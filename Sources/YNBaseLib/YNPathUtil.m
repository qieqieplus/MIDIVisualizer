//******************************************************************************
//
// Simple Base Library / YNPathUtil
//
// パスユーティリティクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNPathUtil.h"


@implementation YNPathUtil

//******************************************************************************
// プロセス実行ファイルディレクトリパス取得
//******************************************************************************
+ (NSString*)moduleDirPath
{
	return [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
}

//******************************************************************************
// リソースディレクトリパス取得
//******************************************************************************
+ (NSString*)resourceDirPath
{
	return [[NSBundle mainBundle] resourcePath];
}

//******************************************************************************
// 拡張子判定
//******************************************************************************
+ (BOOL)isFileExtMatch:(NSString*)path ext:(NSString*)ext
{
	return [[path pathExtension] isEqualToString:ext];
}

@end


