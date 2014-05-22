//******************************************************************************
//
// OpenGL Utility / OGLTexture
//
// テクスチャクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "OGLTexture.h"


//##############################################################################
// テクスチャクラス
//##############################################################################
//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLTexture::OGLTexture(void)
{
	m_isEnableRectangleExt = false;
	m_Target = GL_TEXTURE_2D;
	m_isLoaded = false;
	m_TextureId = 0;
	m_Width = 0;
	m_Height = 0;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLTexture::~OGLTexture(void)
{
	Release();
}

//******************************************************************************
// 任意画像サイズ有効化：初期値 false
//******************************************************************************
void OGLTexture::EnableRectanbleExt(
		bool isEnable
	)
{
	m_isEnableRectangleExt = isEnable;
	m_Target = GL_TEXTURE_RECTANGLE_EXT;
}

//******************************************************************************
// 画像ファイル読み込み
//******************************************************************************
int OGLTexture::LoadImageFile(
		NSString* pImageFilePath
	)
{
	int result = 0;
	NSBitmapImageRep* pBitmapImage = nil;
	
	//画像ファイル読み込み
	pBitmapImage = [NSBitmapImageRep imageRepWithContentsOfFile:pImageFilePath];
	if (pBitmapImage == nil) {
		result = YN_SET_ERR(@"Bitmap file open error.", 0, 0);
		goto EXIT;
	}
	
	//ビットマップからテクスチャ作成
	result = LoadBitmap(pBitmapImage);
	if (result != 0) goto EXIT;
	
EXIT:;
	//TOOD: pBitmapImageはautoreleaseされている？
	return result;
}

//******************************************************************************
// ビットマップ読み込み
//******************************************************************************
int OGLTexture::LoadBitmap(
		NSBitmapImageRep* pBitmapImage
	)
{
	int result = 0;
	GLenum glresult = 0;
	NSInteger bitsPerPixel = 0;
	GLenum pixelDataFormat;
	unsigned char* pBitmapData = NULL;
	
	if (pBitmapImage == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	Release();
	
	m_Width = [pBitmapImage pixelsWide];
	m_Height = [pBitmapImage pixelsHigh];
	bitsPerPixel = [pBitmapImage bitsPerPixel];
	pBitmapData = [pBitmapImage bitmapData];
	
	if ((m_Width > OGL_TEXTURE_IMAGE_MAX_WIDTH) 
	 || (m_Height > OGL_TEXTURE_IMAGE_MAX_HEIGHT)) {
		result = YN_SET_ERR(@"Bitmap size is too large.", m_Width, m_Height);
		goto EXIT;
	}
	
	//ピクセルデータフォーマット確認
	if (bitsPerPixel == 24) {
		//24bitカラー
		pixelDataFormat = GL_RGB;
	}
	else if (bitsPerPixel == 32) {
		//24bitカラー＋8bitアルファ
		pixelDataFormat = GL_RGBA;
	}
	else {
		result = YN_SET_ERR(@"Unsupported bitmap format.", bitsPerPixel, 0);
		goto EXIT;
	}
	
	//テクスチャ有効
	glEnable(m_Target);
	
	//テクスチャID生成
	glGenTextures(1, &m_TextureId);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	
	//テクスチャバインド
	glBindTexture(m_Target, m_TextureId);
	
	//テクスチャ画像を登録
	glTexImage2D(
			m_Target,			//ターゲット
			0,					//詳細レベル：ベースイメージレベル
			pixelDataFormat,	//色要素数
			m_Width,			//幅
			m_Height,			//高さ
			0,					//ボーダー幅
			pixelDataFormat,	//ピクセルデータフォーマット
			GL_UNSIGNED_BYTE,	//ピクセルデータタイプ
			pBitmapData			//画像データ
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	
	//テクスチャ無効化
	glDisable(m_Target);
	
	m_isLoaded = true;
	
EXIT:;
	return result;
}

//******************************************************************************
// 破棄
//******************************************************************************
void OGLTexture::Release()
{
	if (m_isLoaded) {
		glDeleteTextures(1, &m_TextureId);
		m_isLoaded = false;
		m_TextureId = 0;
	}
	m_Width = 0;
	m_Height = 0;
}

//******************************************************************************
// テクスチャサイズ取得：幅
//******************************************************************************
GLsizei OGLTexture::GetWidth()
{
	return m_Width;
}

//******************************************************************************
// テクスチャサイズ取得：高さ
//******************************************************************************
GLsizei OGLTexture::GetHeight()
{
	return m_Height;
}

//******************************************************************************
// テクスチャ描画開始処理
//******************************************************************************
void OGLTexture::BindTexture()
{
	//テクスチャ繰り返し無効（有効にする場合はGL_REPEAT）
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	
	//この設定がないとテクスチャが描画されない
	//テクスチャ拡大縮小方式
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,  GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,  GL_LINEAR);
	
	if (m_isLoaded) {
		//テクスチャ有効化
		glEnable(m_Target);
		//テクスチャ登録
		glBindTexture(m_Target, m_TextureId);
	}
}

//******************************************************************************
// テクスチャ描画終了処理
//******************************************************************************
void OGLTexture::UnbindTexture()
{
	if (m_isLoaded) {
		//テクスチャ無効化
		glDisable(m_Target);
	}
}


