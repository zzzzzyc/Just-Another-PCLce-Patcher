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
        $keys = @('UnlockRegion', 'UnlockProfiles', 'DisableTelemetry', 'DisableLobbyTelemetry', 'HideCommunityHint')
        $labels = @('解除地区限制', '解除正版档案门槛', '关闭普通遥测（含弹窗修改）', '关闭联机遥测', '隐藏 PCL CE 组织名称提示', '完成后删除本配置 BAT')
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
    $start = @{ FilePath = $launcher; PassThru = $true; Wait = $true }
    if ($arguments.Count) { $start.ArgumentList = $arguments }
    $process = Start-Process @start
    if ($process.ExitCode -ne 0) { throw '启动失败，请按错误提示处理后重试。' }
    if ($Configure) {
        Write-Host ''
        Write-Host '配置已保存，已发起带 Hook 启动。' -ForegroundColor Green
        Write-Host '以后双击 PCL.exe；原版快捷方式会直接启动原版。'
        Write-Host '保留 Hook.dll、0Harmony.dll 和 Hook.ini；修改配置后重启 PCL 生效。'
        Write-Host '需要重新配置时，重新解压 Start-PCL.bat 即可。'
        if ($deleteSetup) { Write-Host '关闭本菜单后将删除 Start-PCL.bat。' }
        [void](Read-Host '按回车结束')
    }
    if ($deleteSetup) { exit 10 }
    exit 0
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
