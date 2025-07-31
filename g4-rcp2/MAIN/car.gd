@tool
extends RigidBody3D
##A class representing a car in VitaVehicle.
class_name ViVeCar

#These are magic numbers that have been pulled out of the codebase.
#Any guesses or information on what these could actually be would be appreciated!
##Related to turbo.
const turbo_magic_number:float = 0.609
##Related to RevSpeed. 
##According to Jreo, this is "nothing". Just an arbitrary scaler ig.
const revspeed_magic_number:float = 1.475
##Used in torque calculations as a divider value.
const torque_fractional:float = 10000000.0

const keyboard_mouse_controls:ViVeCarControls = preload("res://MISC/controls config/presets/keyboard_and_mouse.tres")
const keyboard_controls:ViVeCarControls = preload("res://MISC/controls config/presets/keyboard.tres")
const touch_controls:ViVeCarControls = preload("res://MISC/controls config/presets/touch_screen.tres")
const joypad_controls:ViVeCarControls = preload("res://MISC/controls config/presets/joypad.tres")

#handful of string names used for the perfomance singleton
const perf_front_dist:StringName = &"Front Weight Distribution"
const perf_rear_dist:StringName = &"Rear Weight Distribution"
const perf_rpm:StringName = &"Current RPM"
const perf_turbo_psi:StringName = &"Current Turbo PSI"
const perf_gear:StringName = &"Transmission Gear"
const perf_torque:StringName = &"Torque"
const perf_resistance:StringName = &"Resistance"

##Which control type the car is going to be associated with.
enum ControlType {
	##Use the keyboard and mouse for control.
	CONTROLS_KEYBOARD_MOUSE,
	##Use just the keyboard for control.
	CONTROLS_KEYBOARD,
	##Use the touchscreen for control.
	CONTROLS_TOUCH,
	##Use a connected game controller for control.
	CONTROLS_JOYPAD,
}

##Selection of transmission types that are implemented in VitaVehicle.
enum TransmissionTypes {
	##Full manual transmission.
	full_manual = 0,
	##Automatic transmission.
	auto = 1,
	##CVT (continuously variable transmission)
	continuous_variable = 2,
	##Semi auto transmission.
	semi_auto = 3
}

@export_group("Controls")
##Use global controls (unimplemented)
@export var Use_Global_Control_Settings:bool = false
##The control set of this car.
@export var car_controls:ViVeCarControls = ViVeCarControls.new()
##The control preset for this car to use.
@export_enum("Keyboard and Mouse", "Keyboard", "Touch controls (Gyro)", "Joypad") var control_type:int = 1
## Presets to make shift assistance work properly.
@export var GearAssist:ViVeGearAssist = ViVeGearAssist.new()

@export_group("Meta")
##The name of this car.
@export var car_name:StringName = &"Vita Vehicle"
##Whether the car is a user-controlled vehicle or not
@export var Controlled:bool = true
##Whether or not debug mode is active.
@export var Debug_Mode:bool = false
##This locks RPM to the RPMLimit, disables differential locks,
##and disables FloatReduction, in order to make static testing easier.
@export var StaticRPMDebug:bool = false

@export_group("Chassis")
##Vehicle weight in kilograms.
@export var Weight:float = 900.0:
	set(new_weight):
		Weight = new_weight
		mass = Weight / 10.0

@export_group("Body")
##Up-pitch force based on the car’s velocity.
@export var LiftAngle:float = 0.1
##A force moving opposite in relation to the car’s velocity.
@export var DragCoefficient:float = 0.25
##A force moving downwards in relation to the car’s velocity.
@export var Downforce:float = 0.0

@export_group("Steering")
##The longitudinal pivot point from the car’s geometry (measured in default unit scale).
@export var AckermannPoint:float = -3.8
##Minimum turning circle (measured in default unit scale).
@export var Steer_Radius:float = 13.0
##The node names of the [ViVeWheels] actively driving (powering) the car.
@export var Powered_Wheels:Array[String] = ["fl", "fr"]

@export_group("Drivetrain")
##The transmission of this [ViVeCar].
@export var Transmission:ViVeTransmission = ViVeTransmissionManual.new():
	set(new_trans):
		Transmission = new_trans
		Transmission.car = self
##Final Drive Ratio refers to the last set of gears that connect a vehicle's engine to the driving axle.
@export var FinalDriveRatio:float = 4.250
##A set of gears a vehicle's transmission has, in order from first to last. [br]
##A gear ratio is the ratio of the number of rotations of a driver gear  to the number of rotations of a driven gear .
@export var GearRatios:Array[float] = [ 3.250, 1.894, 1.259, 0.937, 0.771 ]
##The gear ratio of the reverse gear.
@export var ReverseRatio:float = 3.153
##Similar to FinalDriveRatio, but this should not relate to any real-life data. You may keep the value as it is.
@export var RatioMult:float = 9.5
##The amount of stress put into the transmission (as in accelerating or decelerating) to restrict clutchless gear shifting.
@export var StressFactor:float = 1.0
##A space between the teeth of all gears to perform clutchless gear shifts. Higher values means more noise. Compensate with StressFactor.
@export var GearGap:float = 60.0
##Driveshaft weight. Usually, you should leave this as is.
@export var DSWeight:float = 150.0

##The [ViVeCar.TransmissionTypes] used for this car.
@export_enum("Fully Manual", "Automatic", "Continuously Variable", "Semi-Auto") var TransmissionType:int = 0

@export var AutoSettings:ViVeTransmissionAuto = ViVeTransmissionAuto.new()

## Settings for CVT.
@export var CVTSettings:ViVeCVT = ViVeCVT.new()

@export_group("Stability")
## Anti-lock Braking System. 
@export var ABS:ViVeABS = ViVeABS.new()
## @experimental 
## Electronic Stability Program. [br][br] CURRENTLY DOESN'T WORK!
@export var ESP:ViVeESP = ViVeESP.new()
## @experimental 
## Prevents wheel slippage using the brakes. [br] [br] CURRENTLY DOESN'T WORK!
@export var BTCS:ViVeBTCS = ViVeBTCS.new()
## @experimental 
## Prevents wheel slippage by partially closing the throttle. [br] [br] CURRENTLY DOESN'T WORK!
@export var TTCS:ViVeTTCS = ViVeTTCS.new()

@export_group("Differentials")
## Locks differential under acceleration.
@export var Locking:float = 0.1
## Locks differential under deceleration.
@export var CoastLocking:float = 0.0
## Static differential locking.
@export_range(0.0, 1.0) var Preload:float = 0.0
## Locks centre differential under acceleration.
@export var Centre_Locking:float = 0.5
## Locks centre differential under deceleration.
@export var Centre_CoastLocking:float = 0.5
## Static centre differential locking.
@export_range(0.0, 1.0) var Centre_Preload:float = 0.0

@export_group("Engine")
## Flywheel weight/lightness.
@export var RevSpeed:float = 2.0
## Chance of stalling.
@export var EngineFriction:float = 18000.0
## Rev drop rate.
@export var EngineDrag:float = 0.006
## How instant the engine corresponds with throttle input.
@export_range(0.0, 1.0) var ThrottleResponse:float = 0.5
## RPM below this threshold would stall the engine.
@export var DeadRPM:float = 100.0

