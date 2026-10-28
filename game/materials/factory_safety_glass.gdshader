shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
// Original shader. Real room reflections come from the static ReflectionProbe.
// Undistorted screen transmission preserves detail; depth testing protects foreground actors.
uniform sampler2D transmission_screen : hint_screen_texture, repeat_disable, filter_linear;
uniform vec3 glass_tint : source_color = vec3(0.37, 0.49, 0.51);
// Parameters come from the same layout that constructs the actual emitters.
uniform vec4 ceiling_row = vec4(-2.0,3.0,6.0,3.865);
uniform vec3 ceiling_diffuser = vec3(3.1,1.25,.29);
uniform vec3 ceiling_radiance = vec3(2.22,2.55,2.85);
varying vec3 surface_world;
void vertex() { surface_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
// Analytic reflection of the physical opposite ceiling diffusers. No scene copy,
// no recursive screen feedback, no duplicate foreground character silhouettes.
float ceiling_reflection(vec3 camera_world) {
    vec3 ray = reflect(normalize(surface_world - camera_world), vec3(0.0,0.0,1.0));
    float distance_to_ceiling = (ceiling_row.w-surface_world.y) / max(ray.y,0.0001);
    vec3 hit = surface_world + ray * distance_to_ceiling;
    float cell_x = abs(mod(hit.x-ceiling_row.x+ceiling_row.y*0.5,ceiling_row.y)-ceiling_row.y*0.5);
    float dx = max(fwidth(cell_x),0.018);
    float dz = max(fwidth(hit.z),0.018);
    float panel = (1.0-smoothstep(ceiling_diffuser.y-dx,ceiling_diffuser.y+dx,cell_x)) * (1.0-smoothstep(ceiling_diffuser.z-dz,ceiling_diffuser.z+dz,abs(hit.z-ceiling_diffuser.x)));
    return panel * step(0.001,ray.y) * step(ceiling_row.x-ceiling_diffuser.y,hit.x) * step(hit.x,ceiling_row.x+(ceiling_row.z-1.0)*ceiling_row.y+ceiling_diffuser.y);
}
void fragment() {
    float grazing = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 4.0);
    vec2 edge_distance = min(UV, vec2(1.0) - UV) * vec2(4.72, 2.65);
    float border = 1.0 - smoothstep(0.008, 0.025, min(edge_distance.x, edge_distance.y));
    // Small etched safety dots low on the pane; antialiased at production camera scale.
    vec2 dot_uv = vec2(fract(UV.x * 36.0) - 0.5, (UV.y - 0.84) * 20.0);
    float d = length(dot_uv);
    float aa = max(fwidth(d), 0.025);
    float etch = (1.0 - smoothstep(0.065-aa, 0.065+aa, d)) * smoothstep(0.03, 0.05, UV.x) * (1.0-smoothstep(0.95, 0.97, UV.x));
    ALBEDO = vec3(0.62, 0.67, 0.68) * etch;
    METALLIC = 0.0;
    SPECULAR = 0.5;
    ROUGHNESS = mix(0.07, 0.35, etch);
    vec3 transmission = textureLod(transmission_screen, SCREEN_UV, 0.0).rgb;
    float reflection = 0.04 + 0.96 * grazing;
    vec3 tint = mix(vec3(0.965, 0.985, 0.99), glass_tint, border * 0.3);
    EMISSION = transmission * tint * (1.0-reflection) * (1.0-etch * 0.6);
    EMISSION += ceiling_radiance * reflection * ceiling_reflection(INV_VIEW_MATRIX[3].xyz);
    ALPHA = 1.0;
}
