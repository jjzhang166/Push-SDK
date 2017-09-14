package org.anyrtc.PA.filter;

import android.opengl.GLES20;

/**
 * Created by kanli on 12/22/16.
 */

public class ColorMatrixHardVideoFilter extends OriginalHardVideoFilter{
    private int mColorMatrixUniform;
    private int mIntensityUniform;

    protected final float[] mColorMatrix = new float[16];
    protected float mIntensity;


    protected static String FRAGMENTSHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 vCamTextureCoord;" +
            "uniform sampler2D uCamTexture;\n" +
            "uniform lowp mat4 uColorMatrix;\n" +
            "uniform lowp float uIntensity;\n" +
            "void main() {\n" +
            "   lowp vec4 textureColor = texture2D(uCamTexture, vCamTextureCoord);\n" +
            "   lowp vec4 outputColor = textureColor * uColorMatrix;\n" +
            "   gl_FragColor = (uIntensity * outputColor) + ((1.0 - uIntensity) * textureColor);\n" +
            "}\n" +
            ""
            ;
    /*
    protected static String FRAGMENTSHADER = "" +
            "precision mediump float;\n" +
            "varying mediump vec2 vCamTextureCoord;\n" +
            "uniform sampler2D uCamTexture;\n" +
            "uniform sampler2D uColorMapTexture;\n" +
            "void main(){\n" +
            "   vec4 c1 = texture2D(uCamTexture, vCamTextureCoord);\n" +
            "   float r = texture2D(uColorMapTexture, vec2(c1.r,0.0)).r;\n" +
            "   float g = texture2D(uColorMapTexture, vec2(c1.g,0.0)).g;\n" +
            "   float b = texture2D(uColorMapTexture, vec2(c1.b,0.0)).b;\n" +
            "   gl_FragColor = vec4(r,g,b,1.0);\n" +
            "}";
    */
    public ColorMatrixHardVideoFilter() {
        super(null, FRAGMENTSHADER);


    }

    @Override
    public void onInit(int inWidth, int inHeight, int outWidth, int outHeight) {
        super.onInit(inWidth, inHeight, outWidth, outHeight);
        mColorMatrixUniform = GLES20.glGetUniformLocation(glProgram, "uColorMatrix");
        mIntensityUniform = GLES20.glGetUniformLocation(glProgram, "uIntensity");
        mIntensity = 1.0f;
    }

    @Override
    public void onPreDraw() {
        super.onPreDraw();
        GLES20.glUniform1f(mIntensityUniform, mIntensity);
        synchronized (mColorMatrix) {
            GLES20.glUniformMatrix4fv(mColorMatrixUniform, 1, false, mColorMatrix, 0);
        }
    }

}
