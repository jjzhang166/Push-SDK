//
//  IAAudioCaptureEngine.m
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/16.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import "IAAudioCaptureEngine.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CoreFoundation/CoreFoundation.h>

#define  SUPPORT_AAC_ENCODER  @"SUPPORT_AAC_ENCODER"
#define  Max_audioRawArray    30
#define  Max_encodedDataArray 30

@interface IAAudioCaptureEngine ()<AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession* m_capture ;
    AudioConverterRef m_converter;
}

@property(nonatomic,strong)NSMutableArray* audioRawArray;
@property(nonatomic,strong)NSMutableArray* audioEncodedArray;
@property(nonatomic,assign)NSTimeInterval  startAudioTimeInterval;

@end

char * audioInData = NULL;
int remainSize = 0;

@implementation IAAudioCaptureEngine

-(void)open {
    NSError *error;
    self.startAudioTimeInterval = 0;
    m_capture = [[AVCaptureSession alloc]init];
    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (audioDev == nil)
    {
        NSLog(@"Couldn't create audio capture device");
        return ;
    }
    
    // create mic device
    AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDev error:&error];
    if (error != nil)
    {
        NSLog(@"Couldn't create audio input");
        return ;
    }
    
    
    // add mic device in capture object
    if ([m_capture canAddInput:audioIn] == NO)
    {
        NSLog(@"Couldn't add audio input");
        return ;
    }
    [m_capture addInput:audioIn];
    // export audio data
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if ([m_capture canAddOutput:audioOutput] == NO)
    {
        NSLog(@"Couldn't add audio output");
        return ;
    }
    [m_capture addOutput:audioOutput];
    [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    [m_capture startRunning];
    return ;
}

-(void)close {
    if (m_capture != nil && [m_capture isRunning])
    {
        [m_capture stopRunning];
    }
    
    if(NULL != audioInData)
        free(audioInData);
    
    return;
}
-(BOOL)isOpen {
    if (m_capture == nil)
    {
        return NO;
    }
    
    return [m_capture isRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
//    [self cacheRawAudioData:sampleBuffer];
    
    //temp
    
    char szBuf[4096];
    int  nSize = sizeof(szBuf);
    char*  beginData = " f";
    
    //        CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(cachedSample);
    //        long long timeStamp = (1000*1000*presentationTimeStamp.value) / presentationTimeStamp.timescale;
    
    if (self.startAudioTimeInterval==0) {
        self.startAudioTimeInterval =[NSDate timeIntervalSinceReferenceDate];
    }
    NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval offsetInterval = currentInterval-self.startAudioTimeInterval;
    offsetInterval = offsetInterval*1000*1000;
    
#ifdef SUPPORT_AAC_ENCODER
    if ([self encoderAAC:sampleBuffer aacData:szBuf aacLen:&nSize] == YES)
    {
        if (strcmp(szBuf, beginData)!=0) {
            //        const char bytes[] = "\x00\x00\x00\x00\x00\x00";
            //        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
            //        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
            //        NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
            //        [mutableData appendData:[NSData dataWithBytes:szBuf length:nSize]];
        
            
            if (self.delegate&&[self.delegate respondsToSelector:@selector(gotAudioEncodedData:len:timeDuration:)]) {
                [self.delegate gotAudioEncodedData:[NSData dataWithBytes:szBuf length:nSize] len:nSize timeDuration:offsetInterval];
            }
        }
        
    }
#else //#if SUPPORT_AAC_ENCODER
    AudioStreamBasicDescription outputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(cachedSample)));
    nSize = CMSampleBufferGetTotalSampleSize(cachedSample);
    CMBlockBufferRef databuf = CMSampleBufferGetDataBuffer(cachedSample);
    if (CMBlockBufferCopyDataBytes(databuf, 0, nSize, szBuf) == kCMBlockBufferNoErr)
    {
        NSLog(@"UNSUPPORT_AAC_ENCODER szBuf  :%s",szBuf);
    }
#endif

}


