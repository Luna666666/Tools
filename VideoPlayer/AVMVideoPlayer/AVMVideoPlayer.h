//
//  AVMVideoPlayer.h
//  ZFPTest
//
//  Created by sunzongtang on 2017/6/8.
//  Copyright © 2017年 sunzongtang. All rights reserved.
//

/* 用法
 AVMVideoPlayerModel *playerModel = [AVMVideoPlayerModel new];
 playerModel.title = @"标题";
 playerModel.videoURL = @"https://video.uning.tv/56c13a6d-4c2d-42f5-9360-1e7353e6a9eb/film/36dbc7ff-d6cd-4e9b-8793-8908cd1714cd.mp4?s=52502834";
 AVMVideoPlayer *videoPlayer = [AVMVideoPlayer playerViewWithViewController:self superView:nil];
 videoPlayer.frame = CGRectMake(0, 200, 375, 200);
 videoPlayer.videoPlayerModel = playerModel;
 [videoPlayer initPlayer];
 self.videoPlayer = videoPlayer;
 */

#import <UIKit/UIKit.h>

@class AVMVideoPlayerModel;
@class ZFPlayerView;
@interface AVMVideoPlayer : NSObject

@property (nonatomic, assign,getter=isAutoPlay)BOOL autoPlay;
@property (nonatomic, assign,readonly, getter=isPlaying) BOOL playing;
@property (nonatomic, assign)CGRect frame;
@property (nonatomic, assign)BOOL showHD;
@property (nonatomic, strong)AVMVideoPlayerModel *avm_videoPlayerModel;


/**
 参数设置完在调用
 */
- (void)initPlayer;

/**
 *  自动播放，默认不自动播放 当不是自动播放时，调用此方法开始播放
 */
- (void)autoPlayTheVideo;

- (void)pause;
- (void)play;
- (void)resetToPlayNewVideo:(AVMVideoPlayerModel *)videoModel;

/**
 播放器初始化唯一方法 -

 @param viewController nil
 @param superView  播放器的superView
 @return <#return value description#>
 */
+(instancetype)playerViewWithViewController:(UIViewController *)viewController superView:(UIView *)superView;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark -在cell上播放用这个 多个
/* --需要view的tag >100
 AVMVideoPlayerModel *playerModel = [AVMVideoPlayerModel new];
 playerModel.title = cell.homePageViewCellModel.filmTitle;
 playerModel.videoURL = @"https://video.uning.tv/56c13a6d-4c2d-42f5-9360-1e7353e6a9eb/film/36dbc7ff-d6cd-4e9b-8793-8908cd1714cd.mp4?s=52502834";
 playerModel.scrollView = self.theTableView;
 playerModel.indexPath = [self.theTableView indexPathForCell:cell];
 playerModel.fatherViewTag = cell.theGoOnPlayShowView.tag;
 AVMCellVideoPlayer *videoPlayer = [AVMCellVideoPlayer new];
 videoPlayer.videoPlayerModel = playerModel;
 videoPlayer.fatherView = cell.theGoOnPlayShowView;
 [videoPlayer initPlayer];
 */
@interface AVMCellVideoPlayer : NSObject

@property (nonatomic, strong)AVMVideoPlayerModel *avm_videoPlayerModel;
@property (nonatomic, weak)UIView *fatherView;
@property (nonatomic, assign,getter=isAutoPlay)BOOL autoPlay;

/**
参数设置完在调用
*/
- (void)initPlayer;

/**
 *  自动播放，默认不自动播放 当不是自动播放时，调用此方法开始播放
 */
- (void)autoPlayTheVideo;

- (void)pause;
- (void)play;

@end

@interface AVMVideoPlayerModel : NSObject
/** 视频标题 */
@property (nonatomic, copy  ) NSString     *title;
/** 视频URL */
@property (nonatomic, strong) NSString        *videoURL;
/** 视频封面本地图片 */
@property (nonatomic, strong) UIImage      *placeholderImage;
/**
 * 视频封面网络图片url
 * 如果和本地图片同时设置，则忽略本地图片，显示网络图片
 */
@property (nonatomic, copy  ) NSString     *placeholderImageURLString;

@property (nonatomic, copy  ) NSString *videoTimeLength;

#pragma mark -视频广告
/**
 广告封面地址
 */
@property (nonatomic, copy) NSString *ADCoverImageUrl;
/**
 广告打开地址
 */
@property (nonatomic, copy) NSString *ADWebUrl;

// cell播放视频，以下属性必须设置值
@property (nonatomic, strong) UIScrollView *scrollView;
/** cell所在的indexPath */
@property (nonatomic, strong) NSIndexPath  *indexPath;
/**
 * cell上播放必须指定
 * 播放器View的父视图tag（根据tag值在cell里查找playerView加到哪里)
 */
@property (nonatomic, assign) NSInteger    fatherViewTag;
@end

