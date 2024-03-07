extends RigidBody3D
class_name ViVeCar

var stats:ViVeCarSS = ViVeCarSS.new()

var c_pws:Array[ViVeWheel]

@export var Powered_Wheels:PackedStringArray = ["fl", "fr"]

@onready var front_left:ViVeWheel = $"fl"
@onready var front_right:ViVeWheel = $"fr"
@onready var back_left:ViVeWheel = $"rl"
@onready var back_right:ViVeWheel = $"rr"

@onready var front_wheels:Array[ViVeWheel] = [front_left, front_right]
@onready var rear_wheels:Array[ViVeWheel] = [back_left, back_right]

@export var Debug_Mode :bool = false

# controls
@export var Use_Global_Control_Settings:bool = false
@export var UseMouseSteering:bool = false
@export var UseAccelerometreSteering :bool = false
@export var SteerSensitivity:float = 1.0
@export var KeyboardSteerSpeed:float = 0.025
@export var KeyboardReturnSpeed:float = 0.05
@export var KeyboardCompensateSpeed:float = 0.1

@export var SteerAmountDecay:float = 0.015 # understeer help
@export var SteeringAssistance:float = 1.0
@export var SteeringAssistanceAngular:float = 0.12

@export var LooseSteering :bool = false #simulate rack and pinion steering physics (EXPERIMENTAL)

@export var OnThrottleRate:float = 0.2
@export var OffThrottleRate:float = 0.2

@export var OnBrakeRate:float = 0.05
@export var OffBrakeRate:float = 0.1

@export var OnHandbrakeRate:float = 0.2
@export var OffHandbrakeRate:float = 0.2

@export var OnClutchRate:float = 0.2
@export var OffClutchRate:float = 0.2

@export var MaxThrottle:float = 1.0
@export var MaxBrake:float = 1.0
@export var MaxHandbrake:float = 1.0
@export var MaxClutch:float = 1.0

@export var GearAssist:ViVeGearAssist = ViVeGearAssist.new()

@export_group("Meta")
@export var Controlled:bool = true

@export_group("Chassis")
@export var Weight:float = 900.0 # kg

@export_group("Body")
@export var LiftAngle:float = 0.1
@export var DragCoefficient:float = 0.25
@export var Downforce:float = 0.0

@export_group("Steering")
@export var AckermannPoint:float = -3.8
@export var Steer_Radius:float = 13.0

@export_group("Drivetrain")
@export var FinalDriveRatio:float = 4.250
@export var GearRatios :Array[float] = [ 3.250, 1.894, 1.259, 0.937, 0.771 ]
@export var ReverseRatio:float = 3.153
@export var RatioMult:float = 9.5
@export var StressFactor:float = 1.0
@export var GearGap:float = 60.0
@export var DSWeight:float = 150.0 # Leave this be, unless you know what you're doing.

@export_enum("Fully Manual", "Automatic", "Continuously Variable", "Semi-Auto") var TransmissionType:int = 0

enum TransmissionTypes {
	full_manual = 0,
	auto = 1,
	continuous_variable = 2,
	semi_auto = 3
}

@export var AutoSettings:Array[float] = [
6500.0, # shift rpm (auto)
300.0, # downshift threshold (auto)
0.5, # throttle efficiency threshold (range: 0 - 1) (auto/dct)
0.0, # engagement rpm threshold (auto/dct/cvt)
4000.0, # engagement rpm (auto/dct/cvt)
]

@export var CVTSettings:ViVeCVT = ViVeCVT.new()

@export_group("Stability")
@export var ABS:ViVeABS = ViVeABS.new()
@export var ESP:ViVeESP = ViVeESP.new()
@export var BTCS:ViVeBTCS = ViVeBTCS.new()
@export var TTCS:ViVeTTCS = ViVeTTCS.new()

@export_group("Differentials")
@export var Locking:float = 0.1
@export var CoastLocking:float = 0.0
@export var Preload:float = 0.0

@export var Centre_Locking:float = 0.5
@export var Centre_CoastLocking:float = 0.5
@export var Centre_Preload:float = 0.0

@export_group("Engine")
@export var RevSpeed:float = 2.0 # Flywheel lightness
@export var EngineFriction:float = 18000.0
@export var EngineDrag:float = 0.006
@export var ThrottleResponse:float = 0.5
@export var DeadRPM:float = 100.0

@export_group("ECU")
@export var RPMLimit:float = 7000.0
@export var LimiterDelay:float = 4
@export var IdleRPM:float = 800.0
@export var ThrottleLimit:float = 0.0
@export var ThrottleIdle:float = 0.25
@export var VVTRPM:float = 4500.0 # set this beyond the rev range to disable it, set it to 0 to use this vvt state permanently

@export_group("Torque normal state")
@export var torque_norm:ViVeCarTorque = ViVeCarTorque.new()

@export_group("Torque")
@export var torque_vvt:ViVeCarTorque = ViVeCarTorque.new("VVT")

@export_group("Clutch")
@export var ClutchStable:float = 0.5
@export var GearRatioRatioThreshold:float = 200.0
@export var ThresholdStable:float = 0.01
@export var ClutchGrip:float = 176.125
@export var ClutchFloatReduction:float = 27.0
@export var ClutchWobble:float = 2.5 * 0
@export var ClutchElasticity:float = 0.2 * 0
@export var WobbleRate:float = 0.0

