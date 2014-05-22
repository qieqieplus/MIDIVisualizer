//******************************************************************************
//
// MIDITrail / MTScenePianoRoll2DLive
//
// ライブモニタ用ピアノロール2Dシーン描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTScenePianoRoll3DLive.h"


//******************************************************************************
// ピアノロール2Dシーン描画クラス
//******************************************************************************
class MTScenePianoRoll2DLive : public MTScenePianoRoll3DLive
{
public:
	
	//コンストラクタ／デストラクタ
	MTScenePianoRoll2DLive(void);
	virtual ~MTScenePianoRoll2DLive(void);
	
	//名称取得
	NSString* GetName();
	
	//生成
	virtual int Create(
				NSView* pView,
				OGLDevice* pOGLDevice,
				SMSeqData* pSeqData
			);
	
};


