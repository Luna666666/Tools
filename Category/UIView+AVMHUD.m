//
//  UIView+AVMHUD.m
//  AVM
//
//  Created by sunzongtang on 2017/9/6.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "UIView+AVMHUD.h"

#import "MBProgressHUD.h"

#define kHUDFont [UIFont systemFontOfSize:14]
#define kHUDTextColor [UIColor whiteColor]

@implementation UIView (AVMHUD)

- (void)showHint:(NSString *)hint {
    [self showHint:hint yOffset:0];
}

- (void)showHint:(NSString *)hint yOffset:(float)yOffset
{
    if (!hint) {
        return;
    }
    if ([MBProgressHUD HUDForView:self]) {
        return;
    }
    hint = [NSString stringWithFormat:@"%@",hint];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
    hud.userInteractionEnabled = NO;
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.label.text = hint;
    hud.label.font = kHUDFont;
    hud.label.textColor = kHUDTextColor;
    hud.label.numberOfLines = 0;
    //    hud.margin = 50.f;
    hud.minSize = CGSizeMake(200, 70);
    hud.offset = CGPointMake(hud.offset.x, yOffset);
    hud.removeFromSuperViewOnHide = YES;
    hud.animationType = MBProgressHUDAnimationZoom;
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = kColorWithRGBA(0, 0, 0, 0.6);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

@end
