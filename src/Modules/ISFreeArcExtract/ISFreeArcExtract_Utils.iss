[code]
type
  TBoolEvaluator = function(const S: String): Boolean;

// TODO: Optimize method
function SubPos(const SubStr, S: String): Integer;
var
  i, l, t: Integer;
  tmp: String;
begin
  Result:= -1;
  if S='' then Exit;
  i:=1;
  l:= Length(S);
  t:= Length(SubStr);
  SubStr:= Lowercase(SubStr);
  repeat
    tmp:= Copy(S, i, t);
    if (Lowercase(tmp) = SubStr) then begin
      if ((S[i-1]=')')or(S[i-1]=' '))and((S[i+t]='(')or(S[i+t]=' ')) then begin
        Result:= i;
        Break;
      end;
    end;
    i:= i+1;
  until i>l;
end;

function RemoveBrackets(S: String): String;
begin
  S:= Trim(S);
  Result:= S;

  if (Length(S) < 2) then
    Exit;

  if ((S[1] <> '(') or (S[Length(S)] <> ')')) then
    Exit;

  Result:= Trim(Copy(S, 2, Length(S) - 2));
end;

// TODO: Split string into lexemes
// TODO: Add lexem evaluator helper
// TODO: Optimize method
function EvaluateBoolExpression(S: String; DefFunc: TBoolEvaluator): Boolean;
var
  i, k, c, l: Integer;
  isfalse: Boolean;
  comb: String;
  sub1, sub2: String;
label
  next;
begin
  if (S = '') then
    Exit;

  l:= Length(S);

  if (Pos('(', S)<=0) and (SubPos('and', S)<=0) and (SubPos('or', S)<=0) then begin
    isfalse:= False;
    if (Lowercase(copy(S, 1, 3))='not')and((s[4]=' ')or(S[4]='(')) then begin
      isfalse:= True;
      if S[l]=')' then
        Delete(S, l, 1);
      Delete(S, 1, 4);
    end;
    S:= Trim(RemoveBrackets(S));
    if isfalse then
      Result:= not DefFunc(S)
    else
      Result:= DefFunc(S);
  end else begin
    if S[1]='(' then begin
      i:=2;
      c:= 0;
      repeat
        if (S[i]=')') then begin
          if(c=0) then
            Break
          else
            c:= c-1;
        end;
        if S[i]='(' then
          c:=c+1;
        i:= i+1;
      until i>l;
      sub1:= RemoveBrackets(Copy(S, 1, i));
      comb:= Trim(Copy(S, i+1, l));
      goto next;
    end else begin
      i:= SubPos('or', S);
      if i<=0 then
        i:= SubPos('and', S);
      sub1:= Trim(copy(S, 1, i-1));
      comb:= Trim(Copy(S, i, Length(S)));
    next:
      i:=1;
      k:= Length(comb);
      while (i<=k)and(comb[i]<>' ')and(comb[i]<>'(') do
        i:=i+1;
      sub2:= RemoveBrackets(copy(comb, i, k));
      Delete(comb, i, k);
      case Lowercase(Trim(comb)) of
        'and': Result:= (EvaluateBoolExpression(sub2, DefFunc)) and (EvaluateBoolExpression(sub1, DefFunc));
        'or':  Result:= (EvaluateBoolExpression(sub2, DefFunc)) or (EvaluateBoolExpression(sub1, DefFunc));
      end;
    end;
  end;
end;



function TicksToTime(Ticks: Extended; h, m, s: String; detailed: Boolean): String;
begin
  if (detailed) then begin
    Result:= PADZ(IntToStr(Round(Ticks/3600000)), 2) +':'+ PADZ(IntToStr(Round((Ticks/1000 - Ticks/1000/3600*3600)/60)), 2) +':'+ PADZ(IntToStr(Round(Ticks/1000 - Ticks/1000/60*60)), 2);
    Exit;
  end;

  if (Ticks / 3600 >= 1000) then
    Result:= IntToStr(Round(Ticks/3600000)) +h+' '+ PADZ(IntToStr(Round((Ticks/1000 - Ticks/1000/3600*3600)/60)), 2) +m
  else if (Ticks / 60 >= 1000) then
    Result:= IntToStr(Round(Ticks/60000)) +m+' '+ IntToStr(Round(Ticks/1000 - Ticks/1000/60*60)) +s
  else Result:= Format('%.1n', [Abs(Ticks/1000)]) +s;
end;

Function ExpandENV(S: String): String;
var
  n: UINT;
begin
  Result:= ExpandConstant(S);

  n:= Pos('%',result);
  if (n = 0) then
    Exit;

  Delete(result, n, 1);
  Result:= Copy(Result, 1, n - 1) + ExpandConstant('{%'+Copy(Result, n, Pos('%',result)-n) +'}') + Copy(Result, Pos('%',result)+1, Length(result));
end;

function cm(Message: String): String;
begin
  Result:= ExpandConstant('{cm:'+ Message +'}')
end;

function ParseSectionDirective(var S: String; Code: String): String;
var
  p1, p2: integer;
begin
  Result:= '';
  p1:= Pos(AnsiLowercase(Code), AnsiLowercase(s));

  if p1 > 0 then begin
    p2:= p1;
    while (s[p2] <> ';') and (p2 <= Length(s)) do
      p2:= p2 + 1;

    Result:= Copy(s, p1, p2-p1);
    Delete(s, p1, p2 - p1 + 1);
    Delete(Result, 1, Length(Code));
  end;

  Result:= Trim(Result);
end;

function StrToBool(S: String): Boolean;
begin
  Result:= False;
  if (S = '') then
    Exit;

  S:= Trim(AnsiLowercase(S));
  if (S = 'true')or(S = 'yes')or(S = '1') then
    Result:= True
  else
    Result:= False;
end;

function SplitString(source: String; delimiter: String): array of String;
var
  n, i: Integer;
begin
  SetArrayLength(Result, 0);

  while (source <> '') do begin
    n:= Pos(delimiter, source);
    if (n = 0) then
      n:= Length(source);

    i:= GetArrayLength(Result);
    SetArrayLength(Result, i + 1);

    Result[i]:= Copy(source, 1, n - 1) + ';';
    Delete(source, 1, n - 1 + Length(delimiter));
  end;
end;
