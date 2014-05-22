//******************************************************************************
//
// MIDITrail / MTMainView
//
// メインビュー制御クラス
//
// Copyright (C) 2010-2012 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <CoreAudio/CoreAudio.h>
#import "YNBaseLib.h"
#import "DIKeyDef.h"
#import "MTMainView.h"


@implementation MTMainView

//******************************************************************************
// 生成
//******************************************************************************
- (id)initWithFrame:(NSRect)frameRect rendererParam:(OGLRedererParam)rendererParam
{
	NSOpenGLPixelFormat *pPixelFormat = nil;
	NSOpenGLPixelFormatAttribute attrbSampleMode = 0;
	NSOpenGLPixelFormatAttribute attributes[16];
	
	m_RendererParam = rendererParam;
	
	//ビュー生成時に設定するピクセルフォーマットを制御することで
	//アンチエイリアシングの有効／無効を切り替える
	
	//アンチエイリアシング：サンプルモード
	if (rendererParam.isEnableAntialiasing) {
		if (rendererParam.sampleMode == kCGLSupersampleBit) {
			attrbSampleMode = NSOpenGLPFASupersample;
		}
		else if (rendererParam.sampleMode == kCGLMultisampleBit) {
			attrbSampleMode = NSOpenGLPFAMultisample;
		}
	}
	
	//ピクセルフォーマット属性
	attributes[0]  = NSOpenGLPFAWindow,			//ウィンドウ表示
	attributes[1]  = NSOpenGLPFAColorSize;		//カラーバッファビット数
	attributes[2]  = 32;						//  設定値
	attributes[3]  = NSOpenGLPFAAlphaSize;		//アルファコンポーネントビット数
	attributes[4]  = 8;							//  設定値
	attributes[5]  = NSOpenGLPFADepthSize;		//深度バッファビット数
	attributes[6]  = 32;						//  設定値
	attributes[7]  = NSOpenGLPFADoubleBuffer;	//ダブルバッファピクセルフォーマット選択
	attributes[8]  = NSOpenGLPFAAccelerated;	//ハードウェアレンダリング
	attributes[9]  = NSOpenGLPFANoRecovery;		//リカバリシステム無効
	attributes[10] = 0;							//終端
	if (rendererParam.isEnableAntialiasing) {
		attributes[10] = attrbSampleMode;			//アンチエイリアシング：サンプルモード
		attributes[11] = NSOpenGLPFASampleBuffers;	//マルチサンプルバッファ
		attributes[12] = 1;							//  設定値
		attributes[13] = NSOpenGLPFASamples;		//マルチサンプルバッファごとのサンプル数
		attributes[14] = rendererParam.sampleNum;	//  設定値
		attributes[15] = 0;							//終端
	}
	
	//ピクセルフォーマット生成
	pPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
	[pPixelFormat autorelease];
	
	//ビュー生成
	return [super initWithFrame:frameRect pixelFormat:pPixelFormat];
}

//******************************************************************************
// 破棄
//******************************************************************************
- (void)dealloc
{
	//NSLog(@"MTMainView dealloc");
	[super dealloc];
}

//******************************************************************************
// ファーストレスポンダ受け入れ
//******************************************************************************
- (BOOL)acceptsFirstResponder {
	//ファーストレスポンダを受け入れる
	//キー押下時にポンと音が鳴ってしまうためkeyDownをオーバライドする必要がある
	return YES;
}

//******************************************************************************
// OpenGL初期化
//******************************************************************************
- (void)prepareOpenGL
{
	m_CGLContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
}

