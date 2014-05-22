//******************************************************************************
//
// OpenGL Utility / OGLTransMatrix
//
// 変換行列クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import "OGLTypes.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//最大乗算数
//  一般的な使用例を考慮して最大6とする
//  (1) 拡大縮小
//  (2) 回転（X,Y,Z軸）
//  (3) 移動
//  (4) 拡大縮小（左手系→右手系変換）
#define OGLTRANSMATRIX_MULTIPLY_MAX  (6)


//******************************************************************************
// 変換行列クラス
//******************************************************************************
class OGLTransMatrix
{
public:
	
	//コンストラクタ／デストラクタ
	OGLTransMatrix(void);
	virtual ~OGLTransMatrix(void);
	
	//クリア
	void Clear();
	
	//拡大縮小
	void RegistScale(GLfloat x, GLfloat y, GLfloat z);
	
	//回転
	void RegistRotationX(GLfloat angle);
	void RegistRotationY(GLfloat angle);
	void RegistRotationZ(GLfloat angle);
	void RegistRotationXYZ(GLfloat angle, OGLVECTOR3 axisVector);
	
	//移動
	void RegistTranslation(GLfloat x, GLfloat y, GLfloat z);
	
	//変換行列適用／解除
	void push();
	void pop();
	
	//コピー
	void CopyFrom(OGLTransMatrix* pTransMatrix);
	
private:
	
	//変換種別
	enum OGLTransType {
		OGLTransNone,			//なし
		OGLTransScale,			//拡大縮小
		OGLTransRotation,		//回転
		OGLTransToranslation	//移動
	};
	
	//変換情報構造隊
	typedef struct {
		OGLTransType type;
		OGLVECTOR3 vector;
		GLfloat angle;
	} OGLTransInfo;
	
	//変換情報配列
	OGLTransInfo m_TransInfo[OGLTRANSMATRIX_MULTIPLY_MAX];
	
	//変換情報登録数
	unsigned long m_TransNum;

};


