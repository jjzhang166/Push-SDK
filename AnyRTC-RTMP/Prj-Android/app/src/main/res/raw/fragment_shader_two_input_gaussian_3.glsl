#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform sampler2D uCamTexture;
varying mediump vec2 vCamTextureCoord;

uniform samplerExternalOES uImageTexture;
varying mediump vec2 vImageTextureCoord;

uniform mediump float xStep;
uniform mediump float yStep;

uniform mediump float beautyLevel;
uniform mediump float brightLevel;
uniform mediump float pinkLevel;
const highp mat3 saturateMatrix = mat3(
    1.1102, -0.0598, -0.061,
    -0.0774, 1.0826, -0.1186,
    -0.0228, -0.0228, 1.1772);

//const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);
uniform mediump mat3 gaussianMap;

vec3 hardLight(vec3 colorA, vec3 colorB) {
    return mix(
    2.0 * colorA * colorB,
    1.0 - 2.0 * (1.0 - colorA)*(1.0 - colorB),
    step(0.5,colorA));
}

vec3 softLight(vec3 colorA, vec3 colorB) {
    return mix(
    (2.0*colorA-1.0)*colorB*(1.0-colorB)+colorB,
    (2.0*colorA-1.0)*(sqrt(colorB)-colorB)+colorB,
    step(0.5,colorA));
}

vec3 linearLight(vec3 colorA, vec3 colorB) {
    return colorB+2.0*colorA-1.0;
}

vec3 screen(vec3 colorA, vec3 colorB) {
    return 1.0 - (1.0 - colorA) * (1.0 - colorB);
}

vec3 whiten(vec3 color, float brightLevel) {
    if (brightLevel <= 0.0) {
        return color;
    } else {
        float beta = brightLevel * 3.0 + 1.0;
        return log(color * (beta - 1.0)+ 1.0)/log(beta);
    }
}

void main(){
    vec4 color = texture2D(uImageTexture, vImageTextureCoord);

    float alpha = 0.4;
    vec2 stepVec = vec2(xStep, yStep);
    vec3 sum = vec3(.0,.0,.0);
    vec3 sum2 = vec3(.0,.0,.0);
    /*

    for (int i=-2;i<=2;i++) {
        for (int j=-2;j<=2;j++) {
            vec2 pos = vImageTextureCoord.xy + stepVec * vec2(i, j);
            vec4 color2 = texture2D(uImageTexture, pos);
            sum += gaussianMap[i>0?i:-i][j>0?j:-j] * color2.rgb ;
        }
    }
    */
    /*
    for (int i=-2;i<=2;i++) {
        for (int j=-2;j<=2;j++) {
            vec2 pos = vCamTextureCoord.xy + stepVec * vec2(i, j);
            vec4 color2 = texture2D(uCamTexture, pos);
            sum2 += gaussianMap[i>0?i:-i][j>0?j:-j] * color2.rgb ;
        }
    }
    */
    sum2 = texture2D(uCamTexture, vCamTextureCoord.xy).rgb;
    vec3 gaussinColor = sum;
    vec3 hiphpass = sum2;
    vec3 smoothColor = linearLight(hiphpass, color.rgb);

    vec3 beautyColor = mix(color.rgb, smoothColor, beautyLevel);
    vec3 pinkColor = mix(beautyColor, beautyColor * saturateMatrix, pinkLevel);
    vec3 whitenColor = whiten(pinkColor, brightLevel);

    gl_FragColor.rgb = whitenColor;
}

