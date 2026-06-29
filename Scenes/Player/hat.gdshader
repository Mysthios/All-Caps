shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_density : hint_range(0.0, 5.0) = 1.0;
uniform float line_falloff : hint_range(0.1, 10.0) = 1.0;
uniform float animation_speed : hint_range(0.0, 50.0) = 20.0;
uniform float line_mask : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // Generate stretched speed lines using the noise texture and UV
    vec2 uv = UV * vec2(line_density, 0.1);
    uv.x += TIME * animation_speed;
    
    float noise_value = texture(noise, uv).r;
    
    // Apply falloff for smoother anime-style lines
    float lines = pow(noise_value, line_falloff);
    
    // Create a circular or edge mask if you want to focus lines toward the center
    float mask = distance(UV, vec2(0.5, 0.5));
    mask = smoothstep(line_mask, 0.1, mask);
    
    vec4 final_color = line_color;
    final_color.a = lines * mask;
    
    COLOR = final_color;
}