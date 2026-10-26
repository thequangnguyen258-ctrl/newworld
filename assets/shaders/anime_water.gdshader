shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform vec4 shallow_color : source_color = vec4(0.28, 0.76, 0.84, 0.85);
uniform vec4 deep_color : source_color = vec4(0.12, 0.42, 0.65, 0.95);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);

uniform float wave_speed : hint_range(0.1, 2.0) = 0.6;
uniform float wave_amplitude : hint_range(0.01, 0.5) = 0.08;
uniform float wave_frequency : hint_range(0.1, 5.0) = 1.2;

void vertex() {
    float wave1 = sin(VERTEX.x * wave_frequency + TIME * wave_speed);
    float wave2 = cos(VERTEX.z * (wave_frequency * 0.8) + TIME * (wave_speed * 1.2));
    VERTEX.y += (wave1 + wave2) * wave_amplitude * 0.5;
}

void fragment() {
    float wave_pattern = sin((UV.x * 12.0) + TIME * wave_speed) * cos((UV.y * 12.0) + TIME * wave_speed * 0.9);
    vec3 water_color = mix(shallow_color.rgb, deep_color.rgb, clamp(wave_pattern * 0.5 + 0.5, 0.0, 1.0));
    
    // Crest foam
    float foam_edge = smoothstep(0.7, 0.85, wave_pattern);
    water_color = mix(water_color, foam_color.rgb, foam_edge * 0.5);
    
    ALBEDO = water_color;
    ALPHA = shallow_color.a;
    ROUGHNESS = 0.15;
    SPECULAR = 0.4;
}
