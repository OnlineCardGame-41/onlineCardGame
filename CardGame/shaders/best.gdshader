shader_type canvas_item;

uniform vec3 color_a : source_color = vec3(1.0, 0., 0.);
uniform vec3 color_b : source_color = vec3(1., 1., .0);
uniform vec3 color_c : source_color = vec3(.0, .0, 1.0);

uniform float scale = 2.0;
uniform float time_speed = 0.1;
uniform float blend = .01;
uniform float frequency = 3.0;
uniform float amplitude = 3.333;
uniform float x_offset = 0.0;
uniform float square_count = 100;

vec2 random_gradient(vec2 p) {
    float angle = fract(sin(dot(p, vec2(23.1, 78.2))) * 43758.5453) * 6.28318;
    return vec2(cos(angle), sin(angle));
}

float perlin(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    vec2 g00 = random_gradient(i);
    vec2 g10 = random_gradient(i + vec2(1.0, 0.0));
    vec2 g01 = random_gradient(i + vec2(0.0, 1.0));
    vec2 g11 = random_gradient(i + vec2(1.0, 1.0));

    vec2 d00 = f - vec2(0.0, 0.0);
    vec2 d10 = f - vec2(1.0, 0.0);
    vec2 d01 = f - vec2(0.0, 1.0);
    vec2 d11 = f - vec2(1.0, 1.0);

    float v00 = dot(g00, d00);
    float v10 = dot(g10, d10);
    float v01 = dot(g01, d01);
    float v11 = dot(g11, d11);

    vec2 u = f * f * (3.0 - 2.0 * f);

    float x1 = mix(v00, v10, u.x);
    float x2 = mix(v01, v11, u.x);
    return mix(x1, x2, u.y) * 0.5 + 0.5;
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
	float f = 1.0;
    for (int i = 0; i < 10; i++) {
        v += a * perlin(f * p);
        f *= 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
	float t = time_speed * TIME;
	vec2 uv = UV * scale + 0.25*t;

	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    uv.x *= aspect;

    uv = floor(uv * square_count) / square_count;
    uv.x /= aspect;



	for (int i = 1; i <= 8; i++) {
        float fi   = float(i);
        float s    =  1. / (fi * amplitude);
        float freq = fi * frequency;
        uv.x += s * sin(freq * uv.y + t);
        uv.y += s * cos(freq * uv.x + t);
    }

    float na = fbm(uv + vec2(1.2, 3.4));
    float nb = fbm(uv + vec2(5.6, 7.8));
    float nc = fbm(uv + vec2(9.0, 1.1));

    float max_n = max(max(na, nb), nc);

    float wa = smoothstep(max_n - blend, max_n + blend, na);
    float wb = smoothstep(max_n - blend, max_n + blend, nb);
    float wc = smoothstep(max_n - blend, max_n + blend, nc);

    float total = wa + wb + wc;
    wa /= total;
    wb /= total;
    wc /= total;

    COLOR.rgb = wa * color_a + wb * color_b + wc * color_c;
}
