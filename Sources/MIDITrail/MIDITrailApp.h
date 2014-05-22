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
#import "SMIDILib.h"
#import "OGLUtil.h"
#import "DIKeyCtrl.h"
#import "MTScene.h"
#import "MTWindowSizeCfgDlg.h"
#import "MTMIDIOUTCfgDlg.h"
#import "MTMIDIINCfgDlg.h"
#import "MTGraphicCfgDlg.h"
#import "MTHowToViewDlg.h"
#import "MTAboutDlg.h"
#import "MTStatusDlg.h"
#import "MTCmdLineParser.h"
#import "MTMainWindowCtrl.h"
#import "MTMainView.h"
#import "MTMenuCtrl.h"
#import "MTFileOpenPanel.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//演奏状態数
#define MT_PLAYSTATUS_NUM  (6)


//******************************************************************************
// MIDITrail アプリケーションクラス
//******************************************************************************
class MIDITrailApp
{
public:
	
	//シーン種別
	//TAG:シーン追加
	enum SceneType {
		Title,				//タイトル
		PianoRoll3D,		//ピアノロール3D
		PianoRoll2D,		//ピアノロール2D
		PianoRollRain,		//ピアノロールレイン
		PianoRollRain2D		//ピアノロールレイン2D
	};
	
public:
	
	//コンストラクタ／デストラクタ
	MIDITrailApp(void);
	virtual ~MIDITrailApp(void);
	
	//初期化
	int Initialize(MTMenuCtrl* pMenuCtrl);
	
	//実行
	int Run();
	
	//停止
	int Terminate();
	
	//アプリケーションアクティブ状態設定
	void OnAppActive();
	void OnAppInactive();
	
	//メニューイベント処理
	int OnMenuAbout();
	int OnMenuFileOpen();
	int OnMenuPlay();
	int OnMenuStop();
	int OnMenuRepeat();
	int OnMenuSkipBack();
	int OnMenuSkipForward();
	int OnMenuPlaySpeedDown();
	int OnMenuPlaySpeedUp();
	int OnMenuStartMonitoring();
	int OnMenuStopMonitoring();
	int OnMenuAutoSaveViewpoint();
	int OnMenuResetViewpoint();
	int OnMenuSaveViewpoint();
	int OnMenuEnableEffect(MTScene::EffectType type);
	int OnMenuWindowSize();
	int OnMenuOptionMIDIOUT();
	int OnMenuOptionMIDIIN();
	int OnMenuOptionGraphic();
	int OnMenuHowToView();
	int OnMenuManual();
	int OnMenuSelectSceneType(SceneType type);
	
	//演奏状態変更通知
	int OnChangePlayStatusPause();
	int OnChangePlayStatusStop();
	
	//ファイルドロップイベント
	int OnDropFile(NSString* pPath);
	
	//タイマー呼び出し
	unsigned long GetTimerInterval();
	int OnTimer();
	
private:
	
	//----------------------------------------------------------------
	//パラメータ定義
	//----------------------------------------------------------------
	//演奏状態
	enum PlayStatus {
		NoData,			//データなし
		Stop,			//停止状態
		Play,			//再生中
		Pause,			//一時停止
		MonitorOFF,		//モニタ停止
		MonitorON		//モニタ中
	};
	
	//シーケンサメッセージ
	typedef struct {
		unsigned long wParam;
		unsigned long lParam;
	} MTSequencerMsg;
	
	//最新シーケンサメッセージ
	typedef struct {
		bool isRecvPlayTime;
		bool isRecvTempo;
		bool isRecvBar;
		bool isRecvBeat;
		MTSequencerMsg playTime;
		MTSequencerMsg tempo;
		MTSequencerMsg bar;
		MTSequencerMsg beat;
	} MTSequencerLastMsg;
	
private:
	
	//----------------------------------------------------------------
	//メンバ定義
	//----------------------------------------------------------------
	//コマンドラインパーサ
	MTCmdLineParser m_CmdLineParser;
	
	//メインメニュー制御
	MTMenuCtrl* m_pMenuCtrl;
	
	//ウィンドウ系
	MTMainWindowCtrl* m_pMainWindowCtrl;
	MTMainView* m_pMainView;
	MTFileOpenPanel m_FileOpenPanel;
	
	//レンダリング系
	MTScene* m_pScene;
	OGLRedererParam m_RendererParam;
	
	//MIDI制御系
	SMSeqData m_SeqData;
	SMSequencer m_Sequencer;
	SMMsgQueue m_MsgQueue;
	SMLiveMonitor m_LiveMonitor;
	
	//演奏状態
	PlayStatus m_PlayStatus;
	bool m_isRepeat;
	bool m_isRewind;
	bool m_isOpenFileAfterStop;
	MTSequencerLastMsg m_SequencerLastMsg;
	unsigned long m_PlaySpeedRatio;
	
	//表示効果
	bool m_isEnablePianoKeyboard;
	bool m_isEnableRipple;
	bool m_isEnablePitchBend;
	bool m_isEnableStars;
	bool m_isEnableCounter;
	bool m_isEnableFileName;
	
	//シーン種別
	SceneType m_SceneType;
	SceneType m_SelectedSceneType;
	
	//設定ファイル
	YNUserConf* m_pUserConf;
	
	//アプリケーションアクティブ状態
	bool m_isAppActive;
	
	//キー入力制御
	DIKeyCtrl m_DIKeyCtrl;
	
	//Aboutダイアログ
	MTAboutDlg* m_pAboutDlg;
	
	//プレーヤー制御
	int m_AllowMultipleInstances;
	int m_AutoPlaybackAfterOpenFile;
	
	//リワインド／スキップ制御
	int m_SkipBackTimeSpanInMsec;
	int m_SkipForwardTimeSpanInMsec;
	
	//演奏スピード制御
	int m_SpeedStepInPercent;
	int m_MaxSpeedInPercent;
	
	//自動視点保存
	bool m_isAutoSaveViewpoint;
	
	//次回オープン対象ファイルパス
	NSString* m_pStrNextFilePath;
	
	//----------------------------------------------------------------
	//メソッド定義
	//----------------------------------------------------------------
	//ウィンドウ制御
	int _CreateWindow();
	int _SetWindowSize();
	int _SetWindowPosition();
	
	//初期化処理
	int _InitConfFile();
	int _InitFileOpenPanel();
	
	int _LoadMIDIFile(NSString* pFilePath);
	int _SetPortDev(SMSequencer* pSequencer);
	int _SetMonitorPortDev(SMLiveMonitor* pLiveMonitor, MTScene* pScene);
	int _ChangeWindowSize();
	int _ChangePlayStatus(PlayStatus status);
	int _ChangeMenuStyle();
	int _CreateScene(SceneType type, SMSeqData* pSeqData);
	int _LoadSceneType();
	int _SaveSceneType();
	int _LoadSceneConf();
	int _SaveSceneConf();
	int _LoadViewpoint();
	int _SaveViewpoint();
	int _LoadGraphicConf();
	int _LoadPlayerConf();
	int _DispHowToView();
	int _UpdateMenuCheckmark();
	int _UpdateEffect();
	int _ParseCmdLine();
	int _AutoConfigMIDIOUT();
	int _StopPlaybackAndOpenFile(NSString* pFilePath);
	int _FileOpenProc(NSString* pFilePath);
	int _DispSandboxInfo();
};


