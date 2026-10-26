@echo off
title Dong Bo GitHub - Tan The Gioi
chcp 65001 >nul
echo ========================================================
echo 🔄 ĐANG ĐỒNG BỘ DỰ ÁN VỚI GITHUB (2 CHIỀU)
echo ========================================================
echo.

echo ⬇️ 1. Đang kéo thay đổi từ GitHub về máy (git pull)...
git pull origin main
echo.

echo ⬆️ 2. Đang kiểm tra thay đổi trên máy để đẩy lên GitHub...
git add .
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "Cap nhat tu dong - %date% %time%"
    git push origin main
    echo.
    echo ✅ ĐÃ ĐẨY CÁC THAY ĐỔI MỚI LÊN GITHUB THÀNH CÔNG!
) else (
    echo.
    echo ℹ️ Máy tính của bạn không có tệp nào mới cần đẩy lên.
)

echo.
echo ========================================================
echo 🎉 HOÀN TẤT ĐỒNG BỘ!
echo ========================================================
timeout /t 3
