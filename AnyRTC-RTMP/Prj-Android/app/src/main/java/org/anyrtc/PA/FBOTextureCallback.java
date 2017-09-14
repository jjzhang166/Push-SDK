package org.anyrtc.PA;

import org.anyrtc.PA.gles.FBO_NEW;
import org.webrtc.Logging;
import org.webrtc.CaptureTextureCallback;


/**
 * Created by kanli on 12/18/16.
 */
import android.content.Context;

public class FBOTextureCallback implements CaptureTextureCallback {
    private Context mContext = null;
    private FBO_NEW mFBO = null;

    public FBOTextureCallback(Context context, FBO_NEW fbo) {
        mContext = context;
        mFBO = fbo;
    }

    @Override
    public void onSurfaceCreated() {
        mFBO.initialize(mContext);
    }

    @Override
    public void onSurfaceChanged(int width, int height) {
        mFBO.updateSurfaceSize(width, height);
    }

    @Override
    public void onSurfaceDestroyed() {
        mFBO.release();
    }

    @Override
    public FrameInfo onDrawFrame(int texId, int texWidth, int texHeight, float[] transformMatrix) {
        Logging.e("TextureCallback", "before mFBO.drawFrame");
        FrameInfo frameInfo = mFBO.drawFrame(texId, texWidth, texHeight);
        frameInfo.transformMatrix = transformMatrix;
        Logging.e("TextureCallback", "after mFBO.drawFrame");
        return frameInfo;
    }
}
