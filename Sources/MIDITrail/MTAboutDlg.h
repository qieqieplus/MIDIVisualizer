//******************************************************************************
//
// MIDITrail / MTAboutDlg
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
@interface MTAboutDlg : NSWindowController {
	
	IBOutlet NSImageView* m_pImageView;
	BOOL m_isShow;
	
}

//--------------------------------------
//公開I/F

//生成
- (id)init;

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

//OKボタン押下
- (IBAction)onOK:(id)sender;

//--------------------------------------
//内部処理

//指定ウィンドウの中央に移動
- (void)setPositionToCenterOfWindow:(NSWindow*)pWindow;

//画像表示
- (int)drawIconImage;

@end


