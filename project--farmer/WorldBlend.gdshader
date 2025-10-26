shader_type spatial;
uniform vec4 inner_color : source_color;
uniform vec4 outer_color : source_color;
uniform float radius = 10.0;
void fragment() {
    float d = length(VERTEX.xz);
    float t = clamp(d / radius, 0.0, 1.0);
    ALBEDO = mix(inner_color.rgb, outer_color.rgb, t);
}
