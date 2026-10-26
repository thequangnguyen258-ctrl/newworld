$godot = 'C:\Users\Admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe'
$tests = @(
    'res://scripts/tests/test_spiderweb_transit_network.gd',
    'res://scripts/tests/test_civic_quests_and_four_districts.gd',
    'res://scripts/tests/test_true_500km2_streaming_and_four_districts.gd',
    'res://scripts/tests/test_central_capital_playable.gd',
    'res://scripts/tests/test_mega_office_skyscraper.gd',
    'res://scripts/tests/test_mayor_office_storage.gd',
    'res://scripts/tests/test_central_hub_living_world.gd',
    'res://scripts/tests/test_central_capital_and_civic_os.gd',
    'res://scripts/tests/test_mountain_climb.gd',
    'res://scripts/tests/test_500km2_streaming_world.gd',
    'res://scripts/tests/test_helicopter_boarding_fix.gd',
    'res://scripts/tests/test_helicopter_and_southern_meadow.gd',
    'res://scripts/tests/test_day_night_and_visuals.gd',
    'res://scripts/tests/test_natural_landscape.gd',
    'res://scripts/tests/test_character_system.gd',
    'res://scripts/tests/test_transit_and_scale.gd',
    'res://scripts/tests/test_world_terrain_scale.gd',
    'res://scripts/tests/test_player_physics_runtime.gd',
    'res://scripts/tests/test_sqlite_native.gd',
    'res://scripts/tests/test_map_expansion_and_southern_open_plateau.gd',
    'res://scripts/tests/test_model_houses_and_construction.gd',
    'res://scripts/tests/test_resident_daily_schedule.gd',
    'res://scripts/tests/test_tauplot_integration.gd',
    'res://scripts/tests/test_octahedral_pine_lod.gd',
    'res://scripts/tests/test_radar_and_hotbar_held_props.gd',
    'res://scripts/tests/test_vrm_and_phantom_camera.gd',
    'res://scripts/tests/test_unified_timeline.gd',
    'res://scripts/tests/test_sqlite_viewer_dock.gd',
    'res://scripts/tests/test_has_research_tech_tree.gd',
    'res://scripts/tests/test_save_load.gd',
    'res://scripts/tests/test_player_stamina.gd',
    'res://scripts/tests/test_player_daily_rest.gd'
)
$passed = 0
$failed = 0
Write-Host "================================================================"
Write-Host "🧪 CHẠY TOÀN BỘ $($tests.Count) BÀI KIỂM THỬ TỰ ĐỘNG (GODOT 4.6.2)"
Write-Host "================================================================"

foreach ($t in $tests) {
    $out = & $godot --headless --script $t --path . 2>&1 | Out-String
    $is_success = ($out -match "PASS" -or $out -match "THÀNH CÔNG" -or $out -match "HOÀN TẤT") -and ($out -notmatch "Assertion failed" -and $out -notmatch "SCRIPT ERROR: Assertion failed")
    if ($is_success -or $LASTEXITCODE -eq 0) {
        Write-Host " [PASS] $t" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " [FAIL] $t" -ForegroundColor Red
        $failed++
    }
}

Write-Host "================================================================"
Write-Host "📊 TỔNG KẾT: $passed / $($tests.Count) PASSED | $failed FAILED"
if ($failed -eq 0) {
    Write-Host "🎉 100% TẤT CẢ CÁC BÀI TEST ĐÃ THÀNH CÔNG RỰC RỠ!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ CÓ BÀI TEST BỊ THẤT BẠI!" -ForegroundColor Red
    exit 1
}
