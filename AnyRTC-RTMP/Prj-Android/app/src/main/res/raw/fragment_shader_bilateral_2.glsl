#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES uCamTexture;
varying mediump vec2 vCamTextureCoord;
//const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);
uniform mediump float xStep;
uniform mediump float yStep;
uniform mediump mat3 gaussianMap;
const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);
void main(){
    vec4 color = texture2D(uCamTexture,vCamTextureCoord);
    vec2 stepVec = vec2(xStep, yStep);
    float sigma_r = 0.03;
    float sigma_r22 = 2.0 * sigma_r * sigma_r;
    vec3 sum1 = vec3(0.0, 0.0, 0.0);
    vec3 sum2 = vec3(0.0, 0.0, 0.0);
    for (int i=-2;i<=2;i++) {
        for (int j=-2;j<=2;j++) {
            vec2 pos = vCamTextureCoord.xy + stepVec * vec2(i, j);
            vec4 color2 = texture2D(uCamTexture, pos);
            vec3 distance = color.rgb - color2.rgb;
            vec3 f1 = exp(- distance * distance / sigma_r22) * gaussianMap[i>0?i:-i][j>0?j:-j];
            vec3 f2 = f1 * color2.rgb ;
            sum1 += f1;
            sum2 += f2;
        }
    }
    vec3 tmp = sum2/sum1;
    vec3 tmp2 = tmp.rgb - color.rgb + 0.5;
    gl_FragColor.rgb = tmp2;
}

