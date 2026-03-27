shader_type canvas_item;

// --- Uniforms ---
uniform sampler2D die_texture : filter_nearest; // Set Filter to Nearest for pixel art look
uniform vec3 cube_size = vec3(0.5); // size relative to UV space
instance uniform vec3 basis_x = vec3(1,0,0);
instance uniform vec3 basis_y = vec3(0,1,0);
instance uniform vec3 basis_z = vec3(0,0,1);
// -- Outline Controls --
uniform bool outline_disabled = false; // Set true from code to disable the outline
uniform vec4 outline_color : source_color = vec4(0.5, 0.0, 0.8, 1.0); // Kept for compatibility, not used by the portal outline
instance uniform float outline_thickness : hint_range(0.0, 100.0) = 0.08;
uniform float antialias : hint_range(0.0, 0.1) = 0.02;

// New: outline shape randomization
uniform float outline_messiness : hint_range(0.0, 2.0) = 0.0; // 0 = current clean shape, higher = messier
uniform float outline_noise_scale : hint_range(1.0, 30.0) = 8.0;

// New: per-instance random seed
uniform float portal_seed = 0.0;

// -- Portal / Star Controls --
uniform float portal_star_density_1 : hint_range(0.0, 1.0) = 0.85;
uniform float portal_star_density_2 : hint_range(0.0, 1.0) = 0.90;
uniform float portal_star_density_3 : hint_range(0.0, 1.0) = 0.93;

uniform float portal_star_scale_1 : hint_range(1.0, 30.0) = 6.0;
uniform float portal_star_scale_2 : hint_range(1.0, 30.0) = 10.0;
uniform float portal_star_scale_3 : hint_range(1.0, 30.0) = 16.0;

uniform float portal_star_speed_1 : hint_range(0.0, 5.0) = 0.5;
uniform float portal_star_speed_2 : hint_range(0.0, 5.0) = 0.8;
uniform float portal_star_speed_3 : hint_range(0.0, 5.0) = 1.1;

uniform float portal_star_size_1 : hint_range(0.1, 3.0) = 1.2;
uniform float portal_star_size_2 : hint_range(0.1, 3.0) = 1.0;
uniform float portal_star_size_3 : hint_range(0.1, 3.0) = 0.8;

uniform float portal_star_brightness : hint_range(0.0, 8.0) = 2.5;
uniform float portal_star_contrast : hint_range(0.1, 3.0) = 0.6;
uniform float portal_nebula_strength : hint_range(0.0, 2.0) = 0.15;
uniform float portal_drift_strength : hint_range(0.0, 1.0) = 0.08;

uniform vec4 portal_void_color : source_color = vec4(0.005, 0.005, 0.012, 1.0);
uniform vec4 portal_nebula_color_1 : source_color = vec4(0.08, 0.02, 0.16, 1.0);
uniform vec4 portal_nebula_color_2 : source_color = vec4(0.01, 0.03, 0.08, 1.0);
instance uniform vec4 portal_star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- Helpers ---
float sdBox(vec3 p, vec3 b) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Logic to find which local face was hit
vec3 get_normal(vec3 p) {
	vec3 n = sign(p) * step(max(abs(p).yzx, abs(p).zxy), abs(p));
	return n;
}

// --- Noise / hash helpers ---
float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	float n = hash21(p);
	return vec2(n, hash21(p + n + 17.13));
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += noise2(p) * a;
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

// --- Portal-style outline helpers ---
float star_layer(vec2 uv, float scale, float speed, float threshold, float size_boost, vec2 motion_dir, float time_offset) {
	vec2 p = uv * scale;
	vec2 cell = floor(p);
	vec2 local = fract(p) - 0.5;

	float h = hash21(cell + vec2(portal_seed * 7.31, portal_seed * 11.17));
	vec2 offset = vec2(
		hash21(cell + vec2(1.23, 4.56) + portal_seed * 3.7),
		hash21(cell + vec2(7.89, 0.12) + portal_seed * 5.1)
	) - 0.5;

	float t = TIME * speed + time_offset + h * 6.2831;

	// Randomized movement per instance
	offset += 0.18 * vec2(
		sin(t) * motion_dir.x,
		cos(t * 0.83 + 1.7) * motion_dir.y
	);

	vec2 d = local - offset * 0.6;
	float dist = length(d);

	float star_mask = step(threshold, h);

	float radius = mix(0.03, 0.09 * size_boost, hash21(cell + 9.87 + portal_seed * 13.0));

	float glow = smoothstep(radius, 0.0, dist);
	float core = smoothstep(radius * 0.35, 0.0, dist);

	return star_mask * (glow * 0.45 + core * 0.85);
}

