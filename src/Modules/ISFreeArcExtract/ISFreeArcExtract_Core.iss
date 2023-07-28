// ISFreeArcExtract v.4.3 WIP
[ISToolPreCompile]
#define ISFreeArcExtractVersion "v.4.3 WIP"

#ifndef Archives
  #define Archives ""
#endif

#ifndef ArcIni
  #define ArcIni ""
#endif

#define ParseLine(arcs, file, section_index, index) \
  Local[0] = FileRead(file),  \
  (index <= section_index) ? arcs :  \
  (Local[0] == "") ? arcs : \
  (Pos(";", Local[0]) == 1) ? arcs : \
  (Pos("/", Local[0]) == 1) ? arcs : \
  (arcs == "") ? Local[0] : \
  arcs + "|" + Local[0]

#sub ParseArcFiles
  #expr Local[0] = AddBackslash(GetEnv("TEMP")) + GetDateTimeString('dd/mm-hh:nn', '-', '-') +'.iss'
  #expr SaveToFile(Local[0])
  #expr Local[1] = FileOpen(Local[0])
    #expr Local[2] = Find(0, "[ArcFiles]")
    #for {Local[3] = 0; !FileEof(Local[1]); Local[3] = Local[3] + 1} \
      Archives = ParseLine(Archives, Local[1], Local[2], Local[3])
  #expr FileClose(Local[1])
  #expr DeleteFile(Local[0])
#endsub

[Code]
#include "Windows.iss"
#include "ISFreeArcExtract_Utils.iss"
#include "ISFreeArcExtract_Browse.iss"

type
#if Ver < 84018176
    AnsiString = String;
#endif

  TFreeArcCallback = function (what: PAnsiChar; int1, int2: Integer; str: PAnsiChar): Integer;
  TFreeArcBeforeMethod = function(): Boolean;

  TArc = record
    Path:          String;
    SubPath:       String;
    Filename:      String;
    Destination:   String;
    Components:    String;
    Tasks:         String;
    Password:      String;
    ConfigFile:    String;
    ExtractedSize: DWORD;
    Disks:         Integer;
    UnPack:        Boolean;
    UnPacked:      Boolean;
    AutoDelete:    Boolean; // RFU
    Overwrite:     Boolean; // RFU
    SkipMissed:    Boolean; // RFU
    Packet:        Boolean;
    ID:            DWORD;
  end;

  TSimpleArc = record
    Filename:      String;
    Destination:   String;
    Password:      String;
    ConfigFile:    String;
    ExtractedSize: DWORD;
    ID:            DWORD;
    AutoDelete:    Boolean; // RFU
    Overwrite:     Boolean; // RFU
    SkipMissed:    Boolean; // RFU
  end;

  TFAProgressInfo = record
    CurStage:   String;
    CurName:    String;
    DiskSize:   Integer;
    CurPos:     Integer;
    LastPos:    Integer;
    AllPos:     Integer;
    FilesCount: Integer;
    Percents:   Extended;
    LastSize:   Extended;
    CurSize:    Extended;
    AllSize:    Extended;
  end;

  TFADiskStatus = record
    LastMaxCount: Integer;
    MaxCount:     Integer;
    CurDisk:      Integer;
    NextArc:      Integer;
    RemainsArc:   Integer;
  end;
  TFreeArcUpdateProcess = function(StatusText, FilenameText, Time, ErrorMessage: String; PositionTotal, MaxTotal, PositionCurrent, MaxCurrent, FileCount, CurDisk, DiskCount: Integer; ExtractedSize: Extended): Boolean;

  // TODO: Remove unnecessary global variables
  // TODO: Add signle ArcState
var
  CancelCode, ArcInd, lastMb, baseMb, origsize: Integer;
  Arcs: array of TSimpleArc;
  AllArchives: array of TArc;
  msgError, CompressMethod, Arc_CurPath: String;
  Progress: TFAProgressInfo;
  DS: TFADiskStatus;
  SuspendUpdate: Boolean;
  ReturnFunc: TFreeArcUpdateProcess;
  StartInstall, LastTimerEvent, LastTimeCheck: DWORD;
    
