shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center_offset : hint_range(-1.0, 1.0) = vec2(0.0);

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5) + center_offset;
    vec2 dir = uv - center;
    float dist = length(dir);
    
    float vignette = smoothstep(0.8, 0.2, dist * (1.0 + vignette_amount));
    
    float aberration = distortion_strength * (1.0 / (dist + 0.1));
    
    vec4 color_r = texture(TEXTURE, uv + dir * aberration * 0.02);
    vec4 color_g = texture(TEXTURE, uv);
    vec4 color_b = texture(TEXTURE, uv - dir * aberration * 0.02);
    
    vec4 final_color = vec4(color_r.r, color_g.g, color_b.b, 1.0);
    final_color.rgb *= vignette;
    
    COLOR = final_color;
}
