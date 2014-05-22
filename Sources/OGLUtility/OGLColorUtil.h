//******************************************************************************
//
// OpenGL Utility / OGLColorUtil
//
// カラーユーティリティクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLTypes.h"


//******************************************************************************
// カラーユーティリティクラス
//******************************************************************************
class OGLColorUtil
{
public:
	
	//RGBA（16進数文字列）からの数値変換
	static OGLCOLOR MakeColorFromHexRGBA(const NSString* pHexRGBA);
	
private:
	
	//コンストラクタ／デストラクタ
	OGLColorUtil(void);
	virtual ~OGLColorUtil(void);
	
	//代入とコピーコンストラクタの禁止
	void operator=(const OGLColorUtil&);
	OGLColorUtil(const OGLColorUtil&);

};


