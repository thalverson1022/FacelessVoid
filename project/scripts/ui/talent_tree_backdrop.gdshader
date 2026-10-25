shader_type canvas_item;
uniform vec2 rect_origin = vec2(2.0);
uniform vec2 rect_size = vec2(400.0);
uniform vec4 radii = vec4(6.0, 4.0, 3.0, 3.0);
uniform float darkness : hint_range(0.0, 1.0) = 0.65;
varying vec2 local_point;
void vertex() {
    local_point = VERTEX;
}
void fragment() {
    vec2 p = local_point - rect_origin - rect_size * 0.5;
    float radius = p.y < 0.0 ? (p.x < 0.0 ? radii.x : radii.y) : (p.x < 0.0 ? radii.z : radii.w);
    vec2 q = abs(p) - (rect_size * 0.5 - vec2(radius));
    float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float mask = 1.0 - smoothstep(-0.5, 0.5, distance_to_edge);
    vec4 source = texture(TEXTURE, UV);
    // Runtime black overlay; imported source image stays unmodified.
    COLOR = vec4(source.rgb * (1.0 - darkness), source.a * mask);
}
