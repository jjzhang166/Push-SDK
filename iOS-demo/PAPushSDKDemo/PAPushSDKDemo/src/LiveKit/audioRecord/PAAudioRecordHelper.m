//
//  PAAudioRecordHelper.m
//  anchor
//
//  Created by Derek Lix on 10/04/2017.
//  Copyright © 2017 PAJK. All rights reserved.
//

#import "PAAudioRecordHelper.h"
#import "AudioRecordTool.h"
#import <AVFoundation/AVFoundation.h>
#include "lame.h"

#define kSandboxPathStr [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define kMp3FileName @"myRecord.mp3"
#define kCafFileName @"myRecord.caf"

@interface PAAudioRecordHelper ()

@property (nonatomic,copy) NSString* cafPathStr;
@property (nonatomic,copy) NSString* mp3PathStr;
@property (nonatomic,strong) AudioRecordTool* audioRecord; //maxRecordTime
@property (nonatomic,assign) BOOL isStopRecorde;
@property (nonatomic,assign) BOOL isFinishConvert;
@property (nonatomic,assign) BOOL isCommandLineStop;

@end

@implementation PAAudioRecordHelper

-(id)init{
    
    if (self = [super init]) {
        self.isStopRecorde = YES;
        self.isFinishConvert = NO;
        self.cafPathStr = [kSandboxPathStr stringByAppendingPathComponent:kCafFileName];//default path
        self.mp3PathStr =  [kSandboxPathStr stringByAppendingPathComponent:kMp3FileName];
        _audioRecord = [[AudioRecordTool alloc] init];
        [AudioRecordTool checkRecordPermission:^(BOOL granted) {
            if (!granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"app需要访问您的麦克风"
                                                message:@"请启用麦克风-设置/隐私/麦克风"
                                               delegate:nil
                                      cancelButtonTitle:@"确定"
                                      otherButtonTitles:nil] show];
                });
            }
        }];
    }
    return self;
}

-(void)setRecordPath:(NSString*)path{
    if (path) {
        self.cafPathStr = [path stringByReplacingOccurrencesOfString:@".mp3" withString:@".caf"];
        self.mp3PathStr = path;
    }else{
        
        self.mp3PathStr =  [kSandboxPathStr stringByAppendingPathComponent:kMp3FileName];
        
        self.cafPathStr = [kSandboxPathStr stringByAppendingPathComponent:kCafFileName];
    }
}

-(void)setMaxRecordTime:(NSInteger)maxTime{
    if (self.audioRecord) {
        self.audioRecord.maxRecordTime = maxTime;
    }
}

-(NSString*)recordPath{
    return self.cafPathStr;
}

-(CGFloat)decibels{
    
    return [self.audioRecord decibels];
}

-(void)startRecord{
    
    if (!_audioRecord) return;

    self.isStopRecorde = NO;
    self.isFinishConvert = NO;
    [_audioRecord prepareRecordAtRecordPath:[NSURL URLWithString:self.cafPathStr]];
    [_audioRecord startRecord];
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [wself conventToMp3];
    });

}
-(void)stopRecord:(BOOL)isCommandLineStop{
    if (!_audioRecord) return;
    [_audioRecord stopRecord];
    self.isStopRecorde = YES;
    self.isCommandLineStop = isCommandLineStop;

//    __weak typeof(self) wself = self;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [wself audio_PCMtoMP3:isCommandLineStop];
//    });
}
-(void)playRecord{
}
-(void)stopPlayRecord{
}
-(void)deleteCurrentRecord{
}
-(void)deleteOldRecordFile{
}
-(void)deleteOldRecordFileAtPath:(NSString *)pathStr{
}

