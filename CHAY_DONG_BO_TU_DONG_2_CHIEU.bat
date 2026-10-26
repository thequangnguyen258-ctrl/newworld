@echo off
title AutoGitSync - Tan The Gioi
chcp 65001 >nul
cd /d "%~dp0"

echo ==========================================================
echo 🚀 KHOI CHAY DONG BO TU DONG 2 CHIEU VOI GITHUB
echo ==========================================================
echo.
echo Cua so nay se chay ngam:
echo   - Tu dong day len GitHub moi khi ban sua code/asset
echo   - Tu dong keo ve may moi khi ban sua tren GitHub
echo.
echo Ban co the thu nho cua so nay xuong thanh Taskbar.
echo ==========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\tools\auto_git_sync.ps1"
