extends Node3D

@export var backfire_FuelRichness:float = 0.2
@export var backfire_FuelDecay:float = 0.1
@export var backfire_Air:float = 0.02
@export var backfire_BackfirePrevention:float = 0.1
@export var backfire_BackfireThreshold:float = 1.0
@export var backfire_BackfireRate:float = 1.0
@export var backfire_Volume:float = 0.5

@export var WhinePitch:float = 4 #could be an int?
@export var WhineVolume:float = 0.4
 
@export var BlowOffBounceSpeed:float = 0.0
@export var BlowOffWhineReduction:float = 1.0
@export var BlowDamping:float = 0.25
@export var BlowOffVolume:float = 0.5
@export var BlowOffVolume2:float = 0.5
@export var BlowOffPitch1:float = 0.5
@export var BlowOffPitch2:float = 1.0
@export var MaxWhinePitch:float = 1.8
@export var SpoolVolume:float = 0.5
@export var SpoolPitch:float = 0.5
@export var BlowPitch:float = 1.0
@export var TurboNoiseRPMAffection:float = 0.25

@export var engine_sound:NodePath = NodePath("../engine_sound")
var engine_node:ViVeCarEngineSFX
@export var exhaust_particles :Array[CPUParticles3D] = []

@export var volume:float = 0.25
var blow_psi:float = 0.0
var blow_inertia:float = 0.0

var fueltrace:float = 0.0
var air:float = 0.0
var rand:float = 0.0

var car:ViVeCar = get_parent()

@onready var scwhine:AudioStreamPlayer3D = $"scwhine"
@onready var whistle:AudioStreamPlayer3D = $"whistle"
@onready var blow:AudioStreamPlayer3D = $"blow"
@onready var backfire:AudioStreamPlayer3D = $"backfire"
@onready var spool:AudioStreamPlayer3D = $"spool"
@onready var whigh:AudioStreamPlayer3D = $"whigh"
@onready var wlow:AudioStreamPlayer3D = $"wlow"

func play() -> void:
	blow.stop()
	spool.stop()
	whistle.stop()
	scwhine.stop()
	whigh.play()
	wlow.play()
	if car.TurboEnabled:
		blow.play()
		spool.play()
		whistle.play()
	if car.SuperchargerEnabled:
		scwhine.play()

func stop() -> void:
	for i:AudioStreamPlayer3D in get_children():
		i.stop()

func _ready() -> void:
	car = get_parent_node_3d()
	play()

func _physics_process(_delta:float) -> void:
	fueltrace += (car.throttle) * backfire_FuelRichness
	air = (car.throttle * car.rpm) * backfire_Air + car.turbo_psi
	
	fueltrace = maxf(fueltrace - (fueltrace * backfire_FuelDecay), 0.0)
	
	if not is_instance_valid(engine_node):
		engine_node = get_node(engine_sound)
	else:
		engine_node.pitch_influence -= (engine_node.pitch_influence - 1.0) * 0.5
	
	if car.rpm > car.DeadRPM:
		if fueltrace > randf_range(air * backfire_BackfirePrevention + backfire_BackfireThreshold, 60.0 / backfire_BackfireRate):
			rand = 0.1
			var ft:float = maxf(fueltrace, 10.0)
			
			backfire.play()
			var yed:float = maxf(1.5 - ft * 0.1, 1.0)
			
			backfire.pitch_scale = randf_range(yed * 1.25, yed * 1.5)
			backfire.volume_db = linear_to_db((ft * backfire_Volume) * 0.1)
			backfire.max_db = backfire.volume_db
			engine_node.pitch_influence = 0.5
			for i:CPUParticles3D in exhaust_particles:
				i.emitting = true
		else:
			for i:CPUParticles3D in exhaust_particles:
				i.emitting = false
	
	var wh:float = maxf((absf(car.rpm / 10000.0) * WhinePitch), 0.0)
	
	if wh > 0.01:
		scwhine.volume_db = linear_to_db(WhineVolume * volume)
		scwhine.max_db = scwhine.volume_db
		scwhine.pitch_scale = wh
	else:
		scwhine.volume_db = linear_to_db(0.0)
	
	var blowvol:float = clampf(blow_psi - car.turbo_psi, 0.0, 1.0)
	blow_psi -= (blow_psi - car.turbo_psi) * BlowOffWhineReduction
	blow_inertia += blow_psi - car.turbo_psi
	blow_inertia -= (blow_inertia - (blow_psi - car.turbo_psi)) * BlowDamping
	blow_psi -= blow_inertia * BlowOffBounceSpeed
	
	blow_psi = minf(blow_psi, car.MaxPSI)
	
	var spoolvol:float = clampf(car.turbo_psi / 10.0, 0.0, 1.0)
	
	spoolvol += (absf(car.rpm) * (TurboNoiseRPMAffection / 1000.0)) * spoolvol
	
	blow.volume_db = maxf(linear_to_db(volume * (blowvol * BlowOffVolume2)), -60.0)
	spool.volume_db = maxf(linear_to_db(volume * (spoolvol * SpoolVolume)), -60.0)
	
	blow.max_db = blow.volume_db
	spool.max_db = spool.volume_db
	
	#Take (blowvol * BlowOffVolume), clamp it between 0 and 1, convert to db, make sure it's above -60.0 db
	whistle.volume_db = maxf(linear_to_db(clampf(blowvol * BlowOffVolume, 0.0, 1.0) ), -60.0)
	whistle.max_db = whistle.volume_db
	
	var wps:float = 1.0
	if car.turbo_psi > 0.0:
		wps = blowvol * BlowOffPitch2 + car.turbo_psi * 0.05 + BlowOffPitch1
	else:
		wps = blowvol * BlowOffPitch2 + BlowOffPitch1
	
	whistle.pitch_scale =  minf(wps, MaxWhinePitch)
	spool.pitch_scale = SpoolPitch + spoolvol * 0.5
	blow.pitch_scale = BlowPitch
	
	var h:float = clampf(car.whine_pitch / 200.0, 0.5, 1.0)
	
	var wlow_local:float = linear_to_db(((car.gear_stress * car.GearGap) / 160000.0) * ((1.0 - h) * 0.5))
	wlow_local = maxf(wlow_local, -60.0)
	
	wlow.volume_db = wlow_local
	wlow.max_db = wlow.volume_db
	if car.whine_pitch / 50.0 > 0.0001:
		wlow.pitch_scale = car.whine_pitch / 50.0
	var whigh_local:float = linear_to_db(((car.gear_stress * car.GearGap) / 80000.0) * 0.5)
	
	whigh.volume_db = maxf(whigh_local, -60.0)
	whigh.max_db = whigh.volume_db
	if car.whine_pitch / 100.0 > 0.0001:
		whigh.pitch_scale = car.whine_pitch / 100.0
