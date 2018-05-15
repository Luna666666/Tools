//
//  AVMShareViewController.h
//  AVM
//
//  Created by sunzongtang on 2017/6/17.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
// 分享

#import <UIKit/UIKit.h>

//extern NSString *kAVMShareVideoURL(NSString *filmId,NSInteger platform);

@interface AVMShareViewController : UIViewController

/**
 默认为YES
 */
@property (nonatomic, assign)BOOL showMeipai;
@property (nonatomic, assign)BOOL showAlipay;
@property (nonatomic, assign)BOOL showCopyLink;
@property (nonatomic, assign)BOOL needLogin; //是否需要登录 分享是否需要登录
@property (nonatomic, assign)BOOL isShareApp; //是分享APP 还是视频

@property (nonatomic, copy)NSString *filmId;

@property (nonatomic, copy) NSString *serverUpdateId;
@property (nonatomic, copy)NSString *playUrl; //美拍需要
@property (nonatomic, copy)NSString *shareTitle;
@property (nonatomic, copy)NSString *shareDes;

//从哪里分享的：1我的作品详情页面；2星场详细页面
@property (nonatomic, assign) NSInteger shareFilmFrom;

/**
 分享的链接
 */
@property (nonatomic, copy)NSString *shareUrl;

/**
 图片
 */
@property (nonatomic, strong)UIImage *shareImage;

/** shareImage  的网络地址  当shareImage为nil 是用之 */
@property (nonatomic, copy) NSString *shareImageUrl;

/**
 复制时需要的--
 */
@property (nonatomic, copy)NSString *shareCopyLink;

@property (nonatomic, copy)NSString *topTitle;

//界面消失时的回调，用于重新播放视频
@property (nonatomic, copy) void (^shareVCDidDisAppearBlock)(void);

- (void)show;
- (void)dismiss;

@end
