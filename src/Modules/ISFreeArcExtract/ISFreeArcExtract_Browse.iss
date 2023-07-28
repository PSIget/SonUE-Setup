[code]
var
  Browse_Form: TForm;
  Browse_DirEdit: TEdit;
  Browse_DirBox: TFolderTreeView;
  Browse_Name, Browse_SubPath: String;
  Browse_Modal: Longint;

function CheckFile(Path, SubPath, Filename: String): Boolean;
var
  FSR: TFindRec;
begin
  Result:= False;
  if FindFirst(Path+'\'+Filename, FSR) then begin
    Result:= True;
    FindClose(FSR);
    Exit;
  end;
  if SubPath<>'' then
  if FindFirst(Path+'\'+SubPath+'\'+Filename, FSR) then begin
    Result:= True;
    FindClose(FSR);
    Exit;
  end;
end;

procedure OKOnClick(Sender: TObject);
begin
  if not CheckFile(Browse_DirEdit.Text, Browse_SubPath, Browse_Name) then begin
    MsgBox(CustomMessage('BrowseError'), mbError, MB_OK);
    Exit;
  end;
  Browse_Modal:= mrOk;
  Browse_Form.Close;
end;

procedure DirBoxOnChange(Sender: TObject);
begin
  Browse_DirEdit.Text:= Browse_DirBox.Directory;
end;

function BrowseForFiles(const Message, SrcPath, SubPath, Filename: String; var OutPath: String): Boolean;
var
  h: Integer;
begin
  Browse_Form:= TForm.Create(MainForm);
  Browse_Form.ClientWidth:= 290;
  Browse_Form.BorderStyle:= bsSingle;
  Browse_Form.BorderIcons:= [biSystemMenu];
  Browse_Form.Caption:= CustomMessage('BrowseTitle');

  Browse_Name:= Filename;
  Browse_Modal:= mrCancel;

  with TLabel.Create(Browse_Form) do begin
    Caption:= Message;
    Autosize:= True;
    SetBounds(10, 8, 270, 40);
    WordWrap:= True
    Transparent:= True;
    Parent:= Browse_Form;
    h:= Height;
  end;

  Browse_DirEdit:= TEdit.Create(Browse_Form);
  Browse_DirEdit.SetBounds(0, 0, 0, 0);
  Browse_DirEdit.Parent:= Browse_Form;

  Browse_DirBox:= TFolderTreeView.Create(Browse_Form);
  Browse_DirBox.SetBounds(10, Browse_DirEdit.Top+27, 0, 0);
  Browse_DirBox.Parent:= Browse_Form;
  Browse_DirBox.OnChange:= @DirBoxOnChange;
  Browse_DirBox.ChangeDirectory(SrcPath, False);

  with TButton.Create(Browse_Form) do begin
    SetBounds(135, Browse_DirBox.Top+148, 0, 0);
    Caption:= CustomMessage('BrowseOK');
    OnClick:= @OKOnClick;
    Parent:= Browse_Form;
  end;

  with TButton.Create(Browse_Form) do begin
    ModalResult:= mrCancel;
    SetBounds(210, 30, 70, 23);
    Caption:= CustomMessage('BrowseOK');
    Parent:= Browse_Form;
  end;

  Browse_Form.ClientHeight:= 63;
  Browse_Form.Position:= poScreenCenter;
  Browse_Form.ShowModal;

  if Browse_Modal = mrCancel then
    Result:= False
  else
    Result:= True;

  OutPath:= Browse_DirBox.Directory;
  If (OutPath<>'')and(OutPath[Length(OutPath)]='\') then
    Delete(OutPath, Length(OutPath), 1);

  Browse_Form.Free;
end;