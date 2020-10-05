unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, INIFiles, Vcl.StdCtrls, AddUser,
  SSFunc;

type
  TSteamSwitcherMainForm = class(TForm)
    UsersList: TListBox;
    SwitchBTN: TButton;
    AddUserBTN: TButton;
    DeleteUserBTN: TButton;
    WhereIsMySteam: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AddUserBTNClick(Sender: TObject);
    procedure DeleteUserBTNClick(Sender: TObject);
    procedure SwitchBTNClick(Sender: TObject);
  private
  public
  end;

var
  SteamSwitcherMainForm: TSteamSwitcherMainForm;
  SS: TSteamSwitcher;

implementation

{$R *.dfm}

procedure TSteamSwitcherMainForm.AddUserBTNClick(Sender: TObject);
var
  NewUser: TUser;
  i: byte;
begin
  AddUserForm.ShowModal;
  if AddUserForm.AddAliasEdit.Text <> '' then
    if AddUserForm.AddLoginEdit.Text <> '' then
      if AddUserForm.AddPasswordEdit.Text <> '' then
      begin
        NewUser.Alias := AddUserForm.AddAliasEdit.Text;
        NewUser.Login := AddUserForm.AddLoginEdit.Text;
        NewUser.Password := AddUserForm.AddPasswordEdit.Text;
        SS.AddUser(NewUser);
        UsersList.Clear;
        if SS.UserCount > 0 then
          for i := 0 to SS.UserCount - 1 do
          begin
            SS.CurrentUser := i;
            UsersList.Items.Add(SS.User.Alias);
          end;
      end
      else
        MessageBox(Handle, 'Password string is empty!', 'Error!',
          MB_OK or MB_ICONERROR)
    else
      MessageBox(Handle, 'Login string is empty!', 'Error!',
        MB_OK or MB_ICONERROR)
  else
    MessageBox(Handle, 'Alias string is empty!', 'Error!',
      MB_OK or MB_ICONERROR);
  UsersList.ItemIndex := -1;
end;

procedure TSteamSwitcherMainForm.DeleteUserBTNClick(Sender: TObject);
var
  i: byte;
begin
  if UsersList.ItemIndex = -1 then
    MessageBox(Handle, 'User not selected!', 'Error!', MB_OK or MB_ICONERROR)
  else
  begin
    SS.DeleteUser(UsersList.ItemIndex);
    UsersList.Clear;
    if SS.UserCount > 0 then
      for i := 0 to SS.UserCount - 1 do
      begin
        SS.CurrentUser := i;
        UsersList.Items.Add(SS.User.Alias);
      end;
  end;
  UsersList.ItemIndex := -1;
end;


procedure TSteamSwitcherMainForm.FormCreate(Sender: TObject);
var
  i: byte;
begin
  SS := TSteamSwitcher.Create(ExtractFilePath(Application.ExeName) +
    'settings.ini');
  if SS.ExePath = '' then
    if WhereIsMySteam.Execute then
      SS.ExePath := WhereIsMySteam.FileName;
  if SS.UserCount > 0 then
    for i := 0 to SS.UserCount - 1 do
    begin
      SS.CurrentUser := i;
      UsersList.Items.Add(SS.User.Alias);
    end;
end;

procedure TSteamSwitcherMainForm.FormDestroy(Sender: TObject);
begin
  SS.Free;
end;

procedure TSteamSwitcherMainForm.SwitchBTNClick(Sender: TObject);
begin
  if UsersList.ItemIndex = -1 then
    MessageBox(Handle, 'User not selected!', 'Error!', MB_OK or MB_ICONERROR)
  else
  begin
    SwitchBTN.Enabled := false;
    DeleteUserBTN.Enabled := false;
    AddUserBTN.Enabled := false;
    SS.Switch(UsersList.ItemIndex);
    SwitchBTN.Enabled := true;
    DeleteUserBTN.Enabled := true;
    AddUserBTN.Enabled := true;
    if SS.CloseAfterSwitch then
      Close;
  end;
end;

end.
