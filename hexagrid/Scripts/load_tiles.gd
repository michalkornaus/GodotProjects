@tool
extends EditorScript
func _run():
	var scene_root = EditorInterface.get_edited_scene_root()
	for child in scene_root.get_children():
		if child.get_groups().size() > 0:
			if child.get_groups()[0] == "Tiles":
				for tile_child in child.get_children():
					child.get("all_tiles").append(tile_child)
				break
	#var scene_root = EditorInterface.get_edited_scene_root()
	#for child in scene_root.get_children():
	#	if child.get_groups().size() > 0:
	#		if child.get_groups()[0] == "Tiles":
	#			child.all_tiles.clear()
