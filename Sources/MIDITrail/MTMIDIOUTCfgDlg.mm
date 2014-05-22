//******************************************************************************
//
// MIDITrail / MTMIDIOUTCfgDlg
//
// MIDI出力設定ダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTParam.h"
#import "MTMIDIOUTCfgDlg.h"

@implementation MTMIDIOUTCfgDlg


//******************************************************************************
// 生成
//******************************************************************************
- (id)init
{
	//Nibファイルを指定してウィンドウコントローラを生成
	return [super initWithWindowNibName:@"MIDIOUTCfgDlg"];
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	[m_pUserConf release];
	[super dealloc];
}

//******************************************************************************
// ウィンドウ読み込み完了
//******************************************************************************
- (void)windowDidLoad
{
	int result = 0;
	
	//ウィンドウ表示項目初期化
	//  モーダル終了後に再度モーダル表示してもwindowDidLoadは呼び出されない
	result = [self initDlg];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// モーダルウィンドウ表示
//******************************************************************************
- (void)showModalWindow
{	
	//モーダルウィンドウ表示
	[NSApp runModalForWindow:[self window]];
	
	//モーダル表示終了後はウィンドウを非表示にする
	[[self window] orderOut:self];
}

//******************************************************************************
// OKボタン押下
//******************************************************************************
- (IBAction)onOK:(id)sender
{
	int result = 0;
	
	//設定保存
	result = [self save];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	//モーダル表示終了
	[NSApp stopModal];
}

//******************************************************************************
// Cancelボタン押下：またはESCキー押下
//******************************************************************************
- (IBAction)onCancel:(id)sender
{
	//モーダル表示終了
	[NSApp stopModal];
}

//******************************************************************************
// クローズボタン押下
//******************************************************************************
- (void)windowWillClose:(NSNotification*)aNotification
{
	//モーダル表示終了
	[NSApp stopModal];	
}

//******************************************************************************
// ダイアログ初期化
//******************************************************************************
- (int)initDlg
{
	int result = 0;
	
	//設定ファイル初期化
	result = [self initConfFile];
	if (result != 0) goto EXIT;
	
	//MIDI出力デバイス制御の初期化
	result = m_MIDIOutDevCtrl.Initialize();
	if (result != 0) goto EXIT;
	
	//MIDI出力デバイス選択ポップアップボタン初期化
	result = [self initPopUpButton:m_pPopUpBtnPortA portName:@"PortA"];
	if (result != 0) goto EXIT;
	result = [self initPopUpButton:m_pPopUpBtnPortB portName:@"PortB"];
	if (result != 0) goto EXIT;
	result = [self initPopUpButton:m_pPopUpBtnPortC portName:@"PortC"];
	if (result != 0) goto EXIT;
	result = [self initPopUpButton:m_pPopUpBtnPortD portName:@"PortD"];
	if (result != 0) goto EXIT;
	result = [self initPopUpButton:m_pPopUpBtnPortE portName:@"PortE"];
	if (result != 0) goto EXIT;
	result = [self initPopUpButton:m_pPopUpBtnPortF portName:@"PortF"];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// ポップアップボタン初期化
//******************************************************************************
- (int)initPopUpButton:(NSPopUpButton*)pPopUpButton portName:(NSString*)pPortName
{
	int result = 0;
	unsigned long index = 0;
	unsigned long itemIndex = 0;
	unsigned long selectedIndex = 0;
	NSString* pSelectedDevIDname = nil;
	NSString* pDevIDname = nil;
	NSString* pDevDisplayName = nil;
	NSMenu* pMenu = nil;
	NSMenuItem* pItem = nil;
	
	//ユーザ選択デバイス識別名取得
	pSelectedDevIDname = [m_pUserConf strValueForKey:pPortName defaultValue:@""];
	
	//ユーザ選択デバイスがない場合は「選択なし」を選択状態にする
	if ([pSelectedDevIDname isEqual:@""]) {
		selectedIndex = 0;
	}
	
	//メニュー生成
	pMenu = [[[NSMenu alloc] initWithTitle:@"Port A"] autorelease];
	
	//メニュー項目「選択なし」をメニューに追加
	pItem = [[NSMenuItem alloc] initWithTitle:@"(none)" action:nil keyEquivalent:@""];
	[pItem setTag:index];
	[pMenu addItem:pItem];
	[pItem release];
	itemIndex++;
	
	for (index = 0; index < m_MIDIOutDevCtrl.GetDevNum(); index++) {
		//表示デバイス名をメニューに追加
		pDevIDname = m_MIDIOutDevCtrl.GetDevIdName(index);
		pDevDisplayName = m_MIDIOutDevCtrl.GetDevDisplayName(index);
		pItem = [[NSMenuItem alloc] initWithTitle:pDevDisplayName action:nil keyEquivalent:@""];
		[pItem setTag:index];
		[pMenu addItem:pItem];
		[pItem release];
		if ([pSelectedDevIDname isEqual:pDevIDname]) {
			selectedIndex = itemIndex;
		}
		itemIndex++;
	}
	
	//メニューをポップアップボタンに登録
	[pPopUpButton setMenu:pMenu];
	//	[pMenu release];
	//リリースするとdeallocで落ちる
	
	//選択状態設定
	[pPopUpButton selectItemAtIndex:selectedIndex];
	
	//同期
	[pPopUpButton synchronizeTitleAndSelectedItem];
	
EXIT:;
	return result;
}

//******************************************************************************
// 設定ファイル初期化
//******************************************************************************
- (int)initConfFile
{
	int result = 0;
	
	//ユーザ設定情報初期化
	[m_pUserConf release];
	m_pUserConf = [[YNUserConf alloc] init];
	if (m_pUserConf == nil) {
		YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_MIDI];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIOUT];
	
EXIT:;
	return result;
}

//******************************************************************************
// 設定ファイル保存
//******************************************************************************
- (int)save
{
	int result = 0;
	
	result = [self savePortCfg:m_pPopUpBtnPortA portName:@"PortA"];
	if (result != 0) goto EXIT;
	result = [self savePortCfg:m_pPopUpBtnPortB portName:@"PortB"];
	if (result != 0) goto EXIT;
	result = [self savePortCfg:m_pPopUpBtnPortC portName:@"PortC"];
	if (result != 0) goto EXIT;
	result = [self savePortCfg:m_pPopUpBtnPortD portName:@"PortD"];
	if (result != 0) goto EXIT;
	result = [self savePortCfg:m_pPopUpBtnPortE portName:@"PortE"];
	if (result != 0) goto EXIT;
	result = [self savePortCfg:m_pPopUpBtnPortF portName:@"PortF"];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// ポート設定保存
//******************************************************************************
- (int)savePortCfg:(NSPopUpButton*)pPopUpBotton portName:(NSString*)pPortName
{
	int result = 0;
	int selectedIndex = 0;
	NSString* pDevIdName = nil;
	
	//選択された項目
	selectedIndex = [pPopUpBotton indexOfSelectedItem];
	
	//選択された項目に対応する識別用デバイス名
	if (selectedIndex == 0) {
		pDevIdName = @"";
	}
	else {
		pDevIdName = m_MIDIOutDevCtrl.GetDevIdName(selectedIndex-1);
	}
	
	//設定保存
	[m_pUserConf setStr:pDevIdName forKey:pPortName];

EXIT:;
	return result;
}

@end


