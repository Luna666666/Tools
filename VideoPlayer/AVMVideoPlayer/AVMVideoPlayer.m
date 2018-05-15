//
//  AVMVideoPlayer.m
//  ZFPTest
//
//  Created by sunzongtang on 2017/6/8.
//  Copyright © 2017年 sunzongtang. All rights reserved.
//

#import "AVMVideoPlayer.h"

#import "ZFPlayer.h"

#import "AVMVideoPlayerControl.h"

#pragma mark -AVMVideoPlayer

@interface AVMVideoPlayer ()

@property (nonatomic, weak)UIViewController *viewController;
@property (nonatomic, weak)UIView *superView;

@property (nonatomic, strong)ZFPlayerView *playerView;
@property (nonatomic, strong)ZFPlayerModel *zf_playerModel;

@property (nonatomic, weak)AVMVideoPlayerControl *controlView;

@end
@implementation AVMVideoPlayer
- (void)dealloc {
    NSLog(@"-----delloc ---AVMVideoPlayer--");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.avm_videoPlayerModel = nil;
    [self.playerView pause];
    self.zf_playerModel = nil;
    self.playerView.delegate = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

+ (instancetype)playerViewWithViewController:(UIViewController *)viewController superView:(UIView *)superView {
    NSAssert(superView != nil, @"superView can't nil");
    
    AVMVideoPlayer *videoPlayer = [AVMVideoPlayer new];
    videoPlayer.viewController = viewController;
    videoPlayer.superView = superView;
    videoPlayer.autoPlay = YES;
    return videoPlayer;
}

- (BOOL)isPlaying {
    return !self.playerView.isPauseByUser;
}

- (void)setShowHD:(BOOL)showHD {
    _showHD = showHD;
    [self.controlView showHD:showHD];
}

- (void)initPlayer {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needLoginNotificaion:) name:kAVMNeedLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needLoginNotificaion:) name:kAVMWebCallAVMNotification object:nil];
    [self setupPlayer];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)needLoginNotificaion:(NSNotification *)noti {
    [self pause];
    if (ZFPlayerShared.isLandscape) {
        ZFPlayerShared.isLockScreen = NO;
        [self.playerView zf_controlView:nil fullScreenAction:nil];
    }
}


- (void)autoPlayTheVideo {
    if (self.autoPlay) {
        
    }else {
        self.controlView.hasPlay = YES;
        [self.playerView autoPlayTheVideo];
    }
}

- (void)pause {
    if (self.playerView && !self.playerView.isPauseByUser) {
        [self.playerView pause];
    }
}

- (void)play {
    if (self.playerView && self.playerView.isPauseByUser) {
        [self.playerView play];
    }
}

- (void)resetToPlayNewVideo:(AVMVideoPlayerModel *)videoModel {
    self.avm_videoPlayerModel = videoModel;
    [self changeVideoPlayerModelToZFVideoModel:videoModel];
    [self.playerView resetToPlayNewVideo:self.zf_playerModel];
}


#pragma mark -private method
- (void)setupPlayer {
    AVMVideoPlayerControl *controlView = [[AVMVideoPlayerControl alloc] init];
    [controlView showHD:self.showHD];
    // 初始化播放模型
    
    _zf_playerModel = [[ZFPlayerModel alloc] init];
    // playerView的父视图
    _zf_playerModel.fatherView = self.superView;
    [self changeVideoPlayerModelToZFVideoModel:self.avm_videoPlayerModel];
    
    _playerView = [[ZFPlayerView alloc] init];
    
    [controlView showVideoTimeLength:self.avm_videoPlayerModel.videoTimeLength];
    [self.playerView playerControlView:controlView playerModel:self.zf_playerModel];
    controlView.playerView = _playerView;
    self.controlView = controlView;
    //    self.playerView.delegate = self;
    if (self.isAutoPlay) {
        // 自动播放
        self.controlView.hasPlay = YES;
        [self.playerView autoPlayTheVideo];
    }
    self.playerView.hasPreviewView = NO;

}

