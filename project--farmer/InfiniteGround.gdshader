shader_type spatial;

uniform sampler2D ground_texture : source_color, filter_nearest;
uniform vec4 base_color : source_color = vec4(0.3, 0.8, 0.3, 1.0);
uniform bool has_texture = false;

// Vẫn giữ offset để nếu bạn dùng Texture có hoa văn thì nó vẫn khớp vị trí
uniform vec2 grid_offset;
uniform float spacing = 1.0;

void fragment() {
	vec3 world_pos = (inverse(VIEW_MATRIX) * vec4(VERTEX, 1.0)).xyz;
	vec2 aligned_pos = world_pos.xz + grid_offset;

	// Tính UV để lặp lại texture (nếu có)
	vec2 uv_tile = fract(aligned_pos / spacing);

	// Mặc định lấy màu base_color
	vec3 final_color = base_color.rgb;

	// Nếu có texture thì nhân màu vào
	if (has_texture) {
		vec4 tex = texture(ground_texture, uv_tile);
		final_color *= tex.rgb;
	}

	// --- ĐÃ XÓA ĐOẠN VẼ VIỀN OUTLINE Ở ĐÂY ---

	ALBEDO = final_color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}