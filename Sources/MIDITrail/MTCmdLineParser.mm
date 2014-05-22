//******************************************************************************
//
// MIDITrail / MTCmdLineParser
//
// コマンドライン解析クラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTCmdLineParser.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTCmdLineParser::MTCmdLineParser(void)
{
	m_pFilePath = @"";
	memset(m_CmdSwitchStatus, 0, sizeof(unsigned char)*CMDSW_MAX);
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTCmdLineParser::~MTCmdLineParser(void)
{
	[m_pFilePath release];
	m_pFilePath = nil;
}

//******************************************************************************
// 初期化
//******************************************************************************
int MTCmdLineParser::Initialize()
{
	int result = 0;
	
	//コマンドライン解析
	result = _AnalyzeCmdLine();
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// コマンドライン解析
//******************************************************************************
int MTCmdLineParser::_AnalyzeCmdLine()
{
	int result = 0;
	NSArray* pArgArray = nil;
	NSString* pArg = nil;
	int count = 0;
	
	//引数の配列を取得
	pArgArray = [[NSProcessInfo processInfo] arguments];
	
	//引数の解析
	for (pArg in pArgArray) {
		//先頭のアプリケーションパスは無視する
		count++;
		if (count == 1) continue;
		
		//起動後に再生開始
		if ([pArg isEqualToString:@"-p"]) {
			m_CmdSwitchStatus[CMDSW_PLAY] = CMDSW_ON;
		}
		//再生終了時にアプリ終了
		else if ([pArg isEqualToString:@"-q"]) {
			m_CmdSwitchStatus[CMDSW_QUIET] = CMDSW_ON;
		}
		//デバッグモード
		else if ([pArg isEqualToString:@"-d"]) {
			m_CmdSwitchStatus[CMDSW_DEBUG] = CMDSW_ON;
		}
		//ファイルパス
		//  ファイルパスが複数指定された場合は先頭のみを採用する
		//  先頭の文字列が"-"でなければファイルパスとみなす
		else if ([m_pFilePath length] == 0) {
			if (([pArg length] > 1)
			 && (![[pArg substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"-"])) {
				m_pFilePath = pArg;
				[m_pFilePath retain];
				m_CmdSwitchStatus[CMDSW_FILE_PATH] = CMDSW_ON;
			}
		}
	}
	
	//ファイルパスが未指定の場合
	if (m_CmdSwitchStatus[CMDSW_FILE_PATH] != CMDSW_ON) {
		//再生／終了フラグは共に無効
		m_CmdSwitchStatus[CMDSW_PLAY] = CMDSW_NONE;
		m_CmdSwitchStatus[CMDSW_QUIET] = CMDSW_NONE;
	}
	
	//再生フラグONでなければ終了フラグは無効
	if (m_CmdSwitchStatus[CMDSW_PLAY] != CMDSW_ON) {
		m_CmdSwitchStatus[CMDSW_QUIET] = CMDSW_NONE;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// スイッチ状態取得
//******************************************************************************
int MTCmdLineParser::GetSwitch(
		unsigned long switchType
	)
{
	int switchStatus = CMDSW_NONE;
	
	if (switchType < CMDSW_MAX) {
		switchStatus = m_CmdSwitchStatus[switchType];
	}
	
	return switchStatus;
}

//******************************************************************************
// ファイルパス取得
//******************************************************************************
NSString* MTCmdLineParser::GetFilePath()
{
	return m_pFilePath;
}