@export_group("ECU")
##The maximum RPM at which the engine can still recieve throttle.
@export var RPMLimit:float = 7000.0
##How long throttle will be cut off when the 
##RPM limit is reached, in physics frames.
@export var LimiterDelay:float = 4
##The idling RPM.
@export var IdleRPM:float = 800.0
## Minimum throttle cutoff.
@export_range(0.0, 1.0) var ThrottleLimit:float = 0.0
## Throttle intake on idle.
@export_range(0.0, 1.0) var ThrottleIdle:float = 0.25
##The RPM at which the engine will switch to variable valve timing mode.
##Set this beyond the rev range to disable it, set it to 0 to use the vvt state permanently.
@export var VVTRPM:float = 4500.0 

@export_group("Torque")
##The normal [ViVeCarTorque] presets.
@export var torque_norm:ViVeCarTorque = ViVeCarTorque.new()
##The Variable Valve Timing [ViVeCarTorque] presets.
##The [ViVeCar] will switch to these when [ViVeCar.rpm] exceeded [ViVeCar.VVTRPM].
@export var torque_vvt:ViVeCarTorque = ViVeCarTorque.new("VVT")

@export_group("Clutch")
##This is how slippery the clutch plate is.
@export var ClutchStable:float = 0.5
## Usually on a really short gear, the engine would jitter. This fixes it.
@export var GearRatioRatioThreshold:float = 200.0
## Fix correlated to GearRatioRatioThreshold. Keep this value as it is.
@export var ThresholdStable:float = 0.01
## Clutch Capacity (nm).
@export var ClutchGrip:float = 176.125
## Prevents RPM "Floating". This gives a better sensation on accelerating. 
## Setting it too high would reverse the "floating". Setting it to 0 would turn it off.
@export var ClutchFloatReduction:float = 27.0
##The wobble rate of the clutch disc being in contact with the flywheel.
@export var ClutchWobble:float = 2.5 * 0
##This value is how much the clutch plate will wiggle rotationally when pressed to the flywheel.
@export var ClutchElasticity:float = 0.2 * 0
##Clutch wobble caused by the movement of the drivetrain.
@export var WobbleRate:float = 0.0

@export_group("Forced Inductions")
## Maximum air generated by any forced inductions.
@export var MaxPSI:float = 9.0
## Compression ratio has an effect on forced induction systems. 
##This is only an information for VitaVehicle to read boosts and it doesn't affect torque when TurboEnabled is off.
@export var EngineCompressionRatio:float = 8.0 # Piston travel distance

@export_subgroup("Turbo")
## Turbocharger. Enables turbo.
@export var TurboEnabled:bool = false
## Amount of turbochargers, multiplies boost power.
@export var TurboAmount:float = 1.0
## Turbo Lag. Higher = More turbo lag.
@export var TurboSize:float = 8.0
## Counters TurboSize. Higher = Allows more spooling on low RPM.
@export var Compressor:float = 0.3
## Threshold of throttle before spooling.
@export_range(0.0, 0.9999) var SpoolThreshold:float = 0.1
## How instant spooling stops.
@export var BlowoffRate:float = 0.14
## Turbo Response.
@export_range(0.0, 1.0) var TurboEfficiency:float = 0.075
## Allowing Negative PSI. Performance deficiency upon turbo idle.
@export var TurboVacuum:float = 1.0 

@export_subgroup("Supercharger")
## Enables supercharger.
@export var SuperchargerEnabled:bool = false 
## Boost applied upon engine speeds.
@export var SCRPMInfluence:float = 1.0
## Boost Amplification.
@export var BlowRate:float = 35.0
## Deadzone before boost.
@export var SCThreshold:float = 6.0

##Used by the camera and aerodynamics.
@onready var drag_center:Marker3D = $"DRAG_CENTRE"

##An array containing the front wheels of the car.
var front_wheels:Array[ViVeWheel] 
##An array containing the rear wheels of the car.
var rear_wheels:Array[ViVeWheel]
##An array containing all wheels of the car.
var all_wheels:Array[ViVeWheel]
##A set of wheels that are powered parented under the vehicle.
var driving_wheels:Array[ViVeWheel]
##All the wheels of the car where ViVeWheel.Steer is true.
var steering_wheels:Array[ViVeWheel]

##This is value compared to determine if the control scheme should be changed.
var car_controls_cache:ControlType
##The engine RPM, specifically the raw output (crankshaft RPM)
var rpm:float = 0.0

var throttle_limit_delay:float = 0.0

var actual_gear:int = 0
##This value must be less than [GearGap] in order for clutch-less shifting to be possible.
var gear_stress:float = 0.0
##Engine throttle, ie. the air-fuel mixture being allowed into the engine.
var throttle:float = 0.0
##Acceleration if the car is using a Continuously Variable Transmission
var cvt_accel:float = 0.0
##
var shift_assist_delay:float = 0.0
##The step that shift assistance is on, used in full_manual_transmission
var shift_assist_step:int = 0
##Used in full_manual_transmission.
var clutch_pedal:float = 0.0

var abs_pump:float = 0.0
##Unimplemented, related to [throttle]
var tcs_weight:float = 0.0
##Used in the tachometer.
var tcs_flash:bool = false
##Used in the tachometer.
var esp_flash:bool = false
##This is the overall multiplier from all the gears within 
##the drivetrain which applies to the speed of the axles.
var drive_axle_multiplier:float = 0.0
##The amount of brake, allowed by the ABS system.
var abs_brake_allowed:float = 0.0
##Brake power when ABS is factored in.
var brake_line:float = 0.0
##The total power bias of all powered wheels together.
var power_bias_total:float = 0.0
##[power_bias_total] from the last physics frame.
var previous_power_bias_total:float = 0.0
##This is how locked regular differentials are.
var differential_lock_percent:float = 0.0
##This is how locked the center differential is.
##Will be set to 0 if the car is not 4+WD.
var central_diff_lock_percent:float = 0.0
##Overall inertial-resistance feedback to the drivetrain brought by the wheels.
var drive_wheel_drivetrain_inertia:float = 0.0
##This is the resistance factor of several physical parts,
##acting in counter to the crankshaft RPM
var rpm_resistance:float = 0.0

var whine_pitch:float = 0.0
##The PSI of forced inductions
var turbo_psi:float = 0.0
##RPM when influenced by the supercharger
var sc_rpm:float = 0.0

var boosting:float = 0.0

var rpm_clutchslip:float = 0.0
##[rpm_clutchslip] from the previous frame, subtracted by [resistance].
var rpm_cs_m:float = 0.0
##This is how much the clutch plate is slipping at current RPM,
##affected by values such as the feedback inertia of the drivetrain.
var clutch_plate_slip:float = 0.0
##Used by the wheels for steering
var steer_to_direction:float 
##This is the power from all the drive wheels, 
##taking into account limited-slip differentials
var drive_wheel_diff_power:float = 0.0
##This is the overall "wobble" created by the clutch system.
var clutch_wobble:float = 0.0
##This is the driveshaft's resistance to rotation. 
##It is lessened by the current drive_axle_multiplier.
var driveshaft_weight_resistance:float = 0.0
##This is the average of [w_size] of all the drive wheel combined.
var average_drivewheel_size:float = 1.0
##An array of the global_rotation.y values of each steering wheel at the current physics frame.
##These angles are in degrees.
var steering_angles:Array[float] = []
##The largest value in [steering_angles], set each physics frame.
var max_steering_angle:float = 0.0