//******************************************************************************
// 初期化処理
//******************************************************************************
- (int)initialize:(SMMsgQueue*)pMsgQueue
		 menuCtrl:(MTMenuCtrl*)pMenuCtrl
{
	int result = 0;
	
	//メッセージキュー
	m_pMsgQueue = pMsgQueue;
	
	//メインメニュー制御
	m_pMenuCtrl = pMenuCtrl;
	
	//レンダラ初期化
	result = m_Renderer.Initialize(self, m_RendererParam);
	if (result != 0) goto EXIT;
	
	//時間初期化
	result = m_MachTime.Initialize();
	if (result != 0) goto EXIT;
	
	//ドロップを許可するデータタイプを設定：ファイルパス
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	//ドラッグ状態フラグ
	m_isDragAcceptable = NO;
	m_isDragging = NO;
	
	//キー入力制御初期化
	result = m_DIKeyCtrl.Initialize(nil);
	if (result != 0) goto EXIT;
	
	//モニタ状態
	m_isMonitor = NO;
	
EXIT:;
	return result;
}

//******************************************************************************
// 終了処理
//******************************************************************************
- (void)terminate
{
	//レンダラ終了
	m_Renderer.Terminate();
	
	//キー入力制御終了
	m_DIKeyCtrl.Terminate();
}

//******************************************************************************
// デバイス取得
//******************************************************************************
- (OGLDevice*)getDevice
{
	return m_Renderer.GetDevice();
}

//******************************************************************************
// シーン開始
//******************************************************************************
- (int)startScene:(MTScene*)pScene
		isMonitor:(BOOL)isMonitor
{
	int result = 0;
	
	//シーンオブジェクト
	m_pScene = pScene;
	
	//モニタフラグ
	m_isMonitor = isMonitor;
	
	//シーンメッセージキューをクリア
	m_SceneMsgQueue.Clear();
	
	//描画スレッド起動
	[NSThread detachNewThreadSelector:@selector(thread_DrawScene:)
							 toTarget:self
						   withObject:nil];
	
	return result;
}

//******************************************************************************
// シーン停止
//******************************************************************************
- (int)stopScene
{
	int result = 0;
	MTSceneMsgStopScene* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgStopScene();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//メッセージ通知：同期
	result = m_SceneMsgQueue.SendMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//同期の場合メッセージの破棄は送信側で行う
	delete pMsg;
	return result;
}

