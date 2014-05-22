//******************************************************************************
//
// MIDITrail / MTScenePianoRoll3D
//
// ピアノロール3Dシーン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "MTScene.h"
#import "MTFirstPersonCam.h"
#import "MTNoteBox.h"
#import "MTNoteRipple.h"
#import "MTNoteDesign.h"
#import "MTNotePitchBend.h"
#import "MTGridBox.h"
#import "MTPictBoard.h"
#import "MTDashboard.h"
#import "MTStars.h"
#import "MTTimeIndicator.h"
#import "SMIDILib.h"


//******************************************************************************
// ピアノロール3Dシーン描画クラス
//******************************************************************************
class MTScenePianoRoll3D : public MTScene
{
public:
	
	//コンストラクタ／デストラクタl
	MTScenePianoRoll3D();
	~MTScenePianoRoll3D();
	
	//名称取得
	NSString* GetName();
	
	//生成
	virtual int Create(
			NSView* pView,
			OGLDevice* pD3DDevice,
			SMSeqData* pSeqData
		);
	
	//変換
	int Transform(OGLDevice* pOGLDevice);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//破棄
	void Release();
	
	//ウィンドウクリックイベント受信
	int OnWindowClicked(
			unsigned long button,
			unsigned long wParam,
			unsigned long lParam
		);
	
	//マウスホイールイベント受信
	virtual int OnScrollWheel(
			float deltaWheelX,	//ホイール左右傾斜
			float deltaWheelY,	//ホイール回転
			float deltaWheelZ	//？
		);
	
	//演奏開始イベント受信
	int OnPlayStart();
	
	//演奏終了イベント受信
	int OnPlayEnd();
	
	//シーケンサメッセージ受信
	int OnRecvSequencerMsg(
			unsigned long wParam,
			unsigned long lParam
		);
	
	//巻き戻し
	int Rewind();
	
	//視点取得／登録
	void GetDefaultViewParam(MTViewParamMap* pParamMap);
	void GetViewParam(MTViewParamMap* pParamMap);
	void SetViewParam(MTViewParamMap* pParamMap);
	
	//視点リセット
	void ResetViewpoint();
	
	//エフェクト設定
	void SetEffect(MTScene::EffectType type, bool isEnable);
	
	//演奏速度設定
	void SetPlaySpeedRatio(unsigned long ratio);
	
protected:
	
	//ライト有無
	bool m_IsEnableLight;
	
private:
	
	//ライト
	OGLDirLight m_DirLight;
	
	//一人称カメラ
	MTFirstPersonCam m_FirstPersonCam;
	
	//描画オブジェクト
	MTNoteBox m_NoteBox;
	MTNoteRipple m_NoteRipple;
	MTNotePitchBend m_NotePitchBend;
	MTGridBox m_GridBox;
	MTPictBoard m_PictBoard;
	MTDashboard m_Dashboard;
	MTStars m_Stars;
	MTTimeIndicator m_TimeIndicator;
	
	//マウス視線移動モード
	bool m_IsMouseCamMode;
	
	//自動回転モード
	bool m_IsAutoRollMode;
	
	//視点情報
	MTViewParamMap m_ViewParamMap;
	
	//ノートデザインオブジェクト
	MTNoteDesign m_NoteDesign;
	
	//スキップ状態
	bool m_IsSkipping;
	
	void _Reset();
	int _LoadConf();
	
};


