package com.wangyong.demo.pushsdk.BasicClasses;

import android.util.Log;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.net.UnknownHostException;

/**
 * Created by wangyong on 2017/6/30.
 */

public class Loging {

    public static final int LOG_INFO = 0;
    public static final int LOG_DEBUG = 1;
    public static final int LOG_WARNING = 2;
    public static final int LOG_ERROR = 3;

    private static final int ERROR_BUFFER = -1;
    private static final int ERROR_MEMORY =  -2;
    private static final int ERROR_NETWORK=  -3;
    private static final int ERROR_HEADER  =  -4;
    private static final int ERROR_METADATA = -5;
    private static final int ERROR_DISCONNECT = -6;
    private static final int ERROR_TIME = -7;

    private static final boolean VERBOSE = true;

    public static void Log(String tag, String str) {
        if(true == VERBOSE)
            Log.d(tag, str);
    }

    public static void Log(int level, String tag, String str){
        if(true == VERBOSE) {
            switch (level) {
                case LOG_INFO:
                    Log.i(tag, str);
                    break;

                case LOG_DEBUG:
                    Log.d(tag, str);
                    break;

                case LOG_WARNING:
                    Log.w(tag, str);
                    break;

                case LOG_ERROR:
                    Log.e(tag, str);
                    break;

                default:
                    Log.d(tag, str);
                    break;
            }
        }
    }

    public static String RTMPError2String(int type) {
        String sRNT = null;
        switch (type) {
            case ERROR_BUFFER:
                sRNT = " ERROR_BUFFER ";
                break;
            case ERROR_DISCONNECT:
                sRNT = " ERROR_DISCONNECT ";
                break;
            case ERROR_HEADER:
                sRNT = " ERROR_HEADER ";
                break;
            case ERROR_MEMORY:
                sRNT = " ERROR_MEMORY ";
                break;
            case ERROR_METADATA:
                sRNT = " ERROR_METADATA ";
                break;
            case ERROR_NETWORK:
                sRNT = " ERROR_NETWORK ";
                break;
            case ERROR_TIME:
                sRNT = " ERROR_TIME ";
                break;
            default:
                sRNT = " OK ";
                break;
        }

        return sRNT;
    }

    public static String threadID2String(int type) {
        String snRC = null;

        switch (type) {
            case Constant.AUDIO_RECORDER_THREAD_ID:
                snRC = "Audio recorder thread ";
                break;
            case Constant.AUDIO_ENCODER_THREAD_ID:
                snRC = "Audio encoder thread ";
                break;
            case Constant.VIDEO_ENCODER_INPUT_THREAD_ID:
                snRC = "Video input thread ";
                break;
            case Constant.VIDEO_ENCODER_OUTPUT_THREAD_ID:
                snRC = "Video output thread ";
                break;
            case Constant.RTMP_SENDER_THREAD_ID:
                snRC = "RTMP send thread ";
                break;
            case Constant.INFO_COLLECT_THREAD_ID:
                snRC = "Info Collect thread ";
                break;
            default:
                break;
        }

        return snRC;
    }

    public static void trace(String TAG, String msg, Throwable e) {
        if (false == VERBOSE) {
            return;
        }
        if (null == e || e instanceof UnknownHostException) {
            return;
        }

        final Writer writer = new StringWriter();
        final PrintWriter pWriter = new PrintWriter(writer);
        e.printStackTrace(pWriter);
        String stackTrace = writer.toString();
        if (null == msg || msg.equals("")) {
            msg = "================error!==================";
        }
        Log.e(TAG, "==================================");
        Log.e(TAG, msg);
        Log.e(TAG, stackTrace);
        Log.e(TAG, "-----------------------------------");
    }
}
