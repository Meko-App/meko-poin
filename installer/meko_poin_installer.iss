; ============================================================
;  POS Photorism App - Inno Setup Installer Script
;  Generated for Flutter Windows release build
;
;  Prerequisites (on the Windows build machine):
;    1. Inno Setup 6: https://jrsoftware.org/isdl.php
;    2. Flutter release build already done:
;         flutter build windows --release
;
;  How to compile this script:
;    - Open Inno Setup Compiler -> File -> Open -> select this file
;    - Press F9 (or Build -> Compile)
;    - The output installer will be saved to:
;        installer\Output\POSPhotorism_Setup_1.0.0.exe
; ============================================================

#define AppName      "POS Photorism App"
#define AppVersion   "1.0.0"
#define AppPublisher "Photorism"
#define AppExeName   "meko_poin.exe"
; Path to Flutter Windows release output (relative to this .iss file location)
#define BuildDir     "..\build\windows\x64\runner\Release"

[Setup]
; -- Basic app identity --
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://meko.app
AppSupportURL=https://meko.app
AppUpdatesURL=https://meko.app

; -- Default installation directory --
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}

; -- Output installer file --
OutputDir=Output
OutputBaseFilename=POSPhotorism_Setup_{#AppVersion}

; -- Installer appearance --
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes

; -- Privileges --
; Use "lowest" so installation does not require admin rights.
; Change to "admin" if you need a system-wide install.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; -- Minimum Windows version: Windows 10 --
MinVersion=10.0

; -- Architecture --
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Copy the entire Release build output folder (including data/, flutter_windows.dll, etc.)
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Start Menu shortcuts
Name: "{group}\{#AppName}";                        Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}";  Filename: "{uninstallexe}"
; Desktop shortcut (only if user ticked the task above)
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Offer to launch the app right after installation completes
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove all files left behind by the app after uninstall
Type: filesandordirs; Name: "{app}"
