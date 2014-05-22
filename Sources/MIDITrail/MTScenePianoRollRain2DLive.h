//******************************************************************************
//
// MIDITrail / MTScenePianoRollRain2DLive
//
// ライブモニタ用ピアノロールレイン2Dシーン描画クラス
//
// Copyright (C) 2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#include "MTScenePianoRollRainLive.h"


//******************************************************************************
// ピアノロールレイン2Dシーン描画クラス
//******************************************************************************
class MTScenePianoRollRain2DLive : public MTScenePianoRollRainLive
{
public:
	
	//コンストラクタ／デストラクタ
	MTScenePianoRollRain2DLive(void);
	virtual ~MTScenePianoRollRain2DLive(void);
	
	//名称取得
	NSString* GetName();
	
	//生成
	virtual int Create(
			NSView* pView,
			OGLDevice* pOGLDevice,
			SMSeqData* pSeqData
		);
	
	//視点取得
	virtual void GetDefaultViewParam(MTViewParamMap* pParamMap);
	
};


