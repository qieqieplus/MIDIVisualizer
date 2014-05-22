//******************************************************************************
//
// OpenGL Utility / OGLScene
//
// シーン基底クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// OGLRendererに対応する抽象クラス。

#import "OGLDevice.h"


//******************************************************************************
// シーン基底クラス
//******************************************************************************
class OGLScene
{
public:
	
	//コンストラクタ／デストラクタ
	OGLScene(void);
	virtual ~OGLScene(void);
	
	//背景色設定
	virtual void SetBGColor(OGLCOLOR color);
	
	//背景色取得
	virtual OGLCOLOR GetBGColor();
	
	//描画
	virtual int Draw(OGLDevice* pOGLDevice);
	
private:
	
	//背景色
	OGLCOLOR m_BGColor;
	
};


