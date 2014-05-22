//******************************************************************************
//
// MIDITrail / MTStatusDlg
//
// ステータスダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNBaseLib.h"


//******************************************************************************
// 操作方法ダイアログクラス
//******************************************************************************
@interface MTStatusDlg : NSWindowController {
	
	IBOutlet NSTextField* m_pLabel;
	NSString* m_pMessage;
	BOOL m_isShow;
	
}

//--------------------------------------
//公開I/F

//生成
- (id)initWithMessage:(NSString*)pMessage;

//破棄
- (void)dealloc;

//ウィンドウ表示
- (void)showWindowOnWindow:(NSWindow*)pWindow;

//ウィンドウクローズ
- (void)closeWindow;

//--------------------------------------
//イベントハンドラ

//ウィンドウ読み込み完了
- (void)windowDidLoad;

//--------------------------------------
//内部処理

//指定ウィンドウの中央に移動
- (void)setPositionToCenterOfWindow:(NSWindow*)pWindow;


@end


