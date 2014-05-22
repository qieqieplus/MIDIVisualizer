//******************************************************************************
//
// OpenGL Utility / OGLPrimitive
//
// プリミティブ描画クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "OGLPrimitive.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
OGLPrimitive::OGLPrimitive(void)
{
	//頂点情報
	m_VertexSize = 0;
	m_VertexFormat = 0;
	m_PrimitiveType = GL_POINTS;;
	
	//頂点バッファ情報
	m_VertexBufferId = 0;
	m_VertexNum = 0;
	m_IsVertexLocked = false;
	m_pVertexBuffer = NULL;
	m_VertexBufferLockedOffset = 0;
	m_VertexBufferLockedSize = 0;
	
	//インデックスバッファ情報
	m_IndexBufferId = 0;
	m_IndexNum = 0;
	m_IsIndexLocked = false;
	m_pIndexBuffer = NULL;
	m_IndexBufferLockedOffset = 0;
	m_IndexBufferLockedSize = 0;
	
	memset(&m_Material, 0, sizeof(OGLMATERIAL));
}

//******************************************************************************
// デストラクタ
//******************************************************************************
OGLPrimitive::~OGLPrimitive(void)
{
	Release();
}

//******************************************************************************
// 解放
//******************************************************************************
void OGLPrimitive::Release()
{
	//頂点情報
	m_VertexSize = 0;
	m_VertexFormat = 0;
	m_PrimitiveType = GL_POINTS;
	
	//頂点バッファ情報
	if (m_pVertexBuffer != NULL) {
		glDeleteBuffers(1, &m_VertexBufferId);
		m_VertexBufferId = 0;
		free(m_pVertexBuffer);
		m_pVertexBuffer = NULL;
	}
	m_VertexNum = 0;
	m_IsVertexLocked = false;
	m_VertexBufferLockedOffset = 0;
	m_VertexBufferLockedSize = 0;
	
	//インデックスバッファ情報
	if (m_pIndexBuffer != NULL) {
		glDeleteBuffers(1, &m_IndexBufferId);
		m_IndexBufferId = 0;
		free(m_pIndexBuffer);
		m_pIndexBuffer = NULL;
	}
	m_IndexNum = 0;
	m_IsIndexLocked = false;
	m_IndexBufferLockedOffset = 0;
	m_IndexBufferLockedSize = 0;
}

//******************************************************************************
// 初期化
//******************************************************************************
int OGLPrimitive::Initialize(
		unsigned long vertexSize,
		unsigned long vertexFormat,
		GLenum type
	)
{
	int result = 0;
	
	Release();
	
	m_VertexSize = vertexSize;
	m_VertexFormat = vertexFormat;
	m_PrimitiveType = type;
	m_TransMatrix.Clear();
	
	_GetDefaultMaterial(&m_Material);
	
	return result;
}

//******************************************************************************
// 頂点バッファ生成
//******************************************************************************
int OGLPrimitive::CreateVertexBuffer(
		OGLDevice* pOGLDevice,
		unsigned long vertexNum
	)
{
	int result = 0;
	GLenum glresult = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	if (m_pVertexBuffer != NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//頂点バッファオブジェクトを生成
	//  バッファオブジェクト数／バッファオブジェクト配列格納位置
	glGenBuffers(1, &m_VertexBufferId);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	
	//頂点バッファ生成
	glBindBuffer(GL_ARRAY_BUFFER_ARB, m_VertexBufferId);
	glBufferData(
			GL_ARRAY_BUFFER_ARB,		//ターゲット：頂点バッファ
			m_VertexSize * vertexNum,	//バッファサイズ
			NULL,						//格納する頂点データの位置
			GL_DYNAMIC_DRAW				//使用方式：データ更新あり
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, m_VertexSize * vertexNum);
		goto EXIT;
	}
	glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
	
	//リソース配置場所としてメモリを確保
	//  DirectX9のCreateVertexBuffer/D3DPOOL_MANAGEDと動作を合わせる
	m_pVertexBuffer = malloc(m_VertexSize * vertexNum);
	if (m_pVertexBuffer == NULL) {
		result = YN_SET_ERR(@"Could not allocate memory.", m_VertexSize * vertexNum, 0);
		glDeleteBuffers(1, &m_VertexBufferId);
		m_VertexBufferId = 0;
		goto EXIT;
	}
	
	m_VertexNum = vertexNum;

EXIT:;
	return result;
}

