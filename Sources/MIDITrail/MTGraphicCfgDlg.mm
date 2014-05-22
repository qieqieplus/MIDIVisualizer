//******************************************************************************
//
// MIDITrail / MTGraphicCfgDlg
//
// グラフィック設定ダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <OpenGL/OpenGL.h>
#import "MTParam.h"
#import "MTGraphicCfgDlg.h"


@implementation MTGraphicCfgDlg

//******************************************************************************
// 生成
//******************************************************************************
- (id)init
{
	m_isEnableAntialias = NO;
	m_SampleMode = 0;
	m_SampleNum = 0;
	
	//Nibファイルを指定してウィンドウコントローラを生成
	return [super initWithWindowNibName:@"GraphicCfgDlg"];
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
	m_isChanged = NO;
	
	//モーダルウィンドウ表示
	[NSApp runModalForWindow:[self window]];
	
	//モーダル表示終了後はウィンドウを非表示にする
	[[self window] orderOut:self];
}

//******************************************************************************
// 変更確認
//******************************************************************************
- (BOOL)isCahnged
{
	return m_isChanged;
}

//******************************************************************************
// OKボタン押下
//******************************************************************************
- (IBAction)onOK:(id)sender
{
	int result = 0;
	
	//設定保存
	result = [self saveConfFile];
	if (result != 0) goto EXIT;
	
	m_isChanged = YES;
	
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
	
	//レンダリング情報初期化
	result = m_RendererInfo.Initialize();
	if (result != 0) goto EXIT;
	
	//アンチエイリアスポップアップボタン初期化
	result = [self initPopUpButtonAntiAlias];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// アンチエリアスポップアップボタン初期化
//******************************************************************************
- (int)initPopUpButtonAntiAlias
{
	int result = 0;
	unsigned long index = 0;
	unsigned long itemIndex = 0;
	unsigned long selectedIndex = 0;
	bool isSupportAA = false;
	NSMenu* pMenu = nil;
	NSMenuItem* pItem = nil;
	NSString* pItemStr = nil;
	NSString* pSampleModeName = nil;
	OGLAntialiasInfo antialiasInfo;
	
	//ユーザ設定値読み込み
	[self loadConfFile];
	
	//アンチエイリアシングサポート確認
	if (m_RendererInfo.GetAntialiasInfoNum() > 0) {
		isSupportAA = true;
	}
	
	//メニュー生成
	pMenu = [[[NSMenu alloc] initWithTitle:@"AntiAlias"] autorelease];
	
	//先頭項目を登録
	if (isSupportAA) {
		pItemStr = @"OFF";
	}
	else {
		pItemStr = @"Not supported";
	}
	pItem = [[NSMenuItem alloc] initWithTitle:pItemStr action:nil keyEquivalent:@""];
	[pItem setTag:0];
	[pMenu addItem:pItem];
	[pItem release];
	itemIndex++;
	
	//マルチサンプル種別を追加登録
	for (index = 0; index < m_RendererInfo.GetAntialiasInfoNum(); index++) {
		result = m_RendererInfo.GetAntialiasInfo(index, &antialiasInfo);
		if (result != 0) goto EXIT;
		
		if (antialiasInfo.sampleMode == kCGLSupersampleBit) {
			pSampleModeName = @"Super-sample";
		}
		else if (antialiasInfo.sampleMode == kCGLMultisampleBit) {
			pSampleModeName = @"Multi-sample";
		}
		else {
			pSampleModeName = @"UNKNOWN";
		}
		
		//マルチサンプリング種別をコンボボックスに追加
		pItemStr = [NSString stringWithFormat:@"%@ %dx", pSampleModeName, antialiasInfo.sampleNum];
		pItem = [[NSMenuItem alloc] initWithTitle:pItemStr action:nil keyEquivalent:@""];
		[pItem setTag:index];
		[pMenu addItem:pItem];
		[pItem release];
		
		if (m_isEnableAntialias
		  && (antialiasInfo.sampleMode == m_SampleMode)
		  && (antialiasInfo.sampleNum == m_SampleNum)) {
			selectedIndex = itemIndex;
		}
		itemIndex++;
	}
	
	//メニューをポップアップボタンに登録
	[m_pPopUpBtnAntiAlias setMenu:pMenu];
	//	[pMenu release];
	//リリースするとdeallocで落ちる
	
	//選択状態設定
	[m_pPopUpBtnAntiAlias selectItemAtIndex:selectedIndex];
	
	//アンチエイリアシングをサポートしていなければ不活性にする
	if (!isSupportAA) {
		[m_pPopUpBtnAntiAlias setEnabled:NO];
	}
	
	//同期
	[m_pPopUpBtnAntiAlias synchronizeTitleAndSelectedItem];
	
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
	[m_pUserConf setCategory:MT_CONF_CATEGORY_GRAPHIC];
	[m_pUserConf setSection:MT_CONF_SECTION_AA];
	
EXIT:;
	return result;
}


//******************************************************************************
// 設定ファイル読み込み
//******************************************************************************
- (void)loadConfFile
{
	int enableAntialiasing = 0;
	
	//ユーザ設定値
	enableAntialiasing = [m_pUserConf intValueForKey:@"EnableAntialias" defaultValue:0];
	if (enableAntialiasing == 0) {
		m_isEnableAntialias = NO;
	}
	else {
		m_isEnableAntialias = YES;
	}
	
	m_SampleMode = [m_pUserConf intValueForKey:@"SampleMode" defaultValue:0];
	m_SampleNum = [m_pUserConf intValueForKey:@"SampleNum" defaultValue:0];
}

//******************************************************************************
// 設定ファイル保存
//******************************************************************************
- (int)saveConfFile
{
	int result = 0;
	
	//アンチエイリアス設定保存
	result = [self saveAntiAlias];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// アンチエイリアス設定保存
//******************************************************************************
- (int)saveAntiAlias
{
	int result = 0;
	int index = 0;
	int selectedIndex = 0;
	int enableAntialias = 0;
	NSMenuItem* pItem = nil;
	OGLAntialiasInfo antialiasInfo;
	
	//選択された項目
	selectedIndex = [m_pPopUpBtnAntiAlias indexOfSelectedItem];
	
	//選択された項目に対応するマルチサンプリング種別
	if (selectedIndex == 0) {
		m_isEnableAntialias = NO;
	}
	else {
		pItem = [m_pPopUpBtnAntiAlias selectedItem];
		if (pItem == nil) {
			result = YN_SET_ERR(@"Program error.", 0, 0);
			goto EXIT;
		}
		index = [pItem tag];
		result = m_RendererInfo.GetAntialiasInfo(index, &antialiasInfo);
		if (result != 0) goto EXIT;
		
		m_isEnableAntialias = YES;
		m_SampleMode = antialiasInfo.sampleMode;
		m_SampleNum = antialiasInfo.sampleNum;
	}
	
	//設定保存
	enableAntialias = 0;
	if (m_isEnableAntialias) {
		enableAntialias = 1;
	}
	[m_pUserConf setInt:enableAntialias forKey:@"EnableAntialias"];
	[m_pUserConf setInt:m_SampleMode forKey:@"SampleMode"];
	[m_pUserConf setInt:m_SampleNum forKey:@"SampleNum"];
	
EXIT:;
	return result;
}

@end