const
  oneMB = 1024 * 1024;

function WrapFreeArcCallback (callback: TFreeArcCallback; paramcount: integer):longword; external 'wrapcallbackaddr@files:CallBackCtrl.dll stdcall';
function FreeArcExtract (callback: longword; cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7,cmd8,cmd9,cmd10: PAnsiChar): integer; external 'FreeArcExtract@files:unarc.dll cdecl delayload';
procedure UnloadDLL(); external 'UnloadDLL@files:unarc.dll cdecl delayload';

function FreeArcCmd(callback: longword; cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7,cmd8,cmd9,cmd10: PAnsiChar): integer;
begin
  CancelCode:= 0;
  AppProcessMessage;
  try
    Result:= FreeArcExtract(callback, cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7,cmd8,cmd9,cmd10);
    if CancelCode < 0 then Result:= CancelCode;
  except
    Result:= -63;
  end;
end;

Procedure SetTaskBarTitle(Title: String);
var
  h: Integer;
begin
  h:= GetWindowLong(MainForm.Handle, -8);

  if (h <> 0) then
    SetWindowText(h, Title);
end;

procedure UpdateStatus();
var
  i, t, aTime: string;
  TimeEnable: Boolean;
  Remaining: Extended;
begin
  if (SuspendUpdate)or(GetTickCount - LastTimerEvent < 200) then
    Exit;

  Progress.CurSize := baseMb+lastMb; TimeEnable:= True;
  Progress.Allsize:= Progress.LastSize + lastMb;

  if Progress.DiskSize > 0 then begin
    Progress.CurPos:= round((100000 * Progress.CurSize)/Progress.DiskSize);
    if Progress.CurPos > Progress.LastPos then begin
      Progress.AllPos:= Progress.AllPos + ((Progress.CurPos-Progress.LastPos)/DS.MaxCount);
      Progress.LastPos:=Progress.CurPos
    end;
    Progress.Percents:= Progress.AllPos/100;
    If (Progress.AllPos > 0) then Remaining:= ((100000-Progress.AllPos)*(GetTickCount-StartInstall)/Progress.AllPos)*(DS.MaxCount+1-DS.CurDisk);
    if (Progress.Percents >= 990) then begin TimeEnable:= False; t:= cm('ending'); i:= AnsiLowerCase(t); end;
    if TimeEnable then begin
      t:= FmtMessage(cm('taskbar'), [Format('%.1n',[Progress.Percents/10]), TicksToTime(Remaining, 'h', 'm', 's', false)]);
      i:= TicksToTime(Remaining, cm('hour'), cm('min'), cm('sec'), false);
    end;
  end;

  SetTaskBarTitle(t);

  if (GetTickCount() - LastTimeCheck >= 1000) then begin
    aTime:= i;
    LastTimeCheck:= GetTickCount();
  end;

  LastTimerEvent:= GetTickCount();
  if ReturnFunc<> nil then
    if not ReturnFunc(Progress.CurStage, Progress.CurName, aTime, MsgError, Progress.AllPos, 100000, LastMb, Arcs[ArcInd].ExtractedSize, Progress.FilesCount, DS.CurDisk, DS.MaxCount, Progress.Allsize*oneMB) then
      CancelCode:= -10;
end;

function FreeArcCallback(what: PAnsiChar; Mb, int2: Integer; str: PAnsiChar): Integer;
begin
  // Log('fa_callback('+string(what)+', '+IntToStr(Mb)+', '+IntToStr(int2)+', '+String(str)+')');
  case string(what) of
    'origsize': origsize:= Mb;
    'total_files': Null;
    'filename': begin 
                  Progress.CurName:= OemToAnsiStr(str);
                  Progress.FilesCount:= Progress.FilesCount + 1;
                end;
    'read': Null;
    'write': lastMb:= Mb;
    'error': if (Mb = -2) then CompressMethod:= str;
    'password?': CancelCode:= -10;
  end;

  UpdateStatus();

  if (GetKeyState(VK_ESCAPE) < 0) then
    WizardForm.Close();

  AppProcessMessage();
  Result:= CancelCode;
