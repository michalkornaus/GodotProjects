extends PathFollow3D
var moving_speed: float
var previous_progress: float
var current_index: int
func _process(delta):
	previous_progress = progress
	progress += moving_speed * delta
	if previous_progress - progress >= 1:
		get_parent().get_parent()._modify_terrain(self, current_index)
