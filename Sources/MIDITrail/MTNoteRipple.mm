//******************************************************************************
//
// MIDITrail / MTNoteRipple
//
// ノート波紋描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// Windows版のソースを移植しているため、座標は左手系(DirectX)で処理している。
// 左手系(DirectX)=>右手系(OpenGL)への変換は LH2RH マクロで実現する。

#import "YNBaseLib.h"
#import "MTParam.h"
#import "MTConfFile.h"
#import "MTNoteRipple.h"
#import <new>


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTNoteRipple::MTNoteRipple(void)
{
	m_pNoteStatus = NULL;
	m_CurTickTime = 0;
	m_ActiveNoteNum = 0;
	m_CamVector = OGLVECTOR3(0.0f, 0.0f, 0.0f);
	memset(&m_Material, 0, sizeof(OGLMATERIAL));
	m_isEnable = true;
	m_isSkipping = false;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTNoteRipple::~MTNoteRipple(void)
{
	Release();
}

//******************************************************************************
// ノート波紋生成
//******************************************************************************
int MTNoteRipple::Create(
		OGLDevice* pOGLDevice,
		NSString* pSceneName,
		SMSeqData* pSeqData,
		MTNotePitchBend* pNotePitchBend
   )
{
	int result = 0;
	
	Release();
	
	//ノートデザインオブジェクト初期化
	result = m_NoteDesign.Initialize(pSceneName, pSeqData);
	if (result != 0) goto EXIT;
	
	//テクスチャ生成
	result = _CreateTexture(pOGLDevice, pSceneName);
	if (result != 0) goto EXIT;
	
	//ノート情報配列生成
	result = _CreateNoteStatus();
	if (result != 0) goto EXIT;
	
	//頂点生成
	result = _CreateVertex(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//マテリアル作成
	_MakeMaterial(&m_Material);
	
	//ピッチベンド情報
	m_pNotePitchBend = pNotePitchBend;
	
	//Mach時間初期化
	result = m_MachTime.Initialize();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 移動
//******************************************************************************
int MTNoteRipple::Transform(
		OGLDevice* pOGLDevice,
		OGLVECTOR3 camVector,
		float rollAngle
	)
{
	int result = 0;
	OGLVECTOR3 moveVector;
	OGLTransMatrix transMatrix;
	
	m_CamVector = camVector;
	
	//波紋の頂点更新
	result = _TransformRipple(pOGLDevice);
	if (result != 0) goto EXIT;
	
	//回転
	transMatrix.RegistRotationX(rollAngle);
	
	//移動
	moveVector = m_NoteDesign.GetWorldMoveVector();
	transMatrix.RegistTranslation(moveVector.x, moveVector.y, moveVector.z);
	
	//左手系(DirectX)=>右手系(OpenGL)の変換
	transMatrix.RegistScale(1.0f, 1.0f, LH2RH(1.0f));
	
	//変換行列設定
	m_Primitive.Transform(&transMatrix);
	
EXIT:;
	return result;
}

//******************************************************************************
// 波紋の頂点更新
//******************************************************************************
int MTNoteRipple::_TransformRipple(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	
	//スキップ中なら何もしない
	if (m_isSkipping) goto EXIT;
	
	//波紋の頂点更新
	result = _UpdateVertexOfRipple(pOGLDevice);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 波紋の頂点更新
//******************************************************************************
int MTNoteRipple::_UpdateVertexOfRipple(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	MTNOTERIPPLE_VERTEX* pVertex = NULL;
	unsigned long i = 0;
	unsigned long activeNoteNum = 0;
	uint64_t curTime = 0;
	bool isTimeout = false;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	curTime = m_MachTime.GetCurTimeInMsec();
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	//発音中ノートの波紋について頂点を更新
	for (i = 0; i < MTNOTERIPPLE_MAX_RIPPLE_NUM; i++) {
		if (m_pNoteStatus[i].isActive) {
			//頂点更新：波紋の描画位置とサイズを変える
			_SetVertexPosition(
					&(pVertex[activeNoteNum*6]),
					&(m_pNoteStatus[i]),
					activeNoteNum,
					curTime,
					&isTimeout
				);
			if (isTimeout) {
				//時間切れ消滅
				m_pNoteStatus[i].isActive = false;
			}
			else {
			 	activeNoteNum++;
		 	}
		}
	}
	m_ActiveNoteNum = activeNoteNum;
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 描画
//******************************************************************************
int MTNoteRipple::Draw(
		OGLDevice* pOGLDevice
   )
{
	int result = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	if (!m_isEnable) goto EXIT;
	
	//テクスチャステージ設定
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	//  カラー演算：乗算  引数1：テクスチャ  引数2：ポリゴン
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_PRIMARY_COLOR);
	// アルファ演算：乗算  引数1：テクスチャ  引数1：ポリゴン
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_PRIMARY_COLOR);
	
	//テクスチャフィルタ
	//OGLTexture::BindTexture()で対応
	
	//プリミティブ描画
	//  本来アクティブノートがゼロならAPIを呼び出す必要はない。
	//  しかし初回ノートON発生時の波紋描画で初めてAPIを呼び出すと、
	//  テクスチャが正しく描画されずに四角のポリゴンが一瞬だけ表示されてしまう。
	//  根本原因は不明だが、常にAPIを呼び出すことで回避する。
	//if (m_ActiveNoteNum > 0) {
		//バッファ全体でなく波紋の数に合わせて描画するプリミティブを減らす
		result = m_Primitive.Draw(
						pOGLDevice,			//デバイス
						&m_Texture,			//テクスチャ
						6 * m_ActiveNoteNum	//インデックス数
					);
		if (result != 0) goto EXIT;
	//}
	
EXIT:;
	return result;
}

//******************************************************************************
// 解放
//******************************************************************************
void MTNoteRipple::Release()
{
	m_Primitive.Release();
	m_Texture.Release();
	
	delete [] m_pNoteStatus;
	m_pNoteStatus = NULL;
}

//******************************************************************************
// テクスチャ生成
//******************************************************************************
int MTNoteRipple::_CreateTexture(
		OGLDevice* pOGLDevice,
		NSString* pSceneName
	)
{
	int result = 0;
	NSString* pImgFilePath = nil;
	NSString* pBmpFileName = nil;
	MTConfFile confFile;
	
	result = confFile.Initialize(pSceneName);
	if (result != 0) goto EXIT;
	
	//ビットマップファイル名
	result = confFile.SetCurSection(@"Bitmap");
	if (result != 0) goto EXIT;
	result = confFile.GetStr(@"Ripple", &pBmpFileName, MT_IMGFILE_RIPPLE);
	if (result != 0) goto EXIT;
	
	//画像ファイルパス
	pImgFilePath = [NSString stringWithFormat:@"%@/%@",
									[YNPathUtil resourceDirPath], pBmpFileName];
	
	//画像ファイル読み込み
	result = m_Texture.LoadImageFile(pImgFilePath);
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// ノート情報配列生成
//******************************************************************************
int MTNoteRipple::_CreateNoteStatus()
{
	int result = 0;
	unsigned long i = 0;
	
	//頂点生成
	try {
		m_pNoteStatus = new NoteStatus[MTNOTERIPPLE_MAX_RIPPLE_NUM];
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	memset(m_pNoteStatus, 0, sizeof(NoteStatus) * MTNOTERIPPLE_MAX_RIPPLE_NUM);
	
	for (i = 0; i < MTNOTERIPPLE_MAX_RIPPLE_NUM; i++) {
		m_pNoteStatus[i].isActive = false;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点生成
//******************************************************************************
int MTNoteRipple::_CreateVertex(
		OGLDevice* pOGLDevice
	)
{
	int result = 0;
	unsigned long vertexNum = 0;
	MTNOTERIPPLE_VERTEX* pVertex = NULL;
	
	//プリミティブ初期化
	result = m_Primitive.Initialize(
					sizeof(MTNOTERIPPLE_VERTEX),//頂点サイズ
					_GetFVFFormat(),			//頂点FVFフォーマット
					GL_TRIANGLES				//プリミティブ種別
				);
	if (result != 0) goto EXIT;
	
	//頂点バッファ生成
	vertexNum = 6 * MTNOTERIPPLE_MAX_RIPPLE_NUM;
	result = m_Primitive.CreateVertexBuffer(pOGLDevice, vertexNum);
	if (result != 0) goto EXIT;
	
	//バッファのロック
	result = m_Primitive.LockVertex((void**)&pVertex);
	if (result != 0) goto EXIT;
	
	memset(pVertex, 0, sizeof(MTNOTERIPPLE_VERTEX) * 6 * MTNOTERIPPLE_MAX_RIPPLE_NUM);
	
	//バッファのロック解除
	result = m_Primitive.UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点の座標設定
//******************************************************************************
int MTNoteRipple::_SetVertexPosition(
		MTNOTERIPPLE_VERTEX* pVertex,
		NoteStatus* pNoteStatus,
		unsigned long rippleNo,
		uint64_t curTime,
		bool* pIsTimeout
	)
{
	int result = 0;
	unsigned long i = 0;
	float rh, rw = 0.0f;
	float alpha = 0.0f;
	OGLVECTOR3 center;
	OGLCOLOR color;
	unsigned long elapsedTime = 0;
	short pbValue = 0;
	unsigned char pbSensitivity = SM_DEFAULT_PITCHBEND_SENSITIVITY;
	
	*pIsTimeout = false;
	
	pbValue =       m_pNotePitchBend->GetValue(pNoteStatus->portNo, pNoteStatus->chNo);
	pbSensitivity = m_pNotePitchBend->GetSensitivity(pNoteStatus->portNo, pNoteStatus->chNo);
	
	//ノートボックス中心座標取得
	center = m_NoteDesign.GetNoteBoxCenterPosX(
					m_CurTickTime,
					pNoteStatus->portNo,
					pNoteStatus->chNo,
					pNoteStatus->noteNo,
					pbValue,
					pbSensitivity
				);
	
	//発音開始からの経過時間
	elapsedTime = (unsigned long)(curTime - pNoteStatus->regTime);
	
	//波紋サイズ
	rh = m_NoteDesign.GetRippleHeight(elapsedTime);
	rw = m_NoteDesign.GetRippleWidth(elapsedTime);
	
	//描画終了確認
	if ((rh <= 0.0f) || (rw <= 0.0f)) {
		*pIsTimeout = true;
	}
	
	//波紋を再生平面上からカメラ側に少しだけ浮かせて描画する
	//また波紋同士が同一平面上で重ならないように描画する
	//  Zファイティングによって発生するちらつきやかすれを回避する
	//  グラフィックカードによって現象が異なる
	if (center.x < m_CamVector.x) {
		center.x += (+(float)(rippleNo + 1) * 0.002f);
	}
	else {
		center.x += (-(float)(rippleNo + 1) * 0.002f);
	}
	
	//頂点座標
	pVertex[0].p = OGLVECTOR3(center.x, center.y+(rh/2.0f), center.z+(rw/2.0f));
	pVertex[1].p = OGLVECTOR3(center.x, center.y+(rh/2.0f), center.z-(rw/2.0f));
	pVertex[2].p = OGLVECTOR3(center.x, center.y-(rh/2.0f), center.z+(rw/2.0f));
	pVertex[3].p = pVertex[2].p;
	pVertex[4].p = pVertex[1].p;
	pVertex[5].p = OGLVECTOR3(center.x, center.y-(rh/2.0f), center.z-(rw/2.0f));
	
	//法線
	for (i = 0; i < 6; i++) {
		pVertex[i].n = OGLVECTOR3(-1.0f, 0.0f, 0.0f);
	}
	
	//透明度を徐々に落とす
	alpha = m_NoteDesign.GetRippleAlpha(elapsedTime);
	
	//各頂点のディフューズ色
	for (i = 0; i < 6; i++) {
		color = m_NoteDesign.GetNoteBoxColor(
								pNoteStatus->portNo,
								pNoteStatus->chNo,
								pNoteStatus->noteNo
							);
		pVertex[i].c = OGLCOLOR(color.r, color.g, color.b, alpha);
	}
	
	//テクスチャ座標
	pVertex[0].t = OGLVECTOR2(0.0f, 0.0f);
	pVertex[1].t = OGLVECTOR2(1.0f, 0.0f);
	pVertex[2].t = OGLVECTOR2(0.0f, 1.0f);
	pVertex[3].t = pVertex[2].t;
	pVertex[4].t = pVertex[1].t;
	pVertex[5].t = OGLVECTOR2(1.0f, 1.0f);
	
	return result;
}

//******************************************************************************
// マテリアル作成
//******************************************************************************
void MTNoteRipple::_MakeMaterial(
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
	pMaterial->Power = 10.0f;
	//発光色
	pMaterial->Emissive.r = 0.0f;
	pMaterial->Emissive.g = 0.0f;
	pMaterial->Emissive.b = 0.0f;
	pMaterial->Emissive.a = 0.0f;
}

//******************************************************************************
// ノートOFF登録
//******************************************************************************
void MTNoteRipple::SetNoteOff(
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo
	)
{
	unsigned long i = 0;
	
	//該当のノート情報を無効化
	for (i = 0; i < MTNOTERIPPLE_MAX_RIPPLE_NUM; i++) {
		if ((m_pNoteStatus[i].isActive)
		 && (m_pNoteStatus[i].portNo == portNo)
		 && (m_pNoteStatus[i].chNo == chNo)
		 && (m_pNoteStatus[i].noteNo == noteNo)) {
			m_pNoteStatus[i].isActive = false;
			break;
		}
	}
	
	return;
}

//******************************************************************************
// ノートON登録
//******************************************************************************
void MTNoteRipple::SetNoteOn(
		unsigned char portNo,
		unsigned char chNo,
		unsigned char noteNo,
		unsigned char velocity
	)
{
	unsigned long i = 0;
	
	//空きスペースにノート情報を登録
	//空きが見つからなければ波紋の表示はあきらめる
	for (i = 0; i < MTNOTERIPPLE_MAX_RIPPLE_NUM; i++) {
		if (!(m_pNoteStatus[i].isActive)) {
			m_pNoteStatus[i].isActive = true;
		 	m_pNoteStatus[i].portNo = portNo;
		 	m_pNoteStatus[i].chNo = chNo;
		 	m_pNoteStatus[i].noteNo = noteNo;
		 	m_pNoteStatus[i].velocity = velocity;
		 	m_pNoteStatus[i].regTime = m_MachTime.GetCurTimeInMsec();
			break;
		}
	}
	
	return;
}

//******************************************************************************
// カレントチックタイム設定
//******************************************************************************
void MTNoteRipple::SetCurTickTime(
		unsigned long curTickTime
	)
{
	m_CurTickTime = curTickTime;
}

//******************************************************************************
// リセット
//******************************************************************************
void MTNoteRipple::Reset()
{
	unsigned long i = 0;
	
	m_CurTickTime = 0;
	m_ActiveNoteNum = 0;
	
	for (i = 0; i < MTNOTERIPPLE_MAX_RIPPLE_NUM; i++) {
		m_pNoteStatus[i].isActive = false;
	}

	return;
}

//******************************************************************************
// 表示設定
//******************************************************************************
void MTNoteRipple::SetEnable(
		bool isEnable
	)
{
	m_isEnable = isEnable;
}

//******************************************************************************
// スキップ状態設定
//******************************************************************************
void MTNoteRipple::SetSkipStatus(
		bool isSkipping
	)
{
	m_isSkipping = isSkipping;
}

