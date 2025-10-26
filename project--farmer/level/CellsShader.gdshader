shader_type spatial;
render_mode cull_disabled;

uniform sampler2D atlas_tex : source_color;   // atlas PNG: grass|tilled|wet|fert
uniform vec2 atlas_tiles = vec2(4.0, 1.0);
uniform float grid_visibility = 0.35;

varying vec2 uv0;
void vertex(){ uv0 = UV; }

float tile_idx(){
    #ifdef USE_MULTIMESH
        return round(INSTANCE_CUSTOM.r * 255.0);
    #else
        return 0.0;
    #endif
}

void fragment(){
    float idx = tile_idx();
    vec2 tile = vec2(mod(idx, atlas_tiles.x), floor(idx / atlas_tiles.x));
    vec2 uv = (uv0 + tile) / atlas_tiles;

    vec4 tex = texture(atlas_tex, uv);
    ALBEDO = tex.rgb;
    ROUGHNESS = (idx == 2.0) ? 0.15 : 0.6; // WET bóng hơn
    ALPHA = tex.a * grid_visibility;
}
