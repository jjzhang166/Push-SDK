//
//  H264HwEncoderImpl.m
//  h264v1
//
//  Created by Ganvir, Manish on 3/31/15.
//  Copyright (c) 2015 Ganvir, Manish. All rights reserved.
//

#import "H264HwEncoderImpl.h"
#import <UIKit/UIKit.h>
#import "IAUtility.h"
#import "IAHuitiRtmp.h"


#define YUV_FRAME_SIZE 2000
#define FRAME_WIDTH
#define NUMBEROFRAMES 300
#define DURATION 12

@import VideoToolbox;
@import AVFoundation;



@interface H264HwEncoderImpl ()
@property(nonatomic,assign)BOOL      showGameEvent;
@property(nonatomic,assign)long long smapleIndex;
@property(nonatomic,assign)BOOL      isFirstEncode;
@property(nonatomic,assign)BOOL      encoding;
@property(nonatomic,strong)IAInitialFinishedHandler  initialFinishedHandler;
@property(nonatomic,strong)IACompoundFinishedHandler compoundFinshedHandler;
@property(nonatomic,assign)int resolutionWidth;
@property(nonatomic,assign)int resolutionHeight;
@property(nonatomic,strong)IARtmpCompound*  rtmpCompound;
@property(nonatomic,assign)NSTimeInterval lastVideoFrameInterval;
@property(nonatomic,assign)BOOL  isFirstSendScore;

@property (nonatomic, strong) NSLock* interfaceLock;

@end

@implementation H264HwEncoderImpl
{
    NSString * yuvFile;
    VTCompressionSessionRef EncodingSession;
    dispatch_queue_t aQueue;
    CMFormatDescriptionRef  format;
    CMSampleTimingInfo * timingInfo;
    BOOL initialized;
    int  frameCount;
    NSData *sps;
    NSData *pps;
    
}
@synthesize error;



void CVPixelBuffer_FreeHapDecoderFrame(void *releaseRefCon, const void *baseAddress)	{
    // [(id)releaseRefCon release];
}

-(id)initWithFirstFrameEncodedHandler:(IAInitialFinishedHandler)handler compoundFinishedHandler:(IACompoundFinishedHandler)compoundFinishedHandler{
    
    if (self=[super init]) {
        self.shouldDiscardframe = NO;
        self.isFirstSendScore = YES;
        self.lastVideoFrameInterval = 0;
        self.initialFinishedHandler = handler;
        self.compoundFinshedHandler = compoundFinishedHandler;
        
    
    }
    return self;
}

- (void) deleteYUV
{
    NSString *documentPathStr =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *yuvPath = [documentPathStr stringByAppendingPathComponent:@"yuv.data"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (YES == [fileManager fileExistsAtPath:yuvPath]) {
        [fileManager removeItemAtPath:yuvPath error:nil];
    }
}

- (void) initWithConfiguration
{
    /*yuvFile = [documentsDirectory stringByAppendingPathComponent:@"test.i420"];
     
     if ([fileManager fileExistsAtPath:yuvFile] == NO) {
     NSLog(@"H264: File does not exist");
     return;
     }*/
    self.encoding = NO;
    self.showGameEvent = NO;
    EncodingSession = nil;
    initialized = true;
    aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    frameCount = 0;
    sps = NULL;
    pps = NULL;
    self.isFirstEncode = YES;
    self.interfaceLock = [[NSLock alloc] init];
    
}

-(int) SetScoreboardParameter:(int)paramID param1:(const char*)param1 param2:(const char*)param2
                       pSize1:(int)pSize1 pSize2:(int)pSize2
{
//    if (self.rtmpCompound) {
//        return   [self.rtmpCompound SetScoreboardParameter:paramID param1:param1 param2:param2 pSize1:pSize1 pSize2:pSize2];
//    }
    return -1;
}

-(int) SetEventString:(const char *)eventString{
//    if (self.rtmpCompound) {
//        return [self.rtmpCompound SetEventString:eventString];
//    }
    
    return -1;
}

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                     CMSampleBufferRef sampleBuffer )
{
    //    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    if (status != 0) return;
    
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        //        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    H264HwEncoderImpl* encoder = (__bridge H264HwEncoderImpl*)outputCallbackRefCon;
    
    // Check if we have got a key frame first
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        // CFDictionaryRef extensionDict = CMFormatDescriptionGetExtensions(format);
        // Get the extensions
        // From the extensions get the dictionary with key "SampleDescriptionExtensionAtoms"
        // From the dict, get the value for the key "avcC"
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
        if (statusCode == noErr)
        {
            // Found sps and now check for pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                // Found pps
                encoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                encoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder->_delegate)
                {
                    [encoder->_delegate gotSpsPps:encoder->sps pps:encoder->pps object:encoder];
                }
            }
        }
    }
    long long timeStamp = [((__bridge_transfer NSNumber *)sourceFrameRefCon) longLongValue];

    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // Convert the length value from Big-endian to Little-endian
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder->_delegate gotEncodedData:data isKeyFrame:keyframe timeDuration:timeStamp object:encoder];
            //Move to the next NAL unit in the block buffer
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

