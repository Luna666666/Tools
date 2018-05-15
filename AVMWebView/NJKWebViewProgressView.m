//
//  NJKWebViewProgressView.m
//
//  Created by Satoshi Aasanoon 11/16/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import "NJKWebViewProgressView.h"

@interface NJKWebViewProgressView ()<CAAnimationDelegate>

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CALayer         *mask;

@property (nonatomic, assign) BOOL showProgress;

@end

@implementation NJKWebViewProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureViews];
    }
    return self;
}

-(void)configureViews
{
    self.userInteractionEnabled = NO;
    _barAnimationDuration = 0.27f;
    _fadeAnimationDuration = 0.27f;
    _fadeOutDelay = 0.27f;
    [self initGradientLayer];
}

-(void)setProgress:(float)progress
{
    [self setProgress:progress animated:YES];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    BOOL isGrowing = progress > 0.0;
    [UIView animateWithDuration:(isGrowing && animated) ? _barAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGFloat maskWidth = progress * CGRectGetWidth(self.frame);
        self.mask.frame = CGRectMake(0, 0, maskWidth, CGRectGetHeight(self.frame));
    } completion:^(BOOL finished) {
        if (progress >= 1.0) {
            if (!self.gradientLayer.hidden || self.showProgress) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                [self performSelector:@selector(showGradientLayer:) withObject:@(NO) afterDelay:_fadeOutDelay];
            }
        }
        else {
            if (!self.showProgress) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                [self performSelector:@selector(showGradientLayer:) withObject:@(YES) afterDelay:0.1];
                self.showProgress = YES;
            }
        }
    }];
}

- (void)showGradientLayer:(id) show {
    self.gradientLayer.hidden = ![show boolValue];
    self.showProgress         = [show boolValue];
}
- (CABasicAnimation *)opacityAnimationToValue:(CGFloat)value {
    CABasicAnimation *opAn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opAn.toValue  = @(value);
    opAn.duration = _fadeAnimationDuration;
    opAn.removedOnCompletion = NO;
    opAn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    opAn.delegate = self;
    return opAn;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[(CABasicAnimation *)anim toValue] floatValue] == 1) {
        self.gradientLayer.opacity = 1;
    }else {
        self.gradientLayer.opacity = 0;
    }
}

- (void)initGradientLayer
{
    if (self.gradientLayer == nil) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.frame = self.bounds;
    }
    self.gradientLayer.startPoint = CGPointMake(0, 0.5);
    self.gradientLayer.endPoint   = CGPointMake(1, 0.5);
    
    //create colors, important section
    NSMutableArray *colors = [NSMutableArray array];
//    for (NSInteger deg = 0; deg <= 360; deg += 5) {
//        
//        UIColor *color;
//        color = [UIColor colorWithHue:1.0 * deg / 360.0
//                           saturation:1.0
//                           brightness:1.0
//                                alpha:1.0];
//        [colors addObject:(id)[color CGColor]];
//    }
    [colors addObject:(id)[UIColor greenColor].CGColor];
    [colors addObject:(id)[UIColor blueColor].CGColor];
    [self.gradientLayer setColors:[NSArray arrayWithArray:colors]];
    self.mask = [CALayer layer];
    [self.mask setFrame:CGRectMake(self.gradientLayer.frame.origin.x,
                                   self.gradientLayer.frame.origin.y,
                                   self.progress * CGRectGetWidth(self.frame),
                                   CGRectGetHeight(self.frame))];
    self.mask.borderColor = [[UIColor blueColor] CGColor];
    self.mask.borderWidth = 2;
    [self.gradientLayer setMask:self.mask];
    [self.layer addSublayer:self.gradientLayer];
}

@end
