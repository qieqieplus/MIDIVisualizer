//******************************************************************************
//
// OpenGL Utility / OGLTransMatrix
//
// 変換行列クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLTransMatrix.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLTransMatrix::OGLTransMatrix(void)
{
	Clear();
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLTransMatrix::~OGLTransMatrix(void)
{
}

//******************************************************************************
// クリア
//******************************************************************************
void OGLTransMatrix::Clear()
{
	m_TransNum = 0;
	memset(&(m_TransInfo[0]), 0, sizeof(OGLTransInfo)*OGLTRANSMATRIX_MULTIPLY_MAX);
}

//******************************************************************************
// 拡大縮小
//******************************************************************************
void OGLTransMatrix::RegistScale(GLfloat x, GLfloat y, GLfloat z)
{
	if (m_TransNum >= OGLTRANSMATRIX_MULTIPLY_MAX) goto EXIT;
	
	m_TransInfo[m_TransNum].type = OGLTransScale;
	m_TransInfo[m_TransNum].vector = OGLVECTOR3(x, y, z);
	m_TransNum++;
	
EXIT:;
	return;
}

//******************************************************************************
// 回転：X軸周り
//******************************************************************************
void OGLTransMatrix::RegistRotationX(GLfloat angle)
{
	if (m_TransNum >= OGLTRANSMATRIX_MULTIPLY_MAX) goto EXIT;
	
	m_TransInfo[m_TransNum].type = OGLTransRotation;
	m_TransInfo[m_TransNum].vector = OGLVECTOR3(1.0f, 0.0f, 0.0f);
	m_TransInfo[m_TransNum].angle = angle;
	m_TransNum++;
	
EXIT:;
	return;
}

//******************************************************************************
// 回転：Y軸周り
//******************************************************************************
void OGLTransMatrix::RegistRotationY(GLfloat angle)
{
	if (m_TransNum >= OGLTRANSMATRIX_MULTIPLY_MAX) goto EXIT;
	
	m_TransInfo[m_TransNum].type = OGLTransRotation;
	m_TransInfo[m_TransNum].vector = OGLVECTOR3(0.0f, 1.0f, 0.0f);
	m_TransInfo[m_TransNum].angle = angle;
	m_TransNum++;
	
EXIT:;
	return;
}

//******************************************************************************
// 回転：Z軸周り
//******************************************************************************
void OGLTransMatrix::RegistRotationZ(GLfloat angle)
{
	if (m_TransNum >= OGLTRANSMATRIX_MULTIPLY_MAX) goto EXIT;
	
	m_TransInfo[m_TransNum].type = OGLTransRotation;
	m_TransInfo[m_TransNum].vector = OGLVECTOR3(0.0f, 0.0f, 1.0f);
	m_TransInfo[m_TransNum].angle = angle;
	m_TransNum++;
	
EXIT:;
	return;
}

//******************************************************************************
// 回転：任意軸周り
//******************************************************************************
void OGLTransMatrix::RegistRotationXYZ(
		GLfloat angle,
		OGLVECTOR3 axisVector
	)
{
	if (m_TransNum >= OGLTRANSMATRIX_MULTIPLY_MAX) goto EXIT;
	
	m_TransInfo[m_TransNum].type = OGLTransRotation;
	m_TransInfo[m_TransNum].vector = axisVector;
	m_TransInfo[m_TransNum].angle = angle;
	m_TransNum++;
	
EXIT:;
	return;
}

//******************************************************************************
// 移動
//******************************************************************************
void OGLTransMatrix::RegistTranslation(GLfloat x, GLfloat y, GLfloat z)
{
	if (m_TransNum >= OGLTRANSMATRIX_MULTIPLY_MAX) goto EXIT;
	
	m_TransInfo[m_TransNum].type = OGLTransToranslation;
	m_TransInfo[m_TransNum].vector = OGLVECTOR3(x, y, z);
	m_TransNum++;
	
EXIT:;
	return;
}

//******************************************************************************
// 変換行列適用
//******************************************************************************
void OGLTransMatrix::push()
{
	int index = 0;
	OGLTransInfo transInfo;
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	//行列退避
	glPushMatrix();
	
	if (m_TransNum == 0) goto EXIT;
	
	//変換行列を適用する
	//  OpenGLでは後に適用する行列演算から先に実行する必要がある
	for (index = (m_TransNum - 1); index >= 0; index--) {
		transInfo = m_TransInfo[index];
		switch (transInfo.type) {
			//回転
			case OGLTransRotation:
				glRotatef(
						transInfo.angle,
						transInfo.vector.x,
						transInfo.vector.y,
						transInfo.vector.z
					);
				break;
			//移動
			case OGLTransToranslation:
				glTranslatef(
						transInfo.vector.x,
						transInfo.vector.y,
						transInfo.vector.z
					);
				break;
			//拡大縮小
			case OGLTransScale:
				glScalef(
						transInfo.vector.x,
						transInfo.vector.y,
						transInfo.vector.z
					);
				break;
			//なし
			case OGLTransNone:
				break;
		}
	}
	
EXIT:;
	return;
}

//******************************************************************************
// 変換行列適用解除
//******************************************************************************
void OGLTransMatrix::pop()
{
	//行列復帰
	glPopMatrix();
}

//******************************************************************************
// コピー
//******************************************************************************
void OGLTransMatrix::CopyFrom(OGLTransMatrix* pTransMatrix)
{
	m_TransNum = pTransMatrix->m_TransNum;
	memcpy(
		&(m_TransInfo[0]),
		&(pTransMatrix->m_TransInfo[0]),
		sizeof(OGLTransInfo)*OGLTRANSMATRIX_MULTIPLY_MAX
	);
}


