@tool
extends RayCast3D
##A class representing the wheel of a [ViVeCar].
##Each wheel independently calculates its suspension and other values every physics process frame.
class_name ViVeWheel

##Allows this wheel to steer.
@export var Steer:bool = true
@export_group("Linked Wheels")
##Finds a wheel to correct itself to another, in favour of differential mechanics. 
##Both wheels need to have their properties proposed to each other.
@export var Differed_Wheel_Path:NodePath = ""
##Connects a sway bar to the opposing axle.
##Both wheels should have their properties proposed to each other.
@export var SwayBarConnection:NodePath = ""
##This is something to do with axle positioning.
@export var Solidify_Axles:NodePath = NodePath()
@export_group("")
@export_group("Debug", "debug_")
##The stretching magnitude for the debug axes.
@export var debug_stretch_magnitude:float = 0.5
##The material for the debug axes.
@export var debug_material:Material = StandardMaterial3D.new()
##The default scale for the debug axes.
@export var debug_default_scale:Vector3 = Vector3(0.02, 0.02, 0.02)

##Power Bias (when driven).
@export var W_PowerBias:float = 1.0
##The [ViVeTyreSettings] for this wheel.
@export var tire_settings:ViVeTyreSettings = ViVeTyreSettings.new():
	set(new_settings):
		if tire_settings.is_connected(&"changed", set_physical_stats):
			tire_settings.disconnect(&"changed", set_physical_stats)
		tire_settings = new_settings
		tire_settings.connect(&"changed", set_physical_stats)
		set_physical_stats()
##The [TyreCompoundSettings] for this wheel.
@export var compound_settings:TyreCompoundSettings = TyreCompoundSettings.new():
	set(new_settings):
		if compound_settings.is_connected(&"changed", set_physical_stats):
			compound_settings.disconnect(&"changed", set_physical_stats)
		compound_settings = new_settings
		compound_settings.connect(&"changed", set_physical_stats)
		set_physical_stats()
##Represents information about the axle the [ViVeWheel] is attached to in the car.
@export var axle_settings:ViVeWheelAxle = ViVeWheelAxle.new()
##The wheel suspension values for this [ViVeWheel].
@export var suspension:ViVeWheelSuspension = ViVeWheelSuspension.new():
	set(new_suspension):
		suspension = new_suspension
		suspension.parent_wheel = self
		target_position.y = new_suspension.RestPosition

@export_group("Alignment")
##Camber angle, in degrees.
@export var Camber:float = 0.0
##Caster angle, in degrees.
@export var Caster:float = 0.0
##Toe-in Angle.
@export var Toe:float = 0.0:
	set(new_angle):
		Toe = new_angle
		relative_toe = new_angle * signf(position.x)

@export_group("Braking and Handbraking")
##Brake torque. This is the multiplier of force put into slowing down the wheel when braking.
##This should be adjusted accordingly to account for the weight of the wheel.
@export var B_Torque:float = 15.0
##This is a multiplier that makes the wheel more/less sensitive to the brake.
##a value over 1 increases sensitivity, and a value lower than 1 makes it fractionally as sensitive.
@export var B_Bias:float = 1.0
##Leave this at 1.0 unless you have a heavy vehicle with large wheels, set it higher depending on how big it is.
@export var B_Saturation:float = 1.0
##This is a multiplier that makes the wheel more/less sensitive to the handbrake.
##a value over 1 increases sensitivity, and a value lower than 1 makes it fractionally as sensitive.
@export var HB_Bias:float = 0.0

@export_group("Extras")
##Allows the Anti-lock Braking System to monitor this wheel.
@export var ContactABS:bool = true

@export var ESP_Role:String = ""
##@experimental
####Allows the BTCS to monitor this wheel.
@export var ContactBTCS:bool = false
##@experimental
####Allows the TTCS to monitor this wheel.
@export var ContactTTCS:bool = false

##The parent [ViVeCar]
@onready var car:ViVeCar = get_parent()
##The base node for debugging geometry.
#@onready var n_geometry:MeshInstance3D = $"geometry"
var n_geometry:MeshInstance3D = MeshInstance3D.new()
var n_compress:MeshInstance3D = MeshInstance3D.new()
var n_lateral:MeshInstance3D = MeshInstance3D.new()
var n_longi:MeshInstance3D = MeshInstance3D.new()


