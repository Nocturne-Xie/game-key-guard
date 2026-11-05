#Requires -Version 5.1
# 把本地仓库里所有历史提交的作者改成当前 GitHub 账户，并强制推送
$NewName  = 'Nocturne-Xie'
$NewEmail = '328263129+Nocturne-Xie@users.noreply.github.com'
$RepoUrl  = 'https://github.com/Nocturne-Xie/game-key-guard.git'
$Branch   = 'main'

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$Host.UI.RawUI.WindowTitle = 'Fix Git Author'
Set-Location -LiteralPath $PSScriptRoot

function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Dim($m)  { Write-Host $m -ForegroundColor DarkGray }

Info '==============================================='
Info '  把历史提交作者改为：Nocturne-Xie'
Info '==============================================='

$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) { Warn '没有找到 git'; Read-Host '按回车退出'; exit 1 }

# ---------- 1 ----------
Info "`n[1/5] 设置本地提交身份 ..."
& $git config user.name  $NewName
& $git config user.email $NewEmail
Dim ("    user.name  = " + (& $git config user.name))
Dim ("    user.email = " + (& $git config user.email))

# ---------- 2 ----------
Info "[2/5] 关联新仓库地址 ..."
& $git remote remove origin > $null 2>&1
& $git remote add origin $RepoUrl
& $git branch -M $Branch
Dim "    origin -> $RepoUrl"

# ---------- 3 ----------
Info "[3/5] 提交当前文件改动（LICENSE、发布脚本里的新用户名）..."
& $git add -A
& $git commit -m "更新作者信息为 Nocturne-Xie" 2>&1 | ForEach-Object { Dim ("    " + $_) }

# ---------- 4 ----------
Info "[4/5] 重写全部历史提交的作者（可能需要十几秒）..."
$filter = "export GIT_AUTHOR_NAME='$NewName'; export GIT_AUTHOR_EMAIL='$NewEmail'; export GIT_COMMITTER_NAME='$NewName'; export GIT_COMMITTER_EMAIL='$NewEmail'"
& $git filter-branch -f --env-filter $filter -- --all 2>&1 | ForEach-Object { Dim ("    " + $_) }

# ---------- 5 ----------
Info "[5/5] 强制推送到 GitHub ..."
& $git push --force-with-lease origin $Branch 2>&1 | ForEach-Object { Dim ("    " + $_) }
if ($LASTEXITCODE -ne 0) {
    Warn "    --force-with-lease 失败，改用 --force 再试 ..."
    & $git push --force origin $Branch 2>&1 | ForEach-Object { Dim ("    " + $_) }
}
if ($LASTEXITCODE -ne 0) {
    Warn "`n推送失败。可能原因："
    Warn "  1) 浏览器登录未完成 —— 重新双击本脚本再试"
    Warn "  2) 网络/代理问题"
    Warn "  3) 远程仓库有其他人的新提交 —— 截图发我"
    Read-Host '按回车退出'
    exit 1
}

Ok "`n完成！历史提交作者已经全部改为 $NewName"
Info "`n当前提交记录："
& $git log --format='    %h  %an <%ae>  %s'
Info "`n仓库地址: https://github.com/Nocturne-Xie/game-key-guard"
Write-Host ''
Read-Host '按回车退出'