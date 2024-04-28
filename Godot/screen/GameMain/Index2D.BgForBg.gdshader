shader_type canvas_item;

void fragment() {
	vec4 sum = vec4(0.0, 0.0, 0.0, 0.0);
	vec2 amount = 20. / vec2(textureSize(TEXTURE, 0));
	
	
	sum += texture(TEXTURE, UV + vec2(-1, -1) * amount) * 0.048;
	sum += texture(TEXTURE, UV + vec2(-1, 1) * amount) * 0.048;
	sum += texture(TEXTURE, UV + vec2(1, -1) * amount) * 0.048;
	sum += texture(TEXTURE, UV + vec2(1, 1) * amount) * 0.048;
	sum += texture(TEXTURE, UV + vec2(1, 0) * amount) * 0.143;
	sum += texture(TEXTURE, UV + vec2(-1, 0) * amount) * 0.143;
	sum += texture(TEXTURE, UV + vec2(0, -1) * amount) * 0.143;
	sum += texture(TEXTURE, UV + vec2(0, 1) * amount) * 0.143;
	sum += texture(TEXTURE, UV + vec2(0, 0) * amount) * 0.236;

	COLOR = vec4(sum.xyz * 0.27, 1.0);
}
