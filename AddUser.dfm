object AddUserForm: TAddUserForm
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'AddUserForm'
  ClientHeight = 171
  ClientWidth = 137
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object AddAliasEdit: TLabeledEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    EditLabel.Width = 22
    EditLabel.Height = 13
    EditLabel.Caption = 'Alias'
    TabOrder = 0
  end
  object AddLoginEdit: TLabeledEdit
    Left = 8
    Top = 72
    Width = 121
    Height = 17
    EditLabel.Width = 25
    EditLabel.Height = 13
    EditLabel.Caption = 'Login'
    TabOrder = 1
  end
  object AddPasswordEdit: TLabeledEdit
    Left = 8
    Top = 112
    Width = 121
    Height = 21
    EditLabel.Width = 46
    EditLabel.Height = 13
    EditLabel.Caption = 'Password'
    PasswordChar = '*'
    TabOrder = 2
  end
  object AddUserBTN: TButton
    Left = 8
    Top = 139
    Width = 121
    Height = 25
    Caption = 'Add user'
    TabOrder = 3
    OnClick = AddUserBTNClick
  end
end