@export_group("Forced Inductions")
@export var MaxPSI:float = 9.0 # Maximum air generated by any forced inductions
@export var EngineCompressionRatio:float = 8.0 # Piston travel distance

@export_group("Turbo")
@export var TurboEnabled:bool = false # Enables turbo
@export var TurboAmount:float = 1.0 # Turbo power multiplication.
@export var TurboSize:float = 8.0 # Higher = More turbo lag
@export var Compressor:float = 0.3 # Higher = Allows more spooling on low RPM
@export var SpoolThreshold:float = 0.1 # Range: 0 - 0.9999
@export var BlowoffRate:float = 0.14
@export var TurboEfficiency:float = 0.075 # Range: 0 - 1
@export var TurboVacuum:float = 1.0 # Performance deficiency upon turbo idle

@export_group("Supercharger")
@export var SuperchargerEnabled:bool = false # Enables supercharger
@export var SCRPMInfluence:float = 1.0
@export var BlowRate:float = 35.0
@export var SCThreshold:float = 6.0

var rpm:float = 0.0
var rpmspeed:float = 0.0
var resistancerpm:float = 0.0
var resistancedv:float = 0.0
var gear:int = 0
var limdel:float = 0.0
var actualgear:int = 0
var gearstress:float = 0.0
var throttle:float = 0.0
var cvtaccel:float = 0.0
var sassistdel:float = 0.0
var sassiststep:int = 0
var clutchin:bool = false
var gasrestricted:bool = false
var revmatch:bool = false
var gaspedal:float = 0.0
var brakepedal:float = 0.0
var clutchpedal:float = 0.0
var clutchpedalreal:float = 0.0
var steer:float = 0.0
var steer2:float = 0.0
var abspump:float = 0.0
var tcsweight:float = 0.0
var tcsflash:bool = false
var espflash:bool = false
var ratio:float = 0.0
var vvt:bool = false
var brake_allowed:float = 0.0
var readout_torque:float = 0.0

var brakeline:float = 0.0
var handbrakepull:float = 0.0
var dsweight:float = 0.0
var dsweightrun:float = 0.0
var diffspeed:float = 0.0
var diffspeedun:float = 0.0
var locked:float = 0.0
var c_locked:float = 0.0
var wv_difference:float = 0.0
var rpmforce:float = 0.0
var whinepitch:float = 0.0
var turbopsi:float = 0.0
var scrpm:float = 0.0
var boosting:float = 0.0
var rpmcs:float = 0.0
var rpmcsm:float = 0.0
var currentstable:float = 0.0
var steering_geometry:Array[float] = [0.0,0.0]
var resistance:float = 0.0
var wob:float = 0.0
var ds_weight:float = 0.0
var steer_torque:float = 0.0
var steer_velocity:float = 0.0
var drivewheels_size:float = 1.0

var steering_angles:Array[float] = []
var max_steering_angle:float = 0.0
var assistance_factor:float = 0.0

var pastvelocity:Vector3 = Vector3(0,0,0)
var gforce:Vector3 = Vector3(0,0,0)
var clock_mult:float = 1.0
var dist:float = 0.0
var stress:float = 0.0

var su:bool = false
var sd:bool = false
var gas:bool = false
var brake:bool = false
var handbrake:bool = false
var right:bool = false
var left:bool = false
var clutch:bool = false

var velocity:Vector3 = Vector3(0,0,0)
var rvelocity:Vector3 = Vector3(0,0,0)

var stalled:float = 0.0

#added in for compatibility
var SCEnabled:bool
var TEnabled:bool
var PSI:float
var RPM:float #should be identical to its little case brother

func bullet_fix() -> void:
	var offset:Vector3 = $DRAG_CENTRE.position
	stats.AckermannPoint -= offset.z
	
	for i:Node in get_children():
		i.position -= offset

func _ready() -> void:
#	bullet_fix()
	stats.rpm = stats.IdleRPM
	for i:String in Powered_Wheels:
		var wh:ViVeWheel = get_node(str(i))
		c_pws.append(wh)
	

func get_wheels() -> Array[ViVeWheel]:
	return [front_left, front_right, back_left, back_right]