#physics values
##The velocity from the last physics frame
var past_velocity:Vector3 = Vector3.ZERO
##The force of gravity on the car.
var gforce:Vector3 = Vector3.ZERO
##A multiplier used in order to increase the speed of the simulation.
var clock_mult:float = 1.0
##This is the fastest wheel's 
var fastest_wheel_differed_wv:float = 0.0
##This is the overall grip of all the powered wheels combined.
var overall_power_grip:float = 0.0

var velocity:Vector3 = Vector3.ZERO

var ang_velocity:Vector3 = Vector3.ZERO

var stalled:float = 0.0

var front_load:float = 0.0
##This is the total suspension load on the car from all the wheels.
var total_load:float = 0.0
##This is the distribution of weight onto the front of the car.
var front_weight_distribution:float
##This is the distribution of weight onto the back of the car.
var rear_weight_distribution:float
##The physics tick, stored as a cache value and (eventually)
##a changeable value in order to account for changed physics tick
##in order to maintain proper simulation behavior.
var physics_tick:float = 60.0
##Current gear of the car.
var gear:int

var steer_velocity:float

var assistance_factor:float

var clutch_in:bool = false

var rev_match:bool = false

var gas_restricted:bool = false

var left:bool = false

var right:bool = false
##This is if shift up is pressed.
var shift_up_pressed:bool = false
##This is if shift down is pressed.
var shift_down_pressed:bool = false
##This is if gas is pressed.
var gas_pressed:bool = false
##This is if brake is pressed.
var brake_pressed:bool = false
##This is if handbrake is pressed.
var handbrake_pressed:bool = false
##This is if clutch is pressed.
var clutch_pressed:bool = false
##This is how pushed down the gas pedal is.
var gas_pedal:float = 0.0
##This is how pushed down the brake pedal is.
var brake_pedal:float = 0.0
##This is how far the handbrake is pulled.
var handbrake_pull:float = 0.0
##This is the steer value used by the engine, as opposed to the raw input value.
var effective_steer:float
##This is the raw input value for steering.
var steer_from_input:float

##This is how much contact the clutch plate is making with the flywheel, as a percent.
var clutch_engage_percent:float = 0.0
##Several parts of the engine use the clutch engage percent squared, so this is a 
##cache value for that to (slightly) increase performance.
var clutch_engage_squared:float = 0.0

## Emitted when the wheel arrays are updated.
signal wheels_updated

#Holdover from Godot 3. 
#Still here because Bullet is available as an optional GDExtension, so you never know
##Function for fixing ViVe under Bullet physics. Not needed when using Godot physics.
func bullet_fix() -> void:
	var fix_offset:Vector3 = drag_center.position
	AckermannPoint -= fix_offset.z
	
	for i:Node3D in get_children():
		i.position -= fix_offset

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	physics_tick = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0)
	
	swap_controls()
	
	fix_engine_stall()
	
	update_wheel_arrays()
	
	for wheel:ViVeWheel in all_wheels:
		wheel.register_debug()

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	Performance.add_custom_monitor(car_name + &"/" + perf_rpm, get, ["rpm"])
	Performance.add_custom_monitor(car_name + &"/" + perf_turbo_psi, get_turbo)
	Performance.add_custom_monitor(car_name + &"/" + perf_front_dist, get, ["front_weight_distribution"])
	Performance.add_custom_monitor(car_name + &"/" + perf_rear_dist, get, ["rear_weight_distribution"])
	Performance.add_custom_monitor(car_name + &"/" + perf_gear, get, ["gear"])
	Performance.add_custom_monitor(car_name + &"/" + perf_torque, multivariate, [-1])
	Performance.add_custom_monitor(car_name + &"/" + perf_resistance, get, ["drive_wheel_diff_power"])


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	Performance.remove_custom_monitor(car_name + &"/" + perf_rpm)
	Performance.remove_custom_monitor(car_name + &"/" + perf_turbo_psi)
	Performance.remove_custom_monitor(car_name + &"/" + perf_front_dist)
	Performance.remove_custom_monitor(car_name + &"/" + perf_rear_dist)
	Performance.remove_custom_monitor(car_name + &"/" + perf_gear)
	Performance.remove_custom_monitor(car_name + &"/" + perf_torque)
	Performance.remove_custom_monitor(car_name + &"/" + perf_resistance)

##Get the effective turbo.
func get_turbo() -> float:
	return turbo_psi * TurboAmount

##Updates several internal arrays used for iterating over wheels of various types.
func update_wheel_arrays() -> void:
	all_wheels.clear()
	front_wheels.clear()
	rear_wheels.clear()
	driving_wheels.clear()
	steering_wheels.clear()
	
	for nodes:Node in get_children():
		if nodes.is_class("RayCast3D"): #When in C++, check for "ViVeWheel"
			var wheel:ViVeWheel = nodes as ViVeWheel
			all_wheels.append(wheel)
			#front or rear wheels
			if wheel.position.z > 0:
				front_wheels.append(wheel)
			else:
				rear_wheels.append(wheel)
			#powered wheel
			if Powered_Wheels.has(wheel.name):
				driving_wheels.append(wheel)
			if wheel.Steer:
				steering_wheels.append(wheel)
	
	if all_wheels.is_empty():
		push_error("No wheels found for ", car_name)
	if driving_wheels.is_empty():
		push_error("No powered wheels found for ", car_name)
	if steering_wheels.is_empty():
		push_error("No steering wheels found for ", car_name)
	
	average_drivewheel_size = 0.0
	for wheel:ViVeWheel in driving_wheels:
		average_drivewheel_size += wheel.w_size / driving_wheels.size()
		wheel.live_power_bias = wheel.W_PowerBias
	GearAssist.speed_influence = average_drivewheel_size
	
	wheels_updated.emit()

##Reset the RPM in case of a stall
func fix_engine_stall() -> void:
	rpm = IdleRPM

##Do all the setup needed when swapping control schemes
func swap_controls() -> void:
	var new_control_scheme:ControlType = control_type as ControlType
	##TODO: swap Control resources
	match new_control_scheme:
		ControlType.CONTROLS_KEYBOARD_MOUSE:
			ViVeTouchControls.singleton.hide()
			car_controls = keyboard_mouse_controls
		ControlType.CONTROLS_KEYBOARD:
			ViVeTouchControls.singleton.hide()
			car_controls = keyboard_controls
		ControlType.CONTROLS_TOUCH:
			ViVeTouchControls.singleton.show()
			car_controls = touch_controls
		ControlType.CONTROLS_JOYPAD:
			ViVeTouchControls.singleton.hide()
			car_controls = joypad_controls
	
	car_controls_cache = new_control_scheme
	
	ViVeEnvironment.get_singleton().emit_signal("car_changed")

