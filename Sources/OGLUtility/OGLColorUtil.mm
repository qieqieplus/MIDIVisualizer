//******************************************************************************
//
// OpenGL Utility / OGLColorUtil
//
// カラーユーティリティクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLColorUtil.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLColorUtil::OGLColorUtil(void)
{
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLColorUtil::~OGLColorUtil(void)
{
}

//******************************************************************************
// RGBA（16進数文字列）からの数値変換
//******************************************************************************
OGLCOLOR OGLColorUtil::MakeColorFromHexRGBA(
		const NSString* pHexRGBA
	)
{
	float cr, cg, cb, alpha = 0.0f;
	const char* rgba = NULL;
	char* stopped = NULL;
	char buf[3];
	
	if (pHexRGBA == nil) goto EXIT;
	
	rgba = [pHexRGBA cStringUsingEncoding:NSASCIIStringEncoding];
	if (strlen(rgba) < 4) goto EXIT;
	
	buf[2] = '\0';
	
	buf[0] = rgba[0];
	buf[1] = rgba[1];
	cr     = strtoul(buf, &stopped, 16) / 255.0f;
	
	buf[0] = rgba[2];
	buf[1] = rgba[3];
	cg     = strtoul(buf, &stopped, 16) / 255.0f;
	
	buf[0] = rgba[4];
	buf[1] = rgba[5];
	cb     = strtoul(buf, &stopped, 16) / 255.0f;
	
	buf[0] = rgba[6];
	buf[1] = rgba[7];
	alpha  = strtoul(buf, &stopped, 16) / 255.0f;
	
EXIT:;
	return OGLCOLOR(cr, cg, cb, alpha);
}


