//******************************************************************************
//
// MIDITrail / MTMachTime
//
// Mach時間クラス
//
// Copyright (C) 2010 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import "YNBaseLib.h"
#import "MTMachTime.h"


//******************************************************************************
// コンストラクタ
//******************************************************************************
MTMachTime::MTMachTime(void)
{
	memset(&m_TimebaseInfo, 0, sizeof(mach_timebase_info_data_t));
}

//******************************************************************************
// デストラクタ
//******************************************************************************
MTMachTime::~MTMachTime(void)
{
}

//******************************************************************************
// 初期化
//******************************************************************************
int MTMachTime::Initialize()
{
	int result = 0;
	kern_return_t kresult = 0;
	
	//タイムベース情報取得
	//  struct mach_timebase_info {
    //      uint32_t numer;
    //      uint32_t denom;
	//  };
	kresult = mach_timebase_info(&m_TimebaseInfo);
	if (kresult != KERN_SUCCESS) {
		result = YN_SET_ERR(@"MACH API error.", kresult, 0);
		goto EXIT;
	}
	
	// mach_absolute_time()をナノ秒単位に変換する場合は
	// mach_absolute_time() * number / denom
	
	// Core2 Duo 1.83GHz では numer = 1, denom = 1 が返された
	// iPhone3GS では numer = 125, denom = 3 が返されるらしい
	
EXIT:;
	return result;
}

//******************************************************************************
// 現在時刻取得（ナノ秒）
//******************************************************************************
uint64_t MTMachTime::GetCurTimeInNanosec()
{
	return (mach_absolute_time() * m_TimebaseInfo.numer / m_TimebaseInfo.denom);
}

//******************************************************************************
// 現在時刻取得（ミリ秒）
//******************************************************************************
uint64_t MTMachTime::GetCurTimeInMsec()
{
	return (GetCurTimeInNanosec() / 1000000);
}

//******************************************************************************
// 待機（ナノ秒）
//******************************************************************************
void MTMachTime::waitInNanosec(uint64_t nanosec)
{
	uint64_t machWaitTime = 0;
	
	//待機時間
	machWaitTime = nanosec * m_TimebaseInfo.denom / m_TimebaseInfo.numer;
	
	//待機
	mach_wait_until(mach_absolute_time() + machWaitTime);
}

//******************************************************************************
// 待機（ミリ秒）
//******************************************************************************
void MTMachTime::waitInMsec(uint64_t msec)
{
	waitInNanosec(msec * 1000000);
}


