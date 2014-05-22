//******************************************************************************
//
// OpenGL Utility / OGLTexture
//
// テクスチャクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>


//******************************************************************************
// パラメータ定義
//******************************************************************************
//テクスチャ画像最大サイズ
#define OGL_TEXTURE_IMAGE_MAX_WIDTH   (2048)
#define OGL_TEXTURE_IMAGE_MAX_HEIGHT  (2048)

//******************************************************************************
// テクスチャクラス
//******************************************************************************
class OGLTexture
{
public:
	
	//コンストラクタ／デストラクタ
	OGLTexture(void);
	virtual ~OGLTexture(void);
	
	//任意画像サイズ有効化：初期値 false
	void EnableRectanbleExt(bool isEnable);
	
	//画像ファイル読み込み
	int LoadImageFile(NSString* pImageFilePath);
	
	//ビットマップ読み込み
	int LoadBitmap(NSBitmapImageRep* pBitmapImage);
	
	//破棄
	void Release();
	
	//テクスチャサイズ取得
	GLsizei GetWidth();
	GLsizei GetHeight();
	
	//テクスチャ描画開始処理
	void BindTexture();
	void UnbindTexture();
	
protected:
	
	bool m_isEnableRectangleExt;
	GLenum m_Target;
	bool m_isLoaded;
	GLuint m_TextureId;
	GLsizei m_Width;
	GLsizei m_Height;
	
private:
	
	//代入とコピーコンストラクタの禁止
	void operator=(const OGLTexture&);
	OGLTexture(const OGLTexture&);

};


