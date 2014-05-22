//******************************************************************************
//
// OpenGL Utility / OGLPrimitive
//
// プリミティブ描画クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

// MEMO:
// 頂点バッファとインデックスバッファの操作をラップするクラス。
// インデックスバッファを作成しなければglDrawArrays
// インデックスバッファを作成するとglDrawElements
// を用いて描画する。

#import "OGLTypes.h"
#import "OGLDevice.h"
#import "OGLTransMatrix.h"
#import "OGLTexture.h"


//******************************************************************************
// プリミティブ描画クラス
//******************************************************************************
class OGLPrimitive
{
public:
	
	//コンストラクタ／デストラクタ
	OGLPrimitive(void);
	virtual ~OGLPrimitive(void);
	
	//リソース解放
	void Release();
	
	//初期化
	//  指定可能な頂点データフォーマット
	//    OGLTypes.h で定義されているフォーマット種別を指定する
	//      OGLVERTEX_TYPE_V3N3C
	//      OGLVERTEX_TYPE_V3CT2
	//      OGLVERTEX_TYPE_V3N3CT2
	//  指定可能なプリミティブ種別
	//    GL_POINTS
	//    GL_LINES
	//    GL_LINE_STRIP
	//    GL_TRIANGLES
	//    GL_TRIANGLE_STRIP
	//    GL_TRIANGLE_FAN
	int Initialize(
			unsigned long vertexSize,
			unsigned long vertexFormat,
			GLenum type
		);
	
	//頂点バッファ／インデックスバッファの生成
	int CreateVertexBuffer(OGLDevice* pOGLDevice, unsigned long vertexNum);
	int CreateIndexBuffer(OGLDevice* pOGLDevice, unsigned long indexNum);
	
	//頂点データ／インデックスデータ登録
	//  バッファのロック／アンロック制御は自動的に行われる
	//  本メソッドに指定したデータは利用者側が破棄する
	int SetAllVertex(OGLDevice* pOGLDevice, void* pVertex);
	int SetAllIndex(OGLDevice* pOGLDevice, unsigned long* pIndex);
	
	//マテリアル登録（省略可）
	void SetMaterial(OGLMATERIAL material);
	
	//移動制御
	void Transform(OGLTransMatrix* pTransMatrix);
	
	//描画
	int Draw(
			OGLDevice* pOGLDevice,
			OGLTexture* pTexture = NULL,
			 int drawIndexNum = -1
		);
	
	//頂点バッファ／インデックスバッファのロック制御
	//  バッファの内容を書き換えるにはロックしてバッファのポインタを取得する
	//  バッファの内容を書き終えたらアンロックする
	int LockVertex(void** pPtrVertex, unsigned long offset = 0, unsigned long size = 0);
	int UnlockVertex();
	int LockIndex(unsigned long** pPtrIndex, unsigned long offset = 0, unsigned long size = 0);
	int UnlockIndex();
	
private:
	
	//頂点情報
	unsigned long m_VertexSize;
	unsigned long m_VertexFormat;
	GLenum m_PrimitiveType;
	
	//頂点バッファ情報
	GLuint m_VertexBufferId;
	unsigned long m_VertexNum;
	bool m_IsVertexLocked;
	void* m_pVertexBuffer;
	unsigned long m_VertexBufferLockedOffset;
	unsigned long m_VertexBufferLockedSize;
	
	//インデックスバッファ情報
	GLuint m_IndexBufferId;
	unsigned long m_IndexNum;
	bool m_IsIndexLocked;
	void* m_pIndexBuffer;
	unsigned long m_IndexBufferLockedOffset;
	unsigned long m_IndexBufferLockedSize;
	
	//描画情報
	OGLMATERIAL m_Material;
	OGLTransMatrix m_TransMatrix;
	
	int _GetPrimitiveNum(unsigned long* pNum);
	void _GetDefaultMaterial(OGLMATERIAL* pMaterial);
	
	int _EnableBuffer();
	int _DisableBuffer();
	void _EnableMaterial();
	
private:
	
	//代入とコピーコンストラクタの禁止
	void operator=(const OGLPrimitive&);
	OGLPrimitive(const OGLPrimitive&);

};

