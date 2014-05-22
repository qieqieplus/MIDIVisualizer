//******************************************************************************
//
// MIDITrail / MTLogo
//
// MIDITrail ロゴ描画クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "MTMachTime.h"
#import "MTFontTexture.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//フォント設定
//  Windows ：フォントサイズ40 -> ビットマップサイズ縦40ピクセル (Arial)
//  Mac OS X：フォントサイズ40 -> ビットマップサイズ縦45ピクセル (Arial)
#define MTLOGO_FONTNAME  @"Arial"
#define MTLOGO_FONTSIZE  (40)

//タイトル文字列
#define MTLOGO_TITLE  @"MIDITrail"

//ロゴ描画位置情報
#define MTLOGO_POS_X  (20.0f)   //描画位置x
#define MTLOGO_POS_Y  (-15.0f)  //描画位置y
#define MTLOGO_MAG    (0.08f)   //拡大率：Windows版では0.1

//タイル分割数
#define MTLOGO_TILE_NUM  (40)

//グラデーション時間間隔(msec)
#define MTLOGO_GRADATION_TIME  (1000)

//******************************************************************************
// MIDITrail ロゴ描画クラス
//******************************************************************************
class MTLogo
{
public:
	
	//コンストラクタ／デストラクタl
	MTLogo(void);
	virtual ~MTLogo(void);
	
	//生成
	int Create(OGLDevice* pOGLDevice);
	
	//変換
	int Transform(OGLDevice* pOGLDevice);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//破棄
	void Release();
	
private:
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3CT2 MTLOGO_VERTEX;
	//struct MTLOGO_VERTEX {
	//	OGLVECTOR3 p;		//頂点座標
	//	OGLVECTOR3 n;		//法線
	//	DWORD		c;		//ディフューズ色
	//	OGLVECTOR2	t;		//テクスチャ画像位置
	//};
	
	//頂点バッファーのフォーマットの定義：座標変換済みを指定
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3CT2; }
	
private:
	
	//プリミティブ
	OGLPrimitive m_Primitive;
	
	//フォントテクスチャ
	MTFontTexture m_FontTexture;
	MTLOGO_VERTEX* m_pVertex;
	
	MTMachTime m_MachTime;
	uint64_t m_StartTime;
	
	int _CreateTexture(OGLDevice* pOGLDevice);
	
	int _CreateVertex(OGLDevice* pOGLDevice);
	
	void _SetVertexPosition(
			MTLOGO_VERTEX* pVertex,
			float x,
			float y,
			float magRate
		);
	
	void _SetGradationColor();
	
	void _SetTileColor(
			MTLOGO_VERTEX* pVertex,
			float color
		);
	
};


