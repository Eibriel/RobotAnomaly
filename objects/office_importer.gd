@tool # Needed so it runs in editor.
extends EditorScenePostImport

var root_name: String

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	# Change all node names to "modified_[oldnodename]"
	root_name = scene.name
	print(root_name)
	iterate(scene)
	return scene # Remember to return the imported scene

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func iterate(node):
	if node != null:
		#print_rich("Post-import: [b]%s[/b] -> [b]%s[/b]" % [node.name, "modified_" + node.name])
		#node.name = "modified_" + node.name
		if node is MeshInstance3D:
			var meshnode := node.mesh as Mesh
			var change_lod := false
			if node.name.begins_with("tight_"):
				change_lod = true
			elif node.name.begins_with("knee_"):
				change_lod = true
			elif node.name.begins_with("calf_"):
				change_lod = true
			elif node.name.begins_with("elbow_"):
				change_lod = true
			if change_lod:
				node.lod_bias = 2.0
			for sc in meshnode.get_surface_count():
				var mat := meshnode.surface_get_material(sc)
				if mat is StandardMaterial3D:
					if root_name != "robot":
						mat.metallic_specular = 0.1
		if root_name == "office":
			if node.name == "LightInstancing":
				#node.mesh = null
				pass
				#node.queue_free()
				#return
			if node.name.begins_with("LampSquare"):
				var lamp_mesh = node.mesh as Mesh
				var mat := lamp_mesh.surface_get_material(1) as StandardMaterial3D
				mat.emission_energy_multiplier = 1.3
			if node.name == "Suelo":
				var lamp_mesh = node.mesh as Mesh
				var mat := lamp_mesh.surface_get_material(0) as StandardMaterial3D
				mat.disable_ambient_light = true
				mat.emission_enabled = true
				#mat.emission = Color.DIM_GRAY
				mat.emission_texture = mat.albedo_texture
				mat.emission_energy_multiplier = 0.5
		for child in node.get_children():
			iterate(child)