@onready var velo_1:Marker3D = $"velocity"
var p_velo_1:Vector3
@onready var velo_2:Marker3D = $"velocity2"
var p_velo_2:Vector3
@onready var velo_1_step:Marker3D = $"velocity/step"
var p_velo_1_step:Vector3
@onready var velo_2_step:Marker3D = $"velocity2/step"

@onready var anim:Marker3D = $"animation"

@onready var anim_camber:Marker3D = $"animation/camber"

@onready var anim_camber_wheel:Marker3D = $"animation/camber/wheel"
##The paired wheel for differed calculations
@onready var differed_wheel_node:ViVeWheel = null
##The paired wheel for sway bar calculations
@onready var sway_bar_wheel:ViVeWheel = null
##The paired wheel node for axle position syncing.
@onready var solidify_axles_wheel:ViVeWheel = null

const rigidity:float = 0.67
const rigidity_percent:float = 1.0 - rigidity
#I don't know what this is. Any ideas are welcome!
const magic_number_a:float = 1.15296

##This appears to be for some sort of conversion between radians and degrees.
const conversion_1: float = 90.0
##This is used to get around several "divide by 0" errors in code
const div_by_0_fix:float = 1.0

##The expected variable name for the ViVeSurfaceVariables variable in 
##whatever surface this wheel comes into contact with.
const external_ground_vars:StringName = &"ground_vars"

#identifiers for the performance singleton
const perf_grip:StringName = &"Grip"
const perf_wv:StringName = &"Wheel Spin Velocity"
const perf_suspension:StringName = &"Suspension Force"
const perf_wheelpower:StringName = &"Wheel Power"

#These are all values that usually don't need to be calculated repeatedly

##This is a multiplier so that values can flip to match the side of the car the wheel is on.
var car_side:float = signf(position.x)
##This is Toe * car_side
var relative_toe:float = 0.0
##Wheel size.
var w_size:float = 1.0
##Size read of the wheel. This is w_size but capped to 1.0 or higher.
var w_size_read:float = 1.0
##Weight of the wheel. This is w_size squared.
var w_weight:float = 0.0
##Weight read of the wheel. This is w_weight but capped to 1.0 or higher.
var w_weight_read:float = 0.0
##Maximum grip of the tyre.
var tyre_maxgrip:float = 0.0
##Cached value of "physics/common/physics_ticks_per_second", for compensating for varying physics ticks.
var physics_tick:float = 60.0
##The limited-slip-differential tolerance(?).
##This is computed using some magic numbers (related to rev speed?) and ClutchGrip.
var differential_wheel_velocity_limit:float = 0.0
##The name of the wheel in the Performance singleton
var wheel_name:StringName

#values that are used and changed repeatedly at runtime

##This is the result of the fastest wheel's raw wheel velocity, 
##given the current drivetrain RPM, being distributed to this 
##wheel's raw wheel velocity, also given the current drivetrain RPM.
var differential_distributed_wv:float = 0.0
##Velocity of the wheel(?)
var wv:float = 0.0
##Velocity of the wheel differed(?)
var wv_diff:float = 0.0
##This is related to the runtime computed stiffness of the tyre.
##Appears to be constant, so possibly not fully implemented?
var effectiveness:float = 0.0
##Only ever set in suspension calculation.
##It's in radians.
var angle:float = 0.0
##Related to the differential wheel
var differed_wheel_lock:float = 0.0
##Absolute velocity of the wheel(?)
var absolute_wv:float = 0.0
##[wv] from the last frame.
var output_wv:float = 0.0

##Related to the effect of differentials.
var offset:float = 0.0
##If this wheel is a driving wheel (as dictated by the parent [ViVeCar], this value gets set to [W_PowerBias] by the parent [ViVeCar].
##Otherwise, it stays at 0.
var live_power_bias:float = 0.0
##Seems tied to [wv]
var wheelpower:float = 0.0
##This is set to the absolute value of [wheelpower] after braking calculations are applied, and is used in differentials.
var global_abs_wheelpower:float = 0.0
##This is the grip of the wheel on the ground, based on surface variables and suspension.
var grip:float = 0.0
##Set in SwayBar calculations using [suspension_compression], and is used in calculating some values for suspension().
##This value is clamped between -1 and 1
var sway_bar_compression_offset:float = 0.0
##Some sort of compression factor, set during suspension() and used in sway bar calculations.
var suspension_compression:float = 0.0
##The Camber with Caster values properly factored into it.
##This is in degrees.
var camber_w_caster:float = 0.0
##Appears to be a counterbalance angle to camber_w_caster.
##This is in degrees.
var camber_axle_offset:float = 0.0


