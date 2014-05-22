//******************************************************************************
//
// MIDITrail / MTAboutDlg
//
// ステータスダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTParam.h"
#import "MTAboutDlg.h"


@implementation MTAboutDlg

//******************************************************************************
// 生成
//******************************************************************************
- (id)init
{
	//Nibファイルを指定してウィンドウコントローラを生成
	return [super initWithWindowNibName:@"AboutDlg"];
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
	
	//画像表示
	result = [self drawIconImage];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// ウィンドウ表示
//******************************************************************************
- (void)showWindowOnWindow:(NSWindow*)pWindow
{
	//ウィンドウ表示レベル：フローティングウィンドウ
	[[self window] setLevel:NSFloatingWindowLevel];
	
	//ウィンドウ表示位置を指定ウィンドウの中央に移動
	[self setPositionToCenterOfWindow:pWindow];
	
	//ウィンドウ表示
	[self showWindow:nil];
	
	m_isShow = YES;
}

//******************************************************************************
// 指定ウィンドウの中央に移動
//******************************************************************************
- (void)setPositionToCenterOfWindow:(NSWindow*)pWindow
{
	NSPoint origin;
	NSRect targetRect;
	NSRect rect;
	
	//指定ウィンドウの表示位置
	targetRect = [pWindow frame];
	
	//自ウィンドウの表示位置
	rect = [[self window ]frame];
	
	//自ウィンドウの位置を算出：画面左下が原点
	origin.x = targetRect.origin.x + ((targetRect.size.width - rect.size.width) / 2);
	origin.y = targetRect.origin.y + ((targetRect.size.height - rect.size.height) / 2);
	
	//自ウィンドウの表示原点を設定
	[[self window] setFrameOrigin:origin];
}

//******************************************************************************
// OKボタン押下
//******************************************************************************
- (IBAction)onOK:(id)sender
{
	[self closeWindow];
}

//******************************************************************************
// ウィンドウクローズ
//******************************************************************************
- (void)closeWindow
{
	if (m_isShow) {
		[self close];
		m_isShow = NO;
	}
}

//******************************************************************************
// 画像表示
//******************************************************************************
- (int)drawIconImage
{
	int result = 0;
	NSString* pFilePath = nil;
	NSImage* pImage = nil;
	
	//画像ファイルパス
	pFilePath = [NSString stringWithFormat:@"%@/%@",
							[YNPathUtil resourceDirPath], MT_IMGFILE_ICON];
	
	//画像読み込み
	pImage = [[NSImage alloc] initWithContentsOfFile:pFilePath];
	if (pImage == nil) {
		result = YN_SET_ERR(@"Image file load error.", 0, 0);
		goto EXIT;
	}
	
	//画像表示
	[m_pImageView setImage:pImage];
	
EXIT:;
	return result;
}


@end


