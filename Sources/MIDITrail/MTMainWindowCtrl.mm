//******************************************************************************
//
// MIDITrail / MTMainWindowCtrl
//
// メインウィンドウ制御クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTMainWindowCtrl.h"


@implementation MTMainWindowCtrl

//******************************************************************************
// 生成
//******************************************************************************
- (id)init
{
	//nib読み込み
	self = [super initWithWindowNibName:@"MainWindow"];
	if (self == nil) goto EXIT;
	
	//タイマー開始
	m_pTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
												target:self
											  selector:@selector(timerControl:)
											  userInfo:nil
											   repeats:YES];
	
	m_isAppTermOnClose = YES;
	m_isCenter = YES;
	
EXIT:;
	return self;
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	//NSLog(@"MTMainWindowCtrl dealloc");
	[m_pView release];
	[[self window] setContentView:nil];
	[m_pTimer invalidate];
	[super dealloc];
}

//******************************************************************************
// メインビュー生成
//******************************************************************************
- (int)createMainViewWithRendererParam:(OGLRedererParam)rendererParam
{
	int result = 0;
	NSRect rect;
	
	rect = [[self window] contentRectForFrameRect:[[self window] frame]];
	rect.origin.x = 0;
	rect.origin.y = 0;
	
	//メインビュー生成
	m_pView = [[MTMainView alloc] initWithFrame:rect
								  rendererParam:rendererParam];
	if (m_pView == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ウィンドウにビューを登録
	[[self window] setContentView:m_pView];
	[m_pView setAutoresizesSubviews:NO];
	
EXIT:;
	return result;
}

//******************************************************************************
// メインビュー破棄
//******************************************************************************
- (void)deleteMainView
{
	//メインビュー破棄
	[m_pView terminate];
	[m_pView release];
	m_pView = nil;
	
	//ウィンドウのビュー登録を解除
	[[self window] setContentView:nil];
	
	m_pView = nil;
}

//******************************************************************************
// メインビュー取得
//******************************************************************************
- (MTMainView*)mainView
{
	return m_pView;
}

//******************************************************************************
// ウィンドウサイズ設定
//******************************************************************************
- (void)setWindowSize:(NSSize)size
{
	NSRect newRect;
	NSRect curFrame;
	
	//現在のフレーム情報
	curFrame = [[self window] frame];
	
	//ウィンドウサイズ変更後のフレーム情報（スクリーン左下が原点）
	//  左辺の位置は変更しない
	//  上辺の位置を変更しないように下辺の位置を算出する
	newRect.size.width = size.width;
	newRect.size.height = size.height;
	newRect.origin.x = curFrame.origin.x;
	newRect.origin.y = curFrame.origin.y + (curFrame.size.height - size.height);
	
	//ウィンドウサイズ設定：タイトルバーのサイズを含む
	[[self window] setFrame:newRect display:YES animate:YES];
}

//******************************************************************************
// ウィンドウ位置設定
//******************************************************************************
- (void)setWindowPosition:(NSPoint)position
{
	NSRect screenRect;
	NSRect newRect;
	NSRect curFrame;
	
	//スクリーンのフレーム情報
	screenRect = [[NSScreen mainScreen] frame];
	
	//現在のフレーム情報
	curFrame = [[self window] frame];
	
	//ウィンドウ位置変更後のフレーム情報（スクリーン左下が原点）
	//  ウィンドウサイズは変更しない
	newRect.size.width = curFrame.size.width;
	newRect.size.height = curFrame.size.height;
	newRect.origin.x = position.x;
	newRect.origin.y = screenRect.size.height - position.y - curFrame.size.height;
	
	//ウィンドウサイズ設定：タイトルバーのサイズを含む
	[[self window] setFrame:newRect display:YES animate:YES];
	
	m_isCenter = NO;
}

//******************************************************************************
//ウィンドウ表示
//******************************************************************************
- (void)showWindow
{
	//スクリーン中央に移動
	if (m_isCenter) {
		[self setPositionToCenterOfScreen];
	}
	
	//ウィンドウ表示
	[self showWindow:nil];
}

//******************************************************************************
// スクリーン中央に移動
//******************************************************************************
- (void)setPositionToCenterOfScreen
{
	NSPoint origin;
	NSRect screenRect;
	NSRect rect;
	
	//スクリーンのフレーム情報
	screenRect = [[NSScreen mainScreen] frame];
	
	//自ウィンドウの表示位置
	rect = [[self window] frame];
	
	//自ウィンドウの位置を算出：画面左下が原点
	origin.x = screenRect.origin.x + ((screenRect.size.width - rect.size.width) / 2);
	origin.y = screenRect.origin.y + ((screenRect.size.height - rect.size.height) / 2);
	
	//自ウィンドウの表示原点を設定
	[[self window] setFrameOrigin:origin];
}

//******************************************************************************
// タイマー処理
//******************************************************************************
- (void)timerControl:(NSTimer*)aTimer
{
	NSString* pTitle = nil;
	
	//ウィンドウタイトルにFPSを表示
	if (m_pView == nil) {
		pTitle = @"MIDItrail";
	}
	else {
		pTitle = [NSString stringWithFormat:@"MIDITrail - FPS:%.1f", [m_pView FPS]];
	}
	[[self window] setTitle:pTitle];
}

//******************************************************************************
// ウィンドウクローズ
//******************************************************************************
- (void)close
{
	m_isAppTermOnClose = NO;
	[super close];
}

//******************************************************************************
// クローズボタン押下
//******************************************************************************
- (void)windowWillClose:(NSNotification*)aNotification
{
	//アプリケーション終了
	if (m_isAppTermOnClose) {
		[NSApp terminate:self];
	}
}

@end


