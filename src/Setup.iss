#define ArcIni "{tmp}\arc.ini"

#include ".\Modules\ISFreeArcExtract\ISFreeArcExtract_Core.iss"

#define Name "STALKER on UE - Shadow of Chernobyl"
#define Ver "Build 134"

#define DirName "STALKER on UE SoC Build 134" ;Название папки
#define EXE "Stalker.exe"

#define Size "5272084480" ;В байтах

#define WebLink "https://s2ue.org"
#define DiscordLink "https://discord.gg/8ftbBd4pCX"
#define SourceLink "https://git.s2ue.org/RedProjects/SonUE"
#define ModDBLink ""

[Setup]
AppName=STALKER on UE - Shadow of Chernobyl
AppVersion=Build 134
AppVerName={#Name} ({#Ver})
DefaultDirName={pf}\{#DirName}
ExtraDiskSpaceRequired={#Size}
DirExistsWarning=no
ShowLanguageDialog=auto
OutputBaseFilename=Setup
OutputDir=Output
VersionInfoCopyright=Red Panda, PSIget
WizardStyle=modern
DisableWelcomePage=no
DisableReadyPage=yes
DisableProgramGroupPage=yes
WizardImageFile=Images\Cover.bmp
WizardSmallImageFile=Images\Icon.bmp
SetupIconFile=Images\SetupIcon.ico
UninstallDisplayIcon={app}\Engine\Content\Game.ico

[UninstallDelete]
Type: filesandordirs; Name: {app}

[Files]
Source: "Images\Game.ico"; DestDir: "{app}\Engine\Content"
Source: Images\btn_*.bmp; DestDir: {tmp}; Flags: dontcopy
Source: Modules\ISFreeArcExtract\ISFAEFiles\unarc.dll; DestDir: {tmp}; Flags: dontcopy
Source: Modules\ISFreeArcExtract\ISFAEFiles\CallBackCtrl.dll; DestDir: {tmp}; Flags: dontcopy

[Icons]
Name: "{userdesktop}\{#Name} {#Ver}"; Filename: "{app}\{#EXE}"; WorkingDir: "{app}"; IconFilename: "{app}\Engine\Content\Game.ico"
Name: "{userstartmenu}\Red Panda\STALKER on UE\{#Name} {#Ver}"; Filename: "{app}\{#EXE}"; WorkingDir: "{app}"; IconFilename: "{app}\Engine\Content\Game.ico"
Name: "{userstartmenu}\Red Panda\STALKER on UE\Uninstall"; Filename: "{uninstallexe}"

//[Components]
//Name: Russian; Description: Русификация сообщений и озвучки
//Name: English; Description: Основные игровые файлы; Types: compact full

[Languages]
Name: rus; MessagesFile: "compiler:Languages\Russian.isl,Languages\Russian.iss"
Name: eng; MessagesFile: "compiler:Default.isl,Languages\English.iss"
Name: ukr; MessagesFile: "compiler:Languages\Ukrainian.isl,Languages\Ukrainian.iss"

[Run]
Filename: "{app}\Engine\Extras\Redist\en-us\UEPrereqSetup_x64.exe"; Parameters: "/silent"; StatusMsg: "Install UE Redist"; Check: CheckInstallationIsNotAborted; 
Filename: "{src}\Redist\oalinst.exe"; Parameters: "/SILENT"; StatusMsg: "Install OpenAL"; Check: CheckInstallationIsNotAborted; 

[ArcFiles]
;Source: {src}\*.bin; DestDir: {app}; Disk: 1;
Source: {src}\Data.bin; DestDir: {app};
//Source: {src}\Data2.bin; DestDir: {app}\data; Disk: 1; Components: Russian; Config: {tmp}\arc1.ini
//Source: {src}\Data3.bin; DestDir: {app}\data2; Disk: 1; Components: English; Config: {tmp}\arc2.ini
//Source: {src}\Data4.bin; DestDir: {app}\data3; Disk: 2;
//Source: {src}\Data5.bin; DestDir: {app}\data4; Disk: 2; Components: Russian;
//Source: {src}\Data6.bin; DestDir: {app}\data5; Disk: 2; Components: Russian;
{#ParseArcFiles}

[Code]
var
  StatusLabel, FileNameLabel, ExtractFile, StatusInfo: TLabel;
  ProgressBar: TNewProgressBar; OutErroMsg, CurStage: String;
  UnPackError: Integer; ContinueInstall: Boolean;
  ShouldAbortInstallation: Boolean;
  WebButton, DiscordButton, SourceButton, ModDBButton: TBitmapImage;

#include "Modules\CheckStalkerForms.iss";
#include "Modules\WinTB.iss";

procedure ExitProcess(exitCode:integer);
  external 'ExitProcess@kernel32.dll stdcall';

procedure OpenBrowser(Url: string);
var
  ErrorCode: Integer;
begin
  ShellExec('open', Url, '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure LinkWeb(Sender: TObject);
begin
  OpenBrowser('{#WebLink}');
end;

procedure LinkDiscord(Sender: TObject);
begin
  OpenBrowser('{#DiscordLink}');
end;

procedure LinkSource(Sender: TObject);
begin
  OpenBrowser('{#SourceLink}');
end;

procedure LinkModdb(Sender: TObject);
begin
  OpenBrowser('{#ModDBLink}');
end;

function CreateLabel(Parent: TWinControl; AutoSize, WordWrap, Transparent: Boolean; FontName: String; FontStyle: TFontStyles; FontColor: TColor; Left, Top, Width, Height: Integer; Prefs: TWinControl): TLabel;
Begin
  Result:= TLabel.Create(Parent);
  Result.Parent:= Parent;
  if Prefs <> Nil then begin
    Top:= Prefs.Top;
    Left:= Prefs.Left;
    Width:= Prefs.Width;
    Height:= Prefs.Height;
  end;

  if Top > 0 then
    Result.Top:=Top;
  if Left > 0 then
    Result.Left:= Left;
  if Width > 0 then
    Result.Width:= Width;
  if Height > 0 then
    Result.Height:= Height;

  if FontName <> '' then
    Result.Font.Name:= FontName;
  if FontColor > 0 then
    result.Font.Color:= FontColor;
  if FontStyle <> [] then
    result.Font.Style:= FontStyle;

  Result.AutoSize:= AutoSize;
  result.WordWrap:= WordWrap;
  result.Transparent:= Transparent;
  result.ShowHint:= True;
End;

Function CreateImageButton(Parent: TWinControl; Left, Top, Width, Height: Integer; ImageFile: String): TBitmapImage;
begin
    ExtractTemporaryFile(ImageFile);
    ImageFile := ExpandConstant('{tmp}\' + ImageFile);

    Result := TBitmapImage.Create(Parent);
    Result.Parent:= Parent;

    Result.Bitmap.LoadFromFile(ImageFile);
    Result.Parent := Parent;

    if Left > 0 then
      Result.Left:= ScaleX(Left);
    if Top > 0 then
      Result.Top:= WizardForm.ClientHeight - ScaleY(11 + Width);
    if Width > 0 then
      Result.Width:= ScaleY(Width);
    if Height > 0 then
      Result.Height:= ScaleX(Height);

    Result.Anchors := [akLeft, akBottom];
    Result.Stretch := True;
    Result.Cursor := crHand;
end;

Function NumToStr(Float: Extended): String;
Begin
  Result:= Format('%.2n', [Float]); StringChange(Result, ',', '.');
  while ((Result[Length(Result)] = '0') or (Result[Length(Result)] = '.')) and (Pos('.', Result) > 0) do
    SetLength(Result, Length(Result)-1);
End;

Function ByteOrTB(Bytes: Extended; noMB: Boolean): String;
Begin
  if not noMB then Result:= NumToStr(Int(Bytes)) +' Mb' else
    if Bytes < 1024 then if Bytes = 0 then Result:= '0' else Result:= NumToStr(Int(Bytes)) +' Bt' else
      if Bytes/1024 < 1024 then Result:= NumToStr(round((Bytes/1024)*10)/10) +' Kb' else
        If Bytes/oneMB < 1024 then Result:= NumToStr(round(Bytes/oneMB*100)/100) +' Mb' else
          If Bytes/oneMB/1000 < 1024 then Result:= NumToStr(round(Bytes/oneMB/1024*1000)/1000) +' Gb' else
            Result:= NumToStr(round(Bytes/oneMB/oneMB*1000)/1000) +' Tb';
End;

function UpdateProgress(StatusText, FilenameText, Time, ErrorMessage: String; PositionTotal, MaxTotal, PositionCurrent, MaxCurrent, FileCount, CurDisk, DiskCount: Integer; ExtractedSize: Extended): Boolean;
var
  totalP, arcP: Extended;
  ProgressVal: Integer;
begin
  if ProgressBar.Max<>MaxCurrent then
    ProgressBar.Max:= MaxCurrent;

  if WizardForm.ProgressGauge.Max<>MaxTotal then
    WizardForm.ProgressGauge.Max:= MaxTotal;

  ProgressBar.Position:= PositionCurrent;
  WizardForm.ProgressGauge.Position:= PositionTotal;

  if (MaxTotal <> 0) then
    totalP:= Extended(PositionTotal)*100/Extended(MaxTotal);
  if (MaxCurrent <> 0) then
    arcP:= Extended(PositionCurrent)*100/Extended(MaxCurrent);

  StatusLabel.Caption:= StatusText;
  OutErroMsg:= ErrorMessage;
  FilenameLabel.Caption:= FilenameText;
  CurStage:= StatusText;
  StatusInfo.Caption:= FmtMessage(cm('StatusInfo'), [IntToStr(FileCount), ' ['+ ByteOrTB(ExtractedSize, true) +']', Format('%.1n', [Abs(totalP)]), Time]);
  ExtractFile.Caption:= FmtMessage(cm('ArcInfo'), [IntToStr(CurDisk), IntToStr(DiskCount), IntToStr(ArcInd+1), IntToStr(GetArrayLength(Arcs)), Format('%.1n', [Abs(arcP)])]);
  ProgressBar.Position:= LastMb;

  // Abs(totalP) должен возвращать процент выполнения в формате от 0.0 до 1.0
  // Умножим на 100 и округлим до ближайшего целого, чтобы преобразовать в формат от 0 до 100
  ProgressVal := Round(Abs(totalP));

  // Теперь вы можете передать ProgressVal в SetTaskBarProgressValue
  SetTaskBarProgressValue(ProgressVal);

  Result:= ContinueInstall;
end;

function CheckInstallationIsNotAborted(): Boolean;
begin
  Result := not ShouldAbortInstallation;
end;

function BeforeExtract(): Boolean;
begin
  // Здесь можно извлечь необходимые файлы перед распаковкой
  Result:= True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var n: Integer;
begin
  if CurStep = ssInstall then
  begin
    SetTaskBarProgressValue(0);
    ContinueInstall:= True;

    WizardForm.CancelButton.Enabled:= True;

    ProgressBar.Position:=0;
    WizardForm.ProgressGauge.Position:= 0;

    StatusLabel.Show;
    FileNameLabel.Show;
    StatusInfo.Show;
    ProgressBar.Show;
    ExtractFile.Show;

    UnPackError:= ISFAExtract('{#Archives}', @BeforeExtract, @UpdateProgress);

    if UnPackError <> 0 then begin 
      ShouldAbortInstallation := True;
    end else
      SetTaskBarTitle(SetupMessage(msgSetupAppTitle));

    StatusLabel.Hide;
    FileNameLabel.Hide;
    StatusInfo.Hide;
    ProgressBar.Hide;
    ExtractFile.Hide;
  end;

  if CurStep = ssPostInstall then
  begin
    if UnPackError <> 0 then begin 
      Exec(ExpandConstant('{uninstallexe}'), '/SILENT','', sw_Hide, ewWaitUntilTerminated, n);
      WizardForm.caption:= SetupMessage(msgErrorTitle) +' - '+ cm('ArcBreak');
      SetTaskBarTitle(SetupMessage(msgErrorTitle));
    end else
    
    StatusLabel.Show;
    StatusLabel.Caption:= cm('ending');
  end;
end;

procedure WizardClose(Sender: TObject; var Action: TCloseAction);
Begin
  Action:= caNone; 
  if CurStage = cm('ArcTitle') then begin
    if MsgBox(SetupMessage(msgExitSetupMessage), mbInformation, MB_YESNO) = IDYES then
      ContinueInstall:= false;
  end else
    MainForm.Close;
End;

Procedure CurPageChanged(CurPageID: Integer);
var
  GameFound: Boolean;
  I: Integer;
  InstallLocation: string;
Begin
  if (CurPageID = wpFinished) and (UnPackError <> 0) then begin
    WizardForm.FinishedLabel.Font.Color:= $0000C0;
    WizardForm.FinishedLabel.Height:= WizardForm.FinishedLabel.Height * 2;
    WizardForm.FinishedLabel.Caption:= SetupMessage(msgSetupAborted) + #13#10#13#10 + OutErroMsg;
  end;

  if CurPageID = wpSelectDir then begin
    WizardForm.NextButton.Caption := SetupMessage(msgButtonInstall);

    // Если игра не найдена в любом из путей установки, отключаем кнопку "Next"
    GameFound := False;
    for I := 0 to GetArrayLength(GamePaths) - 1 do
    begin
      InstallLocation := GamePaths[I];
      if CheckGameDirectory(InstallLocation) then
      begin
        GameFound := True;
        Break;
      end;
    end;

    WizardForm.NextButton.Enabled := GameFound;
  end;

  if CurPageID = wpFinished then begin
    WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish)
  end;
end;

Procedure InitializeWizard();
var
  InstallLocation: string;
  I: Integer;
Begin
  InstallationPaths := GetInstallationPath();

  CheckStalkerForms;

  Log('{#Archives}');

  WebButton := CreateImageButton(WizardForm, 11, 11, 24, 24, 'btn_Web.bmp');
  DiscordButton := CreateImageButton(WizardForm, WebButton.Left + WebButton.Width + 8, 11, 24, 24, 'btn_Discord.bmp');
  SourceButton := CreateImageButton(WizardForm, DiscordButton.Left + DiscordButton.Width + 8, 11, 24, 24, 'btn_Source.bmp');
  ModDBButton := CreateImageButton(WizardForm, 1000, 1000, 1, 1, 'btn_ModDB.bmp');

  WebButton.OnClick := @LinkWeb;
  DiscordButton.OnClick := @LinkDiscord;
  SourceButton.OnClick := @LinkSource;
  ModDBButton.OnClick := @LinkModDB;

  StatusLabel:= CreateLabel(WizardForm.InstallingPage,false,false,true,'',[],0,0,0,0,0, WizardForm.StatusLabel);
  FileNameLabel:= CreateLabel(WizardForm.InstallingPage,true,false,true,'',[],0,0,0,0,0, WizardForm.FileNameLabel);
  WizardForm.StatusLabel.Top:= WizardForm.ProgressGauge.Top; WizardForm.FileNameLabel.Top:= WizardForm.ProgressGauge.Top;    // прячем под прогрессбар, тогда все события WM_PAINT перехватываются

  with WizardForm.ProgressGauge do begin
    StatusInfo:= CreateLabel(WizardForm.InstallingPage, false, true, true, '', [], 0, 0, Top + ScaleY(32), Width, 0, Nil);
    ProgressBar := TNewProgressBar.Create(WizardForm);
    ProgressBar.SetBounds(Left, 0 + 0, 0, 0);
    ProgressBar.Parent := WizardForm.InstallingPage;
    ProgressBar.Max := 65536;
    ProgressBar.Hide;
    ExtractFile:= CreateLabel(WizardForm.InstallingPage, false, true, true, '', [], 0, 1000, 1000, 0, 0, Nil);
    StatusLabel.Hide;
    FileNameLabel.Hide;
    StatusInfo.Hide;
    ProgressBar.Hide;
    ExtractFile.Hide;
  end;

  WizardForm.OnClose:= @WizardClose
  WinTBWizard();
End;


