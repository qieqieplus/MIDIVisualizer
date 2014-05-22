//******************************************************************************
//
// MIDITrail / MTDashboardLive
//
// ライブモニタ用ダッシュボード描画クラス
//
// Copyright (C) 2012-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MTDashboardLive.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTDashboardLive::MTDashboardLive(void)
{
	m_pView = nil;
	m_PosCounterX = 0.0f;
	m_PosCounterY = 0.0f;
	m_CounterMag = MTDASHBOARDLIVE_DEFAULT_MAGRATE;
	m_isMonitoring = false;
	m_NoteCount = 0;
	m_CaptionColor = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f);
	m_isEnable = true;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTDashboardLive::~MTDashboardLive(void)
{
	Release();
}

//******************************************************************************
// ダッシュボード生成
//******************************************************************************
int MTDashboardLive::Create(
		OGLDevice* pOGLDevice,
		NSString* pSceneName,
		NSView* pView
   )
{
	int result = 0;
	char counter[100];

	Release();
	
	m_pView = pView;
	
	//設定読み込み
	result = _LoadConfFile(pSceneName);
	if (result != 0) goto EXIT;
	
	//タイトルキャプション
	result = SetMIDIINDeviceName(@"");
	if (result != 0) goto EXIT;
	
	//カウンタキャプション
	result = m_Counter.Create(
					pOGLDevice,
					MTDASHBOARDLIVE_FONTNAME,		//フォント名称
					MTDASHBOARDLIVE_FONTSIZE,		//フォントサイズ
					MTDASHBOARDLIVE_COUNTER_CHARS,	//表示文字
					MTDASHBOARDLIVE_COUNTER_SIZE	//キャプションサイズ
				);
	if (result != 0) goto EXIT;
	m_Counter.SetColor(m_CaptionColor);
	
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
int MTDashboardLive::Transform(
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
int MTDashboardLive::Draw(
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
	
	//タイトル描画：カウンタと同じ拡大率で表示する
	result = m_Title.Draw(pOGLDevice, MTDASHBOARDLIVE_FRAMESIZE, MTDASHBOARDLIVE_FRAMESIZE, m_CounterMag);
	if (result != 0) goto EXIT;
	
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
void MTDashboardLive::Release()
{
	m_Title.Release();
	m_Counter.Release();
}

//******************************************************************************
// カウンタ表示位置取得
//******************************************************************************
int MTDashboardLive::_GetCounterPos(
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
	charWidth = tw / strlen(MTDASHBOARDLIVE_COUNTER_CHARS);
	
	//拡大率1.0のキャプションサイズ
	captionWidth = (unsigned long)(charWidth * MTDASHBOARDLIVE_COUNTER_SIZE);
	
	//カウンタ文字列が画面からはみ出す場合は画面に収まるように拡大率を更新する
	//  タイトルがはみ出すのは気にしないことにする
	if (((cw - (MTDASHBOARDLIVE_FRAMESIZE*2)) < captionWidth) && (tw > 0)) {
		newMag = (float)(cw - (MTDASHBOARDLIVE_FRAMESIZE*2)) / (float)captionWidth;
		if (m_CounterMag > newMag) {
			m_CounterMag = newMag;
		}
	}
	
	//テクスチャの表示倍率を考慮して表示位置を算出
	*pX = MTDASHBOARDLIVE_FRAMESIZE;
	*pY = (float)ch - ((float)th * m_CounterMag) - MTDASHBOARDLIVE_FRAMESIZE;

EXIT:;
	return result;
}

//******************************************************************************
// モニタ状態登録
//******************************************************************************
void MTDashboardLive::SetMonitoringStatus(
		bool isMonitoring
	)
{
	m_isMonitoring = isMonitoring;
}

//******************************************************************************
// ノートON登録
//******************************************************************************
void MTDashboardLive::SetNoteOn()
{
	m_NoteCount++;
}

//******************************************************************************
// カウンタ文字列取得
//******************************************************************************
int MTDashboardLive::_GetCounterStr(
		char* pStr,
		unsigned long bufSize
	)
{
	int result = 0;
	int eresult = 0;
	const char* pMonitorStatus = "";
		
	if (m_isMonitoring) {
		pMonitorStatus = "";
	}
	else {
		pMonitorStatus = "[MONITERING OFF]";
	}
	
	eresult = snprintf(
				pStr,
				bufSize,
				"NOTES:%08lu %s",
				m_NoteCount,
				pMonitorStatus
			);
	if (eresult < 0) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTDashboardLive::Reset()
{
	m_isMonitoring = false;
	m_NoteCount = 0;
}

//******************************************************************************
// 設定ファイル読み込み
//******************************************************************************
int MTDashboardLive::_LoadConfFile(
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
// 表示設定
//******************************************************************************
void MTDashboardLive::SetEnable(
		bool isEnable
	)
{
	m_isEnable = isEnable;
}

//******************************************************************************
//MIDI IN デバイス名登録
//******************************************************************************
int MTDashboardLive::SetMIDIINDeviceName(
		NSString* pName
	)
{
	int result = 0;
	NSString* pTitle = nil;
	NSString* pDisplayName = nil;
	OGLDevice dummyDevice;
	
	m_Title.Release();
	
	if (pName == nil) {
		pDisplayName = @"(none)";
	}
	else if ([pName length] == 0) {
		pDisplayName = @"(none)";
	}
	else {
		pDisplayName = pName;
	}
	
	//タイトルキャプション
	pTitle = [NSString stringWithFormat:@"MIDI IN: %@", pDisplayName];
	result = m_Title.Create(
					&dummyDevice,				//デバイス
					MTDASHBOARDLIVE_FONTNAME,	//フォント名称
					MTDASHBOARDLIVE_FONTSIZE,	//フォントサイズ
					pTitle						//キャプション
				);
	if (result != 0) goto EXIT;
	m_Title.SetColor(m_CaptionColor);

EXIT:;
	return result;
}


