#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES uCamTexture;
varying mediump vec2 vCamTextureCoord;

uniform mediump float xStep;
uniform mediump float yStep;
//uniform mediump mat3 gaussianMap;

uniform mediump float beautyLevel;
uniform mediump float brightLevel;
uniform mediump float pinkLevel;

/*
const highp mat3 saturateMatrix = mat3(
    1.1102, -0.0598, -0.061,
    -0.0774, 1.0826, -0.1186,
    -0.0228, -0.0228, 1.1772);
*/
const mediump mat3 gaussianMap = mat3(
1.0, 0.8824969, 0.60653067,
0.8824969, 0.7788008, 0.53526145,
0.60653067, 0.53526145, 0.36787945
);
/**
 * saturate = 1.1 huerotate = -5
 */
const mediump mat3 saturateMatrix = mat3(
1.093347,-0.057819,0.052884,
-0.011132,1.029331,-0.121834,
-0.082215,0.028487,1.068950
);
const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);

vec3 whiten(vec3 color, float brightLevel) {
    float beta = brightLevel * 3.0 + 1.0;
    return (beta < 1.01)?color:log(color * (beta - 1.0)+ 1.0)/log(beta);
}
void main(){
    vec4 color = texture2D(uCamTexture,vCamTextureCoord);
    vec3 tmp = vec3(0.0, 0.0, 0.0);
    vec3 yuv = rgb2yuv * color.rgb;
    if(yuv.g<-0.225 || yuv.g>0.0 || yuv.b<0.022 || yuv.b>0.206){
        tmp = color.rgb;
    } else {
    vec2 stepVec = vec2(xStep, yStep);
    float sigma_r = 0.05;
    float sigma_r22 = 2.0 * sigma_r * sigma_r;
    vec3 sum1 = vec3(0.0, 0.0, 0.0);
    vec3 sum2 = vec3(0.0, 0.0, 0.0);
    for (int i=-2;i<=2;i++) {
        for (int j=-2;j<=2;j++) {
            vec2 pos = vCamTextureCoord.xy + stepVec * vec2(i, j);
            vec4 color2 = texture2D(uCamTexture, pos);
            vec3 distance = color.rgb - color2.rgb;
            vec3 f1 = exp(-distance * distance / sigma_r22) * gaussianMap[i>0?i:-i][j>0?j:-j];
            vec3 f2 = f1 * color2.rgb ;
            sum1 += f1;
            sum2 += f2;
        }
    }
    tmp = sum2/sum1;
    }
    //vec3 tmp2 = tmp.rgb - color.rgb + 0.5;

    vec3 beautyColor = mix(color.rgb, tmp, beautyLevel);
    vec3 pinkColor = mix(beautyColor, saturateMatrix * beautyColor, pinkLevel);
    vec3 whitenColor = whiten(pinkColor, brightLevel);

    gl_FragColor.rgb = whitenColor;
}

