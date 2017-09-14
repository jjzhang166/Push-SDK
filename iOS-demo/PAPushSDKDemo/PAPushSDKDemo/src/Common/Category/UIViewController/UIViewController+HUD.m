//
//  UIViewController+HUD.m
//  PAPersonalDoctor
//
//  Created by shixiangyu on 16/4/8.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "UIViewController+HUD.h"

@implementation UIViewController (HUD)

- (void)showHud
{
    [self showHudWithInViewCenterXOffset:0.0f centerYOffset:0.0f];
}

- (void)showHudWithInViewCenterXOffset:(CGFloat)xOffSet centerYOffset:(CGFloat)yOffSet
{
    [self.view showHudWithInViewCenterXOffset:xOffSet centerYOffset:yOffSet];
}

- (void)showHudWithText:(NSString *)text
{
    if (text && text.length>1) {
        [self.view showHudWithText:text];
    }
}

- (void)showHudWithTextOnly:(NSString *)text
{
    [self showHudWithTextOnly:text block:nil];
}

- (void)showHudWithTextOnly:(NSString *)text block:(void(^)())block
{
    [self.view showHudWithTextOnly:text block:block];
}

- (void)showHudWithErrorCode:(NSInteger)errorCode
{
//    [self.view showHudWithErrorCode:errorCode];
}

- (void)hideHud
{
    [self.view hideHud];
}

- (void)hideHudAfterDelay:(NSTimeInterval) delay
{
    [self hideHudAfterDelay:delay blcok:nil];
}

- (void)hideHudAfterDelay:(NSTimeInterval) delay blcok:(void(^)())block
{
    [self.view hideHudAfterDelay:delay blcok:block];
}

- (void)showNoDataView
{
    [self.view showNoDataView];
}

- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge
{
    [self.view showNoDataViewInViewWithTopEdge:topEdge];
}

- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge lableAText:(NSString *)lableAString
{
    [self.view showNoDataViewInViewWithTopEdge:topEdge lableAText:lableAString];
}

- (void)showNoDataViewLableAText:(NSString *)lableAString lableBText:(NSString *)lableBString
{
    [self.view showNoDataViewLableAText:lableAString lableBText:lableBString];
}

-(void)removeNoDataView
{
    [self.view removeNoDataView];
}

- (void)showErrorViewWithRetryBlcok:(void(^)())block
{
    [self.view showErrorViewWithRetryBlcok:block];
}

- (void)showErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block
{
    [self.view showErrorViewWithTopEdgeInView:topEdge retryBlcok:block];
}

- (void)showErrorViewInViewWithTopEdge:(CGFloat)topEdge title:(NSString *)title retryBlcok:(void(^)())block
{
    [self.view showErrorViewInViewWithTopEdge:topEdge title:title retryBlcok:block];
}

-(void)removeErrorView
{
    [self.view removeErrorView];
}

- (void)showNetWorkErrorViewWithRetryBlcok:(void(^)())block
{
    [self.view showNetWorkErrorViewWithRetryBlcok:block];
}

- (void)showNetWorkErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block
{
    [self.view showNetWorkErrorViewWithTopEdgeInView:topEdge retryBlcok:block];
}

- (void)showNetWorkErrorViewWithTopEdge:(CGFloat)topEdge title:(NSString *)title retryBlcok:(void(^)())block
{
    [self.view showNetWorkErrorViewWithTopEdge:topEdge title:title retryBlcok:block];
}

- (void)showHtmlNetworkErrorRetryBlcok:(void(^)())rBlock closeBlock:(void(^)())cBlock
{
    [self.view showHtmlNetworkErrorRetryBlcok:rBlock closeBlock:cBlock];
}

-(void)removeNetWorkView
{
    [self.view removeNetWorkView];
}

- (void)removeAllErrorView
{
    [self.view removeAllErrorView];
}

//- (void)handleRequestErrorWithError:(HMError *)error dataListCount:(NSInteger)dataListCount block:(void(^)())block
//{
//    [self.view handleRequestErrorWithError:error dataListCount:dataListCount block:block];
//}

@end
