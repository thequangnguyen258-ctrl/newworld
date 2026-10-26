shader_type spatial;
render_mode diffuse_toon, specular_toon;

// ==============================================================================
// ANIME MOUNTAIN ROCK & TRAIL SHADER (TÂN THẾ GIỚI - GHIBLI STYLE)
// Tự động phân chia thông minh:
// 1. Thảm cỏ xanh anime mượt mà trên đồng cỏ & sườn dốc thoai thoải
// 2. Đường mòn leo núi màu đất đá ấm áp dẫn đường lên đỉnh
// 3. Vách đá sa thạch phân tầng tự nhiên cho các gờ đá & sống núi
// 4. Đỉnh núi phủ tuyết trắng tinh khiết (+680m -> +710m)
// ==============================================================================

uniform vec4 grass_color : source_color = vec4(0.42, 0.76, 0.36, 1.0);
uniform vec4 rock_color_high : source_color = vec4(0.64, 0.58, 0.52, 1.0);
uniform vec4 rock_color_low : source_color = vec4(0.46, 0.42, 0.38, 1.0);
uniform vec4 trail_color : source_color = vec4(0.72, 0.64, 0.50, 1.0);
uniform vec4 snow_color : source_color = vec4(0.94, 0.96, 1.0, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.45, 0.52, 0.68, 1.0);

uniform float slope_threshold : hint_range(0.1, 0.9) = 0.52;
uniform float plateau_altitude : hint_range(50.0, 800.0) = 600.0;

varying vec3 v_world_pos;
varying float v_altitude;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_altitude = v_world_pos.y;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Tính độ dốc bề mặt (1.0 = Bằng phẳng nằm ngang, 0.0 = Dựng đứng thẳng tưng)
	float slope = v_world_normal.y;
	
	// Đá sa thạch tự nhiên mềm mại phong cách Anime/Ghibli
	float n1 = sin(v_altitude * 0.02 + v_world_pos.x * 0.015) * 0.5;
	float n2 = cos(v_world_pos.z * 0.02 + v_altitude * 0.01) * 0.5;
	float rock_factor = clamp(0.5 + (n1 + n2) * 0.25, 0.0, 1.0);
	vec3 rock = mix(rock_color_low.rgb, rock_color_high.rgb, rock_factor);
	
	// Rêu phong xanh ấm áp ở các vách đá ẩm ướt
	vec3 moss_color = vec3(0.38, 0.58, 0.32);
	float moss_mask = clamp(sin(v_world_pos.x * 0.04) * cos(v_world_pos.z * 0.04) * 0.5 + 0.5, 0.0, 1.0);
	rock = mix(rock, moss_color, moss_mask * 0.20 * (1.0 - slope));
	
	// Trộn màu cơ bản theo độ dốc: Bề mặt bằng phẳng/thoải = Cỏ xanh anime; Vách dốc đứng = Đá sa thạch
	vec3 terrain_color = mix(rock, grass_color.rgb, smoothstep(slope_threshold - 0.12, slope_threshold + 0.12, slope));
	
	// 2. Tô màu Đường Mòn Đi Bộ Leo Núi (Hiking Trail)
	// Đường mòn uốn lượn chữ S từ chân núi lên đỉnh ở sườn phía Bắc (Z < -10)
	if (v_world_pos.z < -10.0 && v_world_pos.z > -122.0) {
		float progress = clamp((-v_world_pos.z - 15.0) / 105.0, 0.0, 1.0);
		float trail_x = sin(progress * 3.14159 * 2.5) * 32.0 * (1.0 - progress * 0.6);
		float dist_trail = abs(v_world_pos.x - trail_x);
		if (dist_trail < 3.2) {
			float trail_mask = smoothstep(3.2, 1.2, dist_trail);
			// Hạt sỏi đá & đất vàng trên đường mòn
			float noise_trail = sin(v_world_pos.x * 0.5) * cos(v_world_pos.z * 0.5) * 0.1;
			vec3 trail_rgb = trail_color.rgb + vec3(noise_trail);
			terrain_color = mix(terrain_color, trail_rgb, trail_mask * 0.85);
		}
	}
	
	// 3. Đỉnh núi phủ tuyết trắng tinh khiết (+680m -> +710m)
	if (v_altitude > 675.0) {
		float snow_h = smoothstep(675.0, 700.0, v_altitude);
		float snow_slope = smoothstep(0.35, 0.70, slope);
		float snow_factor = snow_h * snow_slope;
		terrain_color = mix(terrain_color, snow_color.rgb, snow_factor);
	}
	
	ALBEDO = terrain_color;
	ROUGHNESS = 0.88;
	SPECULAR = 0.05;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float light_step = smoothstep(0.4, 0.48, ndotl);
	
	// Bóng đổ Cel-Shaded mang sắc lam tím anime
	vec3 diffuse = mix(ALBEDO * shadow_tint.rgb, ALBEDO, light_step);
	
	// Viền sáng mỏng (Rim light) tôn dáng vách núi
	float ndotv = 1.0 - dot(NORMAL, VIEW);
	float rim = smoothstep(0.7, 0.85, ndotv) * clamp(ndotl + 0.2, 0.0, 1.0) * 0.3;
	
	DIFFUSE_LIGHT += (diffuse * LIGHT_COLOR * ATTENUATION) + vec3(rim);
}
