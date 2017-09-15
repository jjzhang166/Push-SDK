package com.wangyong.demo.pushsdk;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.os.Environment;

import com.wangyong.demo.pushsdk.Audio.AudioMCEncoder;
import com.wangyong.demo.pushsdk.Audio.AudioRecorder;
import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.Constant;
import com.wangyong.demo.pushsdk.BasicClasses.DataQueue;
import com.wangyong.demo.pushsdk.BasicClasses.DataStructure;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;
import com.wangyong.demo.pushsdk.BasicClasses.ThreadBase;
import com.wangyong.demo.pushsdk.MagicFilter.utils.MagicParams;
import com.wangyong.demo.pushsdk.RESVideoTools.RESVideoClient;
import com.wangyong.demo.pushsdk.RESVideoTools.Tools.RESCoreParameters;

/**
 * Created by wangyong on 2017/7/3.
 */

public class RESPushStreamManager implements CallbackInterfaces.CapturedDataCallback, CallbackInterfaces.ThreadBaseInterface{

    private static final String TAG = "PushStreamManager";

    private Context mContext = null;

    private RESVideoClient videoClient = null;
    private SurfaceTexture previewSurfaceTexture = null;

    private AudioRecorder audioRecorder = null;
    private AudioMCEncoder audioMCEncoder = null;
    private RTMPSender rtmpSender = null;

    private AndroidMediaMuxer androidMediaMuxer = null;
    private MediaFormat videoMeidaFormat = null;
    private MediaFormat audioMediaFormat = null;
    private boolean androidMediaMuxerNeedKeyFrame = true;
    private boolean androidMediaMuxerStarted = false;

    private DataQueue yuvDataQueue = null, avcDataQueue = null, pcmDataQueue = null, aacDataQueue = null;
    private ThreadBase audioEncoderThread = null, rtmpSenderThread = null;

    private String pushUrl = null;

    private int rotation = 0, outputVideoWidth = 0, outputVideoHeight = 0, fps = 0, videoBitRate = 0;
    private int sampleRate = 0, sampleBit = 0, channels = 0, audioBitrate = 0;

    private long lastAudioSendTime = 0, lastVideoSendTime = 0;
    private boolean droppingEncodedQueue = false;
    private boolean waitVideoKeyFrame = false;

    /**************** For collect info *******************/
    private ThreadBase infoCollectThread = null;
    CallbackInterfaces.PushSDKCallback pushSDKCallback = null;
    private long infoCollectStartTimestamp = 0; // System.currentTimeMillis();
    private int infoRTMPSendDataSize = 0;
    private int infoAudioCaptureFrames = 0;
    private int infoAudioEncodedFrames = 0;
    private int infoAudioSentFrames = 0;
    private int infoVideoCaptureFrames = 0;
    private int infoVideoEncodedFrames = 0;
    private int infoVideoSentFrames = 0;
    private int infoRTMPSendReturn = 0;

    /**************** Public interfaces *******************/

    public RESPushStreamManager(Context context, int rotation, int width, int height, int fps, int bitrate, int sampleRate, int sampleBit, int channels, int audioBitrate) {

        MagicParams.context = context;
        this.mContext = context;
        this.rotation = rotation;
        this.outputVideoWidth = width;
        this.outputVideoHeight = height;
        this.fps = fps;
        this.videoBitRate = bitrate;
        this.sampleRate = sampleRate;
        this.sampleBit = sampleBit;
        this.channels = channels;
        this.audioBitrate = audioBitrate;

        yuvDataQueue = new DataQueue("YUVDataQueue");
        avcDataQueue = new DataQueue("AVCDataQueue");
        pcmDataQueue = new DataQueue("PCMDataQueue");
        aacDataQueue = new DataQueue("AACDataQueue");

        audioMCEncoder = new AudioMCEncoder();
        audioRecorder = new AudioRecorder();
        audioEncoderThread = new ThreadBase("AudioEncoderThread");
        rtmpSender = new RTMPSender();
        rtmpSenderThread = new ThreadBase("RTMPSenderThread");

        RESCoreParameters parameters = new RESCoreParameters();
        parameters.filterMode = RESCoreParameters.FILTER_MODE_HARD;
        parameters.mediacdoecAVCBitRate = videoBitRate;
        parameters.videoWidth = width;
        parameters.videoHeight = height;
        parameters.videoFPS = fps;
        parameters.videoGOP = 2;
        parameters.mediacodecAACBitRate = audioBitrate;
        parameters.audioRecoderSampleRate = sampleRate;
        parameters.mediacodecAACChannelCount = channels;
        parameters.audioBufferQueueNum = 40;

//        parameters.backCameraDirectionMode = 32;
        parameters.frontCameraDirectionMode = 33;
        parameters.renderingMode = 2;
        parameters.isPortrait = true;
        videoClient = new RESVideoClient(parameters);
        videoClient.prepare();

//        String filePath = Environment.getExternalStorageDirectory().getPath() + "/androidMux.mp4";
//        androidMediaMuxer = new AndroidMediaMuxer(filePath);
    }

