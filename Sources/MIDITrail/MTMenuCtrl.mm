//******************************************************************************
//
// MIDITrail / MTMenuCtrl
//
// メニュー制御クラス
//
// Copyright (C) 2010-2012 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTMenuCtrl.h"
#import "MIDITrailApp.h"


@implementation MTMenuCtrl

//******************************************************************************
// 初期化
//******************************************************************************
- (int)initialize:(MIDITrailApp*)pApp
{
	int result = 0;
	unsigned long index = 0;
	NSMenuItem* pItem = nil;
	
	m_pApp = pApp;
	
	//メニューID一覧
	MTMenuItem menuID[MT_MENU_NUM] = {
		MenuOpen,
		MenuPlay,
		MenuStop,
		MenuRepeat,
		MenuSkipBack,
		MenuSkipForward,
		MenuPlaySpeedDown,
		MenuPlaySpeedUp,
		MenuStartMonitoring,
		MenuStopMonitoring,
		MenuPianoRoll3D,
		MenuPianoRoll2D,
		MenuPianoRollRain,
		MenuPianoRollRain2D,
		MenuAutoSaveViewpoint,
		MenuResetViewpoint,
		MenuSaveViewpoint,
		MenuPianoKeyboard,
		MenuRipple,
		MenuPitchBend,
		MenuStars,
		MenuCounter,
		MenuWindowSize,
		MenuMIDIOUT,
		MenuMIDIIN,
		MenuGraphic,
		MenuHowToView,
		MenuManual
	};
	
	//メニュー項目ごとに親メニューの自動活性機能をOFFにする
	for (index = 0; index < MT_MENU_NUM; index++) {
		//メニューオブジェクト取得
		pItem = [self menuItemOf:menuID[index]];
		
		//メニューの自動活性機能をOFFにする
		[[pItem menu] setAutoenablesItems:NO];
	}
	
	return result;
}

