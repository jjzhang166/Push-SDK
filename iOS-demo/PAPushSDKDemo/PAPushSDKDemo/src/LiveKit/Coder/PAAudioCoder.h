//
//  PAAudioCoder.h
//  anchor
//
//  Created by Derek Lix on 24/11/2016.
//  Copyright © 2016 PAJK. All rights reserved.
//

typedef void(^PACoderBeginHandler)();
typedef void(^PACoderDataCallbackHandler)(char* buffer, UInt32 length);


#import <Foundation/Foundation.h>

@interface PAAudioCoder : NSObject

-(id)initWithDataCallbackHandler:(PACoderDataCallbackHandler)coderCallbackHandler beginHandler:(PACoderBeginHandler)beginHandler;

-(void)convertpcm2aac:(char *)pcmBuffer bufferSize:(int)busfferSize;

@end