##The volume of the wheel rolling/skidding.
var roll_vol:float = 0.0
##The skidding volume.
##Specifically related to the volume of peel2.
var skid_volume:float = 0.0

var velocity:Vector3 = Vector3.ZERO
##Used in calculating various tyre deformation variables
var velocity2:Vector3 = Vector3.ZERO
##This is compensation for the forward velocity/grip on a slope being affected by the [tyre_stiffness].
var slope_force:float = 0.0
##The axle position (of the geometry).
##This is exposed for use in differed calculations, and is updated right before said calculations.
var axle_position:float = 0.0
##This is the effective bumpiness of the ground, given the car's speed.
##This randomly fluctuates between 0 and 1.
var ground_bumpiness:float = 0.0
##Used to fluctuate [ground_bumpiness].
var ground_bumping_up:bool = false

##The [ViVeSurfaceVars] recieved from the ground, with certain values edited at
##the time of recieving.
var surface_vars:ViVeSurfaceVars = ViVeSurfaceVars.new()
##The last collision point reported by the underlying RayCast3D
var hitposition:Vector3 = Vector3.ZERO

var tyre_stiffness:float

##This is [tyre_stiffness] from the previous frame.
var cache_tyrestiffness:float = 0.0
##This is a cached value of the vertical friction applied on the tyre.
var cache_friction_action:float = 0.0
##The directional force of the tire. 
##This is the "sum" that is used to apply physics impulses to the car.
var directional_force:Vector3 = Vector3.ZERO
##Used in calculating tyre smoke and tyre tracks
var slip_perc:Vector2 = Vector2.ZERO
##Used in calculating tyre smoke.
var slip_perc2:float = 0.0
##Has a direct play in steering input calculations.
##Also is what the vertical bars on the wheels in the VGS are.
var slip_percent_pre:float = 0.0

var velocity_last:Vector3 = Vector3.ZERO

var velocity2_last:Vector3 = Vector3.ZERO
##Set to true when the wheel registers itself to the performance singleton
var debug_registered:bool = false

var elasticity:float

var damping_compress:float

var damping_rebound:float

func _ready() -> void:
	if Engine.is_editor_hint():
		pass
	else:
		generate_tree()
	
	physics_tick = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0)
	
	if Differed_Wheel_Path:
		differed_wheel_node = car.get_node(Differed_Wheel_Path)
		if not is_instance_valid(differed_wheel_node):
			push_error("Wheel ", self.name,": Differed Wheel set, but could not be found")
	
	if SwayBarConnection:
		sway_bar_wheel = car.get_node(SwayBarConnection)
		if not is_instance_valid(sway_bar_wheel):
			push_error("Wheel ", self.name,": SwayBarConnection set, but could not be found")
	
	if Solidify_Axles:
		solidify_axles_wheel = car.get_node(Solidify_Axles)
		if not is_instance_valid(solidify_axles_wheel):
			push_error("Wheel ", self.name,": Solidify Axles set, but could not be found")
	
	set_physical_stats()

func generate_tree() -> void:
	#geometry test mesh + material
	if not is_instance_valid(debug_material):
		debug_material = StandardMaterial3D.new()
		debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
		debug_material.disable_ambient_light = true
	
	var geometry_mesh:BoxMesh = BoxMesh.new()
	geometry_mesh.material = debug_material
	
	#geometry
	n_geometry.mesh = PointMesh.new()
	n_geometry.material_override = debug_material
	add_child(n_geometry)
	
	n_compress.mesh = geometry_mesh
	n_compress.scale = debug_default_scale
	n_geometry.add_child(n_compress)
	n_lateral.mesh = geometry_mesh
	n_lateral.scale = debug_default_scale
	n_geometry.add_child(n_lateral)
	n_longi.mesh = geometry_mesh
	n_longi.scale = debug_default_scale
	n_geometry.add_child(n_longi)
	#animation
	
	
	pass

func register_debug() -> void:
	if debug_registered or Engine.is_editor_hint():
		return
	
	wheel_name = car.car_name + &": " + name
	
	Performance.add_custom_monitor(wheel_name + &"/" + perf_grip, get, ["grip"])
	#Performance.add_custom_monitor(wheel_name + &"/" + perf_suspension, suspension)
	Performance.add_custom_monitor(wheel_name + &"/" + perf_wv, get, ["wv"])
	Performance.add_custom_monitor(wheel_name + &"/" + perf_wheelpower, get, ["wheelpower"])
	
	debug_registered = true

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	Performance.remove_custom_monitor(wheel_name + &"/" + perf_grip)
	#Performance.remove_custom_monitor(wheel_name + &"/" + perf_suspension)
	Performance.remove_custom_monitor(wheel_name + &"/" + perf_wv)
	Performance.remove_custom_monitor(wheel_name + &"/" + perf_wheelpower)

