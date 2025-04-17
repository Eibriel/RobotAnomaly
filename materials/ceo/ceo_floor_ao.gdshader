shader_type spatial;

varying vec3 world_pos;

void vertex() {
	// Called for every vertex the material is visible on.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(0.0, 0.0, 0.0);
	ALPHA = clamp(1.0-world_pos.y*6.0, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
