package org.anyrtc.PA.filter;

import android.content.Context;
import android.opengl.GLES20;

import org.anyrtc.PA.gles.GLESTools;
import org.anyrtc.anyrtmp.R;


/**
 * Created by kanli on 12/22/16.
 */

public class BeautyHardVideoFilter extends OriginalHardVideoFilter {
    private int mInputImageTextureUniform = 0;
    private int mSingleStepOffsetUniform = 0;
    private int mParamsUniform = 0;
    private int mBrightnessUniform = 0;

    private float mBeautyLevel;
    private float mToneLevel;
    private float mBrightLevel;

    public BeautyHardVideoFilter(Context context) {
        super(null, GLESTools.readTextFile(context.getResources(), R.raw.fragment_shader_beauty_2));
        mToneLevel = 0.0f;
        mBeautyLevel = 0.0f;
        mBrightLevel = 0.0f;
    }

    public void setBeautyLevel(float beautyLevel) {
        mBeautyLevel = beautyLevel;
    }

    public void setToneLevel(float toneLevel) {
        mToneLevel = toneLevel;
    }

    public void setBrightLevel(float brightLevel) {
        mBrightLevel = brightLevel;
    }

    private void setParams(float beautyLevel, float brightLevel, float toneLevel) {
        float [] params = new float[4];
        params[0] = 1.0f - 0.6f * beautyLevel;
        params[1] = 1.0f - 0.3f * beautyLevel;
        params[2] = 0.1f + 0.3f * toneLevel;
        params[3] = 0.1f + 0.3f * toneLevel;
        GLES20.glUniform4fv(mParamsUniform, 1, params, 0);
        GLES20.glUniform1f(mBrightnessUniform, brightLevel);
    }

    @Override
    public void onInit(int inWidth, int inHeight, int outWidth, int outHeight) {
        super.onInit(inWidth, inHeight, outWidth, outHeight);
        mInputImageTextureUniform = GLES20.glGetUniformLocation(glProgram, "inputImageTexture");
        mSingleStepOffsetUniform = GLES20.glGetUniformLocation(glProgram, "singleStepOffset");
        mParamsUniform = GLES20.glGetUniformLocation(glProgram, "params");
        mBrightnessUniform = GLES20.glGetUniformLocation(glProgram, "brightness");
    }

    @Override
    public void onPreDraw() {
        setParams(mBeautyLevel, mBrightLevel, mToneLevel);
    }

}
