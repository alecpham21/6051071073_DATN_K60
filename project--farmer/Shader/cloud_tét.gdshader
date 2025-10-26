shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;

uniform sampler2D cloud_texture : source_color; // ảnh mây ngoài
uniform bool use_texture = true; // bật/tắt dùng texture
uniform float texture_strength : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform float alpha_cutoff : hint_range(0.0, 1.0, 0.01) = 0.5;

// noise params
uniform float noise_scale : hint_range(0.01, 200.0, 0.01) = 11.24;
uniform float speed : hint_range(0.0, 10.0, 0.001) = 0.16;
uniform float darkness_amount : hint_range(0.0, 64.0, 0.001) = 9.155;
uniform float detail : hint_range(0.0, 4.0, 0.001) = 0.23;
uniform float concentration : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float amount : hint_range(0.0, 1.0, 0.001) = 0.12;
uniform float bloom : hint_range(0.0, 8.0, 0.01) = 2.0;
uniform float alpha_mult : hint_range(0.0, 16.0, 0.01) = 8.0;
uniform vec4 cloud_tint : source_color = vec4(1.0);
uniform float edge_fade : hint_range(-1.0, 1.0, 0.001) = -0.035;
uniform mat2 rotation_matrix = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));

const int FBM_OCTAVES = 7;
const int R_OCTAVES = 8;
const int F_OCTAVES = 8;

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	const float K1 = 0.366025404;
	const float K2 = 0.211324865;
	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a,a), dot(b,b), dot(c,c)), 0.0);
	vec3 n = h*h*h*h * vec3(
		dot(a, hash(i + 0.0)),
		dot(b, hash(i + o)),
		dot(c, hash(i + 1.0))
	);
	return dot(n, vec3(70.0));
}

float fbm(vec2 n) {
	float total = 0.0;
	float amplitude = 0.1;
	for (int i = 0; i < FBM_OCTAVES; i++) {
		total += noise(n) * amplitude;
		n = rotation_matrix * n;
		amplitude *= 0.4;
	}
	return total;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * (speed / 10.0);
	float q = fbm(uv * noise_scale * 0.5);

	float r = 0.0;
	vec2 tuv = uv * noise_scale + q - time;
	float weight = 0.8;
	for (int i = 0; i < R_OCTAVES; i++) {
		r += abs(weight * noise(tuv));
		tuv = rotation_matrix * tuv + time;
		weight *= 0.7;
	}

	float f = 0.0;
	tuv = uv * noise_scale + q - time;
	weight = 0.7;
	for (int i = 0; i < F_OCTAVES; i++) {
		f += weight * noise(tuv);
		tuv = rotation_matrix * tuv + time;
		weight *= 0.6;
	}
	f *= r + f;

	// procedural cloud
	vec3 cloud_color = clamp(cloud_tint.rgb * (darkness_amount * detail * f), 0.0, 1.0) * bloom;
	float cloud_strength = amount + alpha_mult * f * r;
	cloud_strength = clamp(cloud_strength, 0.0, 1.0);

	// fade edges
	float edge_dist = distance(uv, vec2(0.5));
	float fade = smoothstep(edge_fade, 0.5, edge_dist);

	// --- texture blend ---
	if (use_texture) {
		vec4 tex_col = texture(cloud_texture, UV);
		// mix procedural cloud với texture mây thật
		cloud_color = mix(cloud_color, tex_col.rgb * cloud_tint.rgb, texture_strength);
		cloud_strength = mix(cloud_strength, tex_col.a, texture_strength);
	}

	ALBEDO = cloud_color;
	ALPHA = cloud_strength * (1.0 - fade) + concentration;
}
