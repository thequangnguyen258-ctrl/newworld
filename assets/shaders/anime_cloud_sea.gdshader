shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// Shader Biển Mây Anime bồng bềnh lưng chừng núi
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.82);
uniform vec4 shadow_cloud_color : source_color = vec4(0.82, 0.88, 0.95, 0.75);
uniform float speed : hint_range(0.001, 0.05) = 0.008;
uniform float wave_scale : hint_range(0.001, 0.05) = 0.006;

void vertex() {
	// Lượn sóng nhẹ nhàng
	float wave = sin((VERTEX.x * wave_scale + TIME * speed * 2.0)) * cos((VERTEX.z * wave_scale + TIME * speed * 1.5)) * 4.0;
	VERTEX.y += wave;
}

void fragment() {
	vec2 uv_scroll = UV + vec2(TIME * speed, TIME * speed * 0.7);
	float wave_pattern = sin(uv_scroll.x * 20.0) * cos(uv_scroll.y * 20.0) * 0.5 + 0.5;
	
	vec4 final_color = mix(shadow_cloud_color, cloud_color, wave_pattern);
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a * 0.85;
	ROUGHNESS = 0.9;
}
