#Requires -Version 5.1
# 把本项目里的最新 exe 复制到桌面，并重启程序
param([string]$TargetDesktop = '')

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$Host.UI.RawUI.WindowTitle = 'Update GameKeyGuard'

function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }

Info '==============================================='
Info '  游戏快捷键锁 · 更新到桌面'
Info '==============================================='

$src = Join-Path $PSScriptRoot '游戏快捷键锁.exe'
if (-not (Test-Path -LiteralPath $src)) {
    Warn "找不到源文件：$src"
    Read-Host '按回车退出'
    exit 1
}

# ---------- 1. 找桌面 ----------
$desktops = @()
if ($TargetDesktop) { $desktops += $TargetDesktop }
try { $desktops += [Environment]::GetFolderPath('Desktop') } catch {}
$desktops += (Join-Path $env:USERPROFILE 'Desktop')
$desktops = $desktops | Where-Object { $_ } | Select-Object -Unique

$dst = $null
foreach ($d in $desktops) {
    $c = Join-Path $d '游戏快捷键锁.exe'
    if (Test-Path -LiteralPath $c) { $dst = $c; break }
}
if (-not $dst) {
    foreach ($d in $desktops) {
        if (Test-Path -LiteralPath $d) { $dst = Join-Path $d '游戏快捷键锁.exe'; break }
    }
}
if (-not $dst) {
    Warn '找不到桌面目录'
    Read-Host '按回车退出'
    exit 1
}
$desktopDir = Split-Path -Parent $dst
Info ''
Info "源文件 : $src"
Info "桌面   : $desktopDir"
Info "目标   : $dst"

# ---------- 2. 结束正在运行的实例 ----------
Info ''
Info '[1/4] 结束正在运行的程序 ...'
$killed = 0
Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -eq '游戏快捷键锁' -or ($_.Path -and $_.Path -eq $dst)
} | ForEach-Object {
    try { $_.Kill(); $killed++ } catch {}
}
Start-Sleep -Milliseconds 900
Info "    已结束 $killed 个进程"

# ---------- 3. 复制并校验 ----------
Info '[2/4] 复制新版本 ...'
try {
    [IO.File]::Copy($src, $dst, $true)
} catch {
    Warn '    直接覆盖失败（文件可能被占用），先重命名旧文件再试 ...'
    $bak = Join-Path $desktopDir ('游戏快捷键锁.old-{0}.exe' -f (Get-Date -Format 'HHmmss'))
    try { [IO.File]::Move($dst, $bak) } catch {}
    [IO.File]::Copy($src, $dst, $true)
}
Start-Sleep -Milliseconds 300

Info '[3/4] 校验 ...'
$s = Get-Item -LiteralPath $src
$d = Get-Item -LiteralPath $dst
$h1 = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
$h2 = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
Info ("    源  : {0,7} 字节  {1}" -f $s.Length, $s.LastWriteTime)
Info ("    桌面: {0,7} 字节  {1}" -f $d.Length, $d.LastWriteTime)
if ($h1 -ne $h2) {
    Warn '    校验失败：两个文件内容不一致！'
    Read-Host '按回车退出'
    exit 1
}
Ok '    校验通过（SHA256 一致）'
$ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dst)
Ok ("    桌面版本: " + $ver.FileVersion)

# ---------- 4. 启动 ----------
Info ''
Info '[4/4] 启动新版本 ...'
Start-Process -FilePath $dst
Start-Sleep -Milliseconds 700

Ok ''
Ok '完成！请打开程序，确认左上角显示 v1.2.0'
Info '如果左上角没有版本号，说明复制的还是旧文件，把本窗口截图发我。'
Write-Host ''
Read-Host '按回车退出'