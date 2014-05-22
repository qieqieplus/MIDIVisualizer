//******************************************************************************
//
// Simple Base Library / YNErrCtrl
//
// エラー制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNErrInfo.h"
#import "YNErrCtrl.h"


@implementation YNErrCtrl

//******************************************************************************
// スレッド開始時の初期化処理
//******************************************************************************
+ (void)initOnThreadStart
{
	return;
}

//******************************************************************************
// スレッド終了時の解放処理
//******************************************************************************
+ (void)termOnThreadEnd
{
	[YNErrCtrl clear];
	return;
}

//******************************************************************************
// エラー登録
//******************************************************************************
+ (int)setErr:(YNErrLevel)errLevel
		lineNo:(unsigned long)lineNo
	  fileName:(NSString*)fileName
	   message:(NSString*)message
	  errInfo1:(unsigned long)errInfo1
	  errInfo2:(unsigned long)errInfo2
{
	int result = 0;
	NSMutableDictionary *dic = nil;
	YNErrInfo *info = nil;
	
	//エラー情報が登録されたままであれば破棄する
	[YNErrCtrl clear];
	
	//エラー情報オブジェクトを生成
	info = [[YNErrInfo alloc] initWithInfo:errLevel
									lineNo:lineNo
								  fileName:fileName
								   message:message
								  errInfo1:errInfo1
								  errInfo2:errInfo2];
	if (info == nil) {
		result = -2;
		goto EXIT;
	}
	
	//スレッドローカル記憶域に格納
	dic = [[NSThread currentThread] threadDictionary];
	[dic setObject:info forKey:@"YNErrInfo"];
	info = nil;
	
	//TODO:エラーコード生成
	result = -1;
	
EXIT:;
	[info release];
	return result;
}

//******************************************************************************
// エラー情報取得
//******************************************************************************
+ (YNErrInfo*)errInfo
{
	NSMutableDictionary* dic = nil;
	YNErrInfo* info = nil;
	
	//スレッドローカル記憶域からエラー情報オブジェクトを取得
	dic = [[NSThread currentThread] threadDictionary];
	info = [dic objectForKey:@"YNErrInfo"];
	
	return info;
}

//******************************************************************************
// エラー表示
//******************************************************************************
+ (void)showErr
{
	int apiresult = 0;
	YNErrInfo* info = nil;
	NSString* title = nil;
	NSString* msg = nil;
	
	//エラー情報がなければ何もしない
	info = [YNErrCtrl errInfo];
	if (info == nil) goto EXIT;
	
	//メッセージタイトル
	switch ([info errLevel]) {
		case (LVL_ERR):
			title = @"ERROR";
			break;
		case (LVL_WARN):
			title = @"WARNING";
			break;
		case (LVL_INFO):
			title = @"INFORMATION";
			break;
	}
	
	//メッセージ作成
	msg = [[NSString alloc] initWithFormat:@"%@\n\nFILE: %@\nLINE: %ld\nINFO: %08lX %08lX",
			 [info message],
			 [info fileName],
			 [info lineNo],
			 [info errInfo1],
			 [info errInfo2]];
	
	//アラートパネル表示
	apiresult = NSRunAlertPanel(title, msg, @"OK", nil, nil); //2,3番目のボタンは表示しない

EXIT:;
	[title release];
	[msg release];
	[YNErrCtrl clear];
	return;
}

//******************************************************************************
// エラー情報クリア
//******************************************************************************
+ (void)clear
{
	NSMutableDictionary* dic = nil;
	YNErrInfo* info = nil;
	
	//スレッドローカル記憶域に登録した情報を破棄
	dic = [[NSThread currentThread] threadDictionary];
	info = [dic objectForKey:@"YNErrInfo"];
	if (info != nil) {
		[dic removeObjectForKey:@"YNErrInfo"];
		[info release];
	}
	
	return;
}

@end


