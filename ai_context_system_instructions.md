# TECHNICAL SPECIFICATION & ARCHITECTURAL CONTRACT (FOR AI AGENTS)

> **MANDATORY NOTICE FOR AI ASSISTANTS / CODE GENERATORS**:
> You are operating as a core systems programmer, technical artist, and systems designer on a local-first, seamless 3D open-world city simulation developed with **Godot Engine 4.x**.
> Before generating code, shader blocks, or scene hierarchies (`.tscn`), review every section of this document. Violating hardware budgets (especially integrated GPU rendering constraints), breaking the seamless interior paradigm, or bypassing the autonomous citizen architecture is considered a critical architectural failure.
>
> **MASTER GAME DESIGN DOCUMENT (GDD)**: Xem [GAME_DESIGN_CONCEPT.md](file:///d:/Eaut/GMAE/game%20t%C3%A2n%20th%E1%BA%BF%20gi%E1%BB%9Bi/GAME_DESIGN_CONCEPT.md) để nắm toàn bộ triết lý cõi bất tử, cơ chế kinh tế, nhân khẩu học, 4 loại hình nhà ở, giao diện Tablet Thị Trưởng, phân quyền điều hành giữa Thị Trưởng & Người Chăn Chiên, thể chế hành chính 2 cấp, quy trình một cửa 5 bước và 10 dòng chảy xã hội học kiến tạo.

---

## 1. PROJECT METADATA & NORTH STAR

* **Title Concept**: Tân Thế Giới — High-Plateau Commune Simulation (Anime 3D / Stylized Cel-Shaded / Ghibli & Makoto Shinkai aesthetic).
* **Game Genre**: Single-Player 3D Open-World City Builder, Macro HR Governance & Walkable Life Simulator.
* **Architecture Style**: Local-first monolith. The game engine (Godot 4.x) and simulation logic run locally on the client machine with zero external cloud dependencies.
* **Visual Benchmark**: High-end Anime/Cel-shaded aesthetic (vibrant Ghibli skies, stepped toon lighting, inverted hull outlines, stylized water with foam lines, lush grass, vintage trams). **No PBR photogrammetry passes. No high-frequency normal roughness microfacets.**
* **Core Philosophy**:
  1. **Complete Seamless Traversal**: Entering any bank, house, shop, church, laboratory, or town hall is executed in real-time within the active world mesh without loading screens, scene swapping, or player teleportation.
  2. **Cõi Bất Tử Thanh Xuân & Quy Luật Hao Mòn Đồ Vật (Human Immortality vs Object Wear & Tear)**:
     * **Cõi Thánh Khiết — Không Tội Lỗi & Không Chết Chóc**: Nơi đây **tuyệt đối không còn tội lỗi, không còn chết chóc hay tà ác**. Cư dân sống trong sự thanh sạch, bao dung, nhân ái, coi nhau như anh em ruột thịt. Mãi mãi ở độ tuổi thanh xuân rực rỡ (20–25 tuổi).
     * **Đồ Vật, Máy Móc & Hạ Tầng Bị Hao Mòn & Lỗi Thời**: Chỉ có con người là bất tử; máy móc, xe cộ, lò nướng, quần áo bị hao mòn theo thời gian hoặc lỗi thời để thúc đẩy kinh tế mua sắm, nâng cấp và việc làm tuần hoàn.
  3. **Xã Hội Liêm Khiết & Huynh Đệ Thuần Khiết**: Tuyệt đối **KHÔNG CÓ THAM NHŨNG, KHÔNG CÓ RÚT RUỘT QUỸ CÔNG**. Mọi công dân và cán bộ đều trung thực, yêu thương nhau như anh em một nhà.
  4. **Kitô Giáo Hợp Nhất, Thần Linh Hiện Hữu & Tòa Nhà Văn Phòng Siêu To Trung Tâm**:
     * **Thần linh thật sự tồn tại**: Đức Chúa Trời và Chúa Jesus hiện diện sống động trong thế giới, ban phước cho đất đai trù phú, suối nguồn thanh khiết và sự bình an đời đời.
     * **Không còn Satan hay ma quỷ**: Thế lực bóng tối, quỷ dữ và sự cám dỗ tà ác đã bị loại trừ vĩnh viễn khỏi Tân Thế Giới; không có tà thuật hay bóng tối hắc ám.
     * **Tòa Nhà Văn Phòng Siêu To Trung Tâm $(X=0, Z=0)$**: Không phải thánh đường cổ điển, mà là một **Đại cao ốc văn phòng siêu to khổng lồ** (Mega-Office Skyscraper Complex) phong cách Anime hiện đại, tích hợp một **Đại hội trường / Sân vận động có mái che khổng lồ** bên trong để toàn bộ dân số quy tụ.
     * **Người Chăn Chiên (Sứ giả từ trời)**: Có Đức Chúa Trời (ĐCT) và Chúa Jesus ở cùng đời đời. Vì là cõi bất tử, **tuyệt đối không chuyển giao hay kế vị sứ mệnh**; Người là vị mục tử duy nhất và trường tồn.
     * **Lịch Phụng vụ (11:40 - 14:00 Thứ Tư & Chủ Nhật)**: **100% cư dân bắt buộc có mặt offline** tại Đại hội trường của Tòa nhà văn phòng trung tâm. Chỉ trừ số ít trường hợp bất khả kháng (nhà khoa học đang thí nghiệm gấp, bệnh nhân điều dưỡng chưa đi lại được, kỹ sư trực điện) mới theo dõi trực tuyến.
  5. **Autonomous Living Citizens (Free Will)**: Cư dân tự vận hành 100% theo thời gian biểu và nhu cầu. Người chơi không vi điều khiển từng bước đi của dân.
  6. **Macro HR Governance**: Người chơi thực thi quyền lực vĩ mô: quy hoạch, xây dựng công trình, tuyển dụng/sa thải theo bằng cấp chứng chỉ, điều chỉnh lương, và cấp ngân sách nghiên cứu.
  7. **Kinh Tế Thị Trường Tự Nhiên**: Quán xá làm ăn có lãi $\rightarrow$ Mở rộng tuyển dụng thêm nhân viên; Làm ăn thua lỗ $\rightarrow$ Cắt giảm $\rightarrow$ Phá sản đóng cửa.
  8. **Hệ Thống Hai Quỹ Tài Chính & Tiền Dâng Chúa 1/10 (The 1/10 Tithe System)**:
     * **Kho Bạc Đô Thị (City Treasury) & Ngân Hàng Nhà Nước**: Hệ thống ngân hàng nằm trọn trong tay hệ thống tài chính Nhà nước (Ban Tài chính & Kho Bạc). Nhà nước độc quyền định giá tự động và công bằng quyền in tiền bằng thuật toán, bảo chứng bằng sản lượng thực trong kho RAM `CityResourcePool` và năng lực sản xuất; quản trị thuế 5% để xây dựng hạ tầng, giao thông, trả lương công vụ.
     * **Quỹ Dâng Chúa 1/10 (Tiền Thập Phân Dân Sinh & Mục Vụ)**: Hàng tháng mỗi công dân trích đúng $1/10$ ($10\%$) thu nhập để dâng lên Chúa. Quỹ này được dùng minh bạch cho:
       * **Chế Độ Lương Sung Túc Cho Người Hầu Việc Chúa (NHVC) Full-time**: Gồm Người Chăn Chiên (NCC), các Người Đảm Nhiệm Nhà Thờ, Thư ký Đảm nhiệm, Nội Các 9 Trưởng Ban Chuyên Ngành (gồm Trưởng Ban Ca Ngợi & Thờ Phượng riêng) và Thư ký 9 Trưởng Ban. Được chu cấp **chung một mức lương đồng nhất, xứng đáng và sung túc** (tuyệt đối không phân biệt cấp bậc hay nam nữ). **Trang phục chuẩn mực là những bộ VEST lịch lãm, hiện đại, thanh lịch**.
       * **Đội Ngũ Tình Nguyện Viên Hỗ Trợ Chúa (NHVC Part-time — Hoàn Toàn Không Nhận Lương)**: Những công dân có nghề nghiệp đời sống (bác sĩ, giáo viên, thợ bánh, nghệ sĩ, kỹ sư...) tự nguyện dành thời gian rảnh để hỗ trợ Chúa và cộng đồng. **Tuyệt đối không nhận lương hay phụ cấp tiền tệ**. Hoạt động theo **mạng lưới chăm sóc 4 cấp**: *1 Hội Trưởng (Trưởng khu vực) quản lý các Nhóm Trưởng $\rightarrow$ 1 Nhóm Trưởng quản lý các Tổ Trưởng $\rightarrow$ 1 Tổ Trưởng quản lý các Thành Viên Tổ* để kịp thời lắng nghe, nâng đỡ và giúp đỡ mọi người.
       * **Sứ mạng Công Việc Hòa Bình (Works of Peace & Reconciliation)**:
         * Hàn gắn, giải hòa mọi hiểu lầm bất đồng trong tình yêu thương huynh đệ.
         * Viện trợ nhân đạo, đón tiếp và cung cấp chỗ ở ấm áp cho những lữ khách, người tị nạn từ thế giới bên ngoài tìm đến Tân Thế Giới.
         * Gửi tặng lương thực cứu trợ cho các vùng đất lân cận gặp thiên tai, lan tỏa thông điệp hòa bình và hữu nghị.
       * **Chăm lo đời sống dân sinh $100\%$**: Bữa tiệc Bác ái Thứ Tư & Chủ Nhật, miễn phí trà Onsen và điều dưỡng, tài trợ sách vở đàn cho học sinh, tổ chức lễ hội pháo hoa mùa màng.
  9. **Tỷ Lệ Thời Gian Vàng 1:20 (The 1:20 Golden Time Scale)**:
     * 1 giờ in-game = 3 phút đời thực.
     * 1 ngày đêm 24h trọn vẹn = **72 phút đời thực** (vừa vặn cho 1 phiên chơi game).
     * Giờ Thánh Lễ (11:40 - 14:00) = **7 phút đời thực** (thời lượng hoàn hảo cho 1 phân cảnh điện ảnh đắm chìm).
     * **Cơ Chế Bỏ Qua Ban Đêm (Night Skip / Fast-Forward 23:00 - 06:00)**: Người chơi không phải chờ đợi qua đêm. Hỗ trợ 3 cách: (1) Về giường ngủ `[E]` (Fade to black $1.5$s $\rightarrow$ tỉnh dậy lúc $06:00$ kèm Morning Report); (2) Bấm nút `[🌙 Tua Đến 06:00]` trên Tablet/HUD (`[T]`); (3) Tùy chọn Auto-Skip trong Settings. Khi tua, `SimulationEngine` chạy Batch Timestep trong RAM xử lý tức thì sản lượng và phụ tải đêm.
  10. **Thiết Kế Không Gian Địa Hình 3D & Hệ Thủy Văn Master Blueprint**:
      * **Ngọn Núi Trung Tâm**: Đỉnh bằng phẳng cao **$+600\text{ m}$** (Plateau $500\text{ km}^2$, $R \approx 12.62\text{ km}$). Chân núi rộng **$700\text{ km}^2$** ($R \approx 14.93\text{ km}$).
      * **4 Huyện Vệ Tinh**: Bắc, Đông, Nam, Tây, mỗi huyện **$500\text{ km}^2$** tiếp giáp chân núi. Phạm vi tọa độ thế giới $X, Y \in [-30\text{ km}, +30\text{ km}]$.
      * **4 Tầng Cao Độ Theo Chiều Đứng**: Đỉnh cao nguyên $+600\text{ m}$ ($0^\circ - 3^\circ$), Vách đá sa thạch $+400\text{ m} \dots +600\text{ m}$ ($45^\circ - 60^\circ$), Sườn núi trung cấp $+200\text{ m} \dots +400\text{ m}$ ($15^\circ - 25^\circ$), Chân núi & đồng bằng $+0\text{ m} \dots +200\text{ m}$.
      * **Hệ Thủy Văn Khép Kín & Bồn Tích Nước**: Lưu vực $700\text{ km}^2$, mưa $1200 - 1500\text{ mm/năm}$. Hồ Đỉnh $(-2\text{ km}, -3\text{ km}, +590\text{ m})$ diện tích $1.5\text{ km}^2$, sâu $50\text{ m}$, trữ lượng $50 - 100\text{ triệu m}^3$. Thác Nước Chính Nam $(0, -12\text{ km})$ đổ từ $+600\text{ m} \rightarrow +280\text{ m} \rightarrow +140\text{ m}$ (lưu lượng trung bình $26\text{ m}^3\text{/s}$). Hồ Chân Thác $(0, -13\text{ km}, +140\text{ m})$. Biển Mây Anime lơ lửng tại $+140\text{ m}$.
      * **Hệ Thống 10 POIs Cốt Lõi**: Đăng ký tập trung trong `scripts/simulation/poi_manager.gd` để Tablet và HUD bản đồ GPS truy vấn.

---

## 2. HARDWARE SPECIFICATIONS & RUNTIME RESOURCE BUDGETS

The project must maintain **$45 - 60\text{ FPS}$ at $1080\text{p}$ ($1920 \times 1080$)** on the user's specific target machine:

### 2.1 Hardware Baseline

* **Processor (CPU)**: Intel Core i7 (4–8 physical cores, 8–16 threads).
* **System RAM**: $16\text{ GB}$ physical DDR4/DDR5.
* **Storage**: $512\text{ GB}$ NVMe SSD.
* **Graphics Processor (GPU)**: **INTEGRATED GRAPHICS ONLY (Intel Iris Xe or Intel UHD)**.
  * **Dedicated VRAM**: $0\text{ MB}$ (Shares dynamically with System RAM, practically capped at $1.5\text{ GB} - 2.5\text{ GB}$).
  * **Bandwidth Limit**: Strictly constrained by system DDR bus ($25 - 40\text{ GB/s}$). Full-screen post-processing passes must be minimal.

### 2.2 Strict Allocation Budgets

| Metric | Upper Hard Ceiling | Target Nominal Range | Rules for Code / Asset Generation |
| :--- | :--- | :--- | :--- |
| **Total Disk Footprint** | $\le 2.0\text{ GB}$ ($2048\text{ MB}$) | $1.2\text{ GB} - 1.6\text{ GB}$ | VRAM-compressed textures (WebP / VRAM Compression). Max $2048 \times 2048$ for terrain, $1024 \times 1024$ for props. |
| **Active System RAM** | $\le 4.0\text{ GB}$ | $2.2\text{ GB} - 3.2\text{ GB}$ | Object pooling for 3D NPCs & particles; compact struct arrays for citizen data. |
| **Shared GPU VRAM** | $\le 2.5\text{ GB}$ | $1.2\text{ GB} - 1.8\text{ GB}$ | Strict mipmapping, no 4K textures, shared material palettes. |
| **Draw Calls per Frame** | $\le 1200$ | $400 - 800$ | Use `MultiMeshInstance3D` for flora, streetlights, fences, and repeated furniture. |
| **Active Triangles / Frame** | $\le 1.500.000$ | $400.000 - 800.000$ | Terrain chunking ($128\text{m} \times 128\text{m}$); Low-poly BoxOccluders; Tiered 3D NPC rendering. |

### 2.3 Engine Rendering Profile Configuration

* **Renderer Backend**: `gl_compatibility` (OpenGL 3.3 / GLES3 backend).
* **Banned Engine Features**:
  * ❌ **DO NOT USE** `SDFGI` (Signed Distance Field Global Illumination).
  * ❌ **DO NOT USE** `VoxelGI` or real-time screen-space reflections (SSR).
  * ❌ **DO NOT WRITE** custom compute shaders (`RenderingDevice`).
* **Approved Lighting Technique**:
  * Single `DirectionalLight3D` (Sun): `directional_shadow_max_distance = 60.0m` (prevents shadow acne and roof light leaking), 3-split PSSM.
  * Baked lightmaps (`LightmapGI`) OR simplified stylized ambient cubemaps with half-lambert / toon ramp calculations in vertex/fragment shaders.
  * Low-poly `BoxOccluder3D` only (CPU Embree rasterizer must not be overloaded).

---

---

## 3. GEOMETRIC SCALE, TOPOGRAPHY & WORLD MATH: NGỌN NÚI 5 HUYỆN & HỆ THỐNG GIAO THÔNG MẠNG NHỆN

Godot uses a metric coordinate system: **$1.0\text{ unit} = 1.0\text{ meter}$**.

```text
Y-Axis (Độ Cao Mét)
  ▲
  │
+600m ───┼────────────────────────── [ HUYỆN ĐỈNH VÁT (PLATEAU CORE - 1 HUYỆN) ] ──────────────────────────┼───
  │      │  (Bán kính R <= 7km - 8km, Diện tích ~175 km²: Đô thị trung tâm, dân cư sinh sống CHỦ YẾU)          │
  │      │  (Đại cao ốc Mega-Office, Đại hội trường có mái che, Học viện, Phố xá, Ray xe tram, Ga Metro Lõi)  │
+550m ───┘                                                                                                    └───
  │       \ [ SHEER CLIFFS / VÁCH ĐÁ DỰNG ĐỨNG HÀNG TRĂM MÉT ]                                              /
  │        \  (Cáp treo khổng lồ lướt trong mây, Thang máy đứng, Cung đường đèo uốn lượn ngắm cảnh)       /
  │         \  (Metro ngầm cao tốc chạy xuyên thẳng trong lòng khối núi đá)                               /
+100m ───────\                                                                                          /───────
  │           \                                                                                        /
  │            \─── [ VÀNH ĐAI CHÂN NÚI BAO QUANH 4 HƯỚNG (FOOTHILL BELT - 4 HUYỆN) ] ──────────────/
+20m  ──────────────\  (Bán kính R từ 8km đến 30km, Ôm trọn 4 hướng Đông - Tây - Nam - Bắc)        /────────────
  │                  \─────── [ BỜ BIỂN, CẢNG CÁ & BẾN TÀU VIỄN DƯƠNG (HUYỆN NAM) ] ─────────────/
  0m  ──────────────────────────────── [ MỰC NƯỚC BIỂN (SEA LEVEL y = 0.0) ] ──────────────────────────────
  ▼
```

### 3.1 Cấu Trúc Địa Bàn 5 Huyện (1 Đỉnh Vát + 4 Chân Núi)

* **Huyện 1: Đô Thị Đỉnh Vát (The Plateau Capital - Trung Tâm $R \le 7\text{km} - 8\text{km}$)**:
  * Là nơi **cư dân sinh sống CHỦ YẾU**, mật độ đô thị cao, văn minh, sạch sẽ và ngập tràn cây xanh.
  * Tọa độ trung tâm $(X=0, Z=0)$ là **Đại cao ốc Mega-Office Skyscraper** và **Nhà Ga Trung Tâm Đa Tầng (Grand Central Hub)**.
  * Tích hợp Đại hội trường có mái che khổng lồ quy tụ toàn bộ dân số vào các ngày Thánh Lễ.
* **4 Huyện Chân Núi Ôm Quanh 4 Hướng ($R \in [8\text{km}, 30\text{km}]$)**:
  1. **Huyện Đông (Vùng Nông Nghiệp Thảo Nguyên)**: Đồng lúa mì vàng óng bạt ngàn, cối xay gió, trại bò sữa hữu cơ, vườn táo đỏ. Tòa Cao ốc Vệ tinh Huyện Đông đặt tại trung tâm thảo nguyên.
  2. **Huyện Bắc (Vùng Đại Ngàn, Suối Khoáng & Khoáng Sản)**: Rừng thông lá kim, suối Onsen trị liệu, hang động mỏ vàng, bạc, lam ngọc, pha lê. Tòa Cao ốc Vệ tinh Huyện Bắc đặt gần thung lũng Onsen.
  3. **Huyện Tây (Vùng Kỹ Nghệ Sạch & Làng Nghề Thủ Công)**: Cánh đồng điện gió, nhà máy chế biến thực phẩm, xưởng mộc, xưởng dệt may, cơ khí. Tòa Cao ốc Vệ tinh Huyện Tây đặt tại cụm kỹ nghệ sạch.
  4. **Huyện Nam (Vùng Duyên Hải & Bến Cảng Hòa Bình)**: Bờ biển thoai thoải, cảng cá tươi sống, ngọn hải đăng, bến tàu biển đón tiếp lữ khách và người tị nạn. Tòa Cao ốc Vệ tinh Huyện Nam đặt nhìn ra biển cảng.
* **4 Tòa Cao Ốc Văn Phòng Vệ Tinh (Satellite District Complexes)**: Mỗi huyện có 1 Tòa cao ốc phức hợp tích hợp Hội trường có màn hình LED vòm siêu rộng 4K/8K truyền hình trực tiếp bài giảng của Người Chăn Chiên, do Người Đảm Nhiệm Nhà Thờ khu vực phụ trách chăm lo đời sống tâm lý và tổ chức Bữa tiệc Bác ái địa phương cho những cư dân khó khăn di chuyển đường dài lên đỉnh.

---

### 3.2 Hệ Thống Giao Thông Mạng Nhện (Spiderweb / Radial-Concentric Transit)

Mạng lưới giao thông được thiết kế theo hình mạng nhện với **Tâm là Tòa Mega-Office**, giúp toàn bộ người dân từ các huyện chân núi đổ dồn về trung tâm một cách nhanh chóng nhất:

1. **5 Tuyến Vành Đai Đồng Tâm (The 5 Concentric Rings)**:
   * **Vành đai 1 (Lõi Đỉnh Vát - Inner Core Ring)**: Ôm quanh Tòa Mega-Office, Đại hội trường và Quảng trường Trung tâm.
   * **Vành đai 2 (Đô thị Đỉnh Vát - Urban Ring)**: Vành đai mua sắm, học viện, ngân hàng, công viên dân cư.
   * **Vành đai 3 (Mép Vách Núi - Rim Cliff Scenic Parkway)**: Đại lộ ngắm cảnh men theo mép vực đỉnh núi, nơi đặt các trạm cáp treo và thang máy thẳng đứng.
   * **Vành đai 4 (Vòng Tròn Chân Núi - Foothill Ring)**: Đường cao tốc vành đai ôm trọn chu vi chân núi, kết nối thông suốt 4 Huyện (Đông - Tây - Nam - Bắc) với nhau mà không cần đi vòng lên đỉnh.
   * **Vành đai 5 (Ngoại Vi Biên Giới - Far Frontier Ring)**: Kết nối các vùng biên cảng biển, bìa rừng và nông trang xa nhất.

2. **8 Trục Nan Hoa Hướng Tâm (The 8 Radial Spokes)**:
   * 4 Trục Nan hoa Chính (Đại lộ Bắc, Nam, Đông, Tây) kết nối trực tiếp từ tâm của 4 Huyện chân núi chạy xuyên tâm về Tòa Mega-Office.
   * 4 Trục Nan hoa Phụ (Đông Bắc, Đông Nam, Tây Bắc, Tây Nam) chia nhỏ lưu lượng giao thông liên huyện.

---

### 3.3 Quy Chuẩn Vận Tốc & Thời Gian Di Chuyển (Travel Times from Outer Foothills to Core)

Khoảng cách thực địa từ rìa huyện chân núi xa nhất ($R \approx 30\text{km}$) về đến Tòa Nhà Trung Tâm:

| Phương Tiện | Vận Tốc Trung Bình | Thời Gian Di Chuyển (Một Chiều) | Quy Chuẩn Hành Trình |
| :--- | :--- | :--- | :--- |
| **Tàu Ngầm Metro (Xuyên núi)** | $90 - 100\text{ km/h}$ | **$15 - 20\text{ phút}$ (nếu không dừng)** | Chạy theo tuyến hầm ngầm chuyên dụng xuyên lòng núi thẳng lên Ga Lõi Trung Tâm. |
| **Xe Máy / Ô tô** | $60\text{ km/h}$ | **$30\text{ phút}$ (nếu không tắc đường)** | Chạy trên các trục nan hoa đại lộ và đường đèo uốn lượn vượt vách núi. |
| **Xe Bus BRT** | $45\text{ km/h}$ | **$40\text{ phút}$ (nếu không tắc đường)** | Có làn ưu tiên riêng trên trục nan hoa, đón trả khách tại các nút giao vành đai. |
| **Xe Đạp** | $13\text{ km/h}$ | **$4\text{ tiếng}$** | Làn đường xe đạp chuyên dụng có cây xanh rợp bóng, uốn lượn ngắm cảnh. |
| **Đi Bộ** | $4\text{ km/h}$ | **Cả ngày cũng chưa hết** ($\ge 10 - 14\text{ tiếng}$) | Lối đi bộ sinh thái, bậc thang đá phong cách anime leo vách núi. |

* **Tương quan thời gian game 1:20**:
  * $30\text{ phút}$ lái xe in-game $\approx 1.5\text{ phút}$ ($90\text{s}$) người chơi thao tác lái xe trong đời thực.
  * $4\text{ tiếng}$ xe đạp in-game $\approx 12\text{ phút}$ đời thực.
  * $1\text{ ngày}$ đi bộ in-game $\approx 48 - 72\text{ phút}$ đời thực (trọn vẹn một phiên chơi khám phá).

---

### 3.4 Tối Ưu Hóa Kỹ Thuật Render Cho Quy Mô Lớn (GPU Iris Xe / UHD)

* **Godot 4 LWC (Large World Coordinates)**: Tọa độ float 64-bit đảm bảo độ chính xác tuyệt đối không bị rung giật (jitter) ở khoảng cách $30\text{km}$.
* **Chunk Streaming & World Grid**: Bán kính load 3D mesh chi tiết chỉ trong $r \le 256\text{m} - 512\text{m}$ quanh người chơi.
* **Anime Horizon Impostor & Fog / Clouds**: 4 huyện chân núi và vách đá ở xa sử dụng mesh tối giản kết hợp shader mây anime và sương mù che phủ (`Environment.fog_enabled = true`).
* **Mô phỏng Tier 3 Pure Math**: Cư dân đi lại giữa 4 huyện và đỉnh vát được xử lý bằng logic tính toán thuần trong RAM, không sinh node 3D trừ khi lọt vào tầm mắt người chơi ($< 35\text{m}$).

---

## 4. SEAMLESS INTERIOR & BUILDING ARCHITECTURE

All buildings exist directly in the open world mesh. No scene reloading or teleportation is permitted.

### 4.1 Structural Node Composition

Every enterable building conforms to this hierarchy:

```text
Building_Bank_01 (StaticBody3D)
├── ExteriorShell (MeshInstance3D)         # Outer walls, roof, trims (LOD0, LOD1, LOD2)
├── InteriorShell (MeshInstance3D)         # Inner walls, floorboards, ceiling
├── InteriorProps (Node3D)                 # Desks, chairs, counters, cash boxes (0m to 35m, FADE_SELF)
├── InteriorLightingArea (Area3D)          # Dampens exterior sunlight & applies warm interior ambient
├── OccluderEnclosure (OccluderInstance3D) # Low-poly BoxOccluder3D
├── Portal_FrontDoor (Node3D)              # Entrance origin
│   ├── DoorFrame (StaticBody3D)
│   ├── DoorHingePivot (Node3D)            # Rotation pivot (x=0, y=0, z=0 at hinge pin)
│   │   ├── DoorLeaf (MeshInstance3D)
│   │   └── DoorCollision (CollisionShape3D)
│   └── InteractionTrigger (Area3D)        # Proximity detector
├── NPCWorkstations (Node3D)               # Job anchor markers
│   ├── Station_Teller_01 (Marker3D)       # Meta: role="BANK_TELLER", required_cert="CERT_FINANCE"
│   ├── Station_Director (Marker3D)        # Meta: role="BANK_DIRECTOR", required_cert="CERT_FINANCE"
│   └── Station_Security (Marker3D)        # Meta: role="SECURITY", required_cert="CERT_POLICE_SCIENCE"
├── BuildingHRBoard (Area3D)               # Terminal for Player to Hire/Fire based on certificates
└── InteriorNPCManager (Node)              # Manages Tier 1 NPC visual spawn/despawn pooling
```

---

## 5. CÕI BẤT TỬ, GIÁO DỤC CHÍNH QUY & KINH TẾ THỊ TRƯỜNG TỰ NHIÊN

### 5.1 Cõi Bất Tử Thanh Xuân & Quy Luật Hao Mòn Đồ Vật (Durability & Upgrades)

* **Chỉ có Con Người là Bất tử**: Cư dân trường sinh bất tử, không có cái chết tự nhiên. Dừng lão hóa ở độ tuổi 20–25 tuổi. Không có nghĩa trang, tang lễ.
* **Quy luật Hao mòn & Hỏng hóc Vật chất (Durability & Wear/Tear)**:
  * Máy móc, xe cộ, cáp treo, lò nướng, thiết bị phòng lab, bàn ghế, quần áo đều có chỉ số độ bền (`durability: float`).
  * Sử dụng theo thời gian sẽ bị mòn, kẹt máy, hỏng hóc $\rightarrow$ Cần thợ cơ khí (`CERT_AUTO_MECHANIC`), thợ mộc (`CERT_CARPENTRY`), thợ may bảo dưỡng và sửa chữa.
* **Quy luật Lỗi thời & Động lực Nâng cấp (Obsolescence & Tech Upgrades)**:
  * Khi Viện Hàn Lâm Khoa Học phát minh ra công nghệ mới $\rightarrow$ Thiết bị cũ trở nên lỗi thời.
  * Cư dân tích cóp tiền lương để mua đồ mới, nâng cấp xe đạp lên xe điện, nâng cấp lò nướng hiện đại hơn.
  * Nhờ đồ vật hỏng và lỗi thời, nền kinh tế luôn vận động không ngừng: các xưởng sản xuất, cửa hàng buôn bán và thợ kỹ thuật luôn có việc làm quanh năm!
* **Y tế phục hồi & Suối khoáng Onsen**: Bệnh viện và Onsen đóng vai trò trị liệu mệt mỏi, trúng gió, kiệt sức sau lao động, đưa năng lượng về 100%.
* **Đời sống nhân khẩu, Hôn nhân & Nguồn tăng trưởng từ biển**:
  * Cư dân kết hôn và yêu thương nhưng rất ít có nhu cầu sinh sản, hiếm khi có em bé ra đời.
  * Nguồn tăng trưởng dân số chủ lực là **lữ khách / người tị nạn từ biển cập Cảng Hòa Bình (Huyện Nam)**.
* **Cân bằng diện tích đất đai & 4 Hình thức nhà ở linh hoạt**:
  * *Diện tích đất đai hoàn toàn dư dả*: Đỉnh Vát $176.7\text{ km}^2$, dù $100\%$ dân cư ở nhà riêng $300\text{ m}^2$ cũng chỉ chiếm $2.44\%$ diện tích; 4 huyện chân núi rộng tới $2.626\text{ km}^2$ tha hồ canh tác và phát triển.
  * *4 Loại hình nhà ở*: (1) Chung cư Studio Anime 3-5 tầng cho người độc thân; (2) Ký túc xá / Nhà chung ấm cúng (Co-Living) cho nhóm bạn bè; (3) Căn hộ gia đình đa phòng; (4) Nhà vườn Cottage ven đồi. Cư dân tự do chọn nhà theo thẩm mỹ, không áp phạt tâm lý.

### 5.1.1 Quy Chuẩn Trần Dân Số 14.400 Người & Lộ Trình Mở Rộng 144.000 Người (The 14,400 Cap & Phase 2 Expansion)

* **Giai đoạn 1 — Trần Dân Số Đô Thị Đỉnh Vát ($14.400\text{ người}$)**:
  * Thành phố bắt đầu từ một cộng đồng tiên phong ($300\text{ người}$).
  * Dân số tăng trưởng chủ yếu từ việc tiếp nhận lữ khách qua Cảng Hòa Bình (Huyện Nam).
  * **Chạm mốc $14.400\text{ người}$**: Toàn bộ thành phố **dừng sinh sản hoàn toàn**, đóng sổ tiếp nhận cư dân mới vào Đỉnh Vát, đồng thời kích hoạt cổng mở rộng Giai đoạn 2 xuống 4 Huyện chân núi.
* **Chuyển Đổi Giáo Dục Khi Dừng Sinh Sản**:
  * Những đứa trẻ cuối cùng thuộc Hội Ấu Nhi lớn lên đến tuổi $20 - 25$ và dừng lão hóa vĩnh viễn.
  * Các trường tiểu học, trung học được chuyển đổi công năng thành **Học Viện Đa Ngành & Phòng Lab Nghiên Cứu**: Giảng dạy chứng chỉ nghề chuyên sâu (`CERT_*`), nghiên cứu khoa học và sáng tạo nghệ thuật cho $14.400$ cư dân thanh xuân. Đến khi mở Giai đoạn 2 mới mở lại các lớp Ấu Nhi.
* **Đời Sống Nghề Nghiệp Xã Hội Ổn Định (Steady-State Polymath Society)**:
  * Không ai sinh ra, không ai già, không ai chết $\rightarrow$ Cư dân tự do lựa chọn giữa:
    1. Gắn bó lâu năm với nghề sở trường để thăng cấp lên **Đại Nghệ Nhân / Viện Sĩ**.
    2. Đổi nghề sang lĩnh vực mới (Polymath) sau một thời gian để làm phong phú trải nghiệm đời sống.
  * Thị trưởng quản trị vĩ mô bằng cách cấp ngân sách học bổng để điều phối dòng lao động vào các ngành thành phố đang thiếu hụt.
* **Đại Hội Trường Sân Vận Động Mái Vòm $15.000\text{ Chỗ}$ Tại Tòa Mega-Office**:
  * Sức chứa đủ cho toàn bộ $14.400\text{ người}$ tề tựu vào giờ Thánh Lễ (11:40 - 14:00 Thứ Tư & Chủ Nhật).
  * **Tối ưu đồ họa trên GPU Intel Iris Xe**: Vùng gần người chơi ($< 35\text{m}$) hiển thị 3D chi tiết; các tầng khán đài trên cao sử dụng kỹ thuật `MultiMeshInstance3D` kết hợp shader biển người Anime vẫy tay hát thánh ca, đảm bảo khung hình siêu mượt $60\text{ FPS}$.
* **Giai đoạn 2 — Mở Rộng 4 Huyện Chân Núi ($144.000\text{ người}$)**:
  * Sau này khi mở rộng quy hoạch phát triển 4 huyện chân núi, trần dân số sẽ được nâng lên $144.000\text{ người}$ theo biểu tượng Khải Huyền (điều kiện mở khóa sẽ được thiết kế linh hoạt theo tiến trình thế giới).

### 5.2 Giáo Dục Bắt Buộc & Học Viện Đa Chứng Chỉ (Polytechnic Lifelong Learning)

* **Giáo dục chính quy bắt buộc (6–17 tuổi)**: Toàn bộ trẻ em bắt buộc phải hoàn thành Tiểu học và Trung học để nhận bằng **General Diploma**. Không có bằng này không được đi làm.
* **Học viện Đa ngành (Polytechnic Academy)**: Mọi công dân có thể học nhiều chuyên ngành khác nhau để tích lũy nhiều **Chứng chỉ nghề (`CERT_*`)**. Bảng Tuyển dụng chỉ chấp nhận ứng viên có đúng chứng chỉ chuyên môn.

### 5.3 Tài Chính Doanh Nghiệp: Mở Rộng Tuyển Dụng vs Phá Sản

Mỗi cơ sở thương mại tư nhân (Tiệm bánh, Quán cà phê, Tiệm trà, Nhà hàng, Siêu thị...) có sổ sách kế toán độc lập:
$$\text{Lợi Nhuận} = \text{Doanh Thu} - (\text{Tiền Nhập Hàng} + \text{Tiền Thuê Nhà} + \text{Quỹ Lương Nhân Viên})$$

* **Kinh doanh có lãi liên tục**: Quán nâng cấp mặt bằng $\rightarrow$ **Mở thêm vị trí việc làm mới (Unlock Slots)**: Tuyển thêm phục vụ, thợ phụ, thu ngân $\rightarrow$ Đóng thêm thuế thương mại cho Kho bạc.
* **Kinh doanh thua lỗ liên tục**: Quán cắt giảm nhân viên $\rightarrow$ Vẫn lỗ $\rightarrow$ **Phá sản hoàn toàn (Bankruptcy)**. Quán đóng cửa, dán biển thanh lý, nhân viên thất nghiệp quay lại Học viện học chứng chỉ khác hoặc tìm việc mới.

### 5.4 Hệ Thống 8 Bộ Ban Chuyên Ngành Toàn Diện Áp Dụng Cho Toàn Bộ Tổ Chức (The 8 Universal Divisions)

Quy chuẩn áp dụng đồng bộ cho **MỌI TỔ CHỨC** trong thành phố (từ Bệnh viện, Viện Khoa học, Ngân hàng, Nhà In, TTTM, Doanh nghiệp lớn đến Tòa Nhà Văn Phòng Trung Tâm) khi quy mô nhân sự đạt từ **16 người trở lên**:

1. **Ban Nội Vụ & Nhân Sự** (`CERT_CIVIC_ADMIN`): Quản lý hồ sơ, điều phối ca kíp, chăm lo phúc lợi và duy trì sự hòa thuận nội bộ.
2. **Ban Tài Chính & Kế Toán** (`CERT_FINANCE_BANKING`): Thu chi minh bạch, tính lương, quyết toán thuế Kho bạc ($5\%$) và trích nộp $1/10$ tiền dâng Chúa.
3. **Ban Đào Tạo & Kèm Cặp (L&D)** (`CERT_EDU_*`): Kèm cặp người mới, nâng cấp bậc nghề từ Sơ cấp lên Bậc thầy.
4. **Ban Kế Hoạch & Chiến Lược** (`CERT_CIVIC_ADMIN`, `CERT_LOGISTICS_SUPPLY`): Dự trù nguyên vật liệu, lập kế hoạch mở rộng, điều phối tiến độ.
5. **Ban Kỹ Thuật & Bảo Trì Cơ Sở Vật Chất** (`CERT_POWER_GRID`, `CERT_AUTO_MECHANIC`): Sửa chữa máy móc hao mòn, bảo trì đường điện nước, thang máy, mái che sân vận động.
6. **Ban Kiểm Chuẩn Chất Lượng & Môi Trường** (`CERT_ENVIRONMENTAL_HEALTH`): Kiểm tra an toàn thực phẩm, nước sạch, bảo tồn cảnh quan xanh Ghibli.
7. **Ban Truyền Thông, Media & Sự Kiện** (`CERT_JOURNALISM_MEDIA`, `CERT_CINEMA_VIDEOGRAPHY`): Livestream thánh lễ, điều phối hòa nhạc quảng trường, tổ chức lễ hội pháo hoa, bảng tin đô thị.
8. **Ban Mục Vụ, Tư Vấn Tâm Lý & Hòa Bình** (`CERT_DIVINE_SHEPHERD`, `CERT_MEDICINE_GENERAL`): Lắng nghe tâm tư, giải tỏa stress âu lo, tiếp đón lữ khách từ biển xa, viện trợ nhân đạo.

* **Cơ chế Cảnh báo Nghẽn Quản Trị**: Tổ chức vượt quy mô mà chưa tuyển đủ các Trưởng Ban chức năng sẽ bị giảm $-30\%$ năng suất. Khi tuyển đủ $\rightarrow$ Trạng thái "Tổ chức Phồn Vinh" tăng vọt $+50\%$ năng suất!

### 5.4.1 Cơ Chế Phân Quyền Song Hành: Thị Trưởng, Người Chăn Chiên & Nội Các 8 Bộ Ban

* **Trụ Sở Làm Việc Chung Tại Tòa Mega-Office Skyscraper $(X=0, Z=0)$**: Cả Văn phòng Thị Trưởng và Văn phòng Người Chăn Chiên cùng làm việc chung trong tòa cao ốc trung tâm để tiết kiệm diện tích đất và dùng chung phòng họp hội nghị đa năng.
* **Phân Định Thẩm Quyền Rành Mạch**:
  * *Thị Trưởng*: Toàn quyền hành chính công, quy hoạch hạ tầng kỹ thuật (đường sá, ray tram, cấp điện nước, viễn thông), quản trị Kho Bạc Đô Thị và điều phối nhân sự nghề nghiệp (`CERT_*`).
  * *Người Chăn Chiên*: Toàn quyền định hướng đời sống tâm linh, giảng dạy đạo đức, mục vụ cộng đồng, quản trị dòng tiền Quỹ 1/10 và thực thi sứ mạng hòa bình.
* **Nội Các 8 Trưởng Ban Điều Hành Thực Thi**: Thị Trưởng và Người Chăn Chiên không ôm đồm việc vi mô mà giữ vai trò định hướng và chốt duyệt cuối cùng; 8 Trưởng Ban họp chung thành Nội Các thành phố để tiếp nhận nghị quyết và tự động phân công cấp dưới triển khai.
* **Kỳ Họp Bàn Tròn Định Kỳ Theo Quý (3 Tháng/Lần)**: Đánh giá thành tựu quý, phê duyệt các dự án đồng tài trợ (Kho Bạc + Quỹ 1/10). Người chơi có thể dự họp trực tiếp tại Phòng Hội Nghị tầng cao Tòa Mega-Office hoặc ký duyệt qua Tablet.
* **Cơ Chế Phủ Quyết Đạo Đức (Gentle Moral Advisory)**: Người Chăn Chiên đưa ra lời khuyên nhân văn và giải pháp thay thế tốt đẹp hơn (kèm giải pháp đồng tài trợ từ Quỹ 1/10) khi có quy hoạch tác động tiêu cực đến con người hoặc môi trường.
* **Sự Hiện Diện Tự Do (Wandering Pastor)**: Người Chăn Chiên thường xuyên mặc vest dạo bước khắp công viên, ghé tiệm bánh, quán trà trò chuyện với cư dân; Thị trưởng có thể bắt gặp và trò chuyện ngẫu nhiên trên phố.

### 5.5 Đất Lành Được Chúc Phước — Sản Vật Dư Dật (The Blessed Land of Abundance)

* **Phước Lành Thiên Thượng**: Tân Thế Giới là vùng đất được Đức Chúa Trời chúc phước; khí hậu cao nguyên quanh năm ôn hòa, thổ nhưỡng phì nhiêu màu mỡ.
* **Sản Vật Dư Dật Bội Thu**: Nông trại lúa mì, vườn cây ăn trái, trang trại bò sữa và cảng cá luôn đạt sản lượng dồi dào (`blessed_abundance_multiplier = 1.5x - 2.0x`).
* **Kinh Tế No Đủ**: Lương thực dồi dào giúp giá cả luôn rẻ và ổn định, kho dự trữ luôn đầy ắp, đủ lương thực dồi dào cho Bữa tiệc Bác ái hàng tuần và cứu trợ nhân đạo ra thế giới bên ngoài mà không bao giờ lo thiếu hụt.

### 5.6 Hệ Thống 4 Hội Đoàn Cộng Đồng (The 4 Community Fellowships)

Đời sống xã hội và sinh hoạt gắn kết chặt chẽ qua 4 Hội Đoàn đại diện cho từng thế hệ và giới:

1. **Hội Ấu Nhi (Children's Fellowship — Trẻ em 6–17t)**:
   * Sinh hoạt đạo đức, học hát thánh ca thiếu nhi, vẽ tranh, rèn luyện tính trung thực và yêu thương cha mẹ.
2. **Hội Thanh Niên (Youth Fellowship — Tuổi trẻ nhiệt huyết)**:
   * Tiên phong các phong trào âm nhạc (ban nhạc Hiphop, ca đoàn), giải bóng đá, cắm trại dã ngoại vách núi, xây dựng tình bạn và tình yêu hôn nhân trong sáng.
3. **Hội Phụ Nữ (Women's Fellowship — Chị em phụ nữ đảm đang)**:
   * Chuẩn bị Bữa tiệc Bác ái hàng tuần, làm bánh ngọt, đan len may mặc, cắm hoa trang trí thánh đường, chăm sóc suối khoáng Onsen và an ủi người mỏi mệt.
4. **Hội Tráng Niên (Men's Fellowship — Các đấng nam nhi kiên trung)**:
   * Trụ cột kỹ thuật, xây dựng, công nghệ; hỗ trợ sửa chữa nhà cửa, bảo trì hạ tầng cáp treo, bảo vệ trật tự và gương mẫu trong đời sống liêm chính.

* **Sự Gắn Kết Hoàn Hảo**: 4 Hội đoàn phối hợp như một đại gia đình: Hội Tráng Niên dựng rạp $\rightarrow$ Hội Phụ Nữ nấu tiệc $\rightarrow$ Hội Thanh Niên chơi nhạc $\rightarrow$ Hội Ấu Nhi múa hát vui tươi!

### 5.7 Kinh Tế Tự Nhiên — Không Mâu Thuẫn, Không Cạnh Tranh Bẩn (Natural Spatial Economics)

* **Tâm Thức Phụng Sự & Hòa Thuận**: Cư dân mở quán vì đam mê và phục vụ cộng đồng, không có cạnh tranh bẩn, không bán phá giá triệt hạ, không tung tin đồn xấu. Các chủ quán san sẻ nguồn hàng và giúp đỡ nhau.
* **Cung - Cầu & Vị Trí Tự Nhiên**:
  * Cửa hàng đông khách nhờ nằm trên trục đường chính, tiện đường đi làm, cung cấp đúng món cư dân cần.
  * Cửa hàng vắng khách do mở ở ngõ cụt hẻo lánh hoặc khu phố đã bão hòa số lượng tiệm $\rightarrow$ Tự nhiên cạn vốn dự phòng $\rightarrow$ **Tự nguyện đóng cửa thanh lý phá sản trong hòa bình**.
* **Thanh Thản Sau Phá Sản**: Chủ quán phá sản không oán giận, thanh lý đồ đạc, nhận sự nâng đỡ từ Quỹ $1/10$ và cộng đồng, tự do đến Học viện học nghề mới để chuyển đổi công việc.

### 5.8 Mô Phỏng 3 Tầng Hiệu Năng (Three-Tier LoD Simulation)

* **Tier 3 (Mô phỏng trừu tượng trong RAM - Bán kính > 100m)**: Không 3D, không xương animation, chạy dữ liệu nhu cầu và thời gian biểu 24h.
* **Tier 2 (Người đi bộ tầm trung - 35m đến 100m)**: Mesh LOD1 nhẹ, di chuyển dọc vỉa hè theo `NavigationAgent3D` tần số 5 Hz.
* **Tier 1 (Đặc tả chi tiết khi vào gần / vào nhà < 35m)**: Triệu hồi từ Object Pool mô hình 3D chi tiết vào đúng điểm neo `Marker3D` tại bàn làm việc.

---

## 6. DANH MỤC 14 KHỐI NGÀNH NGHỀ & CHỨNG CHỈ TÂN THẾ GIỚI

### Khối 1: Nông Nghiệp, Thủy Hải Sản & Khai Thác Nguyên Liệu

* **Nông trại Lúa mì & Ngũ cốc** (`CERT_AGRI_CROPS`): Quản lý nông trang, Thợ gieo trồng & gặt hái. Cung cấp lúa mì cho Nhà máy xay bột.
* **Vườn Rau củ & Cây ăn trái** (`CERT_AGRI_HORTICULTURE`): Kỹ sư nông nghiệp, Người thu hái. Cung cấp táo, cam, cà chua cho Siêu thị & Nhà hàng.
* **Trang trại Bò sữa & Chăn nuôi** (`CERT_AGRI_LIVESTOCK`): Quản lý trại sữa, Thợ vắt sữa. Cung cấp sữa tươi, bơ cho Tiệm bánh mì.
* **Cảng Cá ven biển** (`CERT_MARITIME_FISHING`): Thuyền trưởng tàu cá, Ngư dân đánh bắt. Cung cấp cá biển tươi cho quán ăn & chợ cá.
* **Lâm trường & Khai thác Đá** (`CERT_FORESTRY_EXTRACTION`): Quản lý lâm trường, Thợ đốn gỗ, Thợ chẻ đá vách núi.

### Khối 2: Công Nghiệp Chế Biến & Tiểu Thủ Công Nghiệp

* **Nhà máy Xay bột & Đóng gói** (`CERT_FOOD_PROCESSING`): Kỹ sư vận hành máy xay bột mì.
* **Xưởng Mộc & Nội thất** (`CERT_CARPENTRY`): Nghệ nhân mộc, Thợ đóng bàn ghế học sinh, quầy thu ngân.
* **Xưởng May mặc & Thời trang** (`CERT_TEXTILE_FASHION`): Nhà thiết kế, Thợ may đồng phục học sinh, blouse bác sĩ, yukata.
* **Lò Gốm & Đồ gia dụng** (`CERT_CERAMIC_CRAFT`): Nghệ nhân làm chén bát, ấm trà, gạch ngói.

### Khối 3: Thương Mại, Dịch Vụ & Ẩm Thực (Doanh Nghiệp Tư Nhân)

* **Tiệm Bánh mì Thủ công** (`CERT_CULINARY_BAKING`): Thợ làm bánh chính, Thợ phụ nhào bột, Nhân viên bán bánh.
* **Tiệm Trà & Cafe Cao nguyên** (`CERT_BEVERAGE_BARISTA`): Nghệ nhân pha trà, Barista, Phục vụ bàn.
* **Nhà hàng & Quán đêm Izakaya** (`CERT_CULINARY_CHEF`): Bếp trưởng, Phụ bếp, Phục vụ, Thu ngân.
* **Siêu thị & Cửa hàng Tiện lợi** (`CERT_COMMERCE_RETAIL`): Quản lý cửa hàng, Thủ kho, Thu ngân.
* **Hiệu Sách & Văn phòng phẩm** (`CERT_LITERATURE_ARCHIVE`): Quản lý hiệu sách, Nhân viên bán sách giáo khoa.

### Khối 4: Tài Chính, Tiền Tệ & Ngân Hàng

* **Chi nhánh Ngân Hàng Nhà Nước** (`CERT_FINANCE_BANKING`): Trực thuộc Hệ thống Tài chính Nhà nước; Giám đốc chi nhánh, Kế toán trưởng, Thu ngân thanh toán số 1 & 2, Chuyên viên điều phối tín dụng kiến tạo 0% lãi suất, Bảo vệ.
* **Văn phòng Bảo hiểm & Thẩm định** (`CERT_FINANCE_ACTUARY`): Giám định viên bảo hiểm rủi ro nông nghiệp.

### Khối 5: Y Tế, Phục Hồi Thể Lực & Suối Nước Nóng (Onsen)

* **Bệnh viện Đa khoa & Viện Điều dưỡng** (`CERT_MEDICINE_GENERAL`, `CERT_NURSING`): Viện trưởng, Bác sĩ phục hồi thể lực, Y tá trưởng, Y tá chăm sóc.
* **Hiệu thuốc Thảo dược** (`CERT_PHARMACY`): Dược sĩ trưởng, Người pha chế trà bổ phục hồi.
* **Khu Suối nước khoáng Onsen** (`CERT_WELLNESS_SPA`): Quản lý khu Onsen, Kỹ thuật viên suối khoáng nóng.

### Khối 6: Giáo Dục Chính Quy & Học Viện Đào Tạo

* **Trường Tiểu học (6–11t)** (`CERT_EDU_PRIMARY`): Hiệu trưởng, Giáo viên tiểu học.
* **Trường Trung học (12–17t)** (`CERT_EDU_SECONDARY`): Hiệu trưởng, Giáo viên Khoa học, Giáo viên Xã hội. Cấp bằng `General Diploma`.
* **Học viện Đa ngành Polytechnic** (`CERT_EDU_PROFESSOR`): Viện trưởng học viện, Các Giáo sư chuyên ngành đào tạo và cấp chứng chỉ `CERT_*`.

### Khối 7: Hành Chính Công, Luật Pháp & Tư Pháp

* **Tòa thị chính** (`CERT_CIVIC_ADMIN`): Chánh văn phòng, Trưởng ban Tài chính & Thuế, Cán bộ Địa chính & Quy hoạch, Cán bộ Hộ tịch.
* **Tòa án Thị trấn** (`CERT_LAW_JUDICIAL`): Thẩm phán chủ tọa, Luật sư hòa giải, Thư ký phiên tòa.

### Khối 8: An Ninh, Trật Tự & Cứu Hộ Vách Núi

* **Đồn Cảnh sát Khu phố** (`CERT_POLICE_SCIENCE`): Cảnh sát trưởng, Cảnh sát tuần tra, Cảnh sát giao thông.
* **Trạm Cứu hỏa & Cứu nạn Vách núi** (`CERT_FIRE_RESCUE`): Đội trưởng cứu hỏa, Lính cứu hỏa, Chuyên viên đu dây cứu nạn vách đá 200m.

### Khối 9: Giao Thông, Vận Tải & Logistics Đa Tầng

* **Trạm Cáp treo Vách núi (200m Gondola)** (`CERT_CABLE_OPERATIONS`): Trưởng ga cáp treo, Kỹ sư cơ khí tời cáp, Soát vé cabin.
* **Tàu điện Leng Keng Mặt đất (Vintage Tram)** (`CERT_TRAM_OPERATOR`): Trưởng trạm tàu điện, Lái tàu điện đường phố, Thợ đường ray.
* **Đội Xe buýt Đô thị** (`CERT_TRANSIT_DRIVER`): Điều phối viên tuyến, Tài xế xe buýt đô thị.
* **Trung tâm Logistics & Xe tải** (`CERT_LOGISTICS_SUPPLY`): Điều phối viên hàng hóa, Tài xế xe tải hàng.
* **Xưởng Sửa chữa & Đăng kiểm Xe** (`CERT_AUTO_MECHANIC`): Quản đốc xưởng, Thợ cơ khí xe cộ.
* **Đội Cầu đường & Bảo trì Mặt đường** (`CERT_CIVIL_INFRASTRUCTURE`): Kỹ sư giao thông, Thợ rải nhựa & lát đá vỉa hè.

### Khối 10: Hạ Tầng Năng Lượng & Tiện Ích Đô Thị

* **Trạm Điện gió & Thủy điện** (`CERT_POWER_GRID`): Kỹ sư trưởng trạm điện, Kỹ thuật viên tuabin.
* **Trạm Cấp nước & Lọc nước ngầm** (`CERT_WATER_SANITATION`): Kỹ sư trưởng nguồn nước, Kỹ thuật viên kiểm chuẩn.
* **Đội Vệ sinh Đô thị & Tái chế Rác** (`CERT_ENVIRONMENTAL_HEALTH`): Đội trưởng vệ sinh, Lao công quét đường phố.

### Khối 11: Văn Hóa, Báo Chí, Sân Khấu & Thể Thao

* **Tòa soạn Báo & Đài Truyền thanh** (`CERT_JOURNALISM_MEDIA`): Tổng biên tập, Phóng viên thực địa, Phát thanh viên loa phố.
* **Nhà hát Kịch & Rạp Chiếu bóng** (`CERT_PERFORMING_ARTS`): Đạo diễn sân khấu, Diễn viên kịch, Kỹ thuật viên âm thanh.
* **Sân Vận động & Khu Thể thao** (`CERT_SPORTS_COACHING`): Huấn luyện viên bóng đá, Trọng tài, Quản lý sân cỏ.

### Khối 12: Khoa Học, Công Nghệ & Nghiên Cứu Đổi Mới

* **Viện Nghiên cứu Công nghệ Cao nguyên** (`CERT_TECH_INNOVATION`): Viện trưởng nghiên cứu, Kỹ sư công nghệ, Chuyên viên tự động hóa. (Nghiên cứu nâng cấp điện gió, tối ưu động cơ tàu điện, giống dâu tây ngọt).
* **Đài Thiên Văn Đỉnh Núi** (`CERT_ASTRONOMY_SPACE`): Nhà thiên văn học, Chuyên viên khí tượng. (Kính viễn vọng ngắm sao băng, dự báo thời tiết).

### Khối 13: Công Nghiệp Giấy, In Ấn & Xuất Bản

* **Nhà máy Sản xuất Giấy & Bìa** (`CERT_PULP_PAPERMAKING`): Kỹ sư bột giấy, Thợ cán giấy màng.
* **Nhà In Trung tâm & Xưởng Xuất bản** (`CERT_PRINTING_GRAPHICS`): Giám đốc nhà in, Nghệ nhân sắp chữ, Kỹ thuật viên máy in màu. (In sách giáo khoa, tiền giấy/sổ tiết kiệm ngân hàng, bằng tốt nghiệp, nhãn mác tiệm bánh).

### Khối 14: Tâm Linh Kitô Giáo — Tòa Nhà Văn Phòng Siêu To Trung Tâm & Người Chăn Chiên Vĩnh Cửu

* **Kiến trúc Đại Cao Ốc Văn Phòng Siêu To (The Mega-Office Complex $(X=0, Z=0)$)**:
  * **Không phải thánh đường cổ điển**: Tòa nhà là một **Đại cao ốc văn phòng phức hợp siêu to khổng lồ**, tường kính hiện đại kết hợp vườn treo trên không (Sky Gardens) phong cách Anime tương lai.
  * **Trái tim Đại Hội Trường Sân Vận Động (Mega-Auditorium Arena)**: Nằm ngay tại trung tâm của tòa nhà văn phòng, được thiết kế như một sân vận động mái vòm có giếng trời đón ánh sáng thiên nhiên, khán đài nhiều tầng đủ chỗ cho 100% cư dân cùng tề tựu.
  * Tòa nhà đồng thời là nơi đặt: Văn phòng của Người Chăn Chiên, Studio truyền hình phát sóng, phòng hội nghị mục vụ, và các văn phòng điều hành công vụ.
* **Người Chăn Chiên (The Shepherd) — Sứ giả từ trời** (`CERT_DIVINE_SHEPHERD`):
  * **Đấng bảo trợ thiêng liêng**: Có **Đức Chúa Trời (ĐCT) và Chúa Jesus ở cùng đời đời**.
  * **Sứ mệnh vĩnh cửu**: Vì là cõi bất tử, **tuyệt đối không bao giờ có sự chuyển giao hay kế vị sứ mệnh**; Người Chăn Chiên là vị mục tử duy nhất và trường tồn cùng thời gian.
  * Giảng dạy tình yêu thương thuần khiết, lòng bác ái, sự tha thứ, chủ trì lễ cưới vĩnh cửu và dẫn dắt đàn chiên trong sự bình an.
* **Đội Ngũ Phục Vụ & Hầu Việc Chúa (Người Thầy Tâm Linh & Bác Sĩ Tâm Lý)**:
  * **Bình Đẳng Giới Tính Hoàn Toàn (Không Yêu Cầu Nam Hay Nữ)**: Cả nam lẫn nữ đều có thể đảm nhiệm mọi vai trò trong hàng ngũ Người Hầu Việc Chúa (NHVC) và Người Đảm Nhiệm Nhà Thờ tại các huyện.
  * **Vai trò Người Thầy Tâm Linh & Trị Liệu Tinh Thần**: Các người hầu việc Chúa kiêm luôn vai trò **Bác sĩ tâm lý và Người dẫn dắt tâm linh**:
    * Lắng nghe, giải tỏa mọi âu lo, băn khoăn về cuộc sống, định hướng nghề nghiệp và xoa dịu những căng thẳng tinh thần của cư dân trong tình yêu thương.
    * Giúp cư dân luôn giữ được tâm hồn thanh thản, an vui trong cõi bất tử không còn tội lỗi hay chết chóc.
  * **Người Hầu Việc Chúa Full-time** (`CERT_DIVINE_SHEPHERD`, `CERT_SANCTUARY_SERVICE`):
    * Tận hiến cho công việc mục vụ, đón tiếp cư dân, cầu nguyện và tư vấn tâm lý (nam hay nữ đều được).
    * **Trang phục chuẩn mực**: Cả nam và nữ NHVC đều mặc những **bộ VEST (Suits) lịch lãm, hiện đại, chỉn chu** phong cách Anime cao cấp.
    * **Chế độ Lương Sung Túc & Đồng Nhất**: Nhận trợ cấp từ Quỹ 1/10 **chung một mức lương đồng nhất, xứng đáng và sung túc** (tuyệt đối không phân biệt lương cao hay thấp hơn, bao gồm cả Người Đảm Nhiệm Nhà Thờ), đủ để tự do mua sắm những món đồ mình yêu thích, những vật dụng mình quý giá và nâng cấp cuộc sống thoải mái.
    * **Quyền Nghỉ Dưỡng & Chuyển Đổi Sứ Mệnh**: Khi cảm thấy **quá mỏi mệt**, người hầu việc Full-time (kể cả Người Đảm Nhiệm Nhà Thờ) hoàn toàn **có quyền xin chuyển xuống sứ mệnh khác nhẹ nhàng hơn, xin chuyển sang làm nghề đời sống (Full-time hoặc Part-time), hoặc xin nghỉ ngơi hoàn toàn một thời gian (Sabbatical Rest)** để hồi phục thể lực.
  * **Tình Nguyện Viên Hỗ Trợ Chúa (NHVC Part-time — Hoàn Toàn Không Nhận Lương)**:
    * Là các công dân có nghề nghiệp chính trong xã hội (bác sĩ, giáo viên, thợ bánh, kỹ sư, thợ mộc, nghệ sĩ...), tự nguyện dành thời gian rảnh rỗi phụng sự Chúa và chăm sóc đồng bào; **hoàn toàn KHÔNG NHẬN LƯƠNG hay phụ cấp**.
    * Tổ chức theo **mạng lưới chăm sóc 4 cấp**: 1 Hội Trưởng (Trưởng khu vực) quản lý các Nhóm Trưởng; 1 Nhóm Trưởng quản lý các Tổ Trưởng; 1 Tổ Trưởng quản lý và thăm hỏi trực tiếp các Thành Viên trong tổ ($8 - 15$ hộ dân), đảm bảo không một ai bị cô đơn hay bỏ lại phía sau.
    * Cùng các ban tình nguyện: ca đoàn (`CERT_MUSIC_PERFORMANCE`), đón tiếp lữ khách Cảng Hòa Bình & chuẩn bị Bữa tiệc Bác ái Agape.
  * **Sứ Mạng Công Việc Hòa Bình (Works of Peace & Reconciliation)**:
    * Trích từ Quỹ 1/10 để viện trợ nhân đạo cho lữ khách, người tị nạn từ biển xa tìm đến cõi Tân Thế Giới.
    * Cứu trợ lương thực và thảo dược cho các vùng đất lân cận khi gặp thiên tai.
    * Hàn gắn mọi mâu thuẫn cộng đồng trong ánh sáng của tình yêu thương và sự hòa thuận.
* **LỊCH PHỤNG VỤ & QUY TẮC HIỆP THÔNG (11:40 - 14:00 THỨ TƯ & CHỦ NHẬT)**:
  * **100% CƯ DÂN THAM DỰ TRỰC TIẾP (OFFLINE) TẠI ĐẠI HỘI TRƯỜNG HOẶC 4 TÒA VỆ TINH**: Khi chuông báo gióng lên, toàn bộ công sở, lớp học, quán xá tạm dừng hoạt động:
    * *Tại Đỉnh Vát*: Dòng người từ Đỉnh Vát và các huyện lân cận tiến vào Đại Hội Trường $15.000$ chỗ tại Tòa Mega-Office Skyscraper $(X=0, Z=0)$ dự trực tiếp cùng Người Chăn Chiên.
    * *Tại 4 Huyện chân núi*: Cư dân khó khăn di chuyển hoặc ở xa tề tựu tại Hội trường của Tòa Cao ốc Vệ tinh huyện mình, theo dõi bài giảng của Người Chăn Chiên qua màn hình LED vòm siêu rộng và hiệp thông cùng Người Đảm Nhiệm Nhà Thờ khu vực.
  * **Ngoại lệ xem phát sóng cá nhân tại phòng**: Chỉ 3 trường hợp bất khả kháng mới được ở lại phòng làm việc/điều dưỡng (nhà khoa học đang thí nghiệm khẩn cấp, bệnh nhân điều dưỡng chưa đi lại được, kỹ sư trực lưới điện/cáp treo).
  * Đúng 14:00: Buổi lễ kết thúc, toàn thể cư dân tại Đỉnh Vát và 4 Tòa Vệ Tinh đồng loạt thưởng thức Bữa tiệc Bác ái Agape miễn phí và tỏa ra tiếp tục nhịp sống năng động!

---

## 7. CẤU TRÚC DỮ LIỆU CỐT LÕI (GDScript Contracts)

### 7.1 Citizen Data (`scripts/simulation/citizen_data.gd`)

```gdscript
class_name CitizenData
extends Resource

enum LifeStage { CHILD, ADULT } # Bất tử dừng lại ở tuổi thanh xuân (20-25 tuổi)

@export var citizen_id: String = ""
@export var full_name: String = ""
@export var age: int = 22
@export var life_stage: LifeStage = LifeStage.ADULT
@export var has_general_diploma: bool = true
@export var earned_certificates: Array[String] = []

# Employment
@export var current_building_id: String = ""
@export var current_slot_id: String = ""
@export var current_salary: float = 1200.0
@export var home_building_id: String = ""

# Needs & Happiness (0.0 to 100.0)
@export var hunger: float = 0.0
@export var energy: float = 100.0
@export var happiness: float = 85.0
@export var wallet_balance: float = 500.0
@export var monthly_tithe_contributed: float = 0.0 # 1/10 tiền dâng Chúa chăm lo dân sinh
```

### 7.2 Enterprise / Business Data (`scripts/simulation/enterprise_data.gd`)

```gdscript
class_name EnterpriseData
extends Resource

enum BusinessTier { TIER_1_STARTUP, TIER_2_GROWING, TIER_3_EXPANDED }

@export var enterprise_id: String = ""
@export var business_name: String = ""
@export var business_type: String = "BAKERY" # BAKERY, CAFE, GROCERY, RESTAURANT
@export var current_tier: BusinessTier = BusinessTier.TIER_1_STARTUP

# Accounting
@export var cash_reserve: float = 5000.0
@export var monthly_revenue: float = 0.0
@export var monthly_expenses: float = 0.0
@export var consecutive_profitable_months: int = 0
@export var consecutive_deficit_months: int = 0
@export var is_bankrupt: bool = false

# Staffing
@export var max_job_slots: int = 1
@export var filled_slots: Dictionary = {} # slot_id -> citizen_id
```

### 7.3 Local Bridge Implementation (`scripts/network/local_bridge.gd`)

```gdscript
class_name LocalBridge
extends Node

signal packet_dispatched(action: String, payload: Dictionary)
signal packet_received(action: String, payload: Dictionary, message_id: String)
signal connection_state_mutated(is_online: bool)

@export var logic_server_url: String = "ws://127.0.0.1:9099"
@export var auto_reconnect_interval: float = 3.0
@export var offline_mock_mode: bool = true

var _peer: WebSocketPeer = WebSocketPeer.new()
var _connected: bool = false
var _reconnect_timer: float = 0.0

func _ready() -> void:
 if not offline_mock_mode:
  _initiate_connection()

func _process(delta: float) -> void:
 if offline_mock_mode:
  return
  
 _peer.poll()
 var state: WebSocketPeer.State = _peer.get_ready_state()

 match state:
  WebSocketPeer.STATE_OPEN:
   if not _connected:
    _connected = true
    connection_state_mutated.emit(true)
   _drain_incoming_packets()
  
  WebSocketPeer.STATE_CLOSED, WebSocketPeer.STATE_CLOSING:
   if _connected:
    _connected = false
    connection_state_mutated.emit(false)
   _reconnect_timer += delta
   if _reconnect_timer >= auto_reconnect_interval:
    _reconnect_timer = 0.0
    _initiate_connection()

func _initiate_connection() -> void:
 var err: Error = _peer.connect_to_url(logic_server_url)
 if err != OK:
  pass

func _drain_incoming_packets() -> void:
 while _peer.get_available_packet_count() > 0:
  var raw_bytes: PackedByteArray = _peer.get_packet()
  var text_str: String = raw_bytes.get_string_from_utf8()
  var parsed_variant: Variant = JSON.parse_string(text_str)
  
  if typeof(parsed_variant) != TYPE_DICTIONARY:
   continue
  
  var dict: Dictionary = parsed_variant
  var action: String = dict.get("action", "")
  var payload: Dictionary = dict.get("payload", {})
  var msg_id: String = dict.get("reply_to", dict.get("message_id", ""))
  
  packet_received.emit(action, payload, msg_id)

func dispatch_command(action: String, payload: Dictionary) -> String:
 var generated_id: String = "%x" % hash(action + str(Time.get_ticks_usec()))
 
 if offline_mock_mode or _peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
  _handle_mock_response(action, payload, generated_id)
  return generated_id

 var packet_envelope: Dictionary = {
  "$schema": "urn:citysim:protocol:v1",
  "message_id": generated_id,
  "action": action,
  "timestamp": Time.get_unix_time_from_system(),
  "payload": payload
 }
 
 var serialized: String = JSON.stringify(packet_envelope)
 _peer.send_text(serialized)
 packet_dispatched.emit(action, payload)
 return generated_id

func _handle_mock_response(action: String, payload: Dictionary, msg_id: String) -> void:
 var mock_reply: Dictionary = {}
 match action:
  "HIRE_CITIZEN":
   mock_reply = {"status": "SUCCESS", "slot_id": payload.get("slot_id", ""), "citizen_id": payload.get("citizen_id", "")}
  "FIRE_CITIZEN":
   mock_reply = {"status": "SUCCESS", "slot_id": payload.get("slot_id", "")}
  "CONSTRUCT_FACILITY":
   mock_reply = {"status": "APPROVED", "assigned_id": "BLD_" + str(randi() % 1000)}
  _:
   mock_reply = {"status": "ACK"}
 
 call_deferred("emit_signal", "packet_received", action, mock_reply, msg_id)
```

---

## 8. STYLIZED SHADER SPECIFICATIONS (ANIME PIPELINE)

### 8.1 Stylized Cel-Shaded Sky (`assets/shaders/anime_sky.gdshader`)

```glsl
shader_type sky;

uniform vec3 sky_zenith_color : source_color = vec3(0.18, 0.45, 0.92);
uniform vec3 sky_horizon_color : source_color = vec3(0.72, 0.85, 0.98);
uniform vec3 ground_color : source_color = vec3(0.25, 0.35, 0.22);
uniform vec3 sun_disc_color : source_color = vec3(1.0, 0.98, 0.85);

uniform float sun_disc_size : hint_range(0.001, 0.05) = 0.015;
uniform float sun_disc_softness : hint_range(0.001, 0.1) = 0.005;

void sky() {
    float elevation = clamp(EYEDIR.y, -1.0, 1.0);
    vec3 col = mix(sky_horizon_color, sky_zenith_color, clamp(elevation * 1.5, 0.0, 1.0));
    if (elevation < 0.0) {
        col = mix(sky_horizon_color, ground_color, clamp(-elevation * 3.0, 0.0, 1.0));
    }

    float sun_distance = distance(EYEDIR, LIGHT0_DIRECTION);
    float sun_mask = smoothstep(sun_disc_size + sun_disc_softness, sun_disc_size, sun_distance);
    col += sun_disc_color * sun_mask * 2.0;

    COLOR = col;
}
```

### 8.2 Inverted Hull Anime Outline (`assets/shaders/anime_outline.gdshader`)

```glsl
shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.12, 0.10, 0.18, 1.0);
uniform float outline_thickness : hint_range(0.001, 0.05) = 0.008;

void vertex() {
    VERTEX += NORMAL * outline_thickness;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
```

### 8.3 Anime Water Surface (`assets/shaders/anime_water.gdshader`)

```glsl
shader_type spatial;
render_mode specular_toon, diffuse_toon;

uniform vec3 deep_water_color : source_color = vec3(0.05, 0.28, 0.53);
uniform vec3 shallow_water_color : source_color = vec3(0.22, 0.72, 0.78);
uniform vec3 foam_edge_color : source_color = vec3(0.95, 0.98, 1.0);
uniform float foam_distance : hint_range(0.01, 2.0) = 0.45;
uniform sampler2D depth_texture : hint_depth_texture;

void fragment() {
    float depth_raw = texture(depth_texture, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float scene_linear_depth = -view.z;
    float surface_depth = -VERTEX.z;
    float depth_diff = clamp(scene_linear_depth - surface_depth, 0.0, 10.0);

    vec3 base_col = mix(shallow_water_color, deep_water_color, smoothstep(0.5, 4.0, depth_diff));
    if (depth_diff < foam_distance) {
        base_col = foam_edge_color;
    }

    ALBEDO = base_col;
    ROUGHNESS = 0.15;
    SPECULAR = 0.5;
}
```

---

## 9. EXPLICIT FILE HIERARCHY RULES

All project assets, scripts, and scenes must be placed strictly within this tree:

```text
├── project.godot
├── README.md
├── assets/
│   ├── models/
│   │   ├── buildings/
│   │   │   ├── bank_modular/           # Bank exterior shells, counters & props
│   │   │   ├── hospital_modular/       # Clinic beds, reception desks
│   │   │   ├── school_modular/         # Desks, blackboards
│   │   │   ├── church_modular/         # Cathedral bell tower, stained glass, pipe organ
│   │   │   ├── science_modular/        # Lab desks, microscopes, observatory dome
│   │   │   ├── transit_modular/        # Cable car cabins, vintage tram cars, bus stops
│   │   │   └── commercial_modular/     # Bakery ovens, cafe counters, shelves
│   │   ├── characters/
│   │   │   └── citizens/               # Anime base meshes (Casual, Suits, Lab Coats, Vestments)
│   │   └── environment/                # Rocks, stylized trees, street lamps, funicular
│   ├── materials/                      # .tres Material files
│   ├── shaders/                        # .gdshader programs
│   └── audio/                          # Ambients (cathedral bells, wind, tram chimes, cicadas)
├── scenes/
│   ├── core/
│   │   ├── main_world.tscn             # Root scene combining terrain, light & sky
│   │   └── player_character.tscn       # Kinematic character controller
│   ├── terrain/
│   │   ├── plateau_terrain.tscn        # Chunked terrain manager
│   │   └── ocean_water_body.tscn       # Water volume
│   ├── characters/
│   │   └── npc_citizen_3d.tscn         # High-fidelity Tier 1 3D NPC agent
│   └── structures/
│       ├── base_building_template.tscn # Master building template with HR Board & Stations
│       ├── bank_building.tscn          # Pre-assembled enterable bank
│       ├── church_sanctuary.tscn       # Pre-assembled church with The Shepherd
│       ├── science_lab.tscn            # Pre-assembled innovation lab
│       └── door_interactable.tscn      # Procedural door unit
└── scripts/
    ├── core/
    │   ├── player_controller.gd        # First/Third-person kinematics
    │   └── world_manager.gd            # Day/night, 24h clock, Wednesday/Sunday liturgy hours
    ├── interactive/
    │   ├── door_controller.gd          # Procedural door swing
    │   └── hr_management_board.gd      # UI interface for hiring/firing by certificate
    ├── simulation/
    │   ├── citizen_data.gd             # Citizen Resource definition
    │   ├── enterprise_data.gd          # Business profit, growth slots, bankruptcy
    │   ├── citizen_manager.gd          # 3-Tier LoD manager & routine scheduler
    │   └── building_job_registry.gd    # Tracks building job slots & active workers
    └── network/
        └── local_bridge.gd             # IPC communication handler (with Mock Mode)
```

---

## 10. INSTRUCTIONS & BEHAVIORAL CONTRACT FOR AI ASSISTANTS

When solving problems, writing code, or generating scenes for this project, you must:

1. **Deny Any Request for Scene Teleportation for Interiors**:
   * Implement the `OccluderInstance3D` + door pivot pattern. All structures are enterable in real-time in the world mesh.
2. **Uphold Absolute Integrity (Zero Corruption)**:
   * Do not implement embezzlement, corruption, or backstabbing mechanics. All citizens and officials are 100% honest and community-focused.
3. **Enforce Liturgy Hours (Thứ Tư & Chủ Nhật: 11:40 - 14:00)**:
   * Church services occur strictly during this window. Town activities pause as citizens attend service led by The Shepherd.
4. **Reflect Macro HR Authority & Certificate Requirements**:
   * Citizens can only be hired into job slots if they possess the exact required certificate (`CERT_*`). Stations remain visually empty if unfilled.
   * R&D Scientists and Researchers (`CERT_APPLIED_RND`, `CERT_NANO_MATERIALS`, `CERT_BIO_GENETICS`) produce Knowledge Breakthrough Units (KBU) to unlock city-wide civic blueprints and mitigate machine wear & tear.
5. **Enforce Type Safety & Hardware Limits**:
   * Always write static GDScript types (`var distance: float = 12.0`, `-> void`).
   * Never block the main thread. Use `WorkerThreadPool` or `await get_tree().process_frame`.
   * Keep draw calls $\le 1200$ using `MultiMeshInstance3D` and LODs.
6. **Local-First Deterministic Persistence**:
   * Save and load world states via local `user://savegame.json` or SQLite using the `"Persist"` group and standard serialization. Absolutely no reliance on cloud backends.
7. **Weather & Seasonal Simulation Integrations**:
   * Simulate 4 seasons (Spring, Summer, Autumn, Winter) and dynamic weather (rain, sun, fog, snow) with agricultural growth rate multipliers ($1.2\times$ rain, $0.8\times$ drought) and realistic seasonal power loads without exceeding Iris Xe rendering budgets.
8. **Nighttime Skip & Batch Timestep Mechanics (23:00 - 06:00)**:
   * Provide seamless ways for the player to skip or fast-forward nighttime: bed sleep interaction `[E]`, UI skip button `[T]`, or Auto-Skip settings. When skipping, execute batch simulation ticks in RAM to preserve economic and demographic determinism.


