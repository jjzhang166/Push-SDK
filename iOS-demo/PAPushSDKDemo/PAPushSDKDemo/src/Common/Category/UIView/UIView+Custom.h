//
//  UIView+Custom.h
//  anchor
//
//  Created by wangweishun on 7/18/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PALineEdge) {
    PALineEdgeTop = 0,
    PALineEdgeBottom,
};


@interface UIView (Custom)

- (void)addLineWithEdge:(PALineEdge)edge;
- (void)addLineWithEdge:(PALineEdge)edge lineColor:(UIColor *)lineColor height:(CGFloat)height;
- (void)removeLineWithEdge:(PALineEdge)edge;

- (void)addDefaultLightGrayLine:(PALineEdge)edge;
- (void)addDefaultLightGrayLine:(PALineEdge)edge lineColor:(UIColor *)color;

@end
