//******************************************************************************
//
// MIDITrail / MTPianoKeyboard
//
// ピアノキーボード描画クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// ピアノキーボード(1ch分)の描画を制御するクラス。

#import "OGLUtil.h"
#import "SMIDILib.h"
#import "MTPianoKeyboardDesign.h"
#import "MTNotePitchBend.h"


//******************************************************************************
// ピアノキーボード描画クラス
//******************************************************************************
class MTPianoKeyboard
{
public:
	
	//コンストラクタ／デストラクタ
	MTPianoKeyboard(void);
	virtual ~MTPianoKeyboard(void);
	
	//生成
	int Create(
			OGLDevice* pOGLDevice,
			NSString* pSceneName,
			SMSeqData* pSeqData,
			OGLTexture* pTexture = NULL
		);
	
	//更新
	int Transform(OGLDevice* pOGLDevice, OGLVECTOR3 moveVector, float rollAngle);
	
	//描画
	int Draw(OGLDevice* pOGLDevice);
	
	//解放
	void Release();
	
	//キー状態変更
	int ResetKey(unsigned char noteNo);
	int PushKey(
			unsigned char noteNo,
			float keyDownRate,
			unsigned long elapsedTime,
			OGLCOLOR* pActiveKeyColor = NULL
		);
	
	//共有用テクスチャ取得
	OGLTexture* GetTexture();
	
private:
	
	//頂点バッファ構造体
	typedef OGLVERTEX_V3N3CT2 MTPIANOKEYBOARD_VERTEX;
	//struct MTPIANOKEYBOARD_VERTEX {
	//	OGLVECTOR3 p;	//頂点座標
	//	OGLVECTOR3 n;	//法線
	//	DWORD		c;	//ディフューズ色
	//	OGLVECTOR2 t;	//テクスチャ画像位置
	//};
	
	//バッファ情報
	typedef struct {
		unsigned long vertexPos;
		unsigned long vertexNum;
		unsigned long indexPos;
		unsigned long indexNum;
	} MTBufInfo;
	
private:
	
	//キーボードプリミティブ
	OGLPrimitive m_PrimitiveKeyboard;
	
	//テクスチャ
	OGLTexture* m_pTexture;
	bool m_isTextureOwner;
	
	//キーボードデザイン
	MTPianoKeyboardDesign m_KeyboardDesign;
	
	//バッファ情報
	MTBufInfo m_BufInfo[SM_MAX_NOTE_NUM];
	
	//頂点バッファFVFフォーマット
	unsigned long _GetFVFFormat(){ return OGLVERTEX_TYPE_V3N3CT2; }
	
	int _CreateKeyboard(OGLDevice* pOGLDevice);
	void _CreateBufInfo();
	int _CreateVertexOfKeyboard(OGLDevice* pOGLDevice);
	int _CreateVertexOfKey(unsigned char noteNo);
	int _CreateVertexOfKeyWhite1(
				unsigned char noteNo,
				MTPIANOKEYBOARD_VERTEX* pVertex,
				unsigned long* pIndex,
				OGLCOLOR* pColor = NULL
			);
	int _CreateVertexOfKeyWhite2(
				unsigned char noteNo,
				MTPIANOKEYBOARD_VERTEX* pVertex,
				unsigned long* pIndex,
				OGLCOLOR* pColor = NULL
			);
	int _CreateVertexOfKeyWhite3(
				unsigned char noteNo,
				MTPIANOKEYBOARD_VERTEX* pVertex,
				unsigned long* pIndex,
				OGLCOLOR* pColor = NULL
			);
	int _CreateVertexOfKeyBlack(
				unsigned char noteNo,
				MTPIANOKEYBOARD_VERTEX* pVertex,
				unsigned long* pIndex,
				OGLCOLOR* pColor = NULL
			);
	int _LoadTexture(OGLDevice* pOGLDevice, NSString* pSceneName);
	void _MakeMaterial(OGLMATERIAL* pMaterial);
	
	int _RotateKey(unsigned char noteNo, float angle, OGLCOLOR* pColor = NULL);
	OGLVECTOR3 _RotateYZ(float centerY, float centerZ, OGLVECTOR3 p1, float angle);
	
	int _HideKey(unsigned char noteNo);
	
};


