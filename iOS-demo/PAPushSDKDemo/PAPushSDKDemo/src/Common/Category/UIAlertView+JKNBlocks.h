//
//  UIAlertView+JKNBlocks.h
//  Shibui
//
//  Created by Jiva DeVoe on 12/28/10.
//  Copyright 2010 Random Ideas, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKNButtonItem.h"

@interface UIAlertView (JKNBlocks)

-(id)initWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonItem:(JKNButtonItem *)inCancelButtonItem otherButtonItems:(JKNButtonItem *)inOtherButtonItems, ... NS_REQUIRES_NIL_TERMINATION;

- (NSInteger)addButtonItem:(JKNButtonItem *)item;

+ (UIAlertView *)alertViewWithTitle:(NSString *)title
                            message:(NSString *)message;

@end
