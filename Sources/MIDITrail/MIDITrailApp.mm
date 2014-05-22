//******************************************************************************
//
// MIDITrail / MIDITrailApp
//
// MIDITrail アプリケーションクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MIDITrailApp.h"
#import "MTSceneTitle.h"
#import "MTScenePianoRoll3D.h"
#import "MTScenePianoRoll2D.h"
#import "MTScenePianoRollRain.h"
#import "MTScenePianoRollRain2D.h"
#import "MTScenePianoRoll3DLive.h"
#import "MTScenePianoRoll2DLive.h"
#import "MTScenePianoRollRainLive.h"
#import "MTScenePianoRollRain2DLive.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MIDITrailApp::MIDITrailApp(void)
{
	//メインメニュー制御
	m_pMenuCtrl = nil;
	
	//ウィンドウ系
	m_pMainWindowCtrl = nil;
	m_pMainView = nil;
	
	//レンダリング系
	m_pScene = NULL;
	memset(&m_RendererParam, 0, sizeof(OGLRedererParam));
	
	//演奏状態
	m_PlayStatus = NoData;
	m_isRepeat = false;
	m_isRewind = false;
	m_isOpenFileAfterStop = false;
	memset(&m_SequencerLastMsg, 0, sizeof(MTSequencerLastMsg));
	m_PlaySpeedRatio = 100;
	
	//表示状態
	m_isEnablePianoKeyboard = true;
	m_isEnableRipple = true;
	m_isEnablePitchBend = true;
	m_isEnableStars = true;
	m_isEnableCounter = true;
	m_isEnableFileName = false;
	
	//シーン種別
	m_SceneType = Title;
	m_SelectedSceneType = PianoRoll3D;
	
	//自動視点保存
	m_isAutoSaveViewpoint = false;
	
	//プレーヤー制御
	m_AutoPlaybackAfterOpenFile = 0;
	
	//ユーザ設定
	m_pUserConf = nil;
	
	//アプリケーションアクティブ状態
	m_isAppActive = true;
	
	//Aboutダイアログ
	m_pAboutDlg = nil;
	
	//リワインド／スキップ制御
	m_SkipBackTimeSpanInMsec = 10000;
	m_SkipForwardTimeSpanInMsec = 10000;
	
	//演奏スピード制御
	m_SpeedStepInPercent = 1;
	m_MaxSpeedInPercent = 400;
	
	//次回オープン対象ファイルパス
	m_pStrNextFilePath = nil;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MIDITrailApp::~MIDITrailApp(void)
{
	//NSLog(@"~MIDITrailApp");
	Terminate();
}

//******************************************************************************
// 初期化
//******************************************************************************
int MIDITrailApp::Initialize(
		MTMenuCtrl* pMenuCtrl
	)
{
	int result = 0;
	
	//メインメニュー制御
	m_pMenuCtrl = pMenuCtrl;
	
	//設定ファイル初期化
	result = _InitConfFile();
	if (result != 0) goto EXIT;
	
	//グラフィック設定読み込み
	result = _LoadGraphicConf();
	if (result != 0) goto EXIT;
	
	//プレーヤー設定読み込み
	result = _LoadPlayerConf();
	if (result != 0) goto EXIT;
	
	//メッセージキュー初期化
	result = m_MsgQueue.Initialize(10000);
	if (result != 0) goto EXIT;
	
	//サンドボックス情報表示
	result = _DispSandboxInfo();
	if (result != 0) goto EXIT;
	
	//シーケンサ初期化
	//  演奏開始時に毎回初期化するので本来はここで実行する必要はないが、
	//  プロセス起動直後の初回演奏開始に限って約2秒止まる現象を回避するため実施する。
	//  当該現象の原因は、MIDI出力制御の初期化処理でCoreMIDI APIである
	//  MIDIGetNumberOfDevices()の呼び出しに1秒以上かかることにある。
	//  プロセス起動時にこの処理を実施して演奏開始時のユーザへのストレスを低減する。
	result = m_Sequencer.Initialize(&m_MsgQueue);
	if (result != 0) goto EXIT;
	
	//メインウィンドウ生成
	result = _CreateWindow();
	if (result != 0) goto EXIT;
	
	//演奏状態変更
	result = _ChangePlayStatus(NoData);
	if (result != 0) goto EXIT;
	
	//シーンオブジェクト生成
	m_SceneType = Title;
	result = _CreateScene(m_SceneType, &m_SeqData);
	if (result != 0) goto EXIT;
	
	//シーン種別読み込み
	result = _LoadSceneType();
	if (result != 0) goto EXIT;
	
	//シーン設定読み込み
	result = _LoadSceneConf();
	if (result != 0) goto EXIT;
	
	//メニュー選択マーク更新
	result = _UpdateMenuCheckmark();
	if (result != 0) goto EXIT;
	
	//キー入力制御初期化
	result = m_DIKeyCtrl.Initialize(nil);
	if (result != 0) goto EXIT;
	
	//ファイルオープンパネル初期化
	result = _InitFileOpenPanel();
	if (result != 0) goto EXIT;
	
	//MIDI OUT 自動設定
	result = _AutoConfigMIDIOUT();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 終了処理
//******************************************************************************
int MIDITrailApp::Terminate()
{
	int result = 0;
	
	//視点保存
	if (m_isAutoSaveViewpoint) {
		result = OnMenuSaveViewpoint();
		//if (result != 0) goto EXIT;
		//エラーが発生しても処理を続行する
	}
	
	//演奏を止める
	if (m_PlayStatus == Play) {
		m_Sequencer.Stop();
		//シーケンサ側のスレッド終了を待ち合わせるべきだが手を抜く
		[NSThread sleepForTimeInterval:0.1];
	}
	else if (m_PlayStatus == MonitorON) {
		m_LiveMonitor.Stop();
		//厳密にはコールバック関数終了を待ち合わせるべきだが手を抜く
		[NSThread sleepForTimeInterval:0.1];
	}
	
	//描画停止
	[m_pMainView stopScene];
	
	//ウィンドウクローズ
	[m_pMainWindowCtrl close];
	
	//シーン破棄
	if (m_pScene != NULL) {
		m_pScene->Release();
		delete m_pScene;
		m_pScene = NULL;
	}
	
	//ユーザ設定
	[m_pUserConf release];
	m_pUserConf = nil;
	
	//キー入力制御終了
	m_DIKeyCtrl.Terminate();
	
	//Aboutダイアログ
	[m_pAboutDlg closeWindow];
	[m_pAboutDlg release];
	m_pAboutDlg = nil;
	
	//次回オープン対象ファイルパス
	[m_pStrNextFilePath release];
	m_pStrNextFilePath = nil;
	
	return result;
}

//******************************************************************************
// 実行
//******************************************************************************
int MIDITrailApp::Run()
{
	int result = 0;
	
	//シーン描画開始
	result = [m_pMainView startScene:m_pScene isMonitor:NO];
	if (result != 0) goto EXIT;
	
	//コマンドライン解析と実行
	result = _ParseCmdLine();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// メインウィンドウ生成
//******************************************************************************
int MIDITrailApp::_CreateWindow()
{
	int result = 0;
	
	//メインウィンドウ生成
	m_pMainWindowCtrl = [[MTMainWindowCtrl alloc] init];
	if (m_pMainWindowCtrl == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ユーザー設定ウィンドウサイズ変更
	result = _SetWindowSize();
	if (result != 0) goto EXIT;
	
	//ユーザー設定ウィンドウ位置変更
	result = _SetWindowPosition();
	if (result != 0) goto EXIT;
	
	//メインビュー生成
	result = [m_pMainWindowCtrl createMainViewWithRendererParam:m_RendererParam];
	if (result != 0) goto EXIT;
	
	//メインビュー初期化
	m_pMainView = [m_pMainWindowCtrl mainView];
	result = [m_pMainView initialize:&m_MsgQueue menuCtrl:m_pMenuCtrl];
	if (result != 0) goto EXIT;
	
	//ウィンドウ表示
	[m_pMainWindowCtrl showWindow];
	
EXIT:;
	return result;
}

//******************************************************************************
// ウィンドウサイズ変更
//******************************************************************************
int MIDITrailApp::_SetWindowSize()
{
	int result = 0;
	int width = 0;
	int height = 0;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_WINDOWSIZE];
	
	//ユーザ選択ウィンドウサイズ取得
	width = [m_pUserConf intValueForKey:@"Width" defaultValue:0];
	height = [m_pUserConf intValueForKey:@"Height" defaultValue:0];
	
	//初回起動時のウィンドウサイズ
	if ((width <= 0) || (height <= 0)) {
		width = 800;
		height = 600;
	}
	
	//ウィンドウサイズ変更
	[m_pMainWindowCtrl setWindowSize:NSMakeSize(width, height)];
	
	return result;
}

//******************************************************************************
// ウィンドウ位置設定
//******************************************************************************
int MIDITrailApp::_SetWindowPosition()
{
	int result = 0;
	int x = 0;
	int y = 0;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_WINDOWPOSITION];
	
	//ウィンドウ位置取得
	x = [m_pUserConf intValueForKey:@"X" defaultValue:-1];
	y = [m_pUserConf intValueForKey:@"Y" defaultValue:-1];
		
	//ウィンドウ位置変更：値が登録されている場合のみ設定する
	if ((x >= 0) && (y >= 0)) {
		[m_pMainWindowCtrl setWindowPosition:NSMakePoint(x, y)];
	}
	
	return result;
}

//******************************************************************************
// 設定ファイル初期化
//******************************************************************************
int MIDITrailApp::_InitConfFile()
{
	int result = 0;
	
	//ユーザ設定は次のプロパティリストファイルに保存する
	// /Users/<username>/Library/Preferences/jp.sourceforge.users.yknk.MIDITrail.plist
	//
	//このファイルの内容を確認するにはターミナルで次のコマンドを実行する
	// $ cd ~/Library/Preferences
	// $ defaults read jp.sourceforge.users.yknk.MIDITrail
	
	//ユーザ設定初期化
	m_pUserConf = [[YNUserConf alloc] init];
	if (m_pUserConf == nil) {
		YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// ファイル選択パネル初期化
//******************************************************************************
int MIDITrailApp::_InitFileOpenPanel()
{
	int result = 0;
	NSString* pDefaultEncodingName = nil;
	NSString* pEncodingName = nil;
	
	//ファイル選択パネル初期化
	result = m_FileOpenPanel.Initialize();
	if (result != 0) goto EXIT;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_PREF];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIFILE];
	
	//エンコーディング選択状態を取得
	pDefaultEncodingName = m_FileOpenPanel.GetDefaultEncodingName();
	pEncodingName = [m_pUserConf strValueForKey:@"Encoding" defaultValue:pDefaultEncodingName];
	
	//エンコーディング選択状態を設定
	m_FileOpenPanel.SetSelectedEncodingName(pEncodingName);
	
EXIT:;
	return result;
}

//******************************************************************************
// アプリケーションアクティブ状態遷移直後
//******************************************************************************
void MIDITrailApp::OnAppActive()
{
	m_isAppActive = true;
	m_DIKeyCtrl.SetActiveState(true);
	[m_pMainView setActiveState:YES];
}

//******************************************************************************
// アプリケーション非アクティブ遷移直後
//******************************************************************************
void MIDITrailApp::OnAppInactive()
{
	m_isAppActive = false;
	m_DIKeyCtrl.SetActiveState(false);
	[m_pMainView setActiveState:NO];
}

//******************************************************************************
// About
//******************************************************************************
int MIDITrailApp::OnMenuAbout()
{
	int result = 0;
	
	//Aboutダイアログ生成
	if (m_pAboutDlg == nil) {
		m_pAboutDlg = [[MTAboutDlg alloc] init];
		if (m_pAboutDlg == nil) {
			result = YN_SET_ERR(@"Program error.", 0, 0);
			goto EXIT;
		}
	}
	
	//Aboutダイアログ表示
	[m_pAboutDlg showWindowOnWindow:[m_pMainWindowCtrl window]];

EXIT:;
	return result;
}

//******************************************************************************
// ファイルオープン
//******************************************************************************
int MIDITrailApp::OnMenuFileOpen()
{
	int result = 0;
	NSString* pPath = nil;
	NSInteger btn = 0;
	
	////演奏中はファイルオープンさせない
	//if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
	//	//ファイルオープンOK
	//}
	//else {
	//	//ファイルオープンNG
	//	goto EXIT;
	//}
	
	//演奏中でもファイルオープン可とする
	
	//ファイル選択パネル表示
	btn = m_FileOpenPanel.showModalWindow();
	
	//エンコーディング選択状態を保存
	[m_pUserConf setCategory:MT_CONF_CATEGORY_PREF];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIFILE];
	[m_pUserConf setStr:m_FileOpenPanel.GetSelectedEncodingName() forKey:@"Encoding"];
	
	//ファイル選択時の処理
	if (btn == NSOKButton) {
		//演奏/モニタ停止とファイルオープン処理
		pPath = m_FileOpenPanel.GetSelectedFilePath();
		result = _StopPlaybackAndOpenFile(pPath);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：再生／一時停止／再開
//******************************************************************************
int MIDITrailApp::OnMenuPlay()
{
	int result = 0;
	
	if (m_PlayStatus == Stop) {
		//シーケンサ初期化
		result = m_Sequencer.Initialize(&m_MsgQueue);
		if (result != 0) goto EXIT;
		
		//シーケンサにポート情報を登録
		result = _SetPortDev(&m_Sequencer);
		if (result != 0) goto EXIT;
		
		//シーケンサにシーケンスデータを登録
		result = m_Sequencer.SetSeqData(&m_SeqData);
		if (result != 0) goto EXIT;
		
		//巻き戻し
		if (m_isRewind) {
			m_isRewind = false;
			result = [m_pMainView scene_Rewind];
			if (result != 0) goto EXIT;
		}
		
		//シーンに演奏開始を通知
		result = [m_pMainView scene_PlayStart];
		if (result != 0) goto EXIT;
		
		//最新シーケンサメッセージクリア
		memset(&m_SequencerLastMsg, 0, sizeof(MTSequencerLastMsg));
		
		//演奏速度
		m_Sequencer.SetPlaySpeedRatio(m_PlaySpeedRatio);
		
		//演奏開始
		result = m_Sequencer.Play();
		if (result != 0) goto EXIT;
		
		//演奏状態変更
		result = _ChangePlayStatus(Play);
		if (result != 0) goto EXIT;
	}
	else if (m_PlayStatus == Play) {
		//演奏一時停止
		m_Sequencer.Pause();
		if (result != 0) goto EXIT;
		
		//演奏状態変更
		result = _ChangePlayStatus(Pause);
		if (result != 0) goto EXIT;
	}
	else if (m_PlayStatus == Pause) {
		//演奏再開
		result = m_Sequencer.Resume();
		if (result != 0) goto EXIT;
		
		//演奏状態変更
		result = _ChangePlayStatus(Play);
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：停止
//******************************************************************************
int MIDITrailApp::OnMenuStop()
{
	int result = 0;
	
	if ((m_PlayStatus == Play) || (m_PlayStatus == Pause)) {
		//演奏停止要求
		m_Sequencer.Stop();
		
		//演奏状態通知が届くまで再生中とみなす
		//ここでは演奏状態を変更しない
		
		//終了後に巻き戻す
		m_isRewind = true;
	}
	
	return result;
}

//******************************************************************************
// メニュー選択：リピート
//******************************************************************************
int MIDITrailApp::OnMenuRepeat()
{
	int result = 0;
	
	//リピート切り替え
	if (m_isRepeat) {
		m_isRepeat = false;
	}
	else {
		m_isRepeat = true;
	}
	
	//メニュー選択マーク更新
	result = _UpdateMenuCheckmark();
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：スキップバック
//******************************************************************************
int MIDITrailApp::OnMenuSkipBack()
{
	int result = 0;
	
	//NSLog(@"OnMenuSkipBack");
	
	result = m_Sequencer.Skip((-1) * m_SkipBackTimeSpanInMsec);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：スキップフォワード
//******************************************************************************
int MIDITrailApp::OnMenuSkipForward()
{
	int result = 0;
	
	//NSLog(@"OnMenuSkipForward");
	
	result = m_Sequencer.Skip((+1) * m_SkipForwardTimeSpanInMsec);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：スピードダウン
//******************************************************************************
int MIDITrailApp::OnMenuPlaySpeedDown()
{
	int result = 0;
	
	//演奏状態確認
	if ((m_PlayStatus == Stop) || (m_PlayStatus == Play) || (m_PlayStatus == Pause)) {
		//変更OK
	}
	else {
		//変更NG
		goto EXIT;
	}
	
	//演奏速度ダウン
	m_PlaySpeedRatio -= m_SpeedStepInPercent;
	
	//リミット
	if (m_PlaySpeedRatio < m_SpeedStepInPercent) {
		m_PlaySpeedRatio = m_SpeedStepInPercent;
	}
	
	//演奏速度設定
	m_Sequencer.SetPlaySpeedRatio(m_PlaySpeedRatio);
	m_pScene->SetPlaySpeedRatio(m_PlaySpeedRatio);
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：スピードアップ
//******************************************************************************
int MIDITrailApp::OnMenuPlaySpeedUp()
{
	int result = 0;
	
	//演奏状態確認
	if ((m_PlayStatus == Stop) || (m_PlayStatus == Play) || (m_PlayStatus == Pause)) {
		//変更OK
	}
	else {
		//変更NG
		goto EXIT;
	}	
	
	//演奏速度アップ
	m_PlaySpeedRatio += m_SpeedStepInPercent;
	
	//リミット 400%
	if (m_PlaySpeedRatio > m_MaxSpeedInPercent) {
		m_PlaySpeedRatio = m_MaxSpeedInPercent;
	}
	
	//演奏速度設定
	m_Sequencer.SetPlaySpeedRatio(m_PlaySpeedRatio);
	m_pScene->SetPlaySpeedRatio(m_PlaySpeedRatio);
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：ライブモニタ開始
//******************************************************************************
int MIDITrailApp::OnMenuStartMonitoring()
{
	int result = 0;
	
	//演奏状態確認
	if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
		//モニタ開始OK
	}
	else {
		//モニタ開始NG
		goto EXIT;
	}
	
	//ライブモニタ用シーン生成
	if (m_PlayStatus != MonitorOFF) {
		//視点保存
		if (m_isAutoSaveViewpoint) {
			result = OnMenuSaveViewpoint();
			if (result != 0) goto EXIT;
		}
		
		//シーン停止
		result = [m_pMainView stopScene];
		if (result != 0) goto EXIT;
		
		//シーン種別
		m_SceneType = m_SelectedSceneType;
		
		//シーン生成
		result = _CreateScene(m_SceneType, NULL);
		if (result != 0) goto EXIT;
		
		//シーン開始
		result = [m_pMainView startScene:m_pScene isMonitor:YES];
		if (result != 0) goto EXIT;
	}
		
	//ライブモニタ初期化
	result = m_LiveMonitor.Initialize(&m_MsgQueue);
	if (result != 0) goto EXIT;
	result = _SetMonitorPortDev(&m_LiveMonitor, m_pScene);
	if (result != 0) goto EXIT;
	
	//シーンに演奏開始を通知
	result = [m_pMainView scene_PlayStart];
	if (result != 0) goto EXIT;	
	
	//ライブモニタ開始
	result = m_LiveMonitor.Start();
	if (result != 0) goto EXIT;
	
	//演奏状態変更
	result = _ChangePlayStatus(MonitorON);
	if (result != 0) goto EXIT;
		
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：ライブモニタ停止
//******************************************************************************
int MIDITrailApp::OnMenuStopMonitoring()
{
	int result = 0;
	
	//演奏状態確認
	if (m_PlayStatus == MonitorON) {
		//モニタ開始OK
	}
	else {
		//モニタ開始NG
		goto EXIT;
	}
	
	//ライブモニタ停止
	result = m_LiveMonitor.Stop();
	if (result != 0) goto EXIT;
	
	//演奏状態変更
	result = _ChangePlayStatus(MonitorOFF);
	if (result != 0) goto EXIT;
	
	//シーンに演奏終了を通知
	if (m_pScene != NULL) {
		result = [m_pMainView scene_PlayEnd];
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：シーン種別
//******************************************************************************
int MIDITrailApp::OnMenuSelectSceneType(
		MIDITrailApp::SceneType type
	)
{
	int result = 0;
	BOOL isMonitor = NO;
	
	//演奏状態確認
	if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
		//シーンタイプ選択OK
	}
	else {
		//シーンタイプ選択NG
		goto EXIT;
	}
	
	//保存
	m_SelectedSceneType = type;
	result = _SaveSceneType();
	if (result != 0) goto EXIT;
	
	//メニュー選択マーク更新
	result = _UpdateMenuCheckmark();
	if (result != 0) goto EXIT;
	
	//停止中の場合はシーンを再構築
	if ((m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
		//視点保存
		if (m_isAutoSaveViewpoint) {
			result = OnMenuSaveViewpoint();
			if (result != 0) goto EXIT;
		}
		
		//シーン停止
		result = [m_pMainView stopScene];
		if (result != 0) goto EXIT;
		
		//シーン生成
		m_SceneType = m_SelectedSceneType;
		if (m_PlayStatus == Stop) {
			//プレイヤのシーン種別切り替え
			isMonitor = NO;
			result = _CreateScene(m_SceneType, &m_SeqData);
			if (result != 0) goto EXIT;
		}
		else {
			//ライブモニタのシーン種別切り替え
			isMonitor = YES;
			result = _CreateScene(m_SceneType, NULL);
			if (result != 0) goto EXIT;
		}
		
		//シーン開始
		result = [m_pMainView startScene:m_pScene isMonitor:isMonitor];
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：自動視点保存
//******************************************************************************
int MIDITrailApp::OnMenuAutoSaveViewpoint()
{
	int result = 0;

	m_isAutoSaveViewpoint = m_isAutoSaveViewpoint ? false : true;

	//メニュー選択マーク更新
	result = _UpdateMenuCheckmark();
	if (result != 0) goto EXIT;

	//シーン設定保存
	result = _SaveSceneConf();
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：視点リセット
//******************************************************************************
int MIDITrailApp::OnMenuResetViewpoint()
{
	int result = 0;
	
	if (m_PlayStatus == NoData) goto EXIT;
	
	//シーンの視点をリセット
	result = [m_pMainView scene_ResetViewpoint];
	if (result != 0) goto EXIT;
	
	//視点保存
	result = _SaveViewpoint();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：視点保存
//******************************************************************************
int MIDITrailApp::OnMenuSaveViewpoint()
{
	int result = 0;
	
	if (m_PlayStatus == NoData) goto EXIT;
	
	//視点保存
	result = _SaveViewpoint();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：表示効果設定
//******************************************************************************
int MIDITrailApp::OnMenuEnableEffect(
		MTScene::EffectType type
	)
{
	int result = 0;
	
	switch (type) {
		case MTScene::EffectPianoKeyboard:
			m_isEnablePianoKeyboard = m_isEnablePianoKeyboard ? false : true;
			break;
		case MTScene::EffectRipple:
			m_isEnableRipple = m_isEnableRipple ? false : true;
			break;
		case MTScene::EffectPitchBend:
			m_isEnablePitchBend = m_isEnablePitchBend ? false : true;
			break;
		case MTScene::EffectStars:
			m_isEnableStars = m_isEnableStars ? false : true;
			break;
		case MTScene::EffectCounter:
			m_isEnableCounter = m_isEnableCounter ? false : true;
			break;
		default:
			break;
	}
	
	//シーンに表示効果を設定する
	result = _UpdateEffect();
	if (result != 0) goto EXIT;
	
	//メインメニューの表示効果選択状態を設定する
	_UpdateMenuCheckmark();
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択：ウィンドウサイズ変更
//******************************************************************************
int MIDITrailApp::OnMenuWindowSize()
{
	int result = 0;
	MTWindowSizeCfgDlg* pWindowSizeCfgDlg = nil;
	
	//ウィンドウ生成
	pWindowSizeCfgDlg = [[MTWindowSizeCfgDlg alloc] init];
	if (pWindowSizeCfgDlg == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//モーダルウィンドウ表示
	[pWindowSizeCfgDlg showModalWindow];
	
	//変更された場合はウィンドウサイズを更新
	if ([pWindowSizeCfgDlg isCahnged]) {
		result = _ChangeWindowSize();
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	[pWindowSizeCfgDlg release];
	return result;
}

//******************************************************************************
// メニュー選択：MIDI出力デバイス設定
//******************************************************************************
int MIDITrailApp::OnMenuOptionMIDIOUT()
{
	int result = 0;
	MTMIDIOUTCfgDlg* pMIDIOUTCfgDlg = nil;
	
	//ウィンドウ生成
	pMIDIOUTCfgDlg = [[MTMIDIOUTCfgDlg alloc] init];
	if (pMIDIOUTCfgDlg == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//モーダルウィンドウ表示
	[pMIDIOUTCfgDlg showModalWindow];
	
EXIT:;
	[pMIDIOUTCfgDlg release];
	return result;
}

//******************************************************************************
// メニュー選択：MIDI入力デバイス設定
//******************************************************************************
int MIDITrailApp::OnMenuOptionMIDIIN()
{
	int result = 0;

	MTMIDIINCfgDlg* pMIDIINCfgDlg = nil;
	
	//ウィンドウ生成
	pMIDIINCfgDlg = [[MTMIDIINCfgDlg alloc] init];
	if (pMIDIINCfgDlg == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//モーダルウィンドウ表示
	[pMIDIINCfgDlg showModalWindow];
	
EXIT:;
	[pMIDIINCfgDlg release];
	return result;
}

//******************************************************************************
// メニュー選択：グラフィック設定
//******************************************************************************
int MIDITrailApp::OnMenuOptionGraphic()
{
	int result = 0;
	MTGraphicCfgDlg* pGraphicCfgDlg = nil;
	
	//ウィンドウ生成
	pGraphicCfgDlg = [[MTGraphicCfgDlg alloc] init];
	if (pGraphicCfgDlg == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//モーダルウィンドウ表示
	[pGraphicCfgDlg showModalWindow];
	
	//変更された場合はレンダラとシーンオブジェクトを再生成
	if ([pGraphicCfgDlg isCahnged]) {
		result = _LoadGraphicConf();
		if (result != 0) goto EXIT;
		result = _ChangeWindowSize();
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	[pGraphicCfgDlg release];
	return result;
}

//******************************************************************************
// HowToView表示
//******************************************************************************
int MIDITrailApp::OnMenuHowToView()
{
	int result = 0;
	MTHowToViewDlg* pHowToViewDlg = nil;
	
	//ウィンドウ生成
	pHowToViewDlg = [[MTHowToViewDlg alloc] init];
	if (pHowToViewDlg == nil) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//モーダルウィンドウ表示
	[pHowToViewDlg showModalWindow];
	
EXIT:;
	[pHowToViewDlg release];
	return result;
}

//******************************************************************************
// マニュアル表示
//******************************************************************************
int MIDITrailApp::OnMenuManual()
{
	int result = 0;
	NSString* pFilePath = nil;
	
	pFilePath = [NSString stringWithFormat:@"%@/%@",
							[YNPathUtil resourceDirPath], MT_MANUALFILE];
	
	//マニュアルファイルを開く
	[[NSWorkspace sharedWorkspace] openFile:pFilePath];
	
	return result;
}

//******************************************************************************
// 演奏状態変更通知：一時停止
//******************************************************************************
int MIDITrailApp::OnChangePlayStatusPause()
{
	int result = 0;
	
	result = _ChangePlayStatus(Pause);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏状態変更通知：停止（演奏終了）
//******************************************************************************
int MIDITrailApp::OnChangePlayStatusStop()
{
	int result = 0;
	
	result = _ChangePlayStatus(Stop);
	if (result != 0) goto EXIT;
	
	//シーンに演奏終了を通知
	if (m_pScene != NULL) {
		result = [m_pMainView scene_PlayEnd];
		if (result != 0) goto EXIT;
	}
	
	//視点保存
	if (m_isAutoSaveViewpoint) {
		result = OnMenuSaveViewpoint();
		if (result != 0) goto EXIT;
	}
	
	//ユーザーの要求によって停止した場合は巻き戻す
	if ((m_isRewind) && (m_pScene != NULL)) {
		m_isRewind = false;
		result = [m_pMainView scene_Rewind];
		if (result != 0) goto EXIT;
	}
	//停止後のファイルオープンが指定されている場合
	else if ((m_isOpenFileAfterStop) && (m_pScene != NULL)) {
		m_isOpenFileAfterStop = false;
		//ファイル読み込み処理
		result = _FileOpenProc(m_pStrNextFilePath);
		if (result != 0) goto EXIT;
	}
	//通常の演奏終了の場合は次回の演奏時に巻き戻す
	else {
		m_isRewind = true;
		//リピート有効なら再生開始
		if (m_isRepeat) {
			result = OnMenuPlay();
			if (result != 0) goto EXIT;
		}
	}
	
	//コマンドラインで終了指定されている場合
	if (m_CmdLineParser.GetSwitch(CMDSW_QUIET) == CMDSW_ON) {
		[m_pMenuCtrl performActionQuit];
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// ファイルドロップイベント
//******************************************************************************
int MIDITrailApp::OnDropFile(
		NSString* pPath
	)
{
	int result = 0;
	
	////停止中でなければファイルドロップは無視する
	//if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
	//	//ファイルドロップOK
	//}
	//else {
	//	//ファイルドロップNG
	//	goto EXIT;
	//}
	
	//常にファイルドロップを許可する
	
	//演奏/モニタ停止とファイルオープン処理
	result = _StopPlaybackAndOpenFile(pPath);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIファイル読み込み
//******************************************************************************
int MIDITrailApp::_LoadMIDIFile(
		NSString* pFilePath
	)
{
	int result = 0;
	NSString* pLogFilePath = nil;
	SMFileReader smfReader;
	MTStatusDlg* pStatusDlg = nil;
	
	//ステータスウィンドウ表示
	//  ファイルドロップ処理実行後、マウス移動量取得API CGGetLastMouseDelta が
	//  正しく動作しなくなる（ドラッグしないと移動量が0になる）。
	//  問題の現象は、MIDItrailのメインウィンドウをアクティブにしたまま
	//  SMFファイルをドロップすると発生する。
	//  他のウィンドウにフォーカスを移してから戻すと正常に動くようになるため、
	//  ステータスウィンドウを表示することにより回避する。
	pStatusDlg = [[MTStatusDlg alloc] initWithMessage:@"Loading..."];
	[pStatusDlg showWindowOnWindow:[m_pMainWindowCtrl window]];
	
	//デバッグモードであればMIDIファイル解析結果をダンプする
	if (m_CmdLineParser.GetSwitch(CMDSW_DEBUG) == CMDSW_ON) {
		pLogFilePath = [NSString stringWithFormat:@"%@%@", pFilePath, @".dump.txt"];
		smfReader.SetLogPath(pLogFilePath);
	}
	
	//ファイル読み込み
	smfReader.SetEncodingId(m_FileOpenPanel.GetSelectedEncodingId());
	result = smfReader.Load(pFilePath, &m_SeqData);
	if (result != 0) goto EXIT;
	
	//描画停止
	result = [m_pMainView stopScene];
	if (result != 0) goto EXIT;
	
	//ファイル読み込み時に再生スピードを100%に戻す：_CreateSceneでカウンタに反映
	m_PlaySpeedRatio = 100;
	
	//シーンオブジェクト生成
	m_SceneType = m_SelectedSceneType;
	result = _CreateScene(m_SceneType, &m_SeqData);
	if (result != 0) goto EXIT;
	
	//演奏状態変更
	result = _ChangePlayStatus(Stop);
	if (result != 0) goto EXIT;
	
	m_isRewind = false;
	
	//描画開始
	result = [m_pMainView startScene:m_pScene isMonitor:NO];
	if (result != 0) goto EXIT;
	
EXIT:;
	//ステータスウィンドウクローズ
	[pStatusDlg closeWindow];
	[pStatusDlg release];
	return result;
}

//******************************************************************************
// ポート情報登録
//******************************************************************************
int MIDITrailApp::_SetPortDev(
		SMSequencer* pSequencer
	)
{
	int result = 0;
	unsigned char portNo = 0;
	NSString* pDevIdName = nil;
	NSString* portName[] = {@"PortA", @"PortB", @"PortC", @"PortD", @"PortE", @"PortF"};
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_MIDI];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIOUT];
	
	//設定ファイルからユーザ選択デバイス名を取得してシーケンサに登録
	for (portNo = 0; portNo < SM_MIDIOUT_PORT_NUM_MAX; portNo++) {
		pDevIdName = [m_pUserConf strValueForKey:portName[portNo] defaultValue:@""];
		if ([pDevIdName length] > 0) {
			result = pSequencer->SetPortDev(portNo, pDevIdName);
			if (result != 0) goto EXIT;
		}
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDI IN モニタ情報登録
//******************************************************************************
int MIDITrailApp::_SetMonitorPortDev(
		SMLiveMonitor* pLiveMonitor,
		MTScene* pScene
	)
{
	int result = 0;
	NSString* pDevIdName = nil;
	NSString* pDevDisplayName = nil;
	int checkMIDITHRU = 0;
	bool isMIDITHRU = false;
	
	//--------------------------------------
	// MIDI IN
	//--------------------------------------
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_MIDI];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIIN];
	
	//設定ファイルからユーザ選択デバイス名を取得してシーケンサに登録
	pDevIdName = [m_pUserConf strValueForKey:@"PortA" defaultValue:@""];
	checkMIDITHRU = [m_pUserConf intValueForKey:@"MIDITHRU" defaultValue:1];
	if (checkMIDITHRU > 0) {
		isMIDITHRU = true;
	}
	if ([pDevIdName length] > 0) {
		result = pLiveMonitor->SetInPortDev(pDevIdName, isMIDITHRU);
		if (result != 0) goto EXIT;
	}
	
	//シーンに MIDI IN デバイス名を登録
	pDevDisplayName = pLiveMonitor->GetInPortDevDisplayName(pDevIdName);
	result = pScene->SetParam(@"MIDI_IN_DEVICE_NAME", pDevDisplayName);
	if (result != 0) goto EXIT;	
	
	//--------------------------------------
	// MIDI OUT (MIDITHRU)
	//--------------------------------------
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_MIDI];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIOUT];
	
	//設定ファイルからユーザ選択デバイス名を取得してシーケンサに登録
	pDevIdName = [m_pUserConf strValueForKey:@"PortA" defaultValue:@""];
	if (result != 0) goto EXIT;
	
	if (([pDevIdName length] > 0) && (isMIDITHRU)) {
		result = pLiveMonitor->SetOutPortDev(pDevIdName);
		if (result != 0) goto EXIT;
	}
		
EXIT:;
	return result;
}

//******************************************************************************
// ウィンドウサイズ変更
//******************************************************************************
int MIDITrailApp::_ChangeWindowSize()
{
	int result = 0;
	BOOL isMonitor = NO;
	
	//停止中でなければサイズ変更は禁止
	if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop)) {
		isMonitor = NO;
	}
	else if (m_PlayStatus == MonitorOFF) {
		isMonitor = YES;
	}
	else {
		//サイズ変更NG
		goto EXIT;
	}
	
	//描画停止
	result = [m_pMainView stopScene];
	if (result != 0) goto EXIT;
	
	//シーン破棄
	if (m_pScene != NULL) {
		m_pScene->Release();
		delete m_pScene;
		m_pScene = NULL;
	}
	
	//メインビューの終了と破棄
	[m_pMainWindowCtrl deleteMainView];
	
	//ビューだけ破棄／再生成して対応したかったが再生成後の描画が正常にならない
	//ウィンドウごと破棄して作り直すことで回避する
	
	//メインウィンドウを閉じる
	[m_pMainWindowCtrl close];
	
	//メインウィンドウ破棄
	[m_pMainWindowCtrl release];
	m_pMainWindowCtrl = nil;
	
	//メインウィンドウ生成
	result = _CreateWindow();
	if (result != 0) goto EXIT;
	
	//メインビューにファイルドラック許可状態を再設定する
	_ChangePlayStatus(m_PlayStatus);
	
	//シーンオブジェクト生成
	if (!isMonitor) {
		//プレイヤのシーン生成
		result = _CreateScene(m_SceneType, &m_SeqData);
		if (result != 0) goto EXIT;
	}
	else {
		//ライブモニタのシーン生成
		result = _CreateScene(m_SceneType, NULL);
		if (result != 0) goto EXIT;
	}
	
	//描画開始
	result = [m_pMainView startScene:m_pScene isMonitor:isMonitor];
	if (result != 0) goto EXIT;
	
	//再生成したウィンドウにアプリケーションのアクティブ状態を伝える
	OnAppActive();
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏状態変更
//******************************************************************************
int MIDITrailApp::_ChangePlayStatus(
		PlayStatus status
	)
{
	int result = 0;
	
	//演奏状態変更
	m_PlayStatus = status;
	
	////ファイルドラック許可
	//if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
	//	[m_pMainView setDragAcceptable:YES];
	//}
	//else {
	//	[m_pMainView setDragAcceptable:NO];
	//}
	
	//常にファイルドラッグ許可
	[m_pMainView setDragAcceptable:YES];
	
	//メニュースタイル更新
	result = _ChangeMenuStyle();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュースタイル更新
//******************************************************************************
int MIDITrailApp::_ChangeMenuStyle()
{
	int result = 0;
	
	unsigned long menuIndex = 0;
	unsigned long statusIndex = 0;
	BOOL isEnable = NO;
	
	//メニューID一覧
	//TAG:シーン追加
	MTMenuItem menuID[MT_MENU_NUM] = {
		MenuOpen,
		MenuPlay,
		MenuStop,
		MenuRepeat,
		MenuSkipBack,
		MenuSkipForward,
		MenuPlaySpeedDown,
		MenuPlaySpeedUp,
		MenuStartMonitoring,
		MenuStopMonitoring,
		MenuPianoRoll3D,
		MenuPianoRoll2D,
		MenuPianoRollRain,
		MenuPianoRollRain2D,
		MenuAutoSaveViewpoint,
		MenuResetViewpoint,
		MenuSaveViewpoint,
		MenuPianoKeyboard,
		MenuRipple,
		MenuPitchBend,
		MenuStars,
		MenuCounter,
		MenuWindowSize,
		MenuMIDIOUT,
		MenuMIDIIN,
		MenuGraphic,
		MenuHowToView,
		MenuManual
	};
	
	//メニュースタイル一覧
	BOOL menuEnabled[MT_MENU_NUM][MT_PLAYSTATUS_NUM] = {
		//データ無, 停止, 再生中, 一時停止, メニューID, モニタ停止, モニタ中
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuOpen
		{	NO,		YES,	YES,	YES,	NO,		NO	},	//MenuPlay
		{	NO,		NO,		YES,	YES,	NO,		NO	},	//MenuStop
		{	YES,	YES,	YES,	YES,	NO,		NO	},	//MenuRepeat
		{	NO,		NO,		YES,	NO,		NO,		NO	},	//MenuSkipBack
		{	NO,		NO,		YES,	NO,		NO,		NO	},	//MenuSkipForward
		{	NO,		YES,	YES,	YES,	NO,		NO	},	//MenuPlaySpeedDown
		{	NO,		YES,	YES,	YES,	NO,		NO	},	//MenuPlaySpeedUp
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuStartMonitor
		{	NO,		NO,		NO,		NO,		NO,		YES	},	//MenuStopMonitor
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuPianoRoll3D
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuPianoRoll2D
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuPianoRollRain
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuPianoRollRain2D
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuAutoSaveViewpoint
		{	NO,		YES,	YES,	YES,	YES,	YES	},	//MenuResetViewpoint
		{	NO,		YES,	YES,	YES,	YES,	YES	},	//MenuSaveViewpoint
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuPianoKeyboard
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuRipple
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuPitchBend
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuStars
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuCounter
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuWindowSize
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuMIDIOUT
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuMIDIIN
		{	YES,	YES,	NO,		NO,		YES,	NO	},	//MenuGraphic
		{	YES,	YES,	YES,	YES,	YES,	YES	},	//MenuHowToView
		{	YES,	YES,	YES,	YES,	YES,	YES	}	//MenuManual
	};
	
	switch (m_PlayStatus) {
		case NoData: statusIndex = 0; break;
		case Stop:   statusIndex = 1; break;
		case Play:   statusIndex = 2; break;
		case Pause:  statusIndex = 3; break;
		case MonitorOFF: statusIndex = 4; break;
		case MonitorON:  statusIndex = 5; break;
	}
	
	//メニュースタイル更新
	for (menuIndex = 0; menuIndex < MT_MENU_NUM; menuIndex++) {
		isEnable = menuEnabled[menuIndex][statusIndex];
		[m_pMenuCtrl setEnabled:isEnable forItem:menuID[menuIndex]];
	}
	
	return result;
}

//******************************************************************************
// シーン生成
//******************************************************************************
int MIDITrailApp::_CreateScene(
		SceneType type,
		SMSeqData* pSeqData  //ライブモニタ時はNULL
	)
{
	int result = 0;
	OGLDevice* pDevice = NULL;
	
	//シーンオブジェクト生成時は描画スレッドが存在しないため
	//シーンオブジェクトを直接操作することが許される
	
	//シーン破棄
	if (m_pScene != NULL) {
		m_pScene->Release();
		delete m_pScene;
		m_pScene = NULL;
	}
	
	//シーンオブジェクト生成
	//TAG:シーン追加
	try {
		if (type == Title) {
			m_pScene = new MTSceneTitle();
		}
		else {
			//プレイヤ用シーン生成
			if (pSeqData != NULL) {
				if (type == PianoRoll3D) {
					m_pScene = new MTScenePianoRoll3D();
				}
				else if (type == PianoRoll2D) {
					m_pScene = new MTScenePianoRoll2D();
				}
				else if (type == PianoRollRain) {
					m_pScene = new MTScenePianoRollRain();
				}
				else if (type == PianoRollRain2D) {
					m_pScene = new MTScenePianoRollRain2D();
				}
			}
			//ライブモニタ用シーン生成
			else {
				if (type == PianoRoll3D) {
					m_pScene = new MTScenePianoRoll3DLive();
				}		
				else if (type == PianoRoll2D) {
					m_pScene = new MTScenePianoRoll2DLive();
				}		
				else if (type == PianoRollRain) {
					m_pScene = new MTScenePianoRollRainLive();
				}
				else if (type == PianoRollRain2D) {
					m_pScene = new MTScenePianoRollRain2DLive();
				}
			}
		}
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", type, 0);
		goto EXIT;
	}
	
	if (m_pScene == NULL) {
		result = YN_SET_ERR(@"Program error.", type, 0);
		goto EXIT;
	}
	
	//シーンの生成
	pDevice = [m_pMainView getDevice];
	result = m_pScene->Create(m_pMainView, pDevice, pSeqData);
	if (result != 0) goto EXIT;
	
	//保存されている視点をシーンに反映する
	if (type != Title) {
		result = _LoadViewpoint();
		if (result != 0) goto EXIT;
	}
	
	//表示効果反映
	//  描画スレッドが存在しないため _UpdateEffect() を呼び出してはならない
	m_pScene->SetEffect(MTScene::EffectPianoKeyboard, m_isEnablePianoKeyboard);
	m_pScene->SetEffect(MTScene::EffectRipple, m_isEnableRipple);
	m_pScene->SetEffect(MTScene::EffectPitchBend, m_isEnablePitchBend);
	m_pScene->SetEffect(MTScene::EffectStars, m_isEnableStars);
	m_pScene->SetEffect(MTScene::EffectCounter, m_isEnableCounter);
	m_pScene->SetEffect(MTScene::EffectFileName, m_isEnableFileName);
	
	//演奏速度設定
	m_pScene->SetPlaySpeedRatio(m_PlaySpeedRatio);
	
EXIT:;
	return result;
}

//******************************************************************************
// シーン種別読み込み
//******************************************************************************
int MIDITrailApp::_LoadSceneType()
{
	int result = 0;
	NSString* pType = nil;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_SCENE];
	
	//ユーザ設定値取得：シーン種別
	pType = [m_pUserConf strValueForKey:@"Type" defaultValue:@""];
	
	//TAG:シーン追加
	if ([pType isEqualToString:@"PianoRoll3D"]) {
		m_SelectedSceneType = PianoRoll3D;
	}
	else if ([pType isEqualToString:@"PianoRoll2D"]) {
		m_SelectedSceneType = PianoRoll2D;
	}
	else if ([pType isEqualToString:@"PianoRollRain"]) {
		m_SelectedSceneType = PianoRollRain;
	}
	else if ([pType isEqualToString:@"PianoRollRain2D"]) {
		m_SelectedSceneType = PianoRollRain2D;
	}
	else {
		m_SelectedSceneType = PianoRoll3D;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// シーン種別保存
//******************************************************************************
int MIDITrailApp::_SaveSceneType()
{
	int result = 0;
	NSString* pType = @"";
	
	//TAG:シーン追加
	switch (m_SelectedSceneType) {
		case PianoRoll3D:
			pType = @"PianoRoll3D";
			break;
		case PianoRoll2D:
			pType = @"PianoRoll2D";
			break;
		case PianoRollRain:
			pType = @"PianoRollRain";
			break;
		case PianoRollRain2D:
			pType = @"PianoRollRain2D";
			break;
		default:
			result = YN_SET_ERR(@"Program error.", m_SelectedSceneType, 0);
			goto EXIT;
			break;
	}
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_SCENE];
	
	//ユーザ設定登録
	[m_pUserConf setStr:pType forKey:@"Type"];
	
EXIT:;
	return result;
}

//******************************************************************************
// シーン設定読み込み
//******************************************************************************
int MIDITrailApp::_LoadSceneConf()
{
	int result = 0;
	int autoSaveViewpoint = 0;

	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_SCENE];
	
	//ユーザ設定値取得：自動視点保存
	autoSaveViewpoint = [m_pUserConf intValueForKey:@"AutoSaveViewpoint" defaultValue:0];
	
	m_isAutoSaveViewpoint = false;
	if (autoSaveViewpoint == 1) {
		m_isAutoSaveViewpoint = true;
	}

EXIT:;
	return result;
}

//******************************************************************************
// シーン設定保存
//******************************************************************************
int MIDITrailApp::_SaveSceneConf()
{
	int result = 0;
	int autoSaveViewpoint = 0;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_SCENE];
	
	//ユーザ設定登録：自動視点保存
	autoSaveViewpoint = m_isAutoSaveViewpoint ? 1 : 0;
	[m_pUserConf setInt:autoSaveViewpoint forKey:@"AutoSaveViewpoint"];
	
EXIT:;
	return result;
}

//******************************************************************************
// 視点読み込み
//******************************************************************************
int MIDITrailApp::_LoadViewpoint()
{
	int result = 0;
	MTScene::MTViewParamMap defParamMap;
	MTScene::MTViewParamMap viewParamMap;
	MTScene::MTViewParamMap::iterator itr;
	NSString* pSection = nil;
	NSString* pKey = nil;
	float param = 0.0f;
	
	//視点読み込み処理はシーン停止後に新しいシーンオブジェクト生成してから実施する
	//描画スレッドは存在しないためシーンオブジェクトを直接操作することが許される
	
	//シーンからデフォルトの視点を取得
	m_pScene->GetDefaultViewParam(&defParamMap);
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	pSection = [NSString stringWithFormat:@"%@%@", MT_CONF_SECTION_VIEWPOINT, m_pScene->GetName()];
	[m_pUserConf setSection:pSection];
	
	//パラメータを設定ファイルから取得
	for (itr = defParamMap.begin(); itr != defParamMap.end(); itr++) {
		pKey = [NSString stringWithCString:(itr->first).c_str() encoding:NSASCIIStringEncoding];
		param = [m_pUserConf floatValueForKey:pKey defaultValue:(itr->second)];
		
		if (result != 0) goto EXIT;
		viewParamMap.insert(MTScene::MTViewParamMapPair((itr->first).c_str(), param));
	}
	
	//シーンに視点を登録
	m_pScene->SetViewParam(&viewParamMap);
	
EXIT:;
	return result;
}

//******************************************************************************
// 視点保存
//******************************************************************************
int MIDITrailApp::_SaveViewpoint()
{
	int result = 0;
	MTScene::MTViewParamMap viewParamMap;
	MTScene::MTViewParamMap::iterator itr;
	NSString* pSection = nil;
	NSString* pKey = nil;
	
	//シーンから現在の視点を取得
	[m_pMainView scene_GetViewpoint:&viewParamMap];
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	pSection = [NSString stringWithFormat:@"%@%@", MT_CONF_SECTION_VIEWPOINT, m_pScene->GetName()];
	[m_pUserConf setSection:pSection];
	
	//パラメータを設定ファイルに登録
	for (itr = viewParamMap.begin(); itr != viewParamMap.end(); itr++) {
		pKey = [NSString stringWithCString:(itr->first).c_str() encoding:NSASCIIStringEncoding];
		[m_pUserConf setFloat:itr->second forKey:pKey];
	}
	
	//視点が切り替えられたことをシーンに伝達
	[m_pMainView scene_SetViewpoint:&viewParamMap];
	
EXIT:;
	return result;
}

//******************************************************************************
// グラフィック設定読み込み
//******************************************************************************
int MIDITrailApp::_LoadGraphicConf()
{
	int result = 0;
	int enableAntialiasing = 0;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_GRAPHIC];
	[m_pUserConf setSection:MT_CONF_SECTION_AA];
	
	//ユーザ設定値
	enableAntialiasing = [m_pUserConf intValueForKey:@"EnableAntialias"
										defaultValue:0];
	if (enableAntialiasing == 0) {
		m_RendererParam.isEnableAntialiasing = NO;
	}
	else {
		m_RendererParam.isEnableAntialiasing = YES;
	}
	
	m_RendererParam.sampleMode = [m_pUserConf intValueForKey:@"SampleMode"
												defaultValue:0];
	m_RendererParam.sampleNum = [m_pUserConf intValueForKey:@"SampleNum"
											   defaultValue:0];
	
EXIT:;
	return result;
}

//******************************************************************************
// プレーヤー設定読み込み
//******************************************************************************
int MIDITrailApp::_LoadPlayerConf()
{
	int result = 0;
	MTConfFile confFile;
	int timeSpan = 400;
	int showFileName = 0;
	
	result = confFile.Initialize(@"Player");
	if (result != 0) goto EXIT;
	
	//----------------------------------
	//プレーヤー制御
	//----------------------------------
	result = confFile.SetCurSection(@"PlayerControl");
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"AutoPlaybackAfterOpenFile", &m_AutoPlaybackAfterOpenFile, 0);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	//表示制御
	//----------------------------------
	result = confFile.SetCurSection(@"ViewControl");
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"ShowFileName", &showFileName, 0);
	if (result != 0) goto EXIT;
	m_isEnableFileName = (showFileName > 0) ? true : false;
	
	//----------------------------------
	//リワインド／スキップ制御
	//----------------------------------
	result = confFile.SetCurSection(@"SkipControl");
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"SkipBackTimeSpanInMsec", &m_SkipBackTimeSpanInMsec, 10000);
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"SkipForwardTimeSpanInMsec", &m_SkipForwardTimeSpanInMsec, 10000);
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"MovingTimeSpanInMsec", &timeSpan, 400);
	if (result != 0) goto EXIT;
	
	//シーケンサにリワインド／スキップ移動時間を設定
	m_Sequencer.SetMovingTimeSpanInMsec(timeSpan);
	
	//----------------------------------
	//演奏スピード制御
	//----------------------------------
	result = confFile.SetCurSection(@"PlaybackSpeedControl");
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"SpeedStepInPercent", &m_SpeedStepInPercent, 1);
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"MaxSpeedInPercent", &m_MaxSpeedInPercent, 400);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// HowToView表示
//******************************************************************************
int MIDITrailApp::_DispHowToView()
{
	int result = 0;
	int count = 0;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_VIEW];
	[m_pUserConf setSection:MT_CONF_SECTION_HOWTOVIEW];
	
	//ユーザ設定値取得
	count = [m_pUserConf intValueForKey:@"DispCount" defaultValue:0];
	
	if (count != 2) {
		//操作方法ダイアログ表示
		result = OnMenuHowToView();
		if (result != 0) goto EXIT;
	}
	
	count = 2;
	[m_pUserConf setInt:count forKey:@"DispCount"];
	
EXIT:;
	return result;
}

//******************************************************************************
// メニュー選択マーク更新
//******************************************************************************
int MIDITrailApp::_UpdateMenuCheckmark()
{
	int result = 0;
	
	//リピート
	[m_pMenuCtrl setMark:m_isRepeat forItem:MenuRepeat];
	
	//シーン種別選択
	//TAG:シーン追加
	[m_pMenuCtrl setMark:NO forItem:MenuPianoRoll3D];
	[m_pMenuCtrl setMark:NO forItem:MenuPianoRoll2D];
	[m_pMenuCtrl setMark:NO forItem:MenuPianoRollRain];
	[m_pMenuCtrl setMark:NO forItem:MenuPianoRollRain2D];
	switch (m_SelectedSceneType) {
		case PianoRoll3D:
			[m_pMenuCtrl setMark:YES forItem:MenuPianoRoll3D];
			break;
		case PianoRoll2D:
			[m_pMenuCtrl setMark:YES forItem:MenuPianoRoll2D];
			break;
		case PianoRollRain:
			[m_pMenuCtrl setMark:YES forItem:MenuPianoRollRain];
			break;
		case PianoRollRain2D:
			[m_pMenuCtrl setMark:YES forItem:MenuPianoRollRain2D];
			break;
		default:
			result = YN_SET_ERR(@"Program error.", m_SelectedSceneType, 0);
			goto EXIT;
			break;
	}
	
	//ピアノキーボード表示
	[m_pMenuCtrl setMark:m_isEnablePianoKeyboard forItem:MenuPianoKeyboard];
	
	//波紋効果
	[m_pMenuCtrl setMark:m_isEnableRipple forItem:MenuRipple];
	
	//ピッチベンド効果
	[m_pMenuCtrl setMark:m_isEnablePitchBend forItem:MenuPitchBend];
	
	//星表示
	[m_pMenuCtrl setMark:m_isEnableStars forItem:MenuStars];
	
	//カウンタ表示
	[m_pMenuCtrl setMark:m_isEnableCounter forItem:MenuCounter];
	
	//自動視点保存
	[m_pMenuCtrl setMark:m_isAutoSaveViewpoint forItem:MenuAutoSaveViewpoint];
	
EXIT:;
	return result;
}

//******************************************************************************
// 表示効果反映
//******************************************************************************
int MIDITrailApp::_UpdateEffect()
{
	int result = 0;
	
	result = [m_pMainView scene_SetEffect:(MTScene::EffectPianoKeyboard)
								 isEnable:m_isEnablePianoKeyboard];
	if (result != 0) goto EXIT;
	
	result = [m_pMainView scene_SetEffect:(MTScene::EffectRipple)
								 isEnable:m_isEnableRipple];
	if (result != 0) goto EXIT;
	
	result = [m_pMainView scene_SetEffect:(MTScene::EffectPitchBend)
								 isEnable:m_isEnablePitchBend];
	if (result != 0) goto EXIT;
	
	result = [m_pMainView scene_SetEffect:(MTScene::EffectStars)
								 isEnable:m_isEnableStars];
	if (result != 0) goto EXIT;
	
	result = [m_pMainView scene_SetEffect:(MTScene::EffectCounter)
								 isEnable:m_isEnableCounter];
	if (result != 0) goto EXIT;
	
	result = [m_pMainView scene_SetEffect:(MTScene::EffectFileName)
								 isEnable:m_isEnableFileName];
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// コマンドライン解析
//******************************************************************************
int MIDITrailApp::_ParseCmdLine()
{
	int result = 0;
	
	//コマンドライン解析
	result = m_CmdLineParser.Initialize();
	if (result != 0) goto EXIT;
	
	//コマンドラインでファイルを指定されている場合
	if (m_CmdLineParser.GetSwitch(CMDSW_FILE_PATH) == CMDSW_ON) {
		
		//ファイルを開く
		result = _LoadMIDIFile(m_CmdLineParser.GetFilePath());
		if (result != 0) goto EXIT;
		
		//再生指定されている場合は再生開始
		if ((m_CmdLineParser.GetSwitch(CMDSW_PLAY) == CMDSW_ON) ||
		    (m_AutoPlaybackAfterOpenFile > 0)) {
			[m_pMenuCtrl performActionPlay];
		}
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// タイマー間隔取得（ミリ秒）
//******************************************************************************
unsigned long MIDITrailApp::GetTimerInterval()
{
	return 200;
}

//******************************************************************************
// タイマー呼び出し
//******************************************************************************
int MIDITrailApp::OnTimer()
{
	int result = 0;
	
	//再生速度制御
	if (m_DIKeyCtrl.IsKeyDown(DIK_F2) && m_isAppActive) {
		m_Sequencer.SetPlaybackSpeed(2);  //2倍速
	}
	else {
		m_Sequencer.SetPlaybackSpeed(1);
	}
	
	return result;
}

//******************************************************************************
// MIDI OUT 自動設定
//******************************************************************************
int MIDITrailApp::_AutoConfigMIDIOUT()
{
	int result = 0;
	NSString* pDevIdName = nil;
	NSString* pMsg = nil;
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_MIDI];
	[m_pUserConf setSection:MT_CONF_SECTION_MIDIOUT];
	
	//設定ファイルから MIDI OUT ユーザ選択デバイス名を取得
	pDevIdName = [m_pUserConf strValueForKey:@"PortA" defaultValue:@""];
	if ([pDevIdName length] == 0) {
		//設定なしの場合
		if ([m_pUserConf intValueForKey:@"AutoConfigConfirm" defaultValue:0] == 0) {
			//自動設定未確認の場合はMIDI OUTデバイスを自動設定する
			[m_pUserConf setInt:1 forKey:@"AutoConfigConfirm"];
			[m_pUserConf setStr:SM_APPLE_DLS_DEVID_NAME forKey:@"PortA"];
			
			//自動設定確認アラートパネル表示
			pMsg = @"MIDItrail selected Apple DLS Music Device to MIDI OUT. If you have any other MIDI device, please configure MIDI OUT.";
			NSRunInformationalAlertPanel(@"INFORMATION", pMsg, @"OK", nil, nil);
		}
		else {
			//自動設定確認済みのため何もしない
		}
	}
	else {
		//設定ありの場合
		[m_pUserConf setInt:1 forKey:@"AutoConfigConfirm"];
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏/モニタ停止とMIDIファイルオープン処理
//******************************************************************************
int MIDITrailApp::_StopPlaybackAndOpenFile(
		NSString* pFilePath
	)
{
	int result = 0;
	
	//演奏ステータスごとの対応方式
	//  データ無   → すぐにファイルを開く
	//  停止       → すぐにファイルを開く
	//  再生中     → シーケンサに停止要求を出す → 停止通知を受けた後にファイルを開く
	//  一時停止   → シーケンサに停止要求を出す → 停止通知を受けた後にファイルを開く
	//  モニタ停止 → すぐにファイルを開く
	//  モニタ中   → モニタを停止してモニタ停止状態へ遷移 → すぐにファイルを開く
	
	//視点保存
	if (m_isAutoSaveViewpoint) {
		result = OnMenuSaveViewpoint();
		if (result != 0) goto EXIT;
	}
	
	//モニタ中であれば停止する
	if (m_PlayStatus == MonitorON) {
		result = OnMenuStopMonitoring();
		if (result != 0) goto EXIT;
		//この時点でモニタ停止に遷移済み
	}
	
	//停止中であればすぐにファイルを開く
	if ((m_PlayStatus == NoData) || (m_PlayStatus == Stop) || (m_PlayStatus == MonitorOFF)) {
		//ファイル読み込み処理
		result = _FileOpenProc(pFilePath);
		if (result != 0) goto EXIT;
	}
	//演奏中の場合は演奏停止後にファイルを開く
	else if ((m_PlayStatus == Play) || (m_PlayStatus == Pause)) {
		//演奏状態通知が届くまで再生中とみなす
		//ここでは演奏状態を変更しない
		m_Sequencer.Stop();
		
		//停止完了後にファイルを開く
		[pFilePath retain];
		[m_pStrNextFilePath release];
		m_pStrNextFilePath = pFilePath;
		m_isOpenFileAfterStop = true;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIファイルオープン処理
//******************************************************************************
int MIDITrailApp::_FileOpenProc(
		NSString* pFilePath
	)
{
	int result = 0;
	
	//MIDIファイル読み込み
	result = _LoadMIDIFile(pFilePath);
	if (result != 0) goto EXIT;
	
	//HowToView表示
	result = _DispHowToView();
	if (result != 0) goto EXIT;

	//再生指定されている場合は再生開始
	if (m_AutoPlaybackAfterOpenFile > 0) {
		result = OnMenuPlay();
		if (result != 0) goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// サンドボックス情報表示
//******************************************************************************
int MIDITrailApp::_DispSandboxInfo()
{
	int result = 0;
	int apiresult = 0;
	NSDictionary* pInfo = nil;
	NSString* pBundleVersion = nil;
	NSString* pPrevVersion = nil;
	NSString* pTitle = nil;
	NSString* pMessage = nil;
	
	//アプリのバージョンを取得
	pInfo = [[NSBundle mainBundle] infoDictionary];
	pBundleVersion = [pInfo objectForKey:@"CFBundleShortVersionString"];
	
	//カテゴリ／セクション設定
	[m_pUserConf setCategory:MT_CONF_CATEGORY_ETC];
	[m_pUserConf setSection:MT_CONF_SECTION_SANDBOX];
	
	//前回起動時のバージョンを取得
	pPrevVersion = [m_pUserConf strValueForKey:@"PreviousVersion" defaultValue:@""];
	
	//今回起動時と前回起動時が異なるバージョンであり
	//かつOSバージョンが10.7(Lion)以降の場合 (#define NSAppKitVersionNumber10_7 1138)
	//  Apple DLS Music Device を利用するとき、OSによって下記の警告メッセージが表示されるため、
	//  あらかじめユーザに対してアプリ側から知らせておく。
	//  要求された Audio Unit を使用するには、"MIDITrail"のセキュリティ設定を下げる必要があります。
	//  続けてもよろしいですか？  [セキュリティ設定を下げる] [キャンセル]
	NSLog(@"ver %f", NSAppKitVersionNumber);
	
	if ((![pBundleVersion isEqualToString:pPrevVersion])
		&& (NSAppKitVersionNumber >= 1138.0)) {
		pTitle = @"INFORMATION";
		pMessage = @"MIDITrail uses Apple DLS audio device.\n"
					"Therefore Mac may ask you to lower security settings to use it.";
		//アラートパネル表示：2,3番目のボタンは表示しない
		apiresult = NSRunAlertPanel(pTitle, pMessage, @"OK", nil, nil);
	}
	
	//今回起動時のバージョンを前回起動時のバージョンとして保存
	[m_pUserConf setStr:pBundleVersion forKey:@"PreviousVersion"];
	
//EXIT:;
	return result;
}

