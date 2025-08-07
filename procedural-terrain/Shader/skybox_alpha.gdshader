shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Domyślnie biały, w pełni nieprzezroczysty
uniform sampler2D base_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 sky_blend_color : source_color;
uniform float fade_start_distance : hint_range(0.0, 2000.0, 1.0) = 500.0;
uniform float fade_end_distance : hint_range(0.0, 2000.0, 1.0) = 1000.0;
varying vec3 v_world_position;

void vertex() {
    v_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float distance_to_camera = distance(CAMERA_POSITION_WORLD, v_world_position);
    float fade_factor = clamp(smoothstep(fade_start_distance, fade_end_distance, distance_to_camera), 0.0, 1.0);
    vec4 tex_color = texture(base_texture, UV);
    vec3 original_albedo = tex_color.rgb * base_color.rgb;
    float original_alpha = tex_color.a * base_color.a;   
    ALBEDO = mix(original_albedo, sky_blend_color, fade_factor);
    ALPHA = original_alpha * (1.0 - fade_factor);
    if (ALPHA < 0.01) {
        discard;
    }
}