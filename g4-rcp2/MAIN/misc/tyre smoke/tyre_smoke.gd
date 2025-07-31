extends Node3D
class_name ViVeTyreSmoke

@export var dirt_type:bool = false

@onready var velo1:Marker3D = get_node("../../../velocity")
@onready var velo2:Marker3D = get_node("../../../velocity2")
@onready var wheel_self:ViVeWheel = get_node("../../..")

@onready var static_particles:Node3D = $"static"
@onready var static_1:CPUParticles3D = $"static/lvl1"
@onready var static_2:CPUParticles3D = $"static/lvl2"
@onready var static_3:CPUParticles3D = $"static/lvl3"

@onready var revolve_l:Node3D = $revolvel
@onready var revolve_l_1:CPUParticles3D = $revolvel/lvl1
@onready var revolve_l_2:CPUParticles3D = $revolvel/lvl2
@onready var revolve_l_3:CPUParticles3D = $revolvel/lvl3

@onready var revolve_r:Node3D = $revolver
@onready var revolve_r_1:CPUParticles3D = $revolvel/lvl1
@onready var revolve_r_2:CPUParticles3D = $revolver/lvl2
@onready var revolve_r_3:CPUParticles3D = $revolver/lvl3

var tyre_width:float

const magic_number_1:float = 0.0030592

func _ready() -> void:
	tyre_width = wheel_self.tire_settings.Width_mm

func _physics_process(_delta:float) -> void:
	visible = misc_graphics_settings.smoke
	if visible:
		run_smoke()

func run_smoke() -> void:
	var velo1_v:Vector3 = wheel_self.velocity
	
	revolve_l.position.x = float(tyre_width) * magic_number_1 / 2
	revolve_r.position.x = - float(tyre_width) * magic_number_1 / 2
	
	static_particles.global_rotation = velo1.global_rotation
	var direction:Vector3 = velo1_v * 0.75
	
	#the range of spin, below
	var spin_range:float = minf(absf(wheel_self.wv), 10.0)
	#how much the effect will be rotationally offset
	var spin:float = clampf(wheel_self.slip_perc.y, -spin_range, spin_range)
	
	direction.z += spin
	
	for i:CPUParticles3D in static_particles.get_children():
		i.direction = direction
		i.initial_velocity_min = direction.length()
		i.initial_velocity_max = direction.length()
		i.position.y = -wheel_self.w_size
		i.emitting = false
	
	for revolve:Node3D in [revolve_l, revolve_r]:
		for i:CPUParticles3D in revolve.get_children():
			if wheel_self.wv > 0:
				i.orbit_velocity_max = 1.0
				i.orbit_velocity_min = 1.0
			else:
				i.orbit_velocity_max = -1.0
				i.orbit_velocity_min = -1.0
			i.emitting = false
	
	var should_emit:bool = (absf(wheel_self.wv * wheel_self.w_size) > velo1_v.length() + 10.0)
	
	if wheel_self.is_colliding():
		if dirt_type:
			if wheel_self.surface_vars.ground_dirt:
				if velo1_v.length() > 20.0:
					static_1.emitting = true
					if should_emit:
						revolve_l_1.emitting = true
						revolve_r_1.emitting = true
				if wheel_self.slip_perc2 > 1.0:
					if wheel_self.slip_perc.length() > 80.0:
						static_3.emitting = true
						if should_emit:
							revolve_l_3.emitting = true
							revolve_r_3.emitting = true
					elif wheel_self.slip_perc.length() > 40.0:
						static_2.emitting = true
						if should_emit:
							revolve_l_2.emitting = true
							revolve_r_2.emitting = true
		else:
			if not wheel_self.surface_vars.ground_dirt:
				if wheel_self.slip_perc2 > 1.0:
					if wheel_self.slip_perc.length() > 80.0:
						static_3.emitting = true
						if should_emit:
							revolve_l_3.emitting = true
							revolve_r_3.emitting = true
					elif wheel_self.slip_perc.length() > 40.0:
						static_2.emitting = true
						if should_emit:
							revolve_l_2.emitting = true
							revolve_r_2.emitting = true
					elif wheel_self.slip_perc.length() > 20.0:
						static_1.emitting = true
						if should_emit:
							revolve_l_1.emitting = true
							revolve_r_1.emitting = true
