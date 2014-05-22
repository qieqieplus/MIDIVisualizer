//******************************************************************************
//
// MIDITrail / MTScenePianoRoll3DLiveLive
//
// ライブモニタ用ピアノロール3Dシーン描画クラス
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
#import "MTScenePianoRoll3DLive.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTScenePianoRoll3DLive::MTScenePianoRoll3DLive()
{
	m_IsEnableLight = true;
	m_IsMouseCamMode = false;
	m_IsAutoRollMode = false;
	m_IsSkipping = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTScenePianoRoll3DLive::~MTScenePianoRoll3DLive()
{
	Release();
}

//******************************************************************************
// 名称取得
//******************************************************************************
NSString* MTScenePianoRoll3DLive::GetName()
{
	return @"PianoRoll3DLive";
}

//******************************************************************************
// シーン生成
//******************************************************************************
int MTScenePianoRoll3DLive::Create(
		NSView* pView,
		OGLDevice* pOGLDevice,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	
	//ライブモニタのため pSeqData には NULL が指定される
	
	Release();
	
	if (pOGLDevice == NULL) {
		result =  YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//設定ファイル読み込み
	result = _LoadConf();
	if (result != 0) goto EXIT;
	
	//ノートデザインオブジェクト初期化
	result = m_NoteDesign.Initialize(GetName(), pSeqData);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// カメラ
	//----------------------------------
	//カメラ初期化
	result = m_FirstPersonCam.Initialize(pView, GetName(), pSeqData);
	if (result != 0) goto EXIT;
	
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
	m_DirLight.SetDirection(OGLVECTOR3(1.0f, -1.0f, LH2RH(2.0f)));
	
	//ライトのデバイス登録
	result = m_DirLight.SetDevice(pOGLDevice, m_IsEnableLight);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// 描画オブジェクト
	//----------------------------------
	//ピッチベンド情報初期化
	result = m_NotePitchBend.Initialize();
	if (result != 0) goto EXIT;
	
	//ノートボックス生成
	result = m_NoteBoxLive.Create(pOGLDevice, GetName(), &m_NotePitchBend);
	if (result != 0) goto EXIT;
	
	//ノート波紋生成
	result = m_NoteRipple.Create(pOGLDevice, GetName(), pSeqData, &m_NotePitchBend);
	if (result != 0) goto EXIT;
	
	//グリッドボックス生成
	result = m_GridBoxLive.Create(pOGLDevice, GetName());
	if (result != 0) goto EXIT;
	
	//ピクチャボード生成
	result = m_PictBoard.Create(pOGLDevice, GetName(), pSeqData);
	if (result != 0) goto EXIT;
	
	//ダッシュボード生成
	result = m_DashboardLive.Create(pOGLDevice, GetName(), pView);
	if (result != 0) goto EXIT;
	
	//星生成
	result = m_Stars.Create(pOGLDevice, GetName());
	if (result != 0) goto EXIT;
	
	//タイムインジケータ生成
	result = m_TimeIndicator.Create(pOGLDevice, GetName(), pSeqData);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	// レンダリングステート
	//----------------------------------
	//画面描画モード
	glDisable(GL_CULL_FACE);
	
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
int MTScenePianoRoll3DLive::Transform(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	float rollAngle = 0.0f;
	OGLVECTOR3 camVector;
	
	if (pOGLDevice == NULL) {
		result =  YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//カメラ更新
	result = m_FirstPersonCam.Transform(pOGLDevice, m_isActive);
	if (result != 0) goto EXIT;
	
	//カメラ座標取得
	m_FirstPersonCam.GetPosition(&camVector);
	
	//回転角度取得
	rollAngle = m_FirstPersonCam.GetManualRollAngle();
	
	//ノートボックス更新
	result = m_NoteBoxLive.Transform(pOGLDevice, rollAngle);
	if (result != 0) goto EXIT;
	
	//グリッドボックス更新
	result = m_GridBoxLive.Transform(pOGLDevice, rollAngle);
	if (result != 0) goto EXIT;
	
	//ピクチャボード更新
	result = m_PictBoard.Transform(pOGLDevice, camVector, rollAngle);
	if (result != 0) goto EXIT;
	
	//ダッシュボード更新
	result = m_DashboardLive.Transform(pOGLDevice, camVector);
	if (result != 0) goto EXIT;
	
	//星更新
	result = m_Stars.Transform(pOGLDevice, camVector);
	if (result != 0) goto EXIT;
	
	//タイムインジケータ更新
	result = m_TimeIndicator.Transform(pOGLDevice, camVector, rollAngle);
	if (result != 0) goto EXIT;
	
	//ノート波紋更新
	result = m_NoteRipple.Transform(pOGLDevice, camVector, rollAngle);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTScenePianoRoll3DLive::Draw(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	if (pOGLDevice == NULL) {
		result =  YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//更新
	result = Transform(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//グリッドボックス描画
	result = m_GridBoxLive.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ノートボックス描画
	result = m_NoteBoxLive.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ピクチャボード描画
	result = m_PictBoard.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//星描画
	result = m_Stars.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//タイムインジケータ描画
	result = m_TimeIndicator.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ノート波紋描画
	result = m_NoteRipple.Draw(pOGLDevice);
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
void MTScenePianoRoll3DLive::Release()
{
	m_NoteBoxLive.Release();
	m_GridBoxLive.Release();
	m_PictBoard.Release();
	m_DashboardLive.Release();
	m_Stars.Release();
	m_TimeIndicator.Release();
	m_NoteRipple.Release();
}

//******************************************************************************
// ウィンドウクリックイベント受信
//******************************************************************************
int MTScenePianoRoll3DLive::OnWindowClicked(
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
int MTScenePianoRoll3DLive::OnScrollWheel(
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
int MTScenePianoRoll3DLive::OnPlayStart()
{
	int result = 0;
	
	_Reset();
	
	m_PictBoard.OnPlayStart();
	
	m_DashboardLive.SetMonitoringStatus(true);
	result = m_DashboardLive.SetMIDIINDeviceName(GetParam(@"MIDI_IN_DEVICE_NAME"));
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏終了イベント受信
//******************************************************************************
int MTScenePianoRoll3DLive::OnPlayEnd()
{
	int result = 0;
	
	m_NoteBoxLive.AllNoteOff();
	m_PictBoard.OnPlayEnd();
	
	m_DashboardLive.SetMonitoringStatus(false);
	
//EXIT:;
	return result;
}

//******************************************************************************
// シーケンサメッセージ受信
//******************************************************************************
int MTScenePianoRoll3DLive::OnRecvSequencerMsg(
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
		m_NoteBoxLive.SetNoteOff(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo());
		m_NoteRipple.SetNoteOff(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo());
	}
	//ノートON通知
	else if (parser.GetMsg() == SMMsgParser::MsgNoteOn) {
		m_DashboardLive.SetNoteOn();
		m_NoteBoxLive.SetNoteOn(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo(), parser.GetVelocity());
		m_NoteRipple.SetNoteOn(parser.GetPortNo(), parser.GetChNo(), parser.GetNoteNo(), parser.GetVelocity());
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
		m_NoteBoxLive.AllNoteOffOnCh(parser.GetPortNo(), parser.GetChNo());
	}
	
	//EXIT:;
	return result;
}

//******************************************************************************
// 巻き戻し
//******************************************************************************
int MTScenePianoRoll3DLive::Rewind()
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
void MTScenePianoRoll3DLive::_Reset()
{
	m_DashboardLive.Reset();
	m_FirstPersonCam.Reset();
	m_TimeIndicator.Reset();
	m_PictBoard.Reset();
	m_NoteBoxLive.Reset();
	m_NoteRipple.Reset();
	m_NotePitchBend.Reset();
}

//******************************************************************************
// デフォルト視点取得
//******************************************************************************
void MTScenePianoRoll3DLive::GetDefaultViewParam(
		MTViewParamMap* pParamMap
	)
{
	OGLVECTOR3 viewPointVector;
	OGLVECTOR3 e4Vector;
	OGLVECTOR3 moveVctor;
	float phi, theta = 0.0f;
	
	//デフォルトのカメラY座標（高さ）をE4の位置とする
	e4Vector = m_NoteDesign.GetNoteBoxCenterPosX(
					0,		//現在時間
					0,		//ポート番号
					0,		//チャンネル番号
					64		//ノート番号：E4
				);
	
	//世界座標配置移動ベクトル取得
	moveVctor = m_NoteDesign.GetWorldMoveVector();
	
	//視点情報作成
	viewPointVector.x =  e4Vector.x + moveVctor.x;
	viewPointVector.y =  e4Vector.y + moveVctor.y;
	viewPointVector.z =  LH2RH(e4Vector.z + moveVctor.z - 18.0f);
	phi      =  LH2RH(90.0f);	//+Z軸方向
	theta    =  90.0f;	//+Z軸方向
	
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
void MTScenePianoRoll3DLive::GetViewParam(
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
	
	//再生面に対する視点であるためX軸方向は再生位置を考慮する
	viewPointVector.x -= m_TimeIndicator.GetPos();
	
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
void MTScenePianoRoll3DLive::SetViewParam(
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
	
	//再生面に対する視点であるためX軸方向は再生位置を考慮する
	viewPointVector.x += m_TimeIndicator.GetPos();
	
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
void MTScenePianoRoll3DLive::ResetViewpoint()
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
void MTScenePianoRoll3DLive::SetEffect(
		MTScene::EffectType type,
		bool isEnable
	)
{
	switch (type) {
		case EffectPianoKeyboard:
			m_PictBoard.SetEnable(isEnable);
			break;
		case EffectRipple:
			m_NoteRipple.SetEnable(isEnable);
			break;
		case EffectPitchBend:
			m_NotePitchBend.SetEnable(isEnable);
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
int MTScenePianoRoll3DLive::_LoadConf()
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

