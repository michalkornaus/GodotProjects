extends StaticBody3D
class_name Stack
@export var red_mat: StandardMaterial3D
@export var green_mat: StandardMaterial3D
@export var blue_mat: StandardMaterial3D
@export var yellow_mat: StandardMaterial3D
@export var white_mat: StandardMaterial3D
@export var black_mat: StandardMaterial3D
@export var purple_mat: StandardMaterial3D
var stack_list: Array[int]

func update_mesh():
	if stack_list.is_empty():
		queue_free()
		return
	var index = 0
	for stack in stack_list:
		var new_mesh = MeshInstance3D.new()
		new_mesh.mesh = CylinderMesh.new()
		new_mesh.mesh.top_radius = 0.1
		new_mesh.mesh.bottom_radius = 0.1
		new_mesh.mesh.height = 0.02
		## 0 - Red, 1 - Green, 2 - Blue, 3 - Yellow, 4 - White, 5 - Black, 6 - Purple
		match stack:
			0:	new_mesh.material_override = red_mat
			1:  new_mesh.material_override = green_mat
			2:	new_mesh.material_override = blue_mat
			3:  new_mesh.material_override = yellow_mat
			4:  new_mesh.material_override = white_mat
			5:  new_mesh.material_override = black_mat
			6:  new_mesh.material_override = purple_mat
		new_mesh.position.y = 0 + 0.025 * index
		index = index + 1
		self.add_child(new_mesh)
	$Label3D.text = str(check_top_count())
	$Label3D.position.y = 0.02 + 0.025 * index

func clean_mesh():
	for child in get_children():
		if child.is_class("MeshInstance3D"):
			child.queue_free()

func check_top_count():
	var index = 0
	var top_piece = stack_list[stack_list.size()-1]
	for i in range(stack_list.size()-1, -1, -1):
		if top_piece == stack_list[i]:
			index += 1
		else:
			break
	return index
