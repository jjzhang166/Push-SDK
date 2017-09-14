//
//  IAAudioCaptureEngine.h
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/16.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAMediaDataModel.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CoreFoundation/CoreFoundation.h>

#define  SUPPORT_AAC_ENCODER  @"SUPPORT_AAC_ENCODER"


typedef void(^IAAudioAuthorizationHandler)(BOOL authoried);

@protocol IAAudioCaptureEngineDelegate <NSObject>

- (void)gotAudioEncodedData:(NSData*)aData len:(long long)len timeDuration:(long long)duration;

@end

@interface IAAudioCaptureEngine : NSObject

@property(nonatomic,weak)id<IAAudioCaptureEngineDelegate> delegate;
@property(atomic,assign)BOOL  preAudioSendSuccess;
@property(nonatomic,strong)AVCaptureAudioDataOutput* outputDevice;
@property(nonatomic,weak) id outputSampleBufferDelegate;

-(id)initWithAudioDataOutputSampleBufferDelegate:(id)delegateObserver  authorizationHandler:(IAAudioAuthorizationHandler)handler;

-(void)open;
-(void)close;
-(BOOL)isOpen;

-(IAMediaDataModel*)audioEncodedDataModel;
-(void)removeEncodedData:(IAMediaDataModel*)encodedModel;

@end
