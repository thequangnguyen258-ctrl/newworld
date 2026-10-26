@echo off
chcp 65001 > nul
title TÂN THẾ GIỚI - BẢNG ĐIỀU HÀNH THIẾT KẾ & KHÁI NIỆM (GODOT 4.6.2)
echo =======================================================================
echo  TÂN THẾ GIỚI — CONCEPT & DESIGN EXECUTIVE DASHBOARD
echo  Khởi chạy Bảng Điều Hành Trực Quan Hóa (5 Huyện, Iris Xe, 20 Bậc R&D, Godot-MCP)
echo =======================================================================
echo.
echo Đang mở Bảng Điều Hành trong trình duyệt mặc định...
start "" "%~dp0dashboard\index.html"
echo.
echo Đã mở thành công! Bạn có thể tương tác trực quan ngay trên trình duyệt.
timeout /t 3 > nul
exit
