@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	# Change all node names to "modified_[oldnodename]"
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
			for sc in meshnode.get_surface_count():
				var mat := meshnode.surface_get_material(sc)
				if mat is StandardMaterial3D:
					mat.metallic_specular = 0.1
		if node.name == "LightInstancing":
			node.mesh = null
			#node.queue_free()
			#return
		if node.name.begins_with("LampSquare"):
			var lamp_mesh = node.mesh as Mesh
			var mat := lamp_mesh.surface_get_material(1) as StandardMaterial3D
			mat.emission_energy_multiplier = 1.3
		for child in node.get_children():
			iterate(child)
