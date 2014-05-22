//******************************************************************************
//
// Simple MIDI Library / SMAppleDLSDevCtrl
//
// Apple DLS (Downloadable Sounds) デバイス制御クラス
//
// Copyright (C) 2010-2011 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>


//******************************************************************************
// Apple DLS (Downloadable Sounds) デバイス制御クラス
//******************************************************************************
class SMAppleDLSDevCtrl
{
public:
	
	//コンストラクタ／デストラクタ
	SMAppleDLSDevCtrl();
	virtual ~SMAppleDLSDevCtrl();
	
	//初期化
	int Initialize();
	
	//デバイスオープン
	int Open();
	
	//デバイスクローズ
	int Close();
	
	//終了
	//void Terminate();
	
	//MIDI出力メッセージ送信
	int SendShortMsg(unsigned char* pMsg, unsigned long size);
	int SendLongMsg(unsigned char* pMsg, unsigned long size);
	int NoteOffAll();
	
private:
	
	//オーディオ処理グラフ
	AUGraph m_AUGraph;
	
	//出力ユニット
	AudioUnit m_UnitOut;
	
	//コントロール番号サポート情報
	unsigned char m_ControlNoSupport[128];
	
private:
	
	//オーディオ処理グラフ生成
	int _CreateAUGraph(AUGraph* pAUGraph, AudioUnit* pUnitOut);
	
	//コントロール番号サポート情報初期化
	void _InitControlNoSupport();
	
};


