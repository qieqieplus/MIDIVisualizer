//******************************************************************************
//
// MIDITrail / MTScenePianoRoll2D
//
// ピアノロール2Dシーン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "MTScenePianoRoll3D.h"


//******************************************************************************
// ピアノロール2Dシーン描画クラス
//******************************************************************************
class MTScenePianoRoll2D : public MTScenePianoRoll3D
{
public:
	
	//コンストラクタ／デストラクタ
	MTScenePianoRoll2D(void);
	virtual ~MTScenePianoRoll2D(void);
	
	//名称取得
	NSString* GetName();
	
	//生成
	virtual int Create(
			NSView* pView,
			OGLDevice* pOGLDevice,
			SMSeqData* pSeqData
		);
	
};


