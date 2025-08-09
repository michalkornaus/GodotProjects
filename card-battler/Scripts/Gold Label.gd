extends Label3D
func hide_timer(time: float):
	await get_tree().create_timer(time).timeout
	visible = false
func destroy_timer(time: float):
	await get_tree().create_timer(time).timeout
	queue_free()
