shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix;

uniform sampler2D direction_texture : filter_nearest;
uniform int grid_width = 20;
uniform int grid_height = 20;
uniform float time_offset = 0.0;

void fragment() {
    // Map fragment to grid cell
    vec2 grid_uv = UV * vec2(float(grid_width), float(grid_height));
    vec2 cell_local = fract(grid_uv);
    ivec2 cell_id = ivec2(floor(grid_uv));

    // Sample direction — use center of texel to avoid interpolation bleed
    vec2 tex_uv = (vec2(cell_id) + vec2(0.5)) / vec2(float(grid_width), float(grid_height));
    vec4 s = texture(direction_texture, tex_uv);

    // Decode: encoded as (dir + 1.0) * 0.5, so remap back
    vec2 dir = s.rg * 2.0 - 1.0;
    float dir_len = length(dir);

    // has_dir = 1.0 when cell has a valid direction, 0.0 otherwise (exit cell / unreachable)
    float has_dir = step(0.1, dir_len);

    // Safe normalized direction (avoid divide-by-zero on zero-length dirs)
    vec2 dir_norm = dir / max(dir_len, 0.001);

    // Arrow in cell-local space (centered at 0.5, 0.5)
    vec2 uv = cell_local - vec2(0.5);
    float fwd  = dot(uv, dir_norm);
    float side = abs(dot(uv, vec2(-dir_norm.y, dir_norm.x)));
    float anim = fract(fwd + time_offset);

    float body = step(side, 0.08) * step(0.05, anim) * step(anim, 0.55);
    float head = step(side, 0.22 * (0.72 - anim)) * step(0.55, anim) * step(anim, 0.75);

    ALBEDO = vec3(0.1, 0.95, 0.85);
    ALPHA = clamp(body + head, 0.0, 1.0) * has_dir * 0.85;
}
