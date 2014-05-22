//******************************************************************************
//
// MIDITrail / MTMIDIOUTCfgDlg
//
// MIDI出力設定ダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNBaseLib.h"
#import "SMIDILib.h"


//******************************************************************************
// MIDI出力設定ダイアログクラス
//******************************************************************************
@interface MTMIDIOUTCfgDlg : NSWindowController {
	
	IBOutlet NSPopUpButton* m_pPopUpBtnPortA;
	IBOutlet NSPopUpButton* m_pPopUpBtnPortB;
	IBOutlet NSPopUpButton* m_pPopUpBtnPortC;
	IBOutlet NSPopUpButton* m_pPopUpBtnPortD;
	IBOutlet NSPopUpButton* m_pPopUpBtnPortE;
	IBOutlet NSPopUpButton* m_pPopUpBtnPortF;
	
	YNUserConf* m_pUserConf;
	SMOutDevCtrlEx m_MIDIOutDevCtrl;
	
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

//設定保存
- (int)save;

//ポート情報保存
- (int)savePortCfg:(NSPopUpButton*)pPopUpBotton portName:(NSString*)pPortName;


@end


