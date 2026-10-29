; ============================================================
;  POS Photorism App - Inno Setup Installer Script
;  Generated for Flutter Windows release build
; ============================================================

#define AppName      "POS Photorism App"
#define AppVersion   "1.0.0"
#define AppPublisher "Photorism"
#define AppExeName   "meko_poin.exe"
; Path to Flutter Windows release output
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

; -- FIXED: Set privileges to admin to allow proper system registration and VC++ runtime setup --
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline

; -- Minimum Windows version: Windows 10 --
MinVersion=10.0

; -- Architecture --
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Copy the main application executable explicitly
Source: "{#BuildDir}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; Copy all assets, dependencies, and DLLs from the Release folder (using Excludes parameter correctly)
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#AppExeName}"

; Bundle Microsoft Visual C++ Redistributable (placed alongside this .iss script)
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: VCRedistNeedsInstall

[Icons]
; Start Menu shortcuts
Name: "{group}\{#AppName}";                        Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}";  Filename: "{uninstallexe}"
; Desktop shortcut
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Install VC++ Redistributable silently before starting the application if missing
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/q /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: waituntilterminated; Check: VCRedistNeedsInstall

; Launch application after setup completes
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Function to check if Visual C++ Redistributable x64 is already installed on the target machine
function VCRedistNeedsInstall(): Boolean;
var
  Version: String;
begin
  Result := not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version);
end;