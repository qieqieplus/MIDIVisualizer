//******************************************************************************
//
// OpenGL Utility / OGLRendererInfo
//
// レンダラ情報クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import <list>


//******************************************************************************
// 構造体定義
//******************************************************************************
//アンチエイリアス情報
typedef struct {
	GLint sampleMode;	//サンプルモード
	GLint sampleNum;	//サンプル数
} OGLAntialiasInfo;


//******************************************************************************
// レンダラ情報クラス
//******************************************************************************
class OGLRendererInfo
{
public:
	
	//コンストラクタ／デストラクタ
	OGLRendererInfo();
	virtual ~OGLRendererInfo();
	
	//初期化
	int Initialize();
	
	//アンチエイリアス情報数取得
	unsigned long GetAntialiasInfoNum();
	
	//アンチエイリアス情報取得
	int GetAntialiasInfo(
				unsigned long index,
				OGLAntialiasInfo* pAntialiasInfo
			);
	
private:
	
	typedef std::list<OGLAntialiasInfo> OGLAntialiasList;
	typedef std::list<OGLAntialiasInfo>::iterator OGLAntialiasListItr;
	
	//アンチエイリアシング情報リスト
	OGLAntialiasList m_AntialiasInfoList;
	
	int _CheckAntialias();
	int _AddAntialiasInfo(
					GLint accelerated,
					GLint sampleMode,
					GLint maxSamples
				);
	
};


