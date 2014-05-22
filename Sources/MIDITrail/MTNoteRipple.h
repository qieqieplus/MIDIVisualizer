//******************************************************************************
//
// MIDITrail / MTNoteRipple
//
// ノート波紋描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTNoteDesign.h"
#import "MTNotePitchBend.h"
#import "MTMachTime.h"


//******************************************************************************
// パラメータ定義
//******************************************************************************
//最大波紋描画数
#define MTNOTERIPPLE_MAX_RIPPLE_NUM  (100)

// TODO: 最大波紋描画数を可変にする
//   事前にシーケンスデータの最大同時発音数を調査しておけば
//   確保するバッファサイズを変更できる
//   現状でもバッファサイズは初期化時点で動的に変更可能である

//******************************************************************************
// ノート波紋描画クラス
//******************************************************************************
class MTNoteRipple
{
public:
	
	//コンストラクタ／デストラクタ
	MTNoteRipple(void);
	virtual ~MTNoteRipple(void);
	
	//生成
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pSceneName,
			SMSeqData* pSeqData,
			MTNotePitchBend* pNotePitchBend
		);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, OGLVECTOR3 camVector, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//ノートOFF登録
	void SetNoteOff(
			unsigned char portNo,
			unsigned char chNo,
			unsigned char noteNo
		);
	
	//ノートON登録
	void SetNoteOn(
			unsigned char portNo,
			unsigned char chNo,
			unsigned char noteNo,
			unsigned char velocity
		);
	
	//演奏チックタイム登録
	void SetCurTickTime(unsigned long curTickTime);
	
	//リセット
	void Reset();
	
	//表示設定
	void SetEnable(bool isEnable);
	
	//スキップ状態
	void SetSkipStatus(bool isSkipping);
	
private:
	
	//ノート発音状態構造体
	struct NoteStatus {
		bool isActive;
		unsigned char portNo;
		unsigned char chNo;
		unsigned char noteNo;
		unsigned char velocity;
		uint64_t regTime;
	};
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3CT2 MTNOTERIPPLE_VERTEX;
	//struct MTNOTERIPPLE_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//	D3DXVECTOR2 t;	//テクスチャ画像位置
	//};
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3CT2; }
	
private:
	
	//描画系
	OGLPrimitive m_Primitive;
	OGLTexture m_Texture;
	OGLMATERIAL m_Material;
	
	//再生時刻
	unsigned long m_CurTickTime;
	MTMachTime m_MachTime;
	
	//カメラ
	OGLVECTOR3 m_CamVector;
	
	//ノートデザイン
	MTNoteDesign m_NoteDesign;
	
	//ピッチベンド情報
	MTNotePitchBend* m_pNotePitchBend;
	
	//ノート発音状態情報
	NoteStatus* m_pNoteStatus;
	unsigned long m_ActiveNoteNum;
	
	//表示可否
	bool m_isEnable;
	
	//スキップ状態
	bool m_isSkipping;
	
	int _CreateTexture(OGLDevice* pOGLDevice, NSString* pSceneName);
	int _CreateNoteStatus();
	int _CreateVertex(OGLDevice* pOGLDevice);
	int _SetVertexPosition(
				MTNOTERIPPLE_VERTEX* pVertex,
				NoteStatus* pNoteStatus,
				unsigned long rippleNo,
				uint64_t curTime,
				bool* pIsTimeout
			);
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	int _TransformRipple(OGLDevice* pOGLDevice);
	int _UpdateVertexOfRipple(OGLDevice* pOGLDevice);
	
};


