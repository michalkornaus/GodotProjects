extends StaticBody3D

var start_pos: Vector3
var end_pos: Vector3
var target_node: Node3D
var projectile_speed: float = 5.0

@onready var mesh_instance: GeometryInstance3D = $ProjectileMeshInstance

# Called when the node enters the scene tree for the first time.
func init(color: Color):
	mesh_instance.material_override.albedo_color = color
	mesh_instance.visible = true
	global_position = start_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(target_node):
		end_pos = target_node.global_position + Vector3(0, 0.6, 0)
		global_position = lerp(global_position, end_pos, delta * projectile_speed)
		if end_pos.distance_to(global_position) < 0.5:
			queue_free()
	else:
		queue_free()
