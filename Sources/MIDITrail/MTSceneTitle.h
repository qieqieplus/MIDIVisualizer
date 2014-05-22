//******************************************************************************
//
// MIDITrail / MTSceneTitle
//
// タイトルシーン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "MTScene.h"
#import "MTLogo.h"
#import "SMIDILib.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//カメラZ座標
#define MTSCENETITLE_CAMERA_POSZ  (-80.0f)

//カメラZ座標変化量
#define MTSCENETITLE_CAMERA_POSZ_DELTA  (0.05f)

//******************************************************************************
// タイトルシーン描画クラス
//******************************************************************************
class MTSceneTitle : public MTScene
{
public:
	
	//コンストラクタ／デストラクタl
	MTSceneTitle(void);
	virtual ~MTSceneTitle(void);
	
	//名称取得
	NSString* GetName();
	
	//生成
	int Create(
			NSView* pView,
			OGLDevice* pOGLDevice,
			SMSeqData* pSeqData
		);
	
	//変換
	int Transform(OGLDevice* pOGLDevice);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//破棄
	void Release();
	
private:
	
	//カメラ位置Z
	float m_CamPosZ;
	
	//カメラ
	OGLCamera m_Camera;
	
	//ライト
	OGLDirLight m_DirLight;
	
	//ロゴ描画オブジェクト
	MTLogo m_Logo;

};


