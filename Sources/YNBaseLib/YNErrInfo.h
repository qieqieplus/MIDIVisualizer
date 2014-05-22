//******************************************************************************
//
// Simple Base Library / YNErrInfo
//
// エラー情報クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>


//******************************************************************************
// パラメータ定義
//******************************************************************************
//エラーレベル
typedef enum _YNErrLevel {
	LVL_ERR,
	LVL_WARN,
	LVL_INFO
} YNErrLevel;


//******************************************************************************
// エラー情報クラス
//******************************************************************************
@interface YNErrInfo : NSObject {
	YNErrLevel m_ErrLevel;
	unsigned long m_LineNo;
	unsigned long m_ErrInfo1;
	unsigned long m_ErrInfo2;
	NSString* m_FileName;
	NSString* m_Message;
}

//初期化
- (id)initWithInfo:(YNErrLevel)errLevel
			lineNo:(unsigned long)lineNo
		  fileName:(NSString*)fileName
		   message:(NSString*)message
		  errInfo1:(unsigned long)errInfo1
		  errInfo2:(unsigned long)errInfo2;

//解放
- (void)dealloc;

//エラーレベル取得
- (YNErrLevel)errLevel;

//行番号取得
- (unsigned long)lineNo;

//ファイル名取得
- (NSString*)fileName;

//メッセージ取得
- (NSString*)message;

//エラー情報取得
- (unsigned long)errInfo1;
- (unsigned long)errInfo2;

@end


