shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
/* ----------  настраиваемые параметры  ---------- */
uniform float speed : hint_range(0.0, 1.0) = 0.1;   // скорость течения
uniform float scale : hint_range(0.1, 10.0) = 1.0;  // «зум» узора
uniform int   steps : hint_range(1, 32) = 32;       // слоёв искажения
/* ---------------------------------------------- */

void fragment()
{

    /* 1. нормализованные экранные координаты (0-1)  */
    vec2 p = UV + vec2(1.0);  // +1 — как в вашем шейдере
    p *= scale;                      // общий масштаб
	float t    = TIME * speed;
    /* 2. domain-warping ‒ псевдо-фрактальное искажение */
    for (int i = 1; i < steps; i++) {
        float fi   = float(i);
        float s    = 0.3 / fi;              // амплитуда (затухает)
        float freq = fi * 3.0;              // частота волн

        p.x += s * sin(freq * p.y + t);
        p.y += s * cos(freq * p.x + t);
    }

    /* 3. плавная синус-палитра (пастельные разводы) */
    float sum = p.x + p.y;
    float r = 0.5 + 0.5 *  cos(sum + 1.0);
    float g = 0.5 + 0.5 *  sin(sum + 1.0);
    float b = 0.5 + 0.3 * (sin(sum) + cos(sum));
    COLOR = vec4(r, g, b, 1.0);
}
