extends Control

class_name ViVeVGS

@export var vgs_scale:float = 1.0

@export var MaxG:float = 0.75

@export var gforce:Vector2 = Vector2.ZERO

@onready var wheel:ViVeDebugWheelMonitor = $wheel.duplicate()

var glength:float = 0.0

var appended:Array[ViVeDebugWheelMonitor] = []

func _ready() -> void:
	$wheel.queue_free()

func clear() -> void:
	for wheels:ViVeDebugWheelMonitor in appended:
		wheels.queue_free()
	appended = []

func append_wheel(node:ViVeWheel) -> void:
	var settings:ViVeTyreSettings = node.tire_settings
	var pos:Vector3 = node.position
	
	var w_size:float = settings.get_size()
	var width:float = (settings.Width_mm * 0.003269) / 2.0
	
	var w:ViVeDebugWheelMonitor = wheel.duplicate()
	add_child(w)
	w.pos = - Vector2(pos.x, pos.z) * 2.0
	w.setting = settings
	w.node = node
	
	w.scale.x = (width * 2.0) / (vgs_scale / 2.0)
	w.scale.y = w_size / (vgs_scale / 2.0)
	
	appended.append(w)

func _physics_process(_delta:float) -> void:
	for wheels:ViVeDebugWheelMonitor in appended:
		wheels.update(size, vgs_scale)
	
	var vector_cache:float = gforce.abs().length()
	glength = maxf(vector_cache / vgs_scale - 1.0, 0.0)
	if vector_cache > MaxG:
		$centre/Circle.modulate = Color.KHAKI #Color(1.0, 1.0, 0.5, 1.0)
	else:
		$centre/Circle.modulate = Color.GOLD #Color(1.0, 0.75, 0.0, 1.0)
	
	gforce /= glength + 1.0
	
	$centre.position = size / 2 + gforce * (64.0 / vgs_scale)
	$field.position = size / 2
