shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float spark_freq : hint_range(0.0, 50.0) = 15.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    
    // 기본 투명도 영역이 아니면 연출도 없음
    if (tex_color.a < 0.01) discard;

    // 불규칙한 타오름을 위한 노이즈
    float n = noise(uv * 12.0 + TIME * 0.5);
    // progress를 -0.1 ~ 1.1 범위로 생각해서 시작과 끝이 자연스럽게 만듦
    float p = progress * 1.2 - 0.1;
    
    // 타오르는 불길의 경계선 (Wipe mask)
    float burn_line = p - (uv.x + n * 0.1);
    
    vec3 final_rgb = base_color.rgb;
    float alpha = tex_color.a;

    // 이미 타버린 곳 (로고 본체)
    if (burn_line > 0.0) {
        alpha = tex_color.a;
    } 
    // 타오르고 있는 경계선 (Heat zone)
    else if (burn_line > -0.15) {
        float heat = smoothstep(-0.15, 0.0, burn_line);
        
        // 색상 단계: 검정 -> 빨강 -> 주황 -> 노랑 -> 흰색
        vec3 fire = mix(vec3(0.8, 0.0, 0.0), vec3(1.0, 0.8, 0.0), heat);
        if (heat > 0.8) fire = mix(fire, vec3(2.0, 2.0, 2.0), (heat - 0.8) * 5.0);
        
        final_rgb = fire;
        alpha = heat * tex_color.a;
        
        // 지지직거리는 스파크 입자들
        float spark_n = random(uv * spark_freq + vec2(TIME * 15.0));
        if (spark_n > 0.95) {
            final_rgb = vec3(3.0, 3.0, 2.0); // 눈부신 하얀 빛
            alpha = tex_color.a;
        }
    } 
    // 아직 타지 않은 곳
    else {
        alpha = 0.0;
    }

    COLOR = vec4(final_rgb, alpha);
}
