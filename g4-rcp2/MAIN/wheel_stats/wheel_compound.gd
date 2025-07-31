@tool
extends Resource

##Compound settings for tires.
class_name TyreCompoundSettings

##@experimental Optimum tyre temperature for maximum grip effect. (Currently isn't used).
@export var OptimumTemp:float = 50.0
##This is a multiplier of how stiff the tyre is.
@export var Stiffness:float = 1.0
##This value directly counters slip that the tyre experiences.
@export var TractionFactor:float = 1.0:
	set(new_factor):
		TractionFactor = new_factor
		emit_changed()

@export var DeformFactor:float = 1.0
##This is affected by the fore friction of the ground.
@export var ForeFriction:float = 0.125

@export var ForeStiffness:float = 0.0

@export var GroundDragAffection:float = 1.0
##Increase in grip on loose surfaces.
@export var BuildupAffection:float = 1.0
##@experimental Tyre Cooldown Rate. (Currently isn't used).
@export var CoolRate:float = 0.000075
