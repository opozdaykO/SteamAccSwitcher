object SteamSwitcherMainForm: TSteamSwitcherMainForm
  Left = 0
  Top = 0
  AlphaBlend = True
  AlphaBlendValue = 200
  AutoSize = True
  BorderStyle = bsSizeToolWin
  Caption = 'Steam Switcher'
  ClientHeight = 275
  ClientWidth = 292
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefault
  Scaled = False
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object UsersList: TListBox
    Left = 0
    Top = 0
    Width = 292
    Height = 244
    ItemHeight = 13
    TabOrder = 0
  end
  object SwitchBTN: TButton
    Left = 0
    Top = 250
    Width = 230
    Height = 25
    Caption = 'Switch account'
    TabOrder = 1
    OnClick = SwitchBTNClick
  end
  object AddUserBTN: TButton
    Left = 236
    Top = 250
    Width = 25
    Height = 25
    Caption = '+'
    TabOrder = 2
    OnClick = AddUserBTNClick
  end
  object DeleteUserBTN: TButton
    Left = 267
    Top = 250
    Width = 25
    Height = 25
    Caption = '-'
    TabOrder = 3
    OnClick = DeleteUserBTNClick
  end
  object WhereIsMySteam: TOpenDialog
    Filter = '*.exe|*.exe'
  end
end
