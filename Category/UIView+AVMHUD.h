//
//  UIView+AVMHUD.h
//  AVM
//
//  Created by sunzongtang on 2017/9/6.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AVMHUD)

- (void)showHint:(NSString *)hint;
- (void)showHint:(NSString *)hint yOffset:(float)yOffset;

@end
