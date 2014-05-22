//******************************************************************************
//
// MIDITrail / MTDashboard
//
// ダッシュボード描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 曲名／演奏時間／テンポ／ビート／小節番号 を表示する。

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
#define MTDASHBOARD_FONTNAME  @"Monaco"
#define MTDASHBOARD_FONTSIZE  (40)

//カウンタキャプション文字列
#define MTDASHBOARD_COUNTER_CHARS  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:/% "

//カウンタキャプションサイズ
//   12345678901234567890123456789012345678901234567890123456789012345678901234  (74)
//  "TIME:00:00/00:00 BPM:000 BEAT:4/4 BAR:000/000 NOTES:00000/00000 SPEED:000%"
//  余裕をみて80にしておく
#define MTDASHBOARD_COUNTER_SIZE  (80)

//枠サイズ（ピクセル）
#define MTDASHBOARD_FRAMESIZE  (5.0f)

//デフォルト表示拡大率
#define MTDASHBOARD_DEFAULT_MAGRATE  (0.45f)  //Windows版では0.5

//******************************************************************************
// ダッシュボード描画クラス
//******************************************************************************
class MTDashboard
{
public:
	
	//コンストラクタ／デストラクタ
	MTDashboard(void);
	virtual ~MTDashboard(void);
	
	//生成
	int Create(OGLDevice* pOGLDevice, NSString* pSceneName, SMSeqData* pSeqData, NSView* pView);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, OGLVECTOR3 camVector);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//演奏経過時間と総演奏時間の登録
	void SetPlayTimeSec(unsigned long playTimeSec);
	void SetTotalPlayTimeSec(unsigned long totalPlayTimeSec);
	
	//テンポ登録
	void SetTempoBPM(unsigned long bpm);
	
	//小節番号と全小節数の登録
	void SetBarNo(unsigned long barNo);
	void SetBarNum(unsigned long barNum);
	
	//拍子記号登録
	void SetBeat(unsigned long numerator, unsigned long denominator);
	
	//ノートON登録
	void SetNoteOn();
	
	//演奏速度登録
	void SetPlaySpeedRatio(unsigned long ratio);
	
	//リセット
	void Reset();
	
	//ノート数登録
	void SetNotesCount(unsigned long notesCount);
	
	//演奏時間取得
	unsigned long GetPlayTimeSec();
	
	//表示設定
	void SetEnable(bool isEnable);
	
	//ファイル名表示設定
	void SetEnableFileName(bool isEnable);
	
private:
	
	NSView* m_pView;
	
	MTStaticCaption m_Title;
	MTStaticCaption m_FileName;
	
	MTDynamicCaption m_Counter;
	float m_PosCounterX;
	float m_PosCounterY;
	float m_CounterMag;
	
	unsigned long m_PlayTimeSec;
	unsigned long m_TotalPlayTimeSec;
	unsigned long m_TempoBPM;
	unsigned long m_BeatNumerator;
	unsigned long m_BeatDenominator;
	unsigned long m_BarNo;
	unsigned long m_BarNum;
	unsigned long m_NoteCount;
	unsigned long m_NoteNum;
	unsigned long m_PlaySpeedRatio;
	
	unsigned long m_TempoBPMOnStart;
	unsigned long m_BeatNumeratorOnStart;
	unsigned long m_BeatDenominatorOnStart;
	
	OGLCOLOR m_CaptionColor;
	
	//表示可否
	bool m_isEnable;
	bool m_isEnableFileName;
	
	int _GetCounterPos(float* pX, float* pY);
	int _GetCounterStr(char* pStr, unsigned long bufSize);
	int _LoadConfFile(NSString* pSceneName);
	
};