vec4 portal_outline_color(vec2 uv) {
	vec2 p = (uv - 0.5) * 2.0;

	// Randomized motion and parallax per instance
	float seed_a = hash11(portal_seed + 1.0);
	float seed_b = hash11(portal_seed + 2.0);
	float seed_c = hash11(portal_seed + 3.0);
	float seed_d = hash11(portal_seed + 4.0);

	vec2 drift_dir = normalize(vec2(seed_a * 2.0 - 1.0, seed_b * 2.0 - 1.0) + vec2(0.001, 0.0));
	vec2 drift = drift_dir * TIME * mix(0.02, 0.09, seed_c);

	vec2 warp = vec2(
		sin(p.y * mix(3.0, 6.0, seed_b) + TIME * mix(0.4, 1.1, seed_a) + seed_d * 10.0),
		cos(p.x * mix(3.2, 6.5, seed_c) - TIME * mix(0.3, 1.0, seed_b) + seed_a * 10.0)
	) * portal_drift_strength;

	vec2 dir1 = normalize(vec2(hash11(portal_seed + 10.0) * 2.0 - 1.0, hash11(portal_seed + 11.0) * 2.0 - 1.0) + vec2(0.001, 0.0));
	vec2 dir2 = normalize(vec2(hash11(portal_seed + 20.0) * 2.0 - 1.0, hash11(portal_seed + 21.0) * 2.0 - 1.0) + vec2(0.001, 0.0));
	vec2 dir3 = normalize(vec2(hash11(portal_seed + 30.0) * 2.0 - 1.0, hash11(portal_seed + 31.0) * 2.0 - 1.0) + vec2(0.001, 0.0));

	float time_offset_1 = hash11(portal_seed + 40.0) * 100.0;
	float time_offset_2 = hash11(portal_seed + 41.0) * 100.0;
	float time_offset_3 = hash11(portal_seed + 42.0) * 100.0;

	vec2 star_uv_1 = p + drift + warp;
	vec2 star_uv_2 = p * mix(1.5, 1.9, seed_a) - drift * mix(1.1, 1.8, seed_b) + warp * mix(1.1, 1.5, seed_c);
	vec2 star_uv_3 = p * mix(2.2, 2.9, seed_d) + drift.yx * vec2(-1.0, 1.0) * mix(0.8, 1.4, seed_a);

	float stars = 0.0;
	stars += star_layer(star_uv_1, portal_star_scale_1, portal_star_speed_1, portal_star_density_1, portal_star_size_1, dir1, time_offset_1);
	stars += star_layer(star_uv_2, portal_star_scale_2, portal_star_speed_2, portal_star_density_2, portal_star_size_2, dir2, time_offset_2);
	stars += star_layer(star_uv_3, portal_star_scale_3, portal_star_speed_3, portal_star_density_3, portal_star_size_3, dir3, time_offset_3);
	stars = clamp(stars, 0.0, 1.0);

	stars = pow(stars, portal_star_contrast);

	vec3 void_base = portal_void_color.rgb;
	vec3 nebula = portal_nebula_color_1.rgb * (0.5 + 0.5 * sin(TIME * mix(0.45, 0.95, seed_a) + p.x * mix(2.0, 4.0, seed_b) + p.y * mix(1.5, 3.5, seed_c) + seed_d * 8.0));
	nebula += portal_nebula_color_2.rgb * (0.5 + 0.5 * cos(TIME * mix(0.35, 0.8, seed_b) - p.x * mix(2.0, 3.5, seed_c) + p.y * mix(2.0, 4.0, seed_a) + seed_c * 8.0));

	vec3 color = void_base + nebula * portal_nebula_strength + portal_star_color.rgb * stars * portal_star_brightness;

	return vec4(color, 1.0);
}

void fragment() {
	// 1. Setup screen coordinates (-1.0 to 1.0)
	vec2 uv = (UV - 0.5) * 2.0;
	
	// 2. Setup the "eye" and ray direction
	vec3 ro = vec3(0.0, 0.0, -3.0); // Camera position
	vec3 rd = normalize(vec3(uv, 1.2)); // Flipped Z for texture correctness
	
	float d = 0.0;
	bool hit = false;
	vec3 p;
	
	// Track the closest the ray ever gets to the cube (for the outline)
	float min_dist = 100.0;

	// 3. Raymarching Loop
	mat3 rotation_matrix = mat3(
		basis_x,basis_y,basis_z
	);
	for (int i = 0; i < 64; i++) {
		p = (ro + rd * d) * rotation_matrix;
		float current_dist = sdBox(p, cube_size);
		min_dist = min(min_dist, current_dist);
		
		if (current_dist < 0.001) {
			hit = true;
			break;
		}
		
		d += current_dist;
		
		if (d > 10.0) {
			break;
		}
	}

	vec4 final_color = vec4(0.0);

	// 4. Composite: Outline -> Texture -> Final Output
	if (!outline_disabled) {
		// Distort the outline shape with seeded noise
		vec2 noise_uv = UV * outline_noise_scale
			+ vec2(hash11(portal_seed + 100.0), hash11(portal_seed + 200.0)) * 50.0
			+ vec2(TIME * 0.12, -TIME * 0.09);

		float n1 = fbm(noise_uv);
		float n2 = fbm(noise_uv * 1.9 + vec2(13.7, 8.2));
		float outline_noise = mix(n1, n2, 0.5) - 0.5;

		float distorted_dist = min_dist - outline_noise * outline_messiness * outline_thickness * 1.8;

		float edge = smoothstep(outline_thickness + antialias, outline_thickness, distorted_dist);
		vec4 portal_col = portal_outline_color(UV);
		final_color = mix(final_color, portal_col, edge * portal_col.a);
	}

	if (hit) {
		vec3 n = get_normal(p);
		vec2 face_uv;
		float face_index = 0.0;

		if (abs(n.x) > 0.5) {
			face_uv = p.zy;
			face_index = n.x > 0.0 ? 0.0 : 1.0;
		} else if (abs(n.y) > 0.5) {
			face_uv = p.xz;
			face_index = n.y > 0.0 ? 2.0 : 3.0;
		} else {
			face_uv = p.xy;
			face_index = n.z > 0.0 ? 4.0 : 5.0;
		}

		face_uv = face_uv / (cube_size.xy * 2.0) + 0.5;

		vec2 atlas_size = vec2(3.0, 2.0);
		vec2 offset = vec2(mod(face_index, 3.0), floor(face_index / 3.0));
		
		vec2 final_uv = (face_uv + offset) / atlas_size;
		vec4 tex_color = texture(die_texture, final_uv);

		final_color = tex_color;
	}

	COLOR = final_color;
}