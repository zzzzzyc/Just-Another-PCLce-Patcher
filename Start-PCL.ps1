param(
    [Parameter(Position = 0)][string]$PclPath,
    [switch]$DisableLobbyTelemetry,
    [switch]$Configure
)
$ErrorActionPreference = 'Stop'
try {
    $launcher = Join-Path $PSScriptRoot 'PCL.exe'
    if (!(Test-Path -LiteralPath $launcher)) { throw '找不到 PCL.exe，请解压完整运行包。' }
    $deleteSetup = $false
    if ($Configure) {
        if (!$PclPath) {
            $original = Join-Path $PSScriptRoot 'Original'
            $folders = @($PSScriptRoot)
            if (Test-Path -LiteralPath $original) { $folders += $original }
            $candidates = @(Get-ChildItem -LiteralPath $folders -Filter '*.exe' -File | Where-Object {
                $_.VersionInfo.ProductName -eq 'Plain Craft Launcher Community Edition'
            })
            if ($candidates.Count -gt 1) { throw '发现多个 PCL CE EXE，请只保留需要使用的一个。' }
            if ($candidates.Count -eq 1 -and $candidates[0].DirectoryName -eq $PSScriptRoot) {
                $destination = Join-Path $original $candidates[0].Name
                if (Test-Path -LiteralPath $destination) { throw "目标文件已存在：$destination" }
                New-Item -ItemType Directory -Path $original -Force | Out-Null
                Move-Item -LiteralPath $candidates[0].FullName -Destination $destination
                Write-Host '已将原版 PCL CE 移入 Original。' -ForegroundColor Green
            }
            elseif ($candidates.Count -eq 0) {
                Write-Host '未找到原版 PCL CE。输入 D 下载适配的 2.15.1 x64，其他键退出。'
                if ((Read-Host '选择') -ne 'd') { exit 0 }
                New-Item -ItemType Directory -Path $original -Force | Out-Null
                $destination = Join-Path $original 'PCL2_CE_Release_x64.exe'
                if (Test-Path -LiteralPath $destination) { throw "目标文件已存在：$destination" }
                $download = Join-Path $original ([IO.Path]::GetRandomFileName() + '.download')
                try {
                    Write-Host '正在下载 PCL CE 2.15.1 x64…'
                    Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/PCL-Community/PCL-CE/releases/download/v2.15.1/PCL2_CE_Release_x64.exe' -OutFile $download
                    $sha = [Security.Cryptography.SHA256]::Create()
                    try { $hash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($download))).Replace('-', '') }
                    finally { $sha.Dispose() }
                    if ($hash -ne '168bd8369d5ed4e5478942677562913330ef1d30a5193870af910bd18198050c') {
                        throw '下载文件校验失败，请重新下载。'
                    }
                    Move-Item -LiteralPath $download -Destination $destination
                }
                finally {
                    if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download }
                }
            }
        }
        $keys = @('UnlockRegion', 'UnlockProfiles', 'DisableTelemetry', 'DisableLobbyTelemetry', 'HideCommunityHint')
        $labels = @('解除地区限制', '解除正版档案门槛', '关闭普通遥测（含弹窗修改）', '关闭联机遥测', '隐藏 PCL CE 组织名称提示', '完成后清理脚本、README 和许可证文件')
        $values = @($true, $true, $true, $true, $true, $true)
        $config = Join-Path $PSScriptRoot 'Hook.ini'
        if (Test-Path -LiteralPath $config) {
            foreach ($line in Get-Content -LiteralPath $config) {
                $pair = $line -split '=', 2
                $index = [array]::IndexOf($keys, $pair[0].Trim())
                if ($index -ge 0 -and $pair.Count -eq 2) { $values[$index] = $pair[1].Trim() -ne '0' }
            }
        }
        while ($true) {
            Clear-Host
            Write-Host '========== PCL Hook 配置 ==========' -ForegroundColor Cyan
            Write-Host '如果你不知道自己在做什么，最好别改。' -ForegroundColor Yellow
            Write-Host ''
            for ($i = 0; $i -lt $labels.Count; $i++) {
                $state = if ($values[$i]) { '开' } else { '关' }
                Write-Host ('  {0}. [{1}] {2}' -f ($i + 1), $state, $labels[$i])
            }
            Write-Host ''
            Write-Host '输入数字切换；回车保存并启动；Q 退出。'
            $choice = Read-Host '选择'
            if ($choice -eq 'q') { exit 0 }
            if ($choice -eq '') { break }
            if ($choice -match '^[1-6]$') { $values[[int]$choice - 1] = !$values[[int]$choice - 1] }
        }
        @(for ($i = 0; $i -lt $keys.Count; $i++) { '{0}={1}' -f $keys[$i], [int]$values[$i] }) |
            Set-Content -LiteralPath $config -Encoding ascii
        $deleteSetup = $values[5]
    }
    $arguments = @()
    if ($PclPath) { $arguments += '"' + (Resolve-Path -LiteralPath $PclPath).Path + '"' }
    if ($DisableLobbyTelemetry) { $arguments += '-DisableLobbyTelemetry' }
    $start = @{ FilePath = $launcher; PassThru = $true }
    if ($arguments.Count) { $start.ArgumentList = $arguments }
    $process = Start-Process @start
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw '启动失败，请按错误提示处理后重试。' }
    if ($Configure) {
        Write-Host ''
        Write-Host '配置已保存，已发起带 Hook 启动。' -ForegroundColor Green
        Write-Host '以后双击 PCL.exe；原版快捷方式会直接启动原版。'
        Write-Host '保留 Hook.dll、0Harmony.dll 和 Hook.ini；修改配置后重启 PCL 生效。'
        Write-Host '需要重新配置时，重新解压 Start-PCL.bat 和 Start-PCL.ps1 即可。'
        if ($deleteSetup) { Write-Host '正在清理 BAT、PS1、README.md、LICENSE 和 Harmony.LICENSE。' }
    }
    if ($deleteSetup) {
        foreach ($name in @('README.md', 'LICENSE', 'Harmony.LICENSE')) {
            $file = Join-Path $PSScriptRoot $name
            if (Test-Path -LiteralPath $file -PathType Leaf) { Remove-Item -LiteralPath $file }
        }
        Remove-Item -LiteralPath $PSCommandPath
        exit 10
    }
    exit 0
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
