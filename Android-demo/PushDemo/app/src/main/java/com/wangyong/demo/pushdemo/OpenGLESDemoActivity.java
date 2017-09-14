package com.wangyong.demo.pushdemo;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.view.KeyEvent;
import android.view.TextureView;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.Toast;

import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.Constant;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;
import com.wangyong.demo.pushsdk.OpenGLESPushStreamInterfaces;

import static android.Manifest.permission.CAMERA;
import static android.Manifest.permission.GET_ACCOUNTS;
import static android.Manifest.permission.READ_EXTERNAL_STORAGE;
import static android.Manifest.permission.WRITE_EXTERNAL_STORAGE;

public class OpenGLESDemoActivity extends Activity implements View.OnClickListener, TextureView.SurfaceTextureListener, CallbackInterfaces.PushSDKCallback{

    private static final String TAG = "OpenGLESDemoActivity";

    private static final int REQUEST_GET_ACCOUNT = 112;
    private static final int PERMISSION_REQUEST_CODE = 200;
    private static final int RECORD_REQUEST_CODE = 300;

    private boolean started = false;

    private Context mContext = null;
    private Button gl_start_push_btn, gl_stop_push_btn, gl_restart_push_btn, enable_beauty_btn, denoise_btn, enable_filter_btn, start_mux_btn, stop_mux_btn, add_logo_btn, remove_logo_btn;
    private EditText gl_editText = null, beauty_level_input = null, filter_type_input = null, file_mux_input = null;
    private FrameLayout frameLayout;

    private String pushUrl = null;
    private OpenGLESPushStreamInterfaces openGLESPushStreamInterfaces = null;
    private int beauty_level = 0;

    private boolean inited = false;
    private boolean enable_denoise = false;

    private int iconPosition = 1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        mContext = this;

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        setContentView(R.layout.activity_opengl_es_demo);

        frameLayout = (FrameLayout) findViewById(R.id.gl_camera_surface_frame);
        gl_editText = (EditText) findViewById(R.id.gl_edit_text);
        beauty_level_input = (EditText) findViewById(R.id.beauty_level_input);

        gl_start_push_btn = (Button) findViewById(R.id.gl_start_push);
        gl_stop_push_btn = (Button) findViewById(R.id.gl_stop_push);
        gl_restart_push_btn = (Button) findViewById(R.id.gl_restart_push);
        enable_beauty_btn = (Button) findViewById(R.id.enable_beauty_level);
        denoise_btn = (Button) findViewById(R.id.gl_denoise);

        filter_type_input = (EditText) findViewById(R.id.filter_type_input);
        enable_filter_btn = (Button) findViewById(R.id.enable_filter);

        file_mux_input = (EditText) findViewById(R.id.file_muxer_input);
        start_mux_btn = (Button) findViewById(R.id.start_mux);
        stop_mux_btn = (Button) findViewById(R.id.stop_mux);

        add_logo_btn = (Button) findViewById(R.id.add_logo);
        remove_logo_btn = (Button) findViewById(R.id.remove_logo);

        gl_start_push_btn.setOnClickListener(this);
        gl_stop_push_btn.setOnClickListener(this);
        gl_restart_push_btn.setOnClickListener(this);
        enable_beauty_btn.setOnClickListener(this);
        denoise_btn.setOnClickListener(this);
        enable_filter_btn.setOnClickListener(this);
        start_mux_btn.setOnClickListener(this);
        stop_mux_btn.setOnClickListener(this);
        add_logo_btn.setOnClickListener(this);
        remove_logo_btn.setOnClickListener(this);

        init();

        TextureView textureView = (TextureView)findViewById(R.id.txv_preview);
        textureView.setSurfaceTextureListener(this);
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.gl_start_push:
                start();
                break;
            case R.id.gl_stop_push:
                stop();
                break;
            case R.id.enable_beauty_level:
                setBeautyLevel();
                break;
            case R.id.gl_restart_push:
                restart();
                break;
            case R.id.gl_denoise:

                enable_denoise = !enable_denoise;

                if (enable_denoise)
                    denoise_btn.setText("NS-Y");
                else
                    denoise_btn.setText("NS-N");

