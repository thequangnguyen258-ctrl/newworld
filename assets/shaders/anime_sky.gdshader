shader_type sky;

uniform vec3 top_color : source_color = vec3(0.24, 0.52, 0.88); // Sky blue
uniform vec3 horizon_color : source_color = vec3(0.85, 0.92, 0.98); // Soft pale blue/white
uniform vec3 bottom_color : source_color = vec3(0.72, 0.84, 0.90);
uniform vec3 sun_color : source_color = vec3(1.0, 0.96, 0.82);
uniform float sun_size : hint_range(0.01, 0.2) = 0.05;
uniform float sun_blur : hint_range(0.01, 0.5) = 0.04;

// Quầng sáng rực rỡ chân trời (Bình minh vàng mật / Hoàng hôn tím hồng)
uniform vec3 horizon_glow_color : source_color = vec3(1.0, 0.72, 0.45);
uniform float horizon_glow_intensity : hint_range(0.0, 2.0) = 0.0;

// Bầu trời đêm sao lung linh (Anime Stars)
uniform float stars_intensity : hint_range(0.0, 1.5) = 0.0;
uniform float stars_twinkle_speed : hint_range(0.5, 10.0) = 3.5;

// Cloud styling
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shadow_color : source_color = vec3(0.82, 0.88, 0.94);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.45;
uniform float cloud_speed : hint_range(0.0, 0.1) = 0.006;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float val = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        val += amp * noise(p);
        p *= 2.1;
        amp *= 0.48;
    }
    return val;
}

void sky() {
    float elevation = EYEDIR.y;
    
    // Smooth horizon gradient
    vec3 sky_base = mix(horizon_color, top_color, clamp(elevation * 1.8, 0.0, 1.0));
    if (elevation < 0.0) {
        sky_base = mix(horizon_color, bottom_color, clamp(-elevation * 2.0, 0.0, 1.0));
    }
    
    // Quầng sáng rực chân trời (Horizon glow)
    if (horizon_glow_intensity > 0.01) {
        float h_band = exp(-abs(elevation) * 7.0) * horizon_glow_intensity;
        sky_base += horizon_glow_color * h_band;
    }
    
    // Mặt trời Toon (chỉ hiện khi nhô lên trên đường chân trời)
    float sun_vis = clamp(LIGHT0_DIRECTION.y * 4.0, 0.0, 1.0);
    float sun_dist = distance(EYEDIR, LIGHT0_DIRECTION);
    float sun_disc = smoothstep(sun_size + sun_blur, sun_size, sun_dist);
    sky_base += sun_color * sun_disc * 0.9 * sun_vis;
    
    // Bầu trời sao anime lung linh ban đêm (Twinkling Anime Stars)
    if (stars_intensity > 0.01 && elevation > 0.03) {
        vec2 star_uv = EYEDIR.xz / (elevation + 0.35) * 45.0;
        vec2 star_id = floor(star_uv);
        float star_rnd = hash(star_id);
        if (star_rnd > 0.92) {
            vec2 star_center = star_id + 0.5;
            float d = length(star_uv - star_center);
            float twinkle = 0.65 + 0.35 * sin(TIME * stars_twinkle_speed + star_rnd * 25.0);
            float star_sparkle = smoothstep(0.35, 0.04, d) * twinkle * stars_intensity;
            vec3 star_tint = mix(vec3(0.85, 0.92, 1.0), vec3(1.0, 0.96, 0.82), fract(star_rnd * 13.0));
            sky_base += star_tint * star_sparkle * 1.6;
        }
    }
    
    // Mây Anime cách điệu (Stylized Cumulus Clouds)
    if (elevation > 0.05) {
        vec2 cloud_uv = EYEDIR.xz / (elevation + 0.15);
        cloud_uv += vec2(TIME * cloud_speed, TIME * cloud_speed * 0.4);
        
        float c_noise = fbm(cloud_uv * 1.8);
        float cloud_mask = smoothstep(1.0 - cloud_coverage, 1.0 - cloud_coverage + 0.15, c_noise);
        
        vec3 final_cloud = mix(cloud_shadow_color, cloud_color, smoothstep(1.0 - cloud_coverage + 0.05, 1.0 - cloud_coverage + 0.25, c_noise));
        sky_base = mix(sky_base, final_cloud, cloud_mask * clamp(elevation * 3.0, 0.0, 0.95));
    }

    COLOR = sky_base;
}