    public int init(String uri) {

        if (null == audioRecorder || null == audioMCEncoder || null == audioEncoderThread
                || null == rtmpSenderThread
                || null == videoClient) {
            Loging.Log(Loging.LOG_ERROR, TAG, "Init error : " + audioRecorder + " " + audioMCEncoder + " " + audioEncoderThread + " " + rtmpSenderThread + " " + videoClient);
            return -1;
        }

        this.pushUrl = uri;

        audioRecorder.setCapturedDataCallback(this);
        audioRecorder.init();

        if(0 != audioMCEncoder.init(audioRecorder.getSampleRate(), sampleBit, channels, audioBitrate)) {
            Loging.Log(Loging.LOG_ERROR, TAG, "AudioEncoder init FAILED !");
            return -1;
        }

        return 0;
    }

    public void destroy() {
        if (null != videoClient) {
            videoClient.destroy();
        }

        if (null != androidMediaMuxer)
            androidMediaMuxer.destroy();

        if (null != audioRecorder)
            audioRecorder.destroy();

        if (null != audioMCEncoder)
            audioMCEncoder.destroy();

        if (null != rtmpSender)
            rtmpSender.RTMPDisconnect();

        setDefaultParameters();
    }

    public void startPreview(SurfaceTexture surfaceTexture, int screenWidth, int screenHeight) {
        this.previewSurfaceTexture = surfaceTexture;
        if (null != videoClient)
            videoClient.startPreview(surfaceTexture, screenWidth, screenHeight);
    }

    public void stopPreview(boolean destorySurfaceView) {
        if (null != videoClient)
            videoClient.stopPreview(destorySurfaceView);
    }

    public void updatePreview(int width, int height) {
        if (null != videoClient)
            videoClient.updatePreview(width, height);
    }

    public int pushStreamStart() {

        if (null == audioRecorder || null == audioMCEncoder || null == audioEncoderThread
                || null == previewSurfaceTexture || null == videoClient
                || null == rtmpSender || null == rtmpSenderThread)
            return -1;

        /***** The start sequence below is NOT random, They have dependencies with each other, Please keep in mind *****/


        audioEncoderThread.setRunnable(this, Constant.AUDIO_ENCODER_THREAD_ID);
        audioEncoderThread.setInvocationInterval(15);

        rtmpSenderThread.setRunnable(this, Constant.RTMP_SENDER_THREAD_ID);
        rtmpSenderThread.setInvocationInterval(10);

        if (0 != rtmpSender.RTMPConnect(pushUrl, 0)) {
            Loging.Log(Loging.LOG_ERROR, TAG, "RTMP connect FAILED !");
            return -1;
        }
        rtmpSender.setAudioInfo(channels, audioRecorder.getSampleRate(), sampleBit);
        rtmpSender.setVideoInfo(outputVideoWidth, outputVideoHeight, fps);

        rtmpSenderThread.start();

        audioMCEncoder.start();

        audioEncoderThread.start();

        if (false == audioRecorder.start()) {
            Loging.Log(Loging.LOG_ERROR, TAG, "AudioRecorder start FAILED !");
            return -1;
        }

        videoClient.startStreaming(this);

        return 0;
    }

    public void pushStreamStop() {

        /***** The start sequence below is NOT random, They have dependencies with each other, Please keep in mind *****/

        if (null != videoClient) {
            videoClient.stopStreaming();
        }

        if (null != androidMediaMuxer)
            androidMediaMuxer.stop();

        if (null != audioEncoderThread) {
            audioEncoderThread.stopThread();
        }

        if (null != rtmpSenderThread) {
            rtmpSenderThread.stopThread();
        }

        if (null != audioRecorder)
            audioRecorder.stop();

        if (null != audioMCEncoder)
            audioMCEncoder.stop();

        if (null != rtmpSender)
            rtmpSender.RTMPDisconnect();

        if (null != pcmDataQueue)
            pcmDataQueue.cleanQueue();

        if (null != aacDataQueue)
            aacDataQueue.cleanQueue();

        if (null != yuvDataQueue)
            yuvDataQueue.cleanQueue();

        if (null != avcDataQueue)
            avcDataQueue.cleanQueue();

        if (null != infoCollectThread)
            infoCollectThread.stopThread();

        lastAudioSendTime = lastVideoSendTime = 0;
    }