//******************************************************************************
// Playメニュー実行
//******************************************************************************
- (void)performActionPlay
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuPlay menu] indexOfItem:m_pMenuPlay];
	
	//メニュー実行
	[[m_pMenuPlay menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Stopメニュー実行
//******************************************************************************
- (void)performActionStop
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuStop menu] indexOfItem:m_pMenuStop];
	
	//メニュー実行
	[[m_pMenuStop menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Quitメニュー実行
//******************************************************************************
- (void)performActionQuit
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuQuit menu] indexOfItem:m_pMenuQuit];
	
	//メニュー実行
	[[m_pMenuQuit menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Skip Backメニュー実行
//******************************************************************************
- (void)performActionSkipBack
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuSkipBack menu] indexOfItem:m_pMenuSkipBack];
	
	//メニュー実行
	[[m_pMenuSkipBack menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Skip Forwardメニュー実行
//******************************************************************************
- (void)performActionSkipForward
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuSkipForward menu] indexOfItem:m_pMenuSkipForward];
	
	//メニュー実行
	[[m_pMenuSkipForward menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Speed Downメニュー実行
//******************************************************************************
- (void)performActionPlaySpeedDown
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuPlaySpeedDown menu] indexOfItem:m_pMenuPlaySpeedDown];
	
	//メニュー実行
	[[m_pMenuPlaySpeedDown menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Speed Upメニュー実行
//******************************************************************************
- (void)performActionPlaySpeedUp
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuPlaySpeedUp menu] indexOfItem:m_pMenuPlaySpeedUp];
	
	//メニュー実行
	[[m_pMenuPlaySpeedUp menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Start Monitoringメニュー実行
//******************************************************************************
- (void)performActionStartMonitoring
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuStartMonitoring menu] indexOfItem:m_pMenuStartMonitoring];
	
	//メニュー実行
	[[m_pMenuStartMonitoring menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// Sttop Monitoringメニュー実行
//******************************************************************************
- (void)performActionStopMonitoring
{
	NSInteger menuIndex;
	
	//メニューインデックス取得
	menuIndex = [[m_pMenuStopMonitoring menu] indexOfItem:m_pMenuStopMonitoring];
	
	//メニュー実行
	[[m_pMenuStopMonitoring menu] performActionForItemAtIndex:menuIndex];
}

//******************************************************************************
// メニュー活性状態設定
//******************************************************************************
- (void)setEnabled:(BOOL)isEnable forItem:(MTMenuItem)item
{
	NSMenuItem* pItem = nil;
	
	//メニューオブジェクト取得
	pItem = [self menuItemOf:item];
	
	//メニュー活性状態設定
	[pItem setEnabled:isEnable];
}

//******************************************************************************
// メニューマーク設定
//******************************************************************************
- (void)setMark:(BOOL)isON forItem:(MTMenuItem)item
{
	NSMenuItem* pItem = nil;
	
	//メニューオブジェクト取得
	pItem = [self menuItemOf:item];
	
	//メニューマーク設定
	if (isON) {
		[pItem setState:NSOnState];
	}
	else {
		[pItem setState:NSOffState];
	}
}

//******************************************************************************
// メニューオブジェクト取得
//******************************************************************************
- (NSMenuItem*)menuItemOf:(MTMenuItem)item
{
	NSMenuItem* pItem = nil;
	
	switch (item) {
		case MenuOpen:
			pItem = m_pMenuOpen;
			break;
		case MenuPlay:
			pItem = m_pMenuPlay;
			break;
		case MenuStop:
			pItem = m_pMenuStop;
			break;
		case MenuRepeat:
			pItem = m_pMenuRepeat;
			break;
		case MenuSkipBack:
			pItem = m_pMenuSkipBack;
			break;
		case MenuSkipForward:
			pItem = m_pMenuSkipForward;
			break;
		case MenuPlaySpeedDown:
			pItem = m_pMenuPlaySpeedDown;
			break;
		case MenuPlaySpeedUp:
			pItem = m_pMenuPlaySpeedUp;
			break;
		case MenuStartMonitoring:
			pItem = m_pMenuStartMonitoring;
			break;
		case MenuStopMonitoring:
			pItem = m_pMenuStopMonitoring;
			break;
		case MenuPianoRoll3D:
			pItem = m_pMenuPianoRoll3D;
			break;
		case MenuPianoRoll2D:
			pItem = m_pMenuPianoRoll2D;
			break;
		case MenuPianoRollRain:
			pItem = m_pMenuPianoRollRain;
			break;
		case MenuPianoRollRain2D:
			pItem = m_pMenuPianoRollRain2D;
			break;
		case MenuAutoSaveViewpoint:
			pItem = m_pMenuAutoSaveViewpoint;
			break;
		case MenuResetViewpoint:
			pItem = m_pMenuResetViewpoint;
			break;
		case MenuSaveViewpoint:
			pItem = m_pMenuSaveViewpoint;
			break;
		case MenuPianoKeyboard:
			pItem = m_pMenuPianoKeyboard;
			break;
		case MenuRipple:
			pItem = m_pMenuRipple;
			break;
		case MenuPitchBend:
			pItem = m_pMenuPitchBend;
			break;
		case MenuStars:
			pItem = m_pMenuStars;
			break;
		case MenuCounter:
			pItem = m_pMenuCounter;
			break;
		case MenuWindowSize:
			pItem = m_pMenuWindowSize;
			break;
		case MenuMIDIOUT:
			pItem = m_pMenuMIDIOUT;
			break;
		case MenuMIDIIN:
			pItem = m_pMenuMIDIIN;
			break;
		case MenuGraphic:
			pItem = m_pMenuGraphic;
			break;
		case MenuHowToView:
			pItem = m_pMenuHowToView;
			break;
		case MenuManual:
			pItem = m_pMenuManual;
			break;
	}
	
	return pItem;
}

//******************************************************************************
// メニュー選択：About
//******************************************************************************
- (IBAction)onMenuAbout:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuAbout");
	
	result = m_pApp->OnMenuAbout();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ファイルオープン
//******************************************************************************
- (IBAction)onMenuOpen:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuOpen");
	
	result = m_pApp->OnMenuFileOpen();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：演奏開始／一時停止
//******************************************************************************
- (IBAction)onMenuPlay:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPlay");
	
	result = m_pApp->OnMenuPlay();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：演奏停止
//******************************************************************************
- (IBAction)onMenuStop:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuStop");
	
	result = m_pApp->OnMenuStop();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：リピート
//******************************************************************************
- (IBAction)onMenuRepeat:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuRepeat");
	
	result = m_pApp->OnMenuRepeat();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：演奏：スキップバック
//******************************************************************************
- (IBAction)onMenuSkipBack:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuSkipBack");
	
	result = m_pApp->OnMenuSkipBack();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：演奏：スキップフォワード
//******************************************************************************
- (IBAction)onMenuSkipForward:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuSkipForward");
	
	result = m_pApp->OnMenuSkipForward();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：演奏：スピードダウン
//******************************************************************************
- (IBAction)onMenuPlaySpeedDown:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPlaySpeedDown");
	
	result = m_pApp->OnMenuPlaySpeedDown();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：演奏：スピードアップ
//******************************************************************************
- (IBAction)onMenuPlaySpeedUp:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPlaySpeedUp");
	
	result = m_pApp->OnMenuPlaySpeedUp();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ライブモニタ開始
//******************************************************************************
- (IBAction)onMenuStartMonitoring:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuStartMonitoring");
	
	result = m_pApp->OnMenuStartMonitoring();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ライブモニタ停止
//******************************************************************************
- (IBAction)onMenuStopMonitoring:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuStopMonitoring");
	
	result = m_pApp->OnMenuStopMonitoring();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ビューモード選択；PianoRoll3D
//******************************************************************************
- (IBAction)onMenuPianoRoll3D:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPianoRoll3D");
	
	result = m_pApp->OnMenuSelectSceneType(MIDITrailApp::PianoRoll3D);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ビューモード選択：PianoRoll2D
//******************************************************************************
- (IBAction)onMenuPianoRoll2D:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPianoRoll2D");
	
	result = m_pApp->OnMenuSelectSceneType(MIDITrailApp::PianoRoll2D);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ビューモード選択：PianoRollRain
//******************************************************************************
- (IBAction)onMenuPianoRollRain:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPianoRollRain");
	
	result = m_pApp->OnMenuSelectSceneType(MIDITrailApp::PianoRollRain);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ビューモード選択：PianoRollRain2D
//******************************************************************************
- (IBAction)onMenuPianoRollRain2D:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPianoRollRain2D");
	
	result = m_pApp->OnMenuSelectSceneType(MIDITrailApp::PianoRollRain2D);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：自動視点保存
//******************************************************************************
- (IBAction)onMenuAutoSaveViewpoint:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuAutoSaveViewpoint");
	
	result = m_pApp->OnMenuAutoSaveViewpoint();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ビューポイントリセット
//******************************************************************************
- (IBAction)onMenuResetViewpoint:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuResetViewpoint");
	
	result = m_pApp->OnMenuResetViewpoint();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ビューポイント保存
//******************************************************************************
- (IBAction)onMenuSaveViewpoint:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuSaveViewpoint");
	
	result = m_pApp->OnMenuSaveViewpoint();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：エフェクトON/OFF：ピアノキーボード
//******************************************************************************
- (IBAction)onMenuPianoKeyboard:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPianoKeyboard");
	
	result = m_pApp->OnMenuEnableEffect(MTScene::EffectPianoKeyboard);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：エフェクトON/OFF：波紋
//******************************************************************************
- (IBAction)onMenuRipple:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuRipple");
	
	result = m_pApp->OnMenuEnableEffect(MTScene::EffectRipple);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：エフェクトON/OFF：ピッチベンド
//******************************************************************************
- (IBAction)onMenuPitchBend:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuPitchBend");
	
	result = m_pApp->OnMenuEnableEffect(MTScene::EffectPitchBend);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：表示ON/OFF：星
//******************************************************************************
- (IBAction)onMenuStars:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuStars");
	
	result = m_pApp->OnMenuEnableEffect(MTScene::EffectStars);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：表示ON/OFF：カウンタ
//******************************************************************************
- (IBAction)onMenuCounter:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuCounter");
	
	result = m_pApp->OnMenuEnableEffect(MTScene::EffectCounter);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：表示ON/OFF：星
//******************************************************************************
- (IBAction)onMenuWindowSize:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuWindowSize");
	
	result = m_pApp->OnMenuWindowSize();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：オプション：MIDI OUT設定
//******************************************************************************
- (IBAction)onMenuMIDIOUT:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuMIDIOUT");
	
	result = m_pApp->OnMenuOptionMIDIOUT();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：オプション：MIDI IN設定
//******************************************************************************
- (IBAction)onMenuMIDIIN:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuMIDIIN");
	
	result = m_pApp->OnMenuOptionMIDIIN();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：オプション：グラフィック設定
//******************************************************************************
- (IBAction)onMenuGraphic:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuGraphic");
	
	result = m_pApp->OnMenuOptionGraphic();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ヘルプ：How to view
//******************************************************************************
- (IBAction)onMenuHowToView:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuHowToView");
	
	result = m_pApp->OnMenuHowToView();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// メニュー選択：ヘルプ：マニュアル参照
//******************************************************************************
- (IBAction)onMenuManual:(id)sender
{
	int result = 0;
	
	//NSLog(@"onMenuManual");
	
	result = m_pApp->OnMenuManual();
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}

//******************************************************************************
// ファイルドロップ実行
//******************************************************************************
- (void)onDropFile:(NSString*)pPath
{
	int result = 0;
	
	//NSLog(@"onDropFile");
	
	result = m_pApp->OnDropFile(pPath);
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) {
		YN_SHOW_ERR();
	}
	return;
}


@end


