//******************************************************************************
//
// MIDITrail / MTMachTime
//
// Mach時間クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <mach/mach_time.h>


//******************************************************************************
// Mach時間クラス
//******************************************************************************
class MTMachTime
{
public:
	
	//コンストラクタ／デストラクタ
	MTMachTime(void);
	virtual ~MTMachTime(void);
	
	//初期化
	int Initialize();
	
	//現在時刻取得（ナノ秒）
	uint64_t GetCurTimeInNanosec();
	
	//現在時刻取得（ミリ秒）
	uint64_t GetCurTimeInMsec();
	
	//待機（ナノ秒）
	void waitInNanosec(uint64_t nanosec);
	
	//待機（ミリ秒）
	void waitInMsec(uint64_t msec);
	
private:
	
	mach_timebase_info_data_t m_TimebaseInfo;
	
};