    /**************** End Public interfaces *******************/


    /**************** Surface Callbacks *******************/

    public void setFilterType(int filter) {

    }

    public void addVideoIcon(Bitmap bitmap, Rect rect) {
        if (null != videoClient)
            videoClient.addVideoIcon(bitmap, rect);
    }

    public void removeIcon(int index) {
        if (null != videoClient)
            videoClient.removeIcon(index);
    }

    public void denoise(boolean denoise) {
        if (null != audioRecorder)
            audioRecorder.denoise(denoise);
    }

    public void setBeautyLevel(int smooth, int white, int pink) {
        if (null != videoClient)
            videoClient.setBeautyLevel(smooth, white, pink);
    }

    public int startWonderfulfileMuxer(String name) {

        return 0;
    }

    public int stopWonderfulfileMuxer() {
        return 0;
    }

    public void onVideoCapturedFrameArrived() {
        if (null != pushSDKCallback && 0 < infoCollectStartTimestamp)
            infoVideoCaptureFrames ++;
    }

    public void setPushSDKCallback(CallbackInterfaces.PushSDKCallback callback, int interval) {
        if (0 < interval) {
            this.pushSDKCallback = callback;

            if (null != this.pushSDKCallback)
                infoCollectThread = new ThreadBase("InfoCollectThread");
            infoCollectThread.setRunnable(this, Constant.INFO_COLLECT_THREAD_ID);
            infoCollectThread.setInvocationInterval(interval * 1000); // we collect info in every interval seconds.
            infoCollectThread.start();
        }
    }
    /**************** Captured data Callbacks *******************/

    public void onCapturedDataUpdate(int type, long index, Object Odata, long timestamp, MediaCodec.BufferInfo info){

        byte[] data = null;
        MediaFormat format = null;
        if (Odata instanceof byte[])
            data = (byte[])Odata;
        else if (Odata instanceof MediaFormat)
            format = (MediaFormat)Odata;

        DataStructure.Data inputData = null;

        if (true == droppingEncodedQueue) { // Dropping all audio & video raw data
            if (null != pcmDataQueue)
                pcmDataQueue.cleanQueue();
            if (null != yuvDataQueue)
                yuvDataQueue.cleanQueue();
        } else if (Constant.YUV == type) { // Video Camera captured yuv data callback.
            if (null == yuvDataQueue)
                yuvDataQueue = new DataQueue("YUVDataQueue");

            inputData = new DataStructure.Data(Constant.YUV, index, data, timestamp, info.flags);
            yuvDataQueue.addTailer(inputData);

            while (yuvDataQueue.len() > 3) {// We do NOT keep too many yuv data.
                yuvDataQueue.removeHeader();
            }

        } else if (Constant.PCM == type) { // Microphone captured pcm data callback.

            if (null == pcmDataQueue)
                pcmDataQueue = new DataQueue("PCMDataQueue");
            inputData = new DataStructure.Data(Constant.PCM, index, data, timestamp, info.flags);
            pcmDataQueue.addTailer(inputData);

            if (null != pushSDKCallback)
                infoAudioCaptureFrames ++;

            while (pcmDataQueue.len() > 10) { // We keep 10 pcm data at most.
                pcmDataQueue.removeHeader();
            }
        } else if (Constant.AVC == type) {
            if (null != data){
                if (null == avcDataQueue)
                    avcDataQueue = new DataQueue("AVCDataQueue");

                boolean bKeyFrame = (0 != (MediaCodec.BUFFER_FLAG_KEY_FRAME & info.flags)) ? true : false;
                if (null != androidMediaMuxer && (false == androidMediaMuxerNeedKeyFrame || (true == androidMediaMuxerNeedKeyFrame && true == bKeyFrame))) {
                    androidMediaMuxerNeedKeyFrame = false;
                    androidMediaMuxer.writeData(false, data, info);
                }

                inputData = new DataStructure.Data(Constant.AVC, index, data, timestamp, info.flags);
                avcDataQueue.addTailer(inputData);
                if (null != pushSDKCallback)
                    infoVideoEncodedFrames++;
            }
        } else if (Constant.AAC == type) {

            if (null == aacDataQueue)
                aacDataQueue = new DataQueue("AACDataQueue");

            inputData = new DataStructure.Data(Constant.AAC, index, data, timestamp, info.flags);
            aacDataQueue.addTailer(inputData);

        } else if (Constant.AVC_FORMAT  == type) {
            if (null != format && null == videoMeidaFormat) {
                videoMeidaFormat = format;
                if (null != androidMediaMuxer) {
                    if (null != videoMeidaFormat)
                        androidMediaMuxer.addTrack(false, videoMeidaFormat);

                    if (false == androidMediaMuxerStarted && null != audioMediaFormat && null != videoMeidaFormat) {
                        androidMediaMuxerStarted = true;
                        androidMediaMuxer.start();
                    }
                }
            }
        } else {
            Loging.Log(Loging.LOG_ERROR, TAG, "Wrong captured data type : " + type);
        }
    }

