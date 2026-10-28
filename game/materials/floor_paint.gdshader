shader_type spatial;
// Worn safety paint on the factory floor: a solid line or diagonal hazard stripes,
// scuffed by procedural wear (no texture). Lies a few millimetres above the floor.
render_mode cull_back;

uniform vec4 paint : source_color = vec4(0.95, 0.68, 0.08, 1.0);
uniform vec4 stripe_dark : source_color = vec4(0.03, 0.03, 0.035, 1.0);
uniform bool hazard = false;
uniform float stripe_width = 0.18;   // metres per stripe (hazard)
uniform float wear = 0.45;           // 0 = fresh, 1 = nearly gone
uniform vec2 size = vec2(1.0, 1.0);  // quad size in metres (for world-scale patterns)

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 m = UV * size;
	// Scuffs: large blotches plus fine streaks along the walking direction (x).
	float blotch = noise(m * 2.3) * 0.65 + noise(m * 9.0) * 0.35;
	float streak = noise(vec2(m.x * 1.2, m.y * 38.0));
	float worn = smoothstep(1.0 - wear, 1.0 - wear + 0.18, blotch * 0.7 + streak * 0.3);
	vec3 col = paint.rgb;
	if (hazard) {
		float s = fract((m.x + m.y) / (stripe_width * 2.0));
		col = s < 0.5 ? paint.rgb : stripe_dark.rgb;
	}
	ALBEDO = col;
	ROUGHNESS = 0.62;
	METALLIC = 0.0;
	ALPHA = (1.0 - worn) * paint.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;  // opaque pass: crisp worn edges, keeps SSR and shadows
}
