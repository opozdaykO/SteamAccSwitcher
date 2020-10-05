unit SSFunc;

{
  TODO:
  1)Написать второй тип авторизации через отправку нажатий в окно стима вместо того,
  чтоб отправлять через параметры коммандной строки
  2)Добавить в основной проект поддерку командной строки
  3)Заменить ShellExecute на прямой вызов
  4)добавить шифрование
}
interface

uses
  Winapi.Windows, Winapi.PsAPI, Winapi.TlHelp32, System.SysUtils,
  System.Win.Registry,
  System.INIFiles, Winapi.ShellApi, System.DateUtils, Vcl.Forms;

type
  TUser = record
    Login, Password, Alias: string;
  end;

  TSteam = record
    Exe, AdParam, LoginParam, PasswordParam, ShutdownParam: string;
    UsersCount, AuthType: byte;
    ShutdownTimeout: Int64;
    CloseAfterSwitch: boolean;
    Users: array [0 .. 255] of TUser;
  end;

  TSteamSwitcher = class(TObject)
  private
    function FReadNAT: byte;
    procedure FWriteNAT(Value: byte);
    procedure Wait(time: Int64);
    function FExeActive: boolean;
    function GetPathFromPID(const PID: cardinal): string;
    function GetPid(ExeName: string): cardinal;
    function GetExePath: string;
    function FReadCAS: boolean;
    procedure FWriteCAS(Value: boolean);
    function FReadUC: byte;
    function FReadPath: string;
    procedure FWritePath(Value: string);
    function FReadST: Int64;
    procedure FWriteST(Value: Int64);
    function FReadCU: integer;
    procedure FWriteCU(Value: integer);
    function FReadU: TUser;
    procedure FWriteU(Value: TUser);
    function FReadAP: string;
    procedure FWriteAP(Value: string);
    function FReadLP: string;
    procedure FWriteLP(Value: string);
    function FReadPP: string;
    procedure FWritePP(Value: string);
    function FReadSP: string;
    procedure FWriteSP(Value: string);
    procedure SwitchAuthTypeFirst(UserNumber: byte);
    procedure SwitchAuthTypeSecond(UserNumber: byte);
    procedure TerminateSteamEXE;
  public
    constructor Create(PathToConfigFile: string);
    destructor Destroy; override;
    property UserCount: byte read FReadUC;
    property CurrentUser: integer read FReadCU write FWriteCU;
    property User: TUser read FReadU write FWriteU;
    procedure Switch(UserNumber: byte);
    procedure AddUser(NewUser: TUser);
    procedure DeleteUser(UserNumber: byte);
    property ExePath: string read FReadPath write FWritePath;
    property ExeActive: boolean read FExeActive;
    property ShutdownTimeout: Int64 read FReadST write FWriteST;
    property CloseAfterSwitch: boolean read FReadCAS write FWriteCAS;
    property AdParam: string read FReadAP write FWriteAP;
    property LoginParam: string read FReadLP write FWriteLP;
    property PasswordParam: string read FReadPP write FWritePP;
    property ShutdownParam: string read FReadSP write FWriteSP;
    property AuthType: byte read FReadNAT write FWriteNAT;
  end;

implementation

var
  Settings: TSteam;
  INIFile: TINIFile;
  CU: integer;
  { TSteamSwitcher }

procedure TSteamSwitcher.AddUser(NewUser: TUser);
begin
  Settings.Users[Settings.UsersCount] := NewUser;
  Settings.UsersCount := Settings.UsersCount + 1;
end;

constructor TSteamSwitcher.Create(PathToConfigFile: string);
var
  i: byte;
begin
  INIFile := TINIFile.Create(PathToConfigFile);
  with Settings do
  begin
    Exe := INIFile.ReadString('Base', 'SteamExePath', '');
    if Exe = '' then
      Exe := GetExePath;
    AdParam := INIFile.ReadString('Base', 'AdParam', '');
    LoginParam := INIFile.ReadString('Base', 'LoginParam', '-login');
    PasswordParam := INIFile.ReadString('Base', 'PasswordParam', '');
    ShutdownParam := INIFile.ReadString('Base', 'ShutdownParam', '-shutdown');
    ShutdownTimeout := INIFile.ReadInteger('Base', 'ShutdownTimeout', 5);
    CloseAfterSwitch := INIFile.ReadBool('Base', 'CloseAfterSwitch', true);
    UsersCount := INIFile.ReadInteger('Base', 'UsersCount', 0);
    AuthType := INIFile.ReadInteger('Base', 'AuthType', 0);
    if UsersCount > 0 then
      for i := 0 to UsersCount - 1 do
      begin
        Users[i].Login := INIFile.ReadString('User' + IntToStr(i), 'Login', '');
        Users[i].Password := INIFile.ReadString('User' + IntToStr(i),
          'Password', '');
        Users[i].Alias := INIFile.ReadString('User' + IntToStr(i), 'Alias', '');
      end;
  end;
  CU := -1;
