unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, StrUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonExportCSVClick: TButton;
    ButtonConvertClick: TButton;
    MemoInput: TMemo;
    MemoOutput: TMemo;
    SaveDialog1: TSaveDialog;
    procedure ButtonConvertClickClick(Sender: TObject);
    procedure ButtonExportCSVClickClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MemoInputChange(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ButtonConvertClickClick(Sender: TObject);
var
  i, GTINEnd, CurrPos, Next91, Next92: Integer;
  InputLine, FixedCode, Body: string;
begin
  MemoOutput.Clear;
  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    {
      По стандарту GS1 первые 16 символов (01 + 14 цифр GTIN) идут слитно.
      Всё, что после них — это тело кода с идентификаторами применения (AI).
    }
    if Length(InputLine) >= 16 then
    begin
      FixedCode := Copy(InputLine, 1, 16);
      Body := Copy(InputLine, 17, MaxInt);
    end
    else
    begin
      FixedCode := InputLine;
      Body := '';
    end;

    CurrPos := 1;

    {
      Как только находим 91 или 92, вставляем перед ними #29 (GS)
      и перепрыгиваем через сам ключ на длину его значения до следующего ключа.
    }
    while CurrPos <= Length(Body) do
    begin
      Next91 := PosEx('91', Body, CurrPos);
      Next92 := PosEx('92', Body, CurrPos);
      if (Next91 = 0) and (Next92 = 0) then
      begin

        FixedCode := FixedCode + Copy(Body, CurrPos, MaxInt);
        Break;
      end;

      if (Next91 > 0) and ((Next92 = 0) or (Next91 < Next92)) then
      begin

        FixedCode := FixedCode + Copy(Body, CurrPos, Next91 - CurrPos) + #29 + '91';
        CurrPos := Next91 + 2;


        Next91 := PosEx('91', Body, CurrPos);
        Next92 := PosEx('92', Body, CurrPos);
        if (Next91 = 0) and (Next92 = 0) then
          Next91 := Length(Body) + 1
        else if (Next91 = 0) then
          Next91 := Next92
        else if (Next92 = 0) then

        else if Next92 < Next91 then
          Next91 := Next92;

        FixedCode := FixedCode + Copy(Body, CurrPos, Next91 - CurrPos);
        CurrPos := Next91;
      end
      else
      begin

        FixedCode := FixedCode + Copy(Body, CurrPos, Next92 - CurrPos) + #29 + '92';
        CurrPos := Next92 + 2;

        Next91 := PosEx('91', Body, CurrPos);
        Next92 := PosEx('92', Body, CurrPos);
        if (Next91 = 0) and (Next92 = 0) then
          Next92 := Length(Body) + 1
        else if (Next92 = 0) then
          Next92 := Next91
        else if (Next91 = 0) then

        else if Next91 < Next92 then
          Next92 := Next91;

        FixedCode := FixedCode + Copy(Body, CurrPos, Next92 - CurrPos);
        CurrPos := Next92;
      end;
    end;

    // Очистка возможных дублей разделителей во входных данных
    while Pos(#29#29, FixedCode) > 0 do
      Delete(FixedCode, Pos(#29#29, FixedCode), 1);

    if (Length(FixedCode) > 0) and (FixedCode[Length(FixedCode)] = #29) then
      SetLength(FixedCode, Length(FixedCode) - 1);

    MemoOutput.Lines.Add(FixedCode);
  end;
end;

procedure TForm1.ButtonExportCSVClickClick(Sender: TObject);
var
  sl: TStringList;
  i: Integer;
  Line, EscapedLine, FileName: string;
begin
  if SaveDialog1.Execute then
  begin
    sl := TStringList.Create;
    try

      ForceDirectories(ExtractFilePath(SaveDialog1.FileName));

      for i := 0 to MemoOutput.Lines.Count - 1 do
      begin
        Line := Trim(MemoOutput.Lines[i]);
        if Line = '' then Continue;

        { --- Экранирование по RFC 4180 --- }
        EscapedLine := StringReplace(Line, '"', '""', [rfReplaceAll]);
        EscapedLine := '"' + EscapedLine + '"';

        sl.Add(EscapedLine);
      end;

      // Сохраняем строго в UTF-8 без BOM
      sl.SaveToFile(SaveDialog1.FileName, TEncoding.UTF8);
      ShowMessage('Файл успешно сохранен: ' + ExtractFileName(SaveDialog1.FileName));

    finally
      sl.Free;
    end;
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
// Настройка диалога сохранения
  SaveDialog1.Filter := 'Файлы CSV|*.csv';
  SaveDialog1.DefaultExt := 'csv';

  MemoOutput.Clear;
  MemoInput.Clear;
  
    // Настройка формы
  BorderStyle := bsSingle;
  BorderIcons := BorderIcons - [biMaximize];
  Constraints.MinWidth := Width;
  Constraints.MaxWidth := Width;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;
end;

procedure TForm1.MemoInputChange(Sender: TObject);
begin

end;

end.

