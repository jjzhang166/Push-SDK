#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform sampler2D uCamTexture;
varying mediump vec2 vCamTextureCoord;

uniform samplerExternalOES uImageTexture;
varying mediump vec2 vImageTextureCoord;

uniform mediump float xStep;
uniform mediump float yStep;


//const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);
uniform mediump mat3 gaussianMap;

void main(){
    vec4 color = texture2D(uImageTexture, vImageTextureCoord);

    float alpha = 0.4;
    vec2 stepVec = vec2(xStep, yStep);
    vec3 sum2 = vec3(.0,.0,.0);

    for (int i=-2;i<=2;i++) {
        for (int j=-2;j<=2;j++) {
            vec2 pos = vCamTextureCoord.xy + stepVec * vec2(i, j);
            vec4 color2 = texture2D(uCamTexture, pos);
            sum2 += gaussianMap[i>0?i:-i][j>0?j:-j] * color2.rgb ;
        }
    }
    vec3 tmp = sum2;
    vec3 tmp2 = color.rgb + tmp - 0.5;
    vec3 tmp3 = color.rgb * (1.0-alpha) + tmp2 * alpha;
    gl_FragColor.rgb = tmp3;
}

