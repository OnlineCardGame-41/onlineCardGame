shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float speed : hint_range(0.0, 1.0) = 0.01;   
uniform float scale : hint_range(0.1, 10.0) = 1.0;  
uniform int   steps : hint_range(1, 32) = 16;       

void fragment()
{

    vec2 p = UV + vec2(1.0); 
    p *= scale;                      
	float t    = TIME * speed;
    
    for (int i = 1; i < steps; i++) {
        float fi   = float(i);
        float s    = 0.3 / fi;              
        float freq = fi * 3.0;              

        p.x += s * sin(freq * p.y + t);
        p.y += s * cos(freq * p.x + t);
    }

    
    float sum = p.x + p.y;
    float r = 0.5 + 0.5 *  cos(sum + 1.0);
    float g = 0.5 + 0.5 *  sin(sum + 1.0);
    float b = 0.5 + 0.3 * (sin(sum) + cos(sum));
    COLOR = vec4(r, g, b, 1.0);
}