func controls() -> void:
	
	var mouseposx:float = 0.0
	
	if get_viewport().size.x > 0.0:
		mouseposx = get_viewport().get_mouse_position().x / get_viewport().size.x
	
	#Tbh I don't see why these need to be divided, but...
	if UseMouseSteering:
		gas = Input.is_action_pressed("gas_mouse")
		brake = Input.is_action_pressed("brake_mouse")
		su = Input.is_action_just_pressed("shiftup_mouse")
		sd = Input.is_action_just_pressed("shiftdown_mouse")
		handbrake = Input.is_action_pressed("handbrake_mouse")
	else:
		gas = Input.is_action_pressed("gas")
		brake = Input.is_action_pressed("brake")
		su = Input.is_action_just_pressed("shiftup")
		sd = Input.is_action_just_pressed("shiftdown")
		handbrake = Input.is_action_pressed("handbrake")
	
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	
	if left:
		steer_velocity -= 0.01
	elif right:
		steer_velocity += 0.01
	
	if LooseSteering:
		steer += steer_velocity
		
		if abs(steer) > 1.0:
			steer_velocity *= -0.5
		
		for i:ViVeWheel in [front_left,front_right]:
			steer_velocity += (i.directional_force.x * 0.00125) * i.Caster
			steer_velocity -= (i.stress * 0.0025) * (atan2(abs(i.wv),1.0) * i.angle)
			
			steer_velocity += steer*(i.directional_force.z * 0.0005) * i.Caster
			
			if i.position.x>0:
				steer_velocity += i.directional_force.z * 0.0001
			else:
				steer_velocity -= i.directional_force.z * 0.0001
		
			steer_velocity /= i.stress / (i.slip_percpre * (i.slip_percpre * 100.0) + 1.0) + 1.0
	
	if Controlled:
		if GearAssist.assist_level == 2:
			if gas and not gasrestricted and not gear == -1 or brake and gear == -1 or revmatch:
				gaspedal += OnThrottleRate/clock_mult
			else:
				gaspedal -= OffThrottleRate/clock_mult
			if brake and not gear == -1 or gas and gear == -1:
				brakepedal += OnBrakeRate/clock_mult
			else:
				brakepedal -= OffBrakeRate/clock_mult
		else:
			if GearAssist.assist_level == 0:
				gasrestricted = false
				clutchin = false
				revmatch = false
			
			if gas and not gasrestricted or revmatch:
				gaspedal += OnThrottleRate/clock_mult
			else:
				gaspedal -= OffThrottleRate/clock_mult
			
			if brake:
				brakepedal += OnBrakeRate/clock_mult
			else:
				brakepedal -= OffBrakeRate/clock_mult
		
		if handbrake:
			handbrakepull += OnHandbrakeRate/clock_mult
		else:
			handbrakepull -= OffHandbrakeRate/clock_mult
		
		var siding:float = abs(velocity.x)
		
		#Based on the syntax, I'm unsure if this is doing what it "should" do...?
		if velocity.x > 0 and steer2 > 0 or velocity.x < 0 and steer2 < 0:
			siding = 0.0
			
		var going:float = velocity.z / (siding +1.0)
		if going < 0:
			going = 0
		
		if not LooseSteering:
			if UseMouseSteering:
				steer2 = (mouseposx-0.5)*2.0
				steer2 *= SteerSensitivity
				
				steer2 = clampf(steer2, -1.0, 1.0)
				
				var s:float = abs(steer2) * 1.0 + 0.5
				if s > 1:
					s = 1
				
				steer2 *= s
			elif UseAccelerometreSteering:
				steer2 = Input.get_accelerometer().x/10.0
				steer2 *= SteerSensitivity
				
				steer2 = clampf(steer2, -1.0, 1.0)
				
				var s:float = abs(steer2)*1.0 +0.5
				if s > 1:
					s = 1
				
				steer2 *= s
			
			else:
				if right:
					if steer2 > 0:
						steer2 += KeyboardSteerSpeed
					else:
						steer2 += KeyboardCompensateSpeed
				elif left:
					if steer2 < 0:
						steer2 -= KeyboardSteerSpeed
					else:
						steer2 -= KeyboardCompensateSpeed
				else:
					if steer2 > KeyboardReturnSpeed:
						steer2 -= KeyboardReturnSpeed
					elif steer2<-KeyboardReturnSpeed:
						steer2 += KeyboardReturnSpeed
					else:
						steer2 = 0.0
				
				steer2 = clampf(steer2, -1.0, 1.0)
				
			if assistance_factor > 0.0:
				var maxsteer:float = 1.0 / (going * (SteerAmountDecay / assistance_factor) + 1.0)
				
				var assist_commence:float = linear_velocity.length() / 10.0
				if assist_commence > 1.0:
					assist_commence = 1.0
				
				steer = (steer2*maxsteer) -(velocity.normalized().x*assist_commence)*(SteeringAssistance*assistance_factor) +rvelocity.y*(SteeringAssistanceAngular*assistance_factor)
			else:
				steer = steer2

func limits() -> void:
	gaspedal = clampf(gaspedal, 0.0, MaxThrottle)
	brakepedal = clampf(brakepedal, 0.0, MaxBrake)
	handbrakepull = clampf(handbrakepull, 0.0, MaxHandbrake)
	steer = clampf(steer, -1.0, 1.0)

