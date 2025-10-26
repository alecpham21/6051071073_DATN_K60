shader_type spatial;
render_mode cull_disabled;

uniform vec3 tint = vec3(1.0, 1.0, 0.2);
uniform float alpha = 0.5;

void fragment(){
    float pulse = 0.9 + 0.1 * sin(TIME * 4.0);
    ALBEDO = tint * pulse;
    ALPHA = alpha;
    ROUGHNESS = 1.0;
}