##Apply power. 
func power() -> void:
	differential_distributed_wv *= car.clutch_engage_squared / car.clutch_plate_slip
	
	var limited_slip_differential_wv:float = clampf(differential_distributed_wv, -differential_wheel_velocity_limit, differential_wheel_velocity_limit)
	
	car.power_bias_total += live_power_bias
	car.overall_power_grip += grip * live_power_bias
	
	if car.previous_power_bias_total > 0.0:
		if car.rpm > car.DeadRPM:
			wheelpower -= (((limited_slip_differential_wv / car.driveshaft_weight_resistance) / (car.previous_power_bias_total / 2.5)) * live_power_bias) / w_weight
		car.drive_wheel_diff_power += (((limited_slip_differential_wv * 10.0) / car.previous_power_bias_total) * live_power_bias)

##This runs computations for differentials between two wheels.
func differentials() -> void:
	if car.differential_lock_percent > 0.0 and is_instance_valid(differed_wheel_node):
		var diff_lock_influence_amplified:float = (car.differential_lock_percent * 16.0)
		
		differed_wheel_lock = differed_wheel_node.global_abs_wheelpower / diff_lock_influence_amplified + div_by_0_fix
		
		absolute_wv = output_wv + (offset * differed_wheel_lock)
		
		var distance_2:float = absf(absolute_wv - differed_wheel_node.output_wv) / diff_lock_influence_amplified
		distance_2 += differed_wheel_node.global_abs_wheelpower / diff_lock_influence_amplified
		
		distance_2 = maxf(distance_2, differed_wheel_lock)
		
		distance_2 += 1.0 / cache_tyrestiffness
		if distance_2 > 0.0:
			wheelpower += -((output_wv - differed_wheel_node.output_wv) / distance_2)

##Run logic for the Sway Bar connection, if one is properly set.
func sway_bar() -> void:
	if is_instance_valid(sway_bar_wheel):
		sway_bar_compression_offset = clampf(suspension_compression - sway_bar_wheel.suspension_compression, -1.0, 1.0)

##Factor in the effects of braking and/or handbraking to the velocity of the wheel.
func apply_braking() -> void:
	var total_brake_effect:float = minf(car.brake_line * B_Bias + car.handbrake_pull * HB_Bias, 1.0)
	#Get brake power by multiplying the total_brake_effect factor by the brake force, 
	#and dividing that result by the weight of the wheel
	var brake_power:float = (B_Torque * total_brake_effect) / w_weight_read
	
	if car.actual_gear != 0 and car.previous_power_bias_total > 0.0:
		brake_power += ((car.stalled * (live_power_bias / car.driveshaft_weight_resistance)) * car.clutch_engage_percent) * (((5.0 / car.RevSpeed) / (car.previous_power_bias_total / 2.5)) / w_weight_read)
	if brake_power > 0.0:
		if not is_zero_approx(absolute_wv):
			var distanced:float = absf(absolute_wv) / brake_power
			distanced -= car.brake_line
			distanced = maxf(distanced, differed_wheel_lock * (w_size_read / B_Saturation))
			wheelpower -= absolute_wv / distanced
		else:
			wheelpower -= absolute_wv
	
	global_abs_wheelpower = absf(wheelpower)

