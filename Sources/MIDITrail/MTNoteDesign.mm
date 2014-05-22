//******************************************************************************
//
// MIDITrail / MTNoteDesign
//
// ノートデザインクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "OGLUtil.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MTNoteDesign.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTNoteDesign::MTNoteDesign(void)
{
	_Clear();
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTNoteDesign::~MTNoteDesign(void)
{
}

//******************************************************************************
// 初期化
//******************************************************************************
int MTNoteDesign::Initialize(
		NSString* pSceneName,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	unsigned long index = 0;
	unsigned long portIndex = 0;
	unsigned char portNo = 0;
	
	//ライブモニタ向け設定
	if (pSeqData == NULL) {
		//分解能
		m_TimeDivision = 48;
		//ポートリスト
		m_PortList.Clear();
		m_PortList.AddPort(0);
	}
	//通常設定
	else {
		//分解能取得
		m_TimeDivision = pSeqData->GetTimeDivision();
		if (m_TimeDivision == 0) {
			result = YN_SET_ERR(@"Invalid data found.", 0, 0);
			goto EXIT;
		}
		//ポートリスト取得
		result = pSeqData->GetPortList(&m_PortList);
		if (result != 0) goto EXIT;
	}
	
	//ポート番号に昇順のインデックスを振る
	//ポート 0番 3番 5番 に出力する場合のインデックスはそれぞれ 0, 1, 2
	for (index = 0; index < 256; index++) {
		m_PortIndex[index] = 0;
	}
	for (index = 0; index < m_PortList.GetSize(); index++) {
		m_PortList.GetPort(index, &portNo);
		m_PortIndex[portNo] = (unsigned char)portIndex;
		portIndex++;
	}
	
	//パラメータ設定ファイル読み込み
	result = _LoadConfFile(pSceneName);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏位置取得
//******************************************************************************
float MTNoteDesign::GetPlayPosX(
		unsigned long curTickTime
	)
{
	return ((float)curTickTime * m_QuarterNoteLength / (float)m_TimeDivision);
}

//******************************************************************************
// ライブモニタ用ノート位置取得
//******************************************************************************
float MTNoteDesign::GetLivePosX(
		unsigned long elapsedTime
	)
{
	return (((float)elapsedTime / 1000.0f) * m_LiveNoteLengthPerSecond);
}

//******************************************************************************
// ノートボックス中心座標取得
//******************************************************************************
OGLVECTOR3 MTNoteDesign::GetNoteBoxCenterPosX(
		unsigned long curTickTime,
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo,
		short pitchBendValue,				//省略可：ピッチベンド
		unsigned char pitchBendSensitivity	//省略可：ピッチベンド感度
	)
{
	OGLVECTOR3 vector;
	float pb = 0.0f;
	
	//ピッチベンドによるY座標の移動量
	if (pitchBendValue < 0) {
		pb = GetNoteStep() * pitchBendSensitivity * ((float)pitchBendValue / 8192.0f);
	}
	else {
		pb = GetNoteStep() * pitchBendSensitivity * ((float)pitchBendValue / 8191.0f);
	}
	
	//演奏位置
	vector.x = GetPlayPosX(curTickTime);
	
	//ノート番号
	vector.y = GetPortOriginY(portNo) + (m_NoteStep * noteNo + pb);
	
	//ポート番号とチャンネル番号
	vector.z = GetPortOriginZ(portNo) + (GetChStep() * chNo);
	
	return vector;
}

//******************************************************************************
// ノートボックス縦サイズ取得
//******************************************************************************
float MTNoteDesign::GetNoteBoxHeight()
{
	return m_NoteBoxHeight;
}

//******************************************************************************
// ノートボックス横サイズ取得
//******************************************************************************
float MTNoteDesign::GetNoteBoxWidht()
{
	return m_NoteBoxWidth;
}

//******************************************************************************
// ノート間隔取得
//******************************************************************************
float MTNoteDesign::GetNoteStep()
{
	return m_NoteStep;
}

//******************************************************************************
// チャンネル間隔取得
//******************************************************************************
float MTNoteDesign::GetChStep()
{
	return m_ChStep;
}

//******************************************************************************
//ライブモニタ表示期間（ミリ秒）
//******************************************************************************
unsigned long MTNoteDesign::GetLiveMonitorDisplayDuration()
{
	return (unsigned long)m_LiveMonitorDisplayDuration;
}

//******************************************************************************
// ノートボックス頂点座標取得
//******************************************************************************
void MTNoteDesign::GetNoteBoxVirtexPos(
		unsigned long curTickTime,
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo,
		OGLVECTOR3* pVector0,	//YZ平面+X軸方向を見て左上
		OGLVECTOR3* pVector1,	//YZ平面+X軸方向を見て右上
		OGLVECTOR3* pVector2,	//YZ平面+X軸方向を見て左下
		OGLVECTOR3* pVector3,	//YZ平面+X軸方向を見て右下
		short pitchBendValue,				//省略可：ピッチベンド
		unsigned char pitchBendSensitivity	//省略可：ピッチベンド感度
	)
{
	OGLVECTOR3 center;
	float bh, bw = 0.0f;
	
	center = GetNoteBoxCenterPosX(curTickTime, portNo, chNo, noteNo, pitchBendValue, pitchBendSensitivity);
	
	bh = GetNoteBoxHeight();
	bw = GetNoteBoxWidht();
	
	*pVector0 = OGLVECTOR3(center.x, center.y+(bh/2.0f), center.z+(bw/2.0f));
	*pVector1 = OGLVECTOR3(center.x, center.y+(bh/2.0f), center.z-(bw/2.0f));
	*pVector2 = OGLVECTOR3(center.x, center.y-(bh/2.0f), center.z+(bw/2.0f));
	*pVector3 = OGLVECTOR3(center.x, center.y-(bh/2.0f), center.z-(bw/2.0f));
}

//******************************************************************************
// ライブモニタ用ノートボックス頂点座標取得
//******************************************************************************
void MTNoteDesign::GetNoteBoxVirtexPosLive(
		unsigned long elapsedTime,
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo,
		OGLVECTOR3* pVector0,	//YZ平面+X軸方向を見て左上
		OGLVECTOR3* pVector1,	//YZ平面+X軸方向を見て右上
		OGLVECTOR3* pVector2,	//YZ平面+X軸方向を見て左下
		OGLVECTOR3* pVector3,	//YZ平面+X軸方向を見て右下
		short pitchBendValue,				//省略可：ピッチベンド
		unsigned char pitchBendSensitivity	//省略可：ピッチベンド感度
	)
{
	OGLVECTOR3 center;
	float bh, bw = 0.0f;
	float x = 0.0f;
	unsigned long tickTimeDummy = 0;
	
	center = GetNoteBoxCenterPosX(tickTimeDummy, portNo, chNo, noteNo, pitchBendValue, pitchBendSensitivity);
	
	x = -(GetLivePosX(elapsedTime));
	
	bh = GetNoteBoxHeight();
	bw = GetNoteBoxWidht();
	
	*pVector0 = OGLVECTOR3(x, center.y+(bh/2.0f), center.z+(bw/2.0f));
	*pVector1 = OGLVECTOR3(x, center.y+(bh/2.0f), center.z-(bw/2.0f));
	*pVector2 = OGLVECTOR3(x, center.y-(bh/2.0f), center.z+(bw/2.0f));
	*pVector3 = OGLVECTOR3(x, center.y-(bh/2.0f), center.z-(bw/2.0f));
}

//******************************************************************************
// グリッドボックス頂点座標取得
//******************************************************************************
void MTNoteDesign::GetGridBoxVirtexPos(
		unsigned long curTickTime,
		unsigned char portNo,
		OGLVECTOR3* pVector0,	//YZ平面+X軸方向を見て左上
		OGLVECTOR3* pVector1,	//YZ平面+X軸方向を見て右上
		OGLVECTOR3* pVector2,	//YZ平面+X軸方向を見て左下
		OGLVECTOR3* pVector3 	//YZ平面+X軸方向を見て右下
	)
{
	float x, bh, bw = 0.0f;
	float gridHeight = 0.0f;
	float gridWidth = 0.0f;
	float oy = 0.0f;
	float oz = 0.0f;
	
	x = GetPlayPosX(curTickTime);
	
	bh = GetNoteBoxHeight();
	bw = GetNoteBoxWidht();
	
	gridHeight = GetNoteStep() * 127;
	gridWidth  = GetChStep() * 15;
	
	oy = GetPortOriginY(portNo);
	oz = GetPortOriginZ(portNo);
	
	*pVector0 = OGLVECTOR3(x, oy+gridHeight+(bh/2.0f), oz+gridWidth+(bw/2.0f));
	*pVector1 = OGLVECTOR3(x, oy+gridHeight+(bh/2.0f), oz          -(bw/2.0f));
	*pVector2 = OGLVECTOR3(x, oy           -(bh/2.0f), oz+gridWidth+(bw/2.0f));
	*pVector3 = OGLVECTOR3(x, oy           -(bh/2.0f), oz          -(bw/2.0f));
}

//******************************************************************************
// グリッドボックス頂点座標取得
//******************************************************************************
void MTNoteDesign::GetGridBoxVirtexPosLive(
		unsigned long elapsedTime,
		unsigned char portNo,
		OGLVECTOR3* pVector0,	//YZ平面+X軸方向を見て左上
		OGLVECTOR3* pVector1,	//YZ平面+X軸方向を見て右上
		OGLVECTOR3* pVector2,	//YZ平面+X軸方向を見て左下
		OGLVECTOR3* pVector3 	//YZ平面+X軸方向を見て右下
	)
{
	float x, bh, bw = 0.0f;
	float gridHeight = 0.0f;
	float gridWidth = 0.0f;
	float oy = 0.0f;
	float oz = 0.0f;
	
	x = -(GetLivePosX(elapsedTime));
	
	bh = GetNoteBoxHeight();
	bw = GetNoteBoxWidht();
	
	gridHeight = GetNoteStep() * 127;
	gridWidth  = GetChStep() * 15;
	
	oy = GetPortOriginY(portNo);
	oz = GetPortOriginZ(portNo);
	
	*pVector0 = OGLVECTOR3(x, oy+gridHeight+(bh/2.0f), oz+gridWidth+(bw/2.0f));
	*pVector1 = OGLVECTOR3(x, oy+gridHeight+(bh/2.0f), oz          -(bw/2.0f));
	*pVector2 = OGLVECTOR3(x, oy           -(bh/2.0f), oz+gridWidth+(bw/2.0f));
	*pVector3 = OGLVECTOR3(x, oy           -(bh/2.0f), oz          -(bw/2.0f));
}

//******************************************************************************
// 再生面頂点座標取得
//******************************************************************************
void MTNoteDesign::GetPlaybackSectionVirtexPos(
		unsigned long curTickTime,
		OGLVECTOR3* pVector0,	//YZ平面+X軸方向を見て左上
		OGLVECTOR3* pVector1,	//YZ平面+X軸方向を見て右上
		OGLVECTOR3* pVector2,	//YZ平面+X軸方向を見て左下
		OGLVECTOR3* pVector3 	//YZ平面+X軸方向を見て右下
	)
{
	OGLVECTOR3 firstPortVecotr[4];
	OGLVECTOR3 finaltPortVecotr[4];
	unsigned char lastPortNo = 0;
	
	m_PortList.GetPort(m_PortList.GetSize()-1, &lastPortNo);
	
	GetGridBoxVirtexPos(
			curTickTime,
			0,
			&(firstPortVecotr[0]),
			&(firstPortVecotr[1]),
			&(firstPortVecotr[2]),
			&(firstPortVecotr[3])
		);
	GetGridBoxVirtexPos(
			curTickTime,
			lastPortNo,
			&(finaltPortVecotr[0]),
			&(finaltPortVecotr[1]),
			&(finaltPortVecotr[2]),
			&(finaltPortVecotr[3])
		);
	
	*pVector0 = finaltPortVecotr[0];
	*pVector1 = firstPortVecotr[1];
	*pVector2 = finaltPortVecotr[2];
	*pVector3 = firstPortVecotr[3];
}

//******************************************************************************
// 波紋縦サイズ取得
//******************************************************************************
float MTNoteDesign::GetRippleHeight(
		unsigned long elapsedTime	//省略可：経過時間（ミリ秒）
	)
{
	float height = 0.0f;
	
	if ((int)elapsedTime <= m_RippleDuration) {
		height = m_RippleHeight * (1.0f - ((float)elapsedTime / m_RippleDuration));
	}
	
	return height;
}

//******************************************************************************
// 波紋横サイズ取得
//******************************************************************************
float MTNoteDesign::GetRippleWidth(
		unsigned long elapsedTime	//省略可：経過時間（ミリ秒）
	)
{
	float width = 0.0f;
	
	if ((int)elapsedTime <= m_RippleDuration) {
		width = m_RippleWidth * (1.0f - ((float)elapsedTime / m_RippleDuration));
	}
	
	return width;
}

//******************************************************************************
// 波紋透明度取得
//******************************************************************************
float MTNoteDesign::GetRippleAlpha(
		unsigned long elapsedTime	//経過時間（ミリ秒）
	)
{
	float alpha = 1.0f;
	
	if ((int)elapsedTime <= m_RippleDuration) {
		alpha = 1.0f - ((float)elapsedTime / m_RippleDuration);
	}
	
	return alpha;
}

//******************************************************************************
// ピクチャボード相対位置取得
//******************************************************************************
float MTNoteDesign::GetPictBoardRelativePos()
{
	return m_PictBoardRelativePos;
}

//******************************************************************************
// ポート原点Y座標取得
//******************************************************************************
float MTNoteDesign::GetPortOriginY(
		unsigned char portNo
	)
{
	//   +y
	//    |
	//    +-- Note#127
	//    |   Note#126
	//    |
	//    |
	// ---0----->+x(time)
	//    |
	//    |
	//    |   Note#1
	//    @-- Note#0  @:OriginY
	//    |
	//   -y
	
	return (0.0f - (GetNoteStep() * 127.0f / 2.0f));
}

//******************************************************************************
// ポート原点Z座標取得
//******************************************************************************
float MTNoteDesign::GetPortOriginZ(
		unsigned char portNo
	)
{
	float portIndex = 0.0f;
	float portWidth = 0.0f;
	
	//                  +y
	//                   |
	//         portC   portB   portA
	//       +-------+-------+-------+Note#127
	//       |       |   |   |       |
	//       |       |   |   |       |
	//       |       |   |   |       |
	// +z<---|-------@---0---@-------@--------->-z
	//       |       |   |   |       |
	//       |       |   |   |       |  @:OriginZ(for portA,B,C)
	//       |       |   |   |       |
	//       +-------+-------+-------+Note#0
	//    Ch. 16    0 16 |  0 16    0
	//                   |
	//                  -y
	
	portIndex = (float)(m_PortIndex[portNo]);
	portWidth = GetChStep() * 16.0f;
	
	return ((portWidth * portIndex) - (portWidth * m_PortList.GetSize() / 2.0f));
}

//******************************************************************************
// 世界座標配置移動ベクトル取得
//******************************************************************************
OGLVECTOR3 MTNoteDesign::GetWorldMoveVector()
{
	OGLVECTOR3 vector;

	vector.x = 0.0f;
	vector.y = - GetPortOriginY(0);
	vector.z = - GetPortOriginZ(0);
	
	return vector;
}

//******************************************************************************
// ノートボックスカラー取得
//******************************************************************************
OGLCOLOR MTNoteDesign::GetNoteBoxColor(
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo
	)
{
	OGLCOLOR color;
	
	if (m_NoteColorType == Channel) {
		//チャンネル番号によって色を変える
		//ポート番号とノート番号による色の変化は未サポート
		
		if (chNo >= 16) {
			//データ異常だが無視する
			color = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f); //RGBA
		}
		else {
			color = m_NoteColor[chNo];
		}
	}
	else if (m_NoteColorType == Scale) {
		//音階によって色を変える
		color = m_NoteColorOfScale[(noteNo % 12)];
	}

	
	return color;
}

//******************************************************************************
// 発音中ノートボックスカラー取得
//******************************************************************************
OGLCOLOR MTNoteDesign::GetActiveNoteBoxColor(
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo,
		unsigned long elapsedTime
	)
{
	OGLCOLOR color;
	float r,g,b,a = 0.0f;
	float rate = 0.0f;
	
	color = GetNoteBoxColor(portNo, chNo, noteNo);
	
	//m_ActiveNoteDuration リリースタイム
	//  発音開始時点からノート色を元に戻すまでの時間
	//  ただし m_ActiveNoteEmissive によってリリース後もノートOFFまで発光する
	
	//m_ActiveNoteWhiteRate 最大白色率
	//  0.0 → ノート色変化なし
	//  0.5 → ノート色と白の中間色
	//  1.0 → 白
	
	rate = 0.0f;
	if ((int)elapsedTime < m_ActiveNoteDuration) {
		rate = 1.0f - ((float)elapsedTime / (float)m_ActiveNoteDuration);
	}
	r = color.r + ((1.0f - color.r) * rate * m_ActiveNoteWhiteRate);
	g = color.g + ((1.0f - color.g) * rate * m_ActiveNoteWhiteRate);
	b = color.b + ((1.0f - color.b) * rate * m_ActiveNoteWhiteRate);
	a = color.a;
	color = OGLCOLOR(r, g, b, a);
	
	return color;
}

//******************************************************************************
// 発音中ノートボックスエミッシブ取得（マテリアル用）
//******************************************************************************
OGLCOLOR MTNoteDesign::GetActiveNoteEmissive()
{
	return m_ActiveNoteEmissive;
}

//******************************************************************************
// グリッドラインカラー取得
//******************************************************************************
OGLCOLOR MTNoteDesign::GetGridLineColor()
{
	return m_GridLineColor;
}

//******************************************************************************
// 再生面カラー取得
//******************************************************************************
OGLCOLOR MTNoteDesign::GetPlaybackSectionColor()
{
	return m_PlaybackSectionColor;
}

//******************************************************************************
// クリア
//******************************************************************************
void MTNoteDesign::_Clear(void)
{
	unsigned long i = 0;
	
	m_TimeDivision = 0;
	m_QuarterNoteLength = 0.0f;
	m_NoteBoxHeight = 0.0f;
	m_NoteBoxWidth = 0.0f;
	m_NoteStep = 0.0f;
	m_ChStep = 0.0f;
	m_RippleHeight = 0.0f;
	m_RippleWidth = 0.0f;
	m_PictBoardRelativePos = 0.0f;
	m_PortList.Clear();
	
	for (i = 0; i < 256; i++) {
		m_PortIndex[i] = 0;
	}
	
	m_NoteColorType = Channel;
	for (i = 0; i < 16; i++) {
		m_NoteColor[i] = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f); //RGBA
	}
	for (i = 0; i < 12; i++) {
		m_NoteColorOfScale[i] = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f); //RGBA
	}
	m_ActiveNoteEmissive   = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f); //RGBA
	m_GridLineColor        = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f); //RGBA
	m_PlaybackSectionColor = OGLCOLOR(1.0f, 1.0f, 1.0f, 1.0f); //RGBA
	
	m_ActiveNoteDuration = 400;
	m_ActiveNoteWhiteRate = 1.0f;
	m_RippleDuration = 1600;
}

