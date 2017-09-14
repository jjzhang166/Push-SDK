//
//  IAAudioCaptureEngine.h
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/16.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAMediaDataModel.h"

@protocol IAAudioCaptureEngineDelegate <NSObject>

- (void)gotAudioEncodedData:(NSData*)aData len:(long long)len timeDuration:(long long)duration;

@end

@interface IAAudioCaptureEngine : NSObject

@property(nonatomic,weak)id<IAAudioCaptureEngineDelegate> delegate;

-(void)open;
-(void)close;
-(BOOL)isOpen;

-(IAMediaDataModel*)audioEncodedDataModel;
-(void)removeEncodedData:(IAMediaDataModel*)encodedModel;

@end
