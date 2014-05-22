//******************************************************************************
//
// OpenGL Utility / OGLCamera
//
// カメラクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLCamera.h"
#import "YNBaseLib.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLCamera::OGLCamera(void)
{
	_Clear();
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLCamera::~OGLCamera(void)
{
}

//******************************************************************************
// 初期化
//******************************************************************************
int OGLCamera::Initialize()
{
	_Clear();
	return 0;
}

//******************************************************************************
// 基本パラメータ設定
//******************************************************************************
void OGLCamera::SetBaseParam(
		float viewAngle,
		float nearPlane,
		float farPlane
	)
{
	m_ViewAngle = viewAngle;
	m_NearPlane = nearPlane;
	m_FarPlane = farPlane;
}

//******************************************************************************
// カメラ位置設定
//******************************************************************************
void OGLCamera::SetPosition(
		OGLVECTOR3 camVector,
		OGLVECTOR3 camLookAtVector,
		OGLVECTOR3 camUpVector
	)
{
	m_CamVector = camVector;
	m_CamLookAtVector = camLookAtVector;
	m_CamUpVector = camUpVector;
}

//******************************************************************************
// 変換
//******************************************************************************
int OGLCamera::Transform(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	GLenum glresult = 0;
	OGLVIEWPORT viewPort;
	float aspect = 0.0f;
	
	//ビューポート取得
	pOGLDevice->GetViewPort(&viewPort);
	
	//アスペクト比
	aspect = viewPort.width / viewPort.height;
	
	//ビューポート設定
	glViewport(
			viewPort.originx,	//左下隅の座標x
			viewPort.originy,	//左下隅の座標y
			viewPort.width,		//ビューポートの幅
			viewPort.height		//ビューポートの高さ
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	
	//射影行列の設定
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(
			m_ViewAngle,	//視覚度
			aspect,			//アスペクト比
			m_NearPlane,	//nearプレーン
			m_FarPlane		//farプレーン
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	
	//視線方向設定
	gluLookAt(
			m_CamVector.x,			//カメラ位置
			m_CamVector.y,			//
			m_CamVector.z,			//
			m_CamLookAtVector.x,	//注目点
			m_CamLookAtVector.y,	//
			m_CamLookAtVector.z,	//
			m_CamUpVector.x,		//カメラの上方向
			m_CamUpVector.y,		//
			m_CamUpVector.z			//
		);
	
EXIT:;
	return result;
}

//******************************************************************************
// クリア
//******************************************************************************
void OGLCamera::_Clear()
{
	m_ViewAngle = 45.0f;
	m_NearPlane = 1.0f;
	m_FarPlane = 1000.0f;
	m_CamVector = OGLVECTOR3(0.0f, 0.0f, 0.0f);
	m_CamLookAtVector = OGLVECTOR3(0.0f, 0.0f, 1.0f);
	m_CamUpVector = OGLVECTOR3(0.0f, 1.0f, 0.0f);
}


