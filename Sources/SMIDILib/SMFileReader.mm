//******************************************************************************
//
// Simple MIDI Library / SMFileReader
//
// 標準MIDIファイル読み込みクラス
//
// Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "SMFileReader.h"
#import "SMCommon.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
SMFileReader::SMFileReader(void)
{
	m_FilePos = 0;
	m_pFileData = nil;
	m_pLogPath = nil;
	m_pLogFile = nil;
	m_IsLogOut = false;
	m_EncodingId = NSShiftJISStringEncoding;
}

//******************************************************************************
// デストラクタ
//******************************************************************************
SMFileReader::~SMFileReader(void)
{
	[m_pLogPath release];
}

//******************************************************************************
// ログ出力パス設定
//******************************************************************************
int SMFileReader::SetLogPath(
		NSString* pLogPath
	)
{
	int result = 0;
	
	[pLogPath retain];
	[m_pLogPath release];
	m_pLogPath = pLogPath;
	
	return result;
}

//******************************************************************************
// エンコーディングID登録（NSStringEncoding）
//******************************************************************************
void SMFileReader::SetEncodingId(
		unsigned long encodingId
	)
{
	m_EncodingId = encodingId;
}

//******************************************************************************
// Standard MIDI File のロード
//******************************************************************************
int SMFileReader::Load(
		NSString* pSMFPath,
		SMSeqData* pSeqData
	)
{
	int result = 0;
	unsigned long i = 0;
	SMFChunkTypeSection chunkTypeSection;
	SMFChunkDataSection chunkDataSection;
	SMFChunkTypeSection chunkTypeSectionOfTrack;
	SMTrack* pTrack = NULL;
	
	if ((pSMFPath == nil) || (pSeqData == NULL)) {
		result = YN_SET_ERR(@"Program error.", 0, 0);
		goto EXIT;
	}
	
	pSeqData->Clear();
	pSeqData->SetEncodingId(m_EncodingId);
	
	//ログファイルを開く
	result = _OpenLogFile();
	if (result != 0 ) goto EXIT;
	
	//ファイルを開く
	result = _OpenFile(pSMFPath);
	if (result != 0) goto EXIT;
	
	//ヘッダ読み込み
	result = _ReadChunkHeader(&chunkTypeSection, &chunkDataSection);
	if (result != 0 ) goto EXIT;
	
	if ((chunkDataSection.format != 0) && (chunkDataSection.format != 1)) {
		//フォーマット0,1以外は未対応
		result = YN_SET_ERR(@"Unsupported SMF format.", chunkDataSection.format, 0);
		goto EXIT;
	}
	if ( chunkDataSection.ntracks == 0) {
		//データ異常
		result = YN_SET_ERR(@"Invalid data found.", 0, 0);
		goto EXIT;
	}
	if ( chunkDataSection.timeDivision == 0) {
		//データ異常
		result = YN_SET_ERR(@"Invalid data found.", 0, 0);
		goto EXIT;
	}
	if ((chunkDataSection.timeDivision & 0x80000000) != 0) {
		//分解能が負の場合はデルタタイムを実時間とみなす仕様がある
		//一般的でないので今のところサポートしない
		result = YN_SET_ERR(@"Unsupported SMF format.", chunkDataSection.timeDivision, 0);
		goto EXIT;
	}
	
	pSeqData->SetSMFFormat(chunkDataSection.format);
	pSeqData->SetTimeDivision(chunkDataSection.timeDivision);
	
	for (i = 0; i < chunkDataSection.ntracks; i++) {
		//トラックヘッダ読み込み
		result = _ReadTrackHeader(i, &chunkTypeSectionOfTrack);
		if (result != 0 ) goto EXIT;
		
		//トラックイベント読み込み
		result = _ReadTrackEvents(chunkTypeSectionOfTrack.chunkSize, &pTrack);
		if (result != 0 ) goto EXIT;
		
		result = pSeqData->AddTrack(pTrack);
		if (result != 0 ) goto EXIT;
		pTrack = NULL;
	}
	
	//トラックを閉じる
	result = pSeqData->CloseTrack();
	if (result != 0 ) goto EXIT;
	
	//ファイル名登録
	pSeqData->SetFileName([pSMFPath lastPathComponent]);
	
EXIT:;
	_CloseFile();
	_CloseLogFile();
	return result;
}

