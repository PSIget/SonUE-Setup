#ifndef _H_WINDOWS_
#define _H_WINDOWS_

[code]
#define API_ENCODING defined(UNICODE) ? "W" : "A"

#if !defined(IS_ENHANCED)
type
  TMsg = record
    hwnd: HWND;
    message: LongWord;
    wParam: Longint;
    lParam: Longint;
    time: LongWord;
    pt: TPoint;
  end;
#endif

const
  CP_ACP    = 0;
  CP_UTF8   = 65001;

  VK_ESCAPE = 27;

Function OemToChar(lpszSrc, lpszDst: AnsiString): longint; external 'OemToCharA@user32.dll stdcall';
Function MultiByteToWideChar(CodePage: UINT; dwFlags: DWORD; lpMultiByteStr: PAnsiChar; cbMultiByte: integer; lpWideCharStr: PAnsiChar; cchWideChar: integer): longint; external 'MultiByteToWideChar@kernel32.dll stdcall';
Function WideCharToMultiByte(CodePage: UINT; dwFlags: DWORD; lpWideCharStr: PAnsiChar; cchWideChar: integer; lpMultiByteStr: PAnsiChar; cbMultiByte: integer; lpDefaultChar: integer; lpUsedDefaultChar: integer): longint; external 'WideCharToMultiByte@kernel32.dll stdcall';

function PeekMessage(var lpMsg: TMsg; hWnd: HWND; wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL; external 'PeekMessageA@user32.dll stdcall';
function TranslateMessage(const lpMsg: TMsg): BOOL; external 'TranslateMessage@user32.dll stdcall';
function DispatchMessage(const lpMsg: TMsg): Longint; external 'DispatchMessageA@user32.dll stdcall';

function GetTickCount: DWord; external 'GetTickCount@kernel32';
function GetWindowLong(hWnd, nIndex: Integer): Longint; external 'GetWindowLongA@user32 stdcall delayload';
function SetWindowText(hWnd: Longint; lpString: String): Longint; external 'SetWindowText{#API_ENCODING}@user32 stdcall delayload';
function GetKeyState(nVirtKey: Integer): ShortInt; external 'GetKeyState@user32 stdcall delayload';

procedure AppProcessMessage;
var
  Msg: TMsg;
begin
  if (not PeekMessage(Msg, 0, 0, 0, 1)) then
    Exit;

  TranslateMessage(Msg);
  DispatchMessage(Msg);
end;

function OemToAnsiStr(strSource: AnsiString): AnsiString;
begin
  SetLength(Result, Length(strSource));
  OemToChar(strSource, Result);
end;

function AnsiToUtf8(strSource: string): string;
var
  nRet: integer;
  WideCharBuf, MultiByteBuf: AnsiString;
begin
  SetLength(WideCharBuf, Length(strSource) * 2);
  SetLength(MultiByteBuf, Length(strSource) * 2);
  MultiByteToWideChar(CP_ACP, 0, strSource, -1, WideCharBuf, Length(WideCharBuf));
  nRet:= WideCharToMultiByte(CP_UTF8, 0, WideCharBuf, -1, MultiByteBuf, Length(MultiByteBuf), 0, 0);
  Result:= Copy(MultiByteBuf, 1, nRet);
end;
#endif