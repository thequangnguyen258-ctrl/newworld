class_name DailyScheduleManager
extends RefCounted

# ==============================================================================
# DAILY SCHEDULE MANAGER - HỆ THỐNG LỊCH TRÌNH SINH HOẠT CƯ DÂN 5 HUYỆN
# Đồng bộ theo Đồng Hồ Thế Giới WorldManager (Tỉ lệ vàng 1:20):
# 1. Ban Mai & Điểm Tâm (06:00 - 08:00): Thức giấc, ăn sáng, tập thể dục, dạo phố
# 2. Lao Động Sản Xuất Sáng (08:00 - 11:40): Chuyên ngành 5 Huyện hăng say
# 3. Thánh Lễ & Tiệc Agape (11:40 - 14:00): Thứ 4 & Chủ Nhật Đại Quy Tụ; ngày thường cơm trưa
# 4. Lao Động & Giao Thương Chiều (14:00 - 17:30): Vận tải mạng nhện, học viện, hội đoàn
# 5. Hoàng Hôn & Thư Giãn (17:30 - 20:30): Cloud Cafe, biển mây, ca nhạc, dạo phố
# 6. Nghỉ Đêm Bình An (20:30 - 06:00): Lên đèn lồng Toon, an giấc ngủ, hỗ trợ Night Skip
# ==============================================================================

enum TimeSlot {
	MORNING_DAWN,       # 06:00 - 08:00
	MORNING_WORK,       # 08:00 - 11:40
	NOON_LITURGY_MEAL,  # 11:40 - 14:00
	AFTERNOON_WORK,     # 14:00 - 17:30
	EVENING_SUNSET,     # 17:30 - 20:30
	NIGHT_REST          # 20:30 - 06:00
}

static func get_time_slot(hour: int, minute: int = 0) -> TimeSlot:
	var total_min = hour * 60 + minute
	if total_min >= 6 * 60 and total_min < 8 * 60:
		return TimeSlot.MORNING_DAWN
	elif total_min >= 8 * 60 and total_min < (11 * 60 + 40):
		return TimeSlot.MORNING_WORK
	elif total_min >= (11 * 60 + 40) and total_min < 14 * 60:
		return TimeSlot.NOON_LITURGY_MEAL
	elif total_min >= 14 * 60 and total_min < (17 * 60 + 30):
		return TimeSlot.AFTERNOON_WORK
	elif total_min >= (17 * 60 + 30) and total_min < (20 * 60 + 30):
		return TimeSlot.EVENING_SUNSET
	else:
		return TimeSlot.NIGHT_REST

static func get_time_slot_name(slot: TimeSlot) -> String:
	match slot:
		TimeSlot.MORNING_DAWN:
			return "Ban Mai & Điểm Tâm"
		TimeSlot.MORNING_WORK:
			return "Lao Động Sản Xuất Sáng"
		TimeSlot.NOON_LITURGY_MEAL:
			return "Thánh Lễ & Bữa Ăn Huynh Đệ"
		TimeSlot.AFTERNOON_WORK:
			return "Lao Động & Giao Thương Chiều"
		TimeSlot.EVENING_SUNSET:
			return "Hoàng Hôn & Thư Giãn Cộng Đồng"
		TimeSlot.NIGHT_REST:
			return "Nghỉ Đêm Bình An"
		_:
			return "Sinh Hoạt Thường Nhật"

static func get_time_slot_icon(slot: TimeSlot) -> String:
	match slot:
		TimeSlot.MORNING_DAWN:
			return "🌅"
		TimeSlot.MORNING_WORK:
			return "🔨"
		TimeSlot.NOON_LITURGY_MEAL:
			return "⛪"
		TimeSlot.AFTERNOON_WORK:
			return "📦"
		TimeSlot.EVENING_SUNSET:
			return "🌆"
		TimeSlot.NIGHT_REST:
			return "🌙"
		_:
			return "🌿"

