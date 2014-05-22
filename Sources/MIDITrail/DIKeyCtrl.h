//******************************************************************************
//
// MIDITrail / DIKeyCtrl
//
// DirectInput キー入力制御クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 現状はイベントバッファ参照機能を持たない。

#import <Cocoa/Cocoa.h>
#import "DIKeyDef.h"


//******************************************************************************
// DirectInput キー入力制御クラス
//******************************************************************************
class DIKeyCtrl
{
public:
	
	//コンストラクタ／デストラクタ
	DIKeyCtrl(void);
	virtual ~DIKeyCtrl(void);
	
	//初期化／終了
	int Initialize(NSView* pView);
	void Terminate();
	
	//アクセス権取得／解放
	int Acquire();
	int Unacquire();
	
	//現時点の状態を取得
	//  GetKeyStatusを一回呼び出してから
	//  状態を取得したいキーの数だけIsKeyDownを呼び出す
	int GetKeyStatus();
	bool IsKeyDown(unsigned char key);
	
	//アクティブ状態設定
	//  アプリケーションが非アクティブの場合はキー押下状態を無視する
	//  アプリケーションのアクティブ状態を知るAPIが見つからないため
	//  クラス利用者から教えてもらう
	void SetActiveState(bool isActive);
	
private:
	
	//アクティブ状態
	bool m_isActive;
	
};