func new_controls() -> void:
	if control_type != car_controls_cache:
		swap_controls()
	
	if control_type == ControlType.CONTROLS_KEYBOARD_MOUSE:
		var mouseposx:float = get_window().get_mouse_position().x / get_window().size.x
		newer_controls(mouseposx)
	elif control_type == ControlType.CONTROLS_KEYBOARD:
		newer_controls()
	elif control_type == ControlType.CONTROLS_TOUCH:
		newer_controls(Input.get_accelerometer().x / 10.0)
	elif control_type == ControlType.CONTROLS_JOYPAD:
		newer_controls(car_controls.get_steer_axis())

func newer_controls(analog_axis:float = 0.0) -> void:
	gas_pressed = car_controls.is_gas_pressed()
	brake_pressed = car_controls.is_brake_pressed()
	handbrake_pressed = car_controls.is_handbrake_pressed()
	shift_up_pressed = car_controls.is_shift_up_pressed()
	shift_down_pressed = car_controls.is_shift_down_pressed()
	clutch_pressed = car_controls.is_clutch_pressed()
	
	if car_controls.LooseSteering:
		effective_steer += steer_velocity
		
		if absf(effective_steer) > 1.0:
			steer_velocity *= -0.5
		
		#for front_wheel:ViVeWheel in front_wheels:
		for front_wheel:ViVeWheel in steering_wheels:
			steer_velocity += (front_wheel.directional_force.x * 0.00125) * front_wheel.Caster
			#steer_velocity -= (front_wheel.grip * 0.0025) * (atan2(absf(front_wheel.wv), 1.0) * front_wheel.angle)
			steer_velocity -= (front_wheel.grip * 0.0025) * (atan(absf(front_wheel.wv)) * front_wheel.angle)
			
			steer_velocity += effective_steer * (front_wheel.directional_force.z * 0.0005) * front_wheel.Caster
			
			steer_velocity += front_wheel.directional_force.z * 0.0001 * signf(front_wheel.position.x)
			
			steer_velocity /= front_wheel.grip / (front_wheel.slip_percent_pre * (front_wheel.slip_percent_pre * 100.0) + 1.0) + 1.0
	
	if not Controlled:
		return
	
	match car_controls.ShiftingAssistance:
		2: #automatically go "forwards" regardless of pedal pressed, using the current gear to decide direction.
			if gear == ViVeTransmission.REVERSE: #going in reverse
				gas_pedal = car_controls.get_throttle(brake_pressed or rev_match)
				brake_pedal = car_controls.get_brake(gas_pressed)
			else: #Forward moving gear 
				gas_pedal = car_controls.get_throttle((gas_pressed and not gas_restricted) or rev_match)
				brake_pedal = car_controls.get_brake(brake_pressed)
		1: #go forward if gas_pressed is pressed, go backwards if brake_pressed is pressed.
			gas_pedal = car_controls.get_throttle(gas_pressed and not gas_restricted or rev_match)
			brake_pedal = car_controls.get_brake(brake_pressed)
		0: #1, but also automatically disable clutch
			gas_restricted = false
			clutch_in = false
			rev_match = false
			
			gas_pedal = car_controls.get_throttle(gas_pressed and not gas_restricted or rev_match)
			brake_pedal = car_controls.get_brake(brake_pressed)
	
	handbrake_pull = car_controls.get_handbrake(handbrake_pressed)
	
	#previously called "going"
	var forward_force:float
	
	#if the car is actively going left or right (and is not stationary)
	if (velocity.x > 0 and steer_from_input > 0) or (velocity.x < 0 and steer_from_input < 0):
		forward_force = maxf(velocity.z, 0.0)
	else:
		forward_force = maxf(velocity.z / (absf(velocity.x)), 0.0)
	
	if car_controls.LooseSteering:
		return
	
	steer_from_input = car_controls.get_steer_axis(analog_axis)
	
	#steering assistance
	if assistance_factor > 0.0:
		var max_steer:float = 1.0 / (forward_force * (car_controls.SteerAmountDecay / assistance_factor) + 1.0)
		var assist_commence:float = minf(linear_velocity.length() / 10.0, 1.0)
		
		if car_controls.EnableSteeringAssistance:
			effective_steer = (steer_from_input * max_steer) - (velocity.normalized().x * assist_commence) * (car_controls.SteeringAssistance * assistance_factor) + ang_velocity.y * (car_controls.SteeringAssistanceAngular * assistance_factor)
		else:
			effective_steer = (steer_from_input * max_steer)
	else:
		effective_steer = steer_from_input

func old_controls() -> void:
	if car_controls.UseAnalogSteering:
		gas_pressed = Input.is_action_pressed("gas_mouse")
		brake_pressed = Input.is_action_pressed("brake_mouse")
		shift_up_pressed = Input.is_action_just_pressed("shiftup_mouse")
		shift_down_pressed = Input.is_action_just_pressed("shiftdown_mouse")
		handbrake_pressed = Input.is_action_pressed("handbrake_mouse")
	else:
		gas_pressed = Input.is_action_pressed("gas")
		brake_pressed = Input.is_action_pressed("brake")
		shift_up_pressed = Input.is_action_just_pressed("shiftup")
		shift_down_pressed = Input.is_action_just_pressed("shiftdown")
		handbrake_pressed = Input.is_action_pressed("handbrake")
	
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	
	if left:
		steer_velocity -= 0.01
	elif right:
		steer_velocity += 0.01
	
	if car_controls.LooseSteering:
		effective_steer += steer_velocity
		
		if absf(effective_steer) > 1.0:
			steer_velocity *= -0.5
		
		#for front_wheel:ViVeWheel in [front_left,front_right]:
		for front_wheel:ViVeWheel in front_wheels:
			steer_velocity += (front_wheel.directional_force.x * 0.00125) * front_wheel.Caster
			steer_velocity -= (front_wheel.grip * 0.0025) * (atan(absf(front_wheel.wv)) * front_wheel.angle)
			
			steer_velocity += effective_steer * (front_wheel.directional_force.z * 0.0005) * front_wheel.Caster
			
			if front_wheel.position.x > 0:
				steer_velocity += front_wheel.directional_force.z * 0.0001
			else:
				steer_velocity -= front_wheel.directional_force.z * 0.0001
			
			steer_velocity /= front_wheel.grip / (front_wheel.slip_percent_pre * (front_wheel.slip_percent_pre * 100.0) + 1.0) + 1.0
	
	if Controlled:
		if car_controls.ShiftingAssistance == 2:
			if (gas_pressed and not gas_restricted and gear != ViVeTransmission.REVERSE) or (brake_pressed and gear == ViVeTransmission.REVERSE) or rev_match:
				gas_pedal += car_controls.OnThrottleRate / clock_mult
			else:
				gas_pedal -= car_controls.OffThrottleRate / clock_mult
			if (brake_pressed and not gear  == ViVeTransmission.REVERSE) or (gas_pressed and gear == ViVeTransmission.REVERSE):
				brake_pedal += car_controls.OnBrakeRate / clock_mult
			else:
				brake_pedal -= car_controls.OffBrakeRate / clock_mult
		else:
			if car_controls.ShiftingAssistance == 0:
				gas_restricted = false
				clutch_in = false
				rev_match = false
			
			#if gas_pressed and not gas_restricted or rev_match:
			if gas_pressed:
				gas_pedal += car_controls.OnThrottleRate / clock_mult
			else:
				gas_pedal -= car_controls.OffThrottleRate / clock_mult
			
			if brake_pressed:
				brake_pedal += car_controls.OnBrakeRate / clock_mult
			else:
				brake_pedal -= car_controls.OffBrakeRate / clock_mult
		
		if handbrake_pressed:
			handbrake_pull += car_controls.OnHandbrakeRate / clock_mult
		else:
			handbrake_pull -= car_controls.OffHandbrakeRate / clock_mult
		
		gas_pedal = clampf(gas_pedal, 0.0, car_controls.MaxThrottle)
		brake_pedal = clampf(brake_pedal, 0.0, car_controls.MaxBrake)
		handbrake_pull = clampf(handbrake_pull, 0.0, car_controls.MaxHandbrake)
		
		var siding:float = absf(velocity.x)
		
		#Based on the syntax, I'm unsure if this is doing what it "should" do...?
		if (velocity.x > 0 and steer_from_input > 0) or (velocity.x < 0 and steer_from_input < 0):
			siding = 0.0
		
		var going:float = velocity.z / (siding + 1.0)
		going = maxf(going, 0)
		
		#Steer based on control options
		if not car_controls.LooseSteering:
			
			if car_controls.UseAnalogSteering:
				var mouseposx:float = 0.0
