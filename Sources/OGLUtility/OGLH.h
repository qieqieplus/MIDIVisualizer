//******************************************************************************
//
// OpenGL Utility / OGLH
//
// ヘルパ関数クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLTypes.h"


//******************************************************************************
// ヘルパ関数クラス
//******************************************************************************
class OGLH
{
public:
	
	//ベクトル正規化
	static void Vec3Normalize(
		OGLVECTOR3* pNormalizedVector,
		const OGLVECTOR3* pVector
	);
	
	//ラジアン算出
	static float ToRadian(float degree);

};


