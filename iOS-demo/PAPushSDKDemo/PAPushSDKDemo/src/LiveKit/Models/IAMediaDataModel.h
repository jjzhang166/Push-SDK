//
//  IAMediaDataModel.h
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/17.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAMediaDataModel : NSObject

@property(nonatomic, strong)NSData*  data;
@property(nonatomic, assign)unsigned long long  size;
@property(nonatomic, assign)long long  timestamp;
@property(nonatomic, assign)BOOL       isVideo;
@property(nonatomic, assign)BOOL       isKeyFrame;
@property(nonatomic, assign)BOOL       isMetadata;

@end
