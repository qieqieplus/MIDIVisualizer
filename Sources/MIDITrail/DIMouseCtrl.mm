//******************************************************************************
//
// MIDITrail / DIMouseCtrl
//
// DirectInput マウス制御クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "DIMouseCtrl.h"


//******************************************************************************
// マクロ定義
//******************************************************************************
#define IS_KEYDOWN(btn)  (btn & 0x80)

//******************************************************************************
// コンストラクタ
//******************************************************************************
DIMouseCtrl::DIMouseCtrl(void)
{
	m_pView = nil;
	m_TrackingArea = nil;
	m_DeltaX = 0;
	m_DeltaY = 0;
	m_DeltaWheel = 0;
	m_DeltaWheelStore = 0;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
DIMouseCtrl::~DIMouseCtrl(void)
{
	Terminate();
}

//******************************************************************************
// 初期化
//******************************************************************************
int DIMouseCtrl::Initialize(
		NSView* pView
	)
{
	int result = 0;
	NSTrackingAreaOptions options;
	
	m_pView = pView;
	
	//CGGetLastMouseDeltaでマウスの移動量を取得するため
	//対象のビューにトラッキングを追加してマウスの移動を検出するように設定しておく
	
	//トラッキングエリアのオプション
	options = ( //トラッキングエリアの種別：一つ以上指定
					// NSTrackingMouseEnteredAndExited
					NSTrackingMouseMoved
					// NSTrackingCursorUpdate
				//トラッキングエリアがアクティブになるタイミングの指定：一つのみ指定
					// | NSTrackingActiveWhenFirstResponder
					| NSTrackingActiveInKeyWindow
					// | NSTrackingActiveInActiveApp
					// | NSTrackingActiveAlways
				//トラッキングエリアの振る舞い：任意指定
					//| NSTrackingAssumeInside
					//| NSTrackingInVisibleRect
					//| NSTrackingEnabledDuringMouseDrag
			);
	
	//トラッキングエリアの生成
	m_TrackingArea = [[NSTrackingArea alloc] initWithRect:[m_pView bounds]
												  options:options
													owner:m_pView
												 userInfo:nil];
	
	//ビューにトラッキングエリアを追加する
	[m_pView addTrackingArea:m_TrackingArea];
	
EXIT:;
	return result;
}

//******************************************************************************
// 終了処理
//******************************************************************************
void DIMouseCtrl::Terminate()
{
	[m_pView removeTrackingArea:m_TrackingArea];
	[m_TrackingArea release];
	m_pView = nil;
	m_TrackingArea = nil;
}

//******************************************************************************
// デバイスアクセス権取得
//******************************************************************************
int DIMouseCtrl::Acquire()
{
	//ダミーメソッド
	return 0;
}

//******************************************************************************
// デバイスアクセス権解放
//******************************************************************************
int DIMouseCtrl::Unacquire()
{
	//ダミーメソッド
	return 0;
}

//******************************************************************************
// マウス状態取得
//******************************************************************************
int DIMouseCtrl::GetMouseStatus()
{
	//マウス移動量を取得
	//  ホイールの移動量を取得することができない
	CGGetLastMouseDelta(&m_DeltaX, &m_DeltaY);
	
	//Windows版と変化率を合わせる：感覚値
	m_DeltaX = (int32_t)((float)m_DeltaX * 0.6f);
	m_DeltaY = (int32_t)((float)m_DeltaY * 0.6f);
	
	//マウスホイール移動量
	m_DeltaWheel = m_DeltaWheelStore;
	m_DeltaWheelStore = 0;
	
	return 0;
}

//******************************************************************************
// マウス相対移動量取得
//******************************************************************************
int DIMouseCtrl::GetDelta(
		MouseAxis	target
	)
{
	int rel = 0;
	
	if (target == AxisX) {
		rel = m_DeltaX;
	}
	if (target == AxisY) {
		rel = m_DeltaY;
	}
	if (target == AxisWheel) {
		rel = m_DeltaWheel;
	}
	
EXIT:;
	return rel;
}

//******************************************************************************
// マウスホイールイベント
//******************************************************************************
void DIMouseCtrl::OnScrollWheel(
		float deltaWheelX,
		float deltaWheelY,
		float deltaWheelZ
	)
{	
	//マウスホイールの変化量のみ記録する
	//  Windows環境での移動量と同じになるように調整する
	m_DeltaWheelStore += (int32_t)(deltaWheelY * 30.0f);
}


