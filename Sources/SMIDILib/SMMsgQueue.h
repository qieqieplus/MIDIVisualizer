//******************************************************************************
//
// Simple MIDI Library / SMMsgQueue
//
// メッセージキュークラスヘッダ
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "SMSimpleList.h"


//******************************************************************************
// メッセージキュークラス
//******************************************************************************
class SMMsgQueue
{
public:
	
	//コンストラクタ／デストラクタ
	SMMsgQueue(void);
	virtual ~SMMsgQueue(void);
	
	//初期化
	int Initialize(unsigned long maxMsgNum);
	
	//メッセージ登録
	int PostMessage(unsigned long param1, unsigned long param2);
	
	//メッセージ取得
	int GetMessage(bool* pIsExist, unsigned long* pParam1, unsigned long* pParam2);
	
private:
	
	NSObject* m_pSync;
	
	SMSimpleList m_List;
	unsigned long m_MaxMsgNum;
	unsigned long m_NextPostIndex;
	unsigned long m_NextReadIndex;

};


