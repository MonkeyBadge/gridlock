shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform sampler2D direction_texture : filter_nearest;
uniform int grid_width = 20;
uniform int grid_height = 20;
uniform float time_offset = 0.0;

void fragment() {
    // Map this fragment to a grid cell
    vec2 grid_uv = UV * vec2(float(grid_width), float(grid_height));
    vec2 cell_local = fract(grid_uv);

    // Sample direction from texture using normalised UV
    vec2 tex_uv = (floor(grid_uv) + vec2(0.5)) / vec2(float(grid_width), float(grid_height));
    vec4 sample = texture(direction_texture, tex_uv);

    // Decode: R/G encoded as (value + 1.0) * 0.5  →  remap back to [-1, 1]
    vec2 dir = sample.rg * 2.0 - vec2(1.0);

    float dir_len = length(dir);
    if (dir_len < 0.1) {
        ALBEDO = vec3(0.0);
        ALPHA = 0.0;
        return;
    }

    vec2 dir_norm = dir / dir_len;

    // Draw animated arrow in cell-local UV space
    vec2 uv = cell_local - vec2(0.5);
    float fwd = dot(uv, dir_norm);
    float side = abs(dot(uv, vec2(-dir_norm.y, dir_norm.x)));
    float anim = fract(fwd + time_offset);

    float body = step(side, 0.08) * step(0.05, anim) * step(anim, 0.55);
    float head = step(side, 0.22 * (0.72 - anim)) * step(0.55, anim) * step(anim, 0.75);
    float alpha = clamp(body + head, 0.0, 1.0);

    ALBEDO = vec3(0.1, 0.9, 0.8) * 0.8;
    ALPHA = alpha;
}
