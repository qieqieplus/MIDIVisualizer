//******************************************************************************
//
// OpenGL Utility / OGLRendererInfo
//
// レンダラ情報クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <OpenGL/OpenGL.h>
#import "YNBaseLib.h"
#import "OGLRendererInfo.h"


//*****************************************************************************
// コンストラクタ
//******************************************************************************
OGLRendererInfo::OGLRendererInfo(void)
{
}

//*****************************************************************************
// デストラクタ
//******************************************************************************
OGLRendererInfo::~OGLRendererInfo(void)
{
	m_AntialiasInfoList.clear();
}

//*****************************************************************************
// 初期化
//******************************************************************************
int OGLRendererInfo::Initialize()
{
	int result = 0;
	
	//ハードウェアのアンチエイリアシングサポート状況を確認する
	result = _CheckAntialias();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//*****************************************************************************
// アンチエイリアシングサポートチェック
//******************************************************************************
int OGLRendererInfo::_CheckAntialias()
{
	int result = 0;
	CGLError cglresult = kCGLNoError;
	CGLRendererInfoObj rendererInfo = NULL;
	GLint numberOfRenderers = 0;
	GLint rendererIndex = 0;
	GLint accelerated = 0;
	GLint sampleMode = 0;
	GLint maxSamples = 0;
	
	m_AntialiasInfoList.clear();
	
	//レンダラ情報オブジェクト取得
	cglresult = CGLQueryRendererInfo(
						CGDisplayIDToOpenGLDisplayMask(CGMainDisplayID()), //ディスプレイマスク
						&rendererInfo,		//レンダラ情報
						&numberOfRenderers	//レンダラ数
					);
	if (cglresult != kCGLNoError) {
		result = YN_SET_ERR(@"CGL API error.", cglresult, 0);
		goto EXIT;
	}
	
	//レンダラ情報取得
	for (rendererIndex = 0; rendererIndex < numberOfRenderers; rendererIndex++) {
		//ハードウェアアクセラレート
		cglresult = CGLDescribeRenderer(
							rendererInfo,		//レンダラ情報オブジェクト
							rendererIndex,		//レンダラインデックス
							kCGLRPAccelerated,	//プロパティ種別
							&accelerated		//取得した値
						);
		if (cglresult != kCGLNoError) {
			result = YN_SET_ERR(@"CGL API error.", cglresult, 0);
			goto EXIT;
		}
		
		//サポートしているサンプルモード
		cglresult = CGLDescribeRenderer(
							rendererInfo,		//レンダラ情報オブジェクト
							rendererIndex,		//レンダラインデックス
							kCGLRPSampleModes,	//プロパティ種別
							&sampleMode			//取得した値
						);
		if (cglresult != kCGLNoError) {
			result = YN_SET_ERR(@"CGL API error.", cglresult, 0);
			goto EXIT;
		}
		
		//サポートしているサンプル数
		cglresult = CGLDescribeRenderer(
							rendererInfo,		//レンダラ情報オブジェクト
							rendererIndex,		//レンダラインデックス
							kCGLRPMaxSamples,	//プロパティ種別
							&maxSamples			//取得した値
						);
		if (cglresult != kCGLNoError) {
			result = YN_SET_ERR(@"CGL API error.", cglresult, 0);
			goto EXIT;
		}
		
		//アンチエイリアス情報を登録
		if ((sampleMode & kCGLSupersampleBit) != 0) {
			result = _AddAntialiasInfo(accelerated, kCGLSupersampleBit, maxSamples);
			if (result != 0) goto EXIT;
		}
		if ((sampleMode & kCGLMultisampleBit) != 0) {
			result = _AddAntialiasInfo(accelerated, kCGLMultisampleBit, maxSamples);
			if (result != 0) goto EXIT;
		}
	}
	
	//レンダラ情報オブジェクトを破棄
	cglresult = CGLDestroyRendererInfo(rendererInfo);
	if (cglresult != kCGLNoError) {
		result = YN_SET_ERR(@"CGL API error.", cglresult, 0);
		goto EXIT;
	}
	
EXIT:;
	return result;
}

//*****************************************************************************
// アンチエイリアシングサポート情報登録
//******************************************************************************
int OGLRendererInfo::_AddAntialiasInfo(
		GLint accelerated,
		GLint sampleMode,
		GLint maxSamples
	)
{
	int result = 0;
	OGLAntialiasInfo info;
	
	//ソフトウェアレンダリングの場合
	//アンチエイリアシングが有効であっても無視する
	if (accelerated == 0) goto EXIT;
	
	info.sampleMode = sampleMode;
	
	//最大サンプル数と実際に設定できる値の関係がドキュメントに記載されていない
	//設定可能値を 2,4,6,8,16 としておく	
	if (maxSamples >= 2) {
		info.sampleNum = 2;
		m_AntialiasInfoList.push_back(info);
	}
	if (maxSamples >= 4) {
		info.sampleNum = 4;
		m_AntialiasInfoList.push_back(info);
	}
	if (maxSamples >= 6) {
		info.sampleNum = 6;
		m_AntialiasInfoList.push_back(info);
	}
	if (maxSamples >= 8) {
		info.sampleNum = 8;
		m_AntialiasInfoList.push_back(info);
	}
	if (maxSamples >= 16) {
		info.sampleNum = 16;
		m_AntialiasInfoList.push_back(info);
	}
	
EXIT:;
	return result;
}

//*****************************************************************************
// アンチエイリアスサポート情報数取得
//*****************************************************************************
unsigned long OGLRendererInfo::GetAntialiasInfoNum()
{
	return m_AntialiasInfoList.size();
}

//*****************************************************************************
// アンチエイリアスサポート情報取得
//*****************************************************************************
int OGLRendererInfo::GetAntialiasInfo(
		unsigned long index,
		OGLAntialiasInfo* pAntialiasInfo
	)
{
	int result = 0;
	OGLAntialiasListItr itr;
	
	if (index >= m_AntialiasInfoList.size()) {
		result = YN_SET_ERR(@"Program error.", index, 0);
		goto EXIT;
	}
	
	itr = m_AntialiasInfoList.begin();
	advance(itr, index);
	*pAntialiasInfo = *itr;
	
EXIT:;
	return result;
}