//******************************************************************************
// インデックスバッファ生成
//******************************************************************************
int OGLPrimitive::CreateIndexBuffer(
		OGLDevice* pOGLDevice,
		unsigned long indexNum
	)
{
	int result = 0;
	GLenum glresult = 0;
	
	if (pOGLDevice == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	if (m_pIndexBuffer != NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//インデックスバッファオブジェクトを生成
	//  バッファオブジェクト数／インデックスオブジェクト配列格納位置
	glGenBuffers(1, &m_IndexBufferId);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	
	//頂点バッファ生成
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, m_IndexBufferId);
	glBufferData(
			GL_ELEMENT_ARRAY_BUFFER_ARB,//ターゲット：インデックスバッファ
			sizeof(GLuint) * indexNum,	//バッファサイズ
			NULL,						//格納する頂点データの位置
			GL_DYNAMIC_DRAW				//使用方式：データ更新あり
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, sizeof(GLuint) * indexNum);
		goto EXIT;
	}
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
	
	//リソース配置場所としてメモリを確保
	//  DirectX9のCreateVertexBuffer/D3DPOOL_MANAGEDと動作を合わせる
	m_pIndexBuffer = malloc(sizeof(GLuint) * indexNum);
	if (m_pIndexBuffer == NULL) {
		result = YN_SET_ERR(@"Could not allocate memory.", sizeof(GLuint) * indexNum, 0);
		glDeleteBuffers(1, &m_IndexBufferId);
		m_IndexBufferId = 0;
		goto EXIT;
	}
	
	m_IndexNum = indexNum;
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点登録
//******************************************************************************
int OGLPrimitive::SetAllVertex(
		OGLDevice* pOGLDevice,
		void* pVertex
	)
{
	int result = 0;
	void* pBuf = NULL;
	
	//頂点バッファのロック
	result = LockVertex(&pBuf);
	if (result != 0) goto EXIT;
	
	//バッファに頂点データを書き込む
	try {
		memcpy(pBuf, pVertex, (m_VertexSize * m_VertexNum));
	}
	catch (...) {
		result = YN_SET_ERR(@"Memory access error.", (unsigned long)pVertex, m_VertexNum);
		goto EXIT;
	}
	
	//頂点バッファのアンロック
	//  実際はこのタイミングでGPUのメモリに転送する
	result = UnlockVertex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// インデックス登録
//******************************************************************************
int OGLPrimitive::SetAllIndex(
		OGLDevice* pOGLDevice,
		unsigned long* pIndex
	)
{
	int result = 0;
	unsigned long* pBuf = NULL;
	
	//頂点バッファのロック
	result = LockIndex(&pBuf);
	if (result != 0) goto EXIT;
	
	//バッファに頂点データを書き込む
	try {
		memcpy(pBuf, pIndex, (sizeof(unsigned long)* m_IndexNum));
	}
	catch (...) {
		result = YN_SET_ERR(@"Memory access error.", (unsigned long)pIndex, m_IndexNum);
		goto EXIT;
	}
	
	//インデックスバッファのアンロック
	//  実際はこのタイミングでGPUのメモリに転送する
	result = UnlockIndex();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// マテリアル設定
//******************************************************************************
void OGLPrimitive::SetMaterial(
		OGLMATERIAL material
	)
{
	m_Material = material;
}

//******************************************************************************
// 移動
//******************************************************************************
void OGLPrimitive::Transform(
		OGLTransMatrix* pTransMatrix
	)
{
	m_TransMatrix.CopyFrom(pTransMatrix);
}

//******************************************************************************
// 描画
//******************************************************************************
int OGLPrimitive::Draw(
		OGLDevice* pOGLDevice,
		OGLTexture* pTexture,
		int drawIndexNum
	)
{
	int result = 0;
	GLenum glresult = 0;
	unsigned long indexNum = 0;
	unsigned long indexNumMax = 0;
	
	if (m_IsVertexLocked || m_IsIndexLocked) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//頂点が存在しなければ何もしない
	if (m_pVertexBuffer == NULL) goto EXIT;
	
	//バッファ有効化
	result = _EnableBuffer();
	if (result != 0) goto EXIT;
	
	//マテリアル設定
	_EnableMaterial();
	
	//テクスチャ有効化
	if (pTexture == NULL) {
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_TEXTURE_RECTANGLE_EXT);
	}
	else {
		pTexture->BindTexture();
	}
	
	//変換行列適用
	m_TransMatrix.push();
	
	//インデックス最大数
	indexNumMax = m_IndexNum;
	if (m_pIndexBuffer == NULL) {
		indexNumMax = m_VertexNum;
	}
	
	//描画インデックス数
	//  直接インデックス数を指定された場合はそれに従う
	if (drawIndexNum < 0) {
		indexNum = indexNumMax;
	}
	else {
		indexNum = drawIndexNum;
		if ((unsigned long)drawIndexNum > indexNumMax) {
			result = YN_SET_ERR(@"Program error.", drawIndexNum, indexNumMax);
			goto EXIT;
		}
	}
	
	//プリミティブの描画
	if (m_pIndexBuffer != NULL) {
		//インデックス付きプリミティブの描画
		glDrawElements(
				m_PrimitiveType,	//プリミティブ種別
				indexNum,			//インデックスの数
				GL_UNSIGNED_INT,	//インデックスの型
				NULL				//インデクス配列のポインタ：インデックスバッファ適用時はNULL
			);
		if ((glresult = glGetError()) != GL_NO_ERROR) {
			result = YN_SET_ERR(@"OpenGL API error.", glresult, indexNum);
			goto EXIT;
		}
	}
	else {
		//インデックスなしプリミティブの描画
		glDrawArrays(
				m_PrimitiveType,	//プリミティブ種別
				0,					//先頭インデックス
				indexNum			//インデックスの数
			);
		if ((glresult = glGetError()) != GL_NO_ERROR) {
			result = YN_SET_ERR(@"OpenGL API error.", glresult, indexNum);
			goto EXIT;
		}
	}
	
	//テクスチャ無効化
	if (pTexture != NULL) {
		pTexture->UnbindTexture();
	}
	
	//変換行列適用解除
	m_TransMatrix.pop();
	
	//バッファ無効化
	result = _DisableBuffer();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// バッファ有効化
//******************************************************************************
int OGLPrimitive::_EnableBuffer()
{
	int result = 0;
	GLenum glresult = 0;
	unsigned long offset = 0;
	unsigned long elementSize = 0;
	unsigned long stride = 0;
	
	result = _DisableBuffer();
	if (result != 0) goto EXIT;
	
	//--------------------------------------
	//頂点バッファ有効化
	//--------------------------------------
	glBindBuffer(GL_ARRAY_BUFFER_ARB, m_VertexBufferId);
	stride = m_VertexSize;
	
	//頂点座標
	if (m_VertexFormat & OGLVERTEX_ELEMENT_VERTEX) {
		//頂点座標配列の有効化
		glEnableClientState(GL_VERTEX_ARRAY);
		//配列構造
		elementSize = sizeof(GLfloat)*3;
		//頂点座標配列の位置：要素数／座標種別／頂点間オフセット／配列先頭ポインタ
		glVertexPointer(3, GL_FLOAT, stride, (GLvoid*)offset);
		if ((glresult = glGetError()) != GL_NO_ERROR) {
			result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
			goto EXIT;
		}
		offset += elementSize;
	}
	//法線
	if (m_VertexFormat & OGLVERTEX_ELEMENT_NORMAL) {
		//法線配列の有効化
		glEnableClientState(GL_NORMAL_ARRAY);
		//配列構造
		elementSize = sizeof(GLfloat)*3;
		//法線配列の位置：座標種別／頂点間のオフセット／配列先頭ポインタ
		glNormalPointer(GL_FLOAT, stride, (GLvoid*)offset);
		if ((glresult = glGetError()) != GL_NO_ERROR) {
			result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
			goto EXIT;
		}
		offset += elementSize;
	}
	//色
	if (m_VertexFormat & OGLVERTEX_ELEMENT_COLOR) {
		//色配列の有効化
		glEnable(GL_COLOR_MATERIAL);
		glEnableClientState(GL_COLOR_ARRAY);
		//配列構造
		elementSize = sizeof(GLubyte)*4;
		//色配列の位置：要素数／座標種別／頂点間オフセット／配列先頭ポインタ
		glColorPointer(4, GL_UNSIGNED_BYTE, stride, (GLvoid*)offset);
		if ((glresult = glGetError()) != GL_NO_ERROR) {
			result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
			goto EXIT;
		}
		offset += elementSize;
	}
	//テクスチャ座標
	if (m_VertexFormat & OGLVERTEX_ELEMENT_TEXTURE) {
		//テクスチャ座標配列の有効化
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		//配列構造
		elementSize = sizeof(GLfloat)*2;
		//テクスチャ座標配列の位置：要素数／座標種別／頂点間オフセット／配列先頭ポインタ
		glTexCoordPointer(2, GL_FLOAT, stride, (GLvoid*)offset);
		if ((glresult = glGetError()) != GL_NO_ERROR) {
			result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
			goto EXIT;
		}
		offset += elementSize;
	}
	
	//--------------------------------------
	//インデックスバッファ有効化
	//--------------------------------------
	if (m_pIndexBuffer != NULL) {
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, m_IndexBufferId);
		glEnableClientState(GL_INDEX_ARRAY);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// バッファ無効化
//******************************************************************************
int OGLPrimitive::_DisableBuffer()
{
	int result = 0;
	
	glDisable(GL_COLOR_MATERIAL);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_INDEX_ARRAY);
	
	glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
	
	return result;
}

//******************************************************************************
// マテリアル設定
//******************************************************************************
void OGLPrimitive::_EnableMaterial()
{
	//拡散光
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, (GLfloat*)(m_Material.Diffuse));
	//環境光
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, (GLfloat*)(m_Material.Ambient));
	//鏡面反射光
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, (GLfloat*)(m_Material.Specular));
	//鏡面反射光の鮮明度
	glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, (GLfloat*)&(m_Material.Power));
	//発光色
	glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, (GLfloat*)(m_Material.Emissive));
}

