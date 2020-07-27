unit AddUser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TAddUserForm = class(TForm)
    AddAliasEdit: TLabeledEdit;
    AddLoginEdit: TLabeledEdit;
    AddPasswordEdit: TLabeledEdit;
    AddUserBTN: TButton;
    procedure AddUserBTNClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AddUserForm: TAddUserForm;

implementation

{$R *.dfm}

procedure TAddUserForm.AddUserBTNClick(Sender: TObject);
var
  buf: integer;
begin
  buf := MessageBox(handle, 'Add this user?', 'Warring!', MB_YESNOCANCEL);
  if buf <> 2 then
    if buf = 6 then
      Close;
end;

procedure TAddUserForm.FormShow(Sender: TObject);
begin
  AddAliasEdit.Clear;
  AddLoginEdit.Clear;
  AddPasswordEdit.Clear;
end;

end.
