program SteamSwitcher;

uses
  Vcl.Forms,
  Main in 'Main.pas' {SteamSwitcherMainForm},
  AddUser in 'AddUser.pas' {AddUserForm},
  SSFunc in 'SSFunc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSteamSwitcherMainForm, SteamSwitcherMainForm);
  Application.CreateForm(TAddUserForm, AddUserForm);
  Application.Run;
end.
