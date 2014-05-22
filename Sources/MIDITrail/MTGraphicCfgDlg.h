//******************************************************************************
//
// MIDITrail / MTGraphicCfgDlg
//
// グラフィック設定ダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "YNBaseLib.h"
#import "OGLRendererInfo.h"


//******************************************************************************
// グラフィック設定ダイアログクラス
//******************************************************************************
@interface MTGraphicCfgDlg : NSWindowController {
	
	IBOutlet NSPopUpButton* m_pPopUpBtnAntiAlias;
	YNUserConf* m_pUserConf;
	OGLRendererInfo m_RendererInfo;
	BOOL m_isChanged;
	
	BOOL m_isEnableAntialias;
	int m_SampleMode;
	int m_SampleNum;
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

//--------------------------------------
//内部処理

//ダイアログ初期化
- (int)initDlg;

// アンチエリアスポップアップボタン初期化
- (int)initPopUpButtonAntiAlias;

//設定ファイル初期化
- (int)initConfFile;

//設定ファイル読み込み
- (void)loadConfFile;

//設定保存
- (int)saveConfFile;

//アンチエイリアス設定保存
- (int)saveAntiAlias;

@end


