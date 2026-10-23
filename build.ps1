$ErrorActionPreference = 'Stop'
$env:MSBuildEnableWorkloadResolver = 'false'
dotnet build "$PSScriptRoot/Hook/Hook.csproj" -c Release -o "$PSScriptRoot/dist"
if ($LASTEXITCODE) { exit $LASTEXITCODE }
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /optimize+ /reference:System.Windows.Forms.dll /reference:System.Core.dll "/win32icon:$PSScriptRoot/Launcher/PCL.ico" "/out:$PSScriptRoot/dist/PCL.exe" "$PSScriptRoot\Launcher\Program.cs"
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Copy-Item -LiteralPath "$PSScriptRoot/Start-PCL.ps1", "$PSScriptRoot/Start-PCL.bat", "$PSScriptRoot/LICENSE", "$PSScriptRoot/README.md" -Destination "$PSScriptRoot/dist"
