[Code]
var
  SourceOfPaths: TArrayOfString;
const
  SteamRegistry = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 4500';
  GogRegistry = 'SOFTWARE\WOW6432Node\GOG.com\Games\1207660573';
  DVDRegistry = 'SOFTWARE\GSC Game World\STALKER-SHOC';

function CheckGameDirectory(Dir: string): Boolean;
begin
  Result := DirExists(Dir) and FileExists(AddBackslash(Dir) + 'bin\XR_3DA.exe');
  Log('Checking game directory ' + Dir + '...');
  if Result then
    Log('Game found at ' + Dir)
  else
    Log('Game not found at ' + Dir);
end;

function IsInArray(Arr: TArrayOfString; Value: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to GetArrayLength(Arr) - 1 do
    if CompareText(Arr[I], Value) = 0 then
    begin
      Result := True;
      Break;
    end;
end;

function GetInstallationPath(): TArrayOfString;
var
  Drives: array[0..2] of string;
  I: Integer;
  RootKeys: array [0..2] of Integer;
  RootKeyIndex: Integer;
  InstallLocation: string;
begin
  SetArrayLength(Result, 0);
  SetArrayLength(SourceOfPaths, 0);
  RootKeys[0] := HKLM;
  RootKeys[1] := HKLM32;
  RootKeys[2] := HKLM64;

  // Check all root keys for the Steam registry
  for RootKeyIndex := 0 to 2 do
  begin
    if RegQueryStringValue(RootKeys[RootKeyIndex], SteamRegistry, 'InstallLocation', InstallLocation) then
    begin
      if CheckGameDirectory(InstallLocation) and not IsInArray(Result, InstallLocation) then
      begin
        SetArrayLength(Result, GetArrayLength(Result) + 1);
        Result[GetArrayLength(Result)-1] := InstallLocation;
        SetArrayLength(SourceOfPaths, GetArrayLength(SourceOfPaths) + 1);
        SourceOfPaths[GetArrayLength(SourceOfPaths)-1] := 'Steam';
      end;
    end;
  end;

  // Check all root keys for the GOG Galaxy registry
  for RootKeyIndex := 0 to 2 do
  begin
    if RegQueryStringValue(RootKeys[RootKeyIndex], GogRegistry, 'path', InstallLocation) then
    begin
      if CheckGameDirectory(InstallLocation) and not IsInArray(Result, InstallLocation) then
      begin
        SetArrayLength(Result, GetArrayLength(Result) + 1);
        Result[GetArrayLength(Result)-1] := InstallLocation;
        SetArrayLength(SourceOfPaths, GetArrayLength(SourceOfPaths) + 1);
        SourceOfPaths[GetArrayLength(SourceOfPaths)-1] := 'GOG';
      end;
    end;
  end;

  // Check all root keys for the DVD registry
  for RootKeyIndex := 0 to 2 do
  begin
    if RegKeyExists(RootKeys[RootKeyIndex], DVDRegistry) then
    begin
      if RegQueryStringValue(RootKeys[RootKeyIndex], DVDRegistry, 'InstallSource', InstallLocation) then
      begin
        if CheckGameDirectory(InstallLocation) and not IsInArray(Result, InstallLocation) then
        begin
          SetArrayLength(Result, GetArrayLength(Result) + 1);
          Result[GetArrayLength(Result)-1] := InstallLocation;
          SetArrayLength(SourceOfPaths, GetArrayLength(SourceOfPaths) + 1);
          SourceOfPaths[GetArrayLength(SourceOfPaths)-1] := 'DVD';
        end;
      end
    end;
  end;

  // Check C:\Games, D:\Games, and E:\Games
  Drives[0] := 'C';
  Drives[1] := 'D';
  Drives[2] := 'E';
  for I := 0 to 2 do
  begin
    InstallLocation := Drives[I] + ':\Games\STALKER Shadow of Chernobyl';
    if CheckGameDirectory(InstallLocation) and not IsInArray(Result, InstallLocation) then
    begin
      SetArrayLength(Result, GetArrayLength(Result) + 1);
      Result[GetArrayLength(Result)-1] := InstallLocation;
      SetArrayLength(SourceOfPaths, GetArrayLength(SourceOfPaths) + 1);
      SourceOfPaths[GetArrayLength(SourceOfPaths)-1] := 'Manual';
    end;
  end;
end;
