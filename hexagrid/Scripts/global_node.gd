extends Node
signal score_changed(new_value)
var score: int:
	get:
		return score
	set(value):
		score = value
		score_changed.emit(value)
var level_score: int = 300
## Increase difficulty level (new color) every 100 points
var difficulty_level: int = 0
var is_reseting: bool = false
func reset_current_level():
	if is_reseting: 
		return
	is_reseting = true
	await get_tree().create_timer(2).timeout
	score = 0
	difficulty_level = 0
	get_tree().reload_current_scene()
	is_reseting = false
	
