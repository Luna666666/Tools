//
//  ZFFullScreenViewController.m
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZFFullScreenViewController.h"
#import "ZFPlayer.h"

@interface ZFFullScreenViewController ()
@property (nonatomic, strong) UIImageView *bgImageView;

@end

@implementation ZFFullScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.bgImageView];
    self.bgImageView.center = CGPointMake(self.view.frame.size.height/2, self.view.frame.size.width/2);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 执行到这里就开始执行viewDidLoad了
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    //为了适配，当视频横屏->双击home ->点击空白区域返回 ->点击AVM -> “返回”按钮 界面错乱问题
////    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
//}


// 是否支持自动转屏
- (BOOL)shouldAutorotate {
    return YES;
}

// 支持哪些屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight);
}

// 默认的屏幕方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.orientation;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return ZFPlayerShared.isStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)setScreenshotImage:(UIImage *)screenshotImage{
    _screenshotImage = screenshotImage;
    self.bgImageView.image = screenshotImage;
}

- (void)setOrientation:(UIInterfaceOrientation)orientation {
    _orientation = orientation;
    if (orientation == UIInterfaceOrientationLandscapeRight) {
        self.bgImageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        self.bgImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }else {
        self.bgImageView.transform = CGAffineTransformIdentity;
    }
}


@end