func _physics_process(_delta:float) -> void:
	if Engine.is_editor_hint():
		return
	
	var last_position:Vector3 = position
	
	#Do steer rotation things if this wheel is a steering wheel
	#if Steer and absf(car.effective_steer) > 0:
	if Steer and not is_zero_approx(car.effective_steer):
		var last_global_position:Vector3 = global_position
		
		#look_at_from_position(position, Vector3(car.steer_to_direction, rotation.y, car.AckermannPoint), Vector3.UP)
		look_at_from_position(position, Vector3(car.steer_to_direction, 0.0, car.AckermannPoint), Vector3.UP)
		global_position = last_global_position
		
		rotate_y(-(deg_to_rad(90) * signf(car.effective_steer)))
		
		#Using local rotation for literal_steer_rotation *could* be used for some sort of steer centering assist
		var literal_steer_rotation:float = wrapf(global_rotation.y, -3.0, 3.0)
		
		#calculations for steering_angles
		look_at_from_position(position, Vector3(car.Steer_Radius, 0.0, car.AckermannPoint), Vector3.UP)
		global_position = last_global_position
		
		rotate_y(deg_to_rad(90.0))
		
		car.steering_angles.append(global_rotation_degrees.y)
		
		rotation = Vector3.ZERO
		
		rotation.y = literal_steer_rotation
		
		rotation_degrees.y += relative_toe
	else:
		rotation_degrees = Vector3(0.0, relative_toe, 0.0)
	
	position = last_position
	
	camber_w_caster = Camber + Caster * rotation.y * car_side
	
	directional_force = Vector3.ZERO
	
	#You don't [i]really[/i] need these to be repeatedly calculated under 
	#normal circumstances (see the desc of set_physical_stats), so it's
	#disabled unless debug is on.
	if car.Debug_Mode:
		set_physical_stats()
	
	#Sync positions. Without this, the car is very bouncy.
	velo_1.position = Vector3.ZERO
	velo_2.global_position = n_geometry.global_position
	
	velo_1_step.global_position = velocity_last
	velo_2_step.global_position = velocity2_last
	
	velocity_last = velo_1.global_position
	velocity2_last = velo_2.global_position
	
	#60 here is likely the physics tick per second
	
	velocity = -velo_1_step.position * 60.0
	velocity2 = -velo_2_step.position * 60.0
	
	velo_1.rotation = Vector3.ZERO
	velo_2.rotation = Vector3.ZERO
	
	# VARS
	
	elasticity = suspension.get_elasticity(sway_bar_compression_offset)
	damping_compress = suspension.get_compression_dampening(sway_bar_compression_offset)
	damping_rebound = suspension.get_rebound_dampening(sway_bar_compression_offset)
	
	sway_bar()
	
	var surface_deform_factor:float = (Vector2(velocity.x, velocity.z).length() / 50.0 + 0.5) * compound_settings.DeformFactor
	
	surface_deform_factor /= surface_vars.ground_stiffness + surface_vars.fore_stiffness * compound_settings.ForeStiffness
	surface_deform_factor = maxf(surface_deform_factor, 1.0)
	
	tyre_stiffness = ((tire_settings.static_wheel_stiffness / surface_deform_factor) * ((tire_settings.AirPressure / 30.0) * 0.1 + 0.9) ) * compound_settings.Stiffness + effectiveness
	
	tyre_stiffness = maxf(tyre_stiffness, 1.0)
	
	cache_tyrestiffness = tyre_stiffness
	
	absolute_wv = output_wv + (offset * differed_wheel_lock) - slope_force * magic_number_a
	
	wheelpower = 0.0
	
	apply_braking()
	
	#moving this check into this function (should perform better)
	if not is_zero_approx(live_power_bias):
		power()
	differentials()
	
	differed_wheel_lock = 1.0
	offset = 0.0
	
	slip_perc = Vector2.ZERO
	slip_perc2 = 0.0
	
	# WHEEL
	if is_colliding():
		#Apply ground surface variables
		var collider:Node3D = get_collider()
		if external_ground_vars in collider:
			var extern_surf:ViVeSurfaceVars = collider.get(external_ground_vars)
			surface_vars = extern_surf
			surface_vars.drag *= pow(compound_settings.GroundDragAffection, 2.0)
			surface_vars.ground_builduprate *= compound_settings.BuildupAffection
			surface_vars.ground_bump_frequency_random += 1.0
		
		if ground_bumping_up:
			ground_bumpiness -= surface_vars.get_random_bump() * (velocity.length() * 0.001)
			if ground_bumpiness < 0.0:
				ground_bumpiness = 0.0
				ground_bumping_up = false
		else:
			ground_bumpiness += surface_vars.get_random_bump() * (velocity.length() * 0.001)
			if ground_bumpiness > 1.0:
				ground_bumpiness = 1.0
				ground_bumping_up = true
		
		hitposition = get_collision_point()
		directional_force.y = calculate_suspension()
		
		
		#Grip is the result of gravity multiplied by the tyre grip, 
		#times the ground and fore friction times the compound fore friction
		grip = (directional_force.y * tyre_maxgrip) * (surface_vars.ground_friction + surface_vars.fore_friction * compound_settings.ForeFriction)
		
		var wheelpower_increase:float = (wheelpower * (1.0 - (1.0 / tyre_stiffness)))
		
		wv += wheelpower_increase
		var wv_increase:float = wv + wheelpower_increase
		var wheel_dist_y:float = velocity2.z - (wv * w_size)
		var wheel_dist_x:float = velocity2.x
		
		#wheel_dist_y / w_size == (velocity2.z / w_size) - wv
		offset = clampf(wheel_dist_y / w_size, -grip, grip)
		
		var gravity_incline:Vector3 = (n_geometry.global_transform.basis.orthonormalized().transposed() * Vector3.UP)
		
		slope_force = gravity_incline.z * (directional_force.y / tyre_stiffness)
		
		wheel_dist_x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		
		wheel_dist_x *= tyre_stiffness
		wheel_dist_y *= tyre_stiffness
		
		#up until now, the calculations are identical. After here, however,
		#they are different, because wheel calculations mess with wv, which 
		#friction calculations then use the modified value therein
		var force_dist_x:float = wheel_dist_x
		
		wheel_dist_x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		#calculate the grip of the tire
		if grip > 0:
			var wheel_slip:float = Vector2(wheel_dist_x, wheel_dist_y).length() / grip
			
			slip_percent_pre = wheel_slip / tyre_stiffness
			
			wheel_slip /= wheel_slip * surface_vars.ground_builduprate + div_by_0_fix
			wheel_slip -= compound_settings.TractionFactor
			wheel_slip = maxf(wheel_slip, 0.0)
			
			if absf(wheel_dist_y) / (tyre_stiffness / 3.0) > (car.ABS.threshold / grip) * pow(surface_vars.ground_friction, 2.0) and car.ABS.enabled and absf(velocity.z) > car.ABS.speed_pre_active and ContactABS:
				car.abs_pump = car.ABS.pump_time
				if absf(wheel_dist_y) / (tyre_stiffness / 3.0) > (car.ABS.lat_thresh / grip) * pow(surface_vars.ground_friction, 2.0):
					car.abs_pump = car.ABS.lat_pump_time
			
			var wheel_force_x:float = -wheel_dist_x / (wheel_slip + div_by_0_fix)
			var wheel_force_y:float = -wheel_dist_y / (wheel_slip + div_by_0_fix)
			
			var abs_friction_x:float = minf(absf(wheel_force_x), 1.0)
			var abs_friction_y:float = minf(absf(wheel_force_y), 1.0)
			
			var sq_friction_x:float = minf(abs_friction_x * abs_friction_x, 1.0)
			
			wheel_force_x /= sq_friction_x * rigidity + (rigidity_percent)
			wheel_force_y /= abs_friction_y * rigidity + (rigidity_percent)
			
			
			var distyw:float = Vector2(wheel_dist_x, wheel_dist_y).length()
			distyw /= compound_settings.TractionFactor
			distyw = maxf(distyw, grip)
			
			var ok:float = minf(distyw / (tyre_stiffness * grip * w_size), 1.0)
			differed_wheel_lock = minf(ok * w_weight_read, 1.0)
			
			cache_friction_action = wheel_force_y * ok
			
			wv -= cache_friction_action
			wv += (wheelpower * (1.0 / tyre_stiffness))
			
			#Volume calculation?
			var slip_sk:float = Vector2(wheel_dist_x * 2.0, wheel_dist_y).length() / grip
			slip_sk /= wheel_slip * surface_vars.ground_builduprate + div_by_0_fix
			slip_sk -= compound_settings.TractionFactor
			slip_sk = maxf(slip_sk, 0.0)
			
			skid_volume = maxf(slip_sk - tyre_stiffness, 0.0) / 4.0
			roll_vol = velocity.length() * grip
		
		var force_dist_y:float = velocity2.z - (wv * w_size) / (surface_vars.drag + div_by_0_fix)
		
		if is_instance_valid(differed_wheel_node):
			force_dist_y = velocity2.z - ((wv * (1.0 - car.differential_lock_percent) + differed_wheel_node.wv_diff * car.differential_lock_percent) * w_size) / (surface_vars.drag + div_by_0_fix)
		
		slip_perc = Vector2(force_dist_x, force_dist_y)
		
		force_dist_y *= tyre_stiffness
		
		force_dist_x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		if grip > 0.0:
			var force_slip:float = Vector2(force_dist_x, force_dist_y).length() / grip
			
			force_slip /= force_slip * surface_vars.ground_builduprate + div_by_0_fix
			force_slip -= compound_settings.TractionFactor
			force_slip = maxf(force_slip, 0.0)
			
			slip_perc2 = force_slip
			
			var force_x:float = -force_dist_x / (force_slip + div_by_0_fix)
			var force_y:float = -force_dist_y / (force_slip + div_by_0_fix)
			
			var abs_force_x:float= minf(absf(force_x), 1.0)
			var abs_force_y:float= minf(absf(force_y), 1.0)
			
			var sq_force_x:float = minf(abs_force_x * abs_force_x, 1.0)
			
			force_x /= sq_force_x * rigidity + (rigidity_percent)
			force_y /= abs_force_y * rigidity + (rigidity_percent)
			
			directional_force.x = force_x
			directional_force.z = force_y
	else:
		wv += wheelpower
		grip = 0.0
		roll_vol = 0.0
		skid_volume = 0.0
		directional_force.y = 0.0
		slope_force = 0.0
		n_geometry.position = target_position
	
	wv_diff = wv
	output_wv = wv
	
	anim_camber_wheel.rotate_x(deg_to_rad(wv))
	
	n_geometry.position.y += w_size
	
	var inned:float = (absf(camber_axle_offset) + axle_settings.Geometry4) / 90
	inned *= inned - axle_settings.Geometry4 / 90.0
	
	n_geometry.position.x = -inned * position.x
	
	anim_camber.rotation_degrees.z = -(camber_w_caster - camber_axle_offset) * car_side
	anim_camber.rotation.z *= axle_settings.Camber_Gain
	
	axle_position = n_geometry.position.y
	
	if not is_instance_valid(solidify_axles_wheel):
		#The x and y offset of the axle added together.
		var axle_offset:float = (n_geometry.position.y + (absf(target_position.y) - axle_settings.Vertical_Mount)) / (absf(position.x) + axle_settings.Lateral_Mount_Pos + div_by_0_fix)
		axle_offset /= absf(axle_offset) + div_by_0_fix
		camber_axle_offset = (axle_offset * conversion_1) - axle_settings.Geometry4
	else:
		#The x and y offset of the axle added together.
		var axle_offset:float = (n_geometry.position.y - solidify_axles_wheel.axle_position) / (absf(position.x) + div_by_0_fix)
		axle_offset /= absf(axle_offset) + div_by_0_fix
		camber_axle_offset = (axle_offset * conversion_1)
	
	anim.position = n_geometry.position
	
	#apply forces
	var forces:Vector3 = velo_2.global_basis.orthonormalized() * directional_force
	
	car.apply_impulse(forces, hitposition - car.global_transform.origin)
	
	update_geometry() #originally in forces.gd as a child node; child process after parent

