shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

uniform sampler2D leaf_texture : source_color;
uniform vec4 leaf_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float alpha_cutoff = 0.1;

// --- WIND (GIỮ NGUYÊN CỦA CÂY PHỤ CHO NHẸ) ---
uniform float wind_strength = 0.2;
uniform float wind_speed = 2.0;

// --- FRESNEL (LẤY TỪ CÂY CHÍNH SANG) ---
uniform float fresnelStrength : hint_range(-2.0, 2.0) = 0.5;
uniform float fresnelBlend : hint_range(-1.0,1.0) = 1.0;
uniform vec4 fresnelColor : source_color = vec4(0.58,0.65,0.33,1.0);

void vertex() {
	// Logic gió sway đơn giản (giữ nguyên để tối ưu cho background)
	float offset = sin(TIME * wind_speed + VERTEX.x * 0.1) * wind_strength;
	VERTEX.x += offset;
	
	// Cây phụ thường không cần tính toán Normal phức tạp, 
	// nhưng để Fresnel đẹp thì cần Normal hướng lên một chút hoặc giữ nguyên.
	// NORMAL = vec3(0.0, 1.0, 0.0); // Bỏ comment dòng này nếu muốn lá sáng đều như cây chính
}

void fragment() {
	vec4 tex_color = texture(leaf_texture, UV);
	if (tex_color.a < alpha_cutoff) {
		discard;
	}

	// --- MÀU SẮC CƠ BẢN ---
	// Bỏ Gradient, chỉ dùng Texture * Màu tint để giống cây chính
	vec3 base_albedo = tex_color.rgb * leaf_color.rgb;
	ALBEDO = base_albedo;
	ALPHA = tex_color.a;

	// --- FRESNEL EFFECT (LOGIC TỪ CÂY CHÍNH) ---
	// Tính toán hiệu ứng viền sáng
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	
	// Áp dụng màu Fresnel
	vec3 fres_col = base_albedo * (1.0 - fresnelStrength);
	fres_col += fresnelColor.rgb * fresnelStrength;
	fres_col *= fresnel;
	fres_col *= fresnelBlend;
	
	// Gán vào Emission
	EMISSION = fres_col;
}