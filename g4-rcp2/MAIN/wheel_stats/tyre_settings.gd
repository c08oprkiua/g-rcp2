@tool
extends Resource
##A [Resource] for tyre settings.
class_name ViVeTyreSettings

##Grip and traction amplification.
@export var GripInfluence:float = 1.0:
	set(new_influence):
		GripInfluence = new_influence
		emit_changed()
##Width of the tyre, in millimeters.
@export_range(0, 999999) var Width_mm:int = 185:
	set(new_size):
		Width_mm = new_size
		static_wheel_stiffness = get_stiffness()
		size = get_size()
		emit_changed()
##Aspect ratios are delivered in percentages. 
##Tire makers calculate the aspect ratio by dividing a tire's height off the rim by its width. 
##If a tire has an aspect ratio of 70, it means the tire's height is 70 percent of its width.
@export_range(0.0, 100.0) var Aspect_Ratio:float = 60.0:
	set(new_ratio):
		Aspect_Ratio = new_ratio
		static_wheel_stiffness = get_stiffness()
		size = get_size()
		emit_changed()
##Rim size, in inches(?).
@export_range(0, 99999999) var Rim_Size_in:int = 14:
	set(new_size):
		Rim_Size_in = new_size
		size = get_size()
		emit_changed()
##Air pressure of the tire, in PSI (hypothetical).
@export var AirPressure:float = 30.0:
	set(new_pressure):
		AirPressure = new_pressure
		emit_changed()
@export_group("Model")
##The mesh of the tyre associated with these settings.
@export var TyreMesh:Mesh = null
##The default [Transform3D] of the tyre mesh.
@export_storage var TyreMeshTransform:Transform3D = Transform3D()
@export var TyreMeshPosition:Vector3:
	get():
		return TyreMeshTransform.origin
	set(new_pos):
		TyreMeshTransform.origin = new_pos

##The stiffness, pre-calculated for faster retrieval
var static_wheel_stiffness:float
##The size, pre-calculated for faster retrieval
var size:float

func _init() -> void:
	static_wheel_stiffness = get_stiffness()
	size = get_size()

##Get the size of the tyre.
func get_size() -> float:
	#likely some conversion multiplier between meters and ViVe units
	const magic_number_d:float = 0.003269
	#1 inch is 25.4 millimeters
	const inch_to_millimeters:float = 25.4
	#return ((Width_mm * ((Aspect_Ratio * 2.0) * 0.01) + Rim_Size_in * inch_to_millimeters) * magic_number_d) * 0.5
	return ((Width_mm * (Aspect_Ratio * 0.02) + Rim_Size_in * inch_to_millimeters) * magic_number_d) * 0.5

##Get the stiffness of the tyre.
func get_stiffness() -> float:
	#var calc_2:float = (Width_mm * 3) / (Aspect_Ratio * 2)
	const magic_number:float = 1.5
	return Width_mm / (Aspect_Ratio / magic_number)
