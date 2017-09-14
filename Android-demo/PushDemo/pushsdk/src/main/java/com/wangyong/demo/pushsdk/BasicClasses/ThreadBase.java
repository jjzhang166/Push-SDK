package com.wangyong.demo.pushsdk.BasicClasses;

import java.util.concurrent.locks.ReentrantLock;

/**
 * Created by wangyong on 2017/7/3.
 */

public class ThreadBase extends Thread {

    private String TAG = "ThreadBase";

    private boolean stopped = false;
    private CallbackInterfaces.ThreadBaseInterface threadBaseInterface = null;
    private int threadID = -1;
    private int invocationInterval = 30; //Default 30ms

    private ReentrantLock reentrantLock = null;


    public ThreadBase(String name) {
        super(name);
        TAG = name;
        reentrantLock = new ReentrantLock();
    }

    public void setRunnable(CallbackInterfaces.ThreadBaseInterface threadBaseInterface, int id) {
        this.threadBaseInterface = threadBaseInterface;
        this.threadID = id;
    }

    public void setInvocationInterval(int interval) {
        this.invocationInterval = interval;
    }

    public void stopThread() {
        reentrantLock.lock();
        this.stopped = true;
        reentrantLock.unlock();
    }

    @Override
    public void run() {
        long before = 0, needWaitDuration = 0, timeElapsed = 0, sleepTimes = 0;

        while (true != stopped && null != threadBaseInterface) {

            before = System.currentTimeMillis();

            reentrantLock.lock();

            int nRC = threadBaseInterface.RunLoop(threadID);

            reentrantLock.unlock();

            if (0 > nRC) {
                if (Constant.RTMP_SENDER_THREAD_ID == threadID)
                    Loging.Log(Loging.LOG_ERROR, getName(), "Thread ID : " + Loging.threadID2String(threadID) + " RunLoop return :" + Loging.RTMPError2String(nRC));
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
                    while (true != stopped && null != threadBaseInterface && 2 > sleepTimes ++) {
                        Thread.sleep(needWaitDuration / 2);
                    }
                    sleepTimes = 0;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        this.threadBaseInterface = null;
    }
}
