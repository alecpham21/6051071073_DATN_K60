shader_type spatial;

uniform float noise_strength = 1.0;
uniform vec4 albedo : source_color;
uniform float shadow_strenght = 0.95;
uniform sampler2D noise_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(0.1);
uniform vec2 speed = vec2(0.03);

varying mat4 world_mat;

void vertex() {
	world_mat = INV_VIEW_MATRIX;
}

varying vec3 _vertex;

void fragment(){

	_vertex = VERTEX;

	ALBEDO = albedo.rgb;
}

void light() {

  if(LIGHT_IS_DIRECTIONAL){

	//ray
	// p = ray_start + ray_dir * t
	vec3 ray_dir = -LIGHT; // in view space
	ray_dir = mat3(world_mat) * ray_dir; // in world space
	vec3 ray_start = (INV_VIEW_MATRIX * vec4(_vertex, 1.0f)).xyz;

	//plane
	// (p - p0) . n = 0
	vec3 n = vec3(0.0, 1.0, 0.0);
	vec3 PO = vec3(0.0, 1.0, 0.0); // can make offset to the top
	vec3 v = PO - ray_start;

	// solve for parameter t
	// t = ((p0 - ray_start) . n) / (ray_dir . n)
	float t = dot(normalize(v), n) * length(v) / dot(ray_dir, n);
	vec3 P = ray_start + t * ray_dir;  // in world space

	vec2 uv = P.xz; // convert it to texture UV
	vec2 uv_offset = vec2(TIME, TIME) * speed;

	vec4 rg = texture( noise_texture, uv * uv_scale + uv_offset) * noise_strength;

	float clouds = smoothstep(0.2, 1.0, 1.0 - rg.r);

	//make it less dark, can skip it
	clouds *= 0.9;
	clouds += 0.1;

	//To sample shadow with different blur param, check the tutorial linked in the description
	//float blur = 1.;
	//if(clouds < 1.0) blur += 10. * smoothstep(0.2, 1.0, rg.r) ;
	//float shadow = get_directional_shadow(LIGHT_INDEX, _vertex, blur);
	float shadow = ATTENUATION;

	if( clouds < 1.0 && shadow < 1.0) {
		shadow *= 1.0 - 0.2 * smoothstep(0.1, 1.0, rg.r) ;
		shadow += 0.2 * smoothstep(0.1, 1.0, rg.r) ;
		clouds = min(clouds, shadow);
	}

	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * clouds * shadow * ALBEDO * LIGHT_COLOR;

  }
}