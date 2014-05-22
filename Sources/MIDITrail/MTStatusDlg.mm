//******************************************************************************
//
// MIDITrail / MTStatusDlg
//
// ステータスダイアログ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTStatusDlg.h"


@implementation MTStatusDlg

//******************************************************************************
// 生成
//******************************************************************************
- (id)initWithMessage:(NSString*)pMessage
{
	m_pMessage = pMessage;
	[m_pMessage retain];
	
	//Nibファイルを指定してウィンドウコントローラを生成
	return [super initWithWindowNibName:@"StatusDlg"];
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	[m_pMessage release];
	[super dealloc];
}

//******************************************************************************
// ウィンドウ読み込み完了
//******************************************************************************
- (void)windowDidLoad
{
	//メッセージ登録
	[m_pLabel setStringValue:m_pMessage];
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
// ウィンドウクローズ
//******************************************************************************
- (void)closeWindow
{
	if (m_isShow) {
		[self close];
		m_isShow = NO;
	}
}

@end


