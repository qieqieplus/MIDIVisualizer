//******************************************************************************
//
// Simple MIDI Library / SMFileReader
//
// 標準MIDIファイル読み込みクラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

//#include "mmsystem.h"
#include "SMEvent.h"
#include "SMEventMIDI.h"
#include "SMEventSysEx.h"
#include "SMEventMeta.h"
#include "SMTrack.h"
#include "SMSeqData.h"
#include <stdio.h>


//******************************************************************************
// 標準MIDIファイル読み込みクラス
//******************************************************************************
class SMFileReader
{
public:
	
	//コンストラクタ／デストラクタ
	SMFileReader(void);
	~SMFileReader(void);
	
	//ログ出力先ファイルパス登録
	int SetLogPath(NSString* pLogPath);
	
	//エンコーディングID登録（NSStringEncoding）
	void SetEncodingId(unsigned long encodingId);
	
	//標準MIDIファイル読み込み
	int Load(NSString* pSMFPath, SMSeqData* pMIDIData);
	
private:
	
	//チャンクヘッダ構造
	
	#pragma pack(push,1)
	
	typedef struct {
		unsigned char chunkType[4];		//チャンクタイプ MThd/MTrk
		unsigned long chunkSize;		//チャンクサイズ
	} SMFChunkTypeSection;
	
	typedef struct {
		unsigned short format;			//フォーマット 0,1,2
		unsigned short ntracks;			//トラック数
		unsigned short timeDivision;	//4分音符あたりの分解能
	} SMFChunkDataSection;
	
	#pragma pack(pop)
	
private:
	
	unsigned char m_PrevStatus;
	unsigned long m_FilePos;
	NSData* m_pFileData;
	NSString* m_pLogPath;
	NSFileHandle* m_pLogFile;
	bool m_IsLogOut;
	unsigned long m_EncodingId;
	
	int _ReadChunkHeader(
			SMFChunkTypeSection* pChunkTypeSection,
			SMFChunkDataSection* pChunkDataSection
		);
	
	int _ReadTrackHeader(
			unsigned long trackNo,
			SMFChunkTypeSection* pChunkTypeSection
		);
	
	int _ReadTrackEvents(
			unsigned long chunkSize,
			SMTrack** pPtrTrack
		);
	
	int _ReadDeltaTime(
			unsigned long* pDeltaTime,
			unsigned long* pOffset
		);
	
	int _ReadVariableDataSize(
			unsigned long* pVariableDataSize,
			unsigned long* pOffset
		);
	
	int _ReadEvent(
			SMEvent* pEvent,
			bool* pIsEndOfTrack,
			unsigned long* pOffset
		);
	
	int _ReadEventMIDI(
			unsigned char status,
			SMEvent* pEvent,
			unsigned long* pOffset
		);
	
	int _ReadEventSysEx(
			unsigned char status,
			SMEvent* pEvent,
			unsigned long* pOffset
		);
	
	int _ReadEventMeta(
			unsigned char status,
			SMEvent* pEvent,
			bool* pIsEndOfTrack,
			unsigned long* pOffset
		);

	void _ReverseEndian(
			void* pData,
			unsigned long size
		);
	
	int _OpenFile(NSString* pSMFPath);
	int _ReadFile(
			void* pDest,
			unsigned long size,
			unsigned long callPos
		);
	int _CloseFile();
	
	int _OpenLogFile();
	int _CloseLogFile();
	int _WriteLog(const char* pText);
	int _WriteLogChunkHeader(
				SMFChunkTypeSection* pChunkTypeSection,
				SMFChunkDataSection* pChunkDataSection
			);
	int _WriteLogTrackHeader(
				unsigned long trackNo,
				SMFChunkTypeSection* pChunkTypeSection
			);
	int _WriteLogDeltaTime(
				unsigned long deltaTime
			);
	int _WriteLogEventMIDI(
				unsigned char status,
				unsigned char* pData,
				unsigned long size
			);
	int _WriteLogEventSysEx(
				unsigned char status,
				unsigned char* pData,
				unsigned long size
			);
	int _WriteLogEventMeta(
				unsigned char status,
				unsigned char type,
				unsigned char* pData,
				unsigned long size
			);
	
	//代入とコピーコンストラクタの禁止
	void operator=(const SMFileReader&);
	SMFileReader(const SMFileReader&);

};


