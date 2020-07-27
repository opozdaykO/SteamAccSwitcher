unit Functions;

interface

uses
  Winapi.Windows, Winapi.PsAPI, Winapi.TlHelp32, System.SysUtils;

type
  TUser = record
    Login, Password, Alias: string;
  end;

type
  TSteam = record
    Exe, AdParam, LoginParam, PasswordParam, ShutdownParam: string;
    UsersCount: byte;
    ShutdownTimeout: Int64;
    CloseAfterSwitch: boolean;
    Users: array [0 .. 255] of TUser;
  end;

function GetPathFromPID(const PID: cardinal): string;
function GetPid(ExeName: string): cardinal;
function ExeRunning(PathToExe: string): boolean;

implementation

function GetPathFromPID(const PID: cardinal): string;
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
    False, PID);
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

function GetPid(ExeName: string): cardinal;
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

function ExeRunning(PathToExe: string): boolean;
var
  PID: cardinal;
begin
  result := False;
  PID := GetPid(ExtractFileName(PathToExe));
  if PID <> 0 then
    if GetPathFromPID(PID) = PathToExe then
      result := true;
end;

end.
