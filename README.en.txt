**********************************************************************

  MIDITrail source code Ver.1.2.1 for Mac OS X

  Copyright (C) 2010-2013 WADA Masashi. All Rights Reserved.

  Web : http://sourceforge.jp/projects/miditrail/
  Mail: yknk@users.sourceforge.jp

**********************************************************************

(1) Introduction

  This is the entire source code of MIDITrail for Mac OS X.

(2) Development environment

  Mac OS X 10.7.5 (Lion)
  Xcode 4.4.1

(3) Folders

  Sources/MIDITrail
    The application project.
    It implements the processing of rendering by OpenGL.
    It uses "OGLUtility", "SMIDILib" and "YNBaseLib".

  Source/OGLUtility
    The OpenGL Utility project.
    It implements the wrapping for OpenGL APIs.
    It uses "YNBaseLib".

  Sources/SMIDILib
    The Simple MIDI Library project.
    It implements the processing of MIDI control and analyzing note informantion.
    It uses "YNBaseLib".

  Sources/YNBaseLib
    The Basic Library Project.
    It implements the error control and utility functions.

(4) License

  MIDITrail is released under the BSD license.
  Please check "LICENSE.txt".


