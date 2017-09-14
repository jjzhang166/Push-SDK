package com.wangyong.demo.pushsdk.MagicFilter.filter.advanced;

import android.opengl.GLES20;

//import com.seu.magicfilter.R;
//import com.seu.magicfilter.filter.base.gpuimage.GPUImageFilter;
//import com.seu.magicfilter.utils.MagicParams;
//import com.seu.magicfilter.utils.OpenGlUtils;

import com.wangyong.demo.pushsdk.R;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageFilter;
import com.wangyong.demo.pushsdk.MagicFilter.utils.MagicParams;
import com.wangyong.demo.pushsdk.MagicFilter.utils.OpenGlUtils;

/**
 * Created by Administrator on 2016/5/22.
 */
public class MagicBeautyFilter extends GPUImageFilter{
    private int mSingleStepOffsetLocation;
    private int mParamsLocation;

    public MagicBeautyFilter(){
        super(NO_FILTER_VERTEX_SHADER ,
                OpenGlUtils.readShaderFromRawResource(R.raw.beauty));
    }

    protected void onInit() {
        super.onInit();
        mSingleStepOffsetLocation = GLES20.glGetUniformLocation(getProgram(), "singleStepOffset");
        mParamsLocation = GLES20.glGetUniformLocation(getProgram(), "params");
        setBeautyLevel(MagicParams.beautyLevel);
    }

    private void setTexelSize(final float w, final float h) {
        setFloatVec2(mSingleStepOffsetLocation, new float[] {2.0f / w, 2.0f / h});
    }

    @Override
    public void onInputSizeChanged(final int width, final int height) {
        super.onInputSizeChanged(width, height);
        setTexelSize(width, height);
    }

    public void setBeautyLevel(int level){
        switch (level) {
            case 0:
                setFloat(mParamsLocation, 0.0f);
                break;
            case 1:
                setFloat(mParamsLocation, 1.0f);
                break;
            case 2:
                setFloat(mParamsLocation, 0.8f);
                break;
            case 3:
                setFloat(mParamsLocation,0.6f);
                break;
            case 4:
                setFloat(mParamsLocation, 0.4f);
                break;
            case 5:
                setFloat(mParamsLocation,0.33f);
                break;
            default:
                break;
        }
    }

    public void onBeautyLevelChanged(){
        setBeautyLevel(MagicParams.beautyLevel);
    }
}
