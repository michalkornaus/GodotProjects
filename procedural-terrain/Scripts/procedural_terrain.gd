extends Node3D

@export_category("Generation variables")
@export_range(25, 500) var spawn_distance: int = 15
@export_range(25, 500) var despawn_distance: int = 15
@export_range(1, 100) var moving_speed: float = 1
@export_range(2, 50) var segment_size: int = 4
@export_range(1, 50) var segment_width_count: int = 4
var segment_count

@export_category("Prefabs")
@export var segment_prefab: PackedScene
@export var terrain_prefab: PackedScene
@export var rail_node_prefab: PackedScene
@export var rail_gravel_prefab: PackedScene
@onready var path3d: Path3D = $Path3D

@export_category("Terrain variables")
@export var fast_noise: FastNoiseLite
@export var texture: CompressedTexture2D
var terrain_material: StandardMaterial3D
@export var terrain_shader: ShaderMaterial
@export_category("Vegetation variables")
@export var tree_models: Array[PackedScene]
@export var grass_sprites: Array[CompressedTexture2D]
@export var vegetation_noise: FastNoiseLite

func _ready():
	# -- Setting terrain material
	terrain_material = StandardMaterial3D.new()
	terrain_material.albedo_texture = texture
	terrain_material.metallic = 0.2
	terrain_material.roughness = 1.0
	terrain_material.uv1_triplanar = true
	terrain_material.uv1_scale = Vector3(0.25, 0.25, 0.25)
	# -- Setting noise seeds
	fast_noise.seed = 100
	vegetation_noise.seed = 100
	# -- Setting up Path3D
	path3d.curve.set_point_position(0, Vector3i(0, 0, spawn_distance))
	path3d.curve.set_point_position(1, Vector3i(0, 0, -despawn_distance))
	segment_count = (spawn_distance + despawn_distance) / segment_size
	for i in segment_count:
		var terrain_follow: PathFollow3D = terrain_prefab.instantiate()
		# -- Creating new temporary Plane Mesh
		var _mesh: Mesh = PlaneMesh.new()
		_mesh.size = Vector2(segment_size * segment_width_count, segment_size)
		_mesh.subdivide_depth = 4 
		_mesh.subdivide_width = 4 * segment_width_count
		# -- Transforming Plane Mesh to ArrayMesh and using MeshDataTool
		var surface_tool := SurfaceTool.new()
		surface_tool.create_from(_mesh, 0)
		var mesh := surface_tool.commit()
		var mdt = MeshDataTool.new()
		mdt.create_from_surface(mesh, 0)
		# -- Using noise to change vertex height
		var index: int = 0
		for j in range(mdt.get_vertex_count()):
			var vertex = mdt.get_vertex(j)
			vertex.y += (fast_noise.get_noise_2d(vertex.x, vertex.z + (segment_size * i)) * 18) * 0.003 * abs(vertex.x)
			var noise_value = vegetation_noise.get_noise_2d(vertex.x, vertex.z + (segment_size * i))
			if noise_value > 1 - (0.3 * abs(vertex.x) / 3) && index > 10:
				if noise_value > 1 - (0.15 * abs(vertex.x) / 30):
					var new_tree = tree_models[randi_range(0, 5)].instantiate()
					new_tree.scale = Vector3(0.5, 0.5, 0.5)
					new_tree.position = vertex
					terrain_follow.add_child(new_tree)
				else:
					var new_grass = Sprite3D.new()
					new_grass.texture = grass_sprites[randi_range(0, 9)]
					new_grass.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
					new_grass.position = vertex + Vector3(0, 0.5, 0)
					terrain_follow.add_child(new_grass)
				index = 0
			mdt.set_vertex(j, vertex)
			index += 1	
		mesh.clear_surfaces()
		mdt.commit_to_surface(mesh)
		# -- Creating new mesh and changing its mesh and material
		var mi = MeshInstance3D.new()
		mi.name = "MeshInstance3D"
		mi.mesh = mesh
		mi.mesh.surface_set_material(0, terrain_material)#terrain_shader)
		# -- Creating rail and gravel nodes
		var rail_node: Node3D = rail_node_prefab.instantiate()
		rail_node.position.y = 0.1
		var rail_gravel: Node3D = rail_gravel_prefab.instantiate()
		rail_gravel.position.y = 0.1
		# -- Setting variables
		terrain_follow.moving_speed = moving_speed
		terrain_follow.current_index = segment_count + i
		terrain_follow.add_child(mi)
		terrain_follow.add_child(rail_node)
		terrain_follow.add_child(rail_gravel)
		path3d.add_child(terrain_follow)
		terrain_follow.progress_ratio = 1 - (i / float(segment_count))

