@tool
extends Resource
##A class that handles and controls the car's control options.
class_name ViVeCarControls

##The asthetic name of the control preset
@export var ControlMapName:String = "Default"

@export_group("Shifting")
##Action name for shifting up.
@export var ActionNameShiftUp:StringName = &"shiftup"
##Action name for shifting down.
@export var ActionNameShiftDown:StringName = &"shiftdown"
##The shift assistance level.
@export_enum("None", "Automatic clutch", "Fully automatic") var ShiftingAssistance:int = 2


@export_group("Steering")
##If true, analog steering will be used
@export var UseAnalogSteering:bool = false

@export_subgroup("Analog")
## Steering amplification on analog steering.
@export var SteerSensitivity:float = 1.0

@export_subgroup("Digital")
##Action name for steering left by button.
@export var ActionNameSteerLeft:StringName = &"left"
##Action name for steering right by button.
@export var ActionNameSteerRight:StringName = &"right"
## Digital steering response rate.
@export var KeyboardSteerSpeed:float = 0.025
## Digital steering centering rate.
@export var KeyboardReturnSpeed:float = 0.05
## Digital return rate when steering from an opposite direction. 
@export var KeyboardCompensateSpeed:float = 0.1

## Reduces steering rate based on the vehicle’s speed.
##This helps with understeer.
@export var SteerAmountDecay:float = 0.015
## Enable Steering Assistance.
@export var EnableSteeringAssistance:bool = true
## Drift Help. The higher the value, the more the car will automatically center itself when drifting.
@export var SteeringAssistance:float = 1.0
## Drift Stability Help.
@export var SteeringAssistanceAngular:float = 0.12
##@experimental Simulate rack and pinion steering physics.
@export var LooseSteering:bool = false

#In C++, none of these will be indepenent variables: The setgets will map directly to their structs.
@export_group("Throttle")
##Action name for throttle.
@export var ActionNameThrottle:StringName = &"gas":
	set(new_name):
		ActionNameThrottle = new_name
		throttle_button.name = new_name
##If throttle is from a digital source (button).
@export var IsThrottleDigital:bool = true:
	set(new_value):
		IsThrottleDigital = new_value
		throttle_button.digital = new_value
## Throttle pressure rate.
@export var OnThrottleRate:float = 0.2:
	set(new_rate):
		OnThrottleRate = new_rate
		throttle_button.on_rate = new_rate
## Throttle depress rate.
@export var OffThrottleRate:float = 0.2:
	set(new_rate):
		OffThrottleRate = new_rate
		throttle_button.off_rate = new_rate
## Maximum throttle amount.
@export var MaxThrottle:float = 1.0:
	set(new_max):
		MaxThrottle = new_max
		throttle_button.maximum = new_max
@export_group("Brake")
##Action name for braking.
@export var ActionNameBrake:StringName = &"brake":
	set(new_name):
		ActionNameBrake = new_name
		brake_button.name = new_name
##If braking is from a digital source (button).
@export var IsBrakeDigital:bool = true:
	set(new_value):
		IsBrakeDigital = new_value
		brake_button.digital = new_value
## Brake pressure rate.
@export var OnBrakeRate:float = 0.05:
	set(new_rate):
		OnBrakeRate = new_rate
		brake_button.on_rate = new_rate
## Brake depress rate.
@export var OffBrakeRate:float = 0.1:
	set(new_rate):
		OffBrakeRate = new_rate
		brake_button.off_rate = new_rate
## Maximum brake_pressed amount.
@export var MaxBrake:float = 1.0:
	set(new_max):
		MaxBrake = new_max
		brake_button.maximum = new_max
@export_group("Handbrake")
##Action name for handbraking.
@export var ActionNameHandbrake:StringName = &"handbrake":
	set(new_name):
		ActionNameHandbrake = new_name
		handbrake_button.name = new_name
##If handbrake is from a digital source (button).
@export var IsHandbrakeDigital:bool = true:
	set(new_value):
		IsHandbrakeDigital = new_value
		handbrake_button.digital = new_value
## Handbrake pull rate.
@export var OnHandbrakeRate:float = 0.2:
	set(new_rate):
		OnHandbrakeRate = new_rate
		handbrake_button.on_rate = new_rate
## Handbrake push rate.
@export var OffHandbrakeRate:float = 0.2:
	set(new_rate):
		OffHandbrakeRate = new_rate
		handbrake_button.off_rate = new_rate
## Maximum handbrake amount.
@export var MaxHandbrake:float = 1.0:
	set(new_max):
		MaxHandbrake = new_max
		handbrake_button.maximum = new_max
@export_group("Clutch")
##Action name for clutching.
@export var ActionNameClutch:StringName = &"clutch":
	set(new_name):
		ActionNameClutch = new_name
		clutch_button.name = new_name
##If clutch is from a digital source (button).
@export var IsClutchDigital:bool = true:
	set(new_value):
		IsClutchDigital = new_value
		clutch_button.digital = new_value
## Clutch release rate.
@export var OnClutchRate:float = 0.2:
	set(new_rate):
		OnClutchRate = new_rate
		clutch_button.on_rate = new_rate
## Clutch engage rate.
@export var OffClutchRate:float = 0.2:
	set(new_rate):
		OffClutchRate = new_rate
		clutch_button.off_rate = new_rate