//******************************************************************************
// 設定ファイル読み込み
//******************************************************************************
int MTNoteDesign::_LoadConfFile(
		NSString* pSceneName
	)
{
	int result = 0;
	NSString* pKey = nil;
	NSString* pHexColor = nil;
	NSString* pNoteColorType = nil;
	unsigned long i = 0;
	MTConfFile confFile;
	
	result = confFile.Initialize(pSceneName);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	//スケール情報
	//----------------------------------
	result = confFile.SetCurSection(@"Scale");
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"QuarterNoteLength", &m_QuarterNoteLength, 1.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"NoteBoxHeight", &m_NoteBoxHeight, 0.1f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"NoteBoxWidth", &m_NoteBoxWidth, 0.1f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"NoteStep", &m_NoteStep, 0.1f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"ChStep", &m_ChStep, 0.5f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"RippleHeight", &m_RippleHeight, 1.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"RippleWidth", &m_RippleWidth, 1.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"PictBoardRelativePos", &m_PictBoardRelativePos, 1.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetFloat(@"LiveNoteLengthPerSecond", &m_LiveNoteLengthPerSecond, 2.0f);
	if (result != 0) goto EXIT;
	result = confFile.GetInt(@"LiveMonitorDisplayDuration", &m_LiveMonitorDisplayDuration, 30000);
	if (result != 0) goto EXIT;
	
	//----------------------------------
	//色情報
	//----------------------------------
	result = confFile.SetCurSection(@"Color");
	if (result != 0) goto EXIT;
	
	//ノートカラー種別を取得
	result = confFile.GetStr(@"NoteColorType", &pNoteColorType, @"CHANNEL");
	if (result != 0) goto EXIT;
	
	//ノートカラー種別を決定
	m_NoteColorType = Channel;
	if ([pNoteColorType isEqualToString:@"SCALE"]) {
		m_NoteColorType = Scale;
	}
	
	//ノート色情報を取得
	for (i = 0; i < 16; i++) {
		pKey = [NSString stringWithFormat:@"Ch-%02ld-NoteRGBA", i+1];
		result = confFile.GetStr(pKey, &pHexColor, @"FFFFFFFF");
		if (result != 0) goto EXIT;
		
		m_NoteColor[i] = OGLColorUtil::MakeColorFromHexRGBA(pHexColor);
	}
	
	//音階用ノート色情報を取得
	for (i = 0; i < 12; i++) {
		pKey = [NSString stringWithFormat:@"Scale-%02ld-NoteRGBA", i+1];
		result = confFile.GetStr(pKey, &pHexColor, @"FFFFFFFF");
		if (result != 0) goto EXIT;
		
		m_NoteColorOfScale[i] = OGLColorUtil::MakeColorFromHexRGBA(pHexColor);
	}
	
	//グリッドライン色情報を取得
	result = confFile.GetStr(@"GridLineRGBA", &pHexColor, @"444444FF");
	if (result != 0) goto EXIT;
	m_GridLineColor = OGLColorUtil::MakeColorFromHexRGBA(pHexColor);
	
	//再生面色情報を取得
	result = confFile.GetStr(@"PlaybackSectionRGBA", &pHexColor, @"AAAAFFFF");
	if (result != 0) goto EXIT;
	m_PlaybackSectionColor = OGLColorUtil::MakeColorFromHexRGBA(pHexColor);
	
	//----------------------------------
	//発音ノート情報
	//----------------------------------
	result = confFile.SetCurSection(@"ActiveNote");
	if (result != 0) goto EXIT;
	
	//発音中ノート色情報：継続時間(msec)
	result = confFile.GetInt(@"Duration", &m_ActiveNoteDuration, 400);
	if (result != 0) goto EXIT;
	
	//発音中ノート色情報：白色率
	result = confFile.GetFloat(@"WhiteRate", &m_ActiveNoteWhiteRate, 0.9f);
	if (result != 0) goto EXIT;
	
	//発音中ノート色情報：マテリアル発光色
	result = confFile.GetStr(@"EmissiveRGBA", &pHexColor, @"1A1A1A1A");
	if (result != 0) goto EXIT;
	m_ActiveNoteEmissive = OGLColorUtil::MakeColorFromHexRGBA(pHexColor);
	
	//----------------------------------
	//波紋情報
	//----------------------------------
	result = confFile.SetCurSection(@"Ripple");
	if (result != 0) goto EXIT;
	
	//波紋継続時間(msec)
	result = confFile.GetInt(@"Duration", &m_RippleDuration, 1600);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}


