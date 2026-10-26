# QUY CHUẨN KỸ THUẬT & THIẾT KẾ DỰ ÁN TÂN THẾ GIỚI

### RULE: VIETNAMESE_IME_INPUT_BULLETPROOFING
- **Nguyên nhân**: Khi người dùng chơi game bật Unikey / EVKey ở chế độ Tiếng Việt (Telex/VNI), các phím điều khiển `WASD` bị bộ gõ chuyển thành ký tự có dấu (`ư`, `s`, `đ`, `â`), làm mất tín hiệu phím chuẩn dẫn đến nhân vật không di chuyển được.
- **Ràng buộc bắt buộc**:
  1. Trong `project.godot` (InputMap), luôn khai báo đồng thời cả `keycode` và `physical_keycode` cho mọi action di chuyển và tương tác (`move_forward`, `move_backward`, `move_left`, `move_right`, `jump`, `interact`).
  2. Trong các script Controller (như `PlayerController`), phải lập trình cơ chế Fallback trực tiếp phần cứng:
     - Dùng `Input.is_physical_key_pressed()` cho các phím W, A, S, D, Q, Z.
     - Luôn hỗ trợ song song 4 phím Mũi Tên (`KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT`).

### RULE: CONTINUOUS_ELEVATION_FUNCTION_FOR_MODULAR_TERRAIN
- **Nguyên nhân**: Sử dụng các mảng bậc thang rời rạc trong từng chunk địa hình tạo ra các vách đứng $70^\circ - 90^\circ$ chắn ngang không thể leo được và bị nứt khe hở giữa các chunk.
- **Ràng buộc bắt buộc**:
  1. Mọi chunk và mọi vật thể tự nhiên (cây cối, hoa dại, đá cuội, NPC) trong thế giới mở phải truy vấn cùng một hàm toán học liên tục `ModularNatureChunk.get_world_height(wx, wz)`.
  2. Khu vực phía sau Mega Office phải giữ cao nguyên bằng phẳng ở +600m, không tạo đỉnh núi che khuất tòa nhà. Những cung đường núi ở khu vực khác phải có đường mòn leo núi với độ dốc $\le 20^\circ$.
  3. Thứ tự các đỉnh tam giác của quad địa hình luôn tuân thủ winding counter-clockwise `(v00, v10, v01)` và `(v10, v11, v01)` để pháp tuyến luôn hướng thẳng lên trời $(0, 1, 0)$, cho phép `is_on_floor()` luôn nhận diện chính xác.

### RULE: CHARACTERBODY3D_SLOPE_SNAPPING
- **Ràng buộc bắt buộc**:
  1. Mọi `CharacterBody3D` di chuyển trên địa hình tự nhiên phải thiết lập:
     - `floor_snap_length = 0.5`
     - `floor_max_angle = deg_to_rad(60.0)`
     - `floor_stop_on_slope = true`
     - `floor_block_on_wall = true`
  2. Khi di chuyển xuống dốc núi, `apply_floor_snap()` giúp nhân vật bám sát mặt đất, không bị nảy tưng tưng hoặc rơi tự do giữa các sườn đồi.

### RULE: NHVC_VOLUNTEER_ORGANIZATION
- **Quy chuẩn**: Nhân sự việc Chúa (NHVC) Part-Time **tuyệt đối không nhận lương hay phụ cấp tiền tệ**. Họ là Tình Nguyện Viên tự nguyện 100%, có nghề đời sống riêng để nuôi sống bản thân.
- **Cơ cấu phân cấp**: `Hội Trưởng (Trưởng khu vực)` $\rightarrow$ `Nhóm Trưởng` $\rightarrow$ `Tổ Trưởng` $\rightarrow$ `Thành Viên Tổ`.

### RULE: NIGHT_SKIP_SIMULATION_MECHANISM
- **Quy chuẩn**: Cung cấp đồng thời 3 cơ chế: Về giường đi ngủ `[E]` (Life Sim), Phím bấm Tua đến 06:00 trên Tablet/HUD `[T]` / `[F5]` (City Builder), và Tùy chọn Auto-Skip trong Cài Đặt.
- Động cơ `SimulationEngine` chạy tính toán gộp tức thì (**Batch Timestep**) trong RAM cho 7 giờ đêm để đảm bảo hiệu năng và không bắt người chơi phải chờ đợi.

