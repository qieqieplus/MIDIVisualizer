//******************************************************************************
//
// MIDITrail / MTMenuCtrl
//
// メニュー制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>


//相互参照のため先行宣言する
//ヘッダファイルは実装ファイルでインクルードする
class MIDITrailApp;

//******************************************************************************
// メニュー項目定義
//******************************************************************************
//メニュースタイル制御
#define MT_MENU_NUM  (28)

//メニュー項目種別
enum MTMenuItem {
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

//******************************************************************************
// メニュー制御クラス
//******************************************************************************
@interface MTMenuCtrl : NSObject {
	
	MIDITrailApp* m_pApp;
	
	IBOutlet NSMenuItem* m_pMenuOpen;
	IBOutlet NSMenuItem* m_pMenuPlay;
	IBOutlet NSMenuItem* m_pMenuStop;
	IBOutlet NSMenuItem* m_pMenuRepeat;
	IBOutlet NSMenuItem* m_pMenuSkipBack;
	IBOutlet NSMenuItem* m_pMenuSkipForward;
	IBOutlet NSMenuItem* m_pMenuPlaySpeedDown;
	IBOutlet NSMenuItem* m_pMenuPlaySpeedUp;
	IBOutlet NSMenuItem* m_pMenuStartMonitoring;
	IBOutlet NSMenuItem* m_pMenuStopMonitoring;	
	IBOutlet NSMenuItem* m_pMenuPianoRoll3D;
	IBOutlet NSMenuItem* m_pMenuPianoRoll2D;
	IBOutlet NSMenuItem* m_pMenuPianoRollRain;
	IBOutlet NSMenuItem* m_pMenuPianoRollRain2D;
	IBOutlet NSMenuItem* m_pMenuAutoSaveViewpoint;
	IBOutlet NSMenuItem* m_pMenuResetViewpoint;
	IBOutlet NSMenuItem* m_pMenuSaveViewpoint;
	IBOutlet NSMenuItem* m_pMenuPianoKeyboard;
	IBOutlet NSMenuItem* m_pMenuRipple;
	IBOutlet NSMenuItem* m_pMenuPitchBend;
	IBOutlet NSMenuItem* m_pMenuStars;
	IBOutlet NSMenuItem* m_pMenuCounter;
	IBOutlet NSMenuItem* m_pMenuWindowSize;
	IBOutlet NSMenuItem* m_pMenuMIDIOUT;
	IBOutlet NSMenuItem* m_pMenuMIDIIN;
	IBOutlet NSMenuItem* m_pMenuGraphic;
	IBOutlet NSMenuItem* m_pMenuHowToView;
	IBOutlet NSMenuItem* m_pMenuManual;
	IBOutlet NSMenuItem* m_pMenuQuit;
	
}

//初期化
- (int)initialize:(MIDITrailApp*)pApp;

//Playメニュー実行
- (void)performActionPlay;

//Stopメニュー実行
- (void)performActionStop;

//Quitメニュー実行
- (void)performActionQuit;

//Skip Backメニュー実行
- (void)performActionSkipBack;

//Skip Forwardメニュー実行
- (void)performActionSkipForward;

//Speed Downメニュー実行
- (void)performActionPlaySpeedDown;

//Speed Upメニュー実行
- (void)performActionPlaySpeedUp;

//Start Monitorメニュー実行
- (void)performActionStartMonitoring;

//Sttop Monitorメニュー実行
- (void)performActionStopMonitoring;

//メニュー活性状態設定
- (void)setEnabled:(BOOL)isEnable forItem:(MTMenuItem)item;

//メニューマーク設定
- (void)setMark:(BOOL)isON forItem:(MTMenuItem)item;

//メニューオブジェクト参照
- (NSMenuItem*)menuItemOf:(MTMenuItem)item;

//メニュー選択イベント
- (IBAction)onMenuAbout:(id)sender;
- (IBAction)onMenuOpen:(id)sender;
- (IBAction)onMenuPlay:(id)sender;
- (IBAction)onMenuStop:(id)sender;
- (IBAction)onMenuRepeat:(id)sender;
- (IBAction)onMenuSkipBack:(id)sender;
- (IBAction)onMenuSkipForward:(id)sender;
- (IBAction)onMenuPlaySpeedDown:(id)sender;
- (IBAction)onMenuPlaySpeedUp:(id)sender;
- (IBAction)onMenuStartMonitoring:(id)sender;
- (IBAction)onMenuStopMonitoring:(id)sender;
- (IBAction)onMenuPianoRoll3D:(id)sender;
- (IBAction)onMenuPianoRoll2D:(id)sender;
- (IBAction)onMenuPianoRollRain:(id)sender;
- (IBAction)onMenuPianoRollRain2D:(id)sender;
- (IBAction)onMenuAutoSaveViewpoint:(id)sender;
- (IBAction)onMenuResetViewpoint:(id)sender;
- (IBAction)onMenuSaveViewpoint:(id)sender;
- (IBAction)onMenuPianoKeyboard:(id)sender;
- (IBAction)onMenuRipple:(id)sender;
- (IBAction)onMenuPitchBend:(id)sender;
- (IBAction)onMenuStars:(id)sender;
- (IBAction)onMenuCounter:(id)sender;
- (IBAction)onMenuWindowSize:(id)sender;
- (IBAction)onMenuMIDIOUT:(id)sender;
- (IBAction)onMenuMIDIIN:(id)sender;
- (IBAction)onMenuGraphic:(id)sender;
- (IBAction)onMenuHowToView:(id)sender;
- (IBAction)onMenuManual:(id)sender;

//ファイルドロップ実行
- (void)onDropFile:(NSString*)pPath;


@end