static func get_facility_schedule(facility_id: String, day_index: int, hour: int, minute: int) -> Dictionary:
	var slot := get_time_slot(hour, minute)
	var attendant_id := ""
	var attendant_name := ""
	var service_slots: Array[int] = []

	match facility_id:
		"bakery":
			attendant_id = "baker_nam"
			attendant_name = "Bác Nam"
			service_slots = [TimeSlot.MORNING_DAWN, TimeSlot.MORNING_WORK, TimeSlot.AFTERNOON_WORK]
		"clinic":
			attendant_id = "doctor_mai"
			attendant_name = "Chị Mai"
			service_slots = [TimeSlot.MORNING_DAWN, TimeSlot.MORNING_WORK, TimeSlot.AFTERNOON_WORK]
		"east_wheat_station":
			attendant_id = "farmer_hai"
			attendant_name = "Bác Hai"
			service_slots = [TimeSlot.MORNING_WORK, TimeSlot.AFTERNOON_WORK]
		"north_onsen_station":
			attendant_id = "ranger_lam"
			attendant_name = "Thợ Rừng Lâm"
			service_slots = [TimeSlot.MORNING_WORK, TimeSlot.AFTERNOON_WORK]
		"west_solar_station":
			attendant_id = "engineer_khoa"
			attendant_name = "Kỹ Sư Khoa"
			service_slots = [TimeSlot.MORNING_WORK, TimeSlot.AFTERNOON_WORK]
		"south_harbor_station":
			attendant_id = "captain_hai"
			attendant_name = "Thuyền Trưởng Hải"
			service_slots = [TimeSlot.MORNING_WORK, TimeSlot.AFTERNOON_WORK]
		_:
			return {"is_tracked": false, "is_open": true}

	var is_open := service_slots.has(slot)
	return {
		"is_tracked": true,
		"is_open": is_open,
		"attendant_id": attendant_id,
		"attendant_name": attendant_name,
		"slot": slot,
		"slot_name": get_time_slot_name(slot),
		"day_index": day_index,
		"status_text": "Đang phục vụ" if is_open else "Đóng cửa theo lịch sinh hoạt"
	}