#pragma mark - caf转mp3
- (void)audio_PCMtoMP3:(BOOL)fromCommandLine
{
    NSLog(@"RecordHelper begin");
    @try {
        int read, write;
        
        FILE *pcm = fopen([self.cafPathStr cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        if (NULL == pcm) {
            return;
        }

        fseek(pcm, 0l, SEEK_END);
        long fileLen = ftell(pcm)/4;
        if (4096 >= fileLen) {
            fclose(pcm);
            return;
        }

        fseek(pcm, 0l, SEEK_SET);
        long tempFileLen = 0;
        int offset = 40000;
        if ((fileLen<offset)||!fromCommandLine) {
            offset = 0;
        }

        NSLog(@"longggg :%ld,offset:%d",fileLen,offset);

        fseek(pcm, 4*1024, SEEK_CUR); //skip file header

        FILE *mp3 = fopen([self.mp3PathStr cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        if (NULL == mp3) {
            if (NULL != pcm)
                fclose(pcm);
            return;
        }

     //   251950
     //   1007800
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, HLSAudioRecordSampleRate);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        unsigned char mp3_header[10] = {0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x47, 0x00};
        fwrite(mp3_header, sizeof(mp3_header), 1, mp3);

        do {
            if (tempFileLen>=(fileLen-offset)) {
                break;
            }
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            tempFileLen += read;
        
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        
        //remove caf file
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.cafPathStr]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.cafPathStr error:nil];
        }
    }
    
}


- (void)conventToMp3 {
    @try {
        int read, write;
        FILE *pcm = fopen([self.cafPathStr cStringUsingEncoding:NSASCIIStringEncoding], "rb");
        FILE *mp3 = fopen([self.mp3PathStr cStringUsingEncoding:NSASCIIStringEncoding], "wb");
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE * 2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame,2);
        lame_set_in_samplerate(lame, HLSAudioRecordSampleRate);
     //   lame_set_VBR(lame, vbr_default);
        lame_set_brate(lame, 16);
        lame_set_mode(lame, 3);
        lame_set_quality(lame, 2);
        lame_init_params(lame);
        
        long curpos;
        BOOL isSkipPCMHeader = NO;
        int readAfterStop = 0;
    
        unsigned char mp3_header[10] = {0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
        fwrite(mp3_header, sizeof(mp3_header), 1, mp3);
        do {
            curpos = ftell(pcm);
            long startPos = ftell(pcm);
            fseek(pcm, 0, SEEK_END);
            long endPos = ftell(pcm);
            long length = endPos - startPos;
            fseek(pcm, curpos, SEEK_SET);
            long maxLen = PCM_SIZE * 10 * sizeof(short int);
//            if (self.isStopRecorde&&self.isCommandLineStop) { //为了不录结尾处的线程结束声
//                NSLog(@"exit loop");
//                break;
//            }

            if (self.isCommandLineStop && self.isStopRecorde) {
                readAfterStop ++;
                if(readAfterStop > 4) {
                    NSLog(@"Eoollo last read %d length %ld", read, length);
                    readAfterStop = 0;
                    break;
                }
            }

            if (length > maxLen || self.isStopRecorde) {
                
                if (!isSkipPCMHeader) {
                    //Uump audio file header, If you do not skip file header
                    //you will heard some noise at the beginning!!!
                    fseek(pcm, 4 * 1024, SEEK_SET);
                    isSkipPCMHeader = YES;
                    NSLog(@"skip pcm file header !!!!!!!!!!");
                }
                read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                fwrite(mp3_buffer, write, 1, mp3);
//                NSLog(@"Eoollo do read %d length %ld self.isCommandLineStop %d", read, length, self.isCommandLineStop);
            } else {
                [NSThread sleepForTimeInterval:0.05];
            }
            
            if (10 > length && self.isStopRecorde) {
//                NSLog(@"Eoollo do read %d length %ld write %d", read, length, write);
                break;
            }
        } while (1);

//        NSLog(@"do read write length %d bytes, stop %d", write, self.isStopRecorde);
//
//        read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
//        write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
//        NSLog(@"read %d bytes and flush to mp3 file", write);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        self.isFinishConvert = YES;
    }
    @catch (NSException *exception) {
        NSLog(@"conventToMp3 %@", [exception description]);
    }
    @finally {
    }
}




@end
