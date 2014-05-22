//******************************************************************************
//
// MIDITrail / MTStars
//
// 星描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 星をランダムに配置して描画する。

#import "OGLUtil.h"


//******************************************************************************
// 星描画クラス
//******************************************************************************
class MTStars
{
public:
	
	//コンストラクタ／デストラクタ
	MTStars(void);
	virtual ~MTStars(void);
	
	//生成
	int Create(OGLDevice* pD3DDevice, NSString* pSceneName);
	
	//更新
	int Transform(OGLDevice* pD3DDevice, OGLVECTOR3 camVector);
	
	//描画
	int Draw(OGLDevice* pD3DDevice);
	
	//破棄
	void Release();
	
	//表示設定
	void SetEnable(bool isEnable);
	
private:
	
	int m_NumOfStars;
	OGLPrimitive m_Primitive;
	
	//表示可否
	bool m_isEnable;
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3C MTSTARS_VERTEX;
	//struct MTSTARS_VERTEX {
	//	D3DXVECTOR3 p;		//頂点座標
	//	D3DXVECTOR3 n;		//法線
	//	DWORD		c;		//ディフューズ色
	//};
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3C; }
	
	int _CreateVertexOfStars(MTSTARS_VERTEX* pVertex);
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	int _LoadConfFile(NSString* pSceneName);
	
};


