//******************************************************************************
//
// OpenGL Utility / OGLTypes
//
// データ型定義ヘッダ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <GLUT/glut.h>


//******************************************************************************
// 数値型定義
//******************************************************************************
//左手系(DirectX)=>右手系(OpenGL)の座標変換マクロ
#define LH2RH(z)  (-(z))

//******************************************************************************
// 二次元ベクトル
//******************************************************************************
typedef struct OGLVECTOR2
{
public:
	
	GLfloat x;
	GLfloat y;
	
public:
	
	//コンストラクタ
	OGLVECTOR2() {};
	OGLVECTOR2(GLfloat x, GLfloat y);
	
	//キャスト
	operator GLfloat* ();
	operator const GLfloat* () const;
	
	//演算子：vectorA += vectorB
	OGLVECTOR2& operator += (const OGLVECTOR2&);
	OGLVECTOR2& operator -= (const OGLVECTOR2&);
	
	//演算子：+ vectorA
	OGLVECTOR2 operator + () const;
	OGLVECTOR2 operator - () const;
	
	//演算子：vectorA + vectorB
	OGLVECTOR2 operator + (const OGLVECTOR2&) const;
	OGLVECTOR2 operator - (const OGLVECTOR2&) const;
	
} OGLVECTOR2, *LPOGLVECTOR2;


//******************************************************************************
// 三次元ベクトル
//******************************************************************************
typedef struct OGLVECTOR3
{
public:
	
	GLfloat x;
	GLfloat y;
	GLfloat z;
	
public:
	
	//コンストラクタ
	OGLVECTOR3() {};
	OGLVECTOR3(GLfloat x, GLfloat y, GLfloat z);
	
	//キャスト
	operator GLfloat* ();
	operator const GLfloat* () const;
	
	//演算子：vectorA += vectorB
	OGLVECTOR3& operator += (const OGLVECTOR3&);
	OGLVECTOR3& operator -= (const OGLVECTOR3&);
	
	//演算子：+ vectorA
	OGLVECTOR3 operator + () const;
	OGLVECTOR3 operator - () const;
	
	//演算子：vectorA + vectorB
	OGLVECTOR3 operator + (const OGLVECTOR3&) const;
	OGLVECTOR3 operator - (const OGLVECTOR3&) const;
	
} OGLVECTOR3, *LPOGLVECTOR3;


//******************************************************************************
// 色
//******************************************************************************
typedef struct OGLCOLOR
{
public:
	
	GLfloat r;
	GLfloat g;
	GLfloat b;
	GLfloat a;
	
public:
	
	//コンストラクタ
	OGLCOLOR() {};
	OGLCOLOR(GLuint rgba);
	OGLCOLOR(GLfloat r, GLfloat g, GLfloat b, GLfloat a);
	
	//キャスト
	operator GLuint () const;
	operator GLfloat* ();
	operator const GLfloat* () const;
	
	//演算子：colorA += colorB
	OGLCOLOR& operator += (const OGLCOLOR&);
	OGLCOLOR& operator -= (const OGLCOLOR&);
	
	//演算子：+ colorA
	OGLCOLOR operator + () const;
	OGLCOLOR operator - () const;
	
	//演算子：colorA + colorB
	OGLCOLOR operator + (const OGLCOLOR&) const;
	OGLCOLOR operator - (const OGLCOLOR&) const;
	
} OGLCOLOR, *LPOGLCOLOR;


//******************************************************************************
// 頂点データセット
//******************************************************************************
//------------------------------------------------------------------------------
// 頂点データ要素
//------------------------------------------------------------------------------
#define OGLVERTEX_ELEMENT_VERTEX  (0x00000001)	//頂点座標
#define OGLVERTEX_ELEMENT_NORMAL  (0x00000010)	//法線ベクトル
#define OGLVERTEX_ELEMENT_COLOR   (0x00000100)	//色（4ub）
#define OGLVERTEX_ELEMENT_TEXTURE (0x00001000)	//テクスチャ座標

//------------------------------------------------------------------------------
// 頂点データフォーマット：頂点座標／色
//------------------------------------------------------------------------------
// データフォーマット定義
#define OGLVERTEX_TYPE_V3C (				\
			OGLVERTEX_ELEMENT_VERTEX		\
			| OGLVERTEX_ELEMENT_COLOR )

// データ構造定義
typedef struct OGLVERTEX_V3C {
	OGLVECTOR3 p;	//頂点座標
	GLuint     c;	//色(4ub)
} OGLVERTEX_V3C;

//------------------------------------------------------------------------------
// 頂点データフォーマット：頂点座標／法線ベクトル／色
//------------------------------------------------------------------------------
// データフォーマット定義
#define OGLVERTEX_TYPE_V3N3C (				\
			OGLVERTEX_ELEMENT_VERTEX		\
			| OGLVERTEX_ELEMENT_NORMAL		\
			| OGLVERTEX_ELEMENT_COLOR )

// データ構造定義
typedef struct OGLVERTEX_V3N3C {
	OGLVECTOR3 p;	//頂点座標
	OGLVECTOR3 n;	//法線ベクトル
	GLuint     c;	//色(4ub)
} OGLVERTEX_V3N3C;

//------------------------------------------------------------------------------
// 頂点データフォーマット：頂点座標／色／テクスチャ座標
//------------------------------------------------------------------------------
// データフォーマット定義
#define OGLVERTEX_TYPE_V3CT2 (				\
			OGLVERTEX_ELEMENT_VERTEX		\
			| OGLVERTEX_ELEMENT_COLOR		\
			| OGLVERTEX_ELEMENT_TEXTURE )

// データ構造定義
typedef struct OGLVERTEX_V3CT2 {
	OGLVECTOR3 p;	//頂点座標
	GLuint     c;	//色(4ub)
	OGLVECTOR2 t;	//テクスチャ座標
} OGLVERTEX_V3CT2;

//------------------------------------------------------------------------------
// 頂点データフォーマット：頂点座標／法線ベクトル／色／テクスチャ座標
//------------------------------------------------------------------------------
// データフォーマット定義
#define OGLVERTEX_TYPE_V3N3CT2 (			\
			OGLVERTEX_ELEMENT_VERTEX		\
			| OGLVERTEX_ELEMENT_NORMAL		\
			| OGLVERTEX_ELEMENT_COLOR		\
			| OGLVERTEX_ELEMENT_TEXTURE )

// データ構造定義
typedef struct OGLVERTEX_V3N3CT2 {
	OGLVECTOR3 p;	//頂点座標
	OGLVECTOR3 n;	//法線ベクトル
	GLuint     c;	//色(4ub)
	OGLVECTOR2 t;	//テクスチャ座標
} OGLVERTEX_V3N3CT2;


//******************************************************************************
// ビューポート構造体
//******************************************************************************
typedef struct OGLVIEWPORT {
	float originx;
	float originy;
	float width;
	float height;
} OGLVIEWPORT;


//******************************************************************************
// マテリアル構造体
//******************************************************************************
typedef struct OGLMATERIAL {
	OGLCOLOR Diffuse;	//拡散光
	OGLCOLOR Ambient;	//環境光
	OGLCOLOR Specular;	//鏡面反射光
	GLfloat Power;		//鏡面反射光の鮮明度 [0-128]
	OGLCOLOR Emissive;	//発光色
} OGLMATERIAL;


