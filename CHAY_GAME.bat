@echo off
chcp 65001 >nul
title Tân Thế Giới - 3D Open World (500 km²)
echo ================================================================
echo 🎮 TÂN THẾ GIỚI - 3D OPEN WORLD LIFE SIMULATOR (500 KM²)
echo ================================================================
echo - [W, A, S, D / Phím Mũi Tên] : Di chuyển nhân vật
echo - [Shift]                      : Tăng tốc chạy (Sprint)
echo - [Space]                      : Nhảy
echo - [E]                          : Tương tác / Trò chuyện NPC / Lên xe
echo - [F]                          : Lên / Xuống Xe Buggy Điện & Trực Thăng
echo - [1 / 2]                      : Dùng Bánh Mì Baguette / Trà Thảo Mộc
echo - [I]                          : Mở Túi Đồ Thị Trưởng (Inventory)
echo - [M / Tab]                    : Mở Tablet Bản Đồ Toàn Cảnh 500 km²
echo - [V]                          : Đổi Góc Nhìn Thứ 3 (Third-Person) / Thứ Nhất
echo - [T / F5]                     : Tua Nhanh Qua Đêm (Đón bình minh 06:00)
echo - [Esc]                        : Bật / Tắt con trỏ chuột
echo ================================================================
echo Đang khởi động Godot Engine 4.6.2...
start "" "C:\Users\Admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe" --path "%~dp0."
