//******************************************************************************
//
// MIDITrail / MTFirstPersonCam
//
// 一人称カメラクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// FPSゲームライクな視点移動を実現する。
// 本クラス内でキーボード／マウスの状態を取得する。

#import "OGLUtil.h"
#import "DIKeyCtrl.h"
#import "DIMouseCtrl.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"
#import "MTMachTime.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//カメラ位置最大範囲
#define MTFIRSTPERSONCAM_CAMVECTOR_LIMIT  (1000000.0f)

//******************************************************************************
// 一人称カメラクラス
//******************************************************************************
class MTFirstPersonCam
{
public:
	
	enum MTProgressDirection {
		DirX,
		DirY,
		DirZ
	};
	
public:
	
	//コンストラクタ／デストラクタ
	MTFirstPersonCam(void);
	virtual ~MTFirstPersonCam(void);
	
	//クリア
	int Clear();
	
	//初期化
	int Initialize(NSView* pView, NSString* pSceneName, SMSeqData* pSeqData);
	
	//カメラ位置設定
	void SetPosition(
			OGLVECTOR3 camVector
		);
	
	//カメラ方向設定
	//  方位角：XZ平面上のX軸との角度 +X軸方向=0度 +Z軸方向=90度
	//  天頂角：Y軸との角度           +Y軸方向=0度 XZ平面上=90度
	void SetDirection(
			float phi,		//方位角
			float theta		//天頂角
		);
	
	//カメラ位置取得
	void GetPosition(OGLVECTOR3* pCamVector);
	
	//カメラ方向取得
	void GetDirection(
			float* pPhi,
			float* pTheta
		);
	
	//マウス視線移動モード登録
	void SetMouseCamMode(bool isEnable);
	
	//自動回転モード登録
	void SetAutoRollMode(bool isEnable);
	void SwitchAutoRllDirecton();
	
	//更新
	int Transform(OGLDevice* pOGLDevice, bool isActive);
	
	//演奏チックタイム登録
	void SetCurTickTime(unsigned long curTickTime);
	
	//リセット
	void Reset();
	
	//回転角度取得
	float GetManualRollAngle();
	float GetAutoRollVelocity();
	
	//回転角度設定
	void SetManualRollAngle(float rollAngle);
	void SetAutoRollVelocity(float rollVelocity);
	
	//進行方向設定
	void SetProgressDirection(MTProgressDirection dir);
	
	//マウスホイールイベント受信
	void OnScrollWheel(
			float deltaWheelX,	//ホイール左右傾斜
			float deltaWheelY,	//ホイール回転
			float deltaWheelZ	//？
		);
	
private:
	
	OGLCamera m_Camera;
	OGLVECTOR3 m_CamVector;
	float m_CamDirPhi;
	float m_CamDirTheta;
	MTProgressDirection m_ProgressDirection;
	
	DIKeyCtrl m_DIKeyCtrl;
	DIMouseCtrl m_DIMouseCtrl;
	bool m_IsMouseCamMode;
	bool m_IsAutoRollMode;
	NSView* m_pView;
	MTNoteDesign m_NoteDesign;
	
	//移動速度
	float m_VelocityFB;		//前後移動量 m/sec.
	float m_VelocityLR;		//左右移動量 m/sec.
	float m_VelocityUD;		//上下移動量 m/sec.
	float m_VelocityPT;		//視線移動量 degrees/sec.
	float m_AcceleRate;		//加速倍率
	
	//回転制御系
	float m_RollAngle;
	float m_VelocityAutoRoll;
	float m_VelocityManualRoll;
	
	uint64_t m_PrevTime;
	uint64_t m_DeltaTime;
	
	unsigned long m_PrevTickTime;
	unsigned long m_CurTickTime;
	
	MTMachTime m_MachTime;
	bool m_isActive;
	
	int _TransformEyeDirection(int dX, int dY);
	int _TransformCamPosition();
	int _TransformRolling(int dW);
	int _SetCamPosition();
	int _ClipCursor(bool isClip);
	void _CalcDeltaTime();
	int _LoadConfFile(NSString* pSceneName);
	void _ClipCamVector(OGLVECTOR3* pVector);
	
};


