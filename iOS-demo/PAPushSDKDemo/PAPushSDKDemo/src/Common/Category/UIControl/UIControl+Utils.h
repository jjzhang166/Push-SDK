//
//  UIControl+Utils.h
//  anchor
//
//  Created by yu on 16/6/17.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControl (Utils)

/**
 移除所有的actions
 */
- (void)removeAllTargets;

/**
 Adds or replaces a target and action for a particular event (or events)
 to an internal dispatch table.
 */
- (void)setTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

/**
 Adds a block for a particular event (or events) to an internal dispatch table.
 It will cause a strong reference to @a block.
 */
- (void)addBlockForControlEvents:(UIControlEvents)controlEvents block:(void (^)(id sender))block;

/**
 Adds or replaces a block for a particular event (or events) to an internal
 dispatch table. It will cause a strong reference to @a block.
 */
- (void)setBlockForControlEvents:(UIControlEvents)controlEvents block:(void (^)(id sender))block;

/**
 Removes all blocks for a particular event (or events) from an internal
 dispatch table.
 */
- (void)removeAllBlocksForControlEvents:(UIControlEvents)controlEvents;

@end