//******************************************************************************
// 頂点バッファロック
//******************************************************************************
int OGLPrimitive::LockVertex(
		void** pPtrVertex,
		unsigned long offset,	//省略時はゼロ
		unsigned long size		//省略時はゼロ
	)
{
	int result = 0;
	unsigned long lockSize = 0;
	
	if (m_IsVertexLocked) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ロックサイズ算出
	lockSize = size;
	if (lockSize == 0) {
		lockSize = (m_VertexSize * m_VertexNum) - offset;
	}
	if ((m_VertexSize * m_VertexNum) < (offset + lockSize)) {
		result = YN_SET_ERR(@"Program error.", offset, lockSize);
		goto EXIT;
	}
	
	//頂点バッファのロック位置を取得
	*pPtrVertex = (void*)((unsigned char*)m_pVertexBuffer + offset);
	
	//ロック範囲情報
	m_VertexBufferLockedOffset = offset;
	m_VertexBufferLockedSize = lockSize;
	
	m_IsVertexLocked = true;
	
EXIT:;
	return result;
}

//******************************************************************************
// 頂点バッファロック解除
//******************************************************************************
int OGLPrimitive::UnlockVertex()
{
	int result = 0;
	GLenum glresult = 0;
	
	if (!m_IsVertexLocked) goto EXIT;
	
	//頂点バッファ書き込み
	glBindBuffer(GL_ARRAY_BUFFER_ARB, m_VertexBufferId);
	glBufferSubData(
			GL_ARRAY_BUFFER_ARB,		//ターゲット：頂点バッファ
			m_VertexBufferLockedOffset,	//オフセット
			m_VertexBufferLockedSize,	//サイズ
			(void*)((unsigned char*)m_pVertexBuffer + m_VertexBufferLockedOffset)
										///格納するデータの位置
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
	
	m_IsVertexLocked = false;
	
EXIT:;
	return result;
}

//******************************************************************************
// インデックスバッファロック
//******************************************************************************
int OGLPrimitive::LockIndex(
		unsigned long** pPtrIndex,
		unsigned long offset,	//省略時はゼロ
		unsigned long size		//省略時はゼロ
	)
{
	int result = 0;
	unsigned long lockSize = 0;
	
	if (m_IsIndexLocked) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//ロックサイズ算出
	lockSize = size;
	if (lockSize == 0) {
		lockSize = (sizeof(GLuint) * m_IndexNum) - offset;
	}
	if ((sizeof(GLuint) * m_IndexNum) < (offset + lockSize)) {
		result = YN_SET_ERR(@"Program error.", offset, lockSize);
		goto EXIT;
	}
	
	//頂点バッファのロック位置を取得
	*pPtrIndex = (unsigned long*)((unsigned char*)m_pIndexBuffer + offset);
	
	//ロック範囲情報
	m_IndexBufferLockedOffset = offset;
	m_IndexBufferLockedSize = lockSize;
	
	m_IsIndexLocked = true;
	
EXIT:;
	return result;
}

//******************************************************************************
// インデックスバッファロック解除
//******************************************************************************
int OGLPrimitive::UnlockIndex()
{
	int result = 0;
	GLenum glresult = 0;
	
	if (!m_IsIndexLocked) goto EXIT;
	
	//頂点バッファ書き込み
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, m_IndexBufferId);
	glBufferSubData(
			GL_ELEMENT_ARRAY_BUFFER_ARB,//ターゲット：インデックスバッファ
			m_IndexBufferLockedOffset,	//オフセット
			m_IndexBufferLockedSize,	//サイズ
			(void*)((unsigned char*)m_pIndexBuffer + m_IndexBufferLockedOffset)
										///格納するデータの位置
		);
	if ((glresult = glGetError()) != GL_NO_ERROR) {
		result = YN_SET_ERR(@"OpenGL API error.", glresult, 0);
		goto EXIT;
	}
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
	
	m_IsIndexLocked = false;
	
EXIT:;
	return result;
}

