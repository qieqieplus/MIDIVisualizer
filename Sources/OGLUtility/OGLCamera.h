//******************************************************************************
//
// OpenGL Utility / OGLCamera
//
// カメラクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLTypes.h"
#import "OGLDevice.h"


//******************************************************************************
// カメラクラス
//******************************************************************************
class OGLCamera
{
public:
	
	//コンストラクタ／デストラクタ
	OGLCamera(void);
	virtual ~OGLCamera(void);
	
	//初期化
	int Initialize();
	
	//基本パラメータ設定
	void SetBaseParam(
			float viewAngle,
			float nearPlane,
			float farPlane
		);
	
	//カメラ位置設定
	void SetPosition(
			OGLVECTOR3 camVector,
			OGLVECTOR3 camLookAtVector,
			OGLVECTOR3 camUpVector
		);
	
	//更新
	int Transform(OGLDevice* pOGLDevice);
	
private:
	
	//カメラの画角
	float m_ViewAngle;
	
	//Nearプレーン：0だとZ軸順制御がおかしくなる
	float m_NearPlane;
	
	//Farプレーン
	float m_FarPlane;
	
	//カメラ位置
	OGLVECTOR3 m_CamVector;
	
	//注目点
	OGLVECTOR3 m_CamLookAtVector;
	
	//カメラの上方向
	OGLVECTOR3 m_CamUpVector;
	
	void _Clear();

};