    public int RunLoop(int id) {
        int nRC = 0;
        switch (id) {
            case Constant.AUDIO_ENCODER_THREAD_ID:
                nRC = audioEncoderLoop();
                break;
            case Constant.VIDEO_ENCODER_OUTPUT_THREAD_ID:
                break;
            case Constant.RTMP_SENDER_THREAD_ID:
                nRC = RTMPSenderLoop();
                infoRTMPSendReturn = nRC;
                break;
            case Constant.INFO_COLLECT_THREAD_ID:
                nRC = collectAndCallbackInfo();
                break;
        }

        return nRC;
    }

    /**************** End Callbacks *******************/


    /************** Private ***************/

    private int audioEncoderLoop() {

        int nRC = Constant.THREAD_RUN_STATUS_NORMAL;
        DataStructure.Data pcmData = null;

        if (null == audioMCEncoder || null == pcmDataQueue || null == aacDataQueue)
            return -1;

        int pcmQueueLen = pcmDataQueue.len();

        try{
            if (pcmQueueLen <= 0) {
                // Empty queue.
                nRC = Constant.THREAD_RUN_STATUS_IDLE;
            } else {
                pcmData = pcmDataQueue.removeHeader();
                nRC = Constant.THREAD_RUN_STATUS_NORMAL;
            }
            if (null != pcmData) {
                audioMCEncoder.queueInputBuffer(pcmData.buf, pcmData.timestamp);
            }

            DataStructure.EncodedData encodedData = null;

            Object outputBuffer = audioMCEncoder.dequeueOutputBuffer(0);

            if (outputBuffer instanceof DataStructure.EncodedData) {
                encodedData = (DataStructure.EncodedData) outputBuffer;
            } else if (outputBuffer instanceof MediaFormat) {
                if (null == audioMediaFormat) {
                    audioMediaFormat = (MediaFormat) outputBuffer;
                    if (null != androidMediaMuxer) {
                        if (null != audioMediaFormat)
                            androidMediaMuxer.addTrack(true, audioMediaFormat);

                        if (false == androidMediaMuxerStarted && null != audioMediaFormat && null != videoMeidaFormat) {
                            androidMediaMuxerStarted = true;
                            androidMediaMuxer.start();
                        }
                    }
                }
            }

            if (null != encodedData) {
                if (null != androidMediaMuxer && false == androidMediaMuxerNeedKeyFrame) {
                    androidMediaMuxer.writeData(true, encodedData.data, encodedData.bufferInfo);
                }

                DataStructure.Data data = new DataStructure.Data(Constant.AAC, 0, encodedData.data, encodedData.bufferInfo.presentationTimeUs, encodedData.bufferInfo.flags);
                if (null == aacDataQueue)
                    aacDataQueue = new DataQueue("AACDataQueue");
                aacDataQueue.addTailer(data);

                if (null != pushSDKCallback)
                    infoAudioEncodedFrames ++;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return nRC;
    }

    private int RTMPSenderLoop() {
        int nRC = Constant.THREAD_RUN_STATUS_NORMAL;

        if (null != pushSDKCallback && 0 == infoCollectStartTimestamp)
            infoCollectStartTimestamp = System.currentTimeMillis();

        boolean needSendAudio = lastAudioSendTime <= lastVideoSendTime ? true : false;

        DataStructure.Data sendData = null;

        if (null == aacDataQueue || null == avcDataQueue)
            return -1;

//        if (avcDataQueue.queueDuration() > 5000000 || aacDataQueue.queueDuration() > 5000000) { // AV queue contain too many data, clean them all.
//          cleanEncodedDataQueue();
//          nRC = Constant.THREAD_RUN_STATUS_IDLE;
//        } else if (abs(lastAudioSendTime - lastVideoSendTime) >= 5000000) { // AV async more then 5s, clean them all.
//          cleanEncodedDataQueue();
//          nRC = Constant.THREAD_RUN_STATUS_IDLE;
//        }else if (false == needSendAudio) { // Audio delayed
        if (true == needSendAudio) { // Audio delayed
            sendData = aacDataQueue.removeHeader();
//            Loging.Log(Loging.LOG_ERROR, TAG, "Send AAC Audio queue len " + aacDataQueue.len());

        } else if (false == needSendAudio){ // Video delayed.
            sendData = avcDataQueue.removeHeader();
//            Loging.Log(Loging.LOG_ERROR, TAG, "Send AVC Video queue len " + avcDataQueue.len());
        }

        String stringType = true == needSendAudio ? "audio" : "video";
        int mediaType = true == needSendAudio ? 0 : 1;

        if (null != sendData && null != rtmpSender) {

            if (true == needSendAudio)
                lastAudioSendTime = sendData.timestamp;
            else
                lastVideoSendTime = sendData.timestamp;

            nRC = rtmpSender.RTMPSendData(mediaType, sendData.buf, sendData.timestamp);

            if (null != pushSDKCallback) {
                if (true == needSendAudio)
                    infoAudioSentFrames++;
                else
                    infoVideoSentFrames++;
                infoRTMPSendDataSize += sendData.buf.length;
            }

            if (0 > nRC)
                Loging.Log(Loging.LOG_ERROR, TAG, "Send lastAudio " + lastAudioSendTime + " lastVideo " + lastVideoSendTime + " " + stringType + " size : " + sendData.buf.length + " pts : " + sendData.timestamp + " Return : " + Loging.RTMPError2String(nRC));

        } else if (null == sendData)
            nRC = Constant.THREAD_RUN_STATUS_IDLE;

//        nRC = Constant.THREAD_RUN_STATUS_IDLE; // For debug drop frame logic

        return nRC;
    }

    private void cleanEncodedDataQueue() {

        Loging.Log(TAG, "AAC Queue Duration : " + aacDataQueue.queueDuration() + " AVC Queue Duration : " + avcDataQueue.queueDuration() + " Last send timestamp audio : " + lastAudioSendTime + " video : " + lastVideoSendTime);

        droppingEncodedQueue = true;
        waitVideoKeyFrame = true;

        if (null != aacDataQueue)
            aacDataQueue.cleanQueue();
        if (null != avcDataQueue)
            avcDataQueue.cleanQueue();

        lastAudioSendTime = lastVideoSendTime = 0;
        droppingEncodedQueue = false;
    }

    private void setDefaultParameters() {
        audioRecorder = null;
        audioMCEncoder = null;
        rtmpSender = null;

        yuvDataQueue = avcDataQueue = pcmDataQueue = aacDataQueue = null;
        audioEncoderThread = rtmpSenderThread = infoCollectThread = null;

        pushUrl = null;

        outputVideoWidth = outputVideoHeight = fps = videoBitRate = 0;
        sampleRate = sampleBit = channels = audioBitrate = 0;

        lastAudioSendTime = lastVideoSendTime = 0;
        droppingEncodedQueue = waitVideoKeyFrame = false;
    }

    private int collectAndCallbackInfo() {

        long past = System.currentTimeMillis() - infoCollectStartTimestamp;

        if (null != pushSDKCallback) {
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_SPEED, 1000 * infoRTMPSendDataSize / past, 0, 0);
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_AUDIO_FPS, 1000 * infoAudioSentFrames / past, 0, 0);
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_VIDEO_FPS, 1000 * infoVideoSentFrames / past, 0, 0);
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_AUDIO_CAPTURE_FPS, 1000 * infoAudioCaptureFrames / past, 0, 0);
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_AUDIO_ENCODED_FPS, 1000 * infoAudioEncodedFrames / past, 0, 0);
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_VIDEO_CAPTURE_FPS, 1000 * infoVideoCaptureFrames / past, 0, 0);
            pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_PUSH_VIDEO_ENCODED_FPS, 1000 * infoVideoEncodedFrames / past, 0, 0);

            if (0 > infoRTMPSendReturn) {
                pushSDKCallback.onPushSDKCallback(Constant.INFO_UPDATE_RTMP_PUSH_RETURN, infoRTMPSendReturn, 0, 0);
                infoRTMPSendReturn = 0;
            }

            infoRTMPSendDataSize = 0;
            infoAudioSentFrames = infoAudioCaptureFrames  = infoAudioEncodedFrames = 0;
            infoVideoSentFrames = infoVideoCaptureFrames = infoVideoEncodedFrames = 0;
            infoCollectStartTimestamp += past;
        }

        return Constant.THREAD_RUN_STATUS_NORMAL;
    }
}
