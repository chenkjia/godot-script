shader_type canvas_item;

uniform float sigma: hint_range(0.1, 20.0) = 3.3; // Limited to 20 because of performance, if you want feel free to break it.
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	COLOR.rgb = texture(SCREEN_TEXTURE, SCREEN_UV,sigma).rgb;
}
