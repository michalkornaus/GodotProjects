extends Path3D
var radius: float = 1.5
## 360 -> 10 degrees between points = 36 points, but 0 and 36 point overlap
var points: int = 37
func _ready():
	var angle = 0
	var angle_diff = 360 / (points - 1)
	for point in points:
		var x: float = radius * cos(angle)
		var y: float = radius * sin(angle)
		var pos = Vector3(x, 0, y)
		angle += angle_diff
		curve.add_point(pos)
		print(pos)
