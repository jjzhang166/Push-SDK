package com.wangyong.demo.pushsdk.Audio;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaCodec;
import android.media.MediaRecorder;

import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.Constant;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;
import com.wangyong.demo.pushsdk.BasicClasses.ThreadBase;

/**
 * Created by wangyong on 2017/7/5.
 */

public class AudioRecorder implements CallbackInterfaces.ThreadBaseInterface{

    private static final String TAG = "AudioRecorder";

    // audio mic settings.
    private int sampleRate = 0, channels = 0, sampleBit = 0, bitRate = 0;
    private int bitDeeps = 0;

    private AudioRecord audioRecord = null;
    private byte[] audioBuffer = null;
    private byte[] speexAudioBuffer = null;
    private long startRecordedTimestamp = 0, preRecordedTimestamp = 0;

    private SpeexProcessor speexProcessor = null;
    private WebRTCAudioProcessing webRTCAudioProcessing = null;
    private CallbackInterfaces.CapturedDataCallback capturedDataCallback = null;
    private ThreadBase audioRecordReadThread = null;

    private boolean running = false;
    private boolean enableDenoise = false;

    /********************* Public interfaces **********************/

    public void init(){

        speexProcessor = new SpeexProcessor();
//        webRTCAudioProcessing = new WebRTCAudioProcessing();

//        int[] sampleRates = {44100, 22050, 11025, 16000};
        int[] sampleRates = {32000, 16000, 44100, 8000, 48000, 22050, 11025};

        for (int sampleRate : sampleRates) {
            int audioFormat = AudioFormat.ENCODING_PCM_16BIT;
            int channelConfig = AudioFormat.CHANNEL_CONFIGURATION_MONO;

            int bSamples = 8;
            if (audioFormat == AudioFormat.ENCODING_PCM_16BIT) {
                bSamples = 16;
            }

            int nChannels = 2;
            if (channelConfig == AudioFormat.CHANNEL_CONFIGURATION_MONO) {
                nChannels = 1;
            }

            //int bufferSize = 2 * bSamples * nChannels / 8;
            int bufferSize = 2 * AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat);
//            AudioRecord audioRecorder = new AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize);
            AudioRecord audioRecorder = new AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSize);
//            AudioRecord audioRecorder = new AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, sampleRate, channelConfig, audioFormat, bufferSize);

            if (audioRecorder.getState() != AudioRecord.STATE_INITIALIZED) {
                Loging.Log(Loging.LOG_ERROR, TAG, "Create AudioRecord sampleRate : " + sampleRate + " state : " + audioRecorder.getState());
                continue;
            }

            this.sampleRate = sampleRate;
            this.bitDeeps = audioFormat;
            this.sampleBit = bSamples;
            this.channels = nChannels;
            this.bitRate = sampleRate * nChannels * bSamples;
            this.audioRecord = audioRecorder;
            audioBuffer = new byte[Math.min(2048, bufferSize)];

            if (null != speexProcessor) {
                speexProcessor.open(audioBuffer.length, sampleRate, 8000);
                speexProcessor.setDenoiseParameter(1, -20);
            }