func transmission() -> void:
	su = Input.is_action_just_pressed("shiftup") and not UseMouseSteering or Input.is_action_just_pressed("shiftup_mouse") and UseMouseSteering
	sd = Input.is_action_just_pressed("shiftdown") and not UseMouseSteering or Input.is_action_just_pressed("shiftdown_mouse") and UseMouseSteering
	
	#var clutch:bool
	clutch = Input.is_action_pressed("clutch") and not UseMouseSteering or Input.is_action_pressed("clutch_mouse") and UseMouseSteering
	if not GearAssist.assist_level == 0:
		clutch = Input.is_action_pressed("handbrake") and not UseMouseSteering or Input.is_action_pressed("handbrake_mouse") and UseMouseSteering
	clutch = not clutch
	
	if TransmissionType == 0:
		if clutch and not clutchin:
			clutchpedalreal -= OffClutchRate / clock_mult
		else:
			clutchpedalreal += OnClutchRate / clock_mult
		
		clutchpedalreal = clamp(clutchpedalreal, 0, MaxClutch)
		
		clutchpedal = 1.0 - clutchpedalreal
		
		if gear > 0:
			ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
		elif gear == -1:
			ratio = ReverseRatio*FinalDriveRatio*RatioMult
		if GearAssist.assist_level == 0:
			if su:
				su = false
				if gear < len(GearRatios):
					if gearstress < GearGap:
						actualgear += 1
			if sd:
				sd = false
				if gear > -1:
					if gearstress < GearGap:
						actualgear -= 1
		elif GearAssist.assist_level == 1:
			if rpm < GearAssist.clutch_out_RPM:
				var irga_ca:float = (GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM)
				clutchpedalreal = irga_ca * irga_ca
				if clutchpedalreal > 1.0:
					clutchpedalreal = 1.0
			else:
				if not gasrestricted and not revmatch:
					clutchin = false
			if su:
				su = false
				if gear < len(GearRatios):
					if rpm < GearAssist.clutch_out_RPM:
						actualgear += 1
					else:
						if actualgear < 1:
							actualgear += 1
							if rpm > GearAssist.clutch_out_RPM:
								clutchin = false
						else:
							if sassistdel > 0:
								actualgear += 1
							sassistdel = GearAssist.shift_delay / 2.0
							sassiststep = -4
							
							clutchin = true
							gasrestricted = true
			elif sd:
				sd = false
				if gear > -1:
					if rpm < GearAssist.input_delay:
						actualgear -= 1
					else:
						if actualgear == 0 or actualgear == 1:
							actualgear -= 1
							clutchin = false
						else:
							if sassistdel > 0:
								actualgear -= 1
							sassistdel = GearAssist.shift_delay / 2.0
							sassiststep = -2
							
							clutchin = true
							revmatch = true
							gasrestricted = false
		elif GearAssist.assist_level == 2:
			var assistshiftspeed:float = (GearAssist.upshift_RPM / ratio) * GearAssist.speed_influence
			var assistdownshiftspeed:float = (GearAssist.down_RPM / abs((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
			if gear == 0:
				if gas:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = 1
				elif brake:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = -1
				else:
					sassistdel = 60
			elif linear_velocity.length() < 5:
				if not gas and gear == 1 or not brake and gear == -1:
					sassistdel = 60
					actualgear = 0
			if sassiststep == 0:
				if rpm < GearAssist.clutch_out_RPM:
					var irga_ca:float = (GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM)
					clutchpedalreal = irga_ca * irga_ca
					if clutchpedalreal > 1.0:
						clutchpedalreal = 1.0
				else:
					clutchin = false
				if not gear == -1:
					if gear < len(GearRatios) and linear_velocity.length() > assistshiftspeed:
						sassistdel = GearAssist.shift_delay / 2.0
						sassiststep = -4
						
						clutchin = true
						gasrestricted = true
					if gear > 1 and linear_velocity.length() < assistdownshiftspeed:
						sassistdel = GearAssist.shift_delay / 2.0
						sassiststep = -2
						
						clutchin = true
						gasrestricted = false
						revmatch = true
		
		if sassiststep == -4 and sassistdel < 0:
			sassistdel = GearAssist.shift_delay / 2.0
			if gear < len(GearRatios):
				actualgear += 1
			sassiststep = -3
		elif sassiststep == -3 and sassistdel < 0:
			if rpm > GearAssist.clutch_out_RPM:
				clutchin = false
			if sassistdel < - GearAssist.input_delay:
				sassiststep = 0
				gasrestricted = false
		elif sassiststep == -2 and sassistdel < 0:
			sassiststep = 0
			if gear > -1:
				actualgear -= 1
			if rpm > GearAssist.clutch_out_RPM:
				clutchin = false
			gasrestricted = false
			revmatch = false
		gear = actualgear
	
	elif TransmissionType == 1:
		clutchpedal = (rpm - float(AutoSettings[3]) * (gaspedal * float(AutoSettings[2]) + (1.0 - float(AutoSettings[2]))) ) / float(AutoSettings[4])
		
		if not GearAssist.assist_level == 2:
			if su:
				su = false
				if gear < 1:
					actualgear += 1
			if sd:
				sd = false
				if gear > -1:
					actualgear -= 1
		else:
			if gear == 0:
				if gas:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = 1
				elif brake:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = -1
				else:
					sassistdel = 60
			elif linear_velocity.length()<5:
				if not gas and gear == 1 or not brake and gear == -1:
					sassistdel = 60
					actualgear = 0
				
		if actualgear == -1:
			ratio = ReverseRatio*FinalDriveRatio*RatioMult
		else:
			ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
		if actualgear > 0:
			var lastratio:float = GearRatios[gear - 2] * FinalDriveRatio * RatioMult
			su = false
			sd = false
			for i:ViVeWheel in c_pws:
				if (i.wv / GearAssist.speed_influence) > (float(AutoSettings[0]) * (gaspedal *float(AutoSettings[2]) + (1.0 - float(AutoSettings[2])))) / ratio:
					su = true
				elif (i.wv / GearAssist.speed_influence) < ((float(AutoSettings[0]) - float(AutoSettings[1])) * (gaspedal * float(AutoSettings[2]) + (1.0 - float(AutoSettings[2])))) / lastratio:
					sd = true
					
			if su:
				gear += 1
			elif sd:
				gear -= 1
			
			gear = clampi(gear, 1, len(GearRatios))
			
		else:
			gear = actualgear
	elif TransmissionType == 2:
		
		clutchpedal = (rpm- float(AutoSettings[3])*(gaspedal * float(AutoSettings[2]) +(1.0-float(AutoSettings[2]))) )/float(AutoSettings[4])
		
		#clutchpedal = 1
		
		if not GearAssist.assist_level == 2:
			if su:
				su = false
				if gear < 1:
					actualgear += 1
			if sd:
				sd = false
				if gear > -1:
					actualgear -= 1
		else:
			if gear == 0:
				if gas:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = 1
				elif brake:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = -1
				else:
					sassistdel = 60
			elif linear_velocity.length()<5:
				if not gas and gear == 1 or not brake and gear == -1:
					sassistdel = 60
					actualgear = 0
		
		gear = actualgear
		var wv:float = 0.0
		
		for i:ViVeWheel in c_pws:
			wv += i.wv / len(c_pws)
		
		cvtaccel -= (cvtaccel - (gaspedal * CVTSettings.throt_eff_thresh + (1.0 - CVTSettings.throt_eff_thresh))) * CVTSettings.accel_rate
		
		var a:float = CVTSettings.iteration_3 / ((abs(wv) / 10.0) * cvtaccel + 1.0)
		
		a = maxf(a, CVTSettings.iteration_4)
		
		ratio = (CVTSettings.iteration_1 * 10000000.0) / (abs(wv) * (rpm * a) + 1.0)
		
		
		ratio = minf(ratio, CVTSettings.iteration_2)
	
	elif TransmissionType == 3:
		clutchpedal = (rpm- float(AutoSettings[3]) * (gaspedal*float(AutoSettings[2]) + (1.0-float(AutoSettings[2]))) ) /float(AutoSettings[4])
		
		if gear > 0:
			ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
		elif gear == -1:
			ratio = ReverseRatio * FinalDriveRatio*RatioMult
		
		if GearAssist.assist_level < 2:
			if su:
				su = false
				if gear < len(GearRatios):
					actualgear += 1
			if sd:
				sd = false
				if gear > -1:
					actualgear -= 1
		else:
			var assistshiftspeed:float = (GearAssist.upshift_RPM / ratio) * GearAssist.speed_influence
			var assistdownshiftspeed:float = (GearAssist.down_RPM / abs((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
			if gear == 0:
				if gas:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = 1
				elif brake:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = -1
				else:
					sassistdel = 60
			elif linear_velocity.length()<5:
				if not gas and gear == 1 or not brake and gear == -1:
					sassistdel = 60
					actualgear = 0
			if sassiststep == 0:
				if not gear == -1:
					if gear < len(GearRatios) and linear_velocity.length() > assistshiftspeed:
						actualgear += 1
					if gear > 1 and linear_velocity.length() < assistdownshiftspeed:
						actualgear -= 1
		
		gear = actualgear
	
	clutchpedal = clampf(clutchpedal, 0.0, 1.0)

func full_manual_transmission():
		if clutch and not clutchin:
			clutchpedalreal -= OffClutchRate / clock_mult
		else:
			clutchpedalreal += OnClutchRate / clock_mult
		
		clutchpedalreal = clamp(clutchpedalreal, 0, MaxClutch)
		
		clutchpedal = 1.0 - clutchpedalreal
		
		
		if gear > 0:
			ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
		elif gear == -1:
			ratio = ReverseRatio * FinalDriveRatio * RatioMult
		
		match GearAssist.assist_level:
			0:
				if su:
					su = false
					if gear < len(GearRatios):
						if gearstress < GearGap:
							actualgear += 1
				if sd:
					sd = false
					if gear > -1:
						if gearstress < GearGap:
							actualgear -= 1
			1:
				if rpm < GearAssist.clutch_out_RPM:
					var irga_ca:float = (GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM)
					clutchpedalreal = irga_ca * irga_ca
					if clutchpedalreal > 1.0:
						clutchpedalreal = 1.0
				else:
					if not gasrestricted and not revmatch:
						clutchin = false
				if su:
					su = false
					if gear < len(GearRatios):
						if rpm < GearAssist.clutch_out_RPM:
							actualgear += 1
						else:
							if actualgear < 1:
								actualgear += 1
								if rpm > GearAssist.clutch_out_RPM:
									clutchin = false
							else:
								if sassistdel > 0:
									actualgear += 1
								sassistdel = GearAssist.shift_delay / 2.0
								sassiststep = -4
								
								clutchin = true
								gasrestricted = true
				elif sd:
					sd = false
					if gear > -1:
						if rpm < GearAssist.input_delay:
							actualgear -= 1
						else:
							if actualgear == 0 or actualgear == 1:
								actualgear -= 1
								clutchin = false
							else:
								if sassistdel > 0:
									actualgear -= 1
								sassistdel = GearAssist.shift_delay / 2.0
								sassiststep = -2
								
								clutchin = true
								revmatch = true
								gasrestricted = false
			2:
				pass

		if GearAssist.assist_level == 2:
			var assistshiftspeed:float = (GearAssist.upshift_RPM / ratio) * GearAssist.speed_influence
			var assistdownshiftspeed:float = (GearAssist.down_RPM / abs((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
			if gear == 0:
				if gas:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = 1
				elif brake:
					sassistdel -= 1
					if sassistdel < 0:
						actualgear = -1
				else:
					sassistdel = 60
			elif linear_velocity.length() < 5:
				if not gas and gear == 1 or not brake and gear == -1:
					sassistdel = 60
					actualgear = 0
			if sassiststep == 0:
				if rpm < GearAssist.clutch_out_RPM:
					var irga_ca:float = (GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM)
					clutchpedalreal = irga_ca * irga_ca
					if clutchpedalreal > 1.0:
						clutchpedalreal = 1.0
				else:
					clutchin = false
				if not gear == -1:
					if gear < len(GearRatios) and linear_velocity.length() > assistshiftspeed:
						sassistdel = GearAssist.shift_delay / 2.0
						sassiststep = -4
						
						clutchin = true
						gasrestricted = true
					if gear > 1 and linear_velocity.length() < assistdownshiftspeed:
						sassistdel = GearAssist.shift_delay / 2.0
						sassiststep = -2
						
						clutchin = true
						gasrestricted = false
						revmatch = true
		
		if sassiststep == -4 and sassistdel < 0:
			sassistdel = GearAssist.shift_delay / 2.0
			if gear < len(GearRatios):
				actualgear += 1
			sassiststep = -3
		elif sassiststep == -3 and sassistdel < 0:
			if rpm > GearAssist.clutch_out_RPM:
				clutchin = false
			if sassistdel < - GearAssist.input_delay:
				sassiststep = 0
				gasrestricted = false
		elif sassiststep == -2 and sassistdel < 0:
			sassiststep = 0
			if gear > -1:
				actualgear -= 1
			if rpm > GearAssist.clutch_out_RPM:
				clutchin = false
			gasrestricted = false
			revmatch = false
		gear = actualgear

func drivetrain() -> void:
	
		rpmcsm -= (rpmcs - resistance)
	
		rpmcs += rpmcsm * ClutchElasticity
		
		rpmcs -= rpmcs * (1.0 - clutchpedal)
		
		wob = ClutchWobble * clutchpedal
		
		wob *= ratio * WobbleRate
		
		rpmcs -= (rpmcs - resistance) * (1.0 / (wob + 1.0))
		
#		torquereadout = multivariate(RiseRPM,TorqueRise,BuildUpTorque,EngineFriction,EngineDrag,OffsetTorque,rpm,DeclineRPM,DeclineRate,FloatRate,turbopsi,TurboAmount,EngineCompressionRatio,TurboEnabled,VVTRPM,VVT_BuildUpTorque,VVT_TorqueRise,VVT_RiseRPM,VVT_OffsetTorque,VVT_FloatRate,VVT_DeclineRPM,VVT_DeclineRate,SuperchargerEnabled,SCRPMInfluence,BlowRate,SCThreshold)
		if gear < 0:
			rpm -= ((rpmcs * 1.0) / clock_mult) * (RevSpeed / 1.475)
		else:
			rpm += ((rpmcs * 1.0) / clock_mult) * (RevSpeed / 1.475)
		
		if "": #...what-
			rpm = 7000.0
			Locking = 0.0
			CoastLocking = 0.0
			Centre_Locking = 0.0
			Centre_CoastLocking = 0.0
			Preload = 1.0
			Centre_Preload = 1.0
			ClutchFloatReduction = 0.0
		
		gearstress = (abs(resistance) * StressFactor) * clutchpedal
		var stabled:float = ratio * 0.9 + 0.1
		ds_weight = DSWeight / stabled
		
		whinepitch = abs(rpm / ratio) * 1.5
		
		if resistance > 0.0:
			locked = abs(resistance/ds_weight) * (CoastLocking/100.0) + Preload
		else:
			locked = abs(resistance/ds_weight) * (Locking/100.0) + Preload
		
		locked = clampf(locked, 0.0, 1.0)
		
		
		if wv_difference > 0.0:
			c_locked = abs(wv_difference) * (Centre_CoastLocking / 10.0) + Centre_Preload
		else:
			c_locked = abs(wv_difference) * (Centre_Locking / 10.0) + Centre_Preload
		if c_locked < 0.0 or len(c_pws) < 4:
			c_locked = 0.0
		c_locked = minf(c_locked, 1.0)
		
		var maxd:ViVeWheel = VitaVehicleSimulation.fastest_wheel(c_pws)
		#var mind = VitaVehicleSimulation.slowest_wheel(c_pws)
		var what:float = 0.0
		
		var floatreduction:float = ClutchFloatReduction
		
		if dsweightrun > 0.0:
			floatreduction = ClutchFloatReduction / dsweightrun
		else:
			floatreduction = 0.0
		
		var stabling:float = - (GearRatioRatioThreshold - ratio * drivewheels_size) * ThresholdStable
		stabling = maxf(stabling, 0.0)
		
		currentstable = ClutchStable + stabling
		currentstable *= (RevSpeed/1.475)
		
		if dsweightrun > 0.0:
			what = (rpm -(((rpmforce * floatreduction) * pow(currentstable, 1.0)) / (ds_weight / dsweightrun)))
		else:
			what = rpm
			
		if gear < 0.0:
			dist = maxd.wv + what / ratio
		else:
			dist = maxd.wv - what / ratio
		
		dist *= (clutchpedal * clutchpedal)
		
		if gear == 0:
			dist *= 0.0
		
		wv_difference = 0.0
		drivewheels_size = 0.0
		for i in c_pws:
			drivewheels_size += i.w_size/len(c_pws)
			i.c_p = i.W_PowerBias
			wv_difference += ((i.wv - what / ratio) / (len(c_pws))) * (clutchpedal * clutchpedal)
			if gear < 0:
				i.dist = dist * (1 - c_locked) + (i.wv + what / ratio) * c_locked
			else:
				i.dist = dist * (1 - c_locked) + (i.wv - what / ratio) * c_locked
			if gear == 0:
				i.dist *= 0.0
		GearAssist.speed_influence = drivewheels_size
		resistance = 0.0
		dsweightrun = dsweight
		dsweight = 0.0
		tcsweight = 0.0
		stress = 0.0

func aero() -> void:
	var drag:float = DragCoefficient
	var df:float = Downforce
	
#	var veloc = global_transform.basis.orthonormalized().xform_inv(linear_velocity)
	var veloc:Vector3 = global_transform.basis.orthonormalized().transposed() * (linear_velocity)
	
#	var torq = global_transform.basis.orthonormalized().xform_inv(Vector3(1,0,0))
	#var torq = global_transform.basis.orthonormalized().transposed() * (Vector3(1,0,0))
	
#	apply_torque_impulse(global_transform.basis.orthonormalized().xform( Vector3(((-veloc.length()*0.3)*LiftAngle),0,0)  ) )
	apply_torque_impulse(global_transform.basis.orthonormalized() * ( Vector3(((-veloc.length() * 0.3) * LiftAngle), 0, 0) ) )
	
	var vx:float = veloc.x * 0.15
	var vy:float = veloc.z * 0.15
	var vz:float = veloc.y * 0.15
	var vl:float = veloc.length() * 0.15
	
#	var forc = global_transform.basis.orthonormalized().xform(Vector3(1,0,0))*(-vx*drag)
	var forc:Vector3 = global_transform.basis.orthonormalized() * (Vector3(1, 0, 0)) * (- vx * drag)
#	forc += global_transform.basis.orthonormalized().xform(Vector3(0,0,1))*(-vy*drag)
	forc += global_transform.basis.orthonormalized() * (Vector3(0, 0, 1)) * (- vy * drag)
#	forc += global_transform.basis.orthonormalized().xform(Vector3(0,1,0))*(-vl*df -vz*drag)
	forc += global_transform.basis.orthonormalized() * (Vector3(0, 1, 0)) * (- vl * df - vz * drag)
	
	if has_node("DRAG_CENTRE"):
#		apply_impulse(global_transform.basis.orthonormalized().xform($DRAG_CENTRE.position),forc)
		apply_impulse(forc, global_transform.basis.orthonormalized() * ($DRAG_CENTRE.position))
	else:
		apply_central_impulse(forc)

func _physics_process(_delta:float) -> void:
	
	if len(steering_angles) > 0:
		max_steering_angle = 0.0
		for i:float in steering_angles:
			max_steering_angle = maxf(max_steering_angle,i)
		
		assistance_factor = 90.0 / max_steering_angle
	steering_angles = []
	
	if Use_Global_Control_Settings:
		UseMouseSteering = VitaVehicleSimulation.UseMouseSteering
		UseAccelerometreSteering = VitaVehicleSimulation.UseAccelerometreSteering
		SteerSensitivity = VitaVehicleSimulation.SteerAmountDecay
		KeyboardSteerSpeed = VitaVehicleSimulation.KeyboardSteerSpeed
		KeyboardReturnSpeed = VitaVehicleSimulation.KeyboardReturnSpeed
		KeyboardCompensateSpeed = VitaVehicleSimulation.KeyboardCompensateSpeed
		
		SteerAmountDecay = VitaVehicleSimulation.SteerAmountDecay
		SteeringAssistance = VitaVehicleSimulation.SteeringAssistance
		SteeringAssistanceAngular = VitaVehicleSimulation.SteeringAssistanceAngular
		
		GearAssist.assist_level = VitaVehicleSimulation.GearAssistant
	
	if Input.is_action_just_pressed("toggle_debug_mode"):
		if Debug_Mode:
			Debug_Mode = false
		else:
			Debug_Mode = true
	
#	velocity = global_transform.basis.orthonormalized().xform_inv(linear_velocity)
	velocity = global_transform.basis.orthonormalized().transposed() * (linear_velocity)
#	rvelocity = global_transform.basis.orthonormalized().xform_inv(angular_velocity)
	rvelocity = global_transform.basis.orthonormalized().transposed() * (angular_velocity)
	
	#if not mass == Weight / 10.0:
	#	mass = Weight/10.0
	mass = Weight / 10.0
	aero()
	
	gforce = (linear_velocity - pastvelocity) * ((0.30592 / 9.806) * 60.0)
	pastvelocity = linear_velocity
	
#	gforce = global_transform.basis.orthonormalized().xform_inv(gforce)
	gforce = global_transform.basis.orthonormalized().transposed() * (gforce)
	
	controls()
	
	ratio = 10.0
	
	sassistdel -= 1

	transmission()
	
	limits()
	
	var steeroutput:float = steer
	
	var uhh:float = (max_steering_angle / 90.0) * (max_steering_angle / 90.0)
	uhh *= 0.5
	steeroutput *= abs(steer) * (uhh) + (1.0 - uhh)
	
	if abs(steeroutput) > 0.0:
		steering_geometry = [-Steer_Radius / steeroutput, AckermannPoint]
	
	abspump -= 1    
	
	if abspump < 0:
		brake_allowed += ABS.pump_force
	else:
		brake_allowed -= ABS.pump_force
	
	brake_allowed = clampf(brake_allowed, 0.0, 1.0)
	
	brakeline = brakepedal * brake_allowed
	
	brakeline = maxf(brakeline, 0.0)
	
	limdel -= 1
	
	if limdel < 0:
		throttle -= (throttle - (gaspedal / (tcsweight * clutchpedal + 1.0))) * (ThrottleResponse / clock_mult)
	else:
		throttle -= throttle * (ThrottleResponse / clock_mult)
	
	if rpm > RPMLimit:
		if throttle > ThrottleLimit:
			throttle = ThrottleLimit
			limdel = LimiterDelay
	elif rpm < IdleRPM:
		if throttle < ThrottleIdle:
			throttle = ThrottleIdle
	
	#var stab:float = 300.0
	var thr:float = 0.0
	
	if TurboEnabled:
		thr = (throttle-SpoolThreshold)/(1-SpoolThreshold)
		
		if boosting > thr:
			boosting = thr
		else:
			boosting -= (boosting - thr) * TurboEfficiency
		 
		turbopsi += (boosting * rpm) / ((TurboSize / Compressor) * 60.9)
		
		turbopsi -= turbopsi * BlowoffRate
		
		turbopsi = minf(turbopsi, MaxPSI)
		
		turbopsi = maxf(turbopsi, -TurboVacuum)
	
	elif SuperchargerEnabled:
		scrpm = rpm * SCRPMInfluence
		turbopsi = (scrpm / 10000.0) * BlowRate - SCThreshold
		
		turbopsi = clampf(turbopsi, 0.0, MaxPSI)
	
	else:
		turbopsi = 0.0
	
	vvt = rpm > VVTRPM
	
	var torque:float = 0.0
	
	var torque_local:ViVeCarTorque
	if vvt:
		torque_local = torque_vvt
	else:
		torque_local = torque_norm
	
	var f:float = rpm - torque_local.RiseRPM
	f = maxf(f, 0.0)
	
	torque = (rpm * torque_local.BuildUpTorque + torque_local.OffsetTorque + (f * f) * (torque_local.TorqueRise / 10000000.0)) * throttle
	torque += ( (turbopsi * TurboAmount) * (EngineCompressionRatio * 0.609) )
	
	var j:float = rpm - torque_local.DeclineRPM
	j = maxf(j, 0.0)
	
	torque /= (j * (j * torque_local.DeclineSharpness + (1.0 - torque_local.DeclineSharpness))) * (torque_local.DeclineRate / 10000000.0) + 1.0
	torque /= abs(rpm * abs(rpm)) * (torque_local.FloatRate / 10000000.0) + 1.0
	
	rpmforce = (rpm / (abs(rpm * abs(rpm)) / (EngineFriction / clock_mult) + 1.0)) * 1.0
	if rpm < DeadRPM:
		torque = 0.0
		rpmforce /= 5.0
		stalled = 1.0 - rpm / DeadRPM
	else:
		stalled = 0.0
	rpmforce += (rpm * (EngineDrag / clock_mult)) * 1.0
	rpmforce -= (torque / clock_mult) * 1.0
	rpm -= rpmforce * RevSpeed
	
	drivetrain()

var front_load:float = 0.0
var total:float = 0.0

var weight_dist:Array[float] = [0.0,0.0]

func _process(_delta:float) -> void:
	if Debug_Mode:
		front_wheels = []
		rear_wheels = []
		#Why is this run?
		for i:ViVeWheel in get_wheels():
			if i.position.z > 0:
				front_wheels.append(i)
			else:
				rear_wheels.append(i)
		
		front_load = 0.0
		total = 0.0
		
		for f:ViVeWheel in front_wheels:
			front_load += f.directional_force.y
			total += f.directional_force.y
		for r:ViVeWheel in rear_wheels:
			front_load -= r.directional_force.y
			total += r.directional_force.y
		
		if total > 0:
			weight_dist[0] = (front_load / total) * 0.5 + 0.5
			weight_dist[1] = 1.0 - weight_dist[0]
	
	#readout_torque = VitaVehicleSimulation.multivariate(RiseRPM,TorqueRise,BuildUpTorque,EngineFriction,EngineDrag,OffsetTorque,rpm,DeclineRPM,DeclineRate,FloatRate,MaxPSI,TurboAmount,EngineCompressionRatio,TurboEnabled,VVTRPM,VVT_BuildUpTorque,VVT_TorqueRise,VVT_RiseRPM,VVT_OffsetTorque,VVT_FloatRate,VVT_DeclineRPM,VVT_DeclineRate,SuperchargerEnabled,SCRPMInfluence,BlowRate,SCThreshold,DeclineSharpness,VVT_DeclineSharpness)
	readout_torque = VitaVehicleSimulation.multivariate(self)
