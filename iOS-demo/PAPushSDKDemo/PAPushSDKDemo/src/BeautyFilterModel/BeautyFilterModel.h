//
//  BeautyFilterModel.h
//  anchor
//
//  Created by wangweishun on 9/18/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BeautyFilterModel : NSObject

@property (nonatomic, assign) CGFloat smooth;
@property (nonatomic, assign) CGFloat white;
@property (nonatomic, assign) CGFloat pink;

+ (id)localBeautyModel;
+ (id)modelWithSmooth:(CGFloat)smooth white:(CGFloat)white pink:(CGFloat)pink;

- (void)save;

@end