#				if get_viewport().size.x > 0.0:
#					mouseposx = get_viewport().get_mouse_position().x / get_viewport().size.x
				if get_window().size.x > 0.0:
					mouseposx = get_window().get_mouse_position().x / get_window().size.x
				
				steer_from_input = (mouseposx - 0.5) * 2.0
				steer_from_input *= car_controls.SteerSensitivity
				
				steer_from_input = clampf(steer_from_input, -1.0, 1.0)
				
				var s:float = absf(steer_from_input) * 1.0 + 0.5
				s = minf(s, 1.0)
				
				steer_from_input *= s
				mouseposx = (mouseposx - 0.5) * 2.0
			elif car_controls.UseAnalogSteering:
				steer_from_input = Input.get_accelerometer().x / 10.0
				steer_from_input *= car_controls.SteerSensitivity
				
				steer_from_input = clampf(steer_from_input, -1.0, 1.0)
				
				var s:float = absf(steer_from_input) * 1.0 + 0.5
				s = minf(s, 1.0)
				
				steer_from_input *= s
			else:
				if right:
					if steer_from_input > 0:
						steer_from_input += car_controls.KeyboardSteerSpeed
					else:
						steer_from_input += car_controls.KeyboardCompensateSpeed
				elif left:
					if steer_from_input < 0:
						steer_from_input -= car_controls.KeyboardSteerSpeed
					else:
						steer_from_input -= car_controls.KeyboardCompensateSpeed
				else:
					if steer_from_input > car_controls.KeyboardReturnSpeed:
						steer_from_input -= car_controls.KeyboardReturnSpeed
					elif steer_from_input < - car_controls.KeyboardReturnSpeed:
						steer_from_input += car_controls.KeyboardReturnSpeed
					else:
						steer_from_input = 0.0
				steer_from_input = clampf(steer_from_input, -1.0, 1.0)
			
			
			if assistance_factor > 0.0:
				var maxsteer:float = 1.0 / (going * (car_controls.SteerAmountDecay / assistance_factor) + 1.0)
				
				var assist_commence:float = linear_velocity.length() / 10.0
				assist_commence = minf(assist_commence, 1.0)
				
				effective_steer = (steer_from_input * maxsteer) - (velocity.normalized().x * assist_commence) * (car_controls.SteeringAssistance * assistance_factor) + ang_velocity.y * (car_controls.SteeringAssistanceAngular * assistance_factor)
			else:
				effective_steer = steer_from_input

func transmission() -> void:
	if not car_controls.ShiftingAssistance == 0:
		clutch_pressed = handbrake_pressed
	clutch_pressed = not clutch_pressed
	
	#TODO: Put clutch/torque converter calculations here
	
	#rpm = Transmission._transmission_callback(rpm)
	#gear = Transmission._get_current_gear()
	if TransmissionType == TransmissionTypes.full_manual:
		full_manual_transmission()
	elif TransmissionType == TransmissionTypes.auto:
		automatic_transmission()
	elif TransmissionType == TransmissionTypes.continuous_variable:
		cvt_transmission()
	elif TransmissionType == TransmissionTypes.semi_auto:
		semi_auto_transmission()
	
	clutch_engage_percent = clampf(clutch_engage_percent, 0.0, 1.0)
	clutch_engage_squared = clutch_engage_percent * clutch_engage_percent

