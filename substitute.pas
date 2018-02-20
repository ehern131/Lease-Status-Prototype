unit substitute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TForm2 }

  TForm2 = class(TForm)
    btnOk: TButton;
    btnCancel: TButton;
    EdPrice: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    edQty: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Panel1: TPanel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;

implementation

uses ProtoMpMain;

{$R *.lfm}

{ TForm2 }

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Left := Mouse.CursorPos.X;
  Top  := Mouse.CursorPos.Y - Form2.Height div 2;
end;

procedure TForm2.btnOkClick(Sender: TObject);
var
  p_RecordCount, p_RecNo: Integer;
  p_Price, p_OldPrice, p_percent, p_diff: Real;
  p_TextPrice, p_qty: String;
  p_PostFund: Boolean;
  p_iqty, p_diffqty, p_OldQty: Integer;
  p_fundDate, p_fundTime, p_dod, p_reference: String;
begin
  p_percent := 0.15;
  p_iqty    := 0;
  p_Price   := StrToFloatDef(EdPrice.Text, 0);

  with Form1.SdfItems do begin
     p_postfund  := FieldValues['postfund'];
     p_fundDate  := FieldValues['fundDate'];
     p_fundTime  := FieldValues['fundTime'];
     p_dod       := FieldValues['dod'];
     p_OldQty    := StrToIntDef(FieldValues['qty'], 0);
  end;

  if p_Price = 0 then begin
     ShowMessage('Please Provide Item Price!');
     Exit;
  end;

  with Form1.SdfItems do begin
     p_iqty := StrToIntDef(edQty.Text, 0);
     if p_iqty > StrToIntDef(FieldValues['qty'],1) then begin
        ShowMessage('Substitution Quantity Exceeded!');
        Exit;
     end;
     if p_iqty <= 0  then begin
        ShowMessage('Invalid Substitution Quantity!');
        Exit;
     end;
  end;

  p_TextPrice := Form1.SdfItems.FieldValues['price'];
  p_OldPrice  := StrToFloatDef(p_TextPrice, 0);
  p_diff      := p_OldPrice * p_percent;
  p_PostFund  := Form1.SdfItems.FieldValues['postFund'];

  if p_price > (p_OldPrice + p_diff) then begin
     ShowMessage('Substitution Price Exceeded!');
     Exit;
  end;

  with Form1.SdfItems do begin
    p_diffqty     :=  StrToIntDef(FieldValues['qty'],1) - p_iqty;

    Edit;
    p_RecNo := RecNo;
    if StrToIntDef(FieldValues['qty'],1) = p_iqty then
       if not Empty(FieldValues['dod']) then
          FieldValues['status'] := 'Returned'
       else
         FieldValues['status'] := 'Cancelled';

    if p_diffqty <> 0 then begin
       FieldValues['qty']   := IntToStr(p_diffqty);
       FieldValues['total'] := FormatFloat('######0.00', p_OldPrice * p_diffqty);
    end;
    Post;
    LogJournal('Substituted', IntToStr(p_OldQty - p_diffqty), -(p_OldQty - p_diffqty) * p_OldPrice);
  end;
  Decision;

  AddTrigger('Create New Lease');
  AddTrigger('Generate New Payment Schedule');
  AddTrigger('Notify Customer to Sign New Lease');

  with Form1.SdfLeases do begin;
    p_reference := FieldValues['lease'];
    Append;
    FieldValues['lease']     := IntToStr(RecordCount+1);
    FieldValues['status']    := 'Open';
    Post;
    CopyFile(g_path_of_data + 'items1.csv', g_path_of_data + 'items' + FieldValues['lease'] + '.csv', False, True);

    Form1.SdfItems.RecNo := p_RecNo;
    Form1.SdfItems.Edit;
    Form1.SdfItems.FieldValues['reference'] := IntToStr(RecordCount);
    Form1.SdfItems.Post;

    Form1.DBGridLeasesCellClick(Nil);
  end;

  Truncate(Form1.SdfItems);
  with Form1.SdfItems do begin
    p_RecordCount := RecordCount + 1;
    Append;
    FieldValues['lease']     := Form1.SdfLeases.FieldValues['lease'];
    FieldValues['item']      := IntToStr(p_RecordCount);                                                                                                             FieldValues['status']   := 'Open';
    FieldValues['qty']       := IntToStr(p_iqty);
    FieldValues['price']     := FormatFloat('######0.00', p_Price);
    FieldValues['total']     := FormatFloat('######0.00', p_Price * p_iqty);
    FieldValues['postfund']  := False;
    FieldValues['fundDate']  := ' ';
    FieldValues['fundTime']  := ' ';
    FieldValues['dod']       := NotEmpty(p_dod);
    FieldValues['batch']     := ' ';
    FieldValues['reference'] := p_reference;
    Post;
  end;
  Close;
end;

procedure TForm2.btnCancelClick(Sender: TObject);
begin
  Close;
end;

end.

