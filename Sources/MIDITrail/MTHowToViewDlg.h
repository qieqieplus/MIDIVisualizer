//******************************************************************************
//
// MIDITrail / MTHowToViewDlg
//
// 操作方法ダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNBaseLib.h"


//******************************************************************************
// 操作方法ダイアログクラス
//******************************************************************************
@interface MTHowToViewDlg : NSWindowController {
	
	IBOutlet NSImageView* m_pImageView;
	IBOutlet NSButton* m_pPreviousButton;
	IBOutlet NSButton* m_pNextButton;
	int m_PageNo;
	
}

//--------------------------------------
//公開I/F

//生成
- (id)init;

//破棄
- (void)dealloc;

//モーダルウィンドウ表示
- (void)showModalWindow;

//--------------------------------------
//イベントハンドラ

//ウィンドウ読み込み完了
- (void)windowDidLoad;

// Cancelボタン押下：またはESCキー押下
- (IBAction)onCancel:(id)sender;

//クローズボタン押下
- (void)windowWillClose:(NSNotification*)aNotification;

//前ボタン押下
- (IBAction)onPreviousButton:(id)sender;

//次ボタン押下
- (IBAction)onNextButton:(id)sender;

//クローズボタン押下
- (IBAction)onCloseButton:(id)sender;

//--------------------------------------
//内部処理

//ダイアログ初期化
- (int)initDlg;

//画像表示
- (int)drawHowToImage;

//ボタン状態更新
- (void)updateButtonStatus;


@end


