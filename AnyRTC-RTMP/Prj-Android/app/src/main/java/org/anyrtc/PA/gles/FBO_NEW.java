package org.anyrtc.PA.gles;

import android.content.Context;
import android.opengl.GLES20;

import org.anyrtc.PA.filter.BaseHardVideoFilter;
import org.anyrtc.PA.filter.BeautyHardVideoFilter;
import org.anyrtc.PA.filter.BilateralHardCameraFilter;
import org.anyrtc.PA.filter.HSBHardVideoFilter;
import org.anyrtc.PA.filter.HardVideoGroupFilter;
import org.anyrtc.PA.filter.OriginalHardCameraFilter;
import org.anyrtc.PA.filter.SkinBlurHardVideoFilter;
import org.anyrtc.PA.filter.TowInputGaussianFilterHard;
import org.anyrtc.PA.filter.WhiteningHardVideoFilter;
import org.webrtc.CaptureTextureCallback;
import android.os.Trace;

import java.util.LinkedList;

/**
 * Created by kanli on 12/19/16.
 */

public class FBO_NEW {
    private static final String TAG = "FBO_NEW";

    private int mSurfaceWidth;
    private int mSurfaceHeight;
    private Context mContext;

    private int mInTexId;
    private int mInTexWidth;
    private int mInTexHeight;

    private int mOutTexId;
    private int mOutTexWidth;
    private int mOutTexHeight;

    // Used for off-screen rendering.
    private int mOffscreenProcessTexture;
    private int mOffscreenProcessFramebuffer;
    private int mOffscreenCameraTexture;
    private int mOffscreenCameraFramebuffer;

    SkinBlurHardVideoFilter mSkinBlurFilter = null;
    HSBHardVideoFilter mPinkFilter = null;
    WhiteningHardVideoFilter mWhiteFilter = null;
    BeautyHardVideoFilter mBeautyFilter = null;



    private BaseHardVideoFilter mVideoFilter = null;
    private TowInputGaussianFilterHard mVideoFilter2 = null;
    private BaseHardVideoFilter mCameraFilter = null;
    private BilateralHardCameraFilter mCameraFilter2 = null;

    private boolean mEnable = false;
    private float mSmooth = 0.0f;
    private float mWhite = 0.0f;
    private float mPink = 0.0f;

    public FBO_NEW(Context context) {
        mContext = context;
        mSkinBlurFilter = new SkinBlurHardVideoFilter(mContext, 3);
        mWhiteFilter = new WhiteningHardVideoFilter();
        mPinkFilter = new HSBHardVideoFilter();
        mBeautyFilter = new BeautyHardVideoFilter(mContext);
    }
    public void setFilterEnable(boolean enable) {
        mEnable = enable;
    }
    public void setFilterWithSmooth(float smooth, float white, float pink) {
        if (mSkinBlurFilter != null) {
            if (smooth >= 0.0f && smooth <= 1.0f) {
                mSkinBlurFilter.setScale(smooth * 5);
            }

        }
        if (mPinkFilter != null) {
            if (pink >= 0.0f && pink <= 1.0f) {
                mPinkFilter.reset();
                mPinkFilter.rotateHue(0.0f);
                mPinkFilter.adjustSaturation(1.0f);
                mPinkFilter.adjustBrightness(1.0f);

            }
        }
        if (mWhiteFilter != null) {
            if (white >= 0.0f && white <= 1.0f) {

            }
        }
        if (mBeautyFilter != null) {
            if (smooth >= 0.0f && smooth <= 1.0f) {
                mBeautyFilter.setBeautyLevel(smooth);
            }
            if (pink >= 0.0f && pink <= 1.0f) {
                mBeautyFilter.setToneLevel(pink);
            }
            if (white >= 0.0f && white <= 1.0f) {
                mBeautyFilter.setBrightLevel(white);
            }
        }
        if (mVideoFilter2 != null) {
            if (smooth >= 0.0f && smooth <= 1.0f) {
                mVideoFilter2.setBeautyLevel(smooth);
            }
            if (pink >= 0.0f && pink <= 1.0f) {
                mVideoFilter2.setPinkLevel(pink);
            }
            if (white >= 0.0f && white <= 1.0f) {
                mVideoFilter2.setBrightLevel(white);
            }
        }
        if (mCameraFilter2 != null) {
            if (smooth >= 0.0f && smooth <= 1.0f) {
                mCameraFilter2.setBeautyLevel(smooth);
            }
            if (pink >= 0.0f && pink <= 1.0f) {
                mCameraFilter2.setPinkLevel(pink);
            }
            if (white >= 0.0f && white <= 1.0f) {
                mCameraFilter2.setBrightLevel(white);
            }
        }
    }

    public void updateSurfaceSize(int width, int height) {
        mSurfaceWidth = width;
        mSurfaceHeight = height;
    }

