shader_type spatial;
render_mode cull_disabled;

uniform sampler2D leaf_texture : source_color;
uniform vec4 leaf_color = vec4(1.0);
uniform float wind_strength = 0.2;
uniform float wind_speed = 2.0;
uniform float alpha_cutoff = 0.5;

void vertex() {
    float wave = sin(TIME * wind_speed + VERTEX.z * 0.2);
    float angle = wave * wind_strength;

    // Ma trận xoay quanh trục X
    vec3 col0 = vec3(1.0, 0.0, 0.0);
    vec3 col1 = vec3(0.0, cos(angle), -sin(angle));
    vec3 col2 = vec3(0.0, sin(angle),  cos(angle));
    mat3 rot = mat3(col0, col1, col2);

    VERTEX.xyz = rot * VERTEX.xyz;
    VERTEX.y += wave * 0.1; // có thể bỏ nếu chỉ muốn xoay
}

void fragment() {
    vec4 tex = texture(leaf_texture, UV);
    if (tex.a < alpha_cutoff) discard;

    ALBEDO = tex.rgb * leaf_color.rgb;
    ALPHA = tex.a;
}
