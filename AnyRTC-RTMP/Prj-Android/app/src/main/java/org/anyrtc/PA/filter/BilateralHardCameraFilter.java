package org.anyrtc.PA.filter;

import android.content.Context;
import android.opengl.GLES20;
import android.util.Log;
import android.util.StringBuilderPrinter;

import org.anyrtc.PA.gles.GLESTools;
import org.anyrtc.anyrtmp.R;

/**
 * Created by kanli on 1/12/17.
 */

public class BilateralHardCameraFilter extends OriginalHardCameraFilter {
    private static String FRAGMENTSHADER;


    private int xStepLoc;
    private int yStepLoc;
    private int glGaussianMapLoc;
    private float stepScale;

    protected int beautyLevelLoc;
    protected int brightLevelLoc;
    protected int pinkLevelLoc;

    private float beautyLevel = 0.0f;
    private float brightLevel = 0.0f;
    private float pinkLevel = 0.0f;

    float sigma_s = 2.0f;
    float[] gaussianMap = new float[9];


        /**
         * @param stepScale suggest:480P = 2,720P = 3
         */
    public BilateralHardCameraFilter(Context context, int stepScale) {
        super(null, GLESTools.readTextFile(context.getResources(), R.raw.fragment_shader_bilateral_3));
        this.stepScale = (float) stepScale;
    }

    @Override
    public void onInit(int inWidth, int inHeight, int outWidth, int outHeight) {
        super.onInit(inWidth, inHeight, outWidth, outHeight);
        yStepLoc = GLES20.glGetUniformLocation(glProgram, "yStep");
        xStepLoc = GLES20.glGetUniformLocation(glProgram, "xStep");

        beautyLevelLoc = GLES20.glGetUniformLocation(glProgram, "beautyLevel");
        brightLevelLoc = GLES20.glGetUniformLocation(glProgram, "brightLevel");
        pinkLevelLoc = GLES20.glGetUniformLocation(glProgram, "pinkLevel");

        //glGaussianMapLoc = GLES20.glGetUniformLocation(glProgram, "gaussianMap");
        float sigma_s22 = 2.0f * sigma_s * sigma_s;
        float sum = 0.0f;
        StringBuilder sb = new StringBuilder();
        for (int i=0;i<=2;i++) {
            for (int j = 0; j <= 2; j++) {
                float f = (float) Math.exp(-(i * i + j * j) / sigma_s22);
                gaussianMap[i * 3 + j] = f;
                sb.append(f);
                sb.append(" ");
                sum += f;
            }
            sb.append("\n");
        }

        Log.i("aa", sb.toString());
    }

    public void setBeautyLevel(float beautyLevel) {
        this.beautyLevel = beautyLevel;
    }
    public void setBrightLevel(float brightLevel) {
        this.brightLevel = brightLevel;
    }
    public void setPinkLevel(float pinkLevel) {
        this.pinkLevel = pinkLevel;
    }

    @Override
    protected void onPreDraw() {
        super.onPreDraw();
        GLES20.glUniform1f(xStepLoc, (float) (stepScale / IN_WIDTH));
        GLES20.glUniform1f(yStepLoc, (float) (stepScale / IN_HEIGHT));

        GLES20.glUniform1f(beautyLevelLoc, beautyLevel);
        GLES20.glUniform1f(brightLevelLoc, brightLevel);
        GLES20.glUniform1f(pinkLevelLoc, pinkLevel);

        //GLES20.glUniformMatrix3fv(glGaussianMapLoc, 1, false, gaussianMap, 0);
    }
}
