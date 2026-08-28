unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Clipbrd;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnCopy: TButton;
    ButtonExportCSVClick: TButton;
    ButtonConvertClick: TButton;
    Label1: TLabel;
    Label2: TLabel;
    MemoInput: TMemo;
    MemoOutput: TMemo;
    SaveDialog1: TSaveDialog;
    procedure BtnCopyClick(Sender: TObject);
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
  POS_21 = 17;          // AI 21 всегда на 17-й позиции
  SHORT_SERIAL = 6;     // Короткий ИСН = 6 символов (1 код страны + 5)
  LONG_SERIAL = 13;     // Длинный ИСН = 13 символов (1 код страны + 12)
  RADIO_SERIAL = 20;    // Радиоэлектроника = 20 символов
  AI_LEN = 2;           // Длина идентификатора (91, 92, 93)
  KEY_LEN = 4;          // Длина ключа проверки
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

    // ТОЛЬКО GS1 коды (начинаются с 01, есть 21 на позиции 17)
    if (Copy(InputLine, 1, 2) = '01') and
       (Copy(InputLine, POS_21, 2) = '21') then
    begin
      // 1. КОРОТКИЙ КОД (ИСН = 6): 93 на позиции 17+2+6 = 25
      if Copy(InputLine, POS_21 + 2 + SHORT_SERIAL, 2) = '93' then
      begin
        FixedCode :=
          Copy(InputLine, 1, POS_21 + 2 + SHORT_SERIAL - 1) +
          #29 + Copy(InputLine, POS_21 + 2 + SHORT_SERIAL, AI_LEN + KEY_LEN) +
          Copy(InputLine, POS_21 + 2 + SHORT_SERIAL + AI_LEN + KEY_LEN, MaxInt);
      end
      // 2. ДЛИННЫЙ КОД (ИСН = 13): 91 на позиции 17+2+13 = 32
      else if Copy(InputLine, POS_21 + 2 + LONG_SERIAL, 2) = '91' then
      begin
        FixedCode :=
          Copy(InputLine, 1, POS_21 + 2 + LONG_SERIAL - 1) +
          #29 + Copy(InputLine, POS_21 + 2 + LONG_SERIAL, AI_LEN + KEY_LEN) +
          #29 + Copy(InputLine, POS_21 + 2 + LONG_SERIAL + AI_LEN + KEY_LEN, 2) +
          Copy(InputLine, POS_21 + 2 + LONG_SERIAL + AI_LEN + KEY_LEN + 2, MaxInt);
      end
      // 3. РАДИОЭЛЕКТРОНИКА (ИСН = 20): 91 на позиции 17+2+20 = 39
      else if Copy(InputLine, POS_21 + 2 + RADIO_SERIAL, 2) = '91' then
      begin
        FixedCode :=
          Copy(InputLine, 1, POS_21 + 2 + RADIO_SERIAL - 1) +
          #29 + Copy(InputLine, POS_21 + 2 + RADIO_SERIAL, AI_LEN + KEY_LEN) +
          #29 + Copy(InputLine, POS_21 + 2 + RADIO_SERIAL + AI_LEN + KEY_LEN, 2) +
          Copy(InputLine, POS_21 + 2 + RADIO_SERIAL + AI_LEN + KEY_LEN + 2, MaxInt);
      end
      else
        FixedCode := InputLine; // неизвестный формат
    end
    else
      FixedCode := InputLine; // не GS1 код

    MemoOutput.Lines.Add(FixedCode);
  end;
end;

procedure TForm1.ButtonConvertClickClick(Sender: TObject);
begin
  ConvertLines;
  ShowMessage('Конвертация выполнена!');
end;

procedure TForm1.BtnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := MemoOutput.Lines.Text;
  ShowMessage('Результат скопирован в буфер обмена');
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