//******************************************************************************
// シーン操作：演奏開始
//******************************************************************************
- (int)scene_PlayStart
{
	int result = 0;
	MTSceneMsgPlayStart* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgPlayStart();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// シーン操作：演奏終了
//******************************************************************************
- (int)scene_PlayEnd
{
	int result = 0;
	MTSceneMsgPlayEnd* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgPlayEnd();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// シーン操作：巻き戻し
//******************************************************************************
- (int)scene_Rewind
{
	int result = 0;
	MTSceneMsgRewind* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgRewind();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// シーン操作：視点リセット
//******************************************************************************
- (int)scene_ResetViewpoint
{
	int result = 0;
	MTSceneMsgResetViewpoint* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgResetViewpoint();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// シーン操作：視点登録
//******************************************************************************
- (int)scene_SetViewpoint:(MTScene::MTViewParamMap*)pParamMap
{
	int result = 0;
	MTSceneMsgSetViewpoint* pMsg = NULL;
	MTScene::MTViewParamMap* pDestPramMap = NULL;
	MTScene::MTViewParamMap::iterator itr;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgSetViewpoint();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//指定された視点情報をメッセージにコピーする
	pDestPramMap = pMsg->GetViewParamMapPtr();
	for (itr = pParamMap->begin(); itr != pParamMap->end(); itr++) {
		pDestPramMap->insert(MTScene::MTViewParamMapPair((itr->first).c_str(), itr->second));
	}
	
	//メッセージ通知：同期
	result = m_SceneMsgQueue.SendMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//同期の場合メッセージの破棄は送信側で行う
	delete pMsg;
	return result;
}

//******************************************************************************
// シーン操作：視点取得
//******************************************************************************
- (int)scene_GetViewpoint:(MTScene::MTViewParamMap*)pParamMap
{
	int result = 0;
	MTSceneMsgGetViewpoint* pMsg = NULL;
	MTScene::MTViewParamMap* pSrcPramMap = NULL;
	MTScene::MTViewParamMap::iterator itr;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgGetViewpoint();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	//メッセージ通知：同期
	result = m_SceneMsgQueue.SendMessage(pMsg);
	if (result != 0) goto EXIT;
	
	//取得した視点情報をコピーして返す
	pParamMap->clear();
	pSrcPramMap = pMsg->GetViewParamMapPtr();
	for (itr = pSrcPramMap->begin(); itr != pSrcPramMap->end(); itr++) {
		pParamMap->insert(MTScene::MTViewParamMapPair((itr->first).c_str(), itr->second));
	}
	
EXIT:;
	//同期の場合メッセージの破棄は送信側で行う
	delete pMsg;
	return result;
}

//******************************************************************************
// シーン操作：エフェクト設定
//******************************************************************************
- (int)scene_SetEffect:(MTScene::EffectType)type isEnable:(bool)isEnable
{
	int result = 0;
	MTSceneMsgSetEffect* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgSetEffect();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	pMsg->SetEffect(type, isEnable);
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// シーン操作：マウスクリックイベント
//******************************************************************************
- (int)scene_OnMouseClick:(unsigned long)button
{
	int result = 0;
	MTSceneMsgOnMouseClick* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgOnMouseClick();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	pMsg->SetClickButton(button);
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// マウスホイールイベント
//******************************************************************************
- (int)scene_OnMouseWheelWithDeltaX:(float)dX deltaY:(float)dY deltaZ:(float)dZ
{
	int result = 0;
	MTSceneMsgOnMouseWheel* pMsg = NULL;
	
	//メッセージ生成
	try {
		pMsg = new MTSceneMsgOnMouseWheel();
	}
	catch (std::bad_alloc) {
		result = YN_SET_ERR(@"Could not allocate memory.", 0, 0);
		goto EXIT;
	}
	
	pMsg->SetWheelDelta(dX, dY, dZ);
	
	//メッセージ通知：非同期
	result = m_SceneMsgQueue.PostMessage(pMsg);
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	return result;
}

//******************************************************************************
// シーン描画スレッド
//******************************************************************************
- (void)thread_DrawScene:(id)sender
{
	int result = 0;
	uint64_t startTime = 0;
	NSAutoreleasePool* pool;
	
	//NSLog(@"thread_DrawScene start");
	
	pool = [[NSAutoreleasePool alloc]init];
	
	m_isStopScene = NO;
	
	//初回描画
	//  描画処理を実施する前に m_pScene->OnPlayStart() などを実行すると
	//  OpenGL API で EXC_BAD_ACCESS が発生する
	result = [self thread_DrawProc];
	if (result != 0) goto EXIT;
	
	//描画処理ループ
	while (YES) {
		
		//描画処理開始時刻
		startTime = m_MachTime.GetCurTimeInNanosec();
		
		//シーケンサメッセージ処理
		result = [self thread_SequencerMsgProc];
		if (result != 0) goto EXIT;
		
		//シーンメッセージ処理
		result = [self thread_SceneMsgProc];
		if (result != 0) goto EXIT;
		
		//シーン停止を要求された場合はスレッド終了
		if (m_isStopScene) break;
		
		//描画
		result = [self thread_DrawProc];
		if (result != 0) goto EXIT;
		
		//待機
		[self thread_WaitInterval:startTime];
		
		//FPS更新
		[self thread_UpdateFPS:startTime];
	}
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
	//NSLog(@"thread_DrawScene end");
	[pool release];
	[NSThread exit];
}

//******************************************************************************
// 描画処理
//******************************************************************************
- (int)thread_DrawProc
{
	int result = 0;
	
	//ウィンドウ表示中のみレンダリングを行う
	if ([[self window] isVisible]) {
		//コンテキストロック
		CGLLockContext(m_CGLContext);
		CGLSetCurrentContext(m_CGLContext);
		//レンダリング
		result = m_Renderer.RenderScene((OGLScene*)m_pScene);
		if (result != 0) {
			YN_SHOW_ERR();
		}
		//コンテキストロック解除
		CGLFlushDrawable(m_CGLContext);
		CGLUnlockContext(m_CGLContext);
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// シーケンサメッセージ処理
//******************************************************************************
- (int)thread_SequencerMsgProc
{
	int result = 0;
	bool isExist = false;
	unsigned long wParam = 0;
	unsigned long lParam = 0;
	SMMsgParser parser;
	
	while (YES) {
		//メッセージ取り出し
		result = m_pMsgQueue->GetMessage(&isExist, &wParam, &lParam);
		if (result != 0) goto EXIT;
		
		//メッセージがなければ終了
		if (!isExist) break;
		
		//メッセージ通知
		result = m_pScene->OnRecvSequencerMsg(wParam, lParam);
		if (result != 0) goto EXIT;	
		
		//演奏状態変更通知への対応
		parser.Parse(wParam, lParam);
		if (parser.GetMsg() == SMMsgParser::MsgPlayStatus) {
			//一時停止
			if (parser.GetPlayStatus() == SMMsgParser::StatusPause) {
				[self thread_PostPlayStatus:@"onChangePlayStatusPause"];
			}
			//停止（演奏終了）
			else if (parser.GetPlayStatus() == SMMsgParser::StatusStop) {
				[self thread_PostPlayStatus:@"onChangePlayStatusStop"];
			}
		}
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// シーンメッセージ処理
//******************************************************************************
- (int)thread_SceneMsgProc
{
	int result = 0;
	bool isExist = false;
	MTSceneMsg* pMsg = NULL;
	
	//描画スレッド実行中はシーンオブジェクトを描画スレッドが占有する
	//他のスレッドからシーンオブジェクトを直接操作してはならない
	//描画スレッドは描画前にキューに登録されたメッセージをすべて処理する
	
	while (YES) {
		//メッセージ取り出し
		result = m_SceneMsgQueue.GetMessage(&isExist, &pMsg);
		if (result != 0) goto EXIT;
		
		//メッセージがなければ終了
		if (!isExist) break;
		
		//メッセージに対応する処理を実行
		result = [self thread_ExecSceneMsg:pMsg];
		if (result != 0) goto EXIT;
		
		//メッセージ処理応答
		if (pMsg->IsSyncMode()) {
			//同期モード：応答する
			//  メッセージ破棄は呼び出し側で行う
			pMsg->WakeUp();
		}
		else {
			//非同期モード
			//  メッセージ破棄は受け取り側で行う
			delete pMsg;
			pMsg = NULL;
		}
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// シーンメッセージ実行
//******************************************************************************
- (int)thread_ExecSceneMsg:(MTSceneMsg*)pMsg
{
	int result = 0;
	MTSceneMsgSetViewpoint* pMsgSetViewpoint = NULL;
	MTSceneMsgGetViewpoint* pMsgGetViewpoint = NULL;
	MTSceneMsgSetEffect* pMsgSetEffect = NULL;
	MTSceneMsgOnMouseClick* pMsgOnMouseClick = NULL;
	MTSceneMsgOnMouseWheel* pMsgOnMouseWheel = NULL;
	MTScene::EffectType type;
	bool isEnable = false;
	float deltaWheelX, deltaWheelY, deltaWheelZ = 0.0f;
	
	//オブジェクト指向的には残念な実装であるが
	//シーンオブジェクトへの操作が見通せるようにする
	
	switch (pMsg->GetMsgId()) {
		//演奏開始
		case MTSCENEMSG_PLAY_START:
			result = m_pScene->OnPlayStart();
			break;
		//演奏終了
		case MTSCENEMSG_PLAY_END:
			result = m_pScene->OnPlayEnd();
			break;
		//巻き戻し
		case MTSCENEMSG_REWIND:
			result = m_pScene->Rewind();
			break;
		//視点リセット
		case MTSCENEMSG_RESET_VIEWPOINT:
			m_pScene->ResetViewpoint();
			break;
		//視点登録
		case MTSCENEMSG_SET_VIEWPOINT:
			pMsgSetViewpoint = (MTSceneMsgSetViewpoint*)pMsg;
			m_pScene->SetViewParam(pMsgSetViewpoint->GetViewParamMapPtr());
			break;
		//視点取得
		case MTSCENEMSG_GET_VIEWPOINT:
			pMsgGetViewpoint = (MTSceneMsgGetViewpoint*)pMsg;
			m_pScene->GetViewParam(pMsgGetViewpoint->GetViewParamMapPtr());
			break;
		//エフェクト設定
		case MTSCENEMSG_SET_EFFECT:
			pMsgSetEffect = (MTSceneMsgSetEffect*)pMsg;
			pMsgSetEffect->GetEffect(&type, &isEnable);
			m_pScene->SetEffect(type, isEnable);
			break;
		//マウスクリックイベント
		case MTSCENEMSG_ON_MOUSE_CLICK:
			pMsgOnMouseClick = (MTSceneMsgOnMouseClick*)pMsg;
			m_pScene->OnWindowClicked(pMsgOnMouseClick->GetClickButton(), 0, 0);
			break; 
		//マウスホイールイベント
		case MTSCENEMSG_ON_MOUSE_WHEEL:
			pMsgOnMouseWheel = (MTSceneMsgOnMouseWheel*)pMsg;
			pMsgOnMouseWheel->GetWheelDelta(&deltaWheelX, &deltaWheelY, &deltaWheelZ);
			m_pScene->OnScrollWheel(deltaWheelX, deltaWheelY, deltaWheelZ);
			break;
		//シーン停止
		case MTSCENEMSG_STOP_SCENE:
			m_isStopScene = YES;
			break;
		default:
			break;
	}
	
EXIT:;
	return result;
}

//******************************************************************************
// 演奏状態変更通知受信処理
//******************************************************************************
- (int)thread_PostPlayStatus:(NSString*)pNotificationName
{
	int result = 0;
	NSNotification* pNotification = nil;
	NSNotificationCenter* pCenter = nil;
	
	//通知オブジェクトを作成
    pNotification = [NSNotification notificationWithName:pNotificationName
												 object:self
											   userInfo:nil];
	//通知する
	pCenter = [NSNotificationCenter defaultCenter];
	
	//通知に対応する処理を演奏スレッドで処理させる場合
	//[pCenter postNotification:pNotification];
	
	//通知に対応する処理をメインスレッドに処理させる場合
	[pCenter performSelectorOnMainThread:@selector(postNotification:)
							  withObject:pNotification
						   waitUntilDone:NO];
	
	return result;
}

//******************************************************************************
// 待機
//******************************************************************************
- (void)thread_WaitInterval:(uint64_t)startTime
{
	uint64_t curTime = 0;
	uint64_t diffTime = 0;
	uint64_t intervalTime = 0;
	uint64_t fps = 60;
	uint64_t waitTime = 0;
	
	//60FPSの時間間隔（ナノ秒）
	intervalTime = 1000000000 / fps;
	
	//現在時刻
	curTime = m_MachTime.GetCurTimeInNanosec();
	
	//描画処理にかかった時間（ナノ秒）
	diffTime = curTime - startTime;
	
	//60FPSの時間間隔よりも速く描画処理が終了したら次回の描画まで休む
	if (intervalTime > diffTime) {
		waitTime = intervalTime - diffTime;
		m_MachTime.waitInNanosec(waitTime);
	}
	
	return;
}

//******************************************************************************
// FPS更新
//******************************************************************************
- (void)thread_UpdateFPS:(uint64_t)startTime
{
	uint64_t curTime = 0;
	uint64_t diffTime = 0;
	
	//現在時刻
	curTime = m_MachTime.GetCurTimeInNanosec();
	
	//描画周期（ナノ秒）
	diffTime = curTime - startTime;
	
	//FPS算出
	m_FPS = (float)((double)(1000 * 1000000) / diffTime);
}

//******************************************************************************
// FPS取得
//******************************************************************************
- (float)FPS
{
	return m_FPS;
}

//******************************************************************************
// アプリケーションアクティブ状態設定
//******************************************************************************
- (void)setActiveState:(BOOL)isActive
{
	bool isActiveState = (isActive)? true : false;
	
	//シーンオブジェクトを直接操作しているが描画スレッドへの影響はない
	if (m_pScene != NULL) {
		m_pScene->SetActiveState(isActiveState);
	}
	m_DIKeyCtrl.SetActiveState(isActiveState);
}

//******************************************************************************
//ドラッグ許可設定
//******************************************************************************
- (void)setDragAcceptable:(BOOL)isAcceptable
{
	m_isDragAcceptable = isAcceptable;
}

//******************************************************************************
// キー押下イベント
//******************************************************************************
- (void)keyDown:(NSEvent*)theEvent
{
	unsigned short keycode = 0;
	
	//タイプされたキーのコード
	keycode = [theEvent keyCode];
	
	//NSLog(@"keyDown %d", keycode);
	
	//メインメニューの当該機能を呼び出す
	//メインメニュー選択操作と同一にする
	switch (keycode) {
		case DIK_SPACE:
		case DIK_NUMPAD0:
			if  (m_DIKeyCtrl.IsKeyDown(DIK_SHIFT)) {
				//モニタ開始
				[m_pMenuCtrl performActionStartMonitoring];
			}
			else {
				//演奏開始／一時停止
				[m_pMenuCtrl performActionPlay];
			}
			break;
		case DIK_ESCAPE:
		case DIK_NUMPADENTER:
			if (m_isMonitor) {
				//モニタ停止
				[m_pMenuCtrl performActionStopMonitoring];		
			}
			else {
				//演奏停止
				[m_pMenuCtrl performActionStop];
			}
			break;
		case DIK_1:
		case DIK_NUMPAD1:
			//再生リワインド
			[m_pMenuCtrl performActionSkipBack];
			break;
		case DIK_2:
		case DIK_NUMPAD2:
			//再生スキップ
			[m_pMenuCtrl performActionSkipForward];
			break;
		case DIK_4:
		case DIK_NUMPAD4:
			//再生スピードダウン
			[m_pMenuCtrl performActionPlaySpeedDown];
			break;
		case DIK_5:
		case DIK_NUMPAD5:
			//再生スピードアップ
			[m_pMenuCtrl performActionPlaySpeedUp];
			break;
	}
}

//******************************************************************************
// マウス左クリックイベント
//******************************************************************************
- (void)mouseDown:(NSEvent*)theEvent
{
	int result = 0;
	
	//NSLog(@"mouseDown");
	
	result = [self scene_OnMouseClick:WM_LBUTTONDOWN];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// マウス右クリックイベント
//******************************************************************************
- (void)rightMouseDown:(NSEvent*)theEvent
{
	int result = 0;
	
	//NSLog(@"rightMouseDown");
	
	result = [self scene_OnMouseClick:WM_RBUTTONDOWN];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// マウス中ボタン押下イベント
//******************************************************************************
- (void)otherMouseDown:(NSEvent*)theEvent
{
	int result = 0;
	
	//NSLog(@"otherMouseDown");
	
	result = [self scene_OnMouseClick:WM_MBUTTONDOWN];
	if (result != 0) goto EXIT;
	
EXIT:;
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
// マウスホイールイベント
//******************************************************************************
- (void)scrollWheel:(NSEvent*)theEvent;
{
	int result = 0;
	
	//NSLog(@"scrollWheel");
	
	result = [self scene_OnMouseWheelWithDeltaX:[theEvent deltaX]
										 deltaY:[theEvent deltaY]
										 deltaZ:[theEvent deltaZ]];
	if (result != 0) goto EXIT;
	
EXIT:;
	//メッセージの破棄は受信側で行う
	if (result != 0) YN_SHOW_ERR();
}

//******************************************************************************
//ファイルドロップ対応：ドラッグ中のマウスカーソルが領域内に入った
//******************************************************************************
- (unsigned int)draggingEntered:(id)sender
{
	BOOL isAcceptableObject = NO;
	NSDragOperation operation;
	NSString* pPath = nil;
	
	//受付可能か確認
	isAcceptableObject = [self isAcceptableObject:sender path:&pPath];
	
	//ドラッグ状態更新
	//ドラッグ許可状態でかつドラッグ可能なパスである場合のみ受け入れる
	if (m_isDragAcceptable && isAcceptableObject) {
		m_isDragging = YES;
		operation = NSDragOperationGeneric;
	}
	else {
		m_isDragging = NO;
		operation = NSDragOperationNone;
	}
	
	return operation;
}

//******************************************************************************
//ファイルドロップ対応：ドラッグ中のマウスカーソルが領域内で移動した
//******************************************************************************
- (unsigned int)draggingUpdated:(id)sender
{
	NSDragOperation operation;
	
	if (m_isDragging) {
		operation = NSDragOperationGeneric;
	}
	else {
		operation = NSDragOperationNone;
	}
	
	return operation;
}

//******************************************************************************
//ファイルドロップ対応：ドラッグ中のマウスカーソルが領域から外れた
//******************************************************************************
- (void)draggingExited:(id)sender
{
	m_isDragging = NO;
}

//******************************************************************************
//ファイルドロップ対応：ドロップされた
//******************************************************************************
- (BOOL)prepareForDragOperation:(id)sender
{
	return m_isDragging;
}

//******************************************************************************
//ファイルドロップ対応：ドロップ処理実行
//******************************************************************************
- (BOOL)performDragOperation:(id)sender
{
	BOOL isDropped = NO;
	BOOL isAcceptableObject = NO;
	NSString* pPath = nil;
	
	//受付可能か確認
	isAcceptableObject = [self isAcceptableObject:sender path:&pPath];
	
	//ドラッグ許可状態でかつドラッグ可能なパスである場合のみ受け入れる
	if (m_isDragAcceptable && isAcceptableObject) {
		//ファイルドロップイベント通知
		[m_pMenuCtrl onDropFile:pPath];
		isDropped = YES;
	}
	
	return isDropped;
}

//******************************************************************************
//ファイルドロップ対応：ドロップ処理完了通知
//******************************************************************************
- (void)concludeDragOperation:(id)sender
{
	//何もしない
}

//******************************************************************************
//ファイルドロップ対応：受け入れ可能判定
//******************************************************************************
- (BOOL)isAcceptableObject:(id)sender path:(NSString**)pPathPtr
{
	NSPasteboard *pPasteboard = nil;
	NSArray *pFileNameArray = nil;
	NSString* pPath = nil;
	BOOL isAcceptable = NO;
	BOOL isExist = NO;
	BOOL isDir = NO;
	
	//ペーストボードからパス配列を取得
	pPasteboard = [sender draggingPasteboard];
	pFileNameArray = [pPasteboard propertyListForType: NSFilenamesPboardType];
	
	//複数ファイルのドロップは無視する
	if ([pFileNameArray count] != 1) goto EXIT;
	
	//パスの取得
	pPath = [pFileNameArray objectAtIndex:0];
	
	//パスの存在確認
	isExist = [[NSFileManager defaultManager] fileExistsAtPath:pPath isDirectory:&isDir];
	if (!isExist) goto EXIT;
	
	//ディレクトリのドロップは無視する
	if (isDir) goto EXIT;
	
	isAcceptable = YES;
	*pPathPtr = pPath;
	
EXIT:;
	return isAcceptable;
}


@end


