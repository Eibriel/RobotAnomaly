shader_type spatial;
//render_mode skip_vertex_transform;

uniform vec3 albedo : source_color;
uniform float emission_amount : hint_range(0.0, 100.0);
uniform sampler2D texture_gradient : source_color, filter_linear_mipmap, repeat_enable;
instance uniform float amount : hint_range(0.0, 1.0, 0.01);

void fragment() {
	float val = texture(texture_gradient, UV).r;
	/*if (val < amount) {
		ALBEDO = vec3(1.0) * albedo;
		EMISSION = vec3(1.0) * albedo * emission_amount;
	} else {
		ALBEDO = vec3(0.0) * albedo;
		EMISSION = vec3(0.0) * albedo * emission_amount;
	}*/
	val = 1.0 - val;
	val = clamp((val * 9.0) + (-10.0 * (1.0-amount)) + 1.0, 0.0, 1.0);
	ALBEDO = vec3(val) * albedo;
	EMISSION = vec3(val) * albedo * emission_amount;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
