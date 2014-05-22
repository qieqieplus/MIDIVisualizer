//******************************************************************************
//
// MIDITrail / MTMainWindowCtrl
//
// メインウィンドウ制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import "MTMainView.h"


//******************************************************************************
// メインウィンドウ制御クラス
//******************************************************************************
@interface MTMainWindowCtrl : NSWindowController {
	
	IBOutlet MTMainView* m_pView;
	NSTimer* m_pTimer;
	BOOL m_isAppTermOnClose;
	BOOL m_isCenter;
	
}

//--------------------------------------
//公開I/F

//生成
- (id)init;

//破棄
- (void)dealloc;

//メインビュー生成
- (int)createMainViewWithRendererParam:(OGLRedererParam)rendererParam;

//メインビュー破棄
- (void)deleteMainView;

//メインビュー取得
- (MTMainView*)mainView;

//ウィンドウサイズ設定
- (void)setWindowSize:(NSSize)size;

//ウィンドウ位置設定
- (void)setWindowPosition:(NSPoint)position;

//ウィンドウ表示
- (void)showWindow;

//ウィンドウクローズ
- (void)close;

//--------------------------------------
//イベントハンドラ

//クローズボタン押下
- (void)windowWillClose:(NSNotification*)aNotification;

//--------------------------------------
//内部処理

//スクリーン中央に移動
- (void)setPositionToCenterOfScreen;

//タイマー処理
- (void)timerControl:(NSTimer*)aTimer;


@end