### RULE: END_TO_END_INTERACTION_TESTING_STANDARD
- **Nguyên nhân**: Viết các bài test chỉ gọi hàm nội bộ (ví dụ: `heli.board(player)`, `dialog.open()`) tạo cảm giác an toàn giả mạo khi bài test đạt 100% Pass nhưng người chơi thực tế vào game lại không thể tương tác được (do lệch layer vật lý, thiếu phím, hoặc thiếu cập nhật tín hiệu).
- **Ràng buộc bắt buộc**:
  1. TUYỆT ĐỐI CẤM: Viết bài test chỉ gọi trực tiếp method nội bộ rồi kết luận tính năng đã hoàn thành.
  2. BẮT BUỘC: Mọi bài test kiểm thử tương tác người chơi phải thực hiện quy trình End-to-End:
     - Bước 1: Khởi tạo scene thực tế và đặt Player từ khoảng cách xa bước vào cự ly tương tác ($\le 6.0\text{m} - 7.5\text{m}$).
     - Bước 2: Chạy ít nhất 2 - 5 physics frames để xác nhận tín hiệu nhận diện kích hoạt (`nearby_*` meta, cảm biến Area3D).
     - Bước 3: Kiểm tra bảng chữ 3D thông báo (`prompt_3d.visible == true`).
     - Bước 4: Tạo sự kiện bàn phím thực tế `InputEventKey` (gồm cả keycode & physical_keycode) và truyền qua `_input()` / `_unhandled_input()`.
     - Bước 5: Xác nhận trạng thái chuyển đổi thành công sau khi nhấn phím (ví dụ: chuyển camera, kích hoạt HUD, ẩn nhân vật, lên xe).

### RULE: INTERACTIVE_OBJECT_DUAL_LAYER_SAFETY
- **Nguyên nhân**: Godot Area3D mặc định chỉ có `collision_mask = 1`, trong khi Player thường ở Layer 2 (`collision_layer = 2`), dẫn đến việc `body_entered` không kích hoạt nếu cấu hình thiếu mask.
- **Ràng buộc bắt buộc**:
  1. Lớp 1 (Physics Collision): Mọi `Area3D` tương tác (Xe cộ, Máy bay, Cửa, Rương, NPC, Công trình) luôn phải thiết lập `collision_layer = 1 | 2 | 4` và `collision_mask = 1 | 2 | 4`. Bán kính nhận diện phải rộng rãi ($\ge 6.0\text{m} - 7.5\text{m}$ cho phương tiện).
  2. Lớp 2 (Distance Fallback Redundancy): Trong `_process()` hoặc `_input()`, luôn lập trình sẵn nhánh fallback đo khoảng cách `global_position.distance_to(player.global_position) <= radius`. Nếu người chơi đứng trong bán kính, lập tức cho phép tương tác ngay cả khi engine vật lý gặp trục trặc hay lệch layer.
  3. Đa phím tương tác: Luôn hỗ trợ song song cả phím đặc thù (như `[F]`) và phím tương tác phổ biến `[E]`. Quét cả `keycode` và `physical_keycode` để bulletproof chống kẹt bộ gõ Unikey / EVKey.

### RULE: DIEGETIC_UI_PROMPT_VISIBILITY_STANDARD
- **Nguyên nhân**: Bảng chữ 3D nhắc phím bị thân vỏ máy bay, tán cây hoặc hình học che lấp nếu bật kiểm tra chiều sâu (depth test) mặc định, khiến người chơi không biết cần bấm phím gì.
- **Ràng buộc bắt buộc**:
  1. Mọi bảng chữ 3D (`Label3D`) nhắc lệnh tương tác trong thế giới bắt buộc phải:
     - `billboard = BaseMaterial3D.BILLBOARD_ENABLED` (luôn quay mặt về phía camera người chơi).
     - `no_depth_test = true` (không bao giờ bị geometry, kính xe hay tán cây che khuất khi đứng gần).
     - `outline_size >= 8`, màu sắc tương phản cao (vàng kim `#FFD700` hoặc lam sáng) kèm viền đen đậm.
  2. Thanh hướng dẫn dưới đáy màn hình (`HintLabel` trên HUD) phải luôn phản ánh đầy đủ các phím ngữ cảnh hiện hành (`[W,A,S,D]`, `[F/E] Tương tác`, `[M] Tablet`, `[V] Góc nhìn`, `[Space] Nhảy`, `[Esc] Chuột`).

