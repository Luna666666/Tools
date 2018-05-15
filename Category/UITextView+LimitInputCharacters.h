//
//  UITextView+LimitInputCharacters.h
//
//  Created by iminer_szt on 16/7/12.
//  Copyright © 2016年 iminer_szt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AVMTextViewLimitInputDelegate <UITextViewDelegate>

@end

@interface UITextView (LimitInputCharacters)
/**
 *  限制输入的最大字数
 */
- (void)limitInputCharacters:(NSInteger)maxLength;

/**
 最大输入行数
 */
@property (nonatomic, assign) NSUInteger maxLines;

//@property (nonatomic,copy) NSString *placeholder;

- (void)setPlaceholder:(NSString *)placeholder;

@property (nonatomic, weak) id<AVMTextViewLimitInputDelegate> avm_delegate;

@end
