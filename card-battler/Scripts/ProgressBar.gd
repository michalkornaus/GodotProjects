extends ProgressBar

var size_y: float = 208.0
var offset = Vector2(0, 0)
var size_big = Vector2(4, 34)
var size_small = Vector2(4, 15)
var lines_array: Array[VSeparator]

func create_lines(hp: int):
	if !lines_array.is_empty():
		for line in lines_array:
			line.queue_free()
		lines_array.clear()
	var hp_float: float = float(hp)
	var segments_offset = hp_float / 10
	var small_segments: float = hp / 10
	var offset: float = fmod(segments_offset, small_segments)
	var interval: float = (size_y / small_segments) - (offset * (size_y / hp_float))
	for index: int in small_segments:
		var _index = index + 1
		if hp >= 750:
			var modulo = _index % 5
			if modulo != 0:
				continue
		elif hp < 750 && hp >= 200:
			var modulo = _index % 2
			if modulo != 0:
				continue
		var _separator: VSeparator = VSeparator.new()
		var style_line = StyleBoxLine.new()
		style_line.thickness = 2
		style_line.color = Color.BLACK
		style_line.vertical = true
		_separator.add_theme_stylebox_override("separator", style_line) 
		var remain = fmod(_index, 10)
		if remain == 0:
			_separator.size = size_big
		else:
			_separator.size = size_small
		_separator.position = Vector2((interval * _index) - 3, 2)
		lines_array.append(_separator)
		get_parent().add_child(_separator)
