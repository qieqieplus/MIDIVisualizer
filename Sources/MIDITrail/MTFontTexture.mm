//******************************************************************************
//
// MIDITrail / MTFontTexture
//
// フォントテクスチャクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTFontTexture.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTFontTexture::MTFontTexture(void)
{
	m_pFontName = nil;
	m_FontSize = 0;
	m_TexHeight = 0;
	m_TexWidth = 0;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTFontTexture::~MTFontTexture(void)
{
	Clear();
}

//******************************************************************************
// クリア
//******************************************************************************
void MTFontTexture::Clear()
{
	[m_pFontName release];
	m_pFontName = nil;
	m_Texture.Release();
}

//******************************************************************************
// フォント設定
//******************************************************************************
int MTFontTexture::SetFont(
		NSString* pFontName,
		float fontSize,
		OGLCOLOR color,
		bool isForceFixedPitch
	)
{
	int result = 0;
	
	[pFontName retain];
	[m_pFontName release];
	m_pFontName = pFontName;
	m_FontSize = fontSize;
	m_Color = color;
	m_isForceFiexdPitch = isForceFixedPitch;
	
EXIT:;
	return result;
}

//******************************************************************************
// テクスチャ生成
//******************************************************************************
int MTFontTexture::CreateTexture(
		OGLDevice* pOGLDevice,
		NSString* pStr
	)
{
	int result = 0;
	NSColor* pTextColor = nil;
	NSFont* pFont = nil;
	NSMutableDictionary* pFontAttributes = nil;
	NSAttributedString* pAttributedString = nil;
	NSImage* pImage = nil;
	NSBitmapImageRep* pBitmap = nil;
	NSSize frameSize;
	NSRect rect;
	float bmpWidth = 0.0f;
	float bmpHeight = 0.0f;
	NSString* pFormat = nil;
	NSString* pErrMsg = nil;
	
	//フォント
	pFont = [NSFont fontWithName:m_pFontName size:m_FontSize];
	if (pFont == nil) {
		pFormat = @"MIDITrail could not open the font '%@'.\nPlease launch Font Book. Is that font enabled?";
		pErrMsg = [NSString stringWithFormat:pFormat, m_pFontName];
		result = YN_SET_ERR(pErrMsg, 0, 0);
		goto EXIT;
	}
	
	//テキスト色
	pTextColor = [NSColor colorWithCalibratedRed:m_Color.r
										   green:m_Color.g
											blue:m_Color.b
										   alpha:m_Color.a];
	
	//フォント属性
	pFontAttributes = [NSMutableDictionary dictionary];
	[pFontAttributes setObject:pFont forKey:NSFontAttributeName];
	[pFontAttributes setObject:pTextColor forKey:NSForegroundColorAttributeName];
	
	//属性付き文字列
	pAttributedString = [[NSAttributedString alloc] initWithString:pStr attributes:pFontAttributes];
	
	//イメージ生成
	frameSize = [pAttributedString size];
	pImage = [[NSImage alloc] initWithSize:frameSize];
	
	//描画開始
	[pImage lockFocus];
	{
		//アンチエイリアスを有効化
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		
		//描画色をセット
		[pTextColor set]; 
		
		//描画
		[pAttributedString drawAtPoint:NSMakePoint(0, 0)];
		
		//描画結果からビットマップ生成
		//  テクスチャ画像の最大サイズを超える場合はクリップする
		bmpWidth = frameSize.width;
		bmpHeight = frameSize.height;
		if (bmpWidth > OGL_TEXTURE_IMAGE_MAX_WIDTH) {
			bmpWidth = OGL_TEXTURE_IMAGE_MAX_WIDTH;
			//NSLog(@"WARNING: The texture image was clipped. width:%f", frameSize.width);
		}
		if (bmpHeight > OGL_TEXTURE_IMAGE_MAX_HEIGHT) {
			bmpHeight = OGL_TEXTURE_IMAGE_MAX_HEIGHT;
			//NSLog(@"WARNING: The texture image was clipped. height:%f", frameSize.height);
		}
		rect = NSMakeRect(0.0f, 0.0f, bmpWidth, bmpHeight);
		pBitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rect];
	}
	//描画終了
	[pImage unlockFocus];
	
	//テクスチャ生成
	result = m_Texture.LoadBitmap(pBitmap);
	if (result != 0) goto EXIT;
	
	m_TexWidth = m_Texture.GetWidth();
	m_TexHeight = m_Texture.GetHeight();
	
EXIT:;
	//TODO: 破棄する必要があるか？
	//[pTextColor release];
	//[pAttributedString release];
	//[pImage release];
	//[pBitmap release];
	return result;
}

//******************************************************************************
// テクスチャポインタ取得
//******************************************************************************
OGLTexture* MTFontTexture::GetTexture()
{
	return &m_Texture;
}

//******************************************************************************
// テクスチャサイズ取得
//******************************************************************************
void MTFontTexture::GetTextureSize(
		unsigned long* pHeight,
		unsigned long* pWidth
	)
{
	*pHeight = m_TexHeight;
	*pWidth = m_TexWidth;
}


