//******************************************************************************
//
// Simple Base Library / YNErrCtrl
//
// エラー制御クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNErrInfo.h"


//******************************************************************************
//エラー制御マクロ
//******************************************************************************
#define YN_SET_ERR(msg,info1,info2)   [YNErrCtrl setErr:LVL_ERR  lineNo:__LINE__ fileName:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] message:msg errInfo1:info1 errInfo2:info2]
#define YN_SET_WARN(msg,info1,info2)  [YNErrCtrl setErr:LVL_WARN lineNo:__LINE__ fileName:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] message:msg errInfo1:info1 errInfo2:info2]
#define YN_SET_INFO(msg,info1,info2)  [YNErrCtrl setErr:LVL_INFO lineNo:__LINE__ fileName:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] message:msg errInfo1:info1 errInfo2:info2]
#define YN_SHOW_ERR()   [YNErrCtrl showErr]

//******************************************************************************
// エラー制御クラス
//******************************************************************************
@interface YNErrCtrl : NSObject {
}

//スレッド開始時の初期化処理
+ (void)initOnThreadStart;

//スレッド終了時の解放処理
+ (void)termOnThreadEnd;

//エラー情報登録
+ (int)setErr:(YNErrLevel)errLevel
	   lineNo:(unsigned long)lineNo
	 fileName:(NSString*)fileName
	  message:(NSString*)message
	 errInfo1:(unsigned long)errInfo1
	 errInfo2:(unsigned long)errInfo2;

//エラー情報取得
+ (YNErrInfo*)errInfo;

//エラー情報ダイアログ表示
+ (void)showErr;

//エラー情報クリア
+ (void)clear;

@end


