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
@property(nonatomic, assign)long long  size;
@property(nonatomic, assign)long long  timestamp;

@end
