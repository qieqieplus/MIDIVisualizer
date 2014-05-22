//******************************************************************************
//
// MIDITrail / MTDashboardLive
//
// ライブモニタ用ダッシュボード描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// MIDI IN デイバイス名, ノート数 を表示する。

#import "SMIDILib.h"
#import "OGLUtil.h"
#import "MTStaticCaption.h"
#import "MTDynamicCaption.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//フォント設定
//  Windows ：フォントサイズ40 -> ビットマップサイズ縦40ピクセル (MS Gothic)
//  Mac OS X：フォントサイズ40 -> ビットマップサイズ縦50ピクセル (Monaco)
#define MTDASHBOARDLIVE_FONTNAME  @"Monaco"
#define MTDASHBOARDLIVE_FONTSIZE  (40)

//カウンタキャプション文字列
#define MTDASHBOARDLIVE_COUNTER_CHARS  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:/%[] "

//カウンタキャプションサイズ
//   1234567890123456789012345678901  (31)
//  "NOTES:00000000 [MONITERING OFF]"
//  余裕をみて40にしておく
#define MTDASHBOARDLIVE_COUNTER_SIZE  (40)

//枠サイズ（ピクセル）
#define MTDASHBOARDLIVE_FRAMESIZE  (5.0f)

//デフォルト表示拡大率
#define MTDASHBOARDLIVE_DEFAULT_MAGRATE  (0.45f)  //Windows版では0.5

//******************************************************************************
// ライブモニタ用ダッシュボード描画クラス
//******************************************************************************
class MTDashboardLive
{
public:
	
	//コンストラクタ／デストラクタ
	MTDashboardLive(void);
	virtual ~MTDashboardLive(void);
	
	//生成
	int Create(OGLDevice* pOGLDevice, NSString* pSceneName, NSView* pView);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, OGLVECTOR3 camVector);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//モニタ状態登録
	void SetMonitoringStatus(bool isMonitoring);
	
	//ノートON登録
	void SetNoteOn();
	
	//リセット
	void Reset();
	
	//表示設定
	void SetEnable(bool isEnable);
	
	//MIDI IN デバイス名登録
	int SetMIDIINDeviceName(NSString* pName);
	
private:
	
	NSView* m_pView;
	
	MTStaticCaption m_Title;
	
	MTDynamicCaption m_Counter;
	float m_PosCounterX;
	float m_PosCounterY;
	float m_CounterMag;
	
	bool m_isMonitoring;
	unsigned long m_NoteCount;
	
	OGLCOLOR m_CaptionColor;
	
	//表示可否
	bool m_isEnable;
	
	int _GetCounterPos(float* pX, float* pY);
	int _GetCounterStr(char* pStr, unsigned long bufSize);
	int _LoadConfFile(NSString* pSceneName);
	
};