- (void)changeVideoPlayerModelToZFVideoModel:(AVMVideoPlayerModel *)videoModel {
    
    _zf_playerModel.title = videoModel.title;
    if ([videoModel.videoURL hasPrefix:@"http"]) {
        _zf_playerModel.videoURL = [NSURL URLWithString:videoModel.videoURL];
    }else {
        _zf_playerModel.videoURL = [NSURL fileURLWithPath:videoModel.videoURL];
    }
    _zf_playerModel.placeholderImage = videoModel.placeholderImage;
    _zf_playerModel.placeholderImageURLString = videoModel.placeholderImageURLString;
    
    _zf_playerModel.ADCoverImageUrl = videoModel.ADCoverImageUrl;
    _zf_playerModel.ADWebUrl        = videoModel.ADWebUrl;
}

@end

@interface AVMCellVideoPlayer ()

@property (nonatomic, strong)ZFPlayerModel *zf_playerModel;
@property (nonatomic, strong) ZFPlayerView        *playerView;

@property (nonatomic, weak)AVMVideoPlayerControl *controlView;

@end
@implementation AVMCellVideoPlayer

- (void)dealloc {
    NSLog(@"-----delloc ---AVMCellVideoPlayer--");
    [self.playerView pause];
    self.zf_playerModel = nil;
    self.playerView.delegate = nil;
    self.playerView = nil;
    self.avm_videoPlayerModel = nil;
    self.fatherView = nil;
}
- (instancetype)init {
    if (self = [super init]) {
        self.autoPlay = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needLoginNotificaion:) name:kAVMNeedLoginNotification object:nil];
    }
    return self;
}

- (void)needLoginNotificaion:(NSNotification *)noti {
    [self pause];
    if (ZFPlayerShared.isLandscape) {
        ZFPlayerShared.isLockScreen = NO;
        [self.playerView zf_controlView:nil fullScreenAction:nil];
    }
}

- (ZFPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [ZFPlayerView sharedPlayerView];
//        _playerView.delegate = self;
        // 当cell播放视频由全屏变为小屏时候，不回到中间位置
        _playerView.cellPlayerOnCenter = NO;
        
        // 当cell划出屏幕的时候停止播放
        // _playerView.stopPlayWhileCellNotVisable = YES;
        //（可选设置）可以设置视频的填充模式，默认为（等比例填充，直到一个维度到达区域边界）
        // _playerView.playerLayerGravity = ZFPlayerLayerGravityResizeAspect;
        // 静音
        // _playerView.mute = YES;
    }
    return _playerView;
}

- (void)initPlayer {
    NSAssert(self.avm_videoPlayerModel != nil, @"--videoPlayerModel can't nil");
    
    [self setupPlayer];
}

- (void)autoPlayTheVideo {
    if (self.autoPlay) {
        
    }else {
        self.controlView.hasPlay = YES;
        [self.playerView autoPlayTheVideo];
    }
}

- (void)pause {
    if (self.playerView && !self.playerView.isPauseByUser) {
        [self.playerView pause];
    }
}

- (void)play {
    if (self.playerView && self.playerView.isPauseByUser) {
        [self.playerView play];
    }
}

- (void)setupPlayer {
    AVMVideoPlayerControl *controlView = [[AVMVideoPlayerControl alloc] init];
    // 初始化播放模型
    _zf_playerModel = [[ZFPlayerModel alloc] init];
    // playerView的父视图
    _zf_playerModel.fatherView = self.fatherView;
    _zf_playerModel.title = self.avm_videoPlayerModel.title;
    _zf_playerModel.videoURL = [NSURL URLWithString:self.avm_videoPlayerModel.videoURL];
    _zf_playerModel.placeholderImage = self.avm_videoPlayerModel.placeholderImage;
    _zf_playerModel.placeholderImageURLString = self.avm_videoPlayerModel.placeholderImageURLString;
    _zf_playerModel.scrollView = self.avm_videoPlayerModel.scrollView;
    _zf_playerModel.indexPath = self.avm_videoPlayerModel.indexPath;
    _zf_playerModel.fatherViewTag = self.avm_videoPlayerModel.fatherViewTag;
    
    [self.playerView playerControlView:controlView playerModel:self.zf_playerModel];
    controlView.playerView = _playerView;
    self.controlView = controlView;
    if (self.isAutoPlay) {
        // 自动播放
        self.controlView.hasPlay = YES;
        [self.playerView autoPlayTheVideo];
    }
    self.playerView.hasPreviewView = YES;
}

@end

@implementation AVMVideoPlayerModel


@end
