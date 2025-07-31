@tool
extends Resource
##A resource for suspension values for a ViVeWheel
class_name ViVeWheelSuspension

##Spring Force.
@export var SpringStiffness:float = 47.0 #S_Stiffness
##Compression Dampening.
@export var CompressionDampening:float = 3.5 #S_Damping
##Rebound Dampening.
@export var ReboundDampening:float = 3.5 #S_ReboundDamping
##Suspension Deadzone.
@export var Deadzone:float = 0.0 #S_RestLength
##Compression Barrier.
@export var MaxCompression:float = 0.5 #S_MaxCompression
##Anti-roll Stiffness.
@export var AntiRollStiffness:float = 0.5 #AR_Stiff
##Anti-roll Reformation Rate. 
@export var AntiRollElasticity:float = 0.1 #AR_Elast
##Used in calculating suspension.
@export var InclineArea:float = 0.2
##This amplifies the effect that slopes have on suspension.
@export var ImpactForce:float = 1.5
##The rest position for the wheel, ie. where it will sit with no counter force applied.
##This is an alias for the wheel's RayCast3D.target_position, for convenience.
@export var RestPosition:float = -2.7:
	set(new_pos):
		RestPosition = new_pos
		if is_instance_valid(parent_wheel):
			parent_wheel.target_position.y = new_pos

var parent_wheel:ViVeWheel = null

signal recalculate_cache

##This gets the total suspension elasticity being applied to the wheel.
##When [sway_bar_influence] is passed in, the effects of the wheel's linked
##sway bar partner will be taken into account for the return value.
##Otherwise, this will just return [SpringStiffness].
func get_elasticity(sway_bar_influence:float = 0.0) -> float:
	return SpringStiffness * (AntiRollElasticity * sway_bar_influence + 1.0)

##This gets the total compression dampening being applied to the wheel.
##When [sway_bar_influence] is passed in, the effects of the wheel's linked
##sway bar partner will be taken into account for the return value.
##Otherwise, this will just return [CompressionDampening].
func get_compression_dampening(sway_bar_influence:float = 0.0) -> float:
	return CompressionDampening * (AntiRollStiffness * sway_bar_influence + 1.0)

##This gets the total rebound dampening being applied to the wheel.
##When [sway_bar_influence] is passed in, the effects of the wheel's linked
##sway bar partner will be taken into account for the return value.
##Otherwise, this will just return [ReboundDampening].
func get_rebound_dampening(sway_bar_influence:float = 0.0) -> float:
	return ReboundDampening * (AntiRollStiffness * sway_bar_influence + 1.0)
