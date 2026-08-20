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
  i, Pos91, Pos92: Integer;
  InputLine, FixedCode: string;
begin
  MemoOutput.Clear;
  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    // Ищем первый "91" начиная с 17-й позиции (после GTIN)
    Pos91 := PosEx('91', InputLine, 17);

    if Pos91 > 0 then
    begin
      // Ищем первый "92" ПОСЛЕ "91"
      Pos92 := PosEx('92', InputLine, Pos91 + 2);

      if Pos92 > 0 then
      begin
        // Собираем строку:
        // 1. Часть до 91 (GTIN + серийный номер + данные)
        // 2. #29 + 91
        // 3. Данные между 91 и 92
        // 4. #29 + 92
        // 5. ВСЕ, что после 92 (хвост)
        FixedCode := Copy(InputLine, 1, Pos91 - 1) +
                     #29 + '91' +
                     Copy(InputLine, Pos91 + 2, Pos92 - (Pos91 + 2)) +
                     #29 + '92' +
                     Copy(InputLine, Pos92 + 2, Length(InputLine) - (Pos92 + 1));
      end
      else
      begin
        // Если нет 92, вставляем только перед 91
        FixedCode := Copy(InputLine, 1, Pos91 - 1) + #29 + '91' + Copy(InputLine, Pos91 + 2, MaxInt);
      end;
    end
    else
    begin
      // Если нет 91, оставляем как есть
      FixedCode := InputLine;
    end;

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

