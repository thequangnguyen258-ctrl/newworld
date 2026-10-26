# TÂN THẾ GIỚI - DỰ ÁN GAME NGUYÊN BẢN (GODOT 4.6.2)

Tài liệu quy tắc và hướng dẫn phát triển cho AI Assistant và Developers.

## 1. CÁC QUY TẮC CỐT LÕI (CORE RULES)
Chi tiết các quy tắc kỹ thuật được lưu trữ tại: [.agents/rules/tan_the_gioi_game_rules.md](file:///d:/Eaut/GMAE/game%20t%C3%A2n%20th%E1%BA%BF%20gi%E1%BB%9Bi/.agents/rules/tan_the_gioi_game_rules.md)

1. **Chống kẹt phím Bộ Gõ Tiếng Việt (Vietnamese IME Bulletproofing)**:
   - Trong `project.godot`, mọi Action di chuyển đều phải đăng ký cả `keycode` và `physical_keycode`.
   - Trong `PlayerController`, luôn hỗ trợ quét `Input.is_physical_key_pressed()` và 4 phím Mũi Tên (`KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT`).
2. **Hàm độ cao địa hình liên tục (Continuous Elevation Function)**:
   - Toàn bộ các chunk, cây cối, hoa dại, đá cuội và NPC ngoài thực địa đều phải truy vấn độ cao thông qua `ModularNatureChunk.get_world_height(wx, wz)`.
   - Khu vực phía sau Mega Office phải giữ cao nguyên bằng phẳng ở +600m, không tạo đỉnh núi che khuất tòa nhà. Những cung đường núi khác phải có đường mòn leo núi với độ dốc $\le 20^\circ$.
3. **Bám dốc cho CharacterBody3D (Slope Snapping)**:
   - Thiết lập `floor_snap_length = 0.5`, `floor_max_angle = deg_to_rad(60.0)`, `floor_stop_on_slope = true` cho mọi CharacterBody3D.
4. **Cơ cấu Tình Nguyện Viên NHVC (Part-Time)**:
   - NHVC Part-Time phục vụ tự nguyện 100%, không nhận lương tiền tệ, có nghề đời sống riêng.
5. **Cơ chế Night Skip**:
   - Hỗ trợ phím tắt `[T]` / `[F5]` và giường ngủ `[E]` để tua nhanh qua đêm sang 06:00 sáng.
6. **Kiểm thử tương tác End-to-End (End-to-End Interaction Testing Standard)**:
   - TUYỆT ĐỐI CẤM: Viết test chỉ gọi trực tiếp hàm nội bộ (ví dụ `heli.board()`, `npc.talk()`) rồi kết luận tính năng hoàn thành.
   - BẮT BUỘC: Test phải mô phỏng Player bước vào cự ly $\rightarrow$ kiểm tra cảm biến/Area3D $\rightarrow$ kiểm tra bảng 3D hiện lên $\rightarrow$ truyền sự kiện phím vật lý `InputEventKey` $\rightarrow$ kiểm tra kết quả hành động.
7. **Bảo hiểm 2 lớp cho vật thể tương tác (Dual-Layer Safety)**:
   - Mọi `Area3D` tương tác luôn phải đặt `collision_layer = 1 | 2 | 4` và `collision_mask = 1 | 2 | 4` (bán kính $\ge 6.0\text{m}$).
   - Bắt buộc lập trình cơ chế Fallback đo khoảng cách `distance_to(player) <= radius` trong `_process()` hoặc `_input()` để bảo đảm 100% người chơi tương tác được ngay cả khi engine vật lý bị trễ tick hoặc lệch layer.
   - Luôn hỗ trợ đa phím: Song song cả phím đặc thù (`[F]`) và phím phổ thông (`[E]`).
8. **Bảng chữ 3D nhắc lệnh xuyên thấu (Diegetic UI Visibility)**:
   - Mọi `Label3D` nhắc phím bắt buộc phải bật `billboard = BaseMaterial3D.BILLBOARD_ENABLED` và `no_depth_test = true` để không bị chi tiết 3D che khuất.
   - Thanh hướng dẫn `HintLabel` trên HUD đáy màn hình luôn cập nhật đầy đủ các phím chức năng ngữ cảnh hiện hành.
9. **Ưu tiên phố đi bộ & Sân đỗ trực thăng Skydeck (Pedestrian-First Urban Zoning)**:
   - Quảng Trường Hòa Bình trung tâm dành 100% cho người đi bộ, xe tram và xe buggy nhẹ. Sân đỗ trực thăng (Helipad) bắt buộc phải nằm trên Sân Thượng Tầng 15 Skydeck (+124.6m / +724.6m) hoặc bãi đáp ngoại vi.
10. **Vùng đệm loại trừ thảm thực vật tự nhiên (Flora Scatter Exclusion Zone)**:
   - Các thuật toán rải cây cỏ, đá cuội phải áp dụng vùng loại trừ tối thiểu $R \ge 40\text{m}$ tính từ tâm quảng trường $(0,0)$.
11. **Tiêu chuẩn `@tool` hiển thị trực quan trong Godot Editor (In-Editor Fidelity Standard)**:
   - Các Node quản lý kiến trúc thủ tục như `CentralCapitalComplex` phải khai báo `@tool` để hiển thị trực quan trong cửa sổ 3D Viewport khi mở Godot Editor.
12. **Chuẩn Hóa Đặt Tên & Khởi Tạo Autoload (Autoload Naming & Resilience Standard)**:
   - Tuyệt đối không dùng `class_name` trùng tên với Autoload Singleton.
   - Singleton truy xuất cơ sở dữ liệu (`DatabaseManager`) hoặc thế giới (`WorldManager`) hỗ trợ Fallback 4 tầng và phương thức tiêm phụ thuộc cho Headless Tests.
13. **Phân Tách Hàm Mô Phỏng Cơ Khí (Decoupled Mechanical Simulation Standard)**:
   - Tách biệt rõ giữa Tầng Đọc Phím Bấm (`_handle_driving_input`) và Tầng Tính Toán Cơ Khí/Hao Mòn Thuần Túy (`apply_driving_wear(speed, delta)`) để hỗ trợ kiểm thử Headless CI/CD xác định.