end;

procedure TSteamSwitcher.DeleteUser(UserNumber: byte);
var
  i: byte;
begin
  for i := UserNumber to Settings.UsersCount do
    Settings.Users[i] := Settings.Users[i + 1];
  Settings.UsersCount := Settings.UsersCount - 1;
end;

destructor TSteamSwitcher.Destroy;
var
  i: byte;
begin
  with Settings do
  begin
    INIFile.WriteString('Base', 'SteamExePath', Exe);
    INIFile.WriteString('Base', 'AdParam', AdParam);
    INIFile.WriteString('Base', 'LoginParam', LoginParam);
    INIFile.WriteString('Base', 'PasswordParam', PasswordParam);
    INIFile.WriteString('Base', 'ShutdownParam', ShutdownParam);
    INIFile.WriteInteger('Base', 'ShutdownTimeout', ShutdownTimeout);
    INIFile.WriteBool('Base', 'CloseAfterSwitch', CloseAfterSwitch);
    INIFile.WriteInteger('Base', 'UsersCount', UsersCount);
    INIFile.WriteInteger('Base', 'AuthType', AuthType);
    for i := 0 to 255 do
      INIFile.EraseSection('User' + IntToStr(i));
    if UsersCount > 0 then
      for i := 0 to UsersCount - 1 do
      begin
        INIFile.WriteString('User' + IntToStr(i), 'Login', Users[i].Login);
        INIFile.WriteString('User' + IntToStr(i), 'Password',
          Users[i].Password);
        INIFile.WriteString('User' + IntToStr(i), 'Alias', Users[i].Alias);
      end;
  end;
  INIFile.Free;
  inherited;
end;

function TSteamSwitcher.FExeActive: boolean;
var
  PID: cardinal;
begin
  result := false;
  PID := GetPid(ExtractFileName(Settings.Exe));
  if PID <> 0 then
    if GetPathFromPID(PID) = Settings.Exe then
      result := true;
end;

function TSteamSwitcher.FReadAP: string;
begin
  result := Settings.AdParam;
end;

function TSteamSwitcher.FReadCAS: boolean;
begin
  result := Settings.CloseAfterSwitch;
end;

function TSteamSwitcher.FReadCU: integer;
begin
  result := CU;
end;

function TSteamSwitcher.FReadLP: string;
begin
  result := Settings.LoginParam;
end;

function TSteamSwitcher.FReadNAT: byte;
begin
  result := Settings.AuthType;
end;

function TSteamSwitcher.FReadPath: string;
begin
  result := Settings.Exe;
end;

function TSteamSwitcher.FReadPP: string;
begin
  result := Settings.PasswordParam;
end;

function TSteamSwitcher.FReadSP: string;
begin
  result := Settings.ShutdownParam;
end;

function TSteamSwitcher.FReadST: Int64;
begin
  result := Settings.ShutdownTimeout;
end;

function TSteamSwitcher.FReadU: TUser;
begin
  result := Settings.Users[CU];
end;

function TSteamSwitcher.FReadUC: byte;
begin
  result := Settings.UsersCount;
end;

procedure TSteamSwitcher.FWriteAP(Value: string);
begin
  Settings.AdParam := Value;
end;

procedure TSteamSwitcher.FWriteCAS(Value: boolean);
begin
  Settings.CloseAfterSwitch := Value;
end;

procedure TSteamSwitcher.FWriteCU(Value: integer);
begin
  if Value > -1 then
    CU := Value;
end;

procedure TSteamSwitcher.FWriteLP(Value: string);
begin
  Settings.LoginParam := Value;
end;

procedure TSteamSwitcher.FWriteNAT(Value: byte);
begin
  Settings.AuthType := Value;
end;

procedure TSteamSwitcher.FWritePath(Value: string);
begin
  Settings.Exe := Value;
end;

procedure TSteamSwitcher.FWritePP(Value: string);
begin
  Settings.PasswordParam := Value;
end;

procedure TSteamSwitcher.FWriteSP(Value: string);
begin
  Settings.ShutdownParam := Value;
end;

procedure TSteamSwitcher.FWriteST(Value: Int64);
begin
  if Value > 0 then
    Settings.ShutdownTimeout := Value;
end;

procedure TSteamSwitcher.FWriteU(Value: TUser);
begin
  Settings.Users[CU] := Value;
end;

function TSteamSwitcher.GetExePath: string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.OpenKey('SOFTWARE\Valve\Steam', false);
  if Reg.KeyExists('SteamExe') then
  begin
    result := Reg.ReadString('SteamExe');
  end
  else
    result := '';
