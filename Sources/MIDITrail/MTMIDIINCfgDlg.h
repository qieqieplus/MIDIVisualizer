//******************************************************************************
//
// MIDITrail / MTMIDIINCfgDlg
//
// MIDI入力設定ダイアログ
//
// Copyright (C) 2012 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNBaseLib.h"
#import "SMIDILib.h"


//******************************************************************************
// MIDI出力設定ダイアログクラス
//******************************************************************************
@interface MTMIDIINCfgDlg : NSWindowController {
	
	IBOutlet NSPopUpButton* m_pPopUpBtnPortA;
	IBOutlet NSButton* m_pCheckBtnMIDITHRU;
	
	YNUserConf* m_pUserConf;
	SMInDevCtrl m_MIDIInDevCtrl;
	
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

//OKボタン押下
- (IBAction)onOK:(id)sender;

//Cancelボタン押下：またはESCキー押下
- (IBAction)onCancel:(id)sender;

//クローズボタン押下
- (void)windowWillClose:(NSNotification*)aNotification;

//--------------------------------------
//内部処理

//ダイアログ初期化
- (int)initDlg;

//設定ファイル初期化
- (int)initConfFile;

//ポップアップボタン初期化
- (int)initPopUpButton:(NSPopUpButton*)pPopUpButton portName:(NSString*)pPortName;

//MIDITHRUチェックボタン初期化
- (int)initCheckBtnMIDITHRU;

//設定保存
- (int)save;

//ポート情報保存
- (int)savePortCfg:(NSPopUpButton*)pPopUpBotton portName:(NSString*)pPortName;

//MIDITHRU保存
- (int)saveMIDITHRU;

@end


