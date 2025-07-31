@tool
extends Resource

##An axle for a [ViVeWheel].
class_name ViVeWheelAxle

#these are originally from ViVeWheel, abstracted for convenience

##Axle vertical mounting position.
##This is an additional downwards offset applied to the axle.
@export var Vertical_Mount:float = 1.15 #A_Geometry1
##Camber gain factor.
@export var Camber_Gain:float = 1.0 #A_Geometry2.
##Axle lateral mounting position, affecting camber gain. 
##High negative values may mount them outside.
@export var Lateral_Mount_Pos:float = 0.0 #A_Geometry3
##Related to the camber.
@export var Geometry4:float = 0.0
