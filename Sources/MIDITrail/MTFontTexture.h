//******************************************************************************
//
// MIDITrail / MTFontTexture
//
// フォントテクスチャクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"


//******************************************************************************
//  フォントテクスチャクラス
//******************************************************************************
class MTFontTexture
{
public:
	
	//コンストラクタ／デストラクタ
	MTFontTexture(void);
	virtual ~MTFontTexture(void);
	
	//クリア
	void Clear();
	
	//フォント設定
	int SetFont(
			NSString* pFontName,
			float fontSize,
			OGLCOLOR color,
			bool isForceFixedPitch = false
		);
	
	//テクスチャ生成
	int CreateTexture(OGLDevice* pOGLDevice, NSString* pStr);
	
	//テクスチャインターフェースポインタ参照
	//  テクスチャオブジェクトは本クラスで管理するため、
	//  テクスチャを使用している期間は本クラスのインスタンスを破棄してはならない。
	OGLTexture* GetTexture();
	
	//テクスチャサイズ取得
	void GetTextureSize(unsigned long* pHeight, unsigned long* pWidth);
	
private:
	
	OGLTexture m_Texture;
	
	NSString* m_pFontName;
	float m_FontSize;
	OGLCOLOR m_Color;
	bool m_isForceFiexdPitch;
	
	unsigned long m_TexHeight;
	unsigned long m_TexWidth;
	
};


