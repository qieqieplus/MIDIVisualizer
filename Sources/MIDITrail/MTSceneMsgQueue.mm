//******************************************************************************
//
// MIDItrail / MTSceneMsgQueue
//
// シーンメッセージキュークラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTSceneMsgQueue.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTSceneMsgQueue::MTSceneMsgQueue(void)
{
	m_pSync = [[NSObject alloc] init];
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTSceneMsgQueue::~MTSceneMsgQueue(void)
{
	[m_pSync release];
	m_pSync = nil;

	Clear();
}

//******************************************************************************
// クリア
//******************************************************************************
void MTSceneMsgQueue::Clear()
{
	MTSceneMsgListItr itr;
	MTSceneMsg* pMsg = NULL;
	
	@synchronized(m_pSync) {
		for (itr = m_MsgList.begin(); itr != m_MsgList.end(); itr++) {
			pMsg = *itr;
			delete pMsg;
		}
		m_MsgList.clear();
	}
}

//******************************************************************************
// メッセージ登録：非同期
//******************************************************************************
int MTSceneMsgQueue::PostMessage(
		MTSceneMsg* pSceneMsg
	)
{
	int result = 0;
	
	if (pSceneMsg == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//同期モード：非同期
	pSceneMsg->SetSyncMode(false);
	
	//キュー登録
	@synchronized(m_pSync) {
		m_MsgList.push_back(pSceneMsg);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// メッセージ登録：同期
//******************************************************************************
int MTSceneMsgQueue::SendMessage(
		MTSceneMsg* pSceneMsg
	)
{
	int result = 0;
	
	if (pSceneMsg == NULL) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	//同期モード：同期
	pSceneMsg->SetSyncMode(true);
	
	//キュー登録
	@synchronized(m_pSync) {
		m_MsgList.push_back(pSceneMsg);
	}
	
	//メッセージ処理終了まで待機する
	pSceneMsg->WaitAns();
	
EXIT:;
	return result;
}

//******************************************************************************
// メッセージ取得
//******************************************************************************
int MTSceneMsgQueue::GetMessage(
		bool* pIsExist,
		MTSceneMsg** pSceneMsgPtr
	)
{
	int result = 0;
	MTSceneMsgListItr itr;
	
	if ((pIsExist == NULL) || (pSceneMsgPtr == NULL)) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	*pIsExist = false;
	*pSceneMsgPtr = NULL;
	
	@synchronized(m_pSync) {
		if (m_MsgList.size() > 0) {
			*pIsExist = true;
			itr = m_MsgList.begin();
			*pSceneMsgPtr = *itr;
			m_MsgList.pop_front();
		}
	}
	
EXIT:;
	return result;
}


