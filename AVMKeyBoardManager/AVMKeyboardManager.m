//
//  AVMKeyBoardManager.m
//  AVM
//
//  Created by sunzongtang on 2017/9/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMKeyboardManager.h"
#import <FDFullscreenPopGesture/UINavigationController+FDFullscreenPopGesture.h>
#import <objc/runtime.h>

#pragma mark -AVMKeyboardInputAccessoryView
@interface AVMKeyboardInputAccessoryView : UIView

@property (nonatomic, strong) UIButton *sureButton;

+ (instancetype)defaultInputAccessoryView:(SEL)sureAction target:(id)target;
+ (instancetype)new NS_UNAVAILABLE;
@end
@implementation AVMKeyboardInputAccessoryView

+ (instancetype)defaultInputAccessoryView:(SEL)sureAction target:(id)target {
    AVMKeyboardInputAccessoryView *accessoryView = [[self alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 40)];
    [accessoryView.sureButton addTarget:target action:sureAction forControlEvents:UIControlEventTouchUpInside];
    return accessoryView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _sureButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _sureButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [_sureButton setTitle:@"完成" forState:UIControlStateNormal];
        [_sureButton setTitleColor:[UIColor colorWithRed:21.0/255.0 green:126.0/255.0 blue:251.0/255 alpha:1] forState:UIControlStateNormal];
        [self addSubview:_sureButton];
        
        CALayer *whiteLineLayer = [CALayer layer];
        whiteLineLayer.frame = CGRectMake(0, CGRectGetHeight(frame)-0.5, CGRectGetWidth(frame), 0.5);
        whiteLineLayer.backgroundColor = [UIColor whiteColor].CGColor;
        [self.layer addSublayer:whiteLineLayer];
        
        
        self.backgroundColor = kColorWithRGB(210, 213, 219);
        _sureButton.backgroundColor = [UIColor clearColor];
        CGFloat width = 60;
        _sureButton.frame = CGRectMake(CGRectGetWidth(frame) -width-2, 0, width, CGRectGetHeight(frame));
        
    }
    return self;
}

@end


#pragma mark -runtime -exchangeMethod

@interface UITextField (AVMInputAccessoryView)

@end
@implementation UITextField (AVMInputAccessoryView)

+ (void)load {
    Method orignalM = class_getInstanceMethod([self class], @selector(initWithFrame:));
    Method exchangedM = class_getInstanceMethod([self class], @selector(avm_initWithFrame:));
    method_exchangeImplementations(orignalM, exchangedM);
    
    Method orignalM_c = class_getInstanceMethod([self class], @selector(initWithCoder:));
    Method exchangedM_c = class_getInstanceMethod([self class], @selector(avm_initWithCoder:));
    method_exchangeImplementations(orignalM_c, exchangedM_c);
}

- (instancetype)avm_initWithFrame:(CGRect)frame {
    [self avm_initWithFrame:frame];
    [self addInputAccessoryView];
    return self;
}

- (instancetype)avm_initWithCoder:(NSCoder *)aDecoder {
    [self avm_initWithCoder:aDecoder];
    [self addInputAccessoryView];
    return self;
}

- (void)addInputAccessoryView {
    AVMKeyboardInputAccessoryView *inputView = [AVMKeyboardInputAccessoryView defaultInputAccessoryView:@selector(registerSelfFirstResponder) target:self];
    self.inputAccessoryView = inputView;
}

- (void)registerSelfFirstResponder {
    [self resignFirstResponder];
}

@end

@interface UITextView (AVMInputAccessoryView)

@end
@implementation UITextView (AVMInputAccessoryView)

+ (void)load {
    Method orignalM = class_getInstanceMethod([self class], @selector(initWithFrame:));
    Method exchangedM = class_getInstanceMethod([self class], @selector(avm_initWithFrame:));
    method_exchangeImplementations(orignalM, exchangedM);
    
    Method orignalM_c = class_getInstanceMethod([self class], @selector(initWithCoder:));
    Method exchangedM_c = class_getInstanceMethod([self class], @selector(avm_initWithCoder:));
    method_exchangeImplementations(orignalM_c, exchangedM_c);
}

- (instancetype)avm_initWithFrame:(CGRect)frame {
    [self avm_initWithFrame:frame];
    [self addInputAccessoryView];
    return self;
}

- (instancetype)avm_initWithCoder:(NSCoder *)aDecoder {
    [self avm_initWithCoder:aDecoder];
    [self addInputAccessoryView];
    return self;
}

- (void)addInputAccessoryView {
    AVMKeyboardInputAccessoryView *inputView = [AVMKeyboardInputAccessoryView defaultInputAccessoryView:@selector(registerSelfFirstResponder) target:self];
    self.inputAccessoryView = inputView;
}

- (void)registerSelfFirstResponder {
    [self resignFirstResponder];
}


@end

#pragma mark -AVMKeyboardManager
@interface AVMKeyboardManager ()