-(void)setwatermarkInfo{

    NSInteger  defaultW = 154 * 8 / 10;
    NSInteger  defaultH = 50 * 8 / 10;
    CGFloat    topY = 33.f * 10 / 9;
    CGFloat    offsetRight = 55.f * 10 / 9;
    CGFloat    baseResolutionW = 540.f;
    CGFloat    baseResolutionH = 960.f;
    
    
    CGFloat widthScale = self.resolutionWidth / baseResolutionW;
    CGFloat heightScale = self.resolutionHeight / baseResolutionH;

    int left = (baseResolutionW-offsetRight-defaultW) * widthScale, top = topY * heightScale;
    int right = left+defaultW*widthScale, bottom = (topY+defaultH) * heightScale;
    
    NSBundle* bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"liveLogo" withExtension:@"bundle"]];
    NSString* logoPath = [bundle pathForResource:@"livelogo" ofType:@"png"];
    
    NSData* broadcastModelData = [[NSUserDefaults standardUserDefaults] objectForKey:PA_Broadcast_Logo_Key];
    if (broadcastModelData) {
        logoPath = [[IAUtility cacheWaterMarkImagePath] path];
    }
    
    if (self.rtmpCompound) {
        [self.rtmpCompound SetLogoRect:left top:top right:right bottom:bottom];
        [self.rtmpCompound SetLogoFile:[logoPath UTF8String]];
    }
}

- (void)initEncode:(int)width  height:(int)height
{
    self.resolutionWidth = width;
    self.resolutionHeight = height;
    self.smapleIndex = 0;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(aQueue, ^{
        // For testing out the logic, lets read from a file and then send it to encoder to create h264 stream
        int fixedBitrate = 1024 * 1024;
        if(self.bitRate==IA_450K){
            fixedBitrate = 450*1024;
        }else if (self.bitRate==IA_512K) {
            fixedBitrate = 512*1024;
        }else if (self.bitRate==IA_550K) {
            fixedBitrate = 550*1024;
        }else if (self.bitRate==IA_700K){
            fixedBitrate = 700*1024;
        }else if (self.bitRate==IA_1M){
            fixedBitrate = 1024*1024;
        }else if (self.bitRate==IA_1Dot5M){
            fixedBitrate = 1280*1024;
        }else if (self.bitRate==IA_2M){
            fixedBitrate = 2048*1024;
        }
        
        
        
        //initCompound
        //[self deleteYUV];
        // colorType: GPUImage output PIX_FMT_RGB32 == 30; Original camera output AV_PIX_FMT_NV12 == 25;
        int colorType = 30;
        // Adjust width to align YUV stride, Cause by GPUImage but do NOT know why.
        int adjustedWidth = self.resolutionWidth;
        if(540 == self.resolutionWidth)
            adjustedWidth = self.resolutionWidth + 4;
        
        //weakSelf.rtmpCompound = [[IARtmpCompound alloc] init];
        if(weakSelf.rtmpCompound){
            int result = [weakSelf.rtmpCompound CompoundInit:0 input:colorType outType:colorType widht:adjustedWidth height:self.resolutionHeight];
            if (result>=0) {
                [weakSelf setwatermarkInfo];
            }else{
                //init error
            }
        }

        // Set the properties
        NSNumber *values[] = {[NSNumber numberWithInt:(fixedBitrate/8)], @1};
        CFArrayRef dataLimitArray = CFArrayCreate(kCFAllocatorDefault, (void *)values, (CFIndex)2, NULL);
        
        OSStatus status = VTCompressionSessionCreate(NULL,width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)self, &EncodingSession);
        if (status != noErr) {
            return;
        }
        
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)([NSNumber numberWithInt:50]));
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration,(__bridge CFTypeRef _Nonnull)([NSNumber numberWithInt:2]));
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)([NSNumber numberWithInt:25]));
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)([NSNumber numberWithInt:fixedBitrate]));

        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_DataRateLimits, dataLimitArray);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
        VTCompressionSessionPrepareToEncodeFrames(EncodingSession);
        CFRelease(dataLimitArray);
        if (weakSelf.initialFinishedHandler) {
            weakSelf.initialFinishedHandler();
        }
    });
}

-(BOOL)isEncoding{
    
    return self.encoding;
}

