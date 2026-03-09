shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform sampler2D direction_texture : hint_default_black, filter_nearest;
uniform int grid_width = 20;
uniform int grid_height = 20;
uniform float time_offset = 0.0;  // Passed from PathOverlay.gd each frame
uniform float arrow_brightness = 0.6;

// Draw an arrow shape in local cell UV [0,1]^2 pointing in direction dir_norm.
// Returns alpha value for the arrow glyph.
float arrow_alpha(vec2 cell_uv, vec2 dir_norm) {
    // Center the cell UV
    vec2 uv = cell_uv - vec2(0.5);
    // Project onto direction and perpendicular
    float fwd = dot(uv, dir_norm);
    float side = abs(dot(uv, vec2(-dir_norm.y, dir_norm.x)));
    // Animated scroll: shift the fwd coordinate over time
    float anim_fwd = fract(fwd + time_offset);
    // Arrow body: thin rectangle
    float body = step(side, 0.08) * step(0.05, anim_fwd) * step(anim_fwd, 0.55);
    // Arrow head: triangle
    float head = step(side, 0.22 * (0.72 - anim_fwd)) * step(0.55, anim_fwd) * step(anim_fwd, 0.75);
    return clamp(body + head, 0.0, 1.0);
}

void fragment() {
    // Determine which grid cell this fragment belongs to
    vec2 grid_uv = UV * vec2(float(grid_width), float(grid_height));
    ivec2 cell = ivec2(int(grid_uv.x), int(grid_uv.y));
    vec2 cell_local_uv = fract(grid_uv);

    // Sample direction texture (encoded as RG = direction.x, direction.y, remapped from [-1,1] to [0,1])
    vec4 dir_sample = texelFetch(direction_texture, cell, 0);
    vec2 dir = dir_sample.rg * 2.0 - vec2(1.0);  // Remap [0,1] -> [-1,1]

    // If direction is zero (exit cell or unreachable), no arrow
    float dir_len = length(dir);
    if (dir_len < 0.1) {
        ALBEDO = vec3(0.0);
        ALPHA = 0.0;
        return;
    }

    vec2 dir_norm = dir / dir_len;
    float alpha = arrow_alpha(cell_local_uv, dir_norm);

    // Glow color: teal/cyan
    ALBEDO = vec3(0.1, 0.9, 0.8) * arrow_brightness;
    ALPHA = alpha * 0.85;
}
