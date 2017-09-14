//
//  UIView+Custom.m
//  anchor
//
//  Created by wangweishun on 7/18/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "UIView+Custom.h"

@implementation UIView (Custom)

- (void)addLineWithEdge:(PALineEdge)edge
{
    [self addLineWithEdge:edge lineColor:[UIColor jkn_colorWithHex:0xe0e0e0] height:1.0];
}

- (void)addLineWithEdge:(PALineEdge)edge lineColor:(UIColor *)lineColor height:(CGFloat)height
{
    CGFloat top = 0.0f;
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingNone;
    if (edge == PALineEdgeBottom) {
        top = self.height - height / 2.0;
        autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    } else if (edge == PALineEdgeTop) {
        top = 0.0f;
        autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    }
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, top, self.width, height)];
    lineView.autoresizingMask = autoresizingMask;
    lineView.backgroundColor = lineColor? lineColor : [UIColor jkn_colorWithHex:0xeaeff1];
    lineView.tag = NSIntegerMin + edge;
    [self addSubview:lineView];
}

- (void)addDefaultLightGrayLine:(PALineEdge)edge
{
    [self addDefaultLightGrayLine:edge lineColor:[UIColor jkn_colorWithHex:0xe0e0e0]];
}

- (void)addDefaultLightGrayLine:(PALineEdge)edge lineColor:(UIColor *)color
{
    UIView *lineView = [UIView new];
    lineView.backgroundColor = color;
    lineView.tag = NSIntegerMin + edge;
    lineView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:lineView];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[lineView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(lineView)]];
    NSString *vflStr = nil;
    CGFloat lineWidth = (1.0/[[UIScreen mainScreen] scale]);
    NSDictionary *metrics = @{@"lineWidth":@(lineWidth)};
    if (edge == PALineEdgeTop) {
        vflStr = @"V:|[lineView(lineWidth)]";
    }
    else {
        vflStr = @"V:[lineView(lineWidth)]|";
    }
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:vflStr options:0 metrics:metrics views:NSDictionaryOfVariableBindings(lineView)]];
}

- (void)removeLineWithEdge:(PALineEdge)edge
{
    for (UIView *view in self.subviews) {
        if (view.tag == NSIntegerMin + edge) {
            [view removeFromSuperview];
        }
    }
}

@end