### RULE: PEDESTRIAN_FIRST_URBAN_ZONING_AND_SKYDECK_HELIPAD
- **Quy định**: Quảng Trường Hòa Bình và các tuyến phố đi bộ trung tâm Vành Đai 1 là không gian dành 100% cho người đi bộ, xe tram cổ điển và xe buggy tuần tra nhẹ.
- **Phương tiện hàng không**: Trực thăng (Helicopter) và Sân đỗ (Helipad) bắt buộc phải đặt trên **Sân Thượng Tầng 15 Skydeck** (+124.6m / +724.6m) hoặc Bãi đáp Ngoại vi cách xa quảng trường ($R > 50\text{m}$), tuyệt đối không để chắn lối đi bộ trước các cửa tiệm dân sinh.

### RULE: FLORA_SCATTER_EXCLUSION_ZONE
- **Quy định**: Mọi thuật toán gieo mầm ngẫu nhiên (`NatureFloraScatter`, đá cuội, cây cối, hoa dại) phải áp dụng điều kiện loại trừ tối thiểu $R \ge 40.0\text{m}$ tính từ tâm Quảng Trường Trung Tâm $(0, 0)$ để tránh hiện tượng đá cuội và thân cây xuyên qua gạch lát hoặc nội thất tòa nhà.

### RULE: IN_EDITOR_FIDELITY_STANDARD
- **Quy định**: Các Node quản lý kiến trúc thủ tục như `CentralCapitalComplex` và `InteractiveStation` phải khai báo `@tool` để khi mở Godot Editor (`MO_EDITOR_GODOT.bat`), Developer và User nhìn thấy ngay toàn cảnh công trình trong cửa sổ 3D Viewport mà không bị bãi đất trống.

### RULE: AUTOLOAD_NAMING_AND_DEPENDENCY_RESILIENCE_STANDARD
- **Nguyên nhân**: Khi một script có `class_name Foo` và đồng thời được đăng ký trong `project.godot` là `Foo="*res://..."`, Godot 4 sẽ báo lỗi biên dịch nghiêm trọng: `Parse Error: Class "Foo" hides an autoload singleton`. Đồng thời, trong môi trường kiểm thử Headless (`extends SceneTree`), Autoloads không được nạp tự động trước `_init()`.
- **Ràng buộc bắt buộc**:
  1. Tuyệt đối không dùng `class_name` trùng tên với Autoload Singleton. Mọi script đăng ký Autoload trong `project.godot` phải khai báo bằng `extends Node` (hoặc lớp cơ sở tương ứng).
  2. Singleton truy xuất cơ sở dữ liệu (`DatabaseManager`) hoặc thế giới (`WorldManager`) phải hỗ trợ Fallback 4 tầng: `cached_reference` -> `Engine.has_singleton()` -> `has_node("/root/...")` -> `get_parent().has_node(...)`.
  3. Cung cấp sẵn các hàm setter (ví dụ: `set_world_manager()`, `set_database_manager()`) để các bài test độc lập có thể tiêm mock/instance mà không phụ thuộc vào thứ tự nạp của SceneTree.
  4. Mọi câu lệnh `get_node(...)` truy xuất đường dẫn tuyệt đối bắt buộc phải được bảo vệ bởi điều kiện `if is_inside_tree() and has_node(...)` để không phát sinh lỗi cảnh báo engine khi khởi tạo ngoài cây.

### RULE: DECOUPLED_MECHANICAL_SIMULATION_STANDARD
- **Nguyên nhân**: Khi các tính toán hao mòn cơ khí (như hao mòn xe cộ `MayorBuggy`, máy phát điện, trạm lọc) lồng chặt trong hàm đọc phím bấm người chơi (`_handle_driving_input`), các bài test tự động không có phím bấm vật lý sẽ không thể kích hoạt hoặc kiểm chứng được tính chính xác của công nghệ R&D (ví dụ: giảm 21% hao mòn).
- **Ràng buộc bắt buộc**:
  1. Mọi vật thể tương tác có tích lũy chỉ số hao mòn hoặc biến đổi trạng thái cơ học phải phân tách rõ ràng giữa **Tầng Đọc Input Người Chơi** (`_handle_driving_input`) và **Tầng Tính Toán Cơ Khí/Vật Lý Thuần Túy** (`apply_driving_wear(speed, delta)`).
  2. Tầng Tính Toán Cơ Khí phải nhận tham số đầu vào tường minh, cho phép các kịch bản kiểm thử End-to-End mô phỏng chính xác hành vi máy móc trong môi trường không có thiết bị ngoại vi vật lý (Headless CI/CD).
