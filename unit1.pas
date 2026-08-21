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
  i: Integer;
  InputLine, head, code, tail, FixedCode: string;
begin
  MemoOutput.Clear;

  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    // Разбиваем строку
    head := Copy(InputLine, 1, 19);
    code := Copy(InputLine, 20, 20);
    tail := Copy(InputLine, 40, Length(InputLine) - 39); // Или Length(InputLine) - 40 + 1

    // Заменяем только в code
    code := StringReplace(code, '91', #29 + '91', []);
    code := StringReplace(code, '92', #29 + '92', []);

    // Собираем обратно
    FixedCode := head + code + tail;

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

