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

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ButtonConvertClickClick(Sender: TObject);
var
i:Integer;
InputLine, OutputLine: string;
FixedCode: string;
begin
  MemoOutput.Clear;
  for i := 0 to MemoInput.Lines.Count - 1 do
  begin
    InputLine := Trim(MemoInput.Lines[i]);
    if InputLine = '' then Continue;

    // Правильная вставка разделителя ПЕРЕД блоками проверки (FNC1 + AI)
    FixedCode := StringReplace(InputLine, '91', #29 + '91', [rfReplaceAll]);
    FixedCode := StringReplace(FixedCode, '92', #29 + '92', [rfReplaceAll]);

    // Удаление дубликатов разделителей, если они возникли
    while Pos(#29#29, FixedCode) > 0 do
      FixedCode := StringReplace(FixedCode, #29#29, #29, [rfReplaceAll]);

    // Убираем лишний разделитель в самом конце строки
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
    // Запрещаем менять размеры вручную
  BorderStyle := bsSingle;

  // Скрываем кнопку "Развернуть"
  BorderIcons := BorderIcons - [biMaximize];

  // Фиксируем размеры текущими значениями из инспектора объектов
  Constraints.MinWidth := Width;
  Constraints.MaxWidth := Width;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;
end;

procedure TForm1.MemoInputChange(Sender: TObject);
begin

end;

end.

