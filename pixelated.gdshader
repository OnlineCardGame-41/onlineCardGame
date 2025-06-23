shader_type canvas_item;

/* ───── Uniforms ───── */
uniform float square_count : hint_range(10.0, 300.0) = 100.0; // “size” in original
uniform float x_offset = 1.5;                                 // initial scroll
/* ───────────────────── */

void fragment() {
    /* --- Screen-space UV --- */
    vec2 uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;   // 0-to-1 across the viewport

    /* --- Keep squares square on any resolution --- */
    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x; // (res_x / res_y)

    uv += vec2(x_offset, 0.0);   // horizontal offset like in Shadertoy
    uv.x *= aspect;

    /* --- Snap to grid --- */
    uv = floor(uv * square_count) / square_count;
    uv.x /= aspect;              // undo the squashing for later math

    /* --- Dynamic warping --- */
    float t = TIME;
    for (int i = 1; i <= 9; i++) {
        float fi   = float(i);
        float s    = 0.3 / fi;
        float freq = fi * 3.0;

        uv.x += s * sin(freq * uv.y + t);
        uv.y += s * cos(freq * uv.x + t);
    }

    /* --- Colour --- */
    float sum = uv.x + uv.y;
    vec3 col;
    col.r = 0.5 + 0.5 * cos(sum + 1.0);
    col.g = 0.5 + 0.5 * sin(sum + 1.0);
    col.b = 0.5 + 0.3 * (sin(sum) + cos(sum));

    COLOR = vec4(col, 1.0);
}
