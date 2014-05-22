//******************************************************************************
//
// OpenGL Utility / OGLDirLight
//
// ディレクショナルライトクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "OGLH.h"
#import "OGLDirLight.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLDirLight::OGLDirLight(void)
{
	memset(m_Diffuse, 0, sizeof(OGLCOLOR));
	memset(m_Specular, 0, sizeof(OGLCOLOR));
	memset(m_Ambient, 0, sizeof(OGLCOLOR));
	memset(m_Direction, 0, sizeof(OGLVECTOR3));
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLDirLight::~OGLDirLight(void)
{
}

//******************************************************************************
// 初期化
//******************************************************************************
int OGLDirLight::Initialize()
{
	int result = 0;
	
	//拡散光
	m_Diffuse.r = 1.0f;
	m_Diffuse.g = 1.0f;
	m_Diffuse.b = 1.0f;
	m_Diffuse.a = 1.0f;
	
	//スペキュラ光
	//  DirectX9ではスペキュラを有効にすると、通常のライトに比べて2倍の負荷が生じる
	//  ということでAPIで無効化していたが、OpenGLには該当するAPIがない。
	//  0.0fを設定すると無効と同じになるのか？
	//  TODO: 外部から設定できるようにする
	m_Specular.r = 0.0f; //1.0f;
	m_Specular.g = 0.0f; //1.0f;
	m_Specular.b = 0.0f; //1.0f;
	m_Specular.a = 0.0f; //1.0f;
	
	//環境光
	m_Ambient.r = 0.1f; // Windows版 0.5f
	m_Ambient.g = 0.1f; // Windows版 0.5f
	m_Ambient.b = 0.1f; // Windows版 0.5f
	m_Ambient.a = 1.0f;
	
	//方向：ベクトルは正規化されていなければならない
	m_Direction = OGLVECTOR3(0.0f, 0.0f, 1.0f);
	
	return result;
}

//******************************************************************************
// ライト方向設定
//******************************************************************************
void OGLDirLight::SetDirection(
		OGLVECTOR3 dirVector
	)
{
	OGLVECTOR3 normalizedVector;
	
	//ベクトル正規化
	OGLH::Vec3Normalize(&normalizedVector, &dirVector);
	
	//ライト情報構造体に登録
	m_Direction = normalizedVector;
}

//******************************************************************************
// デバイス登録
//******************************************************************************
int OGLDirLight::SetDevice(
		OGLDevice* pOGLDevice,
		bool isLightON
	)
{
	int result = 0;
	GLfloat direction[4];
	
	//拡散光
	glLightfv(GL_LIGHT0, GL_DIFFUSE, (GLfloat*)m_Diffuse);
	
	//スペキュラ光
	glLightfv(GL_LIGHT0, GL_SPECULAR, (GLfloat*)m_Specular);
	
	//環境光
	glLightfv(GL_LIGHT0, GL_AMBIENT, (GLfloat*)m_Ambient);
	
	//ライトの位置を設定
	//  DirectXは原点を光源としてその方向をベクトルで表現するが
	//  OpenGLは光源の位置をベクトルで示して原点に光を向ける
	//  ここではDirectXの形式をOpenGLの形式に変換する
	direction[0] = -(m_Direction.x);
	direction[1] = -(m_Direction.y);
	direction[2] = -(m_Direction.z);
	direction[3] = 0.0f;  //(x,y,z)方向の無限遠からの平行光源
	glLightfv(GL_LIGHT0, GL_POSITION, direction);
	
	if (isLightON) {
		//ライトを有効にする
		glEnable(GL_LIGHTING);
		//ライト0番をON
		glEnable(GL_LIGHT0);
	}
	else {
		//ライトを無効にする
		glDisable(GL_LIGHTING);
		//ライト0番をOFF
		glDisable(GL_LIGHT0);
	}
	
EXIT:;
	return result;
}


