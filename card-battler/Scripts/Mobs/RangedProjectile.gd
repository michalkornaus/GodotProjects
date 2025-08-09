extends PathFollow3D

var target_node: Node3D
var projectile_speed: float = 2.5

@onready var mesh_instance: GeometryInstance3D = $StaticBody3D/ProjectileMeshInstance

# Called when the node enters the scene tree for the first time.
func init(color: Color):
	mesh_instance.material_override.albedo_color = color
	mesh_instance.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(target_node):
		progress_ratio += delta * projectile_speed
		if progress_ratio > 0.9:
			queue_free()
	else:
		queue_free()
