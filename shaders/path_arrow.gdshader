shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform sampler2D direction_texture : filter_nearest;
uniform int grid_width = 20;
uniform int grid_height = 20;
uniform float time_offset = 0.0;

void fragment() {
    ALBEDO = vec3(0.1, 0.9, 0.8);
    ALPHA = 0.5;
}
