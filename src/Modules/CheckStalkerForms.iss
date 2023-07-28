[Code]
var
  CheckStalkerInfo: TLabel;
  CheckStalkerGameInfo: TLabel;
  CheckStalkerCB: TNewComboBox;
  CheckStalkerBrowseBtn: TNewButton;
  InstallationPaths: TArrayOfString;
  GamePaths: TArrayOfString;

#include ".\GetStalkerPaths.iss"

procedure CheckStalkerCBChange(Sender: TObject);
var
  InstallLocation: string;
  GameFound: Boolean;
begin
  if (CheckStalkerCB.ItemIndex <> -1) and (CheckStalkerCB.ItemIndex < GetArrayLength(GamePaths)) then
  begin
    InstallLocation := GamePaths[CheckStalkerCB.ItemIndex];
    GameFound := CheckGameDirectory(InstallLocation);
    if GameFound then
    begin
      CheckStalkerGameInfo.Caption := cm('StalkerCheckDirYes');
      CheckStalkerGameInfo.Font.Color := clGreen;
      WizardForm.NextButton.Enabled := True;
    end
    else
    begin
      CheckStalkerGameInfo.Caption := cm('StalkerCheckDirNo');
      CheckStalkerGameInfo.Font.Color := clRed;
      WizardForm.NextButton.Enabled := False;
    end;
  end;
end;

procedure CheckStalkerBrowseButtonClick(Sender: TObject);
var
  Dir: string;
begin
  if BrowseForFolder(SetupMessage(msgBrowseDialogLabel), Dir, false) then
  begin
    if CheckGameDirectory(Dir) then
    begin
      if not IsInArray(InstallationPaths, Dir) then
      begin
        CheckStalkerCB.Items.Add('Manual - ' + Dir);
        SetArrayLength(InstallationPaths, GetArrayLength(InstallationPaths) + 1);
        InstallationPaths[GetArrayLength(InstallationPaths) - 1] := Dir;
        SetArrayLength(SourceOfPaths, GetArrayLength(SourceOfPaths) + 1);
        SourceOfPaths[GetArrayLength(SourceOfPaths)-1] := 'Manual';
        SetArrayLength(GamePaths, GetArrayLength(GamePaths) + 1);
        GamePaths[GetArrayLength(GamePaths) - 1] := Dir;
      end;
      CheckStalkerCB.ItemIndex := CheckStalkerCB.Items.IndexOf('Manual - ' + Dir);
      CheckStalkerCBChange(Sender);  // Явный вызов обработчика событий
    end
    else
    begin
      MsgBox(cm('StalkerCheckDirNo'), mbError, MB_OK);
    end;
  end;
end;

procedure CheckStalkerForms;
var
  I: Integer;
  InstallLocation: string;
  GameFound: Boolean;
Begin
    { Label1 }
  CheckStalkerInfo := TLabel.Create(WizardForm);
  with CheckStalkerInfo do
  begin
    Name := 'Label1';
    Parent := WizardForm.SelectDirPage;
    AutoSize := False;
    Caption := cm('StalkerCheckBrowse');
    WordWrap := true;
    AutoSize := false;
    Left := ScaleX(0);
    Top := ScaleY(WizardForm.DirEdit.Top + WizardForm.DirEdit.Height + 16);
    Width := ScaleX(WizardForm.SelectDirBrowseLabel.Width);
    Height := ScaleY(27);
    Anchors := [akLeft, akTop, akRight];
  end;

  { NewComboBox1 }
  CheckStalkerCB := TNewComboBox.Create(WizardForm);
  with CheckStalkerCB do
  begin
    Parent := WizardForm.SelectDirPage;
    Left := ScaleX(0);
    Top := ScaleY(CheckStalkerInfo.Height + CheckStalkerInfo.Top + 8);
    Width := ScaleX(WizardForm.DirEdit.Width);
    Height := ScaleY(WizardForm.DirEdit.Height);
    Style := csDropDownList; // Allows the user to select an option, not edit text
    OnChange := @CheckStalkerCBChange;

    Anchors := [akLeft, akTop, akRight];
    // Populate the combo box with the installation paths
    for I := 0 to GetArrayLength(InstallationPaths) - 1 do
    begin
      CheckStalkerCB.Items.Add(SourceOfPaths[I] + ' - ' + InstallationPaths[I]);
      SetArrayLength(GamePaths, GetArrayLength(GamePaths) + 1);
      GamePaths[GetArrayLength(GamePaths) - 1] := InstallationPaths[I];
    end;
      // Select the first item if the list is not empty
      if Items.Count > 0 then
        ItemIndex := 0;
  end;

  { NewButton1 }
  CheckStalkerBrowseBtn := TNewButton.Create(WizardForm);
  with CheckStalkerBrowseBtn do
  begin
    Parent := WizardForm.SelectDirPage;
    Caption := SetupMessage(msgButtonBrowse);
    Left := ScaleX(CheckStalkerCB.Width + 10);
    Top := ScaleY(CheckStalkerCB.Top - 1);
    Width := ScaleX(75);
    Height := ScaleY(23);
    Anchors := [akTop, akRight];
    OnClick := @CheckStalkerBrowseButtonClick;
  end;

  { Label2 }
  CheckStalkerGameInfo := TLabel.Create(WizardForm);
  with CheckStalkerGameInfo do
  begin
    Name := 'Label2';
    Parent := WizardForm.SelectDirPage;
    Left := ScaleX(0);
    Top := ScaleY(CheckStalkerCB.Height + CheckStalkerCB.Top + 8);
    Width := ScaleX(WizardForm.SelectDirBrowseLabel.Width);
    Height := ScaleY(13);
    Anchors := [akLeft, akTop, akRight];
  end;

  // Check if the game is in the selected directory and set the text and color of CheckStalkerGameInfo
  if CheckStalkerCB.Items.Count > 0 then
  begin
    InstallLocation := GamePaths[CheckStalkerCB.ItemIndex];
    GameFound := CheckGameDirectory(InstallLocation);
    if GameFound then
    begin
      CheckStalkerGameInfo.Caption := cm('StalkerCheckDirYes');
      CheckStalkerGameInfo.Font.Color := clGreen;
    end
    else
    begin
      CheckStalkerGameInfo.Caption := cm('StalkerCheckDirNo');
      CheckStalkerGameInfo.Font.Color := clRed;
    end;
  end
  else
  begin
    CheckStalkerGameInfo.Caption := cm('StalkerCheckGameNo');
    CheckStalkerGameInfo.Font.Color := clRed;
  end;
end;
