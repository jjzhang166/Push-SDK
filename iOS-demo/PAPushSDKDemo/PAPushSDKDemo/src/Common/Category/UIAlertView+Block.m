//
//  UIAlertView+Block.m
//  Pods
//
//  Created by wangweishun on 6/15/16.
//
//

#import "UIAlertView+Block.h"
#import <objc/runtime.h>

@implementation UIAlertView (Block)

@dynamic buttonTappedBlock;

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message buttonTappedBlock:(void (^)(UIAlertView *, NSInteger))buttonTappedBlock cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION {
    if (self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil]) {
        self.buttonTappedBlock = buttonTappedBlock;
        
        if (otherButtonTitles) {
            // surrogating the var args to the UIAlertView
            va_list argList;
            va_start(argList, otherButtonTitles);
            NSString *title;
            while ((title = va_arg(argList, NSString *))) {
                [self addButtonWithTitle:title];
            }
            va_end(argList);
        }
    }
    return self;
}

- (void (^)(UIAlertView *, NSInteger))buttonTappedBlock {
    return objc_getAssociatedObject(self, @selector(buttonTappedBlock));
}

- (void)setButtonTappedBlock:(void (^)(UIAlertView *, NSInteger))buttonTappedBlock {
    self.delegate = self;
    
    objc_setAssociatedObject(self, @selector(buttonTappedBlock), buttonTappedBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.buttonTappedBlock) {
        self.buttonTappedBlock(alertView, buttonIndex);
    }
}

@end