- (void)encodeWithImageBuffer:(CVImageBufferRef *)imageBuffer
{
    
    if (self.shouldDiscardframe) {
        return;
    }

    dispatch_sync(aQueue, ^{

        [self.interfaceLock lock];

        frameCount++;
        VTEncodeInfoFlags flags;
        OSStatus statusCode;
     
        //add watermark
        [self  addwatermark:*imageBuffer width:self.resolutionWidth height:self.resolutionHeight];

        //////////add custom timestamp
        NSTimeInterval startTimeInterval = [IAUtility startTimestampInterval];
        
        if (startTimeInterval==0) {
            startTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            [IAUtility setStartTimestampInterval:startTimeInterval];
        }
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        NSTimeInterval offsetInterval = currentTimeInterval-startTimeInterval;
        offsetInterval=offsetInterval*1000;
        long tempOffset = offsetInterval;
        int checkInt =  0x1;
        if ((tempOffset&checkInt)!=0) {
            tempOffset+=1;
        }
        if (self.lastVideoFrameInterval!=0) {
            //20ms 160ms
            if ((tempOffset - self.lastVideoFrameInterval)<20) {
                tempOffset = self.lastVideoFrameInterval+20;
            }
        }
        self.lastVideoFrameInterval = tempOffset;
        tempOffset = tempOffset*1000;
        CMTime presentationTimeStamp = CMTimeMake(frameCount, 25);
        CMTime duration = CMTimeMake(1, 25);
        NSNumber *timeNumber = @(tempOffset);
        //////////add custom timestamp end
        
        NSDictionary *properties = nil;
        if (self.smapleIndex%25==0)
            properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
        
        if (self.compoundFinshedHandler) {
            self.compoundFinshedHandler();
        }
        statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                         *imageBuffer,
                                                         presentationTimeStamp,
                                                         duration,
                                                         (__bridge CFDictionaryRef)properties,
                                                         (__bridge_retained void *)timeNumber,
                                                         &flags);
        self.smapleIndex++;
        // Check for error
        if (statusCode != noErr) {
            //                NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            error = @"H264: VTCompressionSessionEncodeFrame failed ";
            
            if (EncodingSession!=nil) {
                // End the session
                VTCompressionSessionInvalidate(EncodingSession);
                CFRelease(EncodingSession);
                EncodingSession = NULL;
            }
            error = NULL;
        }
        [self.interfaceLock unlock];
    });
}

- (void)encode:(CMSampleBufferRef )sampleBuffer //:(CVImageBufferRef *)imageBuffer opaqueCMSampleBuffer *CMSampleBufferRef;
{
    __weak typeof(self)weakSelf = self;
    dispatch_sync(aQueue, ^{
        ////force keyframe

        CFMutableDictionaryRef frameProps = NULL;
        frameProps = CFDictionaryCreateMutable(kCFAllocatorDefault, 1,&kCFTypeDictionaryKeyCallBacks,                                                            &kCFTypeDictionaryValueCallBacks);
        
        CFDictionaryAddValue(frameProps, kVTEncodeFrameOptionKey_ForceKeyFrame, kCFBooleanTrue);
        
        ////force keyframe end
        
        frameCount++;
        
        // Get the CV Image buffer
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        
        //add watermark
        [self  addwatermark:imageBuffer width:self.resolutionWidth height:self.resolutionHeight];
        

        
        // Create properties
        CMTime presentationTimeStamp = CMTimeMake(frameCount, 1000);
        //CMTime duration = CMTimeMake(1, DURATION);
        VTEncodeInfoFlags flags;
        // Pass it to the encoder
        OSStatus statusCode;
        
        
        
        //////////add custom timestamp
        
        NSTimeInterval startTimeInterval = [IAUtility startTimestampInterval];
        
        if (startTimeInterval==0) {
            startTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            [IAUtility setStartTimestampInterval:startTimeInterval];
        }
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        NSTimeInterval offsetInterval = currentTimeInterval-startTimeInterval;
        offsetInterval=offsetInterval*1000;
        long tempOffset = offsetInterval;
        int checkInt =  0x1;
        if ((tempOffset&checkInt)!=0) {
            tempOffset+=1;
        }
        
        if (self.lastVideoFrameInterval!=0) {
            
            //20ms 160ms
            if ((tempOffset - self.lastVideoFrameInterval)<20) {
                tempOffset = self.lastVideoFrameInterval+20;
            }
            
        }
        
        self.lastVideoFrameInterval = tempOffset;
        
        tempOffset = tempOffset*1000;
        
        presentationTimeStamp = CMTimeMake(tempOffset, 1000000);
        
        //////////add custom timestamp end
        
        //end
        
        
        if (self.compoundFinshedHandler) {
            self.compoundFinshedHandler();
        }
        
        
        if (self.smapleIndex%25==0) {
            statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                         imageBuffer,
                                                         presentationTimeStamp,
                                                         kCMTimeInvalid,
                                                         frameProps, NULL, &flags);
            
        }else{
            statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                         imageBuffer,
                                                         presentationTimeStamp,
                                                         kCMTimeInvalid,
                                                         NULL, NULL, &flags);
        }
        self.smapleIndex++;
        
        
        CFRelease(frameProps);
        // Check for error
        if (statusCode != noErr) {
            //                NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            error = @"H264: VTCompressionSessionEncodeFrame failed ";
            
            if (EncodingSession!=nil) {
                // End the session
                VTCompressionSessionInvalidate(EncodingSession);
                CFRelease(EncodingSession);
                EncodingSession = NULL;
            }
            
            error = NULL;
            return;
        }
        //            NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
    });
}


