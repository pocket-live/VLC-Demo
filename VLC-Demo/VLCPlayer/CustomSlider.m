//
//  CustomSlider.m
//  TedcallStorage
//
//  Created by  tedcall on 16/6/28.
//  Copyright © 2016年 pocket. All rights reserved.
//

#import "CustomSlider.h"

@implementation CustomSlider

- (void)drawRect:(CGRect)rect
{
    UIImageView *imageView = nil;
    // 取得滑块View
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            if (view.frame.size.width == view.frame.size.height) {
                imageView = (UIImageView *)view;
            }
        }
    }
    
    if (imageView) { // 有值
        CGFloat redViewW = 6.0;
        CGFloat redViewH =redViewW;
        CGFloat redViewX = (imageView.frame.size.width - redViewW)/2;
        CGFloat redViewY = (imageView.frame.size.height - redViewH)/2;
        UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(redViewX, redViewY, redViewW, redViewH)];
        
        redView.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.7];
        redView.layer.cornerRadius = redViewW/2;
        redView.layer.masksToBounds = YES;
        [imageView addSubview:redView];
    }
}

// 重写进度条frame
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectMake(10, 10, bounds.size.width - 10, 6.0);
}

// 解决两边空隙问题
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    rect.origin.x = rect.origin.x - 10 ;
    rect.size.width = rect.size.width +20;
    return CGRectInset ([super thumbRectForBounds:bounds trackRect:rect value:value], 10, 10);
}

@end