end;

function TSteamSwitcher.GetPathFromPID(const PID: cardinal): string;
type
  TQueryFullProcessImageName = function(hProcess: Thandle; dwFlags: DWORD;
    lpExeName: PChar; nSize: PDWORD): BOOL; stdcall;
var
  hProcess: Thandle;
  path: array [0 .. MAX_PATH - 1] of char;
  QueryFullProcessImageName: TQueryFullProcessImageName;
  nSize: cardinal;
begin
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
    false, PID);
  if hProcess <> 0 then
    try

      if GetModuleFileNameEx(hProcess, 0, path, MAX_PATH) <> 0 then
      begin
        result := path;
      end
      else if Win32MajorVersion >= 6 then
      begin
        nSize := MAX_PATH;
        ZeroMemory(@path, MAX_PATH);
        @QueryFullProcessImageName :=
          GetProcAddress(GetModuleHandle('kernel32'),
          'QueryFullProcessImageNameW');
        if Assigned(QueryFullProcessImageName) then
          if QueryFullProcessImageName(hProcess, 0, path, @nSize) then
            result := path;
      end;

    finally
      CloseHandle(hProcess)
    end
  else
    RaiseLastOSError;
end;

function TSteamSwitcher.GetPid(ExeName: string): cardinal;
var
  hSnapShot: Thandle;
  ProcInfo: TProcessEntry32;
begin
  result := 0;
  hSnapShot := CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnapShot <> Thandle(-1)) then
  begin
    ProcInfo.dwSize := SizeOf(ProcInfo);
    if (Process32First(hSnapShot, ProcInfo)) then
    begin
      while (Process32Next(hSnapShot, ProcInfo)) do
      begin
        if ProcInfo.szExeFile = ExeName then
          result := ProcInfo.th32ProcessID;
      end;
    end;
    CloseHandle(hSnapShot);
  end;
end;

procedure TSteamSwitcher.Switch(UserNumber: byte);
begin
  case Settings.AuthType of
    0:
      SwitchAuthTypeFirst(UserNumber);
    1:
      SwitchAuthTypeSecond(UserNumber);
  else
    MessageBox(0, 'Error! Wrong auth type!', 'Error!', MB_OK or MB_ICONERROR)
  end;
end;

procedure TSteamSwitcher.SwitchAuthTypeFirst(UserNumber: byte);
begin
  if FExeActive then
  begin
    ShellExecute(0, 'open', PWideChar(Settings.Exe),
      PWideChar(Settings.ShutdownParam), PWideChar(ExtractFilePath(Settings.Exe)
      ), SW_SHOWDEFAULT);
    Wait(Settings.ShutdownTimeout);
    if FExeActive then
    begin
      ShellExecute(0, 'open', 'taskkill',
        PWideChar('/F /IM ' + ExtractFileName(Settings.Exe)), '',
        SW_SHOWDEFAULT);
      Wait(Settings.ShutdownTimeout);
      if not FExeActive then
        ShellExecute(0, 'open', PWideChar(Settings.Exe),
          PWideChar(Settings.AdParam + ' ' + Settings.LoginParam + ' ' +
          Settings.Users[UserNumber].Login + ' ' + Settings.PasswordParam + ' '
          + Settings.Users[UserNumber].Password),
          PWideChar(ExtractFilePath(Settings.Exe)), SW_SHOWDEFAULT);
    end
    else
      ShellExecute(0, 'open', PWideChar(Settings.Exe),
        PWideChar(Settings.AdParam + ' ' + Settings.LoginParam + ' ' +
        Settings.Users[UserNumber].Login + ' ' + Settings.PasswordParam + ' ' +
        Settings.Users[UserNumber].Password),
        PWideChar(ExtractFilePath(Settings.Exe)), SW_SHOWDEFAULT);
  end
  else
    ShellExecute(0, 'open', PWideChar(Settings.Exe),
      PWideChar(Settings.AdParam + ' ' + Settings.LoginParam + ' ' +
      Settings.Users[UserNumber].Login + ' ' + Settings.PasswordParam + ' ' +
      Settings.Users[UserNumber].Password),
      PWideChar(ExtractFilePath(Settings.Exe)), SW_SHOWDEFAULT);
end;

procedure TSteamSwitcher.SwitchAuthTypeSecond(UserNumber: byte);
begin
  if FExeActive then
  begin

  end;
end;

procedure TSteamSwitcher.TerminateSteamEXE;
var
  PID: cardinal;
begin

end;

procedure TSteamSwitcher.Wait(time: Int64);
var
  Timeout: TDateTime;
begin
  Timeout := IncSecond(Now, time);
  while (CompareTime(Now, Timeout) < 0) do
    Application.ProcessMessages;
end;

end.
