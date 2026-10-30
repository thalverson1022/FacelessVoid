// Shared skill palette and macro: rounded display mask; source textures stay intact.
shader_type canvas_item;
uniform vec2 icon_size = vec2(40.0);
uniform float radius = 6.0;
uniform bool grayscale = false;
void fragment() {
    vec4 artwork = COLOR;
    vec2 q = abs((UV - vec2(0.5)) * icon_size) - (icon_size * 0.5 - vec2(radius));
    float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float mask = 1.0 - smoothstep(-0.5, 0.5, distance_to_edge);
    float border = smoothstep(-2.0, -1.0, distance_to_edge);
    artwork.rgb = mix(artwork.rgb, vec3(0.368627, 0.364706, 0.380392), border);
    if (grayscale) {
        artwork.rgb = vec3(dot(artwork.rgb, vec3(0.299, 0.587, 0.114)));
    }
    COLOR = vec4(artwork.rgb, artwork.a * mask);
}
