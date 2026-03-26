shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0., -1./3., 2./3., -1.);
    vec4 p = mix(vec4(c.bg, K.wz),
                 vec4(c.gb, K.xy),
                 step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
                 vec4(c.r, p.yzx),
                 step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1e-10;
    return vec3(
        abs(q.z + (q.w - q.y) / (6. * d + e)),
        d / (q.x + e),
        q.x
    );
}

vec3 hsv_to_rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0., 2./3., 1./3.)) * 6. - 3.);
    return c.z * mix(vec3(1.), clamp(p - 1., 0., 1.), c.y);
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec4 bg = texture(screen_tex, SCREEN_UV);

    vec3 base_hsv = rgb_to_hsv(base.rgb);
    vec3 bg_hsv = rgb_to_hsv(bg.rgb);

    vec3 result_hsv = vec3(base_hsv.x, base_hsv.y, bg_hsv.z);

    vec3 result = hsv_to_rgb(result_hsv);

    COLOR = vec4(result, base.a);
}