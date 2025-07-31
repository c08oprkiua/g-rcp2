extends Node3D

var last_pos:Transform3D = transform
var g:Vector3 = Vector3.ZERO

var vertices:Array[Basis] = []

var del:int = 0

var wid:float = 0.125

var ran:bool = false

var inserting:bool = false
var inserting2:bool = false

var current_trail_node:ViVeWheelMark = null
var current_trail:ImmediateMesh = null
var drawers:Array[MeshInstance3D] = []

var wheel_parent:ViVeWheel = null

# i spent 5 days trying to figure out why the skids were not working properly
	# the immediate mesh resource was shared between all the skids :/
	# ok i just do this on line 84


func add_segment() -> void:
	var ppos:Transform3D = global_transform
	vertices.append(Basis(
		ppos.origin + (ppos.basis.orthonormalized() * Vector3(wid, 0, 0)),
		ppos.origin - (ppos.basis.orthonormalized() * Vector3(wid, 0, 0)),
		ppos.origin)
		)
	last_pos = ppos

func _physics_process(_delta:float) -> void:
	
#	get_parent().get_node("Camera").rotation_degrees.y += 20
	
	del -= 1
	
	for i:ViVeWheelMark in drawers:
		i.delete_wait -= 1
		if i.delete_wait < 0:
			if current_trail == i:
				current_trail = null
			i.queue_free()
			drawers.remove_at(0)
	
	if del < 0 and inserting:
		del = 5
		add_segment()


func _process(_delta:float) -> void:
	if not is_instance_valid(wheel_parent):
		wheel_parent = get_parent().get_parent()
	
	inserting = wheel_parent.slip_perc.length() > wheel_parent.grip + 20.0 and wheel_parent.is_colliding()
	
	position.y = - wheel_parent.w_size + 0.025
	wid = wheel_parent.tire_settings.Width_mm / 750.0
	
	if not inserting2 == inserting:
		inserting2 = inserting
		if inserting2:
			
			if not current_trail_node == null:
				var t:Transform3D = current_trail_node.global_transform
				remove_child(current_trail_node)
				get_tree().get_current_scene().add_child(current_trail_node)
				current_trail_node.global_transform = t
			
			vertices.clear()
			current_trail_node = $trail.duplicate()
			# we changed our node so we need to update our resource too.
			# not sure if i should use new resource or use a copy of the old one
			# but im not noticing any difference by using a new one, soo...
			current_trail_node.mesh = ImmediateMesh.new()
			current_trail = current_trail_node.mesh
			
			add_child(current_trail_node)
			drawers.append(current_trail_node)
	
	ran = true
	if (global_transform.origin - g).length_squared() > 0.01:
		look_at(g, Vector3.MODEL_TOP)
	
	g = global_transform.origin
	
	if not current_trail_node == null:
		if inserting:
			current_trail_node.delete_wait = 180
			if not vertices.is_empty():
				vertices[vertices.size() - 1].x = ((g + global_transform.basis.orthonormalized() * Vector3(wid, 0, 0)))
				vertices[vertices.size() - 1].y = ((g - global_transform.basis.orthonormalized() * Vector3(wid, 0, 0)))
				vertices[vertices.size() - 1].z = g
		
		current_trail_node.global_transform.basis = ViVeEnvironment.get_singleton().scene.global_transform.basis
		#current_trail_node.global_transform.basis = get_tree().get_current_scene().global_transform.basis
		current_trail.clear_surfaces()
		
		if not vertices.is_empty(): # check if we actually got stuff to make
			current_trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
			for i:Basis in vertices:
				current_trail.surface_add_vertex(i.x - g)
				current_trail.surface_add_vertex(i.y - g)
				current_trail.surface_add_vertex(i.x - g)
				current_trail.surface_add_vertex(i.y - g)
			current_trail.surface_end()
