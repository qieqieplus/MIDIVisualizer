//******************************************************************************
//
// MIDITrail / MTScenePianoRoll3DLive
//
// ライブモニタ用ピアノロール3Dシーン描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "MTScene.h"
#import "MTFirstPersonCam.h"
#import "MTNoteBoxLive.h"
#import "MTNoteRipple.h"
#import "MTNoteDesign.h"
#import "MTNotePitchBend.h"
#import "MTGridBoxLive.h"
#import "MTPictBoard.h"
#import "MTDashboardLive.h"
#import "MTStars.h"
#import "MTTimeIndicator.h"
#import "SMIDILib.h"


//******************************************************************************
// ライブモニタ用ピアノロール3Dシーン描画クラス
//******************************************************************************
class MTScenePianoRoll3DLive : public MTScene
{
public:
	
	//コンストラクタ／デストラクタl
	MTScenePianoRoll3DLive();
	~MTScenePianoRoll3DLive();
	
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
	
protected:
	
	//ライト有無
	bool m_IsEnableLight;
	
private:
	
	//ライト
	OGLDirLight m_DirLight;
	
	//一人称カメラ
	MTFirstPersonCam m_FirstPersonCam;
	
	//描画オブジェクト
	MTNoteBoxLive m_NoteBoxLive;
	MTNoteRipple m_NoteRipple;
	MTNotePitchBend m_NotePitchBend;
	MTGridBoxLive m_GridBoxLive;
	MTPictBoard m_PictBoard;
	MTDashboardLive m_DashboardLive;
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


