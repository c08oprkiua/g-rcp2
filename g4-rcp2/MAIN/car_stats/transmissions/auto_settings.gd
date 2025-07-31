extends ViVeTransmission

##Transmission automation settings.
##These are for Automatic, CVT and Semi-Auto transmissions; if your car is 
##a full-manual transmission, then these settings will be ignored.
class_name ViVeTransmissionAuto

## Upshift RPM (auto).
@export var shift_rpm:float = 6500.0 #0
## Downshift threshold (auto).
@export var downshift_thresh:float = 300.0 #1
## Throttle efficiency threshold (auto/dct).
@export_range(0.0, 1.0) var throt_eff_thresh:float = 0.5 #2
## Engagement rpm threshold (auto/dct/cvt).
@export var engage_rpm_thresh:float = 0.0 #3
## Engagement rpm (auto/dct/cvt).
@export var engage_rpm:float = 4000.0 #4


##Final Drive Ratio refers to the last set of gears that connect a vehicle's engine to the driving axle.
@export var FinalDriveRatio:float = 4.250
##A set of gears a vehicle's transmission has, in order from first to last. [br]
##A gear ratio is the ratio of the number of rotations of a driver gear  to the number of rotations of a driven gear .
@export var GearRatios:Array[float] = [ 3.250, 1.894, 1.259, 0.937, 0.771 ]
##The gear ratio of the reverse gear.
@export var ReverseRatio:float = 3.153
##Similar to FinalDriveRatio, but this should not relate to any real-life data. You may keep the value as it is.
@export var RatioMult:float = 9.5

#@export var AutoSettings:Array[float] = [
#6500.0, # shift rpm (auto)
#300.0, # downshift threshold (auto)
#0.5, # throttle efficiency threshold (range: 0 - 1) (auto/dct)
#0.0, # engagement rpm threshold (auto/dct/cvt)
#4000.0, # engagement rpm (auto/dct/cvt)
#]

var gear:int

var actual_gear:int

var speed_influence:float

func _transmission_callback(rpm:float) -> float:
	clutch_engage_percent = (rpm - engage_rpm_thresh * (car.gas_pedal * throt_eff_thresh + (1.0 - throt_eff_thresh)) ) / engage_rpm
	
	#if not car_controls.ShiftingAssistance == 2:
		#if shift_up_pressed:
			#shift_up_pressed = false
			#if gear < 1:
				#actual_gear += 1
		#if shift_down_pressed:
			#shift_down_pressed = false
			#if gear > ViVeTransmission.REVERSE:
				#actual_gear -= 1
	#else:
		#if gear == 0:
			#if gas_pressed:
				#shift_assist_delay -= 1
				#if shift_assist_delay < 0:
					#actual_gear = 1
			#elif brake_pressed:
				#shift_assist_delay -= 1
				#if shift_assist_delay < 0:
					#actual_gear = ViVeTransmission.REVERSE
			#else:
				#shift_assist_delay = 60
		#elif car.linear_velocity.length() < 5:
			#if not gas_pressed and gear == 1 or not brake_pressed and gear == ViVeTransmission.REVERSE:
				#shift_assist_delay = 60
				#actual_gear = 0
	
	var output_rpm:float
	
	if actual_gear == ViVeTransmission.REVERSE:
		output_rpm = ReverseRatio * car.FinalDriveRatio * car.RatioMult
	else:
		output_rpm = GearRatios[gear - 1] * car.FinalDriveRatio * car.RatioMult
	
	if actual_gear > 0:
		var last_gears_ratio:float = GearRatios[gear - 2] * car.FinalDriveRatio * car.RatioMult
		
		var shift_up:bool = false
		var shift_down:bool = false
		
		for i:ViVeWheel in car.driving_wheels:
			if (i.wv / speed_influence) > (shift_rpm * (car.gas_pedal * throt_eff_thresh + (1.0 - throt_eff_thresh))) / output_rpm:
				shift_up = true
			elif (i.wv / speed_influence) < ((shift_rpm - downshift_thresh) * (car.gas_pedal * throt_eff_thresh + (1.0 - throt_eff_thresh))) / last_gears_ratio:
				shift_down = true
		
		if shift_up:
			gear += 1
		elif shift_down:
			gear -= 1
		
		gear = clampi(gear , 1, GearRatios.size())
	else:
		gear = actual_gear
	return 0.0
