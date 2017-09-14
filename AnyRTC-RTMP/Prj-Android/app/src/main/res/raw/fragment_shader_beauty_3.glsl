precision mediump float;
varying highp vec2 vCamTextureCoord;

uniform sampler2D uCamTexture;

const float maxdelta = 0.08;
uniform mediump float xStep;
uniform mediump float yStep;
const mediump mat3 rgb2yuv = mat3(0.299,-0.147,0.615,0.587,-0.289,-0.515,0.114,0.436,-0.1);
const mediump mat3 gaussianMap = mat3(0.142,0.131,0.104,0.131,0.122,0.096,0.104,0.096,0.075);

uniform highp vec2 singleStepOffset;
uniform highp vec4 params;
uniform highp float brightness;

const highp vec3 W = vec3(0.299, 0.587, 0.114);
const highp mat3 saturateMatrix = mat3(
    1.1102, -0.0598, -0.061,
    -0.0774, 1.0826, -0.1186,
    -0.0228, -0.0228, 1.1772);

highp float hardLight(highp float color) {
    if (color <= 0.5)
        color = color * color * 2.0;
    else
        color = 1.0 - ((1.0 - color)*(1.0 - color) * 2.0);
    return color;
}


void main(){
    vec4 color = texture2D(uCamTexture,vCamTextureCoord);
    vec3 centralColor = color.rgb;
    float xfS = vCamTextureCoord.x - xStep*2.0;
    float yf = vCamTextureCoord.y - yStep*2.0;
    int x,y;
    float xf=xfS;
    vec4 sum=vec4(0.0,0.0,0.0,0.0);
    vec4 fact=vec4(0.0,0.0,0.0,0.0);
    vec4 tmp;
    vec4 color2;
    float gauss;


    color2 = texture2D(uCamTexture,vec2(xf,yf));

    for(y=-2;y<3;y+=1){
        if (yf < 0.0 || yf > 1.0){
            yf+=yStep;
            continue;
        }
        for(x=-2;x<3;x+=1){
            if (xf < 0.0 || xf > 1.0){
                xf+=xStep;
                continue;
            }
            color2 = texture2D(uCamTexture,vec2(xf,yf));
            tmp = color - color2;
            gauss = gaussianMap[x<0?-x:x][y<0?-y:y];
            if (abs(tmp.r) < maxdelta){
                sum.r += (color2.r*gauss);
                fact.r +=gauss;
            }
            if (abs(tmp.g) < maxdelta){
                sum.g += color2.g*gauss;
                fact.g +=gauss;
            }
            if (abs(tmp.b) < maxdelta){
                sum.b += color2.b*gauss;
                fact.b +=gauss;
            }
            xf+=xStep;
        }
        yf+=yStep;
        xf=xfS;
    }
    vec4 res = sum/fact;
    if(fact.r<1.0){
        tmp.r = color.r;
    }else{
        tmp.r = res.r;
    }
    if(fact.g<1.0){
        tmp.g = color.g;
    }else{
        tmp.g = res.g;
    }
    if(fact.b<1.0){
        tmp.b = color.b;
    }else{
        tmp.b = res.b;
    }
    float sampleColor = tmp.g;

    highp float highPass = centralColor.g - sampleColor + 0.5;

    for (int i = 0; i < 5; i++) {
        highPass = hardLight(highPass);
    }
    highp float lumance = dot(centralColor, W);

    highp float alpha = pow(lumance, params.r);

    highp vec3 smoothColor = centralColor + (centralColor-vec3(highPass))*alpha*0.1;

    smoothColor.r = clamp(pow(smoothColor.r, params.g), 0.0, 1.0);
    smoothColor.g = clamp(pow(smoothColor.g, params.g), 0.0, 1.0);
    smoothColor.b = clamp(pow(smoothColor.b, params.g), 0.0, 1.0);

    highp vec3 lvse = vec3(1.0)-(vec3(1.0)-smoothColor)*(vec3(1.0)-centralColor);
    highp vec3 bianliang = max(smoothColor, centralColor);
    highp vec3 rouguang = 2.0*centralColor*smoothColor + centralColor*centralColor - 2.0*centralColor*centralColor*smoothColor;

    gl_FragColor = vec4(mix(centralColor, lvse, alpha), 1.0);
    gl_FragColor.rgb = mix(gl_FragColor.rgb, bianliang, alpha);
    gl_FragColor.rgb = mix(gl_FragColor.rgb, rouguang, params.b);

    highp vec3 satcolor = gl_FragColor.rgb * saturateMatrix;
    gl_FragColor.rgb = mix(gl_FragColor.rgb, satcolor, params.a);
    gl_FragColor.rgb = vec3(gl_FragColor.rgb + vec3(brightness));
}