            if (null != webRTCAudioProcessing) {
                webRTCAudioProcessing.open(5, 5, 10, 0, 0);
                webRTCAudioProcessing.setParameters(audioBuffer.length, sampleRate, sampleBit, channels);
            }
            //audioBuffer = new byte[bufferSize];
            Loging.Log(Loging.LOG_INFO, TAG, String.format("AudioRecorder open rate=%dHZ, channels=%d, bits=%d, buffer=%d/%d, state=%d", sampleRate, channels, sampleBit, bufferSize, audioBuffer.length, audioRecorder.getState()));
            break;
        }
    }

    public int getSampleRate() {
        return this.sampleRate;
    }

    public void setCapturedDataCallback(CallbackInterfaces.CapturedDataCallback callback){
        capturedDataCallback = callback;
    }

    public boolean start() {
        if(audioRecord == null) return false;

        audioRecordReadThread = new ThreadBase("AudioRecordReadThread");
        audioRecordReadThread.setInvocationInterval(10);
        audioRecordReadThread.setRunnable(this, Constant.AUDIO_RECORDER_THREAD_ID);

        this.preRecordedTimestamp = 0;
        this.startRecordedTimestamp = System.currentTimeMillis();

        Loging.Log(Loging.LOG_INFO, TAG, String.format("Start AudioRecorder in rate=%dHZ, channels=%d, format=%d", sampleRate, channels, bitDeeps));
        try {
            audioRecord.startRecording();
        }catch (IllegalStateException e) {
            Loging.Log(Loging.LOG_WARNING, TAG, "AudioRecorder.startRecording failed");
            return false;
        }

        if (null != audioRecordReadThread)
            audioRecordReadThread.start();

        running = true;

        return true;
    }

    public void stop() {

        if (false == running)
            return;

        if (null != audioRecordReadThread && true == running) {
            audioRecordReadThread.stopThread();
        }

        if (null != audioRecord && true == running) {
            audioRecord.stop();
        }

        running = false;
    }

    public void destroy() {
        if (null != capturedDataCallback) {
            capturedDataCallback = null;
        }

        stop();

        if (null != audioRecord) {
            audioRecord.setRecordPositionUpdateListener(null);
            audioRecord.release();
        }

        if (null != speexProcessor)
            speexProcessor.close();

        if (null != webRTCAudioProcessing)
            webRTCAudioProcessing.close();

        setDefaultParameters();
    }

    public void denoise(boolean denoise) {
        this.enableDenoise = denoise;
    }

    /********************* End Public interfaces **********************/


    /********************* Callback **********************/

    public int RunLoop(int id) {
        int nRC = Constant.THREAD_RUN_STATUS_NORMAL;

        if (null == audioRecord || Constant.AUDIO_RECORDER_THREAD_ID != id)
            return -1;

        MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();

        int index = 0;
        do {
            if (false == running)
                break;

            int size = audioRecord.read(audioBuffer, index, audioBuffer.length - index);
            if (size <= 0) {
                Loging.Log(Loging.LOG_INFO, TAG, "audio ignore, no data to read.");
                break;
            }

            if(size + index < audioBuffer.length){
                index += size;
            }else{
                break;
            }
        }while(true);

        long timestamp = System.currentTimeMillis() - startRecordedTimestamp;

        final long MASK_EVEN = ~0x01;
        final long MIN_STEP = 10;
        final long MAX_STEP = 60;
        timestamp = (timestamp & MASK_EVEN) + 1;

        if(timestamp - preRecordedTimestamp < MIN_STEP) {
            timestamp = preRecordedTimestamp + MIN_STEP;
        }

        preRecordedTimestamp = timestamp;

        if (null != capturedDataCallback) {
            if (true == enableDenoise && null != speexProcessor) {
                if (null == speexAudioBuffer)
                    speexAudioBuffer = audioBuffer.clone();
                speexProcessor.process(audioBuffer, audioBuffer.length, speexAudioBuffer);
                capturedDataCallback.onCapturedDataUpdate(Constant.PCM, 0, speexAudioBuffer, timestamp * 1000, info);
            } else {

                if (true == enableDenoise && null != webRTCAudioProcessing) {
                    webRTCAudioProcessing.process(audioBuffer);
                }

                capturedDataCallback.onCapturedDataUpdate(Constant.PCM, 0, audioBuffer, timestamp * 1000, info);
            }
        }

        return nRC;
    }

    /********************* End Callback **********************/



    /********************* Private *********************/

    private void setDefaultParameters() {
        sampleRate = channels = sampleBit = bitRate = bitDeeps = 0;

        audioRecord = null;
        audioBuffer = null;

        audioRecordReadThread = null;
        startRecordedTimestamp = preRecordedTimestamp = 0;

        running = false;

        speexAudioBuffer = null;
        speexProcessor = null;
        webRTCAudioProcessing = null;
    }
}
