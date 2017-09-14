//
//  BeautyFilterModel.m
//  anchor
//
//  Created by wangweishun on 9/18/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "BeautyFilterModel.h"
#import "ModelSerialize.h"

#define kBeautyPara @"beauty_para_dict"

@implementation BeautyFilterModel

SERIALIZE_CODER_DECODER()

+ (id)localBeautyModel
{
    NSDictionary *beautyDict = [[NSUserDefaults standardUserDefaults] objectForKey:kBeautyPara];
    if (beautyDict) {
        BeautyFilterModel *model = [[BeautyFilterModel alloc] init];
        model.smooth = [beautyDict[@"smooth"] floatValue];
        model.white = [beautyDict[@"white"] floatValue];
        model.pink = [beautyDict[@"pink"] floatValue];
        return model;
    }
    return nil;
}

+ (id)modelWithSmooth:(CGFloat)smooth white:(CGFloat)white pink:(CGFloat)pink
{
    BeautyFilterModel *model = [[BeautyFilterModel alloc] init];
    model.smooth = smooth;
    model.white = white;
    model.pink = pink;
    return model;
}

- (void)save
{
    NSDictionary *dict = @{@"smooth":@(self.smooth), @"white":@(self.white), @"pink":@(self.pink)};
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kBeautyPara];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
