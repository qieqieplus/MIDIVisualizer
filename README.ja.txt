**********************************************************************

  MIDITrail ソースコード Ver.1.2.1 for Mac OS X

  Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.

  Web : http://sourceforge.jp/projects/miditrail/
  Mail: yknk@users.sourceforge.jp

**********************************************************************

(1) 概要

  MIDITrail for Mac OS X の全ソースコードです。

(2) ビルド環境

  Mac OS X 10.7.5 (Lion)
  Xcode 4.4.1

(3) フォルダ構成

  Sources/MIDITrail
    アプリケーション本体のプロジェクトです。
    OpenGLを用いた描画処理を実装しています。
    OGLUtility, SMIDILib, YNBaseLib を利用しています。

  Source/OGLUtility
    OpenGLユーティリティのプロジェクトです。
    OpenGL APIのラッパークラスを実装しています。
    YNBaseLib を利用しています。

  Sources/SMIDILib
    シンプルMIDIライブラリのプロジェクトです。
    MIDIデータの再生とノート情報参照に特化したライブラリです。
    YNBaseLib を利用しています。

  Sources/YNBaseLib
    基本ライブラリのプロジェクトです。
    エラー制御やユーティリティ関数を含んでいます。

(4) ライセンス

  修正BSDライセンスを適用して公開しています。 
  詳細は LICENSE.txt を参照してください。