-(void)cacheRawAudioData:(CMSampleBufferRef)sampleBuffer{
    
    if ([self.audioRawArray count]>=Max_audioRawArray) {
        [self.audioRawArray removeAllObjects];
    }
    [self.audioRawArray addObject:(__bridge id _Nonnull)(sampleBuffer)];
    
    //if the _audioEncodedArray is full stop to encode
    if ([self.audioEncodedArray count]<Max_encodedDataArray) {
        //encode the raw data
        NSInteger  sampleIndex = [self.audioRawArray count]-1;
        CMSampleBufferRef cachedSample = (__bridge CMSampleBufferRef)([self.audioRawArray objectAtIndex:sampleIndex]);
        
        char szBuf[4096];
        int  nSize = sizeof(szBuf);
        char*  beginData = " f";
        
//        CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(cachedSample);
//        long long timeStamp = (1000*1000*presentationTimeStamp.value) / presentationTimeStamp.timescale;
        
        NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval offsetInterval = currentInterval-self.startAudioTimeInterval;
        offsetInterval = offsetInterval*1000*1000;
        
#ifdef SUPPORT_AAC_ENCODER
        if ([self encoderAAC:cachedSample aacData:szBuf aacLen:&nSize] == YES)
        {
            if (strcmp(szBuf, beginData)!=0) {
                //        const char bytes[] = "\x00\x00\x00\x00\x00\x00";
                //        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
                //        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
                //        NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
                //        [mutableData appendData:[NSData dataWithBytes:szBuf length:nSize]];
                
                IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
                encodedAudioModel.data = [NSData dataWithBytes:szBuf length:nSize];
                encodedAudioModel.size = nSize;
                encodedAudioModel.timestamp = offsetInterval;
                [self.audioEncodedArray addObject:encodedAudioModel];
                
                if (self.delegate&&[self.delegate respondsToSelector:@selector(gotAudioEncodedData:len:timeDuration:)]) {
                    [self.delegate gotAudioEncodedData:[NSData dataWithBytes:szBuf length:nSize] len:nSize timeDuration:offsetInterval];
                }
            }
            
        }
#else //#if SUPPORT_AAC_ENCODER
        AudioStreamBasicDescription outputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(cachedSample)));
        nSize = CMSampleBufferGetTotalSampleSize(cachedSample);
        CMBlockBufferRef databuf = CMSampleBufferGetDataBuffer(cachedSample);
        if (CMBlockBufferCopyDataBytes(databuf, 0, nSize, szBuf) == kCMBlockBufferNoErr)
        {
            NSLog(@"UNSUPPORT_AAC_ENCODER szBuf  :%s",szBuf);
        }
#endif
        
        if ([self.audioRawArray containsObject:(__bridge id _Nonnull)(cachedSample)]) {
            [self.audioRawArray removeObject:(__bridge id _Nonnull)(cachedSample)];
        }
    }
    
    
}

#ifdef SUPPORT_AAC_ENCODER
-(BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer { //根据输入样本初始化一个编码转换器
    if (m_converter != nil)
    {
        return TRUE;
    }
    
    AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer))); // 输入音频格式
    AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = inputFormat.mSampleRate; // 采样率保持一致
    outputFormat.mFormatID         = kAudioFormatMPEG4AAC;    // AAC编码
    outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
    outputFormat.mFramesPerPacket  = 1024;                    // AAC一帧是1024个字节
    
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC;
    outputFormat.mReserved = 0;
    
    AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    if (AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, desc, &m_converter) != noErr)
    {
        NSLog(@"AudioConverterNewSpecific failed");
        return NO;
    }
    
    return YES;
}
-(BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char*)aacData aacLen:(int*)aacLen { // 编码PCM成AAC
    if ([self createAudioConvert:sampleBuffer] != YES)
    {
        return NO;
    }
    
    CMBlockBufferRef blockBuffer = nil;
    AudioBufferList  inBufferList;
    if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr)
    {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
        return NO;
    }
    
