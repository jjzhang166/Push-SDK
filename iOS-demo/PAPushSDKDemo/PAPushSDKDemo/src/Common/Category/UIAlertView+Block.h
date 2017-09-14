//
//  UIAlertView+Block.h
//  Pods
//
//  Created by wangweishun on 6/15/16.
//
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Block)

@property (nonatomic, strong) void (^buttonTappedBlock)(UIAlertView *sender, NSInteger buttonIndex);

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message buttonTappedBlock:(void (^)(UIAlertView *, NSInteger))buttonTappedBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@end
