//
//  PAAudioDeviceHelper.m
//  anchor
//
//  Created by Derek Lix on 25/11/2016.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "PAAudioDeviceHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "IAUtility.h"

@interface PAAudioDeviceHelper (){
    BOOL    recording;
    
}

@property(nonatomic,assign)SInt32  preRouteChangeReason;

- (BOOL)hasHeadset;
- (BOOL)hasMicphone;
- (void)cleanUpForEndRecording;

@end

@implementation PAAudioDeviceHelper


-(id)init{
    
    if (self=[super init]) {
    }
    return self;
}

- (void)setupSession {
    NSLog(@"deviceHelper setupSession");
    self.preRouteChangeReason = kAudioSessionRouteChangeReason_Unknown;
    recording = NO;
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange,
                                     paAudioRouteChangeListenerCallback,
                                     (__bridge void *)(self));
    
    
    [self enableBlueToothInput:[self hasHeadset]];
    [self printCurrentCategory];
}


- (BOOL)hasMicphone {
    return [[AVAudioSession sharedInstance] inputIsAvailable];
}

- (BOOL)hasHeadset {
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: audio session code works only on a device
    return NO;
#else
    CFStringRef route;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    
    if((route == NULL) || (CFStringGetLength(route) == 0)){
        // Silent Mode
        NSLog(@"AudioRoute: SILENT, do nothing!");
    } else {
        NSString* routeStr = (__bridge NSString*)route;
        NSLog(@"AudioRoute: %@", routeStr);
        
        /* Known values of route:
         * "Headset"
         * "Headphone"
         * "Speaker"
         * "SpeakerAndMicrophone"
         * "HeadphonesAndMicrophone"
         * "HeadsetInOut"
         * "ReceiverAndMicrophone"
         * "Lineout"
         */
        
        NSRange headphoneRange = [routeStr rangeOfString : @"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString : @"Headset"];
        if (headphoneRange.location != NSNotFound) {
            return YES;
        } else if(headsetRange.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
#endif
    
}

- (void)resetOutputTarget {
    return;
    BOOL hasHeadset = [self hasHeadset];
    NSLog (@"Will Set output target is_headset = %@ .", hasHeadset ? @"YES" : @"NO");
    UInt32 audioRouteOverride = hasHeadset ? kAudioSessionOverrideAudioRoute_None:kAudioSessionOverrideAudioRoute_Speaker;
    OSStatus result = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    if (result!=kAudioSessionNoError) {
        NSLog(@"resetOutputTarget error");
        
    }
}


- (void)resetCategory {
    if (!recording) {
        
     [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers  error:nil];
    }
    
//    if (!recording) {
//        NSLog(@"Will Set category to static value = AVAudioSessionCategoryPlayback!");
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
//                                               error:nil];
//    }
}

- (void)resetSettings {
    [self resetOutputTarget];
    [self resetCategory];
    BOOL isSucced = [[AVAudioSession sharedInstance] setActive: YES error:NULL];
    if (!isSucced) {
        NSLog(@"Reset audio session settings failed!");
    }
}

- (void)cleanUpForEndRecording {
    recording = NO;
    [self resetSettings];
}

- (void)printCurrentCategory {
    UInt32 audioCategory;
    UInt32 size = sizeof(audioCategory);
    AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &audioCategory);
    
    if ( audioCategory == kAudioSessionCategory_UserInterfaceSoundEffects ){
        NSLog(@"current category is : dioSessionCategory_UserInterfaceSoundEffects");
    } else if ( audioCategory == kAudioSessionCategory_AmbientSound ){
        NSLog(@"current category is : kAudioSessionCategory_AmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_AmbientSound ){
        NSLog(@"current category is : kAudioSessionCategory_AmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_SoloAmbientSound ){
        NSLog(@"current category is : kAudioSessionCategory_SoloAmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_MediaPlayback ){
        NSLog(@"current category is : kAudioSessionCategory_MediaPlayback");
    } else if ( audioCategory == kAudioSessionCategory_LiveAudio ){
        NSLog(@"current category is : kAudioSessionCategory_LiveAudio");
    } else if ( audioCategory == kAudioSessionCategory_RecordAudio ){
        NSLog(@"current category is : kAudioSessionCategory_RecordAudio");
    } else if ( audioCategory == kAudioSessionCategory_PlayAndRecord ){
        NSLog(@"current category is : kAudioSessionCategory_PlayAndRecord");
    } else if ( audioCategory == kAudioSessionCategory_AudioProcessing ){
        NSLog(@"current category is : kAudioSessionCategory_AudioProcessing");
    } else {
        NSLog(@"current category is : unknow");
    }
}

void paAudioRouteChangeListenerCallback (
                                       void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue
                                       ) {
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    // Determines the reason for the route change, to ensure that it is not
    //        because of a category change.
    
    CFDictionaryRef    routeChangeDictionary = inPropertyValue;
    CFNumberRef routeChangeReasonRef =
    CFDictionaryGetValue (routeChangeDictionary,
                          CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
    SInt32 routeChangeReason;
    CFNumberGetValue (routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
    PAAudioDeviceHelper* audioDeviceHelper = (__bridge PAAudioDeviceHelper *) inUserData;
    NSLog(@"deviceHelper paAudioRouteChangeListenerCallback :%d pre :%d",routeChangeReason,audioDeviceHelper.preRouteChangeReason);
    switch (routeChangeReason) {
            
            
        case  kAudioSessionRouteChangeReason_Unknown: //0
            break;
        case  kAudioSessionRouteChangeReason_NewDeviceAvailable://1
        {
            
//            if (audioDeviceHelper.preRouteChangeReason != kAudioSessionRouteChangeReason_NewDeviceAvailable) {
//                [audioDeviceHelper enableBlueToothInput:[audioDeviceHelper hasHeadset]];
//            }
//            if (![audioDeviceHelper hasMicphone]) {
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"pluggInMicrophone"
//                                                                    object:nil];
//            }
        }
            break;
        case kAudioSessionRouteChangeReason_OldDeviceUnavailable://2
        {
             [audioDeviceHelper resetSettings];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ununpluggingHeadset"
                                                                object:nil];
        }
            break;
        case kAudioSessionRouteChangeReason_CategoryChange://3
        {
//            if (audioDeviceHelper.preRouteChangeReason != kAudioSessionRouteChangeReason_CategoryChange) {
//                [audioDeviceHelper enableBlueToothInput:[audioDeviceHelper hasHeadset]];
//            }
            
        }
            break;
        case kAudioSessionRouteChangeReason_Override://4
            break;
        case kAudioSessionRouteChangeReason_WakeFromSleep://6
            break;
        case kAudioSessionRouteChangeReason_NoSuitableRouteForCategory://7
        {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"lostMicroPhone"
                                                                object:nil];
        }
            break;
        case kAudioSessionRouteChangeReason_RouteConfigurationChange://8
        {
            /*
            if (audioDeviceHelper.preRouteChangeReason != kAudioSessionRouteChangeReason_CategoryChange) {
                NSError*  error;
                AVAudioSessionCategoryOptions options ;
                if ([audioDeviceHelper hasHeadset]) {
                    options = AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers;
                }else{
                    options = AVAudioSessionCategoryOptionMixWithOthers;
                }
                BOOL categoryResult = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options  error:&error];
                if (!categoryResult) {
                    NSLog(@"setCategory failure");
                }
            }
             */
        }
            break;
        default:
            break;
    }
    
    audioDeviceHelper.preRouteChangeReason = routeChangeReason;
    [audioDeviceHelper printCurrentCategory];
    
}


-(void)enableBlueToothInput:(BOOL)enable{

    [self resetOutputTarget];
    BOOL success = [[AVAudioSession sharedInstance] setActive:NO error: nil];
    if (!success) {
        NSLog(@"deactivationError");
    }
    // create and set up the audio session
    NSError*  error;
    
    AVAudioSessionCategoryOptions options ;
//    if (enable) {
//        options = AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers;
//    }else{
//        options = AVAudioSessionCategoryOptionMixWithOthers;
//    }
    
    options = AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers;
    BOOL categoryResult = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options  error:&error];
    if (!categoryResult) {
        NSLog(@"setCategory failure");
    }
    success = [[AVAudioSession sharedInstance] setActive:YES error: &error];
    if (!success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PA_AUDIOHARDWARE_LOADERROR object:[NSNumber numberWithInteger:[error code]]];
    }
    
    NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if (route.portType == AVAudioSessionPortBluetoothHFP)
        {
            NSError* error ;
            BOOL result = [[AVAudioSession sharedInstance] setPreferredInput:route error:&error];
            if (error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:PA_AUDIOHARDWARE_LOADERROR object:[NSNumber numberWithInteger:[error code]]];
            }
        }else{
            NSLog(@"set built-in microphone");
        }
    }
    
}

-(void)dealloc{

    AudioSessionRemovePropertyListener(kAudioSessionProperty_AudioRouteChange);
}


@end
