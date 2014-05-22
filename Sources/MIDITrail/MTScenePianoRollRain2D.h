//******************************************************************************
//
// MIDITrail / MTScenePianoRollRain2D
//
// ピアノロールレイン2Dシーン描画クラス
//
// Copyright (C) 2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#include "MTScenePianoRollRain.h"


//******************************************************************************
// ピアノロールレイン2Dシーン描画クラス
//******************************************************************************
class MTScenePianoRollRain2D : public MTScenePianoRollRain
{
public:

	//コンストラクタ／デストラクタ
	MTScenePianoRollRain2D(void);
	virtual ~MTScenePianoRollRain2D(void);

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

