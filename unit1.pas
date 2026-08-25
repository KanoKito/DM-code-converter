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
  InputLine, FixedCode: string;
  Pos21, Pos91, Pos92, Pos93: Integer;
begin
  MemoOutput.Clear;

  if MemoInput.Lines.Count = 0 then Exit;

  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    // ========================================
    // 1. СПЕЦИАЛЬНЫЕ ФОРМАТЫ (пропускаем)
    // ========================================

    // Алкоголь, SSCC, КиЗ, АТК, Табак без AI...
    if Copy(InputLine, 1, 3) = '196' then
    begin
      FixedCode := InputLine;
    end
    else if (Length(InputLine) = 20) and (Copy(InputLine, 1, 3) = '001') then
    begin
      FixedCode := InputLine;
    end
    else if (Length(InputLine) = 18) and (Copy(InputLine, 1, 1) = '1') then
    begin
      FixedCode := InputLine;
    end
    else if (Length(InputLine) = 20) and (Copy(InputLine, 3, 1) = '-') then
    begin
      FixedCode := InputLine;
    end
    else if (Length(InputLine) = 25) and (Copy(InputLine, 13, 1) = '1') then
    begin
      FixedCode := InputLine;
    end
    else if (Length(InputLine) = 21) and (Copy(InputLine, 1, 14) = StringOfChar('0', 14)) then
    begin
      FixedCode := InputLine;
    end
    else if (Length(InputLine) = 25) and (Copy(InputLine, 1, 14) = StringOfChar('0', 14)) then
    begin
      FixedCode := InputLine;
    end

    // ========================================
    // 2. СТАНДАРТНЫЙ GS1 ФОРМАТ (с 01...)
    // ========================================

    else if Copy(InputLine, 1, 2) = '01' then
    begin
      // Находим 21 (начало ИСН)
      Pos21 := PosEx('21', InputLine, 3);

      if Pos21 > 0 then
      begin
        // Ищем 91 после 21
        Pos91 := PosEx('91', InputLine, Pos21 + 2);

        if Pos91 > 0 then
        begin
          // Ищем 92 после 91
          Pos92 := PosEx('92', InputLine, Pos91 + 2);

          if Pos92 > 0 then
          begin
            // Есть 91 и 92 — вставляем #29 перед обоими
            FixedCode :=
              Copy(InputLine, 1, Pos91 - 1) + #29 + '91' +
              Copy(InputLine, Pos91 + 2, Pos92 - (Pos91 + 2)) + #29 + '92' +
              Copy(InputLine, Pos92 + 2, MaxInt);  // ВАЖНО: сохраняем ВЕСЬ хвост!
          end
          else
          begin
            // Есть только 91
            FixedCode :=
              Copy(InputLine, 1, Pos91 - 1) + #29 + '91' +
              Copy(InputLine, Pos91 + 2, MaxInt);
          end;
        end
        else
        begin
          // Нет 91 — ищем 93
          Pos93 := PosEx('93', InputLine, Pos21 + 2);

          if Pos93 > 0 then
          begin
            FixedCode :=
              Copy(InputLine, 1, Pos93 - 1) + #29 + '93' +
              Copy(InputLine, Pos93 + 2, MaxInt);
          end
          else
          begin
            // Нет AI для вставки
            FixedCode := InputLine;
          end;
        end;
      end
      else
      begin
        // Нет 21 — некорректный код
        FixedCode := InputLine;
      end;
    end

    // ========================================
    // 3. НЕИЗВЕСТНЫЙ ФОРМАТ
    // ========================================

    else
    begin
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
