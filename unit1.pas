unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

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
    procedure ConvertLines;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ConvertLines;
var
  i: Integer;
  InputLine, head, code, tail, FixedCode: string;
begin
  MemoOutput.Clear;

  if MemoInput.Lines.Count = 0 then Exit;

  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    head := Copy(InputLine, 1, 19);
    code := Copy(InputLine, 20, 20);
    tail := Copy(InputLine, 40, MaxInt);
    //Добавляем служебные символы перед 91 и 92
    code := StringReplace(code, '91', #29 + '91', []);
    code := StringReplace(code, '92', #29 + '92', []);

    FixedCode := head + code + tail;
    MemoOutput.Lines.Add(FixedCode);
  end;
end;

procedure TForm1.ButtonConvertClickClick(Sender: TObject);
begin
  ConvertLines;
  ShowMessage('Конвертация выполнена!');
end;

procedure TForm1.ButtonExportCSVClickClick(Sender: TObject);
var
  sl: TStringList;
  i: Integer;
  Line, EscapedLine: string;
begin
  // Автоматическая конвертация перед экспортом
  ConvertLines;

  if MemoOutput.Lines.Count = 0 then
  begin
    ShowMessage('Нет данных для экспорта!');
    Exit;
  end;

  if not SaveDialog1.Execute then Exit;

  sl := TStringList.Create;
  try
    ForceDirectories(ExtractFilePath(SaveDialog1.FileName));

    for i := 0 to MemoOutput.Lines.Count - 1 do
    begin
      Line := Trim(MemoOutput.Lines[i]);
      if Line = '' then Continue;

      EscapedLine := StringReplace(Line, '"', '""', [rfReplaceAll]);
      sl.Add('"' + EscapedLine + '"');
    end;

    sl.SaveToFile(SaveDialog1.FileName, TEncoding.UTF8);
    ShowMessage('Файл успешно сохранен: ' + ExtractFileName(SaveDialog1.FileName));
  finally
    sl.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SaveDialog1.Filter := 'Файлы CSV|*.csv';
  SaveDialog1.DefaultExt := 'csv';

  MemoOutput.Clear;
  MemoInput.Clear;

  BorderStyle := bsSingle;
  BorderIcons := BorderIcons - [biMaximize];
  Constraints.MinWidth := Width;
  Constraints.MaxWidth := Width;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;
end;

procedure TForm1.MemoInputChange(Sender: TObject);
begin
  // Очищаем результаты при изменении входных данных
  MemoOutput.Clear;
end;

end.
