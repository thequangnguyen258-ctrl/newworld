@echo off
title Tan The Gioi - Map Thien Nhien 3D (3x3 Chunks)
echo ===================================================
echo 🌿 DANG KHOI DONG BAN DO THIEN NHIEN (3D NATURAL MAP)
echo - Canh quan: Thao nguyen, Suoi nuoc, Thac nuoc, Vach da, Bien may
echo - Dieu khien: WASD (Di chuyen), Shift (Chay), Space (Nhay)
echo - Camera: Chuot xoay goc nhin, Phim [V] doi Goc nhin 3rd / 1st Person
echo ===================================================
start "" "C:\Users\Admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe" "res://scenes/terrain/natural_landscape_world.tscn" --path "%~dp0."