func alignAxisToVector(xform:Transform3D, norm:Vector3) -> Transform3D:
	var new_form:Transform3D = xform
	new_form.basis.y = norm
	new_form.basis.x = -new_form.basis.z.cross(norm)
	new_form.basis = new_form.basis.orthonormalized()
	return new_form

#const suspension_args:String = "own,maxcompression,incline_free,incline_impact,rest,elasticity,damping_compress,damping_rebound,linearz,abs_targeted_position,located,hit_located,weight,ground_bumpiness,ground_bump_height"
#const suspension_inputs:String = "self,S_MaxCompression,A_InclineArea,A_ImpactForce,S_RestLength, elasticity,damping_compress,damping_rebound, velocity.y,abs(cast_to.y),global_translation,get_collision_point(),car.mass,ground_bumpiness,ground_bump_height"

##Calculate suspension, which is the y force on the wheel.
func calculate_suspension() -> float:
	var abs_targeted_position:float = absf(target_position.y)
	
	var ground_bump_scale:float = (ground_bumpiness * surface_vars.ground_bump_height)
	
	n_geometry.global_position = get_collision_point()
	n_geometry.position.y -= ground_bump_scale
	#set the n_geometry y position to either wherever it is, or the absolute target position, 
	#whichever is higher up.
	n_geometry.position.y = maxf(n_geometry.position.y, -abs_targeted_position)
	
	velo_1.global_transform = alignAxisToVector(velo_1.global_transform, get_collision_normal())
	velo_2.global_transform = alignAxisToVector(velo_2.global_transform, get_collision_normal())
	
	#This is reminiscent of the calculation for anim camber
	angle = (n_geometry.rotation_degrees.z - ((-camber_w_caster - camber_axle_offset) * car_side) * axle_settings.Camber_Gain) / conversion_1
	
	#The incline of the slope
	var slope_incline:float = (get_collision_normal() - (global_transform.basis.orthonormalized() * Vector3.UP)).length()
	
	#Amplify the slope 
	slope_incline /= 1.0 - suspension.InclineArea
	
	slope_incline -= suspension.InclineArea
	#The rebound effect of the wheel being "forced" into the slope
	slope_incline *= suspension.ImpactForce
	
	slope_incline = clampf(slope_incline, 0.0, 1.0)
	
	#this is a multiplier for how much being on a slope effects suspension power
	var slope_reduction_effect:float = 1.0 - slope_incline
	
	n_geometry.position.y = minf(n_geometry.position.y, - abs_targeted_position + suspension.MaxCompression * slope_reduction_effect)
	
	var damp_variant:float = damping_rebound
	
	#linearz is velocity.y
	if velocity.y < 0: #if we are sunken into the ground
		damp_variant = damping_compress
	
	#this sits at around 2.4 to 2.6 on the base car, which is innacurate
	var hit_position:float = (global_position - get_collision_point()).length()
	
	#The raw positional offset of the target position, minus where the wheel is, minus ground bumpiness
	var raw_pos_compress:float = abs_targeted_position - hit_position - ground_bump_scale
	#The raw compression, but with MaxCompression factored in, and ground bumpiness factored out
	var raw_compress_maxed:float =  maxf(raw_pos_compress - (suspension.MaxCompression + ground_bump_scale), 0.0)
	
	var tenth_car_body_weight:float = (car.mass / 10.0)
	
	var overall_spring_force:float = elasticity * slope_reduction_effect + car.mass * slope_incline
	var angled_damper:float = damp_variant * slope_reduction_effect + tenth_car_body_weight * slope_incline
	var suspension_force:float = maxf(raw_pos_compress - suspension.Deadzone, 0.0) * overall_spring_force
	
	if raw_compress_maxed > 0.0:
		suspension_force -= (velocity.y * tenth_car_body_weight)
		suspension_force += raw_compress_maxed * car.mass
	
	suspension_force -= velocity.y * angled_damper
	
	suspension_compression = raw_pos_compress
	
	return maxf(suspension_force, 0.0)

