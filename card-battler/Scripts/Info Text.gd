extends Label3D
var wait_time: float = 0.5
var font_size_tick: int = 0
func _ready():
	$Timer.start(wait_time)

func _process(delta):
	if font_size_tick >= 3:
		font_size -= 1
		font_size_tick = 0
	font_size_tick += 1
	position.y += delta * 1

func _on_timer_timeout():
	queue_free()