-(int)addwatermark:(CVImageBufferRef)imageBuffer width:(int)width height:(int)height{
    int result = -1;
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    CMSampleBufferRef outCMSampleBufferRef;
    CVImageBufferRef outputBuffer;
    void *inputAddress = NULL;
    
    CVReturn cvErr = kCVReturnSuccess;
    NSDictionary *pixelBufferAttribs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey,
                                        [NSNumber numberWithInteger:(NSUInteger)width], kCVPixelBufferWidthKey,
                                        [NSNumber numberWithInteger:(NSUInteger)height], kCVPixelBufferHeightKey,
                                        [NSNumber numberWithInteger:CVPixelBufferGetBytesPerRow(imageBuffer)],
                                        kCVPixelBufferBytesPerRowAlignmentKey,
                                        nil];
    CVPixelBufferRef cvPixRef = NULL;
    cvErr = CVPixelBufferCreateWithBytes(NULL,
                                         (size_t)width,
                                         (size_t)height,
                                         kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                         baseAddress,
                                         CVPixelBufferGetBytesPerRow(imageBuffer),
                                         CVPixelBuffer_FreeHapDecoderFrame,
                                         NULL,
                                         (__bridge CFDictionaryRef)pixelBufferAttribs,
                                         &cvPixRef);
    if (cvErr!=kCVReturnSuccess || cvPixRef==NULL) {
        NSLog(@"\t\terr %d at CVPixelBufferCreateWithBytes() in %s",cvErr,__func__);
        NSLog(@"\t\tattribs were %@",pixelBufferAttribs);
        NSLog(@"\t\tsize was %ld x %ld",(size_t)width,(size_t)height);
        NSLog(@"\t\trgbPixelFormat passed to method is %u",(unsigned int)kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    } else {
        CMFormatDescriptionRef desc = NULL;
        OSStatus osErr = CMVideoFormatDescriptionCreateForImageBuffer(NULL, cvPixRef, &desc);
        if (osErr!=noErr || desc==NULL)
            NSLog(@"\t\terr %d at CMVideoFormatDescriptionCreate() in %s",(int)osErr,__func__);
        else {
            CMSampleTimingInfo		timing;
            //        CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timing);
            timing.duration = kCMTimeInvalid;
            timing.decodeTimeStamp = kCMTimeInvalid;
            osErr = CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault,
                                                             cvPixRef,
                                                             desc,
                                                             &timing,
                                                             &outCMSampleBufferRef);
            if (osErr!=noErr || outCMSampleBufferRef==NULL)
                NSLog(@"\t\terr %d at CMSampleBufferCreateForImageBuffer() in %s",(int)osErr,__func__);
            else {
                outputBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(outCMSampleBufferRef);
                CVPixelBufferLockBaseAddress(outputBuffer, 0);
                inputAddress = CVPixelBufferGetBaseAddress(outputBuffer);
                
                result = [self.rtmpCompound Compound:0 hasEvent:0 videoBuf:(uint8_t*)inputAddress dstBuf:(uint8_t*)baseAddress];
                
                CVPixelBufferUnlockBaseAddress(outputBuffer,0);
            }
            
            if (outCMSampleBufferRef!=NULL) {
                CFRelease(outCMSampleBufferRef);
                outCMSampleBufferRef = NULL;
            }
            
            
            CFRelease(desc);
            desc = NULL;
        }
        CVPixelBufferRelease(cvPixRef);
        cvPixRef = NULL;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

    return result;
}

- (void)changeResolution:(int)width  height:(int)height
{
}

- (void)End
{
    [self.interfaceLock lock];
    if (self.rtmpCompound) {
        [self.rtmpCompound CompoundUninit];
    }
    if (EncodingSession!=nil) {
        // Mark the completion
        self.encoding = NO;
        VTCompressionSessionCompleteFrames(EncodingSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(EncodingSession);
        CFRelease(EncodingSession);
        EncodingSession = nil;
        error = NULL;
        self.smapleIndex = 0;
    }
    [self.interfaceLock unlock];
    self.interfaceLock = nil;
    NSLog(@"h264HwEncoderImpl end");
}

-(IAMediaDataModel*)audioEncodedDataModel{
    return nil;
}
-(void)removeEncodedData:(IAMediaDataModel*)encodedModel{
}

@end