func full_manual_transmission() -> void:
	clutch_pedal = car_controls.get_clutch(not (clutch_pressed and not clutch_in))
	
	clutch_engage_percent = 1.0 - clutch_pedal
	
	if gear > 0:
		drive_axle_multiplier = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
	elif gear == ViVeTransmission.REVERSE:
		drive_axle_multiplier = ReverseRatio * FinalDriveRatio * RatioMult
	
	if car_controls.ShiftingAssistance == 0:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < GearRatios.size():
				if gear_stress < GearGap:
					actual_gear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > ViVeTransmission.REVERSE:
				if gear_stress < GearGap:
					actual_gear -= 1
	
	elif car_controls.ShiftingAssistance == 1:
		if rpm < GearAssist.clutch_out_RPM:
			clutch_pedal = minf(pow((GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM), 2.0), 1.0)
		else:
			if not gas_restricted and not rev_match:
				clutch_in = false
		
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < GearRatios.size():
				if rpm < GearAssist.clutch_out_RPM:
					actual_gear += 1
				else:
					if actual_gear < 1:
						actual_gear += 1
						if rpm > GearAssist.clutch_out_RPM:
							clutch_in = false
					else:
						if shift_assist_delay > 0:
							actual_gear += 1
						shift_assist_delay = GearAssist.shift_delay / 2.0
						shift_assist_step = -4
						
						clutch_in = true
						gas_restricted = true
		
		elif shift_down_pressed:
			shift_down_pressed = false
			if gear > ViVeTransmission.REVERSE:
				if rpm < GearAssist.clutch_out_RPM:
					actual_gear -= 1
				else:
					if actual_gear == 0 or actual_gear == 1:
						actual_gear -= 1
						clutch_in = false
					else:
						if shift_assist_delay > 0:
							actual_gear -= 1
						shift_assist_delay = GearAssist.shift_delay / 2.0
						shift_assist_step = -2
						
						clutch_in = true
						rev_match = true
						gas_restricted = false
	
	elif car_controls.ShiftingAssistance == 2:
		var assist_shift_speed:float = (GearAssist.upshift_RPM / drive_axle_multiplier) * GearAssist.speed_influence
		var assist_down_shift_speed:float = (GearAssist.down_RPM / absf((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = ViVeTransmission.REVERSE
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == ViVeTransmission.REVERSE:
				shift_assist_delay = 60
				actual_gear = 0
		if shift_assist_step == 0:
			if rpm < GearAssist.clutch_out_RPM:
				clutch_pedal = minf(pow((GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM), 2.0), 1.0)
			else:
				clutch_in = false
			if gear != ViVeTransmission.REVERSE:
				if gear < GearRatios.size() and linear_velocity.length() > assist_shift_speed:
					shift_assist_delay = GearAssist.shift_delay / 2.0
					shift_assist_step = -4
					
					clutch_in = true
					gas_restricted = true
				if gear > 1 and linear_velocity.length() < assist_down_shift_speed:
					shift_assist_delay = GearAssist.shift_delay / 2.0
					shift_assist_step = -2
					
					clutch_in = true
					gas_restricted = false
					rev_match = true
	
	if shift_assist_step == -4 and shift_assist_delay < 0:
		shift_assist_delay = GearAssist.shift_delay / 2.0
		if gear < GearRatios.size():
			actual_gear += 1
		shift_assist_step = -3
	
	elif shift_assist_step == -3 and shift_assist_delay < 0:
		if rpm > GearAssist.clutch_out_RPM:
			clutch_in = false
		if shift_assist_delay < - GearAssist.input_delay:
			shift_assist_step = 0
			gas_restricted = false
	
	elif shift_assist_step == -2 and shift_assist_delay < 0:
		shift_assist_step = 0
		if gear > ViVeTransmission.REVERSE:
			actual_gear -= 1
		if rpm > GearAssist.clutch_out_RPM:
			clutch_in = false
		gas_restricted = false
		rev_match = false
	
	gear = actual_gear

func automatic_transmission() -> void:
	clutch_engage_percent = (rpm - AutoSettings.engage_rpm_thresh * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh)) ) / AutoSettings.engage_rpm
	
	if not car_controls.ShiftingAssistance == 2:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < 1:
				actual_gear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > ViVeTransmission.REVERSE:
				actual_gear -= 1
	else:
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = ViVeTransmission.REVERSE
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == ViVeTransmission.REVERSE:
				shift_assist_delay = 60
				actual_gear = 0
	
	if actual_gear == ViVeTransmission.REVERSE:
		drive_axle_multiplier = ReverseRatio * FinalDriveRatio * RatioMult
	else:
		drive_axle_multiplier = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
	
	if actual_gear > 0:
		var last_gears_ratio:float = GearRatios[gear - 2] * FinalDriveRatio * RatioMult
		
		shift_up_pressed = false
		shift_down_pressed = false
		for i:ViVeWheel in driving_wheels:
			if (i.wv / GearAssist.speed_influence) > (AutoSettings.shift_rpm * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh))) / drive_axle_multiplier:
				shift_up_pressed = true
			elif (i.wv / GearAssist.speed_influence) < ((AutoSettings.shift_rpm - AutoSettings.downshift_thresh) * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh))) / last_gears_ratio:
				shift_down_pressed = true
		
		if shift_up_pressed:
			gear += 1
		elif shift_down_pressed:
			gear -= 1
		
		gear = clampi(gear , 1, GearRatios.size())
	else:
		gear = actual_gear

func cvt_transmission() -> void:
	clutch_engage_percent = (rpm - AutoSettings.engage_rpm_thresh * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh)) ) / AutoSettings.engage_rpm
	
	#clutch_engage_percent = 1
	
	if not car_controls.ShiftingAssistance == 2:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < 1:
				actual_gear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > ViVeTransmission.REVERSE:
				actual_gear -= 1
	else:
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = ViVeTransmission.REVERSE
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == ViVeTransmission.REVERSE:
				shift_assist_delay = 60
				actual_gear = 0
	
	gear = actual_gear
	var all_wheels_velocity:float = 0.0
	
	for i:ViVeWheel in driving_wheels:
		all_wheels_velocity += i.wv / driving_wheels.size()
	
	cvt_accel -= (cvt_accel - (gas_pedal * CVTSettings.throt_eff_thresh + (1.0 - CVTSettings.throt_eff_thresh))) * CVTSettings.accel_rate
	
	var a:float = maxf(CVTSettings.iteration_3 / ((absf(all_wheels_velocity) / 10.0) * cvt_accel + 1.0), CVTSettings.iteration_4)
	
	drive_axle_multiplier = (CVTSettings.iteration_1 * 10000000.0) / (absf(all_wheels_velocity) * (rpm * a) + 1.0)
	
	drive_axle_multiplier = minf(drive_axle_multiplier, CVTSettings.iteration_2)

