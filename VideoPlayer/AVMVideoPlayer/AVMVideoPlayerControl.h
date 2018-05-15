//
//  AVMVideoPlayerControl.h
//  ZFPTest
//
//  Created by sunzongtang on 2017/6/8.
//  Copyright © 2017年 sunzongtang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASValueTrackingSlider.h"
#import "ZFPlayer.h"
#import "ZFPlayerControlViewDelegate.h"

@interface AVMVideoPlayerControl : UIView

@property (nonatomic, weak)ZFPlayerView *playerView;
@property (nonatomic, weak) id<ZFPlayerControlViewDelagate> delegate;

@property (nonatomic, assign)BOOL hasPlay;

/** 是否是全屏 */
@property (nonatomic, assign, readonly) BOOL isFull;

- (void)showHD:(BOOL)hd;

- (void)showVideoTimeLength:(NSString *)length;

@end

