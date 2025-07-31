extends HBoxContainer

const file_name_template:String = "mapping_{}.tres"

@onready var prof_name:LineEdit = $"JumpTo/ProfileName"
@onready var preset_list:VBoxContainer = $"PresetSelect/List"

var car:ViVeCar

var user_root:String
var setting_count:int = 0
var saved_mappings:Array[ViVeCarControls]

func setcar() -> void:
	car = weakref(ViVeEnvironment.get_singleton().car).get_ref()
	if not is_instance_valid(car):
		return
	ViVeGUIControlVariable.control_ref = car.car_controls
	prof_name.text = car.car_controls.ControlMapName

func _ready() -> void:
	user_root = ProjectSettings.globalize_path("user://mappings")
	ViVeEnvironment.get_singleton().connect("ready", setup)
	ViVeEnvironment.get_singleton().connect("car_changed", setcar)
	load_preset_list()

func setup() -> void:
	setcar()
	ViVeEnvironment.get_singleton().emit_signal("car_changed")

func load_preset_list() -> void:
	if not DirAccess.dir_exists_absolute(user_root):
		DirAccess.make_dir_absolute(user_root)
	
	if not DirAccess.get_files_at(user_root).is_empty():
		var load_queue:PackedStringArray
		setting_count = 0
		
		for files:String in DirAccess.get_files_at(user_root):
			#check that they're actual tres files
			if files == file_name_template.format(str(setting_count)):
				load_queue.append(files)
				setting_count += 1

func add_preset(mapping:ViVeCarControls) -> void:
	var new_button:Button
	new_button.name = mapping.ControlMapName
	
	preset_list.add_child(new_button)

func load_mapping() -> void:
	pass

func _on_top_pressed() -> void:
	$"Config/List/input_options".grab_focus()

func _on_steer_digital_pressed() -> void:
	$"Config/List/SteerDigital/Label".grab_focus()

func _on_steer_analog_pressed() -> void:
	$"Config/List/SteerAnalog/Label".grab_focus()

func _on_throttle_pressed() -> void:
	$"Config/List/Throttle/Label".grab_focus()

func _on_brake_pressed() -> void:
	$"Config/List/Brake/Label".grab_focus()

func _on_handbrake_pressed() -> void:
	$"Config/List/Handbrake/Label".grab_focus()

func _on_clutch_pressed() -> void:
	$"Config/List/Clutch/Label".grab_focus()

func _on_apply_pressed() -> void:
	car.car_controls = ViVeGUIControlVariable.control_ref

func _on_cancel_pressed() -> void:
	ViVeGUIControlVariable.control_ref = car.car_controls
	ViVeEnvironment.get_singleton().emit_signal("car_changed")

func _on_save_pressed() -> void:
	
	ResourceSaver.save(ViVeGUIControlVariable.control_ref, user_root + file_name_template.format(str(setting_count)))


#these misc options are directly connected up here
func _on_input_options_item_selected(index: int) -> void:
	car.control_type = index

func _on_label_text_changed(new_text: String) -> void:
	ViVeGUIControlVariable.control_ref.ControlMapName = new_text
