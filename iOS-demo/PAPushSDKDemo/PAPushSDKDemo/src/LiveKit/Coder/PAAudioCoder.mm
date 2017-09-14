//
//  PAAudioCoder.m
//  anchor
//
//  Created by Derek Lix on 24/11/2016.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "PAAudioCoder.h"
#import <AudioToolbox/AudioToolbox.h>

#define AUDIO_SAMPLE_ROTE      44100

@interface PAAudioCoder ()
{
    char* outputBuffer;
    AudioStreamBasicDescription pcmASBD;
    AudioStreamBasicDescription aacASBD;
    AudioConverterRef converter;
    UInt32 outputSizePerPacket;
    int read_block_size;
    int last_size;
    
}

@property(nonatomic,strong)PACoderDataCallbackHandler callbackHandler;
@property(nonatomic,strong)PACoderBeginHandler     beginHandler;

@end

@implementation PAAudioCoder

char* data_test;     //aac encode data


-(id)initWithDataCallbackHandler:(PACoderDataCallbackHandler)coderCallbackHandler beginHandler:(PACoderBeginHandler)beginHandler{
    if(self = [super init]){
        self.callbackHandler = coderCallbackHandler;
        self.beginHandler = beginHandler;
        [self changePcmToAAC];
        data_test = (char*) malloc(sizeof(char)*4096);
        outputBuffer = (char*) malloc (sizeof(char)*1024);
        read_block_size = 0;
        last_size = 0;
    }
    return self;
}

-(void)changePcmToAAC{
    OSStatus error = noErr;
    
    converter = NULL;

    pcmASBD = {0};
    pcmASBD.mSampleRate = AUDIO_SAMPLE_ROTE;//((AVAudioSession *) [AVAudioSession sharedInstance]).currentHardwareSampleRate;
    pcmASBD.mFormatID = kAudioFormatLinearPCM;
    pcmASBD.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger |kLinearPCMFormatFlagIsPacked;
    pcmASBD.mChannelsPerFrame = 1;
    pcmASBD.mBytesPerFrame = sizeof(AudioSampleType);
    pcmASBD.mFramesPerPacket = 1;
    pcmASBD.mBytesPerPacket = pcmASBD.mBytesPerFrame * pcmASBD.mFramesPerPacket;
    pcmASBD.mBitsPerChannel = 8 * pcmASBD.mBytesPerFrame;

    aacASBD = {0};
    aacASBD.mFormatID = kAudioFormatMPEG4AAC;
    aacASBD.mSampleRate = pcmASBD.mSampleRate;//pcmASBD.mSampleRate;
    aacASBD.mChannelsPerFrame = pcmASBD.mChannelsPerFrame;
    
    UInt32 size = sizeof(aacASBD);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &aacASBD);
    
    AudioClassDescription description;
    description.mType = kAudioEncoderComponentType;
    description.mSubType = kAudioFormatMPEG4AAC;
    description.mManufacturer = kAppleSoftwareAudioCodecManufacturer;
    
    // see the question as for setting up pcmASBD and arc ASBD
    OSStatus st = AudioConverterNewSpecific(&pcmASBD, &aacASBD, 1, &description, &converter);
    
    //    OSStatus st = AudioConverterNew(&pcmASBD, &aacASBD, &converter);
    
    if (st) {
        //NSLog(@"error creating audio converter: %@",[self OSStatusToStr:st]);
        return ;
    }
    
    //error = AudioConverterNew(&pcmASBD, &aacASBD, &converter);
    UInt32 outputBitRate = 64000;//1.5*AUDIO_SAMPLE_ROTE; // 192k
    UInt32 propSize = sizeof(outputBitRate);
    
    // ignore errors as setting may be invalid depending on format specifics such as samplerate
    error =   AudioConverterSetProperty(converter, kAudioConverterEncodeBitRate, propSize, &outputBitRate);
    
    // get it back and print it out
    AudioConverterGetProperty(converter, kAudioConverterEncodeBitRate, &propSize, &outputBitRate);
    printf ("AAC Encode Bitrate: %ld\n", outputBitRate);
    
    //error = AudioConverterNew(&pcmASBD, &aacASBD, &converter);
    
    outputSizePerPacket = aacASBD.mBytesPerPacket;
    UInt32 theOutputBufSize = 1024;
    
    if (outputSizePerPacket == 0) {
        // if the destination format is VBR, we need to get max size per packet from the converter
        size = sizeof(outputSizePerPacket);
        error = AudioConverterGetProperty(converter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &outputSizePerPacket);
    }
}

-(void)convertpcm2aac:(char *)pcmBuffer bufferSize:(int)busfferSize{
    //    if (read_block_size == 0) {
    //        time_dts = dts + last_size/(AUDIO_SAMPLE_ROTE*2);
    //    }
    int last_size = 0;
   
    while (last_size != busfferSize)
    {
        if (read_block_size >= 2048) {
            read_block_size = 0;
        }
        if ((busfferSize - last_size) < (2048 -read_block_size))
        {
            memcpy(data_test + read_block_size, pcmBuffer + last_size, (busfferSize - last_size));
            read_block_size += (busfferSize - last_size);
            last_size = busfferSize;
            
            continue;
        }
        else
        {
            memcpy(data_test + read_block_size, pcmBuffer + last_size, (2048 - read_block_size));
            last_size += (2048 - read_block_size);
            read_block_size = 0;
        }
        

        AudioBufferList fillBufList;
        fillBufList.mNumberBuffers = 1;
        fillBufList.mBuffers[0].mNumberChannels = aacASBD.mChannelsPerFrame;
        fillBufList.mBuffers[0].mDataByteSize = outputSizePerPacket;
        fillBufList.mBuffers[0].mData = outputBuffer;
        UInt32 ioOutputDataPackets = 1;//theOutputBufSize / outputSizePerPacket;
        
        if (self.beginHandler) {
            self.beginHandler();
        }
        // pcm to aac
        OSStatus error = AudioConverterFillComplexBuffer(converter, AudioEncoderDataProc, NULL, &ioOutputDataPackets, &fillBufList, NULL);
        UInt32 inNumBytes = fillBufList.mBuffers[0].mDataByteSize;
        if (noErr == error && 0 != ioOutputDataPackets)
        {
            [self setAudioDate:outputBuffer Length:inNumBytes Sample:4 Channel:1];
        }
    }
    
}


-(void) setAudioDate:(char*)datas  Length : (int) len Sample : (int) sample Channel : (int) channel
{
    int length = len + 7;
    
    char bits[7] = {0};
    bits[0] = 0xff;
    bits[1] = 0xf1;
    bits[2] = 0x40 | (sample<<2) | (channel>>2);
    bits[3] = ((channel&0x3)<<6) | (length >>11);
    bits[4] = (length>>3) & 0xff;
    bits[5] = ((length<<5) & 0xff) | 0x1f;
    bits[6] = 0xfc;
    
    char* data = (char*) malloc(sizeof(char)*length);
    if (NULL == data) {
    }
    
    memcpy(data, bits, 7);
    memcpy(data+7, datas, len);
    
    if (self.callbackHandler) {
        self.callbackHandler(data,length);
    }
    free(data);
    
}

static OSStatus AudioEncoderDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{

    ioData->mBuffers[0].mData = data_test;
    ioData->mBuffers[0].mDataByteSize = 2048;
    ioData->mBuffers[0].mNumberChannels = 1;
    *ioNumberDataPackets = 1;
    
    return noErr;
}

@end
