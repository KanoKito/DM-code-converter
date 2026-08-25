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
const
  // Позиции для короткого кода (с 1)
  SHORT_PREFIX_END = 24;    // 01(2) + GTIN(14) + 21(2) + сериал(6) = 24
  SHORT_AI_START = 25;      // Начало AI 93
  SHORT_AI_LEN = 6;         // 93(2) + ключ(4)

  // Позиции для длинного кода (с 1)
  LONG_PREFIX_END = 31;     // 01(2) + GTIN(14) + 21(2) + сериал(13) = 31
  LONG_91_START = 32;       // Начало AI 91
  LONG_91_LEN = 6;          // 91(2) + ключ(4)
  LONG_92_START = 38;       // Начало AI 92
  LONG_92_LEN = 2;          // 92(2)
  LONG_TAIL_START = 40;     // Начало хвоста (крипто)
var
  i: Integer;
  InputLine, FixedCode: string;
begin
  MemoOutput.Clear;

  if MemoInput.Lines.Count = 0 then Exit;

  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    if Copy(InputLine, SHORT_AI_START, 2) = '93' then
    begin
      // Короткий код: GS перед 93
      FixedCode := Copy(InputLine, 1, SHORT_PREFIX_END) +
                   #29 + Copy(InputLine, SHORT_AI_START, SHORT_AI_LEN);
    end
    else if Copy(InputLine, LONG_91_START, 2) = '91' then
    begin
      // Длинный код: GS перед 91 и перед 92
      FixedCode :=
        Copy(InputLine, 1, LONG_PREFIX_END) +
        #29 + Copy(InputLine, LONG_91_START, LONG_91_LEN) +
        #29 + Copy(InputLine, LONG_92_START, LONG_92_LEN) +
        Copy(InputLine, LONG_TAIL_START, MaxInt);
    end
    else
    begin
      // Неизвестный формат — пропускаем без изменений
      FixedCode := InputLine;
    end;

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
