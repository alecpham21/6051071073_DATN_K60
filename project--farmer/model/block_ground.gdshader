shader_type spatial;
render_mode cull_disabled;

// Color picker cho hai màu
uniform vec4 top_color  : source_color = vec4(0.0, 1.0, 0.0, 1.0);   // Xanh lá
uniform vec4 side_color : source_color = vec4(0.6, 0.4, 0.2, 1.0);   // Nâu đất

void fragment() {
    if (NORMAL.y > 0.5) {
        ALBEDO = top_color.rgb;
    } else {
        ALBEDO = side_color.rgb;
    }
}
