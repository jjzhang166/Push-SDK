#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform sampler2D uCamTexture;
varying mediump vec2 vCamTextureCoord;

uniform samplerExternalOES uImageTexture;
varying mediump vec2 vImageTextureCoord;

uniform mediump float xStep;
uniform mediump float yStep;

const float maxdelta = 0.08;
const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);
const mediump mat3 gaussianMap = mat3(0.142,0.131,0.104,0.131,0.122,0.096,0.104,0.096,0.075);
mediump vec2 blurCoordinates[25];
mediump vec4 color2[25];
mediump vec4 diff[25];
mediump vec4 isBlur[25];
mediump mat3 gaussianMap2 = mat3(
          1.0,0.945959468907,0.800737402917,
          0.945959468907,0.894839316814,0.757465128397,
          0.800737402917,0.757465128397,0.64118038843);
mediump vec3 kernalData[25];

void main(){
    vec4 color = texture2D(uImageTexture, vImageTextureCoord);

    float sigma_r = 0.04;
    float sigma_s = 3.0;
    float alpha = 0.4;
    vec2 stepVec = vec2(xStep, yStep);

    float sigma_s22 = 2.0 * sigma_s * sigma_s;
    for (int i=0;i<=2;i++) {
        for (int j=0;j<=2;j++) {
            float f = - float(i*i+j*j)/sigma_s22;
            gaussianMap2[i][j]= exp(f);
        }
    }
    vec3 sum1 = vec3(.0,.0,.0);
    vec3 sum2 = vec3(.0,.0,.0);
    for (int i=-2;i<=2;i++) {
        for (int j=-2;j<=2;j++) {
            vec2 pos = vCamTextureCoord.xy + stepVec * vec2(i, j);
            vec4 color2 = texture2D(uCamTexture, pos);
            float f1 = gaussianMap2[i>0?i:-i][j>0?j:-j];
            vec3 f2 = f1 * color2.rgb ;
            sum1 += f1;
            sum2 += f2;
        }
    }
    vec3 tmp = sum2/sum1;
    vec3 tmp2 = color.rgb + 2.0 * tmp - 1.0;
    vec3 tmp3 = color.rgb * (1.0-alpha) + tmp2 * alpha;
    gl_FragColor = vec4(tmp3,1.0);
}

