//******************************************************************************
//
// OpenGL Utility / OGLDirLight
//
// ディレクショナルライトクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLTypes.h"
#import "OGLDevice.h"


//******************************************************************************
// ディレクショナルライトクラス
//******************************************************************************
class OGLDirLight
{
public:
	
	//コンストラクタ／デストラクタ
	OGLDirLight(void);
	virtual ~OGLDirLight(void);
	
	//初期化
	int Initialize();
	
	//ライト方向登録
	//  原点を光源としてその方向をベクトルで表現する
	void SetDirection(OGLVECTOR3 dirVector);
	
	//デバイスへのライト登録
	int SetDevice(
			OGLDevice* pOGLDevice,
			bool isLightON
		);
	
private:
	
	OGLCOLOR m_Diffuse;
	OGLCOLOR m_Specular;
	OGLCOLOR m_Ambient;
	OGLVECTOR3 m_Direction;

};