func semi_auto_transmission() -> void:
	clutch_engage_percent = (rpm - AutoSettings.engage_rpm_thresh * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh)) ) / AutoSettings.engage_rpm
	
	if gear > 0:
		drive_axle_multiplier = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
	elif gear == ViVeTransmission.REVERSE:
		drive_axle_multiplier = ReverseRatio * FinalDriveRatio * RatioMult
	
	if car_controls.ShiftingAssistance < 2:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < GearRatios.size():
				actual_gear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > ViVeTransmission.REVERSE:
				actual_gear -= 1
	else:
		var assist_shift_speed:float = (GearAssist.upshift_RPM / drive_axle_multiplier) * GearAssist.speed_influence
		var assist_down_shift_speed:float = (GearAssist.down_RPM / absf((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actual_gear = ViVeTransmission.REVERSE
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == ViVeTransmission.REVERSE:
				shift_assist_delay = 60
				actual_gear = 0
		if shift_assist_step == 0:
			if gear != ViVeTransmission.REVERSE:
				if gear < GearRatios.size() and linear_velocity.length() > assist_shift_speed:
					actual_gear += 1
				if gear > 1 and linear_velocity.length() < assist_down_shift_speed:
					actual_gear -= 1
	
	gear = actual_gear

func drivetrain() -> void:
	rpm_cs_m -= (rpm_clutchslip - drive_wheel_diff_power)
	
	rpm_clutchslip += rpm_cs_m * ClutchElasticity
	
	#clutch slips more the less it is contact.
	rpm_clutchslip -= rpm_clutchslip * (1.0 - clutch_engage_percent)
	#clutch wobble is the flywheel contact wobble times current gear wobble
	clutch_wobble = (ClutchWobble * clutch_engage_percent) * (drive_axle_multiplier * WobbleRate)
	
	rpm_clutchslip -= (rpm_clutchslip - drive_wheel_diff_power) * (1.0 / (clutch_wobble + 1.0))
	
	if gear == ViVeTransmission.REVERSE:
		rpm -= ((rpm_clutchslip / clock_mult) * (RevSpeed / revspeed_magic_number))
	else:
		rpm += ((rpm_clutchslip / clock_mult) * (RevSpeed / revspeed_magic_number))
	
	if StaticRPMDebug:
		rpm = RPMLimit
		Locking = 0.0
		CoastLocking = 0.0
		Centre_Locking = 0.0
		Centre_CoastLocking = 0.0
		Preload = 1.0
		Centre_Preload = 1.0
		ClutchFloatReduction = 0.0
	
	gear_stress = (absf(drive_wheel_diff_power) * StressFactor) * clutch_engage_percent
	driveshaft_weight_resistance = DSWeight / float(drive_axle_multiplier * 0.9 + 0.1)
	
	whine_pitch = absf(rpm / drive_axle_multiplier) * 1.5
	
	if drive_wheel_diff_power > 0.0:
		differential_lock_percent = absf(drive_wheel_diff_power / driveshaft_weight_resistance) * (CoastLocking / 100.0) + Preload
	else:
		differential_lock_percent = absf(drive_wheel_diff_power / driveshaft_weight_resistance) * (Locking / 100.0) + Preload
	
	differential_lock_percent = clampf(differential_lock_percent, 0.0, 1.0)
	
	if drive_wheel_drivetrain_inertia > 0.0:
		central_diff_lock_percent = absf(drive_wheel_drivetrain_inertia) * (Centre_CoastLocking / 10.0) + Centre_Preload
	else:
		central_diff_lock_percent = absf(drive_wheel_drivetrain_inertia) * (Centre_Locking / 10.0) + Centre_Preload
	
	central_diff_lock_percent = clampf(central_diff_lock_percent, 0.0, 1.0)
	if driving_wheels.size() < 4:
		central_diff_lock_percent = 0.0
	
	var current_fastest_wheel:ViVeWheel = fastest_wheel()
	var effective_drivetrain_rpm:float = rpm
	var powered_float_reduction:float = 0.0
	
	if previous_power_bias_total > 0.0:
		powered_float_reduction = ClutchFloatReduction / previous_power_bias_total
	
	var drivetrain_inertia_feedback:float = maxf(-(GearRatioRatioThreshold - (drive_axle_multiplier * average_drivewheel_size)) * ThresholdStable, 0.0)
	
	clutch_plate_slip = (ClutchStable + drivetrain_inertia_feedback) * (RevSpeed / revspeed_magic_number)
	
	if previous_power_bias_total > 0.0:
		effective_drivetrain_rpm = rpm - (((rpm_resistance * powered_float_reduction) * clutch_plate_slip) / (driveshaft_weight_resistance / previous_power_bias_total))
	
	#how much RPM the axle is losing in this frame
	var axle_rpm:float = effective_drivetrain_rpm / drive_axle_multiplier
	
	if gear == ViVeTransmission.NEUTRAL:
		fastest_wheel_differed_wv = 0.0
	elif gear == ViVeTransmission.REVERSE:
		fastest_wheel_differed_wv = current_fastest_wheel.wv + axle_rpm
	else:
		fastest_wheel_differed_wv = current_fastest_wheel.wv - axle_rpm
	
	fastest_wheel_differed_wv *= clutch_engage_squared
	
	drive_wheel_drivetrain_inertia = 0.0
	average_drivewheel_size = 0.0
	
	#update stats of all the powered wheels
	for wheel:ViVeWheel in driving_wheels:
		average_drivewheel_size += wheel.w_size / driving_wheels.size()
		wheel.live_power_bias = wheel.W_PowerBias
		
		drive_wheel_drivetrain_inertia += ((wheel.wv - axle_rpm) / driving_wheels.size()) * clutch_engage_squared
		
		if gear == ViVeTransmission.NEUTRAL:
			wheel.differential_distributed_wv = 0.0
		elif gear == ViVeTransmission.REVERSE:
			wheel.differential_distributed_wv = fastest_wheel_differed_wv * (1.0 - central_diff_lock_percent) + (wheel.wv + axle_rpm) * central_diff_lock_percent
		else:
			wheel.differential_distributed_wv = fastest_wheel_differed_wv * (1.0 - central_diff_lock_percent) + (wheel.wv - axle_rpm) * central_diff_lock_percent
	
	#"end of frame" cleanup
	GearAssist.speed_influence = average_drivewheel_size
	drive_wheel_diff_power = 0.0
	previous_power_bias_total = power_bias_total
	power_bias_total = 0.0
	tcs_weight = 0.0
	overall_power_grip = 0.0

##Applies aerodynamics to the car.
func aerodynamics() -> void:
	var normal_velocity:Vector3 = global_transform.basis.orthonormalized().transposed() * (linear_velocity)
	
	apply_torque_impulse(global_transform.basis.orthonormalized() * ( Vector3((-normal_velocity.length() * 0.3) * LiftAngle, 0.0, 0.0)))
	
	var drag_velocity:Vector3 = (normal_velocity * 0.15)
	var drag_velocity_length:float = normal_velocity.length() * 0.15
	
	drag_velocity.x = -drag_velocity.x * DragCoefficient
	drag_velocity.y = -drag_velocity_length * Downforce - drag_velocity.y * DragCoefficient
	drag_velocity.z = -drag_velocity.z * DragCoefficient
	
	var air_drag_force:Vector3 = global_transform.basis.orthonormalized() * drag_velocity
	
	if is_instance_valid(drag_center):
		apply_impulse(air_drag_force, global_transform.basis.orthonormalized() * (drag_center.position))
	else:
		apply_central_impulse(air_drag_force)

func _physics_process(_delta:float) -> void:
	if Engine.is_editor_hint():
		return
	
	if steering_angles.size() > 0:
		max_steering_angle = 0.0
		
		for angles:float in steering_angles:
			max_steering_angle = maxf(max_steering_angle, angles)
		
		assistance_factor = 90.0 / max_steering_angle
	
	steering_angles.clear()
	
	#TODO: Set these elsewhere, such as a settings file
#	if Use_Global_Control_Settings:
#		car_controls = VitaVehicleSimulation.universal_controls
	
	velocity = global_transform.basis.orthonormalized().transposed() * (linear_velocity)
	ang_velocity = global_transform.basis.orthonormalized().transposed() * (angular_velocity)
	
	aerodynamics()
	
	#translation to ViVe units from meters
	const vive_units_to_meters:float = 0.30592
	#gravity constant (because ViVe screws with gravity)
	const normal_gravity:float = 9.806
	#60.0 is likely the physics tick, so that the number is per second and not per physics tick
	#gforce = (linear_velocity - past_velocity) * ((vive_units_to_meters / normal_gravity) * physics_tick)
	gforce = (linear_velocity - past_velocity) * ((vive_units_to_meters / normal_gravity) * 60.0)
	past_velocity = linear_velocity
	
	gforce *= global_transform.basis.orthonormalized().transposed()
	
	new_controls()
	#old_controls()
	
	drive_axle_multiplier = 10.0
	
	shift_assist_delay -= 1
	
	transmission()
	
	effective_steer = clampf(effective_steer, -1.0, 1.0)
	
	#I graphed this function in a calculator, and it only curves significantly if max_steering_angle > 200
	#I've tried it, this calculation is functionally redundant, but imma leave it in because Authenticity:tm:
	#var uhh:float = pow((max_steering_angle / 90.0), 2.0) * 0.5
	
	#var steeroutput:float = effective_steer * (absf(effective_steer) * (uhh) + (1.0 - uhh))
	var steeroutput:float = effective_steer * absf(effective_steer) #without the redundant calculation
	
	if not is_zero_approx(steeroutput):
		steer_to_direction = -Steer_Radius / steeroutput
	
	abs_pump -= 1
	
	if abs_pump < 0:
		abs_brake_allowed += ABS.pump_force
	else:
		abs_brake_allowed -= ABS.pump_force
	
	abs_brake_allowed = clampf(abs_brake_allowed, 0.0, 1.0)
	
	brake_line = maxf(brake_pedal * abs_brake_allowed, 0.0)
	
	throttle_limit_delay -= 1
	
	if throttle_limit_delay < 0:
		throttle -= (throttle - (gas_pedal / (tcs_weight * clutch_engage_percent + 1.0))) * (ThrottleResponse / clock_mult)
	else:
		throttle -= throttle * (ThrottleResponse / clock_mult)
	
	if rpm > RPMLimit:
		if throttle > ThrottleLimit:
			throttle = ThrottleLimit
			throttle_limit_delay = LimiterDelay
	elif rpm < IdleRPM:
		throttle = maxf(throttle, ThrottleIdle)
	
	if TurboEnabled:
		var throttle_spooling:float = (throttle - SpoolThreshold) / (1 - SpoolThreshold)
		
		if boosting > throttle_spooling:
			boosting = throttle_spooling
		else:
			boosting -= (boosting - throttle_spooling) * TurboEfficiency
		 
		turbo_psi += (boosting * rpm) / ((TurboSize / Compressor) * 60.9)
		
		turbo_psi = clampf(turbo_psi - (turbo_psi * BlowoffRate), -TurboVacuum, MaxPSI)
	
	elif SuperchargerEnabled:
		sc_rpm = rpm * SCRPMInfluence
		turbo_psi = clampf((sc_rpm / 10000.0) * BlowRate - SCThreshold, 0.0, MaxPSI)
	
	else:
		turbo_psi = 0.0
	
	var torque:float = 0.0
	
	var torque_local:ViVeCarTorque
	if rpm > VVTRPM:
		torque_local = torque_vvt
	else:
		torque_local = torque_norm
	
	var increased_rpm:float = maxf(rpm - torque_local.RiseRPM, 0.0)
	var reduced_rpm:float = maxf(rpm - torque_local.DeclineRPM, 0.0)
	
	torque = (rpm * torque_local.BuildUpTorque + torque_local.OffsetTorque + (increased_rpm * increased_rpm) * (torque_local.TorqueRise / torque_fractional)) * throttle
	
	#Apply forced induction factors to the outpur torque
	torque += ((turbo_psi * TurboAmount) * (EngineCompressionRatio * turbo_magic_number))
	
	#Apply rpm reductions to the torque
	torque /= (reduced_rpm * (reduced_rpm * torque_local.DeclineSharpness + (1.0 - torque_local.DeclineSharpness))) * (torque_local.DeclineRate / torque_fractional) + 1.0
	
	torque /= (rpm * rpm) * (torque_local.FloatRate / torque_fractional) + 1.0
	
	rpm_resistance = (rpm / ((rpm * rpm) / (EngineFriction / clock_mult) + 1.0))
	var new_rpm_force:float = (rpm * EngineFriction) / (EngineFriction + (rpm * rpm) * clock_mult)
	assert(is_equal_approx(rpm_resistance, new_rpm_force))
	
	if rpm < DeadRPM:
		torque = 0.0
		rpm_resistance /= 5.0
		stalled = 1.0 - rpm / DeadRPM
	else:
		stalled = 0.0
	
	#add the RPM drop to the rpm force
	rpm_resistance += (rpm * (EngineDrag / clock_mult))
	#reduce RPM force by the torque
	rpm_resistance -= (torque / clock_mult)
	#reduce RPM by the rpm force times the flywheel lightness
	rpm -= rpm_resistance * RevSpeed
	
	drivetrain()

func _process(_delta:float) -> void:
	if Engine.is_editor_hint():
		return
	
	if Debug_Mode:
		update_wheel_arrays()
		
		front_load = 0.0
		total_load = 0.0
		
		for front_wheel:ViVeWheel in front_wheels:
			front_load += front_wheel.directional_force.y
			total_load += front_wheel.directional_force.y
		for rear_wheel:ViVeWheel in rear_wheels:
			front_load -= rear_wheel.directional_force.y
			total_load += rear_wheel.directional_force.y
		
		if total_load > 0:
			front_weight_distribution = (front_load / total_load) * 0.5 + 0.5
			rear_weight_distribution = 1.0 - front_weight_distribution

const multivariation_inputs:PackedStringArray = [
"RiseRPM","TorqueRise","BuildUpTorque","EngineFriction",
"EngineDrag","OffsetTorque","RPM","DeclineRPM","DeclineRate",
"FloatRate","PSI","TurboAmount","EngineCompressionRatio",
"TEnabled","VVTRPM","VVT_BuildUpTorque","VVT_TorqueRise",
"VVT_RiseRPM","VVT_OffsetTorque","VVT_FloatRate",
"VVT_DeclineRPM","VVT_DeclineRate","SCEnabled",
"SCRPMInfluence","BlowRate","SCThreshold",
"DeclineSharpness","VVT_DeclineSharpness"
]

##Determine power/torque output on specific rpm values.
##If no specific RPM is provided, or the provided RPM is 0, 
##it will use the current RPM of the car
func multivariate(extern_rpm:float = 0.0) -> float:
	var test_rpm:float
	
	if not is_zero_approx(extern_rpm):
		test_rpm = extern_rpm
	else:
		test_rpm = rpm
	
	var psi:float = MaxPSI
	
	if SuperchargerEnabled:
		var scrpm:float = test_rpm * SCRPMInfluence
		psi = clampf((scrpm / 10000.0) * BlowRate - SCThreshold, 0.0, MaxPSI)
	elif not TurboEnabled:
		psi = 0.0
	
	var torque_local:ViVeCarTorque
	
	if test_rpm > VVTRPM:
		torque_local = torque_vvt
	else:
		torque_local = torque_norm
	
	var increased_rpm:float = maxf(test_rpm - torque_local.RiseRPM, 0.0)
	var reduced_rpm:float = maxf(test_rpm - torque_local.DeclineRPM, 0.0)
	var return_torque:float = 0.0
	
	return_torque = (test_rpm * torque_local.BuildUpTorque + torque_local.OffsetTorque)
	
	return_torque += (psi * TurboAmount) * (EngineCompressionRatio * turbo_magic_number)
	
	return_torque += pow(increased_rpm, 2.0) * (torque_local.TorqueRise / torque_fractional)
	
	return_torque /= (reduced_rpm * (reduced_rpm * torque_local.DeclineSharpness + (1.0 - torque_local.DeclineSharpness))) * (torque_local.DeclineRate / torque_fractional) + 1.0
	
	return_torque /= pow(test_rpm, 2.0) * (torque_local.FloatRate / torque_fractional) + 1.0
	
	return_torque -= test_rpm / (pow(test_rpm, 2.0) / EngineFriction + 1.0)
	return_torque -= test_rpm * EngineDrag
	
	return return_torque

##Get the fastest wheel.
##It gets the fastest of [driving_wheels], and uses [absolute_wv] to determine the fastest.
func fastest_wheel() -> ViVeWheel:
	var val:float = -10000000000000000000000000000000000.0
	var obj:ViVeWheel
	
	for i:ViVeWheel in driving_wheels:
		val = maxf(val, absf(i.absolute_wv))
		
		if is_equal_approx(val, absf(i.absolute_wv)):
			obj = i
	
	return obj
