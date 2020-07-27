unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, INIFiles, Vcl.StdCtrls, AddUser,
  tlhelp32, Functions, ShellApi, DateUtils;

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
  SettingsINI: TINIFile;
  Steam: TSteam;

implementation

{$R *.dfm}

procedure TSteamSwitcherMainForm.AddUserBTNClick(Sender: TObject);
begin
  AddUserForm.ShowModal;
  with Steam do
  begin
    if AddUserForm.AddAliasEdit.Text <> '' then
      if AddUserForm.AddLoginEdit.Text <> '' then
        if AddUserForm.AddPasswordEdit.Text <> '' then
        begin
          Users[UsersCount].Alias := AddUserForm.AddAliasEdit.Text;
          Users[UsersCount].Login := AddUserForm.AddLoginEdit.Text;
          Users[UsersCount].Password := AddUserForm.AddPasswordEdit.Text;
          UsersList.Items.Add(Users[UsersCount].Alias);
          UsersCount := UsersCount + 1;
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
  end;
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
    for i := UsersList.ItemIndex to Steam.UsersCount do
      Steam.Users[i] := Steam.Users[i + 1];
    Steam.UsersCount := Steam.UsersCount - 1;
    UsersList.Clear;
    if Steam.UsersCount > 0 then
      for i := 0 to Steam.UsersCount - 1 do
        UsersList.Items.Add(Steam.Users[i].Alias);
  end;
  UsersList.ItemIndex := -1;
end;

procedure TSteamSwitcherMainForm.FormCreate(Sender: TObject);
var
  i: byte;
begin
  SettingsINI := TINIFile.Create(ExtractFilePath(Application.ExeName) +
    'settings.ini');
  with Steam do
  begin
    Exe := SettingsINI.ReadString('Base', 'SteamExePath', '');
    if Exe = '' then
      if WhereIsMySteam.Execute then
        Exe := WhereIsMySteam.FileName;
    AdParam := SettingsINI.ReadString('Base', 'AdParam', '');
    LoginParam := SettingsINI.ReadString('Base', 'LoginParam', '-login');
    PasswordParam := SettingsINI.ReadString('Base', 'PasswordParam', '');
    ShutdownParam := SettingsINI.ReadString('Base', 'ShutdownParam',
      '-shutdown');
    ShutdownTimeout := SettingsINI.ReadInteger('Base', 'ShutdownTimeout', 5);
    CloseAfterSwitch := SettingsINI.ReadBool('Base', 'CloseAfterSwitch', true);
    UsersCount := SettingsINI.ReadInteger('Base', 'UsersCount', 0);
    if UsersCount > 0 then
      for i := 0 to UsersCount - 1 do
      begin
        Users[i].Login := SettingsINI.ReadString('User' + IntToStr(i),
          'Login', '');
        Users[i].Password := SettingsINI.ReadString('User' + IntToStr(i),
          'Password', '');
        Users[i].Alias := SettingsINI.ReadString('User' + IntToStr(i),
          'Alias', '');
        UsersList.Items.Add(Users[i].Alias);
      end;
  end;
  SettingsINI.Free;
end;

procedure TSteamSwitcherMainForm.FormDestroy(Sender: TObject);
var
  i: byte;
begin
  SettingsINI := TINIFile.Create(ExtractFilePath(Application.ExeName) +
    'settings.ini');
  with Steam do
  begin
    SettingsINI.WriteString('Base', 'SteamExePath', Exe);
    SettingsINI.WriteString('Base', 'AdParam', AdParam);
    SettingsINI.WriteString('Base', 'LoginParam', LoginParam);
    SettingsINI.WriteString('Base', 'PasswordParam', PasswordParam);
    SettingsINI.WriteString('Base', 'ShutdownParam', ShutdownParam);
    SettingsINI.WriteInteger('Base', 'ShutdownTimeout', ShutdownTimeout);
    SettingsINI.WriteBool('Base', 'CloseAfterSwitch', CloseAfterSwitch);
    SettingsINI.WriteInteger('Base', 'UsersCount', UsersCount);
    for i := 0 to 255 do
      SettingsINI.EraseSection('User' + IntToStr(i));
    if UsersCount > 0 then
      for i := 0 to UsersCount - 1 do
      begin
        SettingsINI.WriteString('User' + IntToStr(i), 'Login', Users[i].Login);
        SettingsINI.WriteString('User' + IntToStr(i), 'Password',
          Users[i].Password);
        SettingsINI.WriteString('User' + IntToStr(i), 'Alias', Users[i].Alias);
      end;
  end;
  SettingsINI.Free;
end;

procedure TSteamSwitcherMainForm.SwitchBTNClick(Sender: TObject);
var
  Timeout: TDateTime;
begin
  if UsersList.ItemIndex = -1 then
    MessageBox(Handle, 'User not selected!', 'Error!', MB_OK or MB_ICONERROR)
  else
  begin
    SwitchBTN.Enabled := false;
    DeleteUserBTN.Enabled := false;
    AddUserBTN.Enabled := false;
    if ExeRunning(Steam.Exe) then
    begin
      ShellExecute(Handle, 'open', PWideChar(Steam.Exe),
        PWideChar(Steam.ShutdownParam), PWideChar(ExtractFilePath(Steam.Exe)),
        SW_SHOWDEFAULT);
      Timeout := IncSecond(Now, Steam.ShutdownTimeout);
      while (CompareTime(Now, Timeout) < 0) do
        Application.ProcessMessages;
      if ExeRunning(Steam.Exe) then
      begin
        ShellExecute(Handle, 'open', 'taskkill',
          PWideChar('/F /IM ' + ExtractFileName(Steam.Exe)), '',
          SW_SHOWDEFAULT);
        Timeout := IncSecond(Now, Steam.ShutdownTimeout);
        while (CompareTime(Now, Timeout) < 0) do
          Application.ProcessMessages;
        if ExeRunning(Steam.Exe) then
        begin
          MessageBox(Handle, 'Can not close the programm!', 'Error!',
            MB_OK or MB_ICONERROR);
        end
        else
          ShellExecute(Handle, 'open', PWideChar(Steam.Exe),
            PWideChar(Steam.AdParam + ' ' + Steam.LoginParam + ' ' + Steam.Users
            [UsersList.ItemIndex].Login + ' ' + Steam.PasswordParam + ' ' +
            Steam.Users[UsersList.ItemIndex].Password),
            PWideChar(ExtractFilePath(Steam.Exe)), SW_SHOWDEFAULT);
      end
      else
        ShellExecute(Handle, 'open', PWideChar(Steam.Exe),
          PWideChar(Steam.AdParam + ' ' + Steam.LoginParam + ' ' + Steam.Users
          [UsersList.ItemIndex].Login + ' ' + Steam.PasswordParam + ' ' +
          Steam.Users[UsersList.ItemIndex].Password),
          PWideChar(ExtractFilePath(Steam.Exe)), SW_SHOWDEFAULT);
    end
    else
      ShellExecute(Handle, 'open', PWideChar(Steam.Exe),
        PWideChar(Steam.AdParam + ' ' + Steam.LoginParam + ' ' + Steam.Users
        [UsersList.ItemIndex].Login + ' ' + Steam.PasswordParam + ' ' +
        Steam.Users[UsersList.ItemIndex].Password),
        PWideChar(ExtractFilePath(Steam.Exe)), SW_SHOWDEFAULT);
    SwitchBTN.Enabled := true;
    DeleteUserBTN.Enabled := true;
    AddUserBTN.Enabled := true;
    if Steam.CloseAfterSwitch then
      Close;
  end;
end;

end.
