shader_type canvas_item;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float alpha = 1.0;
uniform float texture_alpha = 1.0;
uniform float inner_radius = 0.0;
uniform float outer_radius = 1.0;

#define MAXCOLORS 16

uniform bool enabled = true;
uniform bool dithering = true;
uniform int colors : hint_range(1, MAXCOLORS) = 12;
uniform int dither_size: hint_range(1, 8) = 1;

global uniform float blood_vignete;
global uniform float underground_vignete;
global uniform float rumble_vignete;
global uniform float lights_percent;
global uniform bool screen_filter;

// Dithering

float dithering_pattern(ivec2 fragcoord) {
	const float pattern[] = {
		0.00, 0.50, 0.10, 0.65,
		0.75, 0.25, 0.90, 0.35,
		0.20, 0.70, 0.05, 0.50,
		0.95, 0.40, 0.80, 0.30
	};

	int x = fragcoord.x % 4;
	int y = fragcoord.y % 4;

	return pattern[y * 4 + x];
}

float reduce_color(float raw, float dither, int depth) {
	float div = 1.0 / float(depth);
	float val = 0.0;
	int i = 0;

	while (i <= MAXCOLORS)
	{
		if (raw > div * (float(i + 1))) {
			i = i + 1;
			continue;
		}

		if (raw * float(depth) - float(i) <= dither * 0.999)
		{
			val = div * float(i);
		}
		else
		{
			val = div * float(i + 1);
		}
		return val;

		i = i+1;
	}

	return val;
}
//

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	vec4 raw = texture(SCREEN_TEXTURE, SCREEN_UV);
	ivec2 uv = ivec2(FRAGCOORD.xy / float(dither_size));

	if (enabled == true){
		float dithering_value = 1.0;
		if (dithering)
		{
			dithering_value = dithering_pattern(uv);
		}

		screen_color.r = reduce_color(raw.r, (dithering_value - 0.5) * dithering_value + 0.5, colors - 1);
		screen_color.g = reduce_color(raw.g, (dithering_value - 0.5) * dithering_value + 0.5, colors - 1);
		screen_color.b = reduce_color(raw.b, (dithering_value - 0.5) * dithering_value + 0.5, colors - 1);

	} else {
		screen_color.rgb = raw.rgb;
	}
	
	vec4 texture_color = texture(TEXTURE, UV);
	vec3 mix_color = mix(screen_color, screen_color * vec4(1.0, 0.1, 0.1, 1.0), blood_vignete).rgb;

	float x = abs(SCREEN_UV.r-.5)*2.0;
	float y = abs(SCREEN_UV.g-.5)*2.0;
	float q = 1.0-(1.0-sqrt(x*x+y*y)/outer_radius)/(1.0-inner_radius);
	vec3 vignete = vec3(1.0 - q*alpha);

	vec3 bw = vec3((screen_color.r+screen_color.g+screen_color.b)/3.0);
	vec3 red = screen_color.rgb * vec3(1.0, 0.05, 0.1);

	mix_color = mix(mix_color, red, underground_vignete*0.5);

	mix_color = mix_color * clamp(vignete, 0.0, 1.0);

	mix_color = mix(mix_color, bw, clamp(q*0.7, 0.0, 1.0));

	//mix_color = mix(mix_color, bw, rumble_vignete);

	if (screen_filter) {
		mix_color *= mix(vec3(1.0), texture_color.rgb, texture_alpha+rumble_vignete);
	}

	mix_color *= mix(1.0, lights_percent, 0.4);

	COLOR = vec4(mix_color, 1.0);

	//COLOR = vec4(clamp(vignete, 0.0, 1.0), 1.0);
}
