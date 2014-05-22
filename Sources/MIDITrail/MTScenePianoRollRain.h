//******************************************************************************
//
// MIDITrail / MTScenePianoRollRain
//
// ピアノロールレインシーン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "MTScene.h"
#import "MTFirstPersonCam.h"
#import "MTStars.h"
#import "MTPianoKeyboardCtrl.h"
#import "MTNoteRain.h"
#import "MTDashboard.h"
#import "MTNotePitchBend.h"
#import "SMIDILib.h"


//******************************************************************************
// ピアノロールレインシーン描画クラス
//******************************************************************************
class MTScenePianoRollRain : public MTScene
{
public:
	
	//コンストラクタ／デストラクタl
	MTScenePianoRollRain(void);
	virtual ~MTScenePianoRollRain(void);
	
	//名称取得
	NSString* GetName();
	
	//生成
	virtual int Create(
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
	
	//ウィンドウクリックイベント受信
	int OnWindowClicked(
			unsigned long button,
			unsigned long wParam,
			unsigned long lParam
		);
	
	//マウスホイールイベント受信
	int OnScrollWheel(
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
	virtual void GetDefaultViewParam(MTViewParamMap* pParamMap);
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
	
	//シングルキーボードフラグ
	bool m_IsSingleKeyboard;
	
private:
	
	//ライト
	OGLDirLight m_DirLight;
	
	//一人称カメラ
	MTFirstPersonCam m_FirstPersonCam;
	
	//描画オブジェクト
	MTStars m_Stars;
	MTPianoKeyboardCtrl m_PianoKeyboardCtrl;
	MTNoteRain m_NoteRain;
	MTNotePitchBend m_NotePitchBend;
	MTDashboard m_Dashboard;
	
	//マウス視線移動モード
	bool m_IsMouseCamMode;
	
	//自動回転モード
	bool m_IsAutoRollMode;
	
	//視点情報
	MTViewParamMap m_ViewParamMap;
	
	//演奏位置
	unsigned long m_CurTickTime;
	
	//スキップ状態
	bool m_IsSkipping;
	
	void _Reset();
	int _LoadConf();
	
};


