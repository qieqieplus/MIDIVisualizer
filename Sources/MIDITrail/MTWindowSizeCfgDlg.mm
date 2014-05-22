//******************************************************************************
//
// MIDITrail / MTWindowSizeCfgDlg
//
// ウィンドウサイズ設定ダイアログ
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTParam.h"
#import "MTWindowSizeCfgDlg.h"


@implementation MTWindowSizeCfgDlg

//******************************************************************************
// 生成
//******************************************************************************
- (id)init
{
	id selfid = nil;
	int result = 0;
	
	//Nibファイルを指定してウィンドウコントローラを生成
	selfid = [super initWithWindowNibName:@"WindowSizeCfgDlg"];
	
	//ウィンドウ表示項目初期化
	if (selfid != nil) {
		result = [self initDlg];
		if (result != 0) YN_SHOW_ERR();
	}
	
	return selfid;
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	[m_pTableView setDataSource:nil];
	[m_pUserConf release];
	[super dealloc];
}

//******************************************************************************
// ウィンドウ読み込み完了
//******************************************************************************
- (void)windowDidLoad
{
	int result = 0;
	NSIndexSet* indexset = nil;

	//Mac OS X 10.5 はここで表示処理を行うとスクロールバーが正しく表示されないためinitに移す
	//----
	//ウィンドウ表示項目初期化
	//  モーダル終了後に再度モーダル表示してもwindowDidLoadは呼び出されない
	//result = [self initDlg];
	//if (result != 0) goto EXIT;

	
	//上記の10.5対応の副作用としてなぜか未選択状態になってしまうため改めて選択処理を行う
	//----
	//選択行を設定
	indexset = [[NSIndexSet alloc] initWithIndex:m_FirstSelectedIndex];
	[m_pTableView selectRowIndexes:indexset byExtendingSelection:NO];
	
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
	result = [self save];
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
	
	//ウィンドウサイズテーブル初期化
	result = [self initWindowSizeTable];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// ウィンドウサイズテーブル初期化
//******************************************************************************
- (int)initWindowSizeTable
{
	int result = 0;
	int curWidth = 0;
	int curHeight = 0;
	int selectedIndex = -1;
	int index = 0;
	NSIndexSet* indexset = nil;
	MTWindowSize* pWindowSize = nil;
	
	//ウィンドウサイズ配列生成
	result = [self createWindowSizeArray];
	if (result != 0) goto EXIT;
	
	//ユーザ選択ウィンドウサイズ取得
	curWidth = [m_pUserConf intValueForKey:@"Width" defaultValue:0];
	curHeight = [m_pUserConf intValueForKey:@"Height" defaultValue:0];
	
	//初回起動時のウィンドウサイズ
	if ((curWidth <= 0) || (curHeight <= 0)) {
		curWidth = 800;
		curHeight = 600;
	}
	
	//ウィンドウサイズ配列から現在選択中のインデックスを探す
	index = 0;
	for (pWindowSize in m_pWindowSizeArray) {
		if (([pWindowSize width] == curWidth) && ([pWindowSize height] == curHeight)) {
			selectedIndex = index;
			break;
		}
		index++;
	}
	//一覧に前回設定値が見つからなかった場合はリストの先頭を選択状態とする
	if (selectedIndex < 0) {
		selectedIndex = 0;
	}
	m_FirstSelectedIndex = selectedIndex;
	
	//選択行を設定
	indexset = [[NSIndexSet alloc] initWithIndex:selectedIndex];
	[m_pTableView selectRowIndexes:indexset byExtendingSelection:NO];
	
	//複数選択を許さない
	[m_pTableView setAllowsMultipleSelection:NO];
	
	//未選択状態を許さない
	[m_pTableView setAllowsEmptySelection:NO];
	
EXIT:;
	return result;
}

//******************************************************************************
// ウィンドウサイズ配列生成
//******************************************************************************
- (int)createWindowSizeArray
{
	int result = 0;
	size_t width = 0;
	size_t height = 0;
	CGDirectDisplayID displayId = 0;
	CFArrayRef modeArray = NULL;
	CFIndex index = 0;
	NSMutableDictionary* pDictionary = nil;
	NSString* pKey = nil;
	NSArray* pAllKeys = nil;
	NSArray* pSortedKeys = nil;
	MTWindowSize* pWindowSize = nil;;

	//----
	CFDictionaryRef modeRef = NULL;
	CFNumberRef numRef = NULL;
	//---- Available in Mac OS X v10.6 and later.
	//CGDisplayModeRef modeRef = NULL;
	//----
	
	//ウィンドウサイズ配列の生成
	m_pWindowSizeArray = [[NSMutableArray alloc] init];
	
	//メインディスプレイID
	displayId = CGMainDisplayID();
	
	//ディスプレイモード配列取得
	//---- Deprecated in Mac OS X v10.6
	modeArray = CGDisplayAvailableModes(displayId);
	//---- Available in Mac OS X v10.6 and later.
	//modeArray = CGDisplayCopyAllDisplayModes(displayId, NULL);
	//----	
	if (modeArray == NULL) {
		result = YN_SET_ERR(@"CoreGraphics API error.", 0, 0);
		goto EXIT;
	}
	
	//ディスプレイモードごとの画面解像度を取得して辞書を作成する
	pDictionary = [[NSMutableDictionary alloc] init];
	for (index = 0; index < CFArrayGetCount(modeArray); index++) {
		//ディスプレイモードの縦横サイズ
		//---- Deprecated in Mac OS X v10.6
		modeRef = (CFDictionaryRef)CFArrayGetValueAtIndex(modeArray, index);
		numRef = (CFNumberRef)CFDictionaryGetValue(modeRef, kCGDisplayWidth);
		if (numRef == NULL) {
			result = YN_SET_ERR(@"Program error.", 0, 0);
			goto EXIT;
		}
		CFNumberGetValue(numRef, kCFNumberLongType, &width);
		numRef = (CFNumberRef)CFDictionaryGetValue(modeRef, kCGDisplayHeight);
		if (numRef == NULL) {
			result = YN_SET_ERR(@"Program error.", 0, 0);
			goto EXIT;
		}
		CFNumberGetValue(numRef, kCFNumberLongType, &height);
		//---- Available in Mac OS X v10.6 and later.
		//modeRef = (CGDisplayModeRef)CFArrayGetValueAtIndex(modeArray, index);
		//width = CGDisplayModeGetWidth(modeRef);
		//height = CGDisplayModeGetHeight(modeRef);
		//----
		
		//縦横サイズを文字列に変換：例 "00800-00600"
		pKey = [NSString stringWithFormat:@"%05ld-%05ld", width, height];
		
		//キーとして辞書登録する：重複するサイズを取り除くため辞書を利用している
		pWindowSize = [[MTWindowSize alloc] init];
		[pWindowSize setWidth:width];
		[pWindowSize setHeight:height];
		[pDictionary setObject:pWindowSize forKey:pKey];
		[pWindowSize release];
	}
	
	//キーの一覧を取得して昇順ソートする
	pAllKeys = [pDictionary allKeys];
	pSortedKeys = [pAllKeys sortedArrayUsingSelector:@selector(compare:)];
	
	//ウィンドウサイズ一覧作成
	for (pKey in pSortedKeys) {
		pWindowSize = [pDictionary objectForKey:pKey];
		[m_pWindowSizeArray addObject:pWindowSize];
	}
	
EXIT:;
	//CGDisplayAvailableModesで取得した配列は破棄してはならない
	//破棄すると配列を再度取得したときに破壊された配列が返される
	//if (modeArray != NULL) CFRelease(modeArray);
	[pDictionary release];
	return result;
}

//******************************************************************************
// テーブルビュー：表示項目数取得
//******************************************************************************
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [m_pWindowSizeArray count];
}