    public void initialize(Context context) {
        if (mVideoFilter != null) {
            mVideoFilter.onDestroy();
        }
        if (mCameraFilter != null) {
            mCameraFilter.onDestroy();
        }

        /**
         * Create a new full frame renderer with beauty filter.
         * There are two another filter, you can have a try.
         */
        mCameraFilter2 = new BilateralHardCameraFilter(mContext, 2);
        mCameraFilter = new OriginalHardCameraFilter();
        mVideoFilter2 = new TowInputGaussianFilterHard(mContext, 2);
        mVideoFilter = new HardVideoGroupFilter(new LinkedList<BaseHardVideoFilter>(){{
            //add(mSkinBlurFilter);
            //add(mWhiteFilter);
            //add(mPinkFilter);
            add(mBeautyFilter);
        }});

        mOffscreenCameraTexture = 0;
        mOffscreenCameraFramebuffer = 0;
        mOffscreenProcessTexture = 0;
        mOffscreenProcessFramebuffer = 0;

    }

    public void release() {
        if (mOffscreenCameraTexture != 0) {
            GLHelper.releaseCamFrameBuff(
                    new int[]{mOffscreenCameraFramebuffer}, new int[]{mOffscreenCameraTexture});
        }
        if (mOffscreenProcessTexture != 0) {
            GLHelper.releaseCamFrameBuff(
                    new int[]{mOffscreenProcessFramebuffer}, new int[]{mOffscreenProcessTexture});
        }
        if (mVideoFilter != null) {
            mVideoFilter.onDestroy();
        }
        if (mCameraFilter != null) {
            mCameraFilter.onDestroy();
        }
    }

    /**
     * Prepares the off-screen framebuffer.
     */
    private void prepareFramebuffer(int inWidth, int inHeight, int outWidth, int outHeight) {
        int tex[] = new int[1];
        int fb[] = new int [1];
        GLHelper.createCamFrameBuff(fb, tex, outWidth, outHeight);
        mOffscreenCameraFramebuffer = fb[0];
        mOffscreenCameraTexture = tex[0];
        GLHelper.createCamFrameBuff(fb, tex, outWidth, outHeight);
        mOffscreenProcessFramebuffer = fb[0];
        mOffscreenProcessTexture = tex[0];
        mCameraFilter.onInit(inWidth, inHeight, outWidth, outHeight);
        mCameraFilter2.onInit(inWidth, inHeight, outWidth, outHeight);
        mVideoFilter.onInit(inWidth, inHeight, outWidth, outHeight);
        mVideoFilter2.onInit(inWidth, inHeight, outWidth, outHeight);
    }

    public CaptureTextureCallback.FrameInfo drawFrame(int texId, int texWidth, int texHeight) {
        Trace.beginSection("glFinish");
        CaptureTextureCallback.FrameInfo frameInfo = new CaptureTextureCallback.FrameInfo();

        if (mOffscreenCameraTexture == 0) {
            mInTexId = texId;
            mInTexWidth = texWidth;
            mInTexHeight = texHeight;
            if (mInTexWidth * 9/16 <= mInTexHeight) {
                mOutTexWidth = mInTexWidth;
                mOutTexHeight = mInTexWidth * 9 / 16;
            } else {
                mOutTexWidth = mInTexHeight * 16 / 9;
                mOutTexHeight = mInTexHeight;
            }
            prepareFramebuffer(mInTexWidth, mInTexHeight, mOutTexWidth, mOutTexHeight);
        }
        if (mEnable) {
            /*
            Logging.e(TAG, "onDraw 01");
            mCameraFilter2.onDraw(texId, mOffscreenCameraFramebuffer, GLHelper.getShapeVerticesBuffer(), GLHelper.getCameraTextureVerticesBuffer());
            Logging.e(TAG, "onDraw 02");
            if (mVideoFilter2 != null) {
                mVideoFilter2.setImageTexture(texId);
                mVideoFilter2.onDraw(mOffscreenCameraTexture, mOffscreenProcessFramebuffer, GLHelper.getShapeVerticesBuffer(), GLHelper.getCameraTextureVerticesBuffer());
                newTex = mOffscreenProcessTexture;
            }
            */
            mCameraFilter2.onDraw(mInTexId, mOffscreenCameraFramebuffer, GLHelper.getShapeVerticesBuffer(), GLHelper.getCameraTextureVerticesBuffer());
            mOutTexId = mOffscreenCameraTexture;
        } else {
            mCameraFilter.onDraw(mInTexId, mOffscreenCameraFramebuffer, GLHelper.getShapeVerticesBuffer(), GLHelper.getCameraTextureVerticesBuffer());
            mOutTexId = mOffscreenCameraTexture;
        }

        GLES20.glFinish();


        frameInfo.texId = mOutTexId;
        frameInfo.texWidth = mOutTexWidth;
        frameInfo.texHeight = mOutTexHeight;
        Trace.endSection();
        return frameInfo;
    }
}