//******************************************************************************
//
// MIDITrail / MTMainView
//
// メインビュー制御クラス
//
// Copyright (C) 2010-2012 WADA Masashi. All Rights Reserved.
//
//******************************************************************************

#import <Cocoa/Cocoa.h>
#import "SMIDILib.h"
#import "OGLUtil.h"
#import "MTMachTime.h"
#import "MTScene.h"
#import "MTMenuCtrl.h"
#import "MTSceneMsgQueue.h"
#import "DIKeyCtrl.h"


//******************************************************************************
// メインビュー制御クラス
//******************************************************************************
@interface MTMainView : NSOpenGLView {
	
	//描画制御系
	CGLContextObj m_CGLContext;
	OGLRenderer m_Renderer;
	OGLRedererParam m_RendererParam;
	MTScene* m_pScene;
	MTMachTime m_MachTime;
	
	//メッセージ制御系
	SMMsgQueue* m_pMsgQueue;
	MTSceneMsgQueue m_SceneMsgQueue;
	BOOL m_isStopScene;
	
	//画面制御系
	MTMenuCtrl* m_pMenuCtrl;
	float m_FPS;
	
	//ドラッグ処理系
	BOOL m_isDragAcceptable;
	BOOL m_isDragging;
	
	//キーボード情報
	DIKeyCtrl m_DIKeyCtrl;
	
	//モニタフラグ
	BOOL m_isMonitor;
	
}

//--------------------------------------
// NSView 属性設定

//ファーストレスポンダ受け入れ
- (BOOL)acceptsFirstResponder;

//OpenGL初期化
- (void)prepareOpenGL;

//--------------------------------------
// 公開I/F

//生成
- (id)initWithFrame:(NSRect)frameRect rendererParam:(OGLRedererParam)rendererParam;

//初期化処理
- (int)initialize:(SMMsgQueue*)pMsgQueue menuCtrl:(MTMenuCtrl*)pMenuCtrl;

//終了処理
- (void)terminate;

//描画デバイス取得
- (OGLDevice*)getDevice;

//シーン開始
- (int)startScene:(MTScene*)pScene isMonitor:(BOOL)isMonitor;

//シーン停止
- (int)stopScene;

//シーン操作：演奏開始
- (int)scene_PlayStart;

//シーン操作：演奏終了
- (int)scene_PlayEnd;

//シーン操作：巻き戻し
- (int)scene_Rewind;

//シーン操作：視点リセット
- (int)scene_ResetViewpoint;

//シーン操作：視点登録
- (int)scene_SetViewpoint:(MTScene::MTViewParamMap*)pParamMap;

//シーン操作：視点取得
- (int)scene_GetViewpoint:(MTScene::MTViewParamMap*)pParamMap;

//シーン操作：エフェクト設定
- (int)scene_SetEffect:(MTScene::EffectType)type isEnable:(bool)isEnable;

//シーン操作：マウスクリックイベント
- (int)scene_OnMouseClick:(unsigned long)button;

//シーン操作：マウスホイールイベント
- (int)scene_OnMouseWheelWithDeltaX:(float)dX deltaY:(float)dY deltaZ:(float)dZ;

//アプリケーションアクティブ状態設定
- (void)setActiveState:(BOOL)isActive;

//ドラッグ許可設定
- (void)setDragAcceptable:(BOOL)isAcceptable;

//FPS取得
- (float)FPS;

//--------------------------------------
// シーン描画スレッド

//シーンスレッド
- (void)thread_DrawScene:(id)sender;

//描画処理
- (int)thread_DrawProc;

//シーケンサメッセージ処理
- (int)thread_SequencerMsgProc;

//シーンメッセージ処理
- (int)thread_SceneMsgProc;

// シーンメッセージ実行
- (int)thread_ExecSceneMsg:(MTSceneMsg*)pMsg;

//演奏状態変更通知受信処理
- (int)thread_PostPlayStatus:(NSString*)pNotificationName;

//待機
- (void)thread_WaitInterval:(uint64_t)startTime;

//FPS更新
- (void)thread_UpdateFPS:(uint64_t)startTime;

//--------------------------------------
// イベントハンドラ

//キー押下イベント
- (void)keyDown:(NSEvent*)theEvent;

//マウス左クリックイベント
- (void)mouseDown:(NSEvent*)theEvent;

//マウス右クリックイベント
- (void)rightMouseDown:(NSEvent*)theEvent;

//マウス中ボタン押下イベント
- (void)otherMouseDown:(NSEvent*)theEvent;

//マウスクリックイベント通知処理
- (int)scene_OnMouseClick:(unsigned long)button;

//マウスホイールイベント
- (void)scrollWheel:(NSEvent*)theEvent;

//ファイルドロップ対応
- (unsigned int)draggingEntered:(id)sender;
- (unsigned int)draggingUpdated:(id)sender;
- (void)draggingExited:(id)sender;
- (BOOL)prepareForDragOperation:(id)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id)sender;
- (BOOL)isAcceptableObject:(id)sender path:(NSString**)pPathPtr;


@end


