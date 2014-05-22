//******************************************************************************
//
// OpenGL Utility / OGLTypes
//
// データ型定義
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLTypes.h"


//******************************************************************************
// 二次元ベクトル
//******************************************************************************
#pragma mark OGLVECTOR2

//------------------------------------------------------------------------------
// コンストラクタ
//------------------------------------------------------------------------------
OGLVECTOR2::OGLVECTOR2(GLfloat init_x, GLfloat init_y)
{
	this->x = init_x;
	this->y = init_y;
}

//------------------------------------------------------------------------------
// キャスト
//------------------------------------------------------------------------------
OGLVECTOR2::operator GLfloat* ()
{
	return &(this->x);
}
OGLVECTOR2::operator const GLfloat* () const
{
	return &(this->x);
}

//------------------------------------------------------------------------------
// 演算子：vectorA += vectorB
//------------------------------------------------------------------------------
OGLVECTOR2& OGLVECTOR2::operator += (const OGLVECTOR2& other)
{
	this->x += other.x;
	this->y += other.y;
	return *this;
}
OGLVECTOR2& OGLVECTOR2::operator -= (const OGLVECTOR2& other)
{
	this->x -= other.x;
	this->y -= other.y;
	return *this;
}

//------------------------------------------------------------------------------
// 演算子：+ vectorA
//------------------------------------------------------------------------------
OGLVECTOR2 OGLVECTOR2::operator + () const
{
	OGLVECTOR2 v;
	v.x = +(this->x);
	v.y = +(this->y);
	return v;
}
OGLVECTOR2 OGLVECTOR2::operator - () const
{
	OGLVECTOR2 v;
	v.x = -(this->x);
	v.y = -(this->y);
	return v;
}

//------------------------------------------------------------------------------
// 演算子：vectorA + vectorB
//------------------------------------------------------------------------------
OGLVECTOR2 OGLVECTOR2::operator + (const OGLVECTOR2& other) const
{
	OGLVECTOR2 v;
	v.x = this->x + other.x;
	v.y = this->y + other.y;
	return v;
}
OGLVECTOR2 OGLVECTOR2::operator - (const OGLVECTOR2& other) const
{
	OGLVECTOR2 v;
	v.x = this->x - other.x;
	v.y = this->y - other.y;
	return v;
}


//******************************************************************************
// 三次元ベクトル
//******************************************************************************
#pragma mark OGLVECTOR3

//------------------------------------------------------------------------------
// コンストラクタ
//------------------------------------------------------------------------------
OGLVECTOR3::OGLVECTOR3(GLfloat init_x, GLfloat init_y, GLfloat init_z)
{
	this->x = init_x;
	this->y = init_y;
	this->z = init_z;
}

//------------------------------------------------------------------------------
// キャスト
//------------------------------------------------------------------------------
OGLVECTOR3::operator GLfloat* ()
{
	return &(this->x);
}
OGLVECTOR3::operator const GLfloat* () const
{
	return &(this->x);
}

//------------------------------------------------------------------------------
// 演算子：vectorA += vectorB
//------------------------------------------------------------------------------
OGLVECTOR3& OGLVECTOR3::operator += (const OGLVECTOR3& other)
{
	this->x += other.x;
	this->y += other.y;
	this->z += other.z;
	return *this;
}
OGLVECTOR3& OGLVECTOR3::operator -= (const OGLVECTOR3& other)
{
	this->x -= other.x;
	this->y -= other.y;
	this->z -= other.z;
	return *this;
}

//------------------------------------------------------------------------------
// 演算子：+ vectorA
//------------------------------------------------------------------------------
OGLVECTOR3 OGLVECTOR3::operator + () const
{
	OGLVECTOR3 v;
	v.x = +(this->x);
	v.y = +(this->y);
	v.z = +(this->z);
	return v;
}
OGLVECTOR3 OGLVECTOR3::operator - () const
{
	OGLVECTOR3 v;
	v.x = -(this->x);
	v.y = -(this->y);
	v.z = -(this->z);
	return v;
}

