package com.wangyong.demo.pushsdk.BasicClasses;

import java.util.concurrent.locks.ReentrantLock;

/**
 * Created by wangyong on 2017/7/3.
 */

public class ThreadBase implements Runnable{

    private String TAG = "ThreadBase";

    private boolean running = false;
    private CallbackInterfaces.ThreadBaseInterface threadBaseInterface = null;
    private int threadID = -1;
    private int invocationInterval = 30; //Default 30ms

    private ReentrantLock reentrantLock = null;

    private Thread thread = null;

    public ThreadBase(String name) {
        TAG = name;
        reentrantLock = new ReentrantLock();
    }

    public void start() {
        thread = new Thread(this);
        thread.start();
    }

    public void setRunnable(CallbackInterfaces.ThreadBaseInterface threadBaseInterface, int id) {
        this.threadBaseInterface = threadBaseInterface;
        this.threadID = id;
    }

    public long getId() {
        if (null == thread)return -1;
        return thread.getId();
    }

    public void setInvocationInterval(int interval) {
        this.invocationInterval = interval;
    }

    public void stopThread() {
        if (true == running) {
            reentrantLock.lock();
            running = false;
            reentrantLock.unlock();
        }
        thread = null;
    }

    private boolean isInterrupted(){
        if(thread == null) return true;
        return thread.isInterrupted();
    }

    public void run() {
        this.running = true;

        long before = 0, needWaitDuration = 0, timeElapsed = 0, sleepTimes = 0;

        while (true == running && null != threadBaseInterface && true != isInterrupted()) {

            before = System.currentTimeMillis();

            reentrantLock.lock();

            int nRC = threadBaseInterface.RunLoop(threadID);

            reentrantLock.unlock();

            if (0 > nRC) {
                if (Constant.RTMP_SENDER_THREAD_ID == threadID)
                    Loging.Log(Loging.LOG_ERROR, TAG, "Thread ID : " + Loging.threadID2String(threadID) + " RunLoop return :" + Loging.RTMPError2String(nRC));
            }

            timeElapsed = System.currentTimeMillis() - before;

            if (Constant.VIDEO_ENCODER_INPUT_THREAD_ID == threadID)
                Loging.Log(TAG, "Video encoder input used : " + timeElapsed + "ms");
            else if (Constant.VIDEO_ENCODER_OUTPUT_THREAD_ID == threadID)
                Loging.Log(TAG, "Video encoder output used : " + timeElapsed + "ms");

            if (timeElapsed < 0)timeElapsed = 0; // Wrong !!!
            needWaitDuration = invocationInterval - timeElapsed;

            switch (nRC) {
                case Constant.THREAD_RUN_STATUS_IDLE:
                    needWaitDuration = needWaitDuration * 2;
                    break;
                case Constant.THREAD_RUN_STATUS_NORMAL:
                    break;
                case Constant.THREAD_RUN_STATUS_DELAY:
                    needWaitDuration = 0;
                    break;
            }

            try {
                if (0 < needWaitDuration) {
                    while (true == running && null != threadBaseInterface && 2 > sleepTimes ++) {
                        Thread.sleep(needWaitDuration / 2);
                    }
                    sleepTimes = 0;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        this.running = false;
        this.threadBaseInterface = null;
    }
}
