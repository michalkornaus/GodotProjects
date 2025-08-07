extends PathFollow3D
var moving_speed: float
var previous_progress: float
func _process(delta):
	previous_progress = progress
	progress += moving_speed * delta
	# Loop is completed on large difference
	if previous_progress - progress >= 1:
		var mat_mesh = StandardMaterial3D.new()
		mat_mesh.albedo_color = _pick_color()
		get_node("MeshInstance3D").material_override = mat_mesh

func _pick_color():
	var random_color = Color(randf(),randf(),randf(),1)
	return random_color
