//******************************************************************************
//
// MIDITrail / MTScenePianoRollRainLive
//
// ライブモニタ用ピアノロールレインシーン描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "OGLColorUtil.h"
#import "MTConfFile.h"
#import "MTScenePianoRollRainLive.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTScenePianoRollRainLive::MTScenePianoRollRainLive(void)
{
	m_IsEnableLight = true;
	m_IsSingleKeyboard = false;
	m_IsMouseCamMode = false;
	m_IsAutoRollMode = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTScenePianoRollRainLive::~MTScenePianoRollRainLive(void)
{
	Release();
}

//******************************************************************************
// 名称取得
//******************************************************************************
NSString* MTScenePianoRollRainLive::GetName()
{
	return @"PianoRollRainLive";
}

//******************************************************************************
// シーン生成
//******************************************************************************
int MTScenePianoRollRainLive::Create(
		NSView* pView,
		OGLDevice* pOGLDevice,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	
	Release();
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//設定ファイル読み込み
	result = _LoadConf();
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// カメラ
	//----------------------------------
	//カメラ初期化
	result = m_FirstPersonCam.Initialize(pView, GetName(), pSeqData);
	if (result != 0) goto EXIT;
	
	//進行方向
	m_FirstPersonCam.SetProgressDirection(MTFirstPersonCam::DirY);
	
	//デフォルト視点を取得
	GetDefaultViewParam(&m_ViewParamMap);
	
	//視点を設定
	SetViewParam(&m_ViewParamMap);
	
	//----------------------------------
	// ライト
	//----------------------------------
	//ライト初期化
	result = m_DirLight.Initialize();
	if (result != 0) goto EXIT;
	
	//ライト方向
	//  原点を光源としてその方向をベクトルで表現する
	//m_DirLight.SetDirection(D3DXVECTOR3(1.0f, -1.0f, LH2RH(2.0f)));
	m_DirLight.SetDirection(OGLVECTOR3(1.0f, -2.0f, LH2RH(0.5f)));
	
	//ライトのデバイス登録
	result = m_DirLight.SetDevice(pOGLDevice, m_IsEnableLight);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// 描画オブジェクト
	//----------------------------------
	//ピッチベンド情報初期化
	result = m_NotePitchBend.Initialize();
	if (result != 0) goto EXIT;
	
	//シングルキーボードはピッチベンド無効
	if (m_IsSingleKeyboard) {
		m_NotePitchBend.SetEnable(false);
	}
	else {
		m_NotePitchBend.SetEnable(true);
	}
	
	//ピアノキーボード制御
	result = m_PianoKeyboardCtrlLive.Create(pOGLDevice, GetName(), &m_NotePitchBend, m_IsSingleKeyboard);
	if (result != 0) goto EXIT;
	
	//ノートレイン
	result = m_NoteRainLive.Create(pOGLDevice, GetName(), &m_NotePitchBend);
	if (result != 0) goto EXIT;
	
	//ダッシュボード生成
	result = m_DashboardLive.Create(pOGLDevice, GetName(), pView);
	if (result != 0) goto EXIT;
	
	//星生成
	result = m_Stars.Create(pOGLDevice, GetName());
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// レンダリングステート
	//----------------------------------
	//画面描画モード
	//裏を向くポリゴンは描画しない（カリング）することにより負荷を下げる
	//  OpenGLとDirectXはポリンゴンの表／裏の方向が逆である
	//  DirectX向けに記載したコードを実行する場合はカリング対象を入れ替える
	glEnable(GL_CULL_FACE);
	if (LH2RH(1) == 1) {
		//OpenGL（右手系）向けコードでのカリング（裏面）
		glCullFace(GL_BACK);
	}
	else {
		//DirectX（左手系）向けコードでのカリング（裏面）
		glCullFace(GL_FRONT);
	}
	
	//Z深度比較：ON
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);  //判定方式をDirectXと同一にする
	
	//ディザリング:ON 高品質描画
	glEnable(GL_DITHER);
	
	//マルチサンプリングアンチエイリアス：有効
	//TODO: 設定必要？
	
	//レンダリングステート設定：通常のアルファ合成
	glDisable(GL_ALPHA_TEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	//シェーディングモデル
	glShadeModel(GL_SMOOTH);  // or GL_FLAT
	
EXIT:;
	return result;
}

//******************************************************************************
// 変換処理
//******************************************************************************
int MTScenePianoRollRainLive::Transform(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	float rollAngle = 0.0f;
	OGLVECTOR3 camVector;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//カメラ更新
	result = m_FirstPersonCam.Transform(pOGLDevice, m_isActive);
	if (result != 0) goto EXIT;
	
	//カメラ座標取得
	 m_FirstPersonCam.GetPosition(&camVector);
	
	//回転角度取得
	rollAngle = m_FirstPersonCam.GetManualRollAngle();
	
	//ピアノキーボード更新
	result = m_PianoKeyboardCtrlLive.Transform(pOGLDevice, rollAngle);
	if (result != 0) goto EXIT;
	
	//ノートレイン更新
	result = m_NoteRainLive.Transform(pOGLDevice, rollAngle);
	if (result != 0) goto EXIT;
	
	//ダッシュボード更新
	result = m_DashboardLive.Transform(pOGLDevice, camVector);
	if (result != 0) goto EXIT;
	
	//星更新
	result = m_Stars.Transform(pOGLDevice, camVector);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTScenePianoRollRainLive::Draw(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//更新
	result = Transform(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ピアノキーボード描画
	result = m_PianoKeyboardCtrlLive.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ノートレイン更新
	result = m_NoteRainLive.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//星描画
	result = m_Stars.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ダッシュボード描画：正射影のため一番最後に描画する
	result = m_DashboardLive.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 破棄
//******************************************************************************
void MTScenePianoRollRainLive::Release()
{
	m_PianoKeyboardCtrlLive.Release();
	m_NoteRainLive.Release();
	m_DashboardLive.Release();
	m_Stars.Release();
}

//******************************************************************************
// ウィンドウクリックイベント受信
//******************************************************************************
int MTScenePianoRollRainLive::OnWindowClicked(
		unsigned long button,
		unsigned long wParam,
		unsigned long lParam
	)
{
	int result = 0;
	
	//左ボタン
	if (button == WM_LBUTTONDOWN) {
		//視線方向制御 ON/OFF
		m_IsMouseCamMode = m_IsMouseCamMode ? false : true;
		m_FirstPersonCam.SetMouseCamMode(m_IsMouseCamMode);
	}
	//右ボタン
	else if (button == WM_RBUTTONDOWN) {
		//何もしない
	}
	//中ボタン
	else if (button == WM_MBUTTONDOWN) {
		//自動回転モード ON/OFF
		m_IsAutoRollMode = m_IsAutoRollMode ? false : true;
		m_FirstPersonCam.SetAutoRollMode(m_IsAutoRollMode);
		if (m_IsAutoRollMode) {
			m_FirstPersonCam.SwitchAutoRllDirecton();
		}
	}
	
	return result;
}

//******************************************************************************
//マウスホイールイベント受信
//******************************************************************************
int MTScenePianoRollRainLive::OnScrollWheel(
		float deltaWheelX,
		float deltaWheelY,
		float deltaWheelZ
	)
{
	m_FirstPersonCam.OnScrollWheel(deltaWheelX, deltaWheelY, deltaWheelZ);
	return 0;
}

//******************************************************************************
// 演奏開始イベント受信
//******************************************************************************
int MTScenePianoRollRainLive::OnPlayStart()
{
	int result = 0;
	
	_Reset();
	
	m_DashboardLive.SetMonitoringStatus(true);
	result = m_DashboardLive.SetMIDIINDeviceName(this->GetParam(@"MIDI_IN_DEVICE_NAME"));
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏終了イベント受信
//******************************************************************************
int MTScenePianoRollRainLive::OnPlayEnd()
{
	int result = 0;
	
	m_NoteRainLive.AllNoteOff();
	m_PianoKeyboardCtrlLive.AllNoteOff();
	
	m_DashboardLive.SetMonitoringStatus(false);
	
//EXIT:;
	return result;
}

//******************************************************************************
// シーケンサメッセージ受信
//******************************************************************************
int MTScenePianoRollRainLive::OnRecvSequencerMsg(
		unsigned long wParam,
		unsigned long lParam
	)
{
	int result = 0;
	SMMsgParser parser;
	
	parser.Parse(wParam, lParam);
	
	//演奏状態通知
	if (parser.GetMsg() == SMMsgParser::MsgPlayStatus) {
		if (parser.GetPlayStatus() == SMMsgParser::StatusStop) {
			//停止（終了）
		}
		else if (parser.GetPlayStatus() == SMMsgParser::StatusPlay) {
			//演奏
		}
		else if (parser.GetPlayStatus() == SMMsgParser::StatusPause) {
			//一時停止
		}
	}
	//ノートOFF通知
	else if (parser.GetMsg() == SMMsgParser::MsgNoteOff) {
		m_NoteRainLive.SetNoteOff(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo());
		m_PianoKeyboardCtrlLive.SetNoteOff(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo());
	}
	//ノートON通知
	else if (parser.GetMsg() == SMMsgParser::MsgNoteOn) {
		m_DashboardLive.SetNoteOn();
		m_NoteRainLive.SetNoteOn(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo(), parser.GetVelocity());
		m_PianoKeyboardCtrlLive.SetNoteOn(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo(), parser.GetVelocity());
	}
	//ピッチベンド通知
	else if (parser.GetMsg() == SMMsgParser::MsgPitchBend) {
		m_NotePitchBend.SetPitchBend(
							parser.GetPortNo(),
							parser.GetChNo(),
							parser.GetPitchBendValue(),
							parser.GetPitchBendSensitivity()
						);
	}
	//オールノートOFF通知
	else if (parser.GetMsg() == SMMsgParser::MsgAllNoteOff) {
		m_NoteRainLive.AllNoteOffOnCh(parser.GetPortNo(), parser.GetChNo());
		m_PianoKeyboardCtrlLive.AllNoteOffOnCh(parser.GetPortNo(), parser.GetChNo());
	}
	
//EXIT:;
	return result;
}

//******************************************************************************
// 巻き戻し
//******************************************************************************
int MTScenePianoRollRainLive::Rewind()
{
	int result = 0;
	
	_Reset();
	
	//視点を設定
	SetViewParam(&m_ViewParamMap);
	
	return result;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTScenePianoRollRainLive::_Reset()
{
	m_DashboardLive.Reset();
	m_FirstPersonCam.Reset();
	m_PianoKeyboardCtrlLive.Reset();
	m_NoteRainLive.Reset();
	m_NotePitchBend.Reset();
}

//******************************************************************************
// デフォルト視点取得
//******************************************************************************
void MTScenePianoRollRainLive::GetDefaultViewParam(
		MTViewParamMap* pParamMap
	)
{
	OGLVECTOR3 viewPointVector;
	float phi, theta = 0.0f;
	
	//視点情報作成
	viewPointVector.x = 0.0f;
	viewPointVector.y = 0.0f;
	viewPointVector.z = LH2RH(-(1.5f * 16.0f / 2.0f) - 10.0f);
	phi   = LH2RH(90.0f);	//+Z軸方向
	theta = 90.0f;	//+Z軸方向
	
	pParamMap->clear();
	pParamMap->insert(MTViewParamMapPair("X", viewPointVector.x));
	pParamMap->insert(MTViewParamMapPair("Y", viewPointVector.y));
	pParamMap->insert(MTViewParamMapPair("Z", viewPointVector.z));
	pParamMap->insert(MTViewParamMapPair("Phi", phi));
	pParamMap->insert(MTViewParamMapPair("Theta", theta));
	pParamMap->insert(MTViewParamMapPair("ManualRollAngle", 0.0f));
	pParamMap->insert(MTViewParamMapPair("AutoRollVelocity", 0.0f));
	
	return;
}

//******************************************************************************
// 視点取得
//******************************************************************************
void MTScenePianoRollRainLive::GetViewParam(
		MTViewParamMap* pParamMap
	)
{
	OGLVECTOR3 viewPointVector;
	float phi, theta = 0.0f;
	float manualRollAngle = 0.0f;
	float autoRollVelocity = 0.0f;
	
	//カメラの位置と方向を取得
	m_FirstPersonCam.GetPosition(&viewPointVector);
	m_FirstPersonCam.GetDirection(&phi, &theta);
	
	//ノートを移動せずにカメラとキーボードを移動させる場合
	//再生面に対する視点であるためY軸方向は再生位置を考慮する
	//viewPointVector.y -= m_NoteRain.GetPos();
	
	//回転角度を取得
	manualRollAngle = m_FirstPersonCam.GetManualRollAngle();
	if (m_IsAutoRollMode) {
		autoRollVelocity = m_FirstPersonCam.GetAutoRollVelocity();
	}
	
	pParamMap->clear();
	pParamMap->insert(MTViewParamMapPair("X", viewPointVector.x));
	pParamMap->insert(MTViewParamMapPair("Y", viewPointVector.y));
	pParamMap->insert(MTViewParamMapPair("Z", viewPointVector.z));
	pParamMap->insert(MTViewParamMapPair("Phi", phi));
	pParamMap->insert(MTViewParamMapPair("Theta", theta));
	pParamMap->insert(MTViewParamMapPair("ManualRollAngle", manualRollAngle));
	pParamMap->insert(MTViewParamMapPair("AutoRollVelocity", autoRollVelocity));
	
	return;
}

//******************************************************************************
// 視点登録
//******************************************************************************
void MTScenePianoRollRainLive::SetViewParam(
		MTViewParamMap* pParamMap
	)
{
	OGLVECTOR3 viewPointVector = OGLVECTOR3(0.0f, 0.0f, 0.0f);
	float phi, theta = 0.0f;
	float manualRollAngle = 0.0f;
	float autoRollVelocity = 0.0f;
	MTViewParamMap::iterator itr;
	
	itr = pParamMap->find("X");
	if (itr != pParamMap->end()) {
		viewPointVector.x = itr->second;
	}
	itr = pParamMap->find("Y");
	if (itr != pParamMap->end()) {
		viewPointVector.y = itr->second;
	}
	itr = pParamMap->find("Z");
	if (itr != pParamMap->end()) {
		viewPointVector.z = itr->second;
	}
	itr = pParamMap->find("Phi");
	if (itr != pParamMap->end()) {
		phi = itr->second;
	}
	itr = pParamMap->find("Theta");
	if (itr != pParamMap->end()) {
		theta = itr->second;
	}
	itr = pParamMap->find("ManualRollAngle");
	if (itr != pParamMap->end()) {
		manualRollAngle = itr->second;
	}
	itr = pParamMap->find("AutoRollVelocity");
	if (itr != pParamMap->end()) {
		autoRollVelocity = itr->second;
	}
	
	//ノートを移動せずにカメラとキーボードを移動させる場合
	//再生面に対する視点であるためY軸方向は再生位置を考慮する
	//viewPointVector.y += m_NoteRain.GetPos();
	
	//カメラの位置と方向を設定
	m_FirstPersonCam.SetPosition(viewPointVector);
	m_FirstPersonCam.SetDirection(phi, theta);
	
	//手動回転角度を設定
	m_FirstPersonCam.SetManualRollAngle(manualRollAngle);
	
	//自動回転速度を設定
	m_IsAutoRollMode = false;
	if (autoRollVelocity != 0.0f) {
		m_IsAutoRollMode = true;
		m_FirstPersonCam.SetAutoRollVelocity(autoRollVelocity);
	}
	m_FirstPersonCam.SetAutoRollMode(m_IsAutoRollMode);
	
	//パラメータの保存
	if (pParamMap != (&m_ViewParamMap)) {
		m_ViewParamMap.clear();
		for (itr = pParamMap->begin(); itr != pParamMap->end(); itr++) {
			m_ViewParamMap.insert(MTViewParamMapPair(itr->first, itr->second));
		}
	}
	
	return;
}

//******************************************************************************
// 視点リセット
//******************************************************************************
void MTScenePianoRollRainLive::ResetViewpoint()
{
	MTViewParamMap paramMap;
	
	//デフォルト視点を取得
	GetDefaultViewParam(&paramMap);
	
	//視点登録
	SetViewParam(&paramMap);
}

//******************************************************************************
// 表示効果設定
//******************************************************************************
void MTScenePianoRollRainLive::SetEffect(
		MTScene::EffectType type,
		bool isEnable
	)
{
	switch (type) {
		case EffectPianoKeyboard:
			m_PianoKeyboardCtrlLive.SetEnable(isEnable);
			break;
		case EffectRipple:
			break;
		case EffectPitchBend:
			if (!m_IsSingleKeyboard) {
				m_NotePitchBend.SetEnable(isEnable);
			}
			break;
		case EffectStars:
			m_Stars.SetEnable(isEnable);
			break;
		case EffectCounter:
			m_DashboardLive.SetEnable(isEnable);
			break;
		default:
			break;
	}
	
	return;
}

//******************************************************************************
// 設定ファイル読み込み
//******************************************************************************
int MTScenePianoRollRainLive::_LoadConf()
{
	int result = 0;
	NSString* pHexColor = nil;
	MTConfFile confFile;
	
	result = confFile.Initialize(GetName());
	if (result != 0) goto EXIT;
	
	result = confFile.SetCurSection(@"Color");
	if (result != 0) goto EXIT;
	
	result = confFile.GetStr(@"BackGroundRGBA", &pHexColor, @"000000FF");
	if (result != 0) goto EXIT;
	
	SetBGColor(OGLColorUtil::MakeColorFromHexRGBA(pHexColor));
	
EXIT:;
	return result;
}

