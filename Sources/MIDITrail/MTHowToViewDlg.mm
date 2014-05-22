//******************************************************************************
//
// MIDITrail / MTHowToViewDlg
//
// 操作方法ダイアログ
//
// Copyright (C) 2010-2011 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTParam.h"
#import "MTHowToViewDlg.h"


@implementation MTHowToViewDlg

//******************************************************************************
// パラメータ定義
//******************************************************************************
//表示画像数
#define MT_HOWTOVIEW_IMAGE_NUM  (3)

//******************************************************************************
// 生成
//******************************************************************************
- (id)init
{
	//Nibファイルを指定してウィンドウコントローラを生成
	return [super initWithWindowNibName:@"HowToViewDlg"];
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
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
// 前ボタン押下
//******************************************************************************
- (IBAction)onPreviousButton:(id)sender
{
	int result = 0;
	
	//前の画像へ移動
	m_PageNo--;
	
	//念のためガードする
	if (m_PageNo < 0) {
		m_PageNo = 0;
	}
	
	//ボタン状態更新
	[self updateButtonStatus];
	
	//画像表示
	result = [self drawHowToImage];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// 次ボタン押下
//******************************************************************************
- (IBAction)onNextButton:(id)sender
{
	int result = 0;
	
	//次の画像へ移動
	m_PageNo++;
	
	//念のためガードする
	if (m_PageNo >= MT_HOWTOVIEW_IMAGE_NUM) {
		m_PageNo = MT_HOWTOVIEW_IMAGE_NUM - 1;
	}
	
	//ボタン状態更新
	[self updateButtonStatus];
	
	//画像表示
	result = [self drawHowToImage];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// クローズボタン押下
//******************************************************************************
- (IBAction)onCloseButton:(id)sender
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
	
	//先頭ページ
	m_PageNo = 0;
	
	//画像表示
	result = [self drawHowToImage];
	if (result != 0) goto EXIT;
	
	//ボタン状態更新
	[self updateButtonStatus];
	
EXIT:;
	return result;
}

//******************************************************************************
// 画像表示
//******************************************************************************
- (int)drawHowToImage
{
	int result = 0;
	NSString* pFilePath = nil;
	NSImage* pImage = nil;
	NSString* pFileName[3] = { MT_IMGFILE_HOWTOVIEW1, MT_IMGFILE_HOWTOVIEW2, MT_IMGFILE_HOWTOVIEW3 };
	
	if (m_PageNo >= MT_HOWTOVIEW_IMAGE_NUM) {
		result = YN_SET_ERR(@"Program error.", m_PageNo, 0);
		goto EXIT;
	}
	
	//画像ファイルパス
	pFilePath = [NSString stringWithFormat:@"%@/%@",
							[YNPathUtil resourceDirPath], pFileName[m_PageNo]];
	
	//画像読み込み
	pImage = [[NSImage alloc] initWithContentsOfFile:pFilePath];
	if (pImage == nil) {
		result = YN_SET_ERR(@"Image file load error.", 0, 0);
		goto EXIT;
	}
	
	//コンテンツ領域のサイズを画像サイズに合わせる
	//[[self window] setContentSize:[pImage size]];
	
	//画像表示
	[m_pImageView setImage:pImage];
	
EXIT:;
	return result;
}

//******************************************************************************
// ボタン状態更新
//******************************************************************************
- (void)updateButtonStatus
{
	[m_pPreviousButton setEnabled:YES];
	[m_pNextButton setEnabled:YES];
	
	//先頭画像表示：前ボタン不活性
	if (m_PageNo == 0) {
		[m_pPreviousButton setEnabled:NO];
	}
	//最終画像表示：次ボタン不活性
	if (m_PageNo == (MT_HOWTOVIEW_IMAGE_NUM - 1)) {
		[m_pNextButton setEnabled:NO];
	}
}


@end


