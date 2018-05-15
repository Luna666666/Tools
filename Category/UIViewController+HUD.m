/************************************************************
 *  * Hyphenate CONFIDENTIAL
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Hyphenate Inc.
 */

#import "UIViewController+HUD.h"

#import "MBProgressHUD.h"
#import <objc/runtime.h>

#define kHUDFont [UIFont systemFontOfSize:14]
#define kHUDTextColor [UIColor whiteColor]
#define kHUDBackgroundColor kColorWithRGBA(0, 0, 0, 0.7)

static const void *HttpRequestHUDKey = &HttpRequestHUDKey;

@implementation UIViewController (HUD)

- (MBProgressHUD *)HUD{
    return objc_getAssociatedObject(self, HttpRequestHUDKey);
}

- (void)setHUD:(MBProgressHUD *)HUD{
    objc_setAssociatedObject(self, HttpRequestHUDKey, HUD, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)showHudInView:(UIView *)view hint:(NSString *)hint{
    if (!hint) {
        return;
    }
    if ([MBProgressHUD HUDForView:view] ) {
        [self HUD].label.text = hint;
        return;
    }
    
    hint = [NSString stringWithFormat:@"%@",hint];
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:view animated:YES];
    HUD.label.text = hint;
    HUD.label.font = kHUDFont;
    HUD.label.numberOfLines = 0;
    HUD.offset = CGPointMake(HUD.offset.x, HUD.offset.y -40);
    HUD.removeFromSuperViewOnHide = YES;
    HUD.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    HUD.bezelView.color = [UIColor whiteColor];
    [HUD showAnimated:YES];
    [self setHUD:HUD];
}

- (void)showHint:(NSString *)hint hide:(CGFloat)time{
    if (!hint) {
        return;
    }
    hint = [NSString stringWithFormat:@"%@",hint];
    UIView *view = [UIApplication sharedApplication].keyWindow;
    if ([MBProgressHUD HUDForView:view]) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.userInteractionEnabled = NO;
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.label.text = hint;
    hud.label.font = kHUDFont;
    hud.label.textColor = kHUDTextColor;
    hud.label.numberOfLines = 0;
//    hud.margin = 10.f;
    hud.minSize = CGSizeMake(200, 70);
    hud.offset = CGPointMake(0, -50);
    hud.removeFromSuperViewOnHide = YES;
    hud.animationType = MBProgressHUDAnimationZoom;
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = kHUDBackgroundColor;
    
    [hud hideAnimated:YES afterDelay:time];
}

- (void)showHint:(NSString *)hint
{
    [self showHint:hint hide:2.0];
}

- (void)showHint:(NSString *)hint yOffset:(float)yOffset
{
    if (!hint) {
        return;
    }
    UIView *view = [UIApplication sharedApplication].keyWindow;
    
    if ([MBProgressHUD HUDForView:view]) {
        return;
    }
    hint = [NSString stringWithFormat:@"%@",hint];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
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
    hud.bezelView.color = kHUDBackgroundColor;
    
    [hud hideAnimated:YES afterDelay:2.f];
}

- (void)hideHud{
    MBProgressHUD *hud = [self HUD];
    [hud hideAnimated:NO];
    objc_removeAssociatedObjects(hud);
    if (!hud) {
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:NO];
    }
}


- (void)show:(NSString *)text icon:(NSString *)icon view:(UIView *)view
{
    if (view == nil) view = [UIApplication sharedApplication].keyWindow;
    
    if ([MBProgressHUD HUDForView:view]) {
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.font = kHUDFont;
    hud.label.text = text;
    hud.label.numberOfLines = 0;
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon]]];
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hideAnimated:YES afterDelay:0.8];
}

- (void)showError:(NSString *)error toView:(UIView *)view{
    [self show:error icon:@"error.png" view:view];
}

- (void)showSuccess:(NSString *)success toView:(UIView *)view
{
    [self show:success icon:@"success.png" view:view];
}

@end