//------------------------------------------------------------------------------
// 演算子：vectorA + vectorB
//------------------------------------------------------------------------------
OGLVECTOR3 OGLVECTOR3::operator + (const OGLVECTOR3& other) const
{
	OGLVECTOR3 v;
	v.x = this->x + other.x;
	v.y = this->y + other.y;
	v.z = this->z + other.z;
	return v;
}
OGLVECTOR3 OGLVECTOR3::operator - (const OGLVECTOR3& other) const
{
	OGLVECTOR3 v;
	v.x = this->x - other.x;
	v.y = this->y - other.y;
	v.z = this->z - other.z;
	return v;
}


//******************************************************************************
// 色
//******************************************************************************
#pragma mark OGLCOLOR

//------------------------------------------------------------------------------
// コンストラクタ
//------------------------------------------------------------------------------
OGLCOLOR::OGLCOLOR(GLuint rgba)
{
	this->r = (GLfloat)((rgba & 0x000000FF) >>  0) / (GLfloat)(0xFF);
	this->g = (GLfloat)((rgba & 0x0000FF00) >>  8) / (GLfloat)(0xFF);
	this->b = (GLfloat)((rgba & 0x00FF0000) >> 16) / (GLfloat)(0xFF);
	this->a = (GLfloat)((rgba & 0xFF000000) >> 24) / (GLfloat)(0xFF);
}
OGLCOLOR::OGLCOLOR(GLfloat init_r, GLfloat init_g, GLfloat init_b, GLfloat init_a)
{
	this->r = init_r;
	this->g = init_g;
	this->b = init_b;
	this->a = init_a;
}

//------------------------------------------------------------------------------
// キャスト
//------------------------------------------------------------------------------
OGLCOLOR::operator GLuint () const
{
	GLuint rgba = 0;
	rgba |= (GLubyte)(this->r * 0xFF) <<  0;
	rgba |= (GLubyte)(this->g * 0xFF) <<  8;
	rgba |= (GLubyte)(this->b * 0xFF) << 16;
	rgba |= (GLubyte)(this->a * 0xFF) << 24;
	return rgba;
}
OGLCOLOR::operator GLfloat* ()
{
	return &(this->r);
}
OGLCOLOR::operator const GLfloat* () const
{
	return &(this->r);
}

//------------------------------------------------------------------------------
// 演算子：colorA += colorB
//------------------------------------------------------------------------------
// 0.0-1.0の範囲を超えたらどうする？
OGLCOLOR& OGLCOLOR::operator += (const OGLCOLOR& other)
{
	this->r += other.r;
	this->g += other.g;
	this->b += other.b;
	this->a += other.a;
	return *this;
}
OGLCOLOR& OGLCOLOR::operator -= (const OGLCOLOR& other)
{
	this->r -= other.r;
	this->g -= other.g;
	this->b -= other.b;
	this->a -= other.a;
	return *this;
}

//------------------------------------------------------------------------------
// 演算子：+ colorA
//------------------------------------------------------------------------------
OGLCOLOR OGLCOLOR::operator + () const
{
	OGLCOLOR c;
	c.r = +(this->r);
	c.g = +(this->g);
	c.b = +(this->b);
	c.a = +(this->a);
	return c;
}
OGLCOLOR OGLCOLOR::operator - () const
{
	OGLCOLOR c;
	c.r = -(this->r);
	c.g = -(this->g);
	c.b = -(this->b);
	c.a = -(this->a);
	return c;
}

//------------------------------------------------------------------------------
// 演算子：colorA + colorB
//------------------------------------------------------------------------------
// 0.0-1.0の範囲を超えたらどうする？
OGLCOLOR OGLCOLOR::operator + (const OGLCOLOR& other) const
{
	OGLCOLOR c;
	c.r = this->r + other.r;
	c.g = this->g + other.g;
	c.b = this->b + other.b;
	c.a = this->a + other.a;
	return c;
}
OGLCOLOR OGLCOLOR::operator - (const OGLCOLOR& other) const
{
	OGLCOLOR c;
	c.r = this->r - other.r;
	c.g = this->g - other.g;
	c.b = this->b - other.b;
	c.a = this->a - other.a;
	return c;
}