//******************************************************************************
// プリミティブ数取得
//******************************************************************************
int OGLPrimitive::_GetPrimitiveNum(
		unsigned long* pNum
	)
{
	int result = 0;
	unsigned long vertexNum = 0;
	
	vertexNum = m_VertexNum;
	if (m_pIndexBuffer != NULL) {
		vertexNum = m_IndexNum;
	}
	
	if (vertexNum == 0) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	switch (m_PrimitiveType) {
		case GL_POINTS:  //D3DPT_POINTLIST:
			*pNum = vertexNum;
			break;
			
		case GL_LINES:  //D3DPT_LINELIST:
			if ((vertexNum % 2) != 0) {
				result = YN_SET_ERR(@"Program error.", vertexNum, 0);
				goto EXIT;
			}
			*pNum = vertexNum / 2;
			break;
			
		case GL_LINE_STRIP:  //D3DPT_LINESTRIP:
			if (vertexNum < 2) {
				result = YN_SET_ERR(@"Program error.", vertexNum, 0);
				goto EXIT;
			}
			*pNum = vertexNum - 1;
			break;
			
		case GL_TRIANGLES:  //D3DPT_TRIANGLELIST:
			if ((vertexNum % 3) != 0) {
				result = YN_SET_ERR(@"Program error.", vertexNum, 0);
				goto EXIT;
			}
			*pNum = vertexNum / 3;
			break;
			
		case GL_TRIANGLE_STRIP:  //D3DPT_TRIANGLESTRIP:
			if (vertexNum < 3) {
				result = YN_SET_ERR(@"Program error.", vertexNum, 0);
				goto EXIT;
			}
			*pNum = vertexNum - 2;
			break;
			
		case GL_TRIANGLE_FAN:  //D3DPT_TRIANGLEFAN:
			if (vertexNum < 3) {
				result = YN_SET_ERR(@"Program error.", vertexNum, 0);
				goto EXIT;
			}
			*pNum = vertexNum - 2;
			break;
		//以下DirectX9では対応する定義が存在しない
		case GL_LINE_LOOP:
		case GL_QUADS:
		case GL_QUAD_STRIP:
		case GL_POLYGON:
		default:
			result = YN_SET_ERR(@"Program error.", (unsigned long)m_PrimitiveType, 0);
			goto EXIT;
			break;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// デフォルトマテリアル
//******************************************************************************
void OGLPrimitive::_GetDefaultMaterial(
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
	pMaterial->Specular.r = 0.0f;//0.2f;
	pMaterial->Specular.g = 0.0f;//0.2f;
	pMaterial->Specular.b = 0.0f;//0.2f;
	pMaterial->Specular.a = 0.0f;//1.0f;
	//鏡面反射光の鮮明度
	pMaterial->Power = 0.0f; //10.0f;
	//発光色
	pMaterial->Emissive.r = 0.0f;
	pMaterial->Emissive.g = 0.0f;
	pMaterial->Emissive.b = 0.0f;
	pMaterial->Emissive.a = 0.0f;
}