//////////////////////
    
    uint8_t * data_pos = NULL;
    int remain = 0;
    uint8_t * ori_p = inBufferList.mBuffers[0].mData;
    int ori_s = inBufferList.mBuffers[0].mDataByteSize;
    
    if(NULL == audioInData){
        audioInData = malloc((2048 + 1)* sizeof(uint8_t));
    }

    if(inBufferList.mBuffers[0].mDataByteSize < 2048){

        if(0 == remainSize) {
            memcpy(audioInData, inBufferList.mBuffers[0].mData, inBufferList.mBuffers[0].mDataByteSize);
            remainSize = inBufferList.mBuffers[0].mDataByteSize;
            CFRelease(blockBuffer);
            return NO;
        } else {
            int data_size = remainSize + inBufferList.mBuffers[0].mDataByteSize;
            if(data_size > 2048) {
                memcpy(audioInData + remainSize, inBufferList.mBuffers[0].mData, 2048 - remainSize);
                data_pos = inBufferList.mBuffers[0].mData + 2048 - remainSize;
                remain = inBufferList.mBuffers[0].mDataByteSize - (2048 - remainSize);
            } else {
                memcpy(audioInData + remainSize, inBufferList.mBuffers[0].mData, inBufferList.mBuffers[0].mDataByteSize);
                if(data_size < 2048) {
                    remainSize += inBufferList.mBuffers[0].mDataByteSize;
                    CFRelease(blockBuffer);
                    return NO;
                }
                remainSize = 0;
            }
        }
        inBufferList.mBuffers[0].mData = audioInData;
        inBufferList.mBuffers[0].mDataByteSize = 2048;
    }

////////////////////
   
    
    // 初始化一个输出缓冲列表
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers              = 1;
    outBufferList.mBuffers[0].mNumberChannels = inBufferList.mBuffers[0].mNumberChannels;
    outBufferList.mBuffers[0].mDataByteSize   = *aacLen; // 设置缓冲区大小
    outBufferList.mBuffers[0].mData           = aacData; // 设置AAC缓冲区
    UInt32 outputDataPacketSize               = 1;
    if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr)
    {
        CFRelease(blockBuffer);
        NSLog(@"AudioConverterFillComplexBuffer failed");
        return NO;
    }
    
///////////////////////
    
    inBufferList.mBuffers[0].mDataByteSize = ori_s;
    inBufferList.mBuffers[0].mData = ori_p;
    memset(audioInData, 0, sizeof(uint8_t) * (2048 + 1));
    if(NULL != data_pos && remain > 0) {
        memcpy(audioInData, data_pos, remain);
        remainSize = remain;
    }
    
//////////////////////
    
    *aacLen = outBufferList.mBuffers[0].mDataByteSize; //设置编码后的AAC大小
    CFRelease(blockBuffer);
    return YES;
}
-(AudioClassDescription*)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer { // 获得相应的编码器
    static AudioClassDescription audioDesc;
    
    UInt32 encoderSpecifier = type, size = 0;
    OSStatus status;
    
    memset(&audioDesc, 0, sizeof(audioDesc));
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (status)
    {
        return nil;
    }
    
    uint32_t count = size / sizeof(AudioClassDescription);
    AudioClassDescription descs[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
    for (uint32_t i = 0; i < count; i++)
    {
        if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer))
        {
            memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
            break;
        }
    }
    return &audioDesc;
}
OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData,AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) { //<span style="font-family: Arial, Helvetica, sans-serif;">AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据</span>
    AudioBufferList bufferList = *(AudioBufferList*)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}
#endif

-(NSMutableArray*)audioRawArray{
    if (!_audioRawArray) {
        _audioRawArray = [[NSMutableArray alloc] init];
    }
    return _audioRawArray;
}

-(NSMutableArray*)audioEncodedArray{
    if (!_audioEncodedArray) {
        _audioEncodedArray = [[NSMutableArray alloc] init];
    }
    return _audioEncodedArray;
}

-(IAMediaDataModel*)audioEncodedDataModel{
    
    NSInteger arrayCount = [self.audioEncodedArray count];
    if (arrayCount>0) {
        IAMediaDataModel* encodedDataModel = [self.audioEncodedArray objectAtIndex:(arrayCount-1)];
        return encodedDataModel;
    }
    return nil;
}

-(void)removeEncodedData:(IAMediaDataModel*)encodedModel{
    if ([self.audioEncodedArray containsObject:encodedModel]) {
        [self.audioEncodedArray removeObject:encodedModel];
    }
}

@end
