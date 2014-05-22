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
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MTFirstPersonCam.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTFirstPersonCam::MTFirstPersonCam(void)
{
	m_CamVector = OGLVECTOR3(0.0f, 0.0f, 0.0f);
	m_CamDirPhi = 0.0f;
	m_CamDirTheta = 0.0f;
	m_IsMouseCamMode = false;
	m_IsAutoRollMode = false;
	m_pView = nil;
	
	m_VelocityFB = 15.0f; // m/sec.
	m_VelocityLR = 15.0f; // m/sec.
	m_VelocityUD = 10.0f; // m/sec.
	m_VelocityPT =  6.0f; // degrees/sec.
	m_AcceleRate =  2.0f; // 加速倍率
	m_PrevTime = 0;
	m_DeltaTime = 0;
	
	m_RollAngle = 0.0f;
	m_VelocityAutoRoll = 6.0f;
	m_VelocityManualRoll = 1.0f;
	
	m_PrevTickTime = 0;
	m_CurTickTime = 0;
	m_ProgressDirection = DirX;
	
	m_isActive = true;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTFirstPersonCam::~MTFirstPersonCam(void)
{
	m_DIKeyCtrl.Terminate();
	m_DIMouseCtrl.Terminate();
	_ClipCursor(false);
}

//******************************************************************************
// 初期化処理
//******************************************************************************
int MTFirstPersonCam::Initialize(
		NSView* pView,
		NSString* pSceneName,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	
	m_pView = pView;
	
	//パラメータ設定ファイル読み込み
	result = _LoadConfFile(pSceneName);
	if (result != 0) goto EXIT;
	
	//ノートデザインオブジェクト初期化
	result = m_NoteDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//キーボードデバイス制御初期化
	result = m_DIKeyCtrl.Initialize(pView);
	if (result != 0) goto EXIT;
	
	//マウスデバイス制御初期化
	result = m_DIMouseCtrl.Initialize(pView);
	if (result != 0) goto EXIT;
	
	//デバイスアクセス権取得
	m_DIKeyCtrl.Acquire();
	m_DIMouseCtrl.Acquire();
	
	//カメラ初期化
	result = m_Camera.Initialize();
	if (result != 0) goto EXIT;
	
	//基本パラメータ設定
	m_Camera.SetBaseParam(
			45.0f,		//画角
			1.0f,		//Nearプレーン：0だとZ軸順制御がおかしくなる
			1000.0f		//Farプレーン
		);
	
	//カメラ位置設定
	m_Camera.SetPosition(
			OGLVECTOR3(0.0f, 0.0f, LH2RH(0.0f)),	//カメラ位置
			OGLVECTOR3(0.0f, 0.0f, LH2RH(1.0f)),	//注目点
			OGLVECTOR3(0.0f, 1.0f, LH2RH(0.0f))		//カメラ上方向
		);
	
	//Mach時間初期化
	result = m_MachTime.Initialize();
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// カメラ位置設定
//******************************************************************************
void MTFirstPersonCam::SetPosition(
		OGLVECTOR3 camVector
	)
{
	m_CamVector = camVector;
}

//******************************************************************************
// カメラ方向設定
//******************************************************************************
void MTFirstPersonCam::SetDirection(
		float phi,
		float theta
	)
{
	m_CamDirPhi = phi;
	m_CamDirTheta = theta;
}
//******************************************************************************
// カメラ位置取得
//******************************************************************************
void MTFirstPersonCam::GetPosition(
		OGLVECTOR3* pCamVector
	)
{
	*pCamVector = m_CamVector;
}

//******************************************************************************
// カメラ方向取得
//******************************************************************************
void MTFirstPersonCam::GetDirection(
		float* pPhi,
		float* pTheta
	)
{
	*pPhi = m_CamDirPhi;
	*pTheta = m_CamDirTheta;
}

//******************************************************************************
// マウス視線移動モード登録
//******************************************************************************
void MTFirstPersonCam::SetMouseCamMode(
		bool isEnable
	)
{
	m_IsMouseCamMode = isEnable;
	
	if (m_IsMouseCamMode) {
		//マウスカーソルを隠す
		CGDisplayHideCursor(kCGDirectMainDisplay);
		_ClipCursor(true);
	}
	else {
		//マウスカーソルを表示
		CGDisplayShowCursor(TRUE);
		_ClipCursor(false);
	}
}

//******************************************************************************
// 自動回転モード登録
//******************************************************************************
void MTFirstPersonCam::SetAutoRollMode(
		bool isEnable
	)
{
	m_IsAutoRollMode = isEnable;
}

//******************************************************************************
// 自動回転方向切り替え
//******************************************************************************
void MTFirstPersonCam::SwitchAutoRllDirecton()
{
	//回転方向を逆にする
	m_VelocityAutoRoll *= -1.0f;
}

//******************************************************************************
// 変換処理
//******************************************************************************
int MTFirstPersonCam::Transform(
		OGLDevice* pOGLDevice,
		bool isActive
	)
{
	int result = 0;
	int dX, dY, dW = 0;
	
	//TODO: ここじゃないどこかへ移す
	m_DIKeyCtrl.Acquire();
	m_DIMouseCtrl.Acquire();
	
	//アプリケーションのアクティブ状態を設定
	m_DIKeyCtrl.SetActiveState(isActive);
	
	//現在のキーボード状態を取得
	result = m_DIKeyCtrl.GetKeyStatus();
	//if (result != 0) goto EXIT;
	result = 0;
	
	//マウス状態取得
	result = m_DIMouseCtrl.GetMouseStatus();
	//if (result != 0) goto EXIT;
	result = 0;
	
	//マウス／ホイール移動量
	dX = m_DIMouseCtrl.GetDelta(DIMouseCtrl::AxisX);
	dY = m_DIMouseCtrl.GetDelta(DIMouseCtrl::AxisY);
	dW = m_DIMouseCtrl.GetDelta(DIMouseCtrl::AxisWheel);
	
	//マウス視線移動モードOFFなら移動量を無視する
	if (!m_IsMouseCamMode) {
		dX = 0;
		dY = 0;
	}
	
	//CTRL+移動キーで視線方向を変化させる
	if (m_DIKeyCtrl.IsKeyDown(DIK_CONTROL)) {
		if (m_DIKeyCtrl.IsKeyDown(DIK_W) || m_DIKeyCtrl.IsKeyDown(DIK_UP)) {
			dY -= m_VelocityPT;
		}
		if (m_DIKeyCtrl.IsKeyDown(DIK_S) || m_DIKeyCtrl.IsKeyDown(DIK_DOWN)) {
			dY += m_VelocityPT;
		}
		if (m_DIKeyCtrl.IsKeyDown(DIK_A) || m_DIKeyCtrl.IsKeyDown(DIK_LEFT)) {
			dX -= m_VelocityPT;
		}
		if (m_DIKeyCtrl.IsKeyDown(DIK_D) || m_DIKeyCtrl.IsKeyDown(DIK_RIGHT)) {
			dX += m_VelocityPT;
		}
	}
	
	//デルタタイム算出
	_CalcDeltaTime();
	
	//視線方向の更新
	result = _TransformEyeDirection(dX, dY);
	if (result != 0) goto EXIT;
	
	//カメラ位置の更新
	result = _TransformCamPosition();
	if (result != 0) goto EXIT;
	
	//カメラ位置設定
	result = _SetCamPosition();
	if (result != 0) goto EXIT;
	
	//カメラ更新
	result = m_Camera.Transform(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//回転対応
	result = _TransformRolling(dW);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 視線方向更新
//******************************************************************************
int MTFirstPersonCam::_TransformEyeDirection(
		int dX,
		int dY
	)
{
	int result = 0;
	float dt = 0.0f;
	float dPhi = 0.0f;
	float dTheta = 0.0f;
	
	//デルタタイム
	dt = (float)m_DeltaTime / 1000.0f;
	
	//マウス移動量から方位角と天頂角の増加量を算出
	dPhi   = (float)-dX * m_VelocityPT * dt;
	dTheta = (float) dY * m_VelocityPT * dt;
	
	//極端な角度の変化を抑止する
	//  画面描画が引っかかった場合にマウス移動量が蓄積され
	//  突然あらぬ方向を向いてしまうことを避けたい
	if (abs(dPhi) > 45.0f) {
		dPhi = 0.0f;
	}
	if (abs(dTheta) > 45.0f) {
		dTheta = 0.0f;
	}
	
	//マウス移動量を方位角と天頂角に反映する
	m_CamDirPhi += LH2RH(dPhi);
	m_CamDirTheta += dTheta;
	
	//クリッピング処理
	if (m_CamDirPhi >= 360.0f) {
		m_CamDirPhi -= 360.0f;
	}
	else if (m_CamDirPhi <= -360.0f) {
		m_CamDirPhi += 360.0f;
	}
	if (m_CamDirTheta <= 1.0f) {
		m_CamDirTheta = 1.0f;
	}
	else if (m_CamDirTheta >= 179.0f) {
		m_CamDirTheta = 179.0f;
	}
	//↑天頂角が0度または180度になると描画がおかしくなる・・・
	
//EXIT:;
	return result;
}

//******************************************************************************
// カメラ位置更新
//******************************************************************************
int MTFirstPersonCam::_TransformCamPosition()
{
	int result = 0;
	float phi = 0.0f;
	float phiRad = 0.0f;
	float distance = 0.0f;
	float dt = 0.0f;
	float rate = 0.0f;
	float progress = 0.0f;
	OGLVECTOR3 moveVector;
	
	//デルタタイム
	dt = (float)m_DeltaTime / 1000.0f;
	
	//移動方向の方位角
	phi = m_CamDirPhi;
	
	if (m_DIKeyCtrl.IsKeyDown(DIK_COMMAND) || m_DIKeyCtrl.IsKeyDown(DIK_CONTROL)) {
		//コマンドキーまたはCTRLキーが押されている場合はキー入力を無視する
	}
	else {
		//移動速度の加速倍率
		rate = 1.0f;
		//if (m_DIKeyCtrl.IsKeyDown(DIK_LSHIFT) || m_DIKeyCtrl.IsKeyDown(DIK_RSHIFT)) {
		if (m_DIKeyCtrl.IsKeyDown(DIK_SHIFT)) {
			rate = m_AcceleRate;
		}
		
		//前移動
		if (m_DIKeyCtrl.IsKeyDown(DIK_W) || m_DIKeyCtrl.IsKeyDown(DIK_UP)) {
			distance = m_VelocityFB * dt * rate;
			phi += 0.0f;
		}
		//後ろ移動：視線は前を向いたまま
		if (m_DIKeyCtrl.IsKeyDown(DIK_S) || m_DIKeyCtrl.IsKeyDown(DIK_DOWN)) {
			distance = m_VelocityFB * dt * rate;
			phi += 180.0f;
		}
		//左移動：視線は前を向いたまま
		if (m_DIKeyCtrl.IsKeyDown(DIK_A) || m_DIKeyCtrl.IsKeyDown(DIK_LEFT)) {
			distance = m_VelocityLR * dt * rate;
			phi += LH2RH(90.0f);
		}
		//右移動：視線は前を向いたまま
		if (m_DIKeyCtrl.IsKeyDown(DIK_D) || m_DIKeyCtrl.IsKeyDown(DIK_RIGHT)) {
			distance = m_VelocityLR * dt * rate;
			phi += LH2RH(-90.0f);
		}
		//上昇：視線変更なし
		if (m_DIKeyCtrl.IsKeyDown(DIK_Q) || m_DIKeyCtrl.IsKeyDown(DIK_PGUP)) {
			m_CamVector.y += +(m_VelocityUD * dt * rate);
		}
		//下降：視線変更なし
		if (m_DIKeyCtrl.IsKeyDown(DIK_E) ||  m_DIKeyCtrl.IsKeyDown(DIK_PGDN)) {
			m_CamVector.y += -(m_VelocityUD * dt * rate);
		}
		//-X軸方向（曲再生逆方向）に移動：視線変更なし
		if (m_DIKeyCtrl.IsKeyDown(DIK_Z) || m_DIKeyCtrl.IsKeyDown(DIK_COMMA)) {
			m_CamVector.x +=  -(m_VelocityFB * dt * rate);
		}
		//+X軸方向（曲再生方向）に移動：視線変更なし
		if (m_DIKeyCtrl.IsKeyDown(DIK_C) || m_DIKeyCtrl.IsKeyDown(DIK_PERIOD)) {
			m_CamVector.x +=  +(m_VelocityFB * dt * rate);
		}
	}
	
	//クリッピング
	if (phi >= 360.0f) {
		phi -= 360.0f;
	}
	else if (phi <= -360.0f) {
		phi += 360.0f;
	}
	
	//移動ベクトル作成（極座標から直行座標へ変換）
	phiRad = OGLH::ToRadian(phi);
	moveVector.x = distance * cos(phiRad);  // r * sin(90) * cos(phi)
	moveVector.y = 0.0f;                    // r * cos(90)
	moveVector.z = distance * sin(phiRad);  // r * sin(90) * cos(phi)
	
	//カメラ位置を移動
	m_CamVector.x += moveVector.x;
	m_CamVector.y += moveVector.y;
	m_CamVector.z += moveVector.z;
	
	//演奏追跡
	progress = m_NoteDesign.GetPlayPosX(m_CurTickTime) - m_NoteDesign.GetPlayPosX(m_PrevTickTime);
	switch (m_ProgressDirection) {
		case DirX:
			m_CamVector.x += progress;
			break;
		case DirY:
			m_CamVector.y += progress;
			break;
		case DirZ:
			m_CamVector.z += progress;
			break;
	}
	
	//カメラ位置クリッピング
	_ClipCamVector(&m_CamVector);
	
	m_PrevTickTime = m_CurTickTime;
	
//EXIT:;
	return result;
}

//******************************************************************************
// 回転対応
//******************************************************************************
int MTFirstPersonCam::_TransformRolling(
		int dW
	)
{
	int result = 0;
	float dt = 0.0f;
	float domega = 0.0f;
	
	//デルタタイム
	dt = (float)m_DeltaTime / 1000.0f;
	
	//ホイール移動量から角度を算出
	domega = (float)dW * m_VelocityManualRoll * dt;
	
	//極端な角度の変化を抑止する
	//  画面描画が引っかかった場合にマウス移動量が蓄積され
	//  突然あらぬ方向を向いてしまうことを避けたい
	if (abs(domega) > 45.0f) {
		domega = 0.0f;
	}
	
	//自動回転
	if (m_IsAutoRollMode) {
		domega += m_VelocityAutoRoll * dt;
	}
	
	//回転角度更新
	m_RollAngle += domega;
	
	//回転角度のクリップ
	if (m_RollAngle >= 360.0f) {
		m_RollAngle -= 360.0f;
	}
	else if (m_RollAngle <= -360.0f) {
		m_RollAngle += 360.0f;
	}
	
//EXIT:;
	return result;
}

//******************************************************************************
// 手動回転角度取得
//******************************************************************************
float MTFirstPersonCam::GetManualRollAngle()
{
	return m_RollAngle;
}

//******************************************************************************
// 手動回転角度設定
//******************************************************************************
void MTFirstPersonCam::SetManualRollAngle(
		float rollAngle
	)
{
	m_RollAngle = rollAngle;
}

//******************************************************************************
// 自動回転速度取得
//******************************************************************************
float MTFirstPersonCam::GetAutoRollVelocity()
{
	return m_VelocityAutoRoll;
}

//******************************************************************************
// 自動回転速度設定
//******************************************************************************
void MTFirstPersonCam::SetAutoRollVelocity(
		float rollVelocity
	)
{
	m_VelocityAutoRoll = rollVelocity;
}

//******************************************************************************
// カメラ位置設定
//******************************************************************************
int MTFirstPersonCam::_SetCamPosition()
{
	int result = 0;
	float phiRad = 0.0f;
	float thetaRad = 0.0f;
	OGLVECTOR3 lookVector;
	OGLVECTOR3 camLookAtVector;
	OGLVECTOR3 camUpVector;
	
	//視線ベクトル（極座標から直交座標へ変換）
	phiRad    = OGLH::ToRadian(m_CamDirPhi);
	thetaRad  = OGLH::ToRadian(m_CamDirTheta);
	lookVector.x = 10.0f * sin(thetaRad) * cos(phiRad);
	lookVector.y = 10.0f * cos(thetaRad);
	lookVector.z = 10.0f * sin(thetaRad) * sin(phiRad);
	
	//カメラ位置に視線ベクトルを足して注目点を算出
	camLookAtVector = m_CamVector;
	camLookAtVector.x += lookVector.x;
	camLookAtVector.y += lookVector.y;
	camLookAtVector.z += lookVector.z;
	
	//カメラ上方向
	camUpVector = OGLVECTOR3(0.0f, 1.0f, LH2RH(0.0f));
	
	//カメラ位置登録
	m_Camera.SetPosition(
			m_CamVector,		//カメラ位置
			camLookAtVector, 	//注目点
			camUpVector			//カメラ上方向
		);

	return result;
}

//******************************************************************************
// カーソル移動範囲制限
//******************************************************************************
int MTFirstPersonCam::_ClipCursor(
		bool isClip
	)
{
	int result = 0;
	
	if (isClip) {
		//マウスとマウスカーソルの連動を停止（カーソルを固定する）
		CGAssociateMouseAndMouseCursorPosition(FALSE);
	}
	else {
		//マウスとマウスカーソルの連携を開始（カーソルを解放する）
		CGAssociateMouseAndMouseCursorPosition(TRUE);
	}
	
	return result;
}

//******************************************************************************
// デルタタイム取得
//******************************************************************************
void MTFirstPersonCam::_CalcDeltaTime()
{
	uint64_t curTime = 0;
	
	curTime = m_MachTime.GetCurTimeInMsec();
	
	if (m_PrevTime == 0) {
		//初回測定時は変化なしとする
		m_DeltaTime = 0;
	}
	else {
		//デルタタイム
		m_DeltaTime = curTime - m_PrevTime;
	}
	
	m_PrevTime = curTime;
	
	return;
}

//******************************************************************************
// チックタイム設定
//******************************************************************************
void MTFirstPersonCam::SetCurTickTime(
		unsigned long curTickTime
	)
{
	m_CurTickTime = curTickTime;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTFirstPersonCam::Reset()
{
	m_PrevTime = 0;
	m_DeltaTime = 0;
	m_PrevTickTime = 0;
	m_CurTickTime = 0;
}

//******************************************************************************
// 設定ファイル読み込み
//******************************************************************************
int MTFirstPersonCam::_LoadConfFile(
		NSString* pSceneName
	)
{
	int result = 0;
	MTConfFile confFile;
	
	result = confFile.Initialize(pSceneName);
	if (result != 0) goto EXIT;
	
	//カメラ移動速度情報取得
	result = confFile.SetCurSection(@"FirstPersonCam");
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"VelocityFB", &m_VelocityFB, 15.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"VelocityLR", &m_VelocityLR, 15.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"VelocityUD", &m_VelocityUD, 10.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"VelocityPT", &m_VelocityPT, 6.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"AcceleRate", &m_AcceleRate, 2.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"VelocityAutoRoll", &m_VelocityAutoRoll, 6.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"VelocityManualRoll", &m_VelocityManualRoll, 1.0f);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// カメラ位置クリッピング
//******************************************************************************
void MTFirstPersonCam::_ClipCamVector(
		OGLVECTOR3* pVector
	)
{
	if (pVector->x < -(MTFIRSTPERSONCAM_CAMVECTOR_LIMIT)) {
		pVector->x = -(MTFIRSTPERSONCAM_CAMVECTOR_LIMIT);
	}
	if (pVector->x > MTFIRSTPERSONCAM_CAMVECTOR_LIMIT) {
		pVector->x = MTFIRSTPERSONCAM_CAMVECTOR_LIMIT;
	}
	if (pVector->y < -(MTFIRSTPERSONCAM_CAMVECTOR_LIMIT)) {
		pVector->y = -(MTFIRSTPERSONCAM_CAMVECTOR_LIMIT);
	}
	if (pVector->y > MTFIRSTPERSONCAM_CAMVECTOR_LIMIT) {
		pVector->y = MTFIRSTPERSONCAM_CAMVECTOR_LIMIT;
	}
	if (pVector->z < -(MTFIRSTPERSONCAM_CAMVECTOR_LIMIT)) {
		pVector->z = -(MTFIRSTPERSONCAM_CAMVECTOR_LIMIT);
	}
	if (pVector->z > MTFIRSTPERSONCAM_CAMVECTOR_LIMIT) {
		pVector->z = MTFIRSTPERSONCAM_CAMVECTOR_LIMIT;
	}
}

//******************************************************************************
// 進行方向設定
//******************************************************************************
void MTFirstPersonCam::SetProgressDirection(
		MTProgressDirection dir
	)
{
	m_ProgressDirection = dir;
}

//******************************************************************************
//マウスホイールイベント受信
//******************************************************************************
void MTFirstPersonCam::OnScrollWheel(
		float deltaWheelX,
		float deltaWheelY,
		float deltaWheelZ
	)
{
	m_DIMouseCtrl.OnScrollWheel(deltaWheelX, deltaWheelY, deltaWheelZ);
}


