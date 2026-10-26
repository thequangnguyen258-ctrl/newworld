class_name CitizenIDModal
extends PanelContainer

# ==============================================================================
# CITIZEN ID MODAL - THẺ CĂN CƯỚC CÔNG DÂN TÂN THẾ GIỚI
# Giao diện Hologram trong suốt hiện đại:
# 1. Chân dung Toon & Quốc huy
# 2. Thông tin sinh trắc, tuổi tác, giới tính, số CCCD
# 3. Nghề nghiệp, chứng chỉ CERT_*, cấp bậc tay nghề
# 4. Hộp thoại tâm sự & các nút tương tác (Thăm hỏi, Học bổng, Đóng)
# ==============================================================================

signal modal_closed

@onready var title_label: Label = $Margin/VBox/Header/TitleLabel
@onready var close_btn: Button = $Margin/VBox/Header/CloseButton

@onready var cccd_label: Label = $Margin/VBox/Grid/CCCDValue
@onready var name_label: Label = $Margin/VBox/Grid/NameValue
@onready var age_label: Label = $Margin/VBox/Grid/AgeValue
@onready var job_label: Label = $Margin/VBox/Grid/JobValue
@onready var cert_label: Label = $Margin/VBox/Grid/CertValue
@onready var skill_label: Label = $Margin/VBox/Grid/SkillValue
@onready var status_label: Label = $Margin/VBox/Grid/StatusValue

@onready var dialogue_box: Label = $Margin/VBox/DialogueContainer/DialogueMargin/DialogueLabel
@onready var encourage_btn: Button = $Margin/VBox/Actions/EncourageButton
@onready var scholarship_btn: Button = $Margin/VBox/Actions/ScholarshipButton
@onready var feedback_label: Label = $Margin/VBox/FeedbackLabel

var current_npc: NPCCharacter

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	if encourage_btn:
		encourage_btn.pressed.connect(_on_encourage_pressed)
	if scholarship_btn:
		scholarship_btn.pressed.connect(_on_scholarship_pressed)

func display_citizen(npc: NPCCharacter) -> void:
	current_npc = npc
	visible = true
	feedback_label.text = ""
	
	var age_str = ""
	match npc.age_group:
		ModularHumanoidBuilder.AgeGroup.CHILD:
			age_str = "%d tuổi • Thiếu nhi hồn nhiên" % npc.age
		ModularHumanoidBuilder.AgeGroup.YOUTH:
			age_str = "%d tuổi • Học viên thanh thiếu niên" % npc.age
		ModularHumanoidBuilder.AgeGroup.ADULT:
			age_str = "%d tuổi • Lao động thanh xuân" % npc.age
		ModularHumanoidBuilder.AgeGroup.ELDER:
			age_str = "%d tuổi • Trưởng lão / Nghệ nhân" % npc.age
			
	name_label.text = npc.citizen_name
	cccd_label.text = npc.cccd_number
	age_label.text = "%s (%s)" % [age_str, npc.gender]
	job_label.text = npc.job_title
	cert_label.text = "Chứng chỉ số: %s" % npc.cert_code
	if skill_label:
		skill_label.text = "Cấp độ tay nghề: Cấp %d / 10" % npc.skill_level
	var act_info = ""
	if "current_activity" in npc and npc.current_activity != "":
		act_info = "\n🕒 Sinh hoạt: %s %s (%s)" % [npc.current_activity_icon, npc.current_activity, npc.current_slot_name]
	status_label.text = "💖 Hòa hợp: %d%% | ⚡ Sinh lực: %d%%%s" % [int(npc.harmony_score), int(npc.vitality), act_info]
	
	dialogue_box.text = "\"%s\"" % npc.dialogue_text
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close_pressed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	modal_closed.emit()

func _on_encourage_pressed() -> void:
	if current_npc:
		current_npc.harmony_score = clampf(current_npc.harmony_score + 5.0, 0.0, 100.0)
		feedback_label.text = "✨ Thị trưởng vừa thăm hỏi động viên! %s rất xúc động và tràn đầy niềm vui!" % current_npc.citizen_name
		status_label.text = "💖 Hòa hợp: %d%% | ⚡ Sinh lực: %d%%" % [int(current_npc.harmony_score), int(current_npc.vitality)]

func _on_scholarship_pressed() -> void:
	if current_npc:
		current_npc.skill_level = mini(current_npc.skill_level + 1, 10)
		feedback_label.text = "🎓 Đã duyệt cấp Học Bổng Học Viện! Tay nghề của %s nâng lên Cấp %d/10!" % [current_npc.citizen_name, current_npc.skill_level]
		skill_label.text = "Cấp độ tay nghề: Cấp %d / 10" % current_npc.skill_level