func update_geometry() -> void:
	n_geometry.visible = car.Debug_Mode
	
	n_geometry.rotation = velo_1.rotation
	n_geometry.position = anim.position
	
	n_geometry.position.y -= w_size
	
	if visible:
		n_compress.visible = is_colliding()
		n_longi.visible = is_colliding()
		n_lateral.visible = is_colliding()
		
		#compress.scale = Vector3(0.02, directional_force.y * (debug_stretch_magnitude / 1.0), 0.02)
		n_compress.scale.y = directional_force.y * (debug_stretch_magnitude / 1.0)
		n_compress.position.y = n_compress.scale.y / 2.0
		#longi.scale = Vector3(0.02, 0.02, directional_force.z * (debug_stretch_magnitude / 1.0))
		n_longi.scale.z = directional_force.z * (debug_stretch_magnitude / 1.0)
		n_longi.position.z = n_longi.scale.z / 2.0
		#lateral.scale = Vector3(directional_force.x * (debug_stretch_magnitude / 1.0), 0.02, 0.02)
		n_lateral.scale.x = directional_force.x * (debug_stretch_magnitude / 1.0)
		n_lateral.position.x = n_lateral.scale.x / 2.0

##This will update various stats like [w_size] and [w_weight]. [br]
##Usually, these stats only need to be set once when the car is loaded,
##since [tire_settings] and [compound_settings] (which are used in calculating these values) usually never change at runtime.
##However, if those are being edited in real time, such as in an editor, these stats need to be re-set.
func set_physical_stats() -> void:
	car_side = signf(position.x)
	relative_toe = - (Toe * car_side)
	
	w_size = tire_settings.get_size()
	w_weight = pow(w_size, 2.0)
	
	w_size_read = maxf(w_size, 1.0)
	w_weight_read = maxf(w_weight, 1.0)
	
	tyre_maxgrip = tire_settings.GripInfluence / compound_settings.TractionFactor
	
	if is_instance_valid(car):
		#const magic_number_b:float = 0.1475
		#const magic_number_c:float = 1.3558
		#differential_wheel_velocity_limit = (magic_number_b / magic_number_c) * car.ClutchGrip
		
		const magic_number_d:float = 13.558
		differential_wheel_velocity_limit = (ViVeCar.revspeed_magic_number / magic_number_d) * car.ClutchGrip

func calculate_cache() -> void:
	pass