# Truy vấn hoạt động chi tiết của cư dân theo thời gian thực
static func get_npc_schedule(npc_id: String, citizen_name: String, job_title: String, district_name: String, day_index: int, hour: int, minute: int) -> Dictionary:
	var slot = get_time_slot(hour, minute)
	var is_liturgy_day = (day_index == 2 or day_index == 6) # Thứ Tư hoặc Chủ Nhật
	var is_saturday = (day_index == 5)                     # Thứ Bảy

	var activity = ""
	var dialogue = ""
	var location = district_name
	var icon = get_time_slot_icon(slot)
	var is_on_duty := slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK
	if npc_id == "baker_nam" or npc_id == "doctor_mai":
		is_on_duty = slot == TimeSlot.MORNING_DAWN or slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK

	match npc_id:
		"baker_nam":
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Nhóm lò nướng bánh mì baguette đầu ngày"
					dialogue = "Chào buổi sáng Thị trưởng! Lò nướng đang hừng đỏ, mẻ bánh mì hoa cúc đầu tiên sắp ra lò thơm phức đây ạ!"
					icon = "🥖"
				TimeSlot.MORNING_WORK:
					activity = "Trao bánh mì nóng & phục vụ cư dân dạo phố"
					dialogue = "Kính mời Thị trưởng nếm thử bánh mì men tự nhiên nóng giòn! Cả đô thị ai cũng thích bữa sáng bổ dưỡng này."
					icon = "🥖"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Dự Thánh Lễ & chuẩn bị bánh mì cho Tiệc Agape"
						dialogue = "Thánh Lễ vừa dâng xong thật phước hạnh. Tôi đã chuyển 500 ổ bánh mì tới Bữa Tiệc Bác Ái Agape rồi thưa ngài!"
						icon = "⛪"
					else:
						activity = "Nghỉ trưa & chia sẻ bữa cơm ấm cúng cùng hàng xóm"
						dialogue = "Mời Thị trưởng ngồi nghỉ uống ngụm nước mát, ăn tạm lát bánh mì ngọt thơm lừng rồi tiếp tục công vụ nhé!"
						icon = "🍵"
				TimeSlot.AFTERNOON_WORK:
					activity = "Ủ men tự nhiên & hướng dẫn học viên nghề làm bánh"
					dialogue = "Lúa mì hữu cơ của Huyện Đông năm nay thơm và dẻo bột lắm ngài ạ. Các bạn học viên thực hành rất tiến bộ!"
					icon = "🌾"
				TimeSlot.EVENING_SUNSET:
					activity = "Dọn quầy bánh & đi dạo ngắm hoàng hôn đài phun nước"
					dialogue = "Ráng chiều vàng buông xuống quảng trường đẹp quá. Bác Nam tranh thủ hóng gió sau một ngày nướng bánh hăng say."
					icon = "🌆"
				TimeSlot.NIGHT_REST:
					activity = "Về nhà nghỉ ngơi tại Nhà Mẫu Vành Đai 2"
					dialogue = "Chúc Thị trưởng buổi tối an lành! Tôi về nhà nghỉ ngơi để sáng mai lại dậy sớm nổi lửa lò nướng."
					icon = "🌙"

		"doctor_mai":
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Đun trà thảo mộc tuyết sơn đón sương mai"
					dialogue = "Chào Thị trưởng! Sáng sớm uống một tách trà thảo mộc ấm sẽ giúp điều hòa khí huyết và minh mẫn suốt ngày dài."
					icon = "🌿"
				TimeSlot.MORNING_WORK:
					activity = "Khám dưỡng sinh & phát trà dược liệu phục hồi sinh lực"
					dialogue = "Trạm xá sinh thái luôn rộng cửa! Cư dân làm việc hăng say nếu thấy mỏi mệt chỉ cần một bình trà là hồi phục 100%!"
					icon = "🌿"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Dự Thánh Lễ & hỗ trợ tổ y tế phụng vụ"
						dialogue = "Lời Chúa ban bình an thật kỳ diệu. Mọi mệt mỏi thể chất của cư dân đều được nâng đỡ trong thánh ân."
						icon = "⛪"
					else:
						activity = "Nghỉ trưa thanh tịnh tại vườn dược liệu trạm xá"
						dialogue = "Giờ nghỉ trưa tĩnh lặng giữa hương hoa tuyết sơn giúp tinh thần bác sĩ luôn tươi mới và an hòa."
						icon = "🍵"
				TimeSlot.AFTERNOON_WORK:
					activity = "Phân loại thảo dược Huyện Bắc & pha chế cao thảo mộc"
					dialogue = "Dược liệu thu hái từ suối khoáng Onsen Huyện Bắc gửi về rất giàu khoáng chất. Tôi đang bào chế cao dưỡng sinh."
					icon = "♨️"
				TimeSlot.EVENING_SUNSET:
					activity = "Dạo bộ ngắm biển mây & trò chuyện tâm lý cư dân"
					dialogue = "Hoàng hôn buông trên đỉnh cao nguyên luôn làm lòng người dịu lại. Ngài Thị trưởng có muốn cùng tản bộ không?"
					icon = "🌆"
				TimeSlot.NIGHT_REST:
					activity = "Nghỉ ngơi an giấc trong trạm xá sinh thái"
					dialogue = "Đêm đã về khuya, chúc Thị trưởng có một giấc ngủ an bình trong sự chở che của Đấng Tối Cao."
					icon = "🌙"

		"farmer_hai":
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Thăm đồng lúa mạch sương mai & kiểm tra cối xay gió"
					dialogue = "Chào Thị trưởng! Đứng giữa đồng lúa Huyện Đông hít thở ngọn gió sớm mai thấy lòng phơi phới lạ thường!"
					icon = "🌾"
				TimeSlot.MORNING_WORK:
					activity = "Thu hoạch lúa mạch vàng ươm & chuyển thóc vào Silo"
					dialogue = "Vụ mùa bội thu rồi thưa ngài! Các thợ gặt đang khẩn trương thu hoạch để trữ đầy kho thóc 14m."
					icon = "🌾"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Dự Thánh Lễ tại Tòa Vệ Tinh Huyện Đông"
						dialogue = "Toàn thể bà con nông trang cùng tạ ơn Trời Đất đã ban mưa thuận gió hòa, mùa màng trĩu hạt!"
						icon = "⛪"
					else:
						activity = "Nghỉ trưa dưới bóng râm cối xay gió khổng lồ"
						dialogue = "Mời ngài ngồi xuống ụ rơm uống chén nước vối mát ngọt của nông thôn Huyện Đông."
						icon = "🍵"
				TimeSlot.AFTERNOON_WORK:
					activity = "Xay lúa mì thành bột mịn & đóng bao tiếp tế Thủ Phủ"
					dialogue = "Cối xay gió đang quay đều tăm tắp, bột lúa mì hữu cơ trắng mịn đã sẵn sàng chuyển lên ga Tram Vành Đai."
					icon = "⚙️"
				TimeSlot.EVENING_SUNSET:
					activity = "Ngồi trên đồi cỏ ngắm cánh quạt cối xay trong hoàng hôn"
					dialogue = "Ráng chiều nhuộm đỏ rực cánh đồng lúa mì, khung cảnh đẹp như tranh vẽ của Makoto Shinkai vậy ngài ơi!"
					icon = "🌆"
				TimeSlot.NIGHT_REST:
					activity = "Nghỉ ngơi ấm cúng trong Grand Barn Huyện Đông"
					dialogue = "Chúc Thị trưởng vạn sự an lành. Nông dân chúng tôi ngủ sớm để đón bình minh 06:00 ngày mai."
					icon = "🌙"

		"engineer_khoa":
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Đo đạc tốc độ gió & chuẩn bị chuỗi quang điện mặt trời"
					dialogue = "Chào Thị trưởng! Luồng gió thung lũng Huyện Tây sáng nay đạt vận tốc lý tưởng 12m/s, quạt gió quay rất êm!"
					icon = "⚡"
				TimeSlot.MORNING_WORK:
					activity = "Bảo dưỡng tuabin gió 24m & kiểm tra trạm sạc siêu tốc"
					dialogue = "Lưới điện xanh của 5 Huyện vận hành 100% ổn định. Không có bất kỳ sự cố chập mạch hay quá tải nào!"
					icon = "⚡"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Dự Thánh Lễ tại Tòa Vệ Tinh Huyện Tây"
						dialogue = "Khoa học kỹ nghệ hòa hợp với tâm linh thuần khiết mang lại sự an tâm tuyệt đối cho các kỹ sư chúng tôi."
						icon = "⛪"
					else:
						activity = "Ăn cơm trưa & thảo luận công nghệ xanh cùng đồng nghiệp"
						dialogue = "Chúng tôi vừa ăn trưa vừa kiểm tra đồ thị phụ tải điện qua màn hình điều khiển."
						icon = "🍱"
				TimeSlot.AFTERNOON_WORK:
					activity = "Nạp đầy các khối Pin Sạch dung lượng cao cho xe Buggy"
					dialogue = "Các khối pin năng lượng sạch dự trữ đã nạp 100%, sẵn sàng bàn giao cho ngài Thị trưởng tuần tra."
					icon = "🔋"
				TimeSlot.EVENING_SUNSET:
					activity = "Đứng trên tháp kỹ nghệ ngắm thung lũng quạt gió ráng chiều"
					dialogue = "Ánh hoàng hôn phản chiếu trên các cánh quạt gió trắng muốt tạo nên vẻ đẹp công nghiệp sinh thái tuyệt mỹ."
					icon = "🌆"
				TimeSlot.NIGHT_REST:
					activity = "Nghỉ ngơi tại trạm điều hành kỹ thuật Huyện Tây"
					dialogue = "Hệ thống tự động đã kích hoạt chế độ giám sát ban đêm. Chúc ngài Thị trưởng một đêm ngon giấc!"
					icon = "🌙"

		"ranger_lam":
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Tuần tra rừng thông đại ngàn & hít thở sương sớm Onsen"
					dialogue = "Chào Thị trưởng! Không khí rừng tuyết tùng Huyện Bắc trong veo, tiếng suối reo hòa cùng tiếng chim líu lo."
					icon = "🌲"
				TimeSlot.MORNING_WORK:
					activity = "Kiểm tra nhiệt độ suối Onsen & hái trà thảo mộc tuyết sơn"
					dialogue = "Hồ nước khoáng nóng Onsen hôm nay đạt 42 độ C lý tưởng, khoáng chất bốc khói mờ ảo chữa lành mọi mỏi mệt."
					icon = "♨️"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Dự Thánh Lễ tại Tòa Vệ Tinh Huyện Bắc"
						dialogue = "Rừng đại ngàn cùng hòa ca lời tạ ơn Đấng Sáng Tạo đã ban cho chúng ta thiên nhiên kỳ vĩ này."
						icon = "⛪"
					else:
						activity = "Ngâm chân suối khoáng & dùng cơm trưa thanh đạm"
						dialogue = "Mời ngài Thị trưởng cởi giày ngâm chân thư giãn trong làn nước khoáng nóng Onsen hồi phục năng lượng!"
						icon = "♨️"
				TimeSlot.AFTERNOON_WORK:
					activity = "Vận hành cối xay nước gỗ cổ điển & gia cố đường mòn rừng"
					dialogue = "Bánh xe cối xay nước gỗ đang quay đều đặn, cấp dòng nước trong vắt về cho hệ thống thủy văn toàn huyện."
					icon = "🪵"
				TimeSlot.EVENING_SUNSET:
					activity = "Thắp lồng đèn ấm áp quanh hồ Onsen đón khách dạo mát"
					dialogue = "Khi ánh đèn lồng rực sáng bên hồ suối khoáng, cả khu rừng như hóa thành khung cảnh huyền ảo trong phim hoạt hình."
					icon = "🏮"
				TimeSlot.NIGHT_REST:
					activity = "Nghỉ ngơi trong chòi gỗ tuyết tùng ngát hương"
					dialogue = "Đêm rừng Bắc tĩnh mịch và sâu lắng. Chúc ngài Thị trưởng bình an trở về thủ phủ."
					icon = "🌙"

		"captain_hai":
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Kéo cờ cảng biển & ngắm bình minh trên biển mây duyên hải"
					dialogue = "Chào Thị trưởng! Gió biển mây Huyện Nam sáng nay thổi căng buồm. Hải âu ríu rít chào ngày mới kìa ngài!"
					icon = "⚓"
				TimeSlot.MORNING_WORK:
					activity = "Đón tàu buôn cập cầu cảng 60m & bốc dỡ hải sản tươi"
					dialogue = "Thuyền câu vừa cập bến với những mẻ cá ngừ, tôm tươi rói phục vụ toàn thể cư dân 5 Huyện!"
					icon = "🐟"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Dự Thánh Lễ tại Tòa Vệ Tinh Cảng Hòa Bình"
						dialogue = "Người đi biển chúng tôi luôn cảm tạ ơn Chúa đã gìn giữ cho sóng yên biển lặng trên muôn dặm hải hành."
						icon = "⛪"
					else:
						activity = "Ăn cơm trưa cá nướng thơm lừng cùng thủy thủ đoàn"
						dialogue = "Mời ngài Thị trưởng thưởng thức món cá biển nướng muối ớt dân dã nhưng đậm đà hương vị đại dương."
						icon = "🍱"
				TimeSlot.AFTERNOON_WORK:
					activity = "Điều phối chợ phiên Bazaar & đóng thùng hải sản dự tiệc"
					dialogue = "Chợ phiên duyên hải đang tấp nập giao thương. Các thùng cá tươi ngon nhất đã được đóng băng gửi về Thủ Phủ."
					icon = "🏪"
				TimeSlot.EVENING_SUNSET:
					activity = "Bật đèn Đại Hải Đăng 26m soi sáng & thổi kèn ốc biển"
					dialogue = "Ngọn hải đăng bắt đầu xoay luồng sáng dẫn đường trong ráng hoàng hôn tím biếc. Biển đêm bắt đầu buông màn."
					icon = "🏮"
				TimeSlot.NIGHT_REST:
					activity = "Nghỉ ngơi trong cabin tàu cảng biển ấm cúng"
					dialogue = "Nghe tiếng sóng vỗ rì rào ru giấc ngủ thật êm đềm. Chúc Thị trưởng một đêm thanh bình."
					icon = "🌙"

		_:
			# Mẫu sinh hoạt tự nhiên cho 8 Cư Dân Thực Địa và các NPC khác
			match slot:
				TimeSlot.MORNING_DAWN:
					activity = "Tập dưỡng sinh & thưởng thức bánh mì điểm tâm"
					dialogue = "Chào Thị trưởng! Một buổi sáng tinh khôi và an lành lại bắt đầu trên vùng đất phước hạnh này."
					icon = "🌅"
				TimeSlot.MORNING_WORK:
					activity = "Lao động chuyên môn: " + job_title
					dialogue = "Chúng tôi đang tập trung làm tốt phần việc của mình để cùng nhau xây dựng Tân Thế Giới phồn vinh!"
					icon = "🔨"
				TimeSlot.NOON_LITURGY_MEAL:
					if is_liturgy_day:
						activity = "Tham dự Thánh Lễ & Bữa Tiệc Bác Ái Agape"
						dialogue = "Cùng hiệp một lòng trong Thánh Lễ và chung vui bữa tiệc huynh đệ là niềm hạnh phúc lớn nhất của chúng tôi."
						icon = "⛪"
					else:
						activity = "Nghỉ trưa, dùng bữa cơm huynh đệ ấm áp"
						dialogue = "Giờ nghỉ trưa thân tình giúp mọi người gắn kết như anh em trong một gia đình."
						icon = "🍲"
				TimeSlot.AFTERNOON_WORK:
					if is_saturday:
						activity = "Sinh hoạt Hội Đoàn & Trao đổi kỹ năng nghề"
						dialogue = "Chiều Thứ Bảy là ngày hội của các bạn trẻ và nghệ nhân chia sẻ kinh nghiệm học tập, sáng tạo."
						icon = "🎨"
					else:
						activity = "Lao động sản xuất & rèn luyện nâng bậc tay nghề"
						dialogue = "Mỗi sản phẩm tạo ra đều được chăm chút bằng tình yêu thương và sự khéo léo."
						icon = "📦"
				TimeSlot.EVENING_SUNSET:
					activity = "Dạo bước quảng trường & ngắm hoàng hôn biển mây"
					dialogue = "Đi bộ thư giãn trên sàn đá hoa cương, lắng nghe tiếng chuông hòa bình ngân vang thật thanh thản."
					icon = "🌆"
				TimeSlot.NIGHT_REST:
					activity = "Nghỉ ngơi tại gia đình ấm cúng"
					dialogue = "Chúc Thị trưởng buổi tối tốt lành và có giấc ngủ êm đềm!"
					icon = "🌙"

	return {
		"slot": slot,
		"slot_name": get_time_slot_name(slot),
		"slot_icon": icon,
		"activity": activity,
		"dialogue": dialogue,
		"location": location,
		"is_on_duty": is_on_duty
	}

