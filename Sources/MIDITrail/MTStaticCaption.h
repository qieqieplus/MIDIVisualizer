//******************************************************************************
//
// MIDITrail / MTStaticCaption
//
// 静的キャプション描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 静的な文字列の高速描画を実現する。
// 表示する文字のテクスチャを作成しておき、四角形ポリゴンにそのまま貼り付ける。
// 後から文字列を変更することはできない。

#import "OGLUtil.h"
#import "MTFontTexture.h"


//******************************************************************************
// 静的キャプション描画クラス
//******************************************************************************
class MTStaticCaption
{
public:
	
	//コンストラクタ／デストラクタ
	MTStaticCaption(void);
	virtual ~MTStaticCaption(void);
	
	//生成
	//  pFontName   フォント名称
	//  fontSize    フォントサイズ（ポイント）
	//  pCaption    キャプション文字列
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pFontName,
			float fontSize,
			NSString* pCaptin
		);
	
	//テクスチャサイズ取得
	void GetTextureSize(unsigned long* pHeight, unsigned long* pWidth);
	
	//色設定
	void SetColor(OGLCOLOR color);
	
	//描画
	//  描画位置は座標変換済み頂点として扱う。ウィンドウ左上が(0,0)。
	//  テクスチャサイズを参照した上で画面表示倍率を指定する。
	//  magRate=1.0 ならテクスチャサイズのまま描画される。
	int Draw(OGLDevice* pOGLDevice, float x, float y, float magRate);
	
	//リソース破棄
	void Release();
	
private:
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3CT2 MTSTATICCAPTION_VERTEX;
	//struct MTSTATICCAPTION_VERTEX {
	//	OGLVECTOR3 p;		//頂点座標
	//	float      rhw;		//除算数
	//	DWORD      c;		//ディフューズ色
	//	OGLVECTOR2 t;		//テクスチャ画像位置
	//};
	
	//頂点バッファーのフォーマットの定義：座標変換済みを指定
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3CT2; }
	
	MTFontTexture m_FontTexture;
	OGLPrimitive m_Primitive;
	OGLCOLOR m_Color;
	
	int _CreateTexture(
			OGLDevice* pOGLDevice,
			NSString* pFontName,
			float fontSize,
			NSString* pCaption
		);
	
	int _CreateVertex(OGLDevice* pOGLDevice);
	
	void _SetVertexPosition(
			MTSTATICCAPTION_VERTEX* pVertex,
			float x,
			float y,
			float magRate
		);
	
	void _SetVertexColor(
			MTSTATICCAPTION_VERTEX* pVertex,
			OGLCOLOR color
		);
	
};