end;

function GetPath(Arc: TArc; ExtrPath: String; UseSubPath: Boolean): String;
begin
  if ExtrPath='' then
    Result:= Arc.Path
  else
    Result:= ExtrPath;

  if (UseSubPath) and (Arc.SubPath<>'') then
    Result:= Result+'\'+Arc.SubPath;

  Result:= Result+'\'+Arc.Filename;
end;


Function ArcDecode(Line: String): array of TArc;
var
  records: array of String;
  tmp: string;
  i, n: integer;
begin
  SetArrayLength(Result, 0);
  if (Line = '') then
    Exit;

  records:= SplitString(Line, '|');
  for n:= 0 to GetArrayLength(records) - 1 do begin
    i:= GetArrayLength(Result);
    SetArrayLength(Result, i + 1);

    Result[i].Path:= ParseSectionDirective(records[n], 'Source:');
    Result[i].Destination:= ParseSectionDirective(records[n], 'DestDir:');

    Result[i].Disks:= 1;
    tmp:= ParseSectionDirective(records[n], 'Disk:');
    if (tmp <> '') then
      Result[i].Disks:= StrToInt(tmp);

    Result[i].Components:= ParseSectionDirective(records[n], 'Components:');
    Result[i].Tasks:= ParseSectionDirective(records[n], 'Tasks:');
    Result[i].Password:= ParseSectionDirective(records[n], 'Password:');

    Result[i].ConfigFile:= ParseSectionDirective(records[n], 'Config:');
    if (Result[i].ConfigFile = '') then
      Result[i].ConfigFile:= '{#ArcIni}';

    Result[i].Filename:= ExtractFileName(Result[i].Path);
    Result[i].Path:= ExtractFilePath(result[i].Path);
    if (Result[i].Path = '') then
      Result[i].Path:= ExpandENV('{src}');

    Result[i].SubPath:= Copy(Result[i].Path, Pos('\', Result[i].Path)+1, Length(Result[i].Path));
    Delete(Result[i].Path, Pos('\', Result[i].Path), Length(Result[i].Path));

    Result[i].Destination:= ExpandENV(Result[i].Destination);
    Result[i].Path:= ExpandENV(Result[i].Path);
  end;
end;

function AddArcs(arc: TArc; var ErrCode: Integer): Integer;
var
  i, b: integer;
  f: String;
  cmd: array [0..9] of String;
begin
  Result:= 0;

  f:= GetPath(arc, Arc_CurPath, True);
  if not FileExists(f) then
    f:= GetPath(arc, Arc_CurPath, False);

  if FileExists(f) then begin
    i:= GetArrayLength(Arcs);
    SetArrayLength(Arcs, i + 1);

    Arcs[i].Filename:= f;
    Arcs[i].Destination:= arc.Destination;
    Arcs[i].Password:= arc.Password;
    Arcs[i].ConfigFile:= arc.ConfigFile;
    Arcs[i].ID:= arc.ID;
    Arcs[i].AutoDelete:= arc.AutoDelete;
    Arcs[i].Overwrite:= arc.Overwrite;
    Arcs[i].SkipMissed:= arc.SkipMissed;


    cmd[0]:= 'l';
    b:= 1;

    if Arcs[i].Password <> '' then begin
      cmd[b]:= '-p'+AnsiToUtf8(Arcs[i].Password);
      b:= b + 1;
    end;

    if (Arcs[i].ConfigFile <> '') then begin
      cmd[b]:= AnsiToUtf8('-cfg'+Arcs[i].ConfigFile);
      b:= b + 1;
    end;

    cmd[b]:= '--';
    cmd[b+1]:= AnsiToUtf8(f)

    ErrCode:= FreeArcCmd(WrapFreeArcCallback(@FreeArcCallback,4), cmd[0],cmd[1],cmd[2],cmd[3],cmd[4],cmd[5],cmd[6],cmd[7],cmd[8],cmd[9]);

    if (ErrCode >= 0) then begin
      Arcs[i].ExtractedSize:= origsize;
      Result:= origsize;
      origsize:= 0;
    end;
  end;
end;

function DispatchError(ErrorCode: Integer; Arc: TSimpleArc): String;
var
  ArcFile: String;
begin
  ArcFile:= ExtractFilename(Arc.Filename);
  case ErrorCode of
    -1:   Result:= cm('ErrorUnknownError');
    -2:   begin
            StringChange(CompressMethod, 'ERROR: unsupported compression method ', '');
            Result:= FmtMessage(cm('ErrorCompressMethod'), [CompressMethod, ArcFile]);
          end;
    -3:   Null;
    -4:   Result:= FmtMessage(cm('ErrorOutBlockSize'), [ArcFile]);
    -5:   Result:= FmtMessage(cm('ErrorNotEnoughRAMMemory'), [ArcFile]);
    -6:   Result:= FmtMessage(cm('ErrorReadData'), [ArcFile]);
    -7:   Result:= FmtMessage(cm('ErrorBadCompressedData'), [ArcFile]);
    -8:   Result:= cm('ErrorNotImplement');
    -9:   Result:= FmtMessage(cm('ErrorDataAlreadyDecompress'), [ArcFile]);
    -10:  Result:= cm('ErrorUnpackTerminated');
    -11:  Result:= FmtMessage(cm('ErrorWriteData'), [ArcFile]);
    -12:  Result:= FmtMessage(cm('ErrorBadCRC'), [ArcFile]);
    -13:  Result:= FmtMessage(cm('ErrorBadPassword'), [ArcFile]);
    -14:  Result:= FmtMessage(cm('ErrorBadHeader'), [ArcFile]);
    -15:  Null;
    -63:  Result:= cm('ErrorCodeException');
    -112: Result:= FmtMessage(cm('ErrorNotEnoughFreeSpace'), [ArcFile]);
  end;
end;

function UnPackArchive(Archive: TSimpleArc): Integer;
var
  cmd: array [0..9] of String;
  b: integer;
  FreeMB, TotalMB: Cardinal;
begin
  cmd[0]:= 'x';
  cmd[1]:= '-o+';
  cmd[2]:= '-dp'+AnsiToUtf8(Archive.Destination);
  cmd[3]:= '-w'+AnsiToUtf8(Archive.Destination);
  b:=4;
  if (Archive.Password <> '') then begin
    cmd[b]:= '-p'+AnsiToUtf8(Archive.Password);
    b:= b + 1;
  end;

  if (Archive.ConfigFile <> '') then begin
    cmd[b]:= '-cfg'+AnsiToUtf8(Archive.ConfigFile);
    b:= b + 1;
  end;

  cmd[b]:='--';
  cmd[b+1]:= AnsiToUtf8(Archive.Filename);
  Result:= FreeArcCmd(WrapFreeArcCallback(@FreeArcCallback,4), cmd[0],cmd[1],cmd[2],cmd[3],cmd[4],cmd[5],cmd[6],cmd[7],cmd[8],cmd[9]);

  if (Result = 0) then
    Exit;

  msgError:= FmtMessage(cm('ArcError'), [IntToStr(Result)]);
  GetSpaceOnDisk(ExtractFileDrive(Archive.Destination), True, FreeMB, TotalMB);

  if FreeMB < (Archive.ExtractedSize - lastMb) then
    Result:= -112;

  MsgError:= msgError+#13#10#13+DispatchError(Result, Archive)
End;

procedure SetUnpacked(File: TSimpleArc);
var
  i: integer;
begin
  for i:=0 to GetArrayLength(AllArchives)-1 do begin
    if (File.ID=AllArchives[i].ID) then begin
      AllArchives[i].UnPacked:=True;
      Break;
    end;
  end;
end;

function FindArcs(Str: TArc): array of TArc;
var
  FSR: TFindRec;
  i: Integer;
  Dir: String;
begin
  if FindFirst(GetPath(Str, Arc_CurPath, True), FSR) then try
    Dir:= ExtractFilePath(GetPath(Str, Arc_CurPath, True));
    repeat
      AppProcessMessage();
      if (FSR.Attributes and FILE_ATTRIBUTE_DIRECTORY > 0) then
        continue;

      i:= GetArrayLength(Result);
      SetArrayLength(Result, i+1);

      Result[i]:= Str;
      Result[i].Filename:= FSR.Name;
      Result[i].Packet:= True;
    until not FindNext(FSR);
  finally
    FindClose(FSR);
  end;
end;

function FillArcList(Source: array of TArc): array of TArc;
var
  i, k: integer;
  zet: array of TArc;
  anil: TArc;
  ADelete: Boolean;
begin
  SetArrayLength(Result, 0);
  for i:= 0 to GetArrayLength(Source)-1 do begin
    if (Pos('*', Source[i].Filename) > 0)and(Source[i].Disks=DS.CurDisk) then
      zet:= FindArcs(Source[i])
    else begin
      k:= GetArrayLength(zet);
      SetArrayLength(zet, k+1);
      zet[k]:= Source[i];
    end;
  end;
  for i:=0 to GetArrayLength(zet)-1 do begin
    if (zet[i].Filename<>'') then for k:=0 to GetArrayLength(zet)-1 do begin
      if (i<>k)and(AnsiLowercase(zet[i].Filename)=AnsiLowercase(zet[k].Filename)) then begin
        if (zet[i].UnPacked)and(zet[k].Packet) then ADelete:= True;
        if not (zet[k].Packet)and(not zet[i].UnPacked) then begin
          ADelete:= true;
//          if (zet[k].list<>'')and(zet[i].list<>'')and(zet[k].list<>zet[i].list) then ADelete:= False;
//          if ((zet[k].list<>'')and(zet[i].list=''))or((zet[k].list='')and(zet[i].list='')) then begin
//            if (zet[i].Packet)and(not zet[k].Packet) then zet[i].Packet:= False;
//            if (zet[k].dest<>'')and(zet[k].dest<>zet[i].dest) then zet[i].dest:= zet[k].dest;
//            if (zet[k].comp<>'')and(zet[k].comp<>zet[i].comp) then zet[i].comp:= zet[k].comp;
//            if (zet[k].task<>'')and(zet[k].task<>zet[i].task) then zet[i].task:= zet[k].task;
//            if (zet[k].pass<>'')and(zet[k].pass<>zet[i].pass) then zet[i].pass:= zet[k].pass;
//            if (zet[k].list<>'')and(zet[k].list<>zet[i].list) then zet[i].list:= zet[k].list;
//          end;
        end;
        if ADelete then zet[k]:= anil;
      end;
    end;
  end;
  for i:=0 to GetArrayLength(zet)-1 do begin
    if (zet[i].Filename <> '') then begin
      k:= GetArrayLength(Result); SetArrayLength(Result, k+1); Result[k]:= zet[i];
      Result[k].ID:=$2*(k+1);
    end;
  end;
end;

function UpdateArcsList(): Integer;
var
  m: integer;
begin
  Result:= 0;
  SetArrayLength(Arcs, 0);
  Progress.DiskSize:= 0;

  for m:=0 to (GetArrayLength(AllArchives)-1) do begin
    if (AllArchives[m].UnPack)and(AllArchives[m].UnPacked=False) then
      Progress.DiskSize:= Progress.DiskSize + AddArcs(AllArchives[m], Result);
    if (Result < 0) then
      Break;
  end;
end;

function UnPack(): Integer;
begin
  Progress.CurPos:= 0;
  Progress.LastPos:= 0;
  baseMb:= 0;

  if (DS.LastMaxCount <> DS.MaxCount) and (DS.CurDisk > 1) then
    Progress.AllPos:= (WizardForm.ProgressGauge.Max/(DS.MaxCount))*(DS.CurDisk-1);

  UpdateStatus();
  for ArcInd:= 0 to GetArrayLength(Arcs) - 1 do begin
    lastMb:= 0;
    SuspendUpdate:= False;
    Result:= UnPackArchive(Arcs[ArcInd]);
    Progress.LastSize:= Progress.AllSize;
    SetUnPacked(Arcs[ArcInd]);
    SuspendUpdate:= True;
    if (Result <> 0) then
      Break;

    baseMb:= baseMb + lastMb;
  end;
end;

function CheckBools(Bools: array of Boolean): Integer;
var
  c, l: integer;
begin
  Result:= 0;
  c:= 0;
  for l:= 0 to GetArrayLength(Bools) - 1 do
    if (Bools[l] = True) then
      c:= c + 1;

  if (c = GetArrayLength(Bools)) then
    Result:= 1;
end;

function GetRemainArcs(): integer;
var
  c: integer;
begin
  Result:= 0;
  for c:= 0 to GetArrayLength(AllArchives)-1 do
    if (AllArchives[c].UnPack)and(not AllArchives[c].UnPacked) then
      Result:= Result + 1;
end;

function GetNextArc(): Integer;
var
  c: Integer;
begin
  Result:= 0;
  for c:= 0 to GetArrayLength(AllArchives)-1 do
    if (AllArchives[c].UnPack) and (not AllArchives[c].UnPacked) then begin
      Result:= c;
      Break;
    end;
end;

function IsComponentSelectedDef(const S: String): Boolean;
begin
  Result:= IsComponentSelected(S);
end;

function IsTaskSelectedDef(const S: String): Boolean;
begin
  Result:= IsTaskSelected(S);
end;

procedure UpdateArcState();
var
  f: Integer;
begin
  for f:= 0 to GetArrayLength(AllArchives) - 1 do begin
    if (not AllArchives[f].UnPacked) then
      AllArchives[f].UnPack:= True;

    if (AllArchives[f].Components <> '') and (not EvaluateBoolExpression(AllArchives[f].Components, @IsComponentSelectedDef)) then
      AllArchives[f].UnPack:= False;

    if (AllArchives[f].Tasks <> '') and (not EvaluateBoolExpression(AllArchives[f].Tasks, @IsTaskSelectedDef)) then
      Allarchives[f].UnPack:= False;
  end;
end;

function ISFAExtract(Archives: string; BeforeExtract: TFreeArcBeforeMethod; Callback: TFreeArcUpdateProcess): Integer;
var
  MsBox, MaxArcs, z, f, k, x, LastDisk: Integer;
  OneDisk, DiskCheck, Packet: Boolean;
  Arc_Path: String;
Label
  freelib;
begin
  ExtractTemporaryFile('unarc.dll');

  if (BeforeExtract <> nil) then
    BeforeExtract();

  ReturnFunc:= Callback;
  Progress.CurStage:= cm('ArcTitle');
  Progress.FilesCount:= 0;
  StartInstall:= GetTickCount;
  LastTimerEvent:= StartInstall - 500;
  LastTimeCheck:= StartInstall - 5000;
  SuspendUpdate:= True;
  OneDisk:= False;
  DiskCheck:= False;
  Packet:= False;

  MsBox:= IDOK;
  DS.CurDisk:=1;
  z:=0;
  k:=0;
  x:=0;
  LastDisk:=1;

  AllArchives:= FillArcList(ArcDecode(Archives)); 
  DS.LastMaxCount:= DS.MaxCount;
  MaxArcs:= GetArrayLength(AllArchives)-1; 
  DS.MaxCount:= AllArchives[MaxArcs].Disks;

  if (Archives = '') then begin
    Result:= -17;
    goto freelib;
  end;

  Arc_Path:= AllArchives[0].Path;
  for f:=0 to MaxArcs do begin
    AllArchives[f].UnPack:=True;
    AllArchives[f].UnPacked:=False;
    AllArchives[f].Packet:=False;

    if (AllArchives[f].Components<>'')and(not EvaluateBoolExpression(AllArchives[f].Components, @IsComponentSelectedDef)) then
      AllArchives[f].UnPack:=False;

    if (AllArchives[f].Tasks<>'')and(not EvaluateBoolExpression(AllArchives[f].Tasks, @IsTaskSelectedDef)) then
      Allarchives[f].UnPack:=False;

    if (Pos('*', AllArchives[f].Filename) > 0) then
      Packet:= True;

    z:=z+CheckBools([CheckFile(AllArchives[f].Path, AllArchives[f].SubPath, AllArchives[f].Filename)]);
    k:=k+CheckBools([AllArchives[f].UnPack]);
    x:=x+CheckBools([AllArchives[f].UnPack, CheckFile(AllArchives[f].Path, AllArchives[f].SubPath, AllArchives[f].Filename)]);
  end;

  if (z=(MaxArcs+1))or(x=k) then begin
    DS.LastMaxCount:=DS.MaxCount;
    DS.MaxCount:=DS.CurDisk;
    OneDisk:=True;
  end;

  DS.NextArc:= GetNextArc;
  while (Result = 0) and (GetRemainArcs > 0) do begin
    if (GetRemainArcs <= 0) then
      Break;
    
    if (not OneDisk) then begin
      x:=0;
      for f:= DS.NextArc to MaxArcs do begin
        x:= x + CheckBools([(AllArchives[f].UnPack), CheckFile(AllArchives[f].Path, AllArchives[f].SubPath, AllArchives[f].Filename)]);
        if (x = ((MaxArcs + 1) - DS.NextArc)) then begin
          DS.LastMaxCount:= DS.MaxCount;
          DS.MaxCount:= DS.CurDisk;
        end;
      end;
    end;
    
    if (not CheckFile(AllArchives[DS.NextArc].Path, AllArchives[DS.NextArc].SubPath, AllArchives[DS.NextArc].Filename))and(not CheckFile(Arc_Path, AllArchives[DS.NextArc].SubPath, AllArchives[DS.NextArc].Filename)) then begin
      if not BrowseForFiles(FmtMessage(cm('InsertDisk'),[IntToStr(DS.CurDisk), AllArchives[DS.NextArc].Filename]), Arc_Path, AllArchives[DS.NextArc].SubPath, AllArchives[DS.NextArc].Filename, Arc_Path) then begin
        Result:= -10;
        Break;
      end;
      Arc_CurPath:= Arc_Path;
    end else
      Arc_CurPath:= '';

    if (not OneDisk) then begin
      if (DS.MaxCount>1)and(DS.CurDisk<>DS.MaxCount)and(not DiskCheck) then begin
        while (LastDisk<=DS.MaxCount)and(f<(MaxArcs+1)) do begin
          k:=0; x:=0;
          for z:=f to MaxArcs do begin
            if AllArchives[z].disks=LastDisk then begin x:=x+1; if (not AllArchives[z].UnPack) then k:=k+1; end;
          end;
          if k=x then begin DS.LastMaxCount:= DS.MaxCount; DS.MaxCount:= DS.MaxCount-1; f:=f+k end;
          LastDisk:=LastDisk+1;
        end;
        DiskCheck:=True;
      end;
      if (DS.CurDisk=DS.MaxCount)and(not Packet) then begin
        k:=0; x:=0;
        for z:=DS.NextArc to MaxArcs do begin
          if (AllArchives[z].disks=DS.CurDisk)and(AllArchives[z].UnPack) then begin
            x:=x+1; if FileExists(AllArchives[z].Path) then k:=k+1;
          end;
        end;
        if k<x then begin DS.LastMaxCount:= DS.MaxCount; DS.MaxCount:= DS.MaxCount+1; end;
      end;
    end;

    AllArchives:= FillArcList(AllArchives);
    UpdateArcState();
    Result:= UpdateArcsList();
    if (Result < 0) then
      Break;

    Result:= UnPack();
    DS.CurDisk:= DS.CurDisk+1;
    DS.NextArc:= GetNextArc;
  end;
  
freelib:
  UnloadDLL();
end;