//******************************************************************************
// SMFヘッダ読み込み
//******************************************************************************
int SMFileReader::_ReadChunkHeader(
		SMFChunkTypeSection* pChunkTypeSection,
		SMFChunkDataSection* pChunkDataSection
	)
{
	int result = 0;
	
	//識別子とヘッダデータサイズの読み込み
	result = _ReadFile(pChunkTypeSection, sizeof(SMFChunkTypeSection), __LINE__);
	if (result != 0) goto EXIT;
	
	//エンディアン変換
	_ReverseEndian(&(pChunkTypeSection->chunkSize), sizeof(unsigned long));
	
	//整合性チェック
	if (memcmp(pChunkTypeSection->chunkType, "MThd", 4) != 0) {
		result = YN_SET_ERR(@"Invalid data found.", 0, 0);
		goto EXIT;
	}
	if (pChunkTypeSection->chunkSize < sizeof(SMFChunkDataSection)) {
		result = YN_SET_ERR(@"Invalid data found.", pChunkTypeSection->chunkSize, 0);
		goto EXIT;
	}
	
	//ヘッダデータの読み込み
	result = _ReadFile(pChunkDataSection, sizeof(SMFChunkDataSection), __LINE__);
	if (result != 0) goto EXIT;
	
	//エンディアン変換
	_ReverseEndian(&(pChunkDataSection->format), sizeof(unsigned short));
	_ReverseEndian(&(pChunkDataSection->ntracks), sizeof(unsigned short));
	_ReverseEndian(&(pChunkDataSection->timeDivision), sizeof(unsigned short));
	
	//指定されたデータサイズまでスキップする（念のため）
	if (pChunkTypeSection->chunkSize > sizeof(SMFChunkDataSection)) {
		m_FilePos = pChunkTypeSection->chunkSize;
	}
	
	result = _WriteLogChunkHeader(pChunkTypeSection, pChunkDataSection);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// SMFトラックヘッダの読み込み
//******************************************************************************
int SMFileReader::_ReadTrackHeader(
		unsigned long trackNo,
		SMFChunkTypeSection* pChunkTypeSection
	)
{
	int result = 0;
	
	//識別子とヘッダデータサイズの読み込み
	result = _ReadFile(pChunkTypeSection, sizeof(SMFChunkTypeSection), __LINE__);
	if (result != 0) goto EXIT;
	
	//エンディアン変換
	_ReverseEndian(&(pChunkTypeSection->chunkSize), sizeof(unsigned long));
	
	//整合性チェック
	if (memcmp(pChunkTypeSection->chunkType, "MTrk", 4) != 0) {
		result = YN_SET_ERR(@"Invalid data found.", 0, 0);
		goto EXIT;
	}
	
	result = _WriteLogTrackHeader(trackNo, pChunkTypeSection);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// SMFトラックイベントの読み込み
//******************************************************************************
int SMFileReader::_ReadTrackEvents(
		unsigned long chunkSize,
		SMTrack** pPtrTrack
	)
{
	int result = 0;
	unsigned long readSize = 0;
	unsigned long deltaTime = 0;
	unsigned long offset = 0;
	unsigned char portNo = 0;
	bool isEndOfTrack = false;
	SMEvent event;
	SMTrack* pTrack = NULL;
	
	try {
		pTrack = new SMTrack();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//出力先ポートの初期値はトラック単位で0番とする
	portNo = 0;
	
	m_PrevStatus = 0;
	while (readSize < chunkSize) {
		
		//デルタタイム読み込み
		result = _ReadDeltaTime(&deltaTime, &offset);
		if (result != 0) goto EXIT;
		readSize += offset;
		
		//イベント読み込み
		result = _ReadEvent(&event, &isEndOfTrack, &offset);
		if (result != 0) goto EXIT;
		readSize += offset;
		
		//出力ポートの切り替えを確認
		if (event.GetType() == SMEvent::EventMeta) {
			if (event.GetMetaType() == 0x21) {
				SMEventMeta meta;
				meta.Attach(&event);
				portNo = meta.GetPortNo();
			}
		}
		
		//イベントリストに追加
		result = pTrack->AddDataSet(deltaTime, &event, portNo);
		if (result != 0) goto EXIT;
		
		//トラック終端
		if (isEndOfTrack) {
			if (readSize != chunkSize) {
				//データ不正
				result = YN_SET_ERR(@"Invalid data found.", readSize, chunkSize);
				goto EXIT;
			}
			break;
		}
	}
	
	*pPtrTrack = pTrack;
	pTrack = NULL;
	
EXIT:;
	delete pTrack;
	return result;
}

//******************************************************************************
// SMFデルタタイムの読み込み
//******************************************************************************
int SMFileReader::_ReadDeltaTime(
		unsigned long* pDeltaTime,
		unsigned long* pOffset
	)
{
	int result = 0;
	
	result = _ReadVariableDataSize(pDeltaTime, pOffset);
	if (result != 0) goto EXIT;
	
	result = _WriteLogDeltaTime(*pDeltaTime);
	if (result != 0) goto EXIT;
	
EXIT:;
	return result;
}

//******************************************************************************
// SMF可変長データサイズの読み込み
//******************************************************************************
int SMFileReader::_ReadVariableDataSize(
		unsigned long* pVariableDataSize,
		unsigned long* pOffset
	)
{
	int result = 0;
	int i = 0;
	unsigned char tmp = 0;
	
	*pVariableDataSize = 0;
	*pOffset = 0;
	
	for (i = 0; i < 4; i++){
		result = _ReadFile(&tmp, sizeof(unsigned char), __LINE__);
		if (result != 0) goto EXIT;
		
		*pOffset += sizeof(unsigned char);
		*pVariableDataSize = (*pVariableDataSize << 7) | (tmp & 0x7F);
		
		if ((tmp & 0x80) == 0) break;
	}

EXIT:;
	return result;
}

//******************************************************************************
// イベントの読み込み
//******************************************************************************
int SMFileReader::_ReadEvent(
		SMEvent* pEvent,
		bool* pIsEndOfTrack,
		unsigned long* pOffset
	)
{
	int result = 0;
	unsigned char tmp = 0;
	unsigned char status = 0;
	unsigned long offsetTmp = 0;
	*pIsEndOfTrack = false;
	*pOffset = 0;
	
	//ステータスを読み込む
	result = _ReadFile(&tmp, sizeof(unsigned char), __LINE__);
	if (result != 0) goto EXIT;
	*pOffset += sizeof(unsigned char);
	
	//ランニングステータスの省略チェック
	//前回のMIDIイベントが存在してかつ今回の1byte最上位ビットが0なら省略
	if ((m_PrevStatus != 0) && ((tmp & 0x80) == 0)) { 
		//省略されたので前回のMIDIイベントのステータスを引き継ぐ
		status = m_PrevStatus;
		//読み込み位置を戻す
		m_FilePos -= 1;
		*pOffset -= 1;
	}
	else {
		status = tmp;
	}
	
	switch (status & 0xF0) {
		case 0x80:  //ノートオフ
		case 0x90:  //ノートオン
		case 0xA0:  //ポリフォニックキープレッシャー
		case 0xB0:  //コントロールチェンジ
		case 0xC0:  //プログラムチェンジ
		case 0xD0:  //チャンネルプレッシャー
		case 0xE0:  //ピッチベンド
			//MIDIイベント
			result = _ReadEventMIDI(status, pEvent, &offsetTmp);
			if (result != 0) goto EXIT;
			//ランニングステータス省略判定のため前回ステータスとして記憶する
			m_PrevStatus = status;
			break;
		case 0xF0:
			if ((status == 0xF0) || (status == 0xF7)) {
				//SysExイベント
				result = _ReadEventSysEx(status, pEvent, &offsetTmp);
				if (result != 0) goto EXIT;
			}
			else if (status == 0xFF) {
				//メタイベント
				result = _ReadEventMeta(status, pEvent, pIsEndOfTrack, &offsetTmp);
				if (result != 0) goto EXIT;
			}
			else {
				//データ不正
				result = YN_SET_ERR(@"Invalid data found.", status, 0);
				goto EXIT;
			}
			break;
		default:
			//データ不正
			result = YN_SET_ERR(@"Invalid data found.", status, 0);
			goto EXIT;
	}
	*pOffset += offsetTmp;
	
EXIT:;
	return result;
}

//******************************************************************************
// MIDIイベントの読み込み
//******************************************************************************
int SMFileReader::_ReadEventMIDI(
		unsigned char status,
		SMEvent* pEvent,
		unsigned long* pOffset
	)
{
	int result = 0;
	unsigned char data[2];
	unsigned long size = 0;
	
	*pOffset = 0;
	
	//DATA1を読み込む
	result = _ReadFile(&(data[0]), sizeof(unsigned char), __LINE__);
	if (result != 0) goto EXIT;
	*pOffset += sizeof(unsigned char);
	
	switch (status & 0xF0) {
		case 0x80:  //ノートオフ
		case 0x90:  //ノートオン
		case 0xA0:  //ポリフォニックキープレッシャー
		case 0xB0:  //コントロールチェンジ
		case 0xE0:  //ピッチベンド
			//DATA2を読み込む
			result = _ReadFile(&(data[1]), sizeof(unsigned char), __LINE__);
			if (result != 0) goto EXIT;
			*pOffset += sizeof(unsigned char);
			size = 2;
			break;
		case 0xC0:  //プログラムチェンジ
		case 0xD0:  //チャンネルプレッシャー
			//DATA2なし
			size = 1;
			break;
		default:
			//データ不正
			result = YN_SET_ERR(@"Invalid data found.", status, 0);
			goto EXIT;
	}
	
	result = pEvent->SetMIDIData(status, data, size);
	if (result != 0) goto EXIT;
	
	result = _WriteLogEventMIDI(status, data, size);
	if (result != 0) goto EXIT;

EXIT:;
	return result;
}

//******************************************************************************
// SysExイベントの読み込み
//******************************************************************************
int SMFileReader::_ReadEventSysEx(
		unsigned char status,
		SMEvent* pEvent,
		unsigned long* pOffset
	)
{
	int result = 0;
	unsigned long size = 0;
	unsigned char* pData = NULL;
	unsigned long offsetTmp = 0;
	*pOffset = 0;
	
	//可変長データサイズを読み込む
	result = _ReadVariableDataSize(&size, &offsetTmp);
	if (result != 0) goto EXIT;
	*pOffset += offsetTmp;
	
	try {
		pData = new unsigned char[size];
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//可変長データを読み込む
	result = _ReadFile(pData, size, __LINE__);
	if (result != 0) goto EXIT;
	*pOffset += size;
	
	result = pEvent->SetSysExData(status, pData, size);
	if (result != 0) goto EXIT;
	
	result = _WriteLogEventSysEx(status, pData, size);
	if (result != 0) goto EXIT;
	
EXIT:;
	delete [] pData;
	return result;
}

//******************************************************************************
// メタイベントの読み込み
//******************************************************************************
int SMFileReader::_ReadEventMeta(
		unsigned char status,
		SMEvent* pEvent,
		bool* pIsEndOfTrack,
		unsigned long* pOffset
	)
{
	int result = 0;
	unsigned long size = 0;
	unsigned char type = 0;
	unsigned char* pData = NULL;
	unsigned long offsetTmp = 0;
	*pIsEndOfTrack = false;
	*pOffset = 0;
	
	//種別を読み込む
	result = _ReadFile(&type, sizeof(unsigned char), __LINE__);
	if (result != 0) goto EXIT;
	*pOffset += sizeof(unsigned char);
	
	//メタイベント種別
	switch (type) {
		            //  size（v:可変長データサイズ）
		case 0x00:  //  2  シーケンス番号
		case 0x01:  //  v  テキスト
		case 0x02:  //  v  著作権表示
		case 0x03:  //  v  シーケンス名／トラック名
		case 0x04:  //  v  楽器名
		case 0x05:  //  v  歌詞
		case 0x06:  //  v  マーカー
		case 0x07:  //  v  キューポイント
		case 0x08:  //  v  プログラム名／音色名
		case 0x09:  //  v  デバイス名 ／音源名
		case 0x20:  //  1  MIDIチャンネルプリフィックス
		case 0x21:  //  1  ポ ート指定
		case 0x2F:  //  0  トラック終端
		case 0x51:  //  3  テンポ設定
		case 0x54:  //  5  SMPTE オフセット
		case 0x58:  //  4  拍子の設定
		case 0x59:  //  2  調の設定
		case 0x7F:  //  v  シーケンサ特定メタイベント
			break;
		default:
			//未知の種別でもエラーにはしない
			// result = YN_SET_ERR("Invalid data found.", type, 0);
			// goto EXIT;
			break;
	}
	
	if (status == 0x2F) {
		*pIsEndOfTrack = true;
	}
	
	//可変長データサイズを読み込む
	result = _ReadVariableDataSize(&size, &offsetTmp);
	if (result != 0) goto EXIT;
	*pOffset += offsetTmp;
	
	//可変長データを読み込む
	if (size > 0) {
		try {
			pData = new unsigned char[size];
		}
		catch (std::bad_alloc) {
			result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
			goto EXIT;
		}
		result = _ReadFile(pData, size, __LINE__);
		if (result != 0) goto EXIT;
		*pOffset += size;
	}
	
	result = pEvent->SetMetaData(status, type, pData, size);
	if (result != 0) goto EXIT;
	
	result = _WriteLogEventMeta(status, type, pData, size);
	if (result != 0) goto EXIT;
	
EXIT:;
	delete [] pData;
	return result;
}

//******************************************************************************
// エンディアン変換
//******************************************************************************
void SMFileReader::_ReverseEndian(
		void* pData,
		unsigned long size
	)
{
	unsigned char tmp;
	unsigned char* pHead = (unsigned char*)pData;
	unsigned char* pTail = pHead + size - 1;
	
	while (pHead < pTail) {
		tmp = *pHead;
		*pHead = *pTail;
		*pTail = tmp;
		pHead += 1;
		pTail -= 1;
	}
	
	return;
}

//******************************************************************************
// ファイルオープン
//******************************************************************************
int SMFileReader::_OpenFile(
		NSString* pSMFPath
	)
{
	int result = 0;
	NSFileHandle* file = nil;
	NSData* head = nil;
	NSRange range;
	unsigned char buf[4];
	
	//ファイルハンドル作成
	file = [NSFileHandle fileHandleForReadingAtPath:pSMFPath];
	if (file == nil) {
		result = YN_SET_ERR(@"File open error.", 0, 0);
		goto EXIT;
	}
	
	//ファイル先頭の4byteを確認する
	@try {
		head = [file readDataOfLength:4];
		range.location = 0;
		range.length = 4;
		[head getBytes:buf range:range];
	}
	@catch (...) {
		result = YN_SET_ERR(@"File open error.", 0, 0);
		goto EXIT;
	}
	if (memcmp(buf, "MThd", 4) != 0) {
		result = YN_SET_ERR(@"The file is not a Standard MIDI file.", 0, 0);
		goto EXIT;
	}
	
	//ファイル全体を一気に読み込む
	@try {
		[file seekToFileOffset:0];
		m_pFileData = [file readDataToEndOfFile];
	}
	@catch (...) {
		result = YN_SET_ERR(@"File open error.", 0, 0);
		goto EXIT;
	}
	
	m_FilePos = 0;
	
EXIT:;
	if (file != nil) {
		[file closeFile];
	}
	return result;
}

//******************************************************************************
// ファイル読み込み
//******************************************************************************
int SMFileReader::_ReadFile(
		void* pDest,
		unsigned long size,
		unsigned long callPos
	)
{
	int result = 0;
	NSRange range;
	
	range.location = m_FilePos;
	range.length = size;
	
	@try {
		[m_pFileData getBytes:pDest range:range];
	}
	@catch (...) {
		result = YN_SET_ERR(@"File read error.", callPos, size);
		goto EXIT;
	}
	m_FilePos += size;
	
EXIT:;
	return result;
}

//******************************************************************************
// ファイルクローズ
//******************************************************************************
int SMFileReader::_CloseFile()
{
	m_FilePos = 0;
	m_pFileData = nil;
	return 0;
}

//******************************************************************************
// ログファイルオープン
//******************************************************************************
int SMFileReader::_OpenLogFile()
{
	int result = 0;
	NSString* pFullPath = nil;
	
	if ([m_pLogPath length] == 0) goto EXIT;
	
	//チルダ付きのパスをフルパスに変換
	pFullPath = [m_pLogPath stringByExpandingTildeInPath];
	
	//ファイルを生成
	[[NSFileManager defaultManager] createFileAtPath:pFullPath contents:nil attributes:nil];
	
	//ファイルを開く
	m_pLogFile = [NSFileHandle fileHandleForWritingAtPath:m_pLogPath];
	if (m_pLogFile == nil) {
		result = YN_SET_ERR(@"File open error.", 0, 0);
		goto EXIT;
	}
	[m_pLogFile retain];
	
	m_IsLogOut = true;

EXIT:;
	return result;
}

//******************************************************************************
// ログファイルクローズ
//******************************************************************************
int SMFileReader::_CloseLogFile()
{
	int result = 0;
	
	if (!m_IsLogOut) goto EXIT;
	
	[m_pLogFile closeFile];
	[m_pLogFile release];
	m_pLogFile = nil;
	
	m_IsLogOut = NO;
	
EXIT:;
	return result;;
}

//******************************************************************************
// ログ出力
//******************************************************************************
int SMFileReader::_WriteLog(
		const char* pText
	)
{
	int result = 0;
	size_t size = 0;
	NSString* pLog = nil;
	NSData* datas = nil;
	
	if (!m_IsLogOut) goto EXIT;
	
	pLog = [NSString stringWithCString:pText encoding:NSASCIIStringEncoding];
	datas = [pLog dataUsingEncoding:NSASCIIStringEncoding];
	if (datas == nil) {
		result = YN_SET_ERR(@"Log file write error.", size, 0);
		goto EXIT;
	}
	@try {
		[m_pLogFile writeData:datas];
	}
	@catch (...) {
		result = YN_SET_ERR(@"Log file write error.", size, 0);
		goto EXIT;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// ログ出力：ファイルヘッダ
//******************************************************************************
int SMFileReader::_WriteLogChunkHeader(
		SMFChunkTypeSection* pChunkTypeSection,
		SMFChunkDataSection* pChunkDataSection
	)
{
	int result = 0;
	char msg[256];
	
	if (!m_IsLogOut) goto EXIT;
	
	_WriteLog("--------------------\n");
	_WriteLog("File Header\n");
	_WriteLog("--------------------\n");
	_WriteLog("Chunk Type : MThd\n");
	snprintf(msg, 256, "Length     : %lu\n", pChunkTypeSection->chunkSize);
	_WriteLog(msg);
	snprintf(msg, 256, "Format     : %d\n", pChunkDataSection->format);
	_WriteLog(msg);
	snprintf(msg, 256, "nTracks    : %d\n", pChunkDataSection->ntracks);
	_WriteLog(msg);
	snprintf(msg, 256, "Devision   : %d\n", pChunkDataSection->timeDivision);
	_WriteLog(msg);
	
EXIT:;
	return result;
}

//******************************************************************************
// ログ出力：トラックヘッダ
//******************************************************************************
int SMFileReader::_WriteLogTrackHeader(
		unsigned long trackNo,
		SMFChunkTypeSection* pChunkTypeSection
	)
{
	int result = 0;
	char msg[256];
	
	if (!m_IsLogOut) goto EXIT;
	
	_WriteLog("--------------------\n");
	snprintf(msg, 256, "Track No.%lu\n", trackNo);
	_WriteLog(msg);
	_WriteLog("--------------------\n");
	_WriteLog("Chunk Type : MTrk\n");
	snprintf(msg, 256, "Length     : %lu\n", pChunkTypeSection->chunkSize);
	_WriteLog(msg);
	_WriteLog("Delta Time | Event\n");
	
EXIT:;
	return result;
}

//******************************************************************************
// ログ出力：デルタタイム
//******************************************************************************
int SMFileReader::_WriteLogDeltaTime(
		unsigned long deltaTime
	)
{
	int result = 0;
	char msg[256];
	
	if (!m_IsLogOut) goto EXIT;
	
	snprintf(msg, 256, "%10lu | ", deltaTime);
	_WriteLog(msg);

EXIT:;
	return result;
}

//******************************************************************************
// ログ出力：MIDIイベント
//******************************************************************************
int SMFileReader::_WriteLogEventMIDI(
		unsigned char status,
		unsigned char* pData,
		unsigned long size
	)
{
	int result = 0;
	const char* cmd = NULL;
	char msg[256];
	
	if (!m_IsLogOut) goto EXIT;
	
	switch (status & 0xF0) {
		case 0x80: cmd = "Note Off";				break;
		case 0x90: cmd = "Note On";					break;
		case 0xA0: cmd = "Polyphonic Key Pressure";	break;
		case 0xB0: cmd = "Control Change";			break;
		case 0xC0: cmd = "Program Change";			break;
		case 0xD0: cmd = "Channel Pressure";		break;
		case 0xE0: cmd = "PitchBend";				break;
		default:   cmd = "unknown";					break;
	}
	
	snprintf(msg, 256, "MIDI: ch.%d cmd=<%s>", (status & 0x0F), cmd);
	_WriteLog(msg);
	
	if (size == 2) {
		snprintf(msg, 256, " data=[ %02X %02X %02X ]\n", status, pData[0], pData[1]);
	}
	else {
		snprintf(msg, 256, " data=[ %02X %02X ]\n", status, pData[0]);
	}
	_WriteLog(msg);
	
EXIT:;
	return result;
}

//******************************************************************************
// ログ出力：SysExイベント
//******************************************************************************
int SMFileReader::_WriteLogEventSysEx(
		unsigned char status,
		unsigned char* pData,
		unsigned long size
	)
{
	int result = 0;
	char msg[256];
	unsigned long i = 0;
	
	if (!m_IsLogOut) goto EXIT;
	
	snprintf(msg, 256, "SysEx: status=%02X size=%lu data=[", status, size);
	_WriteLog(msg);
	
	for (i = 0; i < size; i++) {
		snprintf(msg, 256, " %02X", pData[i]);
		_WriteLog(msg);
	}
	_WriteLog(" ]\n");
	
EXIT:;
	return result;
}

//******************************************************************************
// ログ出力：メタイベント
//******************************************************************************
int SMFileReader::_WriteLogEventMeta(
		unsigned char status,
		unsigned char type,
		unsigned char* pData,
		unsigned long size
	)
{
	int result = 0;
	const char* cmd = NULL;
	char msg[256];
	unsigned long i = 0;
	
	if (!m_IsLogOut) goto EXIT;
	
	switch (type) {
		case 0x00: cmd = "Sequence Number";					break;
		case 0x01: cmd = "Text Event";						break;
		case 0x02: cmd = "Copyright Notice";				break;
		case 0x03: cmd = "Sequence/Track Name";				break;
		case 0x04: cmd = "Instrument Name";					break;
		case 0x05: cmd = "Lyric";							break;
		case 0x06: cmd = "Marker";							break;
		case 0x07: cmd = "Cue Point";						break;
		case 0x08: cmd = "Program Name";					break;
		case 0x09: cmd = "Device Name";						break;
		case 0x21: cmd = "Port Number (Undocumented)";		break;
		case 0x2F: cmd = "End of Track";					break;
		case 0x51: cmd = "Set Tempo";						break;
		case 0x54: cmd = "SMPTE Offset";					break;
		case 0x58: cmd = "Time Signature";					break;
		case 0x59: cmd = "Key Signature";					break;
		case 0x7F: cmd = "Sequencer-Specific Meta-Event";	break;
		default:   cmd = "<unknown>";						break;
	}
	
	snprintf(msg, 256, "Meta: status=%02X type=%02X<%s> size=%lu data=[", status, type, cmd, size);
	_WriteLog(msg);
	
	for (i = 0; i < size; i++) {
		snprintf(msg, 256, " %02X", pData[i]);
		_WriteLog(msg);
	}
	_WriteLog(" ]\n");
	
EXIT:;
	return result;
}