//******************************************************************************
// テーブルビュー：表示文字列取得
//******************************************************************************
- (id)tableView:(NSTableView*)aTableView
		objectValueForTableColumn:(NSTableColumn*)aTableColumn
			row:(NSInteger)rowIndex
{
	int result = 0;
	NSString* pStr = @"";
	MTWindowSize* pSize = nil;
	
	if ([[aTableColumn identifier] isEqual:@"colSize"]) {
		if (rowIndex >= [m_pWindowSizeArray count]) {
			result = YN_SET_ERR(@"Program error.", 0, 0);
			goto EXIT;
		}
		pSize = [m_pWindowSizeArray objectAtIndex:rowIndex];
		pStr = [NSString stringWithFormat:@"%d x %d", [pSize width], [pSize height]];
	}
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	return pStr;
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
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_WINDOWSIZE];
	
EXIT:;
	return result;
}

//******************************************************************************
// 設定ファイル保存
//******************************************************************************
- (int)save
{
	int result = 0;
	NSIndexSet* pIndexSet = nil;
	NSUInteger selectedIndex = 0;
	MTWindowSize* pSize = nil;
	
	//選択項目のインデックスを取得
	pIndexSet = [m_pTableView selectedRowIndexes];
	if ([pIndexSet count] != 1) {
		result = YN_SET_ERR(@"Program error.", [pIndexSet count], 0);
		goto EXIT;
	}
	selectedIndex = [pIndexSet firstIndex];
	
	//インデックスに対応する縦横サイズを取得
	if (selectedIndex >= [m_pWindowSizeArray count]) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	pSize = [m_pWindowSizeArray objectAtIndex:selectedIndex];
	
	//設定保存
	[m_pUserConf setInt:[pSize width] forKey:@"Width"];
	[m_pUserConf setInt:[pSize height] forKey:@"Height"];
	
EXIT:;
	return result;
}

@end


//ウィンドウサイズクラス
@implementation MTWindowSize

//******************************************************************************
// 初期化
//******************************************************************************
- (id)init
{
	[super init];
	
	m_Width = 0;
	m_Height = 0;
	
	return self;
}

//******************************************************************************
// サイズ登録：横
//******************************************************************************
- (void)setWidth:(unsigned long)width
{
	m_Width = width;
}

//******************************************************************************
// サイズ登録：縦
//******************************************************************************
- (void)setHeight:(unsigned long)height
{
	m_Height = height;
}

//******************************************************************************
// サイズ取得：横
//******************************************************************************
- (unsigned long)width
{
	return m_Width;
}

//******************************************************************************
// サイズ取得：縦
//******************************************************************************
- (unsigned long)height
{
	return m_Height;
}

@end