                denoise(enable_denoise);
                break;
            case R.id.enable_filter:
                setFilterType();
                break;
            case R.id.start_mux:
                startMux();
                break;
            case R.id.stop_mux:
                stopMux();
                break;
            case R.id.add_logo:
                addLogo();
                break;
            case R.id.remove_logo:
                removeLogo();
                break;

        }
    }

    /******************** Private ********************/

    private void addLogo() {
        if (null != openGLESPushStreamInterfaces) {
            Bitmap bitmap = BitmapFactory.decodeResource(this.getResources(), R.drawable.ic_launcher);
            Rect rect = new Rect();
            rect.left = rect.top = 50 * iconPosition;
            rect.right = rect.bottom = rect.top + 60;
            iconPosition += 1;
            openGLESPushStreamInterfaces.addVideoIcon(bitmap, rect);
        }
    }

    private void removeLogo() {
        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.removeIcon(0);
    }

    private void setFilterType() {
        int filter = Integer.valueOf(filter_type_input.getText().toString());

        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.setFilterType(filter);
    }

    private void denoise(boolean denoise) {
        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.denoise(denoise);
    }

    private void init() {

        pushUrl = gl_editText.getText().toString();
        String level = beauty_level_input.getText().toString();
        beauty_level = Integer.valueOf(level);
//
//        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
//        frameLayout.removeAllViews();

        int rotation = ((WindowManager)mContext.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation();
        openGLESPushStreamInterfaces = new OpenGLESPushStreamInterfaces(mContext, rotation, 720, 480, 25, 500, 16000, 16, 1, 60);

        addLogo();

//        frameLayout.addView(view, lp);

//        openGLESPushStreamInterfaces.setPushSDKCallback(this, 2);

        inited = true;
    }

    private void start() {

        if (true == started)
            return;

        if (false == inited)
            init();

        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.startPushStream();

        started = true;
    }

    private void stop() {

        if (null != openGLESPushStreamInterfaces) {
            openGLESPushStreamInterfaces.stopPushStream();
            openGLESPushStreamInterfaces.destory();
        }

        openGLESPushStreamInterfaces = null;
        inited = false;
        started = false;
    }

    private void setBeautyLevel(){
        beauty_level = Integer.valueOf(beauty_level_input.getText().toString());

        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.setBeautyLevel(beauty_level, beauty_level, beauty_level);
    }

    private void restart() {
        stop();
        start();
    }

    private void startMux() {

        String filePath = file_mux_input.getText().toString();

        filePath = Environment.getExternalStorageDirectory().getPath() + "/mux.mp4";
        Loging.Log(TAG, "Output file path : " + filePath.toString());
        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.startWonderfulfileMuxer(filePath.toString());

    }

    private void stopMux() {
        if (null != openGLESPushStreamInterfaces)
            openGLESPushStreamInterfaces.stopWonderfulfileMuxer();
    }

    @Override
    public int onPushSDKCallback(int type, long info, long param1, long param2){

        switch (type) {
            case Constant.INFO_UPDATE_PUSH_SPEED:
                Loging.Log(TAG, "Push speed : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_AUDIO_CAPTURE_FPS:
                Loging.Log(TAG, "Audio capture fps : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_AUDIO_ENCODED_FPS:
                Loging.Log(TAG, "Audio encoder fps : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_AUDIO_FPS:
                Loging.Log(TAG, "Audio push fps : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_VIDEO_FPS:
                Loging.Log(TAG, "Video push FPS : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_VIDEO_CAPTURE_FPS:
                Loging.Log(TAG, "Video capture FPS : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_VIDEO_ENCODED_FPS:
                Loging.Log(TAG, "Video encoder FPS : " + info);
                break;
            case Constant.INFO_UPDATE_PUSH_AUDIO_CAPTURE_BLOCK:
                Loging.Log(Loging.LOG_ERROR, TAG, "Audio capture blocked !!!");
                break;
            case Constant.INFO_UPDATE_PUSH_AUDIO_ENCODER_BLOCK:
                Loging.Log(Loging.LOG_ERROR, TAG, "Audio encoder blocked !!!");
                break;
            case Constant.INFO_UPDATE_PUSH_VIDEO_CAPTURE_BLOCK:
                Loging.Log(Loging.LOG_ERROR, TAG, "Video capture blocked !!!");
                break;
            case Constant.INFO_UPDATE_PUSH_VIDEO_ENCODER_BLOCK:
                Loging.Log(Loging.LOG_ERROR, TAG, "Video encoder blocked !!!");
                break;
            case Constant.INFO_UPDATE_RTMP_PUSH_RETURN:
                Loging.Log(Loging.LOG_ERROR, TAG, "RTMP send return : " + info);
                break;
            default:
                Loging.Log(TAG, "Unknown callback type : " + type);
        }

        return 0;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        // TODO Auto-generated method stub
        if(keyCode == KeyEvent.KEYCODE_BACK ){
            exitDialog();
        }
        return false;//当有onclickListener时候，上面的写法showDailog会直接退出程序，不知到为什么
    }

    private void exitDialog(){  //退出程序的方法

        Dialog dialog = new AlertDialog.Builder(OpenGLESDemoActivity.this)
                .setTitle("程序退出？")  // 创建标题
                .setMessage("您确定要退出吗？")    //表示对话框的内容
//                .setIcon(R.drawable.ic_launcher) //设置LOGO
                .setPositiveButton("确定", new DialogInterface.OnClickListener() {

                    public void onClick(DialogInterface dialog, int which) {
                        stop();
                        finish(); //操作结束
                    }
                }).setNegativeButton("取消", new DialogInterface.OnClickListener() {

                    public void onClick(DialogInterface dialog, int which) {

                    }
                }).create();  //创建对话框
        dialog.show();  //显示对话框
    }


    private boolean checkPermission() {
        int result = ContextCompat.checkSelfPermission(getApplicationContext(), GET_ACCOUNTS);
        int result1 = ContextCompat.checkSelfPermission(getApplicationContext(), CAMERA);
        return result == PackageManager.PERMISSION_GRANTED && result1 == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermission() {
        ActivityCompat.requestPermissions(this, new String[]{GET_ACCOUNTS, CAMERA}, REQUEST_GET_ACCOUNT);
        ActivityCompat.requestPermissions(this, new String[]{WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE}, PERMISSION_REQUEST_CODE);
    }

    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        switch (requestCode) {
            case PERMISSION_REQUEST_CODE:
                if (grantResults.length > 0) {

                    boolean locationAccepted = grantResults[0] == PackageManager.PERMISSION_GRANTED;
                    boolean cameraAccepted = grantResults[1] == PackageManager.PERMISSION_GRANTED;

                    if (locationAccepted && cameraAccepted)
                        Toast.makeText(getApplicationContext(), "Permission Granted, Now you can access location data and camera", Toast.LENGTH_LONG).show();
                    else {
                        Toast.makeText(getApplicationContext(), "Permission Denied, You cannot access location data and camera", Toast.LENGTH_LONG).show();
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (shouldShowRequestPermissionRationale(WRITE_EXTERNAL_STORAGE)) {
                                showMessageOKCancel("You need to allow access to both the permissions",
                                        new DialogInterface.OnClickListener() {
                                            @Override
                                            public void onClick(DialogInterface dialog, int which) {
                                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                                    requestPermissions(new String[]{WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE},
                                                            PERMISSION_REQUEST_CODE);
                                                }
                                            }
                                        });
                                return;
                            }
                        }

                    }
                }

                break;

            case RECORD_REQUEST_CODE: {

                if (grantResults.length == 0
                        || grantResults[0] !=
                        PackageManager.PERMISSION_GRANTED) {

                    Loging.Log(TAG, "Permission has been denied by user");
                } else {
                    Loging.Log(TAG, "Permission has been granted by user");
                }
                return;
            }
        }
    }

    private void showMessageOKCancel(String message, DialogInterface.OnClickListener okListener) {
        new android.support.v7.app.AlertDialog.Builder(OpenGLESDemoActivity.this)
                .setMessage(message)
                .setPositiveButton("OK", okListener)
                .setNegativeButton("Cancel", null)
                .create()
                .show();
    }

//    @Override
//    public void onVideoSizeChanged(int width, int height) {
//        txv_preview.setAspectRatio(AspectTextureView.MODE_INSIDE, ((double) width) / height);
//    }

    @Override
    public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
        if(false == inited)
            init();

        if (openGLESPushStreamInterfaces != null) {
            openGLESPushStreamInterfaces.init(surface, pushUrl, width, height);
        }
    }

    @Override
    public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
        if (openGLESPushStreamInterfaces != null) {
            openGLESPushStreamInterfaces.updatePreview(width, height);
        }
    }

    @Override
    public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
        if (openGLESPushStreamInterfaces != null) {
            openGLESPushStreamInterfaces.stopPushStream();
        }
        return false;
    }

    @Override
    public void onSurfaceTextureUpdated(SurfaceTexture surface) {

    }
}