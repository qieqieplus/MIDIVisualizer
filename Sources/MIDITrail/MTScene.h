//******************************************************************************
//
// MIDITrail / MTScene
//
// MIDITrail シーン基底クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "SMIDILib.h"
#import <string>


//******************************************************************************
// パラメータ定義
//******************************************************************************
//マウスボタン種別
#define WM_LBUTTONDOWN  (0)
#define WM_RBUTTONDOWN  (1)
#define WM_MBUTTONDOWN  (2)

//******************************************************************************
// MIDITrail シーン基底クラス
//******************************************************************************
class MTScene : public OGLScene
{
public:
	
	enum EffectType {
		EffectPianoKeyboard,
		EffectRipple,
		EffectPitchBend,
		EffectStars,
		EffectCounter,
		EffectFileName
	};
	
	typedef std::map<std::string, float>  MTViewParamMap;
	typedef std::pair<std::string, float> MTViewParamMapPair;
	
public:
	
	//コンストラクタ／デストラクタ
	MTScene(void);
	virtual ~MTScene(void);
	
	//名称取得
	virtual NSString* GetName();
	
	//生成
	virtual int Create(
					NSView* pView,
					OGLDevice* pD3DDevice,
					SMSeqData* pSeqData
				);
	
	//変換
	virtual int Transform(OGLDevice* pD3DDevice);
	
	//描画
	virtual int Draw(OGLDevice* pD3DDevice);
	
	//破棄
	virtual void Release();
	
	//ウィンドウクリックイベント受信
	virtual int OnWindowClicked(
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
	virtual int OnPlayStart();
	
	//演奏終了イベント受信
	virtual int OnPlayEnd();
	
	//シーケンサメッセージ受信
	virtual int OnRecvSequencerMsg(
					unsigned long wParam,
					unsigned long lParam
				);
	
	//巻き戻し
	virtual int Rewind();
	
	//視点取得／登録
	virtual void GetDefaultViewParam(MTViewParamMap* pParamMap);
	virtual void GetViewParam(MTViewParamMap* pParamMap);
	virtual void SetViewParam(MTViewParamMap* pParamMap);
	
	//視点リセット
	virtual void ResetViewpoint();
	
	//表示効果設定
	virtual void SetEffect(EffectType type, bool isEnable);
	
	//アクティブ状態設定
	virtual void SetActiveState(bool isActive);
	
	//演奏速度設定
	virtual void SetPlaySpeedRatio(unsigned long ratio);
	
	//パラメータ登録／取得
	int SetParam(NSString* pKey, NSString* pValue);
	NSString* GetParam(NSString* pKey);
	
protected:
	
	//ウィンドウアクティブ状態
	bool m_isActive;
	
	//シーンパラメータ
	NSMutableDictionary* m_pSceneParamDictionary;
	
};


