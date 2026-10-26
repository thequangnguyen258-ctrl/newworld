shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(0.85, 0.88, 0.92, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 shadow_tint : source_color = vec4(0.55, 0.60, 0.72, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.01, 0.3) = 0.08;

uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.65;
uniform float rim_spread : hint_range(0.01, 0.5) = 0.15;

uniform float roughness : hint_range(0.0, 1.0) = 0.85;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    vec3 base_color = albedo_color.rgb * tex_color.rgb;
    
    ALBEDO = base_color;
    ROUGHNESS = roughness;
    SPECULAR = 0.1;
}

void light() {
    float ndotl = dot(NORMAL, LIGHT);
    float light_intensity = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ndotl);
    
    // Cel shaded diffuse
    vec3 diffuse = mix(ALBEDO * shadow_tint.rgb, ALBEDO, light_intensity);
    
    // Subtle Anime Rim light
    float ndotv = 1.0 - dot(NORMAL, VIEW);
    float rim_intensity = smoothstep(rim_threshold, rim_threshold + rim_spread, ndotv) * clamp(ndotl + 0.3, 0.0, 1.0);
    vec3 rim = rim_color.rgb * rim_intensity * rim_color.a;
    
    DIFFUSE_LIGHT += (diffuse * LIGHT_COLOR * ATTENUATION) + rim;
}
