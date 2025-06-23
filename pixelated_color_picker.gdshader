shader_type canvas_item;

uniform int square_count  = 100;
uniform float x_offset      = 0.0;

uniform vec3 color_a: source_color   = vec3(1.0, 0.2, 0.2);
uniform vec3 color_b: source_color   = vec3(0.2, 0.2, 1.0);
uniform vec3 color_c: source_color   = vec3(0.2, 0.2, 1.0);
uniform float blend_speed = 1.0;  
uniform float split        : hint_range(0.0, 1.0) = 0.5; 
uniform int scale  = 1;
uniform float frequency = 3.0;
uniform float amplitude = 0.3;
void fragment() {
    vec2 uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE * float(scale);
    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    uv += vec2(x_offset, 0.0);
    uv.x *= aspect;

    uv = floor(uv * float(square_count)) / float(square_count);
    uv.x /= aspect;

    float t = TIME * blend_speed;
    for (int i = 1; i <= 18; i++) {
        float fi   = float(i);
        float s    =  1. / (fi * amplitude);
        float freq = fi * frequency;
        uv.x += s * sin(freq * uv.y + t);
        uv.y += s * cos(freq * uv.x + t);
    }

    float sum = uv.x + uv.y;
    float f = 0.5 + 0.5 * sin(sum + t);
    
	float invSplit = 1.0 / max(split, 0.0001);
	float invRem   = 1.0 / max(1.0 - split, 0.0001);
	float w1 = clamp(f * invSplit, 0.0, 1.0);
	float w2 = clamp((f - split) * invRem, 0.0, 1.0);
	vec3 colAB = mix(color_a, color_b, w1);
	vec3 col   = mix(colAB, color_c, w2);

    COLOR = vec4(col, 1.0);
}
