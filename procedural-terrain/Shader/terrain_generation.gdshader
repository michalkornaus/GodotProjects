shader_type spatial;
uniform sampler2D noise;
uniform sampler2D normalmap;
uniform sampler2D albedo_texture: source_color;
uniform float height_scale = 0.5;
varying vec2 tex_position;

void vertex() {
  tex_position = VERTEX.xz / 2.0 + 0.5;
  float height = texture(noise, tex_position).x;
  VERTEX.y += height * height_scale;
}

void fragment() {
  METALLIC = 0.0;
  ROUGHNESS = 0.7;
  ALBEDO = texture(albedo_texture, UV).rgb;
  NORMAL_MAP = texture(normalmap, tex_position).xyz;
}
