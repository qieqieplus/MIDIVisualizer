//******************************************************************************
//
// MIDItrail / MTSceneMsgQueue
//
// シーンメッセージキュークラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import <list>
#import "MTSceneMsg.h"


//******************************************************************************
// シーンメッセージキュークラス
//******************************************************************************
class MTSceneMsgQueue
{
public:
	
	//コンストラクタ／デストラクタ
	MTSceneMsgQueue(void);
	virtual ~MTSceneMsgQueue(void);
	
	//クリア
	void Clear();
	
	//メッセージ登録：非同期
	int PostMessage(MTSceneMsg* pSceneMsg);
	
	//メッセージ登録：同期
	int SendMessage(MTSceneMsg* pSceneMsg);
	
	//メッセージ取得
	int GetMessage(bool* pIsExist, MTSceneMsg** pSceneMsgPtr);
	
private:
	
	typedef std::list<MTSceneMsg*> MTSceneMsgList;
	typedef std::list<MTSceneMsg*>::iterator MTSceneMsgListItr;
	
private:
	
	NSObject* m_pSync;
	MTSceneMsgList m_MsgList;
	
};


