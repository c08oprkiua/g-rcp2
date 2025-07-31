extends ViVeTransmission
##A Continuously Variable Transmission in VitaVehicle.
class_name ViVeCVT
## Throttle efficiency threshold.
@export_range(0.0, 1.0) var throt_eff_thresh:float = 0.75 #0
## Acceleration rate.
@export_range(0.0, 1.0) var accel_rate:float = 0.025 #1
## Iteration 1. Higher = higher RPM.
@export var iteration_1:float = 0.9 #2
## Iteration 2. Higher = better acceleration from standstill but unstable.
@export var iteration_2:float = 500.0 #3
## Iteration 3. Higher = longer it takes to "lock" the rpm.
@export var iteration_3:float = 2.0 #4
## Iteration 4. Keep it over 0.1.
@export var iteration_4: float = 0.2 #5

#auto settings

@export var engage_rpm_thresh:float

@export var engage_rpm:float

@export var a_throt_eff_thresh:float

var cvt_accel:float

func _transmission_callback(rpm:float) -> float:
	clutch_engage_percent = (rpm - engage_rpm_thresh * (car.gas_pedal * a_throt_eff_thresh + (1.0 - a_throt_eff_thresh)) ) / engage_rpm
	
	#clutch_engage_percent = 1
	
#	if not car.car_controls.ShiftingAssistance == 2:
#		if shift_up_pressed:
#			shift_up_pressed = false
#			if gear < 1:
#				actual_gear += 1
#		if shift_down_pressed:
#			shift_down_pressed = false
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
			#if not car.gas_pressed and gear == 1 or not car.brake_pressed and gear == ViVeTransmission.REVERSE:
				#shift_assist_delay = 60
				#actual_gear = 0
	#
	#gear = actual_gear
	var all_wheels_velocity:float = 0.0
	
	for wheel:ViVeWheel in car.driving_wheels:
		all_wheels_velocity += wheel.wv #/ driving_wheels.size()
	
	all_wheels_velocity /= car.driving_wheels.size()
	
	cvt_accel -= (cvt_accel - (car.gas_pedal * throt_eff_thresh + (1.0 - throt_eff_thresh))) * accel_rate
	
	var a:float = maxf(iteration_3 / ((absf(all_wheels_velocity) / 10.0) * cvt_accel + 1.0), iteration_4)
	
	var output_rpm:float
	output_rpm = (iteration_1 * 10000000.0) / (absf(all_wheels_velocity) * (rpm * a) + 1.0)
	
	output_rpm = minf(output_rpm, iteration_2)
	
	return output_rpm
