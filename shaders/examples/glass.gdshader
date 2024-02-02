// Glass (from godotshaders.com) by Lakamfo
// This shader is included as an example for Godot Shaders Sketchbook


shader_type spatial;
render_mode blend_mix, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

group_uniforms Parameters;
uniform vec4 tint_color : source_color = vec4(0.443137, 0.368627, 1.000000, 0.611765);
uniform vec4 backlight_color : source_color = vec4(0.5, 0.5, 0.5, 1.000000);
uniform float noise_strenght : hint_range(0, 0.05) = 0.005;
uniform float roughness : hint_range(0, 1) = 0;
group_uniforms Textures;
uniform sampler2D noise_texture : repeat_enable;
uniform sampler2D screen_texture : hint_screen_texture;

uniform sampler2D Normal : hint_normal;
uniform float normal_strenght : hint_range(-1, 1) = 0;

void fragment() {
	vec4 noise = texture(noise_texture, UV);
	vec3 noise_uv_effect = vec3(noise_strenght) / vec3(noise.rgb);
	
	vec4 _screen_texture = texture(screen_texture, vec2((vec3(SCREEN_UV, 0.0) + noise_uv_effect).rg)) * tint_color;
	
	vec2 specular = inversesqrt(vec2(tint_color.a)) * vec2(0.500000);
	
	vec4 normal = texture(Normal, UV);
	vec3 normal_map = vec3(normal.rgb) * vec3(normal_strenght);
	
	ALBEDO = vec3(_screen_texture.rgb);
	ROUGHNESS = roughness;
	SPECULAR = specular.x;
	NORMAL_MAP = normal_map;
	BACKLIGHT = vec3(backlight_color.rgb);
}