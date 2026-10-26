@echo off
chcp 65001 >nul
title Kiem Thu Toan Bo - Tan The Gioi
echo ================================================================
echo 🧪 CHẠY TOÀN BỘ KIỂM THỬ TỰ ĐỘNG - TÂN THẾ GIỚI (25 BÀI TEST)
echo ================================================================

set GODOT_BIN="C:\Users\Admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"
set FAILED_COUNT=0
set PASSED_COUNT=0

call :run_test "Hệ Thống Giao Thông Mạng Nhện 5 Vành Đai" "res://scripts/tests/test_spiderweb_transit_network.gd"
call :run_test "Nhiệm Vụ Dân Sinh 5 Huyện & Đô Thị 12/12" "res://scripts/tests/test_civic_quests_and_four_districts.gd"
call :run_test "Đại Thế Giới 500 km² Thật Sự & 4 Huyện Ngoại Vi" "res://scripts/tests/test_true_500km2_streaming_and_four_districts.gd"
call :run_test "Thủ Phủ Trung Tâm Đỉnh Vát Hoàn Thiện & Playable" "res://scripts/tests/test_central_capital_playable.gd"
call :run_test "Tòa Mega-Office Skyscraper 68M & Thang Máy Kính" "res://scripts/tests/test_mega_office_skyscraper.gd"
call :run_test "Văn Phòng Thị Trưởng Tầng 13 & Kho Riêng" "res://scripts/tests/test_mayor_office_storage.gd"
call :run_test "Đô Thị Trung Tâm Sống Động, Anime RPG & Túi Đồ" "res://scripts/tests/test_central_hub_living_world.gd"
call :run_test "Trung Tâm Đỉnh Vát & Tablet Civic OS 6 Ứng Dụng" "res://scripts/tests/test_central_capital_and_civic_os.gd"
call :run_test "Leo Đỉnh Núi Cao 710M & Đường Mòn Thiên Nhiên" "res://scripts/tests/test_mountain_climb.gd"
call :run_test "Đại Thế Giới 500 km² & Dynamic Streaming Chunks" "res://scripts/tests/test_500km2_streaming_world.gd"
call :run_test "Lên / Xuống Trực Thăng Bằng Phím [F] & [E]" "res://scripts/tests/test_helicopter_boarding_fix.gd"
call :run_test "Trực Thăng Cao Tốc 324 km/h & Thảo Nguyên Nam" "res://scripts/tests/test_helicopter_and_southern_meadow.gd"
call :run_test "Chu Kỳ Ngày - Đêm & Ánh Sáng Anime Toon" "res://scripts/tests/test_day_night_and_visuals.gd"
call :run_test "Cảnh Quan Non Nước Tự Nhiên & Biển Mây Anime" "res://scripts/tests/test_natural_landscape.gd"
call :run_test "Hệ Thống Nhân Vật, Độ Tuổi, Trang Phục & Thẻ CCCD" "res://scripts/tests/test_character_system.gd"
call :run_test "Quy Mô 5 Huyện, Vận Tốc Giao Thông & TNV NHVC" "res://scripts/tests/test_transit_and_scale.gd"
call :run_test "Địa Hình 3D, Cao Độ +600M & Mô Hình Thủy Văn" "res://scripts/tests/test_world_terrain_scale.gd"
call :run_test "Vật Lý Runtime, Quay Chuột/Phím & Góc Nhìn 1/3" "res://scripts/tests/test_player_physics_runtime.gd"
call :run_test "Giao Thức SQLite Native CSDL Hộ Tịch" "res://scripts/tests/test_sqlite_native.gd"
call :run_test "Mở Rộng Bản Đồ 500 km² & Cao Nguyên Nam 12km" "res://scripts/tests/test_map_expansion_and_southern_open_plateau.gd"
call :run_test "Đại Lộ Nhà Mẫu, Mua Đất & Xây Dựng Hoàn Thiện [E]" "res://scripts/tests/test_model_houses_and_construction.gd"
call :run_test "Lịch Trình Sinh Hoạt 6 Khung Giờ Cư Dân 5 Huyện" "res://scripts/tests/test_resident_daily_schedule.gd"
call :run_test "Lưu / Nạp Vị Trí, Thời Gian, Ngân Khố & Nhà Ở" "res://scripts/tests/test_save_load.gd"
call :run_test "Chạy Nước Rút, Hồi Thể Lực & Giới Hạn Khi Kiệt Sức" "res://scripts/tests/test_player_stamina.gd"
call :run_test "Sinh Hoạt Hằng Ngày: Nghỉ Đêm & Hồi Phục Tại Giường" "res://scripts/tests/test_player_daily_rest.gd"

echo.
echo ================================================================
echo 📊 KẾT QUẢ TỔNG HỢP KIỂM THỬ:
echo - Thành công: %PASSED_COUNT% / 25
echo - Thất bại : %FAILED_COUNT% / 25
echo ================================================================
if %FAILED_COUNT% EQU 0 (
    echo 🎉 TOÀN BỘ 25 BÀI KIỂM THỬ ĐÃ ĐẠT 100%% PASS!
) else (
    echo ❌ CÓ %FAILED_COUNT% BÀI TEST BỊ LỖI!
)
pause
exit /b %FAILED_COUNT%

:run_test
set TEST_NAME=%~1
set TEST_SCRIPT=%~2
echo.
echo [TEST] %TEST_NAME% ...
%GODOT_BIN% --headless --script %TEST_SCRIPT% --path "%~dp0." >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   ==^> ✅ PASS
    set /a PASSED_COUNT+=1
) else (
    echo   ==^> ❌ FAIL (Exit Code: %ERRORLEVEL%)
    set /a FAILED_COUNT+=1
)
exit /b 0
