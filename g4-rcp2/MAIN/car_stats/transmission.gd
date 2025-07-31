extends Resource
##This is the base class that represents a transmission of a [ViVeCar].
##This is a base type, and is NOT for direct use in a [ViVeCar].
##Please consult VitaVehicle's documentation on what a transmission implementation needs in order to work.
class_name ViVeTransmission

enum {
	##The transmission is in neutral.
	NEUTRAL = 0,
	##The transmission is in reverse.
	REVERSE = -1,
	##The transmission is in "drive" (no specific gear, such as for an automatic)
	DRIVE = -2,
}

##The [ViVeCar] that this transmission is in.
var car:ViVeCar = null

##This is how engaged the clutch plate is to the flywheel.
var clutch_engage_percent:float = 0.0

##This is a function called by the [ViVeCar] when transmission calculations are to occur.
##Overwriting this function allows for custom behavior to be defined for the transmission.
##[br]
##crankshaft_rpm is the raw RPM coming from the engine. The return value of this function 
##is the RPM as affected by the transmission, ie. the driveshaft RPM.
func _transmission_callback(rpm:float) -> float:
	return rpm

##Called when the engine wants to know what gear the car is in.
##This has three special numbers:
##[br]0, which means the car is in neutral.
##[br]-1, which means the car is in reverse.
##[br]-2, which means the car is generically going forward ("in drive"), with no specific gear.
func _get_current_gear() -> int:
	return NEUTRAL
