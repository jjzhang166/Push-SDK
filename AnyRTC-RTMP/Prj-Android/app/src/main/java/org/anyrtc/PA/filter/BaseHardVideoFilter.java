package org.anyrtc.PA.filter;

import org.anyrtc.PA.gles.GLHelper;

import java.nio.FloatBuffer;
import java.nio.ShortBuffer;

/**
 * Created by kanli on 12/19/16.
 */
public class BaseHardVideoFilter {
    protected int IN_WIDTH;
    protected int IN_HEIGHT;
    protected int OUT_WIDTH;
    protected int OUT_HEIGHT;
    protected int directionFlag=-1;
    protected ShortBuffer drawIndecesBuffer;

    public void onInit(int inWidth, int inHeight, int outWidth, int outHeight) {
        IN_WIDTH = inWidth;
        IN_HEIGHT = inHeight;
        OUT_WIDTH = outWidth;
        OUT_HEIGHT = outHeight;
        drawIndecesBuffer = GLHelper.getDrawIndecesBuffer();
    }

    public void onDraw(final int cameraTexture,final int targetFrameBuffer, final FloatBuffer shapeBuffer, final FloatBuffer textrueBuffer) {
    }

    public void onDestroy() {

    }

    public void onDirectionUpdate(int _directionFlag) {
        this.directionFlag = _directionFlag;
    }
}
