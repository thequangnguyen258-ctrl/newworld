# Auto Git Sync - Công cụ tự động đồng bộ Git 2 chiều
param(
    [int]$IntervalSeconds = 15
)

$Host.UI.RawUI.WindowTitle = "AutoGitSync - Tan The Gioi"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🤖 CÔNG CỤ TỰ ĐỘNG ĐỒNG BỘ GIT 2 CHIỀU (REAL-TIME SYNC) " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "• Máy tính  ---> GitHub : Tự động Commit & Push khi bạn sửa file" -ForegroundColor White
Write-Host "• GitHub   ---> Máy tính : Tự động Pull khi có cập nhật trên web" -ForegroundColor White
Write-Host "• Chu kỳ quét: $IntervalSeconds giây / lần" -ForegroundColor Gray
Write-Host "• Nhấn Ctrl + C để dừng công cụ bất kỳ lúc nào" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $repoRoot

while ($true) {
    try {
        $timestamp = Get-Date -Format "HH:mm:ss"

        # 1. KÉO CẬP NHẬT TỪ GITHUB VỀ MÁY
        git fetch origin main 2>$null
        $localCommit = git rev-parse HEAD 2>$null
        $remoteCommit = git rev-parse origin/main 2>$null

        if ($localCommit -and $remoteCommit -and ($localCommit -ne $remoteCommit)) {
            $base = git merge-base HEAD origin/main 2>$null
            if ($base -eq $localCommit) {
                Write-Host "[$timestamp] ⬇️ Phát hiện có cập nhật mới trên GitHub! Đang kéo về máy..." -ForegroundColor Cyan
                git pull origin main --quiet 2>$null
                Write-Host "[$timestamp] ✅ Đã cập nhật xong vào máy!" -ForegroundColor Green
            }
        }

        # 2. ĐẨY CẬP NHẬT TỪ MÁY LÊN GITHUB
        $status = git status --porcelain
        if ($status) {
            Write-Host "[$timestamp] ⬆️ Phát hiện bạn vừa sửa file trên máy! Đang đẩy lên GitHub..." -ForegroundColor Magenta
            git add .
            $commitMsg = "Auto-sync: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            git commit -m $commitMsg --quiet 2>$null
            git push origin main --quiet 2>$null
            Write-Host "[$timestamp] ✅ Đã đẩy toàn bộ thay đổi lên GitHub thành công!" -ForegroundColor Green
        }
    }
    catch {
        # Bỏ qua lỗi kết nối mạng tạm thời
    }

    Start-Sleep -Seconds $IntervalSeconds
}
