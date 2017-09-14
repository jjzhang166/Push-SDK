package org.anyrtc.anyrtmp;

import android.app.Activity;
import android.graphics.ColorMatrix;
import android.os.Bundle;
import android.os.PowerManager;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.SeekBar;
import android.widget.TextView;

import org.anyrtc.PA.PAPushSDK;
import org.webrtc.EglBase;
import org.webrtc.SurfaceViewRenderer;

import static org.anyrtc.PA.PAPushSDK.PAEventCode.*;
import static org.anyrtc.PA.PAPushSDK.PABitRate.*;
import static org.anyrtc.PA.PAPushSDK.PAResolution.*;

/**
 * Created by kanli on 12/6/16.
 */

public class PAHosterActivity extends Activity implements PAPushSDK.PAPushSDKCallbackHandler , View.OnTouchListener, SeekBar.OnSeekBarChangeListener {
    private PAPushSDK mHoster = null;
    private SurfaceViewRenderer mSurfaceView = null;

    private TextView mopi_tv = null;
    private TextView meibai_tv = null;
    private TextView fennen_tv = null;
    private TextView mTxtStatus = null;
    private boolean mCameraFront = false;
    private boolean mBeautyOn = false;
    private PowerManager.WakeLock mWakeLock = null;
    private void acquireWakeLock() {
        if (mWakeLock == null) {
            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
            mWakeLock = pm.newWakeLock(PowerManager.FULL_WAKE_LOCK, this.getClass().getCanonicalName());
            mWakeLock.acquire();
        }

    }

    private void releaseWakeLock() {
        if (mWakeLock != null && mWakeLock.isHeld()) {
            mWakeLock.release();
            mWakeLock = null;
        }

    }
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_pa_hoster);

        {//* Init UI
            mTxtStatus = (TextView) findViewById(R.id.txt_rtmp_status);
            mSurfaceView = (SurfaceViewRenderer) findViewById(R.id.suface_view);
        }

        {
            String rtmpUrl = getIntent().getExtras().getString("rtmp_url");
            mHoster = PAPushSDK.createPushSDK(this);
            mHoster.initPushSDK(this);
            mHoster.setWindow(mSurfaceView);
            mHoster.setParam(IA_540P, 25, 44100, 16, 1, IA_1Dot5M);
            mHoster.setupDevice();
            mHoster.setPushUrl(rtmpUrl);
            mHoster.startStreaming();
            mSurfaceView.setOnTouchListener(this);
        }

        {
            SeekBar seekBarBeauty = (SeekBar) findViewById(R.id.mopi_sb);
            seekBarBeauty.setOnSeekBarChangeListener(this);
            SeekBar seekBarWhite = (SeekBar) findViewById(R.id.meibai_sb);
            seekBarWhite.setOnSeekBarChangeListener(this);
            SeekBar seekBarPink = (SeekBar) findViewById(R.id.fennen_sb);
            seekBarPink.setOnSeekBarChangeListener(this);


            mopi_tv = (TextView) findViewById(R.id.mopi_value_tv);
            meibai_tv = (TextView) findViewById(R.id.meibai_value_tv);
            fennen_tv = (TextView) findViewById(R.id.fennen_value_tv);
            seekBarBeauty.setProgress(70);
            seekBarPink.setProgress(15);
            seekBarWhite.setProgress(30);
        }
    }
    @Override
    protected void onResume() {
        super.onResume();
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        //acquireWakeLock();
    }
    @Override
    protected void onPause() {
        super.onPause();
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        //releaseWakeLock();
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (mHoster != null) {
            mHoster.destroy();
            mHoster = null;
        }
    }
    /**
     * the button click event listener
     *
     * @param btn
     */
    public void OnBtnClicked(View btn) {
        if (btn.getId() == R.id.btn_close) {
            if (mHoster != null) {
                mHoster.stopStreaming();
                mHoster.destroy();
                mHoster = null;
            }
            finish();
        } else if (btn.getId() == R.id.btn_switch_camera) {
            if (null != mHoster) {
                mCameraFront = !mCameraFront;
                mHoster.setCameraFront(mCameraFront);
            }
        } else if (btn.getId() == R.id.btn_switch_beauty) {
            if (null != mHoster) {
                mBeautyOn = !mBeautyOn;
                mHoster.setBeautyFace(mBeautyOn);
            }
        }
    }
    @Override
    public void onMessage(final int resultId, final int resultCode, final Object reserved1, final Object reserved2) {
        switch (resultId) {
            case PA_PUSH_SPEED:
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        int delayMs = (int)reserved1;
                        int netBand = (int)reserved2;
                        mTxtStatus.setText(String.format(getString(R.string.str_rtmp_status), delayMs, netBand));
                    }
                });
                break;
        }
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        mHoster.setFocusAtPoint((int)(event.getX()), (int)(event.getY()));
        return true;
    }
    private float mBeauty = 0.0f;
    private float mWhite = 0.0f;
    private float mPink = 0.0f;
    @Override
    public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if (seekBar.getId() == R.id.mopi_sb) {
            mBeauty = progress / 100f;
            mopi_tv.setText(String.valueOf(mBeauty));
        } else if (seekBar.getId() == R.id.fennen_sb) {
            mPink = progress / 100f;
            fennen_tv.setText(String.valueOf(mPink));

        } else if (seekBar.getId() == R.id.meibai_sb) {
            mWhite = progress / 100f;
            meibai_tv.setText(String.valueOf(mWhite));
        }
        mHoster.setCameraBeautyFilterWithSmooth(mBeauty, mWhite, mPink);
    }

    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {
        // TODO
    }

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {
        // TODO
    }
}
