//
//  PAAudioRecordHelper.h
//  anchor
//
//  Created by Derek Lix on 10/04/2017.
//  Copyright © 2017 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PAAudioRecordHelper : NSObject

-(void)setRecordPath:(NSString*)path;
-(void)startRecord;
-(void)stopRecord:(BOOL)isCommandLineStop;
-(void)playRecord;
-(void)stopPlayRecord;
-(void)deleteCurrentRecord;
-(void)deleteOldRecordFile;
-(void)deleteOldRecordFileAtPath:(NSString *)pathStr;
-(void)setMaxRecordTime:(NSInteger)maxTime;
-(NSString*)recordPath;
-(CGFloat)decibels;

@end
