shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// Kolor, z którym obiekty będą się mieszać (powinien być zbliżony do dominującego koloru SkyBoxa).
uniform vec3 sky_blend_color : source_color;
// Odległości, na których rozpoczyna się i kończy efekt wtapiania.
uniform float fade_start_distance : hint_range(0.0, 2000.0, 1.0) = 500.0;
uniform float fade_end_distance : hint_range(0.0, 2000.0, 1.0) = 1000.0;
// Zmienna przekazywana z vertex shadera do fragment shadera przechowująca pozycję wierzchołka w przestrzeni świata.
varying vec3 v_world_position;

void vertex() {
	vec3 normal = NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);

	// UV1 Triplanar: Enabled
	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	v_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	vec3 original_albedo = ALBEDO;
	float original_alpha = ALPHA;
	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	// Oblicz odległość od kamery do bieżącego fragmentu (piksela) w przestrzeni świata.
    float distance_to_camera = distance(CAMERA_POSITION_WORLD, v_world_position);
    float fade_factor = clamp(smoothstep(fade_start_distance, fade_end_distance, distance_to_camera), 0.0, 1.0);
    ALBEDO = mix(original_albedo, sky_blend_color, fade_factor);

    ALPHA = original_alpha * (1.0 - fade_factor);
     if (ALPHA < 0.01) {
         discard;
     }
}