static func get_citizen_schedule(
	job_role: String,
	is_church_servant: bool,
	day_index: int,
	hour: int,
	minute: int,
	is_active_driver: bool = true,
	needs_community_support: bool = false,
	is_monthly_meetup: bool = false,
	workplace_id: String = "",
	servant_type: String = "NONE",
	has_family: bool = false
) -> Dictionary:
	var slot := get_time_slot(hour, minute)
	var is_liturgy_day := day_index == 2 or day_index == 6
	var activity := ""
	var icon := get_time_slot_icon(slot)
	var destination := "home"
	var pose := "idle"

	if needs_community_support and is_monthly_meetup:
		activity = "Tham gia buổi gặp mặt hỗ trợ trực tiếp hằng tháng"
		icon = "🤝"
		destination = "gathering"
		pose = "social"
	elif slot == TimeSlot.NIGHT_REST:
		activity = "Ngủ nghỉ tại nhà"
		icon = "🌙"
		pose = "sleep"
	elif slot == TimeSlot.MORNING_DAWN:
		activity = "Thức dậy, vệ sinh cá nhân và ăn sáng"
		icon = "🍳"
		destination = "home"
		pose = "rest"
	elif slot == TimeSlot.NOON_LITURGY_MEAL:
		if is_liturgy_day:
			activity = "Tham dự Thánh Lễ và sinh hoạt cộng đồng"
			icon = "⛪"
			destination = "gathering"
			pose = "social"
		else:
			activity = "Nghỉ trưa và dùng bữa"
			icon = "🍲"
			destination = "rest"
			pose = "sit"
	elif slot == TimeSlot.EVENING_SUNSET:
		if has_family:
			activity = "Dùng bữa và trò chuyện cùng người thân"
			icon = "🏠"
			destination = "family"
		else:
			activity = "Dạo phố, trò chuyện và thư giãn"
			icon = "🌆"
			destination = "leisure"
		pose = "social"
	elif job_role == "Nông dân":
		activity = "Gieo trồng, chăm sóc và thu hoạch mùa vụ"
		icon = "🌾"
		destination = "farm"
		pose = "work"
	elif job_role == "Lái xe bus":
		if is_active_driver:
			activity = "Đưa đón hành khách theo ca xe buýt"
			icon = "🚌"
			destination = "transit"
			pose = "drive"
		else:
			activity = "Bảo dưỡng xe và nghỉ giữa các ca luân phiên"
			icon = "🔧"
			destination = "work"
			pose = "work"
	elif job_role == "Lái tàu điện":
		if is_active_driver:
			activity = "Điều khiển tàu điện theo lịch tuyến"
			icon = "🚊"
			destination = "transit"
			pose = "drive"
		else:
			activity = "Kiểm tra toa tàu và nghỉ giữa các ca luân phiên"
			icon = "🔧"
			destination = "work"
			pose = "work"
	elif job_role in [
		"Tài xế xe tải nhẹ",
		"Tài xế xe tải trung",
		"Tài xế xe container",
		"Tài xế xe siêu trường"
	]:
		activity = "Vận chuyển hàng hóa theo lệnh điều phối và hạng bằng lái"
		icon = "🚛"
		destination = "logistics_depot"
		pose = "drive"
	elif job_role == "Điều phối viên logistics":
		activity = "Lập chuyến, ghép tải và theo dõi bàn giao hàng"
		icon = "📦"
		destination = "logistics_depot"
		pose = "work"
	elif job_role == "Quản lý đội xe":
		activity = "Điều hành công ty vận tải và năng lực đội xe"
		icon = "🏢"
		destination = "logistics_depot"
		pose = "work"
	elif job_role == "Thợ máy xe tải":
		activity = "Kiểm tra và bảo dưỡng xe tải trước ca vận chuyển"
		icon = "🔧"
		destination = "logistics_depot"
		pose = "work"
	elif is_church_servant and servant_type == "FULL_TIME":
		activity = "Phục vụ cộng đồng tại Mega Office"
		icon = "🤝"
		destination = "mega_office"
		pose = "work"
	elif job_role == "Học sinh" or job_role == "Sinh viên":
		activity = "Học tập tại trường"
		icon = "📚"
		destination = "school"
		pose = "sit"
	else:
		activity = "Làm việc: " + job_role
		icon = "🔨"
		destination = _destination_for_workplace(workplace_id)
		pose = "work"

	return {
		"slot": slot,
		"slot_name": get_time_slot_name(slot),
		"slot_icon": icon,
		"activity": activity,
		"destination": destination,
		"pose": pose,
		"is_on_duty": pose == "work" or pose == "drive"
	}

