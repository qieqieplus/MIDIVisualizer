//******************************************************************************
//
// OpenGL Utility / OGLRenderer
//
// レンダラクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "OGLTypes.h"
#import "OGLDevice.h"
#import "OGLScene.h"
#import <list>


//******************************************************************************
// 構造体定義
//******************************************************************************
typedef struct {
	BOOL isEnableAntialiasing;
	int sampleMode;
	int sampleNum;
} OGLRedererParam;

//******************************************************************************
// レンダラクラス
//******************************************************************************
class OGLRenderer
{
public:
	
	//コンストラクタ／デストラクタ
	OGLRenderer();
	virtual ~OGLRenderer();
	
	//初期化
	int Initialize(NSView* pView, OGLRedererParam rendererParam);
	
	//デバイス取得
	OGLDevice* GetDevice();
	
	//描画
	int RenderScene(OGLScene* pScene);
	
	//終了処理
	void Terminate();
	
private:
	
	//デバイス
	OGLDevice* m_pOGLDevice;

};


