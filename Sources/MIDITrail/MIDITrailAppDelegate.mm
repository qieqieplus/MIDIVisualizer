//******************************************************************************
//
// MIDITrail / MIDITrailAppDelegate
//
// アプリケーションデリゲート
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MIDITrailAppDelegate.h"


@implementation MIDITrailAppDelegate

//@synthesize window;

//******************************************************************************
// アプリケーション起動処理開始
//******************************************************************************
- (void)applicationWillFinishLaunching:(NSNotification*)aNotification
{
	int result = 0;
	NSNotificationCenter* pCenter = nil;
	float timerInterval = 0.0f;
	
	//NSLog(@"applicationWillFinishLaunching");
	
	//メニュー制御初期化
	result = [m_pMenuCtrl initialize:&m_App];
	if (result != 0) goto EXIT;
	
	//アプリケーション初期化
	result = m_App.Initialize(m_pMenuCtrl);
	if (result != 0) goto EXIT;
	
	//アプリケーション実行
	result = m_App.Run();
	if (result != 0) goto EXIT;
	
	//通知先登録：演奏状態変更通知
	pCenter = [NSNotificationCenter defaultCenter];
	[pCenter addObserver:self
				selector:@selector(onChangePlayStatusPause:) 
					name:@"onChangePlayStatusPause"
				  object:nil];
	[pCenter addObserver:self
				selector:@selector(onChangePlayStatusStop:) 
					name:@"onChangePlayStatusStop"
				  object:nil];
	
	//タイマー開始
	//  本来タイマーはm_Appで制御すべき
	//  しかしm_AppはC++のクラスであるためNSTimerを利用しにくい
	//  代替策としてデリゲート側からサポートする
	timerInterval = (float)(m_App.GetTimerInterval()) / 1000.0f;
	m_pTimer = [NSTimer scheduledTimerWithTimeInterval:timerInterval
												target:self
											  selector:@selector(timerControl:)
											  userInfo:nil
											   repeats:YES];
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// アプリケーション起動処理終了
//******************************************************************************
- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
	//NSLog(@"applicationDidFinishLaunching");
}

//******************************************************************************
// アプリケーション終了処理開始
//******************************************************************************
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	int result = 0;
	
	//NSLog(@"applicationWillTerminate");
	
	//タイマー停止
	[m_pTimer invalidate];
	
	//アプリケーション停止
	result = m_App.Terminate();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	return;
}

//******************************************************************************
// アプリケーションアクティブ状態遷移直後
//******************************************************************************
- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	//NSLog(@"applicationDidBecomeActive");
	
	m_App.OnAppActive();
}

//******************************************************************************
// アプリケーション非アクティブ遷移直後
//******************************************************************************
- (void)applicationDidResignActive:(NSNotification *)aNotification
{
	//NSLog(@"applicationDidResignActive");
	
	m_App.OnAppInactive();
}

//******************************************************************************
// 演奏状態変更通知：一時停止
//******************************************************************************
- (void)onChangePlayStatusPause:(NSNotification*)pNotification
{
	int result = 0;
	
	//NSLog(@"onChangePlayStatusPause");
	
	result = m_App.OnChangePlayStatusPause();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	return;	
}

//******************************************************************************
// 演奏状態変更通知：停止（演奏終了）
//******************************************************************************
- (void)onChangePlayStatusStop:(NSNotification*)pNotification
{
	int result = 0;
	
	//NSLog(@"onChangePlayStatusStop");
	
	result = m_App.OnChangePlayStatusStop();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	return;	
}

//******************************************************************************
// タイマー処理
//******************************************************************************
- (void)timerControl:(NSTimer*)aTimer
{
	int result = 0;
	
	result = m_App.OnTimer();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	return;	
}

//******************************************************************************
// アプリケーションアイコンへのファイルドロップイベント
//******************************************************************************
- (BOOL)application:(NSApplication*)theApplication openFiles:(NSArray*)pPathArray
{
	NSString* pPath = nil;
	BOOL isAcceptable = NO;
	BOOL isExist = NO;
	BOOL isDir = NO;
	
	//NSLog(@"application openFiles");
	
	//アプリアイコンへのファイルドロップによってアプリが起動した場合
	//  applicationWillFinishLaunching の後（applicationDidFinishLaunching より前）で
	//  application:openFiles: が呼び出される
	//アプリ動作中にアプリアイコンにファイルドロップされた場合も
	//  application:openFiles: が呼び出される
	
	//複数ファイルのドロップは無視する
	if ([pPathArray count] != 1) goto EXIT;
	
	//パスの取得
	pPath = [pPathArray objectAtIndex:0];
	
	//パスの存在確認
	isExist = [[NSFileManager defaultManager] fileExistsAtPath:pPath isDirectory:&isDir];
	if (!isExist) goto EXIT;
	
	//ディレクトリのドロップは無視する
	if (isDir) goto EXIT;
	
	//ファイルドロップ処理実行
	[m_pMenuCtrl onDropFile:[pPathArray objectAtIndex:0]];
	isAcceptable = YES;
	
EXIT:;
	return isAcceptable;
}


@end