## Maxiumum clutch amount.
@export var MaxClutch:float = 1.0:
	set(new_max):
		MaxClutch = new_max
		clutch_button.maximum = new_max

#An internal class for buttons so that it's easier to handle them.
#When ViVe gets ported to C++, this will become a private struct
class ButtonWrapper:
	extends Resource
	static var clock_mult:float = 1.0
	var name:StringName
	
	var strength:float
	var pressed:bool
	
	var digital:bool
	var on_rate:float
	var off_rate:float
	var minimum:float = 0.0 #unused
	var maximum:float = 1.0
	
	func update_press(just:bool) -> bool:
		if digital:
			if just:
				pressed = Input.is_action_just_pressed(name)
			else:
				pressed = Input.is_action_pressed(name)
		else:
			pressed = not is_zero_approx(Input.get_action_strength(name))
		return pressed
	
	func poll(cond:bool) -> float:
		if cond:
			if digital:
				strength += on_rate / clock_mult
			else: 
				strength = Input.get_action_strength(name)
		else:
			strength -= off_rate / clock_mult
		strength = clampf(strength, minimum, maximum)
		return strength

var throttle_button:ButtonWrapper = ButtonWrapper.new()
var brake_button:ButtonWrapper = ButtonWrapper.new()
var handbrake_button:ButtonWrapper = ButtonWrapper.new()
var clutch_button:ButtonWrapper = ButtonWrapper.new()

var clock_mult:float = 1.0

var steer_axis_amount:float

func _init() -> void:
	clock_mult = 1.0
	#ButtonWrapper.clock_mult = ViVeEnvironment.get_singleton().clock_mult #causes load error
	
	throttle_button.name = ActionNameThrottle
	throttle_button.digital = IsThrottleDigital
	throttle_button.on_rate = OnThrottleRate
	throttle_button.off_rate = OffThrottleRate
	throttle_button.maximum = MaxThrottle
	#throttle_button.minimum = MinThrottle
	
	brake_button.name = ActionNameBrake
	brake_button.digital = IsBrakeDigital
	brake_button.on_rate = OnBrakeRate
	brake_button.off_rate = OffBrakeRate
	brake_button.maximum = MaxBrake
	#throttle_button.minimum = MinBrake
	
	handbrake_button.name = ActionNameHandbrake
	handbrake_button.digital = IsHandbrakeDigital
	handbrake_button.on_rate = OnHandbrakeRate
	handbrake_button.off_rate = OffHandbrakeRate
	handbrake_button.maximum = MaxHandbrake
	#handbrake_button.minimum = MinHandbrake
	
	clutch_button.name = ActionNameClutch
	clutch_button.digital = IsClutchDigital
	clutch_button.on_rate = OnClutchRate
	clutch_button.off_rate = OffClutchRate
	clutch_button.maximum = MaxClutch
	#clutch_button.minimum = MinClutch

func get_steer_direction() -> float:
	return Input.get_axis(ActionNameSteerLeft, ActionNameSteerRight)

func get_steer_axis(external_analog:float = 0.0) -> float:
	var analog_axis:float = get_steer_direction()
	
	if UseAnalogSteering:
		if not is_zero_approx(external_analog):
			analog_axis = external_analog
		
		steer_axis_amount = clampf(analog_axis * SteerSensitivity, -1.0, 1.0)
		steer_axis_amount *= minf(absf(steer_axis_amount) + 0.5, 1.0)
	else:
		#the direction the player is steering to
		var steer_direction:float = signf(analog_axis)
		#if the signs don't match, these two directions are opposite, meaning we compensate
		#we do is_equal_approx because they're floats
		var should_compensate:bool = not is_equal_approx(steer_direction, signf(steer_axis_amount))
		
		if not is_zero_approx(steer_direction): #if the player is steering
			if should_compensate: #steer at compensation speeds
				steer_axis_amount += steer_direction * KeyboardCompensateSpeed
			else: #steer at normal speeds
				steer_axis_amount +=  steer_direction * KeyboardSteerSpeed
		else: #car is not steering
			if absf(steer_axis_amount) > KeyboardReturnSpeed:
				steer_axis_amount = move_toward(steer_axis_amount, 0.0, KeyboardReturnSpeed)
			else:
				steer_axis_amount = 0.0
	
	steer_axis_amount = clampf(steer_axis_amount, -1.0, 1.0)
	
	return steer_axis_amount

func get_throttle(condition:bool) -> float:
	return throttle_button.poll(condition)

func get_handbrake(condition:bool) -> float:
	return handbrake_button.poll(condition)

func get_brake(condition:bool) -> float:
	return brake_button.poll(condition)

func get_clutch(condition:bool) -> float:
	return clutch_button.poll(condition)

func is_gas_pressed(just:bool = false) -> bool:
	return throttle_button.update_press(just)

func is_handbrake_pressed(just:bool = false) -> bool:
	return handbrake_button.update_press(just)

func is_brake_pressed(just:bool = false) -> bool:
	return brake_button.update_press(just)

func is_clutch_pressed(just:bool = false) -> bool:
	return clutch_button.update_press(just)

func is_shift_up_pressed() -> bool:
	return Input.is_action_just_pressed(ActionNameShiftUp)

func is_shift_down_pressed() -> bool:
	return Input.is_action_just_pressed(ActionNameShiftDown)