func _modify_terrain(terrain_follow: PathFollow3D, current_index: int):
	# -- Creating new temporary Plane Mesh
	var _mesh: Mesh = PlaneMesh.new()
	_mesh.size = Vector2(segment_size * segment_width_count, segment_size)
	_mesh.subdivide_depth = 4 
	_mesh.subdivide_width = 4 * segment_width_count
	var surface_tool := SurfaceTool.new()
	surface_tool.create_from(_mesh, 0)
	var mesh := surface_tool.commit()
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	for child in terrain_follow.get_children():
		if child is not MeshInstance3D:
			child.queue_free()
	var index: int = 0
	for j in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(j)
		vertex.y += (fast_noise.get_noise_2d(vertex.x, vertex.z + (segment_size * current_index)) * 18) * 0.003 * abs(vertex.x)
		var noise_value = vegetation_noise.get_noise_2d(vertex.x, vertex.z + (segment_size * current_index))
		if noise_value > 1 - (0.3 * abs(vertex.x) / 3) && index > 10:
			if noise_value > 1 - (0.15 * abs(vertex.x) / 30):
				var new_tree = tree_models[randi_range(0, 5)].instantiate()
				new_tree.scale = Vector3(0.5, 0.5, 0.5)
				new_tree.position = vertex
				terrain_follow.add_child(new_tree)
			else:
				var new_grass = Sprite3D.new()
				new_grass.texture = grass_sprites[randi_range(0, 9)]
				new_grass.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
				new_grass.position = vertex + Vector3(0, 0.5, 0)
				terrain_follow.add_child(new_grass)
			index = 0
		mdt.set_vertex(j, vertex)
		index += 1	
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)		
	var mesh_instance = terrain_follow.get_node("MeshInstance3D")
	mesh_instance.mesh = mesh
	mesh_instance.mesh.surface_set_material(0, terrain_material)#terrain_shader)
	# -- Creating rail and gravel nodes
	var rail_node: Node3D = rail_node_prefab.instantiate()
	rail_node.position.y = 0.1
	var rail_gravel: Node3D = rail_gravel_prefab.instantiate()
	rail_gravel.position.y = 0.1
	# -- Setting variables
	terrain_follow.current_index = segment_count + current_index
	terrain_follow.add_child(rail_node)
	terrain_follow.add_child(rail_gravel)

var title = "Procedural Terrain"
func _process(delta):
	get_window().title = title + " | FPS: " + str(Engine.get_frames_per_second())

func _pick_color():
	var random_color = Color(randf(),randf(),randf(),1)
	return random_color
	
# --- shader noise
		#var terrain_follow: PathFollow3D = terrain_prefab.instantiate()
		#var mesh_instance: MeshInstance3D = terrain_follow.get_node("MeshInstance3D")
		#var shader_material: ShaderMaterial = mesh_instance.get_active_material(0)
		#var noise_texture: NoiseTexture2D = shader_material.get_shader_parameter("noise")
		#noise_texture.noise.offset.y = i * 128
		#path3d.add_child(terrain_follow)
		#terrain_follow.progress_ratio = i / float(segment_count)
# --- colorful floors
		#var path_follow = segment_prefab.instantiate()
		#var floor_prefab = MeshInstance3D.new()
		#floor_prefab.name = "MeshInstance3D"
		#floor_prefab.mesh = PlaneMesh.new()
		#floor_prefab.mesh.size = Vector2(segment_size * segment_width_count, segment_size)
		#var mat_mesh = StandardMaterial3D.new()
		#mat_mesh.albedo_color = _pick_color()
		#floor_prefab.material_override = mat_mesh
		#path_follow.moving_speed = moving_speed
		#path_follow.add_child(floor_prefab)
		#path3d.add_child(path_follow)
		#path_follow.progress_ratio = i / float(segment_count)
