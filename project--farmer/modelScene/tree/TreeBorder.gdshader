shader_type spatial;
// render_mode cull_front: Quan trọng! Nó bảo GPU chỉ vẽ mặt trong, bỏ mặt ngoài.
// unshaded: Để viền luôn đen tuyền, không bị bóng đổ làm bạc màu.
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Kỹ thuật "Làm phồng": Đẩy các đỉnh lồi ra theo hướng pháp tuyến
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}