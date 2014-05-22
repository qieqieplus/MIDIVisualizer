//******************************************************************************
//
// MIDITrail / MTWindowSizeCfgDlg
//
// ウィンドウサイズ設定ダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNBaseLib.h"


//******************************************************************************
// ウィンドウサイズ設定ダイアログクラス
//******************************************************************************
@interface MTWindowSizeCfgDlg : NSWindowController {
	
	IBOutlet NSTableView* m_pTableView;
	NSMutableArray* m_pWindowSizeArray;
	YNUserConf* m_pUserConf;
	BOOL m_isChanged;
	int m_FirstSelectedIndex;
	
}

//--------------------------------------
//公開I/F

//生成
- (id)init;

//破棄
- (void)dealloc;

//モーダルウィンドウ表示
- (void)showModalWindow;

//変更確認
- (BOOL)isCahnged;

//--------------------------------------
//イベントハンドラ

//ウィンドウ読み込み完了
- (void)windowDidLoad;

//OKボタン押下
- (IBAction)onOK:(id)sender;

//Cancelボタン押下
- (IBAction)onCancel:(id)sender;

//クローズボタン押下
- (void)windowWillClose:(NSNotification*)aNotification;

//テーブルビュー：表示項目数取得
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

//テーブルビュー：表示文字列取得
- (id)tableView:(NSTableView*)aTableView
	objectValueForTableColumn:(NSTableColumn*)aTableColumn
			row:(NSInteger)rowIndex;

//--------------------------------------
//内部処理

//ダイアログ初期化
- (int)initDlg;

//設定ファイル初期化
- (int)initConfFile;

//ウィンドウサイズテーブル初期化
- (int)initWindowSizeTable;

//ウィンドウサイズ配列生成
- (int)createWindowSizeArray;

//設定保存
- (int)save;

@end


//******************************************************************************
// ウィンドウサイズクラス
//******************************************************************************
@interface MTWindowSize : NSObject {
	unsigned long m_Width;
	unsigned long m_Height;
}

- (id)init;
- (void)setWidth:(unsigned long)width;
- (void)setHeight:(unsigned long)height;
- (unsigned long)width;
- (unsigned long)height;

@end


