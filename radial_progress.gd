@tool
extends Node3D

@export_range(0.0, 100.0, 1.0) var value := 0.0 :
	set(val):
		if value != val:
			time_no_change = 0.0
		value = val
@export var color_scheme: COLOR_SCHEME

enum COLOR_SCHEME{
	RED_GREEN,
	WHITE
}

var mat: StandardMaterial3D = StandardMaterial3D.new()
var grad: GradientTexture1D = GradientTexture1D.new()

var time_no_change := 1.0
var is_feedbacking := false
var feedback_tween: Tween

func _ready() -> void:
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = grad
	mat.emission_enabled = true
	mat.emission_texture = grad
	mat.emission_energy_multiplier = 2.0
	grad.gradient = Gradient.new()
	grad.gradient.colors[1] = Color.BLACK
	grad.gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	$Progress.set_surface_override_material(0, mat)

func _process(delta: float) -> void:
	#var mat := $Progress.get_surface_override_material(0) as StandardMaterial3D
	var text := mat.albedo_texture.gradient as Gradient
	var limited_value := clampf(value, 0.0, 99.0)
	text.offsets[1] = limited_value / 100.0
	match color_scheme:
		COLOR_SCHEME.WHITE:
			text.colors[0] = Color.WHITE
		COLOR_SCHEME.RED_GREEN:
			if value >= 100:
				text.colors[0] = Color.GREEN
			else:
				text.colors[0] = Color.RED
	
	if time_no_change == 0:
		if not is_feedbacking:
			if feedback_tween and feedback_tween.is_running():
				feedback_tween.stop()
			feedback_tween = create_tween()
			feedback_tween.set_ease(Tween.EASE_OUT)
			feedback_tween.set_trans(Tween.TRANS_SPRING)
			feedback_tween.tween_property($Progress, "scale", Vector3.ONE * 1.6, 0.5)
			#$Progress.scale = Vector3.ONE * 1.5
			is_feedbacking = true
	elif time_no_change > 0.2:
		if is_feedbacking:
			if feedback_tween and feedback_tween.is_running():
				feedback_tween.stop()
			feedback_tween = create_tween()
			feedback_tween.set_ease(Tween.EASE_OUT)
			feedback_tween.set_trans(Tween.TRANS_SPRING)
			feedback_tween.tween_property($Progress, "scale", Vector3.ONE, 0.5)
			#$Progress.scale = Vector3.ONE
			is_feedbacking = false
	
	time_no_change += delta