static func _destination_for_workplace(workplace_id: String) -> String:
	match workplace_id:
		"CAPITAL_FARM_PLOTS":
			return "farm"
		"CAPITAL_BUS_DEPOT", "CAPITAL_TRAM_DEPOT":
			return "transit"
		"CAPITAL_SCHOOL":
			return "school"
		"CAPITAL_LOGISTICS_DEPOT":
			return "logistics_depot"
		"CAPITAL_MEGA_OFFICE", "CAPITAL_CIVIC_CENTER":
			return "mega_office"
		_:
			return "work"

# Tổng quan lịch trình theo Huyện cho Tablet Civic OS
static func get_district_live_status(hour: int, minute: int, day_index: int) -> Array[Dictionary]:
	var slot = get_time_slot(hour, minute)
	var is_liturgy = (day_index == 2 or day_index == 6) and (slot == TimeSlot.NOON_LITURGY_MEAL)

	return [
		{
			"district": "🏛️ Thủ Phủ Đỉnh Vát (+600m)",
			"activity": "Thánh Lễ 15.000 Chỗ & Tiệc Agape" if is_liturgy else (
				"Dịch Vụ Công Một Cửa & Học Viện Bách Khoa" if (slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK) else (
				"Dạo Phố Đi Bộ & Cloud Cafe Ngắm Biển Mây" if slot == TimeSlot.EVENING_SUNSET else (
				"Tập Thể Dục & Điểm Tâm Bác Nam" if slot == TimeSlot.MORNING_DAWN else "Đô Thị Lên Đèn Lồng & Nghỉ Đêm"))),
			"lead_npc": "Thị Trưởng & Người Chăn Chiên",
			"traffic_mode": "Xe Tram Vành Đai 1 & Phố Đi Bộ",
			"status_badge": "🟢 Hoạt Động Cao Độ" if (slot == TimeSlot.MORNING_WORK or slot == TimeSlot.NOON_LITURGY_MEAL) else "🟡 Thư Giãn"
		},
		{
			"district": "🌾 Huyện Đông (Nông Trang 10km)",
			"activity": "Tạ Ơn Mùa Màng & Bữa Ăn Thôn Dã" if is_liturgy else (
				"Thu Hoạch Lúa Mạch & Xay Bột Cối Xay Gió" if (slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK) else (
				"Hóng Gió Đụn Rơm Ráng Chiều" if slot == TimeSlot.EVENING_SUNSET else (
				"Thăm Đồng Sương Sớm" if slot == TimeSlot.MORNING_DAWN else "Nghỉ Ngơi Trong Grand Barn"))),
			"lead_npc": "Bác Hai (Trưởng Thôn Nông Trang)",
			"traffic_mode": "Xe Buggy Điện & Ray Tram Vành Đai 2",
			"status_badge": "🟢 Bội Thu Lúa Mạch"
		},
		{
			"district": "⚙️ Huyện Tây (Kỹ Nghệ Gió 10km)",
			"activity": "Thánh Lễ Tòa Vệ Tinh Kỹ Nghệ" if is_liturgy else (
				"Bảo Trì Tuabin Gió & Tích Nạp Pin Mặt Trời" if (slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK) else (
				"Ngắm Thung Lũng Quạt Gió Ráng Chiều" if slot == TimeSlot.EVENING_SUNSET else (
				"Đo Đạc Vận Tốc Gió Sớm" if slot == TimeSlot.MORNING_DAWN else "Hệ Thống Tự Động Trực Đêm"))),
			"lead_npc": "Kỹ Sư Khoa (Trưởng Trạm Năng Lượng)",
			"traffic_mode": "Xe Tự Hành Kỹ Nghệ & Lưới Điện 100%",
			"status_badge": "🟢 Năng Lượng 100%"
		},
		{
			"district": "🌲 Huyện Bắc (Đại Ngàn & Onsen 10km)",
			"activity": "Thánh Lễ Rừng Già & Ngâm Chân Onsen" if is_liturgy else (
				"Đun Nước Suối Khoáng & Hái Trà Tuyết Sơn" if (slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK) else (
				"Thắp Đèn Lồng Onsen Đón Khách Dạo Mát" if slot == TimeSlot.EVENING_SUNSET else (
				"Tuần Rừng Thông Sương Mai" if slot == TimeSlot.MORNING_DAWN else "Chòi Gỗ Hương Tuyết Tùng"))),
			"lead_npc": "Thợ Rừng Lâm (Kiểm Lâm & Onsen)",
			"traffic_mode": "Đường Mòn Sinh Thái & Cáp Treo Rừng",
			"status_badge": "🟢 Onsen 42°C Lý Tưởng"
		},
		{
			"district": "⚓ Huyện Nam (Cảng Hòa Bình 20km)",
			"activity": "Thánh Lễ Thủy Thủ & Tiệc Hải Sản" if is_liturgy else (
				"Đón Tàu Cá Cập Cầu Cảng & Chợ Phiên Bazaar" if (slot == TimeSlot.MORNING_WORK or slot == TimeSlot.AFTERNOON_WORK) else (
				"Bật Đèn Hải Đăng 26m & Thổi Kèn Ốc Biển" if slot == TimeSlot.EVENING_SUNSET else (
				"Kéo Cờ Cảng Sớm" if slot == TimeSlot.MORNING_DAWN else "Cabin Tàu Hải Đăng Ấm Cúng"))),
			"lead_npc": "Thuyền Trưởng Hải (Cảng Trưởng)",
			"traffic_mode": "Tàu Thủy Biển Mây & Đường Đèo Nam",
			"status_badge": "🟢 Cảng Thông Suốt"
		}
	]
