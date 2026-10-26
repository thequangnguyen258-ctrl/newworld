class_name DialogueManager
extends RefCounted

# ==============================================================================
# DIALOGUE MANAGER - HỆ THỐNG ĐỐI THOẠI PHÂN NHÁNH ANIME RPG
# Cung cấp lời thoại và cây lựa chọn quyết sách phong phú cho 5 NPC Trung Tâm:
# 1. Bác Nam (Tiệm Bánh Mì)
# 2. Chị Mai (Trạm Xá Sinh Thái)
# 3. Người Chăn Chiên David (Đại Hội Trường)
# 4. Kỹ Sư Tuấn (Bảo Trì Phương Tiện)
# 5. Bác Ba (Đại Diện Dân Cư 5 Huyện)
# ==============================================================================

const InventoryManagerScript = preload("res://scripts/economy/inventory_manager.gd")

static func get_dialogue_data_for_npc(npc_id: String) -> Dictionary:
	match npc_id:
		"baker_nam":
			var opts = [
				{
					"text": "🥖 Cho tôi xin một ổ bánh mì nóng nhé Bác Nam!",
					"action": "give_baguette"
				}
			]
			if InventoryManagerScript.get_item_count("item_wheat_sack") > 0:
				opts.append({
					"text": "🌾 Giao nộp Bao Lúa Mì Hữu Cơ Huyện Đông cho Bác Nam!",
					"action": "deliver_wheat_sack"
				})
			else:
				opts.append({
					"text": "🌾 Tình hình nguyên liệu lúa mì của tiệm thế nào rồi Bác?",
					"action": "quest_east_wheat"
				})
			opts.append({
				"text": "🪪 Xem Thẻ Căn Cước Số của Bác Nam",
				"action": "open_cccd"
			})
			opts.append({
				"text": "👋 Tạm biệt Bác Nam, chúc tiệm đắt hàng!",
				"action": "close"
			})
			return {
				"name": "Bác Nam",
				"role": "Nghệ Nhân Bánh Mì (52 tuổi)",
				"avatar": "🥖",
				"greeting": "Chào ngài Thị Trưởng! Mẻ bánh mì baguette men tự nhiên vừa ra lò thơm ngát đây ạ. Ngài có muốn nếm thử một ổ nóng hổi không?",
				"options": opts
			}

		"doctor_mai":
			var opts = [
				{
					"text": "🌿 Xin Chị Mai một bình trà thảo mộc tuyết sơn!",
					"action": "give_tea"
				}
			]
			if InventoryManagerScript.get_item_count("item_onsen_herb") > 0:
				opts.append({
					"text": "♨️ Giao Thảo Dược Suối Khoáng Onsen Huyện Bắc cho Chị Mai!",
					"action": "deliver_onsen_herb"
				})
			else:
				opts.append({
					"text": "♨️ Nguồn dược liệu quý của Trạm Xá lấy từ đâu vậy Chị?",
					"action": "quest_north_herb"
				})
			opts.append({
				"text": "🪪 Xem Thẻ Căn Cước Số của Chị Mai",
				"action": "open_cccd"
			})
			opts.append({
				"text": "👋 Cảm ơn Chị Mai, chúc trạm xá một ngày an lành!",
				"action": "close"
			})
			return {
				"name": "Chị Mai",
				"role": "Bác Sĩ Trưởng Trạm Xá (26 tuổi)",
				"avatar": "🌿",
				"greeting": "Kính chào Thị Trưởng! Không khí thảo nguyên và biển mây hôm nay rất tốt lành. Ngài có thấy mệt mỏi trong người không?",
				"options": opts
			}

		"shepherd_david":
			var opts = [
				{
					"text": "🔔 Thưa Mục Tử, tôi xin phép kéo Chuông Hòa Bình cầu nguyện!",
					"action": "ring_bell"
				}
			]
			if InventoryManagerScript.get_item_count("item_fresh_fish") > 0:
				opts.append({
					"text": "🐟 Trao Thùng Hải Sản Huyện Nam chuẩn bị Đại Tiệc Agape!",
					"action": "deliver_fresh_fish"
				})
			opts.append({
				"text": "🕊️ Tình hình các Hội Đoàn và Bữa Tiệc Bác Ái Agape ra sao rồi?",
				"action": "tell_agape"
			})
			opts.append({
				"text": "🪪 Xem Thẻ Căn Cước Số của Mục Tử",
				"action": "open_cccd"
			})
			opts.append({
				"text": "👋 Cảm ơn Mục Tử David!",
				"action": "close"
			})
			return {
				"name": "Người Chăn Chiên David",
				"role": "Mục Tử Đại Hội Trường (38 tuổi)",
				"avatar": "🕊️",
				"greeting": "Bình an cho ngài Thị Trưởng! Thánh đường 15.000 chỗ luôn rộng mở đón tiếp mọi người vào Thứ Tư và Chủ Nhật lúc 11:40.",
				"options": opts
			}

		"mechanic_tuan":
			var opts = [
				{
					"text": "🚗 Nhận chìa khóa điện tử xe Buggy tuần tra",
					"action": "give_buggy_key"
				}
			]
			if InventoryManagerScript.get_item_count("item_solar_battery") > 0:
				opts.append({
					"text": "⚡ Bàn giao Khối Pin Năng Lượng Mặt Trời Huyện Tây cho Kỹ Sư Tuấn!",
					"action": "deliver_solar_battery"
				})
			else:
				opts.append({
					"text": "⚙️ Tình hình lưới điện gió Huyện Tây thế nào Tuấn?",
					"action": "quest_west_power"
				})
			opts.append({
				"text": "🪪 Xem Thẻ Căn Cước Số của Kỹ Sư Tuấn",
				"action": "open_cccd"
			})
			opts.append({
				"text": "👋 Cảm ơn Tuấn, tiếp tục phát huy nhé!",
				"action": "close"
			})
			return {
				"name": "Kỹ Sư Tuấn",
				"role": "Chuyên Viên Kỹ Nghệ & Xe Cộ (29 tuổi)",
				"avatar": "⚡",
				"greeting": "Báo cáo Thị Trưởng! Xe Buggy Điện 60 km/h và Trực Thăng Cao Tốc đều đã được sạc đầy 100% pin mặt trời, sẵn sàng xuất phát!",
				"options": opts
			}

		"elder_ba":
			var opts = [
				{
					"text": "📜 Mở Bảng Tin chi tiết nguyện vọng của 5 huyện",
					"action": "open_petitions"
				}
			]
			if InventoryManagerScript.get_item_count("item_fresh_fish") > 0:
				opts.append({
					"text": "🐟 Trao Thùng Hải Sản Huyện Nam chuẩn bị Đại Tiệc Agape!",
					"action": "deliver_fresh_fish"
				})
			else:
				opts.append({
					"text": "⛵ Bà con Huyện Nam ngoài hải đăng và cầu cảng sinh sống ra sao Bác?",
					"action": "quest_south_port"
				})
			opts.append({
				"text": "🪪 Xem Thẻ Căn Cước Số của Bác Ba",
				"action": "open_cccd"
			})
			opts.append({
				"text": "👋 Chính quyền sẽ luôn lắng nghe và chăm lo cho bà con!",
				"action": "close"
			})
			return {
				"name": "Bác Ba",
				"role": "Đại Diện Cư Dân 5 Huyện (58 tuổi)",
				"avatar": "📜",
				"greeting": "Thưa Thị Trưởng, tôi thay mặt bà con 4 huyện ngoại vi đến trình bày các nguyện vọng an sinh tại Bảng Tin đây ạ!",
				"options": opts
			}

		# --- 4 ĐẠI DIỆN NPC CỐT LÕI TẠI 4 HUYỆN NGOẠI VI ---
		"farmer_hai":
			return {
				"name": "Bác Hai",
				"role": "Trưởng Thôn Nông Trang Huyện Đông (56 tuổi)",
				"avatar": "🌾",
				"greeting": "Kính chào ngài Thị Trưởng ghé thăm Huyện Đông! Vụ lúa mì năm nay trúng lớn, các cối xay gió đang hoạt động hết công suất để xay bột tươi nguyên cám.",
				"options": [
					{
						"text": "🌾 Nhận Bao Lúa Mì Hữu Cơ mang về tiếp tế cho Tiệm Bác Nam",
						"action": "give_wheat_sack"
					},
					{
						"text": "🪪 Xem Thẻ Căn Cước Số của Bác Hai",
						"action": "open_cccd"
					},
					{
						"text": "👋 Chúc bà con Huyện Đông mùa màng luôn bội thu!",
						"action": "close"
					}
				]
			}

		"ranger_lam":
			return {
				"name": "Thợ Rừng Lâm",
				"role": "Kiểm Lâm & Quản Lý Onsen Huyện Bắc (33 tuổi)",
				"avatar": "🌲",
				"greeting": "Kính chào Thị Trưởng! Rừng thông đại ngàn và dòng suối khoáng nóng Onsen Huyện Bắc vô cùng trong lành, nước ấm giàu khoáng chất bốc khói mờ ảo.",
				"options": [
					{
						"text": "♨️ Thu hái Thảo Dược Suối Khoáng Onsen mang về cho Trạm Xá Chị Mai",
						"action": "give_onsen_herb"
					},
					{
						"text": "♨️ Ngâm mình thư giãn tại suối Onsen phục hồi sinh lực (Hồi 100% HP)",
						"action": "bathe_onsen"
					},
					{
						"text": "🪪 Xem Thẻ Căn Cước Số của Thợ Rừng Lâm",
						"action": "open_cccd"
					},
					{
						"text": "👋 Cảm ơn anh, chúc khu rừng luôn xanh tươi an bình!",
						"action": "close"
					}
				]
			}

		"engineer_khoa":
			return {
				"name": "Kỹ Sư Khoa",
				"role": "Trưởng Trạm Năng Lượng Huyện Tây (24 tuổi)",
				"avatar": "⚙️",
				"greeting": "Chào Thị Trưởng! 3 trụ quạt gió và hệ thống pin năng lượng mặt trời trên mái xưởng đang phát điện ổn định 100% công suất hòa vào lưới điện đô thị.",
				"options": [
					{
						"text": "⚡ Nhận Khối Pin Năng Lượng Sạch cấp điện cho Thủ Phủ",
						"action": "give_solar_battery"
					},
					{
						"text": "🚗 Kiểm tra trạm sạc nhanh EV và xe Buggy Huyện Tây",
						"action": "inspect_ev_station"
					},
					{
						"text": "🪪 Xem Thẻ Căn Cước Số của Kỹ Sư Khoa",
						"action": "open_cccd"
					},
					{
						"text": "👋 Tiếp tục duy trì nguồn năng lượng xanh sạch nhé Khoa!",
						"action": "close"
					}
				]
			}

		"captain_hai":
			return {
				"name": "Thuyền Trưởng Hải",
				"role": "Cảng Trưởng Cảng Hòa Bình Huyện Nam (45 tuổi)",
				"avatar": "⚓",
				"greeting": "Kính chào Thị Trưởng đã đến Cảng Hòa Bình Huyện Nam! Ngọn hải đăng vẫn soi sáng đêm ngày, đoàn thuyền đánh cá vừa cập bến với hải sản tươi ngon.",
				"options": [
					{
						"text": "🐟 Nhận Thùng Hải Sản Tươi Ngon cho Bữa Tiệc Bác Ái Agape",
						"action": "give_fresh_fish"
					},
					{
						"text": "⛵ Tham quan ngọn hải đăng và cầu cảng đón tiếp lữ khách",
						"action": "inspect_harbor"
					},
					{
						"text": "🪪 Xem Thẻ Căn Cước Số của Thuyền Trưởng Hải",
						"action": "open_cccd"
					},
					{
						"text": "👋 Chúc các thủy thủ và lữ khách luôn thuận buồm xuôi gió!",
						"action": "close"
					}
				]
			}

		_:
			return {
				"name": "Cư Dân Tân Thế Giới",
				"role": "Công Dân Tự Do",
				"avatar": "🙂",
				"greeting": "Chào ngài Thị Trưởng! Chúc ngài một ngày an lành và đầy phước hạnh!",
				"options": [
					{
						"text": "🪪 Xem Thẻ Căn Cước Số",
						"action": "open_cccd"
					},
					{
						"text": "👋 Chào tạm biệt!",
						"action": "close"
					}
				]
			}

