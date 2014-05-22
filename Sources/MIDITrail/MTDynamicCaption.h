//******************************************************************************
//
// MIDITrail / MTDynamicCaption
//
// 動的キャプション描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 動的な文字列の高速描画を実現する。
// 表示する文字のテクスチャを作成しておき（例："ABCD...0123..."）、
// タイル状に並ぶ四角形ポリゴンに貼り付ける。
// 文字列の変更は、頂点データのテクスチャUV座標を更新するだけ。
// このため、以下の制限がある。
// (1) あらかじめ指定した文字しか使用できない。  
//     ＞テクスチャ画像固定のため
// (2) あらかじめ指定した文字数しか描画できない。
//     ＞ポリゴン数固定のため
// (3) 固定ピッチフォントしか使用できない。
//     ＞テクスチャ画像の文字位置を特定するのが困難なので
//
//   +-----------+
//   |A B C ... Z| テクスチャ画像
//   +-----------+
//   +-+-+-+-+
//   |N|E|K|O| ポリゴン上に1文字ずつ貼り付けられたテクスチャ
//   +-+-+-+-+

#import "OGLUtil.h"
#import "MTFontTexture.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//キャプション最大文字数
#define MTDYNAMICCAPTION_MAX_CHARS  (256)

//******************************************************************************
// フォントタイル描画クラス
//******************************************************************************
class MTDynamicCaption
{
public:
	
	//コンストラクタ／デストラクタ
	MTDynamicCaption(void);
	virtual ~MTDynamicCaption(void);
	
	//生成
	//  pFontName   フォント名称
	//  fontSize    フォントサイズ（ポイント）
	//  pCharacters 任意文字を指定する（最大255文字）例："0123456789"
	//  captionSize キャプション文字数
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pFontName,
			float fontSize,
			const char* pCharacters,
			unsigned long captionSize
		);
	
	//テクスチャサイズ取得
	void GetTextureSize(unsigned long* pHeight, unsigned long* pWidth);
	
	//文字列設定
	//  Createで指定していない文字は描画されない
	//  Createで指定したキャプション文字数を超えた文字は描画しない
	int SetString(char* pStr);
	
	//色設定
	void SetColor(OGLCOLOR color);
	
	//描画
	//  描画位置は座標変換済み頂点として扱う：ウィンドウ左上が(0,0)
	//  テクスチャサイズを参照した上で画面表示倍率を指定する
	//  magRate=1.0 ならテクスチャサイズのまま描画する
	int Draw(OGLDevice* pOGLDevice, float x, float y, float magRate);
	
	//リソース破棄
	void Release();
	
private:
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3CT2 MTDYNAMICCAPTION_VERTEX;
	//struct MTDYNAMICCAPTION_VERTEX {
	//	OGLVECTOR3 p;		//頂点座標
	//	float		rhw;	//除算数
	//	DWORD		c;		//ディフューズ色
	//	OGLVECTOR2	t;		//テクスチャ画像位置
	//};
	
	//頂点バッファーのフォーマットの定義：座標変換済みを指定
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3CT2; }
	
	char m_Chars[MTDYNAMICCAPTION_MAX_CHARS];
	unsigned long m_CaptionSize;
	MTFontTexture m_FontTexture;
	OGLPrimitive m_Primitive;
	OGLCOLOR m_Color;
	
	int _CreateTexture(
			OGLDevice* pOGLDevice,
			NSString* pFontName,
			float fontSize,
			const char* pCharacters
		);
	
	int _CreateVertex(OGLDevice* pOGLDevice);
	
	int _GetTextureUV(
			char target,
			OGLVECTOR2* pV0,
			OGLVECTOR2* pV1,
			OGLVECTOR2* pV2,
			OGLVECTOR2* pV3
		);
	
	void _SetVertexPosition(
			MTDYNAMICCAPTION_VERTEX* pVertex,
			float x,
			float y,
			float magRate
		);
	
	void _SetVertexColor(
			MTDYNAMICCAPTION_VERTEX* pVertex,
			OGLCOLOR color
		);
	
};


