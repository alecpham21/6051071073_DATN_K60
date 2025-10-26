shader_type spatial;
render_mode  cull_disabled;

uniform sampler2D leaf_texture : source_color;
uniform vec4 leaf_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float wind_strength = 0.2;
uniform float wind_speed = 2.0;

/* gradient */
uniform vec4 top_color : source_color = vec4(0.85,0.97,0.75,1.0);
uniform vec4 bottom_color : source_color = vec4(0.2,0.4,0.2,1.0);
uniform float height_min = 0.0;
uniform float height_max = 2.0;
uniform float alpha_cutoff = 0.05;

varying vec3 v_world_pos;

void vertex() {
    // tính vị trí thế giới bằng MODEL_MATRIX
    vec4 world_p = MODEL_MATRIX * vec4(VERTEX, 1.0);
    v_world_pos = world_p.xyz;

    // gió sway
    float offset = sin(TIME * wind_speed + VERTEX.x * 0.1) * wind_strength;
    VERTEX.x += offset;
}

void fragment() {
    vec4 tex_color = texture(leaf_texture, UV);
    if (tex_color.a < alpha_cutoff) {
        discard;
    }

    // gradient theo v_world_pos.y
    float denom = max(height_max - height_min, 0.0001);
    float t = clamp((v_world_pos.y - height_min) / denom, 0.0, 1.0);
    vec3 grad = mix(bottom_color.rgb, top_color.rgb, t);

    ALBEDO = tex_color.rgb * leaf_color.rgb * grad;
    ALPHA = 1.0;
}
