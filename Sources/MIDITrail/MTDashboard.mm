//******************************************************************************
//
// MIDITrail / MTDashboard
//
// ダッシュボード描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MTDashboard.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTDashboard::MTDashboard(void)
{
	m_pView = nil;
	m_PosCounterX = 0.0f;
	m_PosCounterY = 0.0f;
	m_CounterMag = MTDASHBOARD_DEFAULT_MAGRATE;
	
	m_PlayTimeSec = 0;
	m_TotalPlayTimeSec = 0;
	m_TempoBPM = 0;
	m_BeatNumerator = 0;
	m_BeatDenominator = 0;
	m_BarNo = 0;
	m_BarNum = 0;
	m_NoteCount = 0;
	m_NoteNum = 0;
	m_PlaySpeedRatio = 100;
	
	m_TempoBPMOnStart = 0;
	m_BeatNumeratorOnStart = 0;
	m_BeatDenominatorOnStart = 0;
	
	m_CaptionColor = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
	
	m_isEnable = true;
	m_isEnableFileName = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTDashboard::~MTDashboard(void)
{
	Release();
}

//******************************************************************************
// ダッシュボード生成
//******************************************************************************
int MTDashboard::Create(
		OGLDevice* pOGLDevice,
		NSString* pSceneName,
		SMSeqData* pSeqData,
		NSView* pView
   )
{
	int result = 0;
	NSString* pTitle = nil;
	NSString* pFileName = nil;
	SMTrack track;
	SMNoteList noteList;
	char counter[100];
	
	Release();
	
	if (pSeqData == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	m_pView = pView;
	
	//設定読み込み
	result = _LoadConfFile(pSceneName);
	if (result != 0) goto EXIT;
	
	//タイトルキャプション
	//空文字ではテクスチャ生成でエラーとなるため末尾に空白文字を含める
	pTitle = [NSString stringWithFormat:@"%@ ", pSeqData->GetTitle()];
	
	result = m_Title.Create(
					pOGLDevice,
					MTDASHBOARD_FONTNAME,	//フォント名称
					MTDASHBOARD_FONTSIZE,	//フォントサイズ
					pTitle					//キャプション
				);
	if (result != 0) goto EXIT;
	m_Title.SetColor(m_CaptionColor);
	
	//ファイル名キャプション
	//空文字ではテクスチャ生成でエラーとなるため末尾に空白文字を含める
	pFileName = [NSString stringWithFormat:@"%@ ",  pSeqData->GetFileName()];
	
	result = m_FileName.Create(
					pOGLDevice,
					MTDASHBOARD_FONTNAME,	//フォント名称
					MTDASHBOARD_FONTSIZE,	//フォントサイズ
					pFileName				//ファイル名
				);
	if (result != 0) goto EXIT;
	m_FileName.SetColor(m_CaptionColor);
	
	//カウンタキャプション
	result = m_Counter.Create(
					pOGLDevice,
					MTDASHBOARD_FONTNAME,		//フォント名称
					MTDASHBOARD_FONTSIZE,		//フォントサイズ
					MTDASHBOARD_COUNTER_CHARS,	//表示文字
					MTDASHBOARD_COUNTER_SIZE	//キャプションサイズ
				);
	if (result != 0) goto EXIT;
	m_Counter.SetColor(m_CaptionColor);
	
	//全体演奏時間
	SetTotalPlayTimeSec(pSeqData->GetTotalPlayTime()/1000);
	
	//テンポ(BPM)
	SetTempoBPM(pSeqData->GetTempoBPM());
	m_TempoBPMOnStart = pSeqData->GetTempoBPM();
	
	//拍子記号
	SetBeat(pSeqData->GetBeatNumerator(), pSeqData->GetBeatDenominator());
	m_BeatNumeratorOnStart = pSeqData->GetBeatNumerator();
	m_BeatDenominatorOnStart = pSeqData->GetBeatDenominator();
	
	//小節番号
	SetBarNo(1);
	
	//小節数
	SetBarNum(pSeqData->GetBarNum());
	
	result = pSeqData->GetMergedTrack(&track);
	if (result != 0) goto EXIT;
	
	result = track.GetNoteList(&noteList);
	if (result != 0) goto EXIT;
	
	m_NoteNum = noteList.GetSize();
	
	//カウンタ表示文字列生成
	result = _GetCounterStr(counter, 100);
	if (result != 0) goto EXIT;
	
	result = m_Counter.SetString(counter);
	if (result != 0) goto EXIT;
	
	//カウンタ表示位置を算出
	result = _GetCounterPos(&m_PosCounterX, &m_PosCounterY);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 移動
//******************************************************************************
int MTDashboard::Transform(
		OGLDevice* pOGLDevice,
		OGLVECTOR3 camVector
	)
{
	int result = 0;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTDashboard::Draw(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	char counter[100];
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	if (!m_isEnable) goto EXIT;
	
	if (m_isEnableFileName) {
		//ファイル名描画：カウンタと同じ拡大率で表示する
		result = m_FileName.Draw(pOGLDevice, MTDASHBOARD_FRAMESIZE, MTDASHBOARD_FRAMESIZE, m_CounterMag);
		if (result != 0) goto EXIT;
	}
	else {
		//タイトル描画：カウンタと同じ拡大率で表示する
		result = m_Title.Draw(pOGLDevice, MTDASHBOARD_FRAMESIZE, MTDASHBOARD_FRAMESIZE, m_CounterMag);
		if (result != 0) goto EXIT;
	}
	
	//カウンタ文字列描画
	result = _GetCounterStr(counter, 100);
	if (result != 0) goto EXIT;
	
	result = m_Counter.SetString(counter);
	if (result != 0) goto EXIT;
	
	result = m_Counter.Draw(pOGLDevice, m_PosCounterX, m_PosCounterY, m_CounterMag);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTDashboard::Release()
{
	m_Title.Release();
	m_FileName.Release();
	m_Counter.Release();
}

//******************************************************************************
// カウンタ表示位置取得
//******************************************************************************
int MTDashboard::_GetCounterPos(
		float* pX,
		float* pY
	)
{
	int result = 0;
	NSRect rect;
	unsigned long cw, ch = 0;
	unsigned long tw, th = 0;
	unsigned long charHeight, charWidth = 0;
	unsigned long captionWidth = 0;
	float newMag = 0.0f;
	
	//クライアント領域のサイズを取得
	rect = [m_pView bounds];
	cw = rect.size.width;
	ch = rect.size.height;
	
	//テクスチャサイズ取得
	m_Counter.GetTextureSize(&th, &tw);
	
	//文字サイズ
	charHeight = th;
	charWidth = tw / strlen(MTDASHBOARD_COUNTER_CHARS);
	
	//拡大率1.0のキャプションサイズ
	captionWidth = (unsigned long)(charWidth * MTDASHBOARD_COUNTER_SIZE);
	
	//カウンタ文字列が画面からはみ出す場合は画面に収まるように拡大率を更新する
	//  タイトルがはみ出すのは気にしないことにする
	if (((cw - (MTDASHBOARD_FRAMESIZE*2)) < captionWidth) && (tw > 0)) {
		newMag = (float)(cw - (MTDASHBOARD_FRAMESIZE*2)) / (float)captionWidth;
		if (m_CounterMag > newMag) {
			m_CounterMag = newMag;
		}
	}
	
	//テクスチャの表示倍率を考慮して表示位置を算出
	*pX = MTDASHBOARD_FRAMESIZE;
	*pY = (float)ch - ((float)th * m_CounterMag) - MTDASHBOARD_FRAMESIZE;

EXIT:;
	return result;
}

//******************************************************************************
// 演奏時間登録（秒）
//******************************************************************************
void MTDashboard::SetPlayTimeSec(
		unsigned long playTimeSec
	)
{
	m_PlayTimeSec = playTimeSec;
}

//******************************************************************************
// 全体演奏時間登録（秒）
//******************************************************************************
void MTDashboard::SetTotalPlayTimeSec(
		unsigned long totalPlayTimeSec
	)
{
	m_TotalPlayTimeSec = totalPlayTimeSec;
}

//******************************************************************************
// テンポ登録(BPM)
//******************************************************************************
void MTDashboard::SetTempoBPM(
		unsigned long bpm
	)
{
	m_TempoBPM = bpm;
}

//******************************************************************************
// 拍子記号登録
//******************************************************************************
void MTDashboard::SetBeat(
		unsigned long numerator,
		unsigned long denominator
	)
{
	m_BeatNumerator = numerator;
	m_BeatDenominator = denominator;
}

//******************************************************************************
// 小節数登録
//******************************************************************************
void MTDashboard::SetBarNum(
		unsigned long barNum
	)
{
	m_BarNum = barNum;
}

//******************************************************************************
// 小節番号登録
//******************************************************************************
void MTDashboard::SetBarNo(
		unsigned long barNo
	)
{
	m_BarNo = barNo;
}

//******************************************************************************
// ノートON登録
//******************************************************************************
void MTDashboard::SetNoteOn()
{
	m_NoteCount++;
}

//******************************************************************************
// 演奏速度登録
//******************************************************************************
void MTDashboard::SetPlaySpeedRatio(
		unsigned long ratio
	)
{
	m_PlaySpeedRatio = ratio;
}

//******************************************************************************
// ノート数登録
//******************************************************************************
void MTDashboard::SetNotesCount(
		unsigned long notesCount
	)
{
	m_NoteCount = notesCount;
}

//******************************************************************************
// カウンタ文字列取得
//******************************************************************************
int MTDashboard::_GetCounterStr(
		char* pStr,
		unsigned long bufSize
	)
{
	int result = 0;
	int eresult = 0;
	char spdstr[16] = {0};
	
	eresult = snprintf(
				pStr,
				bufSize,
				"TIME:%02lu:%02lu/%02lu:%02lu BPM:%03lu BEAT:%lu/%lu BAR:%03lu/%03lu NOTES:%05lu/%05lu",
				m_PlayTimeSec / 60,
				m_PlayTimeSec % 60,
				m_TotalPlayTimeSec / 60,
				m_TotalPlayTimeSec % 60,
				m_TempoBPM,
				m_BeatNumerator,
				m_BeatDenominator,
				m_BarNo,
				m_BarNum,
				m_NoteCount,
				m_NoteNum
			);
	if (eresult < 0) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//演奏速度が100%以外の場合に限りカウンタに表示する
	if (m_PlaySpeedRatio != 100) {
		eresult = snprintf(spdstr, 16, " SPEED:%03lu%%", m_PlaySpeedRatio);
		if (eresult < 0) {
			result = YN_SET_ERR(@"Program error.", 0, 0);
			goto EXIT;
		}
		strncat(pStr, spdstr, bufSize - strlen(pStr) - 1);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTDashboard::Reset()
{
	m_PlayTimeSec = 0;
	m_TempoBPM = m_TempoBPMOnStart;
	m_BeatNumerator = m_BeatNumeratorOnStart;
	m_BeatDenominator = m_BeatDenominatorOnStart;
	m_BarNo = 1;
	m_NoteCount = 0;
}

//******************************************************************************
// 設定ファイル読み込み
//******************************************************************************
int MTDashboard::_LoadConfFile(
		NSString* pSceneName
	)
{
	int result = 0;
	NSString* pHexColor = nil;
	MTConfFile confFile;
	
	result = confFile.Initialize(pSceneName);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	//色情報
	//----------------------------------
	result = confFile.SetCurSection(@"Color");
	if (result != 0) goto EXIT;
	
	//キャプションカラー
	result = confFile.GetStr(@"CaptionRGBA", &pHexColor, @"FFFFFFFF");
	if (result != 0) goto EXIT;
	m_CaptionColor = OGLColorUtil::MakeColorFromHexRGBA(pHexColor);
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏時間取得
//******************************************************************************
unsigned long MTDashboard::GetPlayTimeSec()
{
	return m_PlayTimeSec;
}

//******************************************************************************
// 表示設定
//******************************************************************************
void MTDashboard::SetEnable(
		bool isEnable
	)
{
	m_isEnable = isEnable;
}

//******************************************************************************
// ファイル名表示設定
//******************************************************************************
void MTDashboard::SetEnableFileName(
		bool isEnable
	)
{
	m_isEnableFileName = isEnable;
}

