shader_type spatial;
render_mode cull_back; // chỉ bật/tắt culling, ko xài depth cũ nữa

uniform float bevel_size : hint_range(0.0, 0.2) = 0.05;
uniform vec4 top_color : source_color = vec4(0.3, 0.8, 0.3, 1.0);
uniform vec4 side_color : source_color = vec4(0.4, 0.25, 0.1, 1.0);

void fragment() {
    // Normal hướng lên -> coi là mặt top
    float top_mask = smoothstep(1.0 - bevel_size, 1.0, abs(NORMAL.y));

    // Blend màu cạnh/góc
    vec4 col = mix(side_color, top_color, top_mask);

    ALBEDO = col.rgb;
    ALPHA = col.a;
}
