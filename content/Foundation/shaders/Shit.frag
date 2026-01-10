#pragma header

void main() {
    vec2 res = vec2(640.0,360.0);
    vec2 pos = getCamPos(openfl_TextureCoordv);
    pos = floor(pos * res) / res;

    vec2 diff = (vec2(0.5, 0.5) / res) / openfl_TextureSize * vec2(_camSize.y, _camSize.w);
    gl_FragColor = textureCam(bitmap, pos);
    gl_FragColor += textureCam(bitmap, pos + vec2(diff.x, 0.0));
    gl_FragColor += textureCam(bitmap, pos + vec2(-diff.x, 0.0));
    gl_FragColor += textureCam(bitmap, pos + vec2(0.0, diff.y));
    gl_FragColor += textureCam(bitmap, pos + vec2(0.0, -diff.y));
    gl_FragColor += textureCam(bitmap, pos + vec2(diff.x, -diff.y));
    gl_FragColor += textureCam(bitmap, pos + vec2(-diff.x, -diff.y));
    gl_FragColor += textureCam(bitmap, pos + vec2(diff.x, diff.y));
    gl_FragColor += textureCam(bitmap, pos + vec2(-diff.x, diff.y));
    gl_FragColor /= 9.0;
}


