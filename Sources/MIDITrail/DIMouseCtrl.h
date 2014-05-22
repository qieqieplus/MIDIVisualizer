//******************************************************************************
//
// MIDITrail / DIMouseCtrl
//
// DirectInput マウス制御クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版と異なり、複数のインスタンスを生成すると正しく動作しない。
// 現状はイベントバッファ参照機能を持たない。

#import <Cocoa/Cocoa.h>


//******************************************************************************
// DirectInput マウス制御クラス
//******************************************************************************
class DIMouseCtrl
{
public:
	
	//マウスボタン種別
	enum MouseButton {
		LeftButton,
		RightButton,
		CenterButton
	};
	
	//マウス軸種別
	enum MouseAxis {
		AxisX,
		AxisY,
		AxisWheel
	};
	
	//マウスイベント種別
	enum MouseEvent {
		LeftButtonDown,
		LeftButtonUp,
		RightButtonDown,
		RightButtonUp,
		CenterButtonDown,
		CenterButtonUp,
		AxisXMove,
		AxisYMove,
		AxisWheelMove
	};
	
public:
	
	//コンストラクタ／デストラクタ
	DIMouseCtrl(void);
	virtual ~DIMouseCtrl(void);
	
	//初期化／終了
	int Initialize(NSView* pView);
	void Terminate();
	
	//アクセス権取得／解放
	int Acquire();
	int Unacquire();
	
	//現時点の状態を取得
	//  GetMouseStatusを一回呼び出してから
	//  状態を取得したいボタンと軸の数だけIsBtnDown,GetDeltaを呼び出す
	int GetMouseStatus();
	int GetDelta(MouseAxis);
	
	//未サポート
	//bool IsBtnDown(MouseButton);
	
	//未サポート
	//バッファデータを取得
	//  pIsExistがfalseになるまで繰り返し呼び出す
	//  呼び出すたびに取得したバッファが削除される
	//int GetBuffer(bool* pIsExist, MouseEvent* pEvent, int* pDeltaAxis = NULL);
	
	//マウスホイールイベント
	//  MacOSXではマウスホイールの変化量を取得するAPIが見つからなかった
	//  マウスホイールのイベントはNSViewのイベントとして受け取るしかないため
	//  DIMouseCtrlクラス利用者側から教えてもらうことにする
	void OnScrollWheel(
				float deltaWheelX,
				float deltaWheelY,
				float deltaWheelZ
			);
	
private:
	
	NSView* m_pView;
	NSTrackingArea* m_TrackingArea;
	
	int32_t m_DeltaX;
	int32_t m_DeltaY;
	int32_t m_DeltaWheel;
	int32_t m_DeltaWheelStore;
	
};


