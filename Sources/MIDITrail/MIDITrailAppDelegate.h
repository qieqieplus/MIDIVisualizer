//******************************************************************************
//
// MIDITrail / MIDITrailAppDelegate
//
// MIDITrail アプリケーションデリゲート
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "SMIDILib.h"
#import "MTMainWindowCtrl.h"
#import "MTMainView.h"
#import "MTScenePianoRoll3D.h"
#import "MTScenePianoRoll2D.h"
#import "MTScenePianoRollRain.h"
#import "MTSceneTitle.h"
#import "MIDITrailApp.h"
#import "MTMenuCtrl.h"


//******************************************************************************
// MIDITrail アプリケーションデリゲート
//******************************************************************************
//  NSApplicationDelegate が導入されたのは Mac OS X 10.6 からである
//  Mac OS X 10.5 サポートのため NSApplicationDelegate を使用しない
//  @interface MIDITrailAppDelegate : NSObject <NSApplicationDelegate> {

@interface MIDITrailAppDelegate : NSObject {
	
	IBOutlet MTMenuCtrl* m_pMenuCtrl;
	MIDITrailApp m_App;
	NSTimer* m_pTimer;
	
}

//@property (assign) IBOutlet NSWindow *window;

//アプリケーション起動処理開始
- (void)applicationWillFinishLaunching:(NSNotification*)aNotification;

//アプリケーション起動処理終了
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

//アプリケーション終了開始
- (void)applicationWillTerminate:(NSNotification *)aNotification;

//アプリケーションアクティブ状態遷移直後
- (void)applicationWillTerminate:(NSNotification *)aNotification;

//アプリケーション非アクティブ状態遷移直後
- (void)applicationDidBecomeActive:(NSNotification *)aNotification;

//演奏状態変更通知
- (void)onChangePlayStatusPause:(NSNotification*)pNotification;
- (void)onChangePlayStatusStop:(NSNotification*)pNotification;

//タイマー処理
- (void)timerControl:(NSTimer*)aTimer;

//アプリケーションアイコンへのファイルドロップイベント
- (BOOL)application:(NSApplication*)theApplication openFiles:(NSArray*)pPathArray;


@end


