//******************************************************************************
//
// OpenGL Utility / OGLDevice
//
// デバイスクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// DirectX向けに開発したコードをインポートしやすくするためのダミークラス。
// デバイス制御の機能は持たない。

#import "OGLTypes.h"
#import "OGLDevice.h"


//******************************************************************************
// デバイスクラス
//******************************************************************************
class OGLDevice
{
public:
	
	//コンストラクタ／デストラクタ
	OGLDevice(void);
	virtual ~OGLDevice(void);
	
	//初期化
	int Initialize();
	
	//破棄
	int Release();
	
	//ビューポート設定
	void SetViewPort(OGLVIEWPORT viewPort);
	
	//ビューポート取得
	void GetViewPort(OGLVIEWPORT* pViewPort);
	
private:
	
	OGLVIEWPORT m_ViewPort;

};


