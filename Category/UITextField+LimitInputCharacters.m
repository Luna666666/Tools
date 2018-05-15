//
//  UITextField+LimitInputCharacters.m
//
//  Created by iminer_szt on 16/7/12.
//  Copyright © 2016年 iminer_szt. All rights reserved.
//

#import "UITextField+LimitInputCharacters.h"
#import <objc/runtime.h>

static const char kMaxInputLength;
@implementation UITextField (LimitInputCharacters)
- (void)limitInputCharacters:(NSInteger)maxLength{
    objc_setAssociatedObject(self, &kMaxInputLength, @(maxLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addTarget:self action:@selector(textFieldChange) forControlEvents:UIControlEventEditingChanged];
}
#pragma mark 限制字数
- (void)textFieldChange{
    NSString *toBeString = self.text;
    NSInteger maxLimitLength = [objc_getAssociatedObject(self, &kMaxInputLength) integerValue];
    if (maxLimitLength == 0) {
        maxLimitLength = 30;
    }
//    for (UITextInputMode *inputMode in [UITextInputMode activeInputModes]) {
    
            NSString *lang = [[UIApplication sharedApplication]textInputMode].primaryLanguage ;
//        NSString *lang = inputMode.primaryLanguage;
        if([lang hasPrefix:@"zh-Hans"]){ //简体中文输入，包括简体拼音，健体五笔，简体手写
            UITextRange *selectedRange = [self markedTextRange];
            UITextPosition *position = [self positionFromPosition:selectedRange.start offset:0];
            
            if (!position){//非高亮
                if (toBeString.length > maxLimitLength) {
                    self.text = [toBeString substringToIndex:maxLimitLength];
                }
            }
            
        }else{//中文输入法以外
            if (toBeString.length > maxLimitLength) {
                self.text = [toBeString substringToIndex:maxLimitLength];
            }
        }
//    }
}

//开启不能使用粘贴复制
//-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
//    return NO;
//}

//设置placeholder颜色
//NSMutableDictionary *att1 = [NSMutableDictionary dictionaryWithDictionary:self.defaultTextAttributes];
//att1[NSForegroundColorAttributeName] = GQColor(153, 153, 153);
//NSAttributedString *p_Str1 = [[NSAttributedString alloc] initWithString:self.placeholder attributes:att1];
//self.attributedPlaceholder = p_Str1;

@end