@property (nonatomic, weak) UIViewController *currentViewController;
@property (nonatomic, weak) UIView *firstResponderView;
@property (nonatomic, assign) CGRect currentViewFrame;
@property (nonatomic, assign) CGRect keyboardFrame;


@end
@implementation AVMKeyboardManager

avm_singleton_implementation(AVMKeyboardManager);

- (instancetype)init {
    if (self = [super init]) {
        self.avmAutoAdjustKeyboardHeight = YES;
        [self addKeyboardMonitor];
    }
    return self;
}

- (void)removeKeyBoardMoitor {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addKeyboardMonitor {
    NSNotificationCenter * nCenter = [NSNotificationCenter defaultCenter];
    
    [nCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [nCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [nCenter addObserver:self selector:@selector(myTextFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [nCenter addObserver:self selector:@selector(myTextFieldDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:nil];
    [nCenter addObserver:self selector:@selector(myTextViewDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [nCenter addObserver:self selector:@selector(myTextViewDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
}

#pragma mark -键盘通知
- (void)keyboardWillShow:(NSNotification *)noti {
    self.currentViewController = [AVMTool currentViewController];
    if (![self findFirstResponder:self.currentViewController.view]) {
        self.currentViewController = nil;
    }else {
        CGRect keyboardFrame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        [self monitorKeyboardFrameChanged:keyboardFrame];
    }
}


- (void)keyboardDidHide:(NSNotification *)noti {
    self.currentViewController = nil;
    self.currentViewFrame      = CGRectZero;
    
}

- (void)keyboardWillChangeFrame:(NSNotification *)noti {
    CGRect keyboardFrame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self monitorKeyboardFrameChanged:keyboardFrame];
    
}

#pragma mark -输入框响应事件
//UITextField
- (void)myTextFieldDidBeginEditing:(NSNotification *)noti {
    UITextField *textField  = noti.object;
    
    self.firstResponderView = textField;
    
    [self monitorKeyboardFrameChanged:self.keyboardFrame];
}

- (void)myTextFieldDidEndEditing:(NSNotification *)noti {
//    UITextField *textField  = noti.object;
    self.firstResponderView = nil;
    
}

//UITextView
- (void)myTextViewDidBeginEditing:(NSNotification *)noti {
    UITextView *textView  = noti.object;
    self.firstResponderView = textView;
    
    [self monitorKeyboardFrameChanged:self.keyboardFrame];
}

- (void)myTextViewDidEndEditing:(NSNotification *)noti {
//    UITextView *textView    = noti.object;
    self.firstResponderView = nil;
    
}

- (void)monitorKeyboardFrameChanged:(CGRect)keyboardFrame {
    if (!self.avmAutoAdjustKeyboardHeight) {
        return;
    }
    //系统正在做侧滑是，不处理键盘信息
    if ([[self.currentViewController.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return;
    }
    self.keyboardFrame = keyboardFrame;
    if (self.firstResponderView && self.currentViewController) {
        CGRect textFrame = [self.firstResponderView.superview convertRect:self.firstResponderView.frame toView:[AVMTool mainWindow]];
        if (CGRectEqualToRect(self.currentViewFrame, CGRectZero)) {
            self.currentViewFrame = self.currentViewController.view.frame;
       }
        if (CGRectEqualToRect(self.currentViewFrame, self.currentViewController.view.frame)) {
            if (self.currentViewController.navigationController && textFrame.origin.y <= 64) {
                return;
            }else if(textFrame.origin.y <= 0) {
                return;
            }
        }
        CGFloat keyboardY = CGRectGetMinY(keyboardFrame) -10;
        
        CGRect selfTempFrame = self.currentViewController.view.frame;
        if (keyboardY < CGRectGetMaxY(textFrame)) {
            selfTempFrame.origin.y += (-(CGRectGetMaxY(textFrame) -keyboardY));
        }else if (keyboardFrame.origin.y < kScreenHeight && self.currentViewController.view.frame.origin.y < self.currentViewFrame.origin.y){
            selfTempFrame.origin.y += (-(CGRectGetMaxY(textFrame) -keyboardY));
        } else if( keyboardFrame.origin.y < kScreenHeight) {
            selfTempFrame = self.currentViewController.view.frame;
        }else {
            selfTempFrame = self.currentViewFrame;
        }
        if (selfTempFrame.origin.y > self.currentViewFrame.origin.y) {
            selfTempFrame = self.currentViewFrame;
        }
        
        if (!CGRectEqualToRect(self.currentViewController.view.frame, selfTempFrame) ) {
            self.currentViewController.view.frame = selfTempFrame;
            [self.currentViewController updateViewConstraints];
        }
    }
}

- (UIView *)findFirstResponder:(UIView *)needFindView
{
    if (needFindView.isFirstResponder) {
        return needFindView;
    }
    for (UIView *subView in needFindView.subviews) {
        UIView *firstResponder = [self findFirstResponder:subView];
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    return nil;
}

@end
