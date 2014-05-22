//******************************************************************************
//
// MIDITrail / MTNoteRain
//
// ノートレイン描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTNoteRain.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//1ノートあたりの頂点数 = 1長方形4頂点 * 1面
#define NOTE_VERTEX_NUM  (4 * 1)

//1ノートあたりのインデックス数 = 1三角形3頂点 * 2個 * 1面
#define NOTE_INDEX_NUM   (3 * 2 * 1)

//******************************************************************************
// コンストラクタ
//******************************************************************************
MTNoteRain::MTNoteRain(void)
{
	m_CurTickTime = 0;
	m_CurNoteIndex = 0;
	m_pNoteStatus = NULL;
	m_CurPos = 0.0f;
	m_isSkipping = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTNoteRain::~MTNoteRain(void)
{
	Release();
}

//******************************************************************************
// 生成処理
//******************************************************************************
int MTNoteRain::Create(
		OGLDevice* pOGLDevice,
		NSString* pSceneName,
		SMSeqData* pSeqData,
		MTNotePitchBend* pNotePitchBend
	)
{
	int result = 0;
	SMTrack track;
	
	Release();
	
	if (pSeqData == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ノートデザインオブジェクト初期化
	result = m_NoteDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//キーボードデザインオブジェクト初期化
	result = m_KeyboardDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//トラック取得
	result = pSeqData->GetMergedTrack(&track);
	if (result != 0) goto EXIT;
	
	//ノートリスト取得
	result = track.GetNoteList(&m_NoteList);
	if (result != 0) goto EXIT;
	
	//全ノートレイン生成
	result = _CreateAllNoteRain(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//ノート情報配列生成
	result = _CreateNoteStatus();
	if (result != 0) goto EXIT;
	
	//ピッチベンド情報
	m_pNotePitchBend = pNotePitchBend;
	
	//Mach時間初期化
	result = m_MachTime.Initialize();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 全ノートレイン生成
//******************************************************************************
int MTNoteRain::_CreateAllNoteRain(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	unsigned long vertexNum = 0;
	unsigned long indexNum = 0;
	MTNOTERAIN_VERTEX* pVertex = NULL;
	unsigned long* pIndex = NULL;
	unsigned long i = 0;
	OGLMATERIAL material;
	SMNote note;
	
	//プリミティブ初期化
	result = m_PrimitiveAllNotes.Initialize(
					sizeof(MTNOTERAIN_VERTEX),	//頂点サイズ
					_GetFVFFormat(),			//頂点FVFフォーマット
					GL_TRIANGLES				//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	vertexNum = NOTE_VERTEX_NUM * m_NoteList.GetSize();
	result = m_PrimitiveAllNotes.CreateVertexBuffer(pOGLDevice, vertexNum);
	if (result != 0) goto EXIT;
	
	//インデックスバッファ生成
	indexNum = NOTE_INDEX_NUM * m_NoteList.GetSize();
	result = m_PrimitiveAllNotes.CreateIndexBuffer(pOGLDevice, indexNum);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_PrimitiveAllNotes.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	result = m_PrimitiveAllNotes.LockIndex(&pIndex);
	if (result != 0) goto EXIT;
	
	//バッファに頂点とインデックスを書き込む
	for (i = 0; i < m_NoteList.GetSize(); i++) {
		result = m_NoteList.GetNote(i, &note);
		if (result != 0) goto EXIT;
		
		result = _CreateVertexOfNote(
						note,							//ノート情報
						&(pVertex[NOTE_VERTEX_NUM * i]),//頂点バッファ書き込み位置
						NOTE_VERTEX_NUM * i,			//頂点バッファインデックスオフセット
						&(pIndex[NOTE_INDEX_NUM * i])	//インデックスバッファ書き込み位置
					);
		if (result != 0) goto EXIT;
	}
	
	//バッファのロック解除
	result = m_PrimitiveAllNotes.UnlockVertex();
	if (result != 0) goto EXIT;
	result = m_PrimitiveAllNotes.UnlockIndex();
	if (result != 0) goto EXIT;
	
	//マテリアル作成
	_MakeMaterial(&material);
	m_PrimitiveAllNotes.SetMaterial(material);
	
EXIT:;
	return result;
}

//******************************************************************************
// ノートボックスの頂点生成
//******************************************************************************
int MTNoteRain::_CreateVertexOfNote(
		SMNote note,
		MTNOTERAIN_VERTEX* pVertex,
		unsigned long vertexOffset,
		unsigned long* pIndex
	)
{
	int result = 0;
	OGLVECTOR3 startVector;
	OGLVECTOR3 endVector;
	OGLVECTOR3 moveVector;
	OGLCOLOR color;
	float rainWidth = m_KeyboardDesign.GetBlackKeyWidth();
	
	//ノートON座標
	startVector.x = 0.0f;
	startVector.y = m_NoteDesign.GetPlayPosX(note.startTime);
	startVector.z = 0.0f;
	
	//ノートOFF座標
	endVector.x = 0.0f;
	endVector.y = m_NoteDesign.GetPlayPosX(note.endTime);
	endVector.z = 0.0f;
	
	//移動ベクトル
	moveVector    = m_KeyboardDesign.GetKeyboardBasePos(note.portNo, note.chNo);
	moveVector.x += m_KeyboardDesign.GetKeyCenterPosX(note.noteNo);
	moveVector.y += m_KeyboardDesign.GetWhiteKeyHeight() / 2.0f;
	moveVector.z += m_KeyboardDesign.GetNoteDropPosZ(note.noteNo);
	
	//座標更新
	startVector = startVector + moveVector;
	endVector   = endVector   + moveVector;
	
	//頂点
	pVertex[0].p = OGLVECTOR3(startVector.x - rainWidth/2.0f, startVector.y, startVector.z);
	pVertex[1].p = OGLVECTOR3(startVector.x + rainWidth/2.0f, startVector.y, startVector.z);
	pVertex[2].p = OGLVECTOR3(endVector.x   + rainWidth/2.0f, endVector.y,   endVector.z);
	pVertex[3].p = OGLVECTOR3(endVector.x   - rainWidth/2.0f, endVector.y,   endVector.z);
	
	//法線
	//実際の面の方向に合わせて(0,0,-1)とするとライトを適用したときに暗くなる
	//鍵盤の上面に合わせることで明るくする
	pVertex[0].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
	pVertex[1].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
	pVertex[2].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
	pVertex[3].n = OGLVECTOR3(0.0f, 1.0f, 0.0f);
	
	//色
	color = m_NoteDesign.GetNoteBoxColor(note.portNo, note.chNo, note.noteNo);
	pVertex[0].c = OGLCOLOR(color.r, color.g, color.b, 1.0f);
	pVertex[1].c = OGLCOLOR(color.r, color.g, color.b, 1.0f);
	pVertex[2].c = OGLCOLOR(color.r, color.g, color.b, 0.5f); //ノートOFFに近づくほど半透明にする
	pVertex[3].c = OGLCOLOR(color.r, color.g, color.b, 0.5f); //ノートOFFに近づくほど半透明にする
	
	//インデックス
	pIndex[0] = vertexOffset + 0;
	pIndex[1] = vertexOffset + 2;
	pIndex[2] = vertexOffset + 1;
	pIndex[3] = vertexOffset + 0;
	pIndex[4] = vertexOffset + 3;
	pIndex[5] = vertexOffset + 2;
	
	return result;
}

//******************************************************************************
// ノート情報配列生成
//******************************************************************************
int MTNoteRain::_CreateNoteStatus()
{
	int result = 0;
	unsigned long i = 0;
	
	//ノート情報配列生成
	try {
		m_pNoteStatus = new NoteStatus[MTNOTERAIN_MAX_ACTIVENOTE_NUM];
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//ノート状態リスト初期化
	for (i = 0; i < MTNOTERAIN_MAX_ACTIVENOTE_NUM; i++) {
		m_pNoteStatus[i].isActive = false;
		m_pNoteStatus[i].index = 0;
		m_pNoteStatus[i].startTime = 0;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// マテリアル作成
//******************************************************************************
void MTNoteRain::_MakeMaterial(
		OGLMATERIAL* pMaterial
	)
{
	memset(pMaterial, 0, sizeof(OGLMATERIAL));
	
	//拡散光
	pMaterial->Diffuse.r = 1.0f;
	pMaterial->Diffuse.g = 1.0f;
	pMaterial->Diffuse.b = 1.0f;
	pMaterial->Diffuse.a = 1.0f;
	//環境光：影の色
	pMaterial->Ambient.r = 0.5f;
	pMaterial->Ambient.g = 0.5f;
	pMaterial->Ambient.b = 0.5f;
	pMaterial->Ambient.a = 1.0f;
	//鏡面反射光
	pMaterial->Specular.r = 0.2f;
	pMaterial->Specular.g = 0.2f;
	pMaterial->Specular.b = 0.2f;
	pMaterial->Specular.a = 1.0f;
	//鏡面反射光の鮮明度
	pMaterial->Power = 40.0f;
	//発光色
	pMaterial->Emissive.r = 0.0f;
	pMaterial->Emissive.g = 0.0f;
	pMaterial->Emissive.b = 0.0f;
	pMaterial->Emissive.a = 0.0f;
}

//******************************************************************************
// 移動
//******************************************************************************
int MTNoteRain::Transform(
		OGLDevice* pOGLDevice,
		float rollAngle
	)
{
	int result = 0;
	OGLVECTOR3 moveVector;
	OGLTransMatrix transMatrix;
	
	//現在発音中ノートの頂点生成
	result = _TransformActiveNotes(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//演奏位置
	m_CurPos = m_NoteDesign.GetPlayPosX(m_CurTickTime);
	
	//移動行列
	//  ノートを移動させる場合
	moveVector = OGLVECTOR3(0.0f, -m_CurPos, 0.0f);
	//  ノートを移動させずにカメラとキーボードを移動させる場合
	//moveVector = OGLVECTOR3(0.0f, 0.0f, 0.0f);
	transMatrix.RegistTranslation(moveVector.x, moveVector.y, moveVector.z);
	
	//回転行列
	transMatrix.RegistRotationY(rollAngle);
	
	//左手系(DirectX)=>右手系(OpenGL)の変換
	transMatrix.RegistScale(1.0f, 1.0f, LH2RH(1.0f));
	
	//変換行列設定
	m_PrimitiveAllNotes.Transform(&transMatrix);

EXIT:;
	return result;
}

//******************************************************************************
// 発音中ノートの頂点処理
//******************************************************************************
int MTNoteRain::_TransformActiveNotes(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	
	//スキップ中なら何もしない
	if (m_isSkipping) goto EXIT;
	
	//発音中ノートの状態更新
	result = _UpdateStatusOfActiveNotes(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//発音中ノートの更新
	result = _UpdateActiveNotes(pOGLDevice);
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// 発音中ノートの状態更新
//******************************************************************************
int MTNoteRain::_UpdateStatusOfActiveNotes(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long i = 0;
	uint64_t curTime = 0;
	bool isFound = false;
	SMNote note;
	
	//TODO: 発音ノートの管理をライブラリ化したい
	
	curTime = m_MachTime.GetCurTimeInMsec();
	
	//発音終了ノートの情報を破棄する
	for (i = 0; i < MTNOTERAIN_MAX_ACTIVENOTE_NUM; i++) {
		if (m_pNoteStatus[i].isActive) {
			result = m_NoteList.GetNote(m_pNoteStatus[i].index, &note);
			if (result != 0) goto EXIT;
			
			if (note.endTime < m_CurTickTime) {
				result = _UpdateVertexOfNote(m_pNoteStatus[i].index);
				if (result != 0) goto EXIT;
				m_pNoteStatus[i].isActive = false;
				m_pNoteStatus[i].index = 0;
				m_pNoteStatus[i].startTime = 0;
			}
		}
	}
	
	//前回検索終了位置から発音開始ノートを検索
	while (m_CurNoteIndex < m_NoteList.GetSize()) {
		//ノート情報取得
		result = m_NoteList.GetNote(m_CurNoteIndex, &note);
		if (result != 0) goto EXIT;
		
		//現在チックタイムが発音開始チックタイムにたどりついていなければ検索終了
		if (m_CurTickTime < note.startTime) break;
		
		//発音中ノートを登録
		if ((note.startTime <= m_CurTickTime) && (m_CurTickTime <= note.endTime)) {
			//すでに登録済みなら何もしない
			isFound = false;
			for (i = 0; i < MTNOTERAIN_MAX_ACTIVENOTE_NUM; i++) {
				if ((m_pNoteStatus[i].isActive)
				 && (m_pNoteStatus[i].index == m_CurNoteIndex)) {
					isFound = true;
					break;
				}
			}
			//空いているところに追加する
			if (!isFound) {
				for (i = 0; i < MTNOTERAIN_MAX_ACTIVENOTE_NUM; i++) {
					if (!(m_pNoteStatus[i].isActive)) {
						m_pNoteStatus[i].isActive = true;
						m_pNoteStatus[i].index = m_CurNoteIndex;
						m_pNoteStatus[i].startTime = curTime;
						break;
					}
				}
			}
		}
		m_CurNoteIndex++;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 発音中ノートの更新
//******************************************************************************
int MTNoteRain::_UpdateActiveNotes(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	SMNote note;
	unsigned long i = 0;
	uint64_t curTime = 0;
	unsigned long elapsedTime = 0;
	bool isEnablePichBendShift = true;
	
	curTime = m_MachTime.GetCurTimeInMsec();
	
	//発音中ノートについて頂点を更新
	for (i = 0; i < MTNOTERAIN_MAX_ACTIVENOTE_NUM; i++) {
		if (m_pNoteStatus[i].isActive) {
			//ノート情報取得
			result = m_NoteList.GetNote(m_pNoteStatus[i].index, &note);
			if (result != 0) goto EXIT;
			
			//発音開始からの経過時間
			elapsedTime = (unsigned long)(curTime - m_pNoteStatus[i].startTime);
			
			//発音中ノートの頂点を更新する
			result = _UpdateVertexOfNote(m_pNoteStatus[i].index, isEnablePichBendShift);
			if (result != 0) goto EXIT;
		}
	}
	
EXIT:;
	return result;
}
//******************************************************************************
// 発音中ノートの更新
//******************************************************************************
int MTNoteRain::_UpdateVertexOfNote(
		unsigned long index,
		bool isEnablePitchBendShift
	)
{
	int result = 0;
	unsigned long offset = 0;
	unsigned long size = 0;
	float posX = 0.0f;
	float pitchBendShift = 0.0f;
	float rainWidth = 0.0f;
	short pitchBendValue = 0;
	unsigned char pitchBendSensitivity = SM_DEFAULT_PITCHBEND_SENSITIVITY;
	SMNote note;
	OGLVECTOR3 moveVector;
	MTNOTERAIN_VERTEX* pVertex = NULL;
	
	//ノート情報取得
	result = m_NoteList.GetNote(index, &note);
	if (result != 0) goto EXIT;
	
	//ピッチベンドによるキーボードシフト量
	if (isEnablePitchBendShift) {
		pitchBendValue =       m_pNotePitchBend->GetValue(note.portNo, note.chNo);
		pitchBendSensitivity = m_pNotePitchBend->GetSensitivity(note.portNo, note.chNo);
		pitchBendShift = m_KeyboardDesign.GetPitchBendShift(pitchBendValue, pitchBendSensitivity);
	}
	
	//ノートX座標
	moveVector = m_KeyboardDesign.GetKeyboardBasePos(note.portNo, note.chNo);
	posX = moveVector.x + m_KeyboardDesign.GetKeyCenterPosX(note.noteNo) + pitchBendShift;
	
	//頂点バッファのロック
	offset = NOTE_VERTEX_NUM * sizeof(MTNOTERAIN_VERTEX) * index;
	size   = NOTE_VERTEX_NUM * sizeof(MTNOTERAIN_VERTEX);
	result = m_PrimitiveAllNotes.LockVertex((void**)&pVertex, offset, size);
	if (result != 0) goto EXIT;
	
	//頂点のX座標を更新
	rainWidth = m_KeyboardDesign.GetBlackKeyWidth();
	pVertex[0].p.x = posX - rainWidth/2.0f;
	pVertex[1].p.x = posX + rainWidth/2.0f;
	pVertex[2].p.x = posX + rainWidth/2.0f;
	pVertex[3].p.x = posX - rainWidth/2.0f;
	
	//バッファのロック解除
	result = m_PrimitiveAllNotes.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTNoteRain::Draw(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	GLboolean isEnable = false;
	
	//レンダリングステートをカリングなしにする
	isEnable = glIsEnabled(GL_CULL_FACE);
	glDisable(GL_CULL_FACE);
	
	//全ノートの描画
	result = m_PrimitiveAllNotes.Draw(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//レンダリングステートを戻す
	if (isEnable) {
		glEnable(GL_CULL_FACE);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTNoteRain::Release()
{
	m_PrimitiveAllNotes.Release();
	m_NoteList.Clear();
	
	delete [] m_pNoteStatus;
	m_pNoteStatus = NULL;
}

//******************************************************************************
// カレントチックタイム設定
//******************************************************************************
void MTNoteRain::SetCurTickTime(
		unsigned long curTickTime
	)
{
	m_CurTickTime = curTickTime;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTNoteRain::Reset()
{
	int result = 0;
	unsigned long i = 0;

	m_CurTickTime = 0;
	m_CurNoteIndex = 0;
	m_CurPos = 0.0f;
	
	for (i = 0; i < MTNOTERAIN_MAX_ACTIVENOTE_NUM; i++) {
		
		//発音中ノートの頂点を復元する
		if (m_pNoteStatus[i].isActive) {
			result = _UpdateVertexOfNote(m_pNoteStatus[i].index);
			//if (result != 0) goto EXIT;
		}
		m_pNoteStatus[i].isActive = false;
		m_pNoteStatus[i].index = 0;
		m_pNoteStatus[i].startTime = 0;
	}
	
	return;
}

//******************************************************************************
// 現在位置取得
//******************************************************************************
float MTNoteRain::GetPos()
{
	return m_CurPos;
}

//******************************************************************************
// スキップ状態設定
//******************************************************************************
void MTNoteRain::SetSkipStatus(
		bool isSkipping
	)
{
	m_isSkipping = isSkipping;
}



