//
//  AVMShareViewController.m
//  AVM
//
//  Created by sunzongtang on 2017/6/17.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMShareViewController.h"

#import "AVMTool.h"
#import "AVMReachabilityManager.h"
#import "UIViewController+HUD.h"
#import "AVMSaveVideoToAlbumManager.h"
#import "AVMShareToMeipaiManager.h"
#import "AVMDownloadFilmManager.h"

#import "AVMMaskView.h"

#import <PureLayout/PureLayout.h>
#import <UShareUI/UShareUI.h>
#import <UMSocialCore/UMSocialCore.h>
#import <MPShareSDK/MPShareSDK.h>

typedef NS_ENUM(NSInteger, AVMSharePlatformType) {
    AVMSharePlatformType_Sina = UMSocialPlatformType_Sina,
    AVMSharePlatformType_QQ = UMSocialPlatformType_QQ,
    AVMSharePlatformType_Qzone = UMSocialPlatformType_Qzone,
    AVMSharePlatformType_AlipaySession = UMSocialPlatformType_AlipaySession,
    AVMSharePlatformType_WechatSeesion = UMSocialPlatformType_WechatSession,
    AVMSharePlatformType_WechatTimeLine = UMSocialPlatformType_WechatTimeLine, //朋友圈
    AVMSharePlatformType_MeiPai = 500, //分享到美拍
    AVMSharePlatformType_CopyLink = 501, //复制链接
};

typedef enum{
    shareFilmToSquare = 1,
    shareFilmToWeChat,
    shareFilmToFriend,
    shareFilmToQQ,
    shareFilmToQQZone,
    shareFilmToSinaWeibo,
    shareFilmCopyLink,
    shareDownLoadFilm,
    shareConnectToTv,
    shareFilmToAliPay = 15,
    shareFilmToMeiPai = 16
    
} shareFilmToType;

NSString *kAVMShareVideoURL(NSString *filmId,NSString *fromId,NSString *serverUpdateId) {
    //http://dev.avmer.net/avm_test/index.php?m=Home&c=Video&a=index
    NSString *shareUrl = [NSString stringWithFormat:@"%@/%@/index.php?m=Home&c=Video&a=index&%@&filmId=%%@&suid=%%@",REQUEST_API_HOST,REQUEST_API_PARAM,[NSString stringWithFormat:@"APPCH=%@",REQUEST_APP_CH]];
    shareUrl = [NSString stringWithFormat:shareUrl,filmId,serverUpdateId];
    return shareUrl;
}

#pragma mark --AVMShareModel
@interface AVMShareModel : NSObject

@property (nonatomic, assign)AVMSharePlatformType sharePlatformType;
@property (nonatomic, copy)NSString *image;
@property (nonatomic, copy)NSString *title;

@end

@implementation AVMShareModel


@end

#pragma mark -AVMShareButton

@interface AVMShareButton : UIButton

@property (nonatomic, assign)AVMSharePlatformType sharePlatformType;

@end

@implementation AVMShareButton

//#error 计算-image位置 --分享

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGRect tRect = [super imageRectForContentRect:contentRect];
    
    CGFloat width = CGRectGetWidth(tRect);
    CGFloat x = (CGRectGetWidth(contentRect) - width)/2.0;
    return CGRectMake(x, 0, width, width);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGRect tRect = [super titleRectForContentRect:contentRect];
    CGFloat tHeight = CGRectGetHeight(tRect);
    CGFloat width = CGRectGetWidth(contentRect);
    CGFloat height = CGRectGetHeight(contentRect);
    return CGRectMake(0, height -tHeight, width, tHeight);
}
@end

@interface AVMShareViewController ()

@property (nonatomic, strong) CALayer *theBackgroundLayer;

@property (nonatomic, strong)UIView *theContainerView;
@property (nonatomic, strong)UILabel *theTopTitleLabel;
@property (nonatomic, strong)UIView *theTopLineView;
@property (nonatomic, strong)UIView *theOperationView;
@property (nonatomic, strong)UIButton *theCancelButton;

@property (nonatomic, strong)AVMMaskView *maskView;

@property (nonatomic, assign)AVMSharePlatformType sharePlatformType;

@property (nonatomic, strong) UIWindow *shareWindow;

@end

@implementation AVMShareViewController

- (void)dealloc {
    kNSLog_dealloc_class;
}

- (instancetype)init {
    if (self = [super init]) {
        self.showMeipai = YES;
        self.showAlipay = YES;
        self.showCopyLink = YES;
        self.needLogin = YES;
        self.isShareApp = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    [self.view.layer addSublayer:self.theBackgroundLayer];
    [self.view addSubview:self.theContainerView];
    
    
    
    
    [self.theContainerView addSubview:self.theTopTitleLabel];
    [self.theContainerView addSubview:self.theOperationView];
    [self.theContainerView addSubview:self.theCancelButton];
    [self.theContainerView addSubview:self.theTopLineView];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self.view addGestureRecognizer:tapGes];
    
    
    if (!kStringIsEmpty(self.topTitle)) {
        self.theTopTitleLabel.text = self.topTitle;
    }
    
    [self setupOpertaionUI];
    [self configConstaints];
    
    self.view.userInteractionEnabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.userInteractionEnabled = YES;
    });
}

- (void)setupOpertaionUI {
    NSMutableArray<AVMShareModel *> *models = [NSMutableArray array];
    UMSocialManager *socialManager = [UMSocialManager defaultManager];
    
    if ([socialManager isInstall:UMSocialPlatformType_WechatSession]) {
        AVMShareModel *model = [AVMShareModel new];
        model.title = @"微信好友";
        model.image = @"app_icon_weixing";
        model.sharePlatformType = AVMSharePlatformType_WechatSeesion;
        [models addObject:model];
        
        AVMShareModel *model1 = [AVMShareModel new];
        model1.title = @"微信朋友圈";
        model1.image = @"app_icon_pengyouquan";
        model1.sharePlatformType = AVMSharePlatformType_WechatTimeLine;
        [models addObject:model1];
    }
    
    if ([socialManager isInstall:UMSocialPlatformType_QQ]) {
        AVMShareModel *model = [AVMShareModel new];
        model.title = @"手机QQ";
        model.image = @"app_icon_qq";
        model.sharePlatformType = AVMSharePlatformType_QQ;
        [models addObject:model];
        
        AVMShareModel *model1 = [AVMShareModel new];
        model1.title = @"QQ空间";
        model1.image = @"app_icon_qq kongjian";
        model1.sharePlatformType = AVMSharePlatformType_Qzone;
        [models addObject:model1];
    }
    
    AVMShareModel *model = [AVMShareModel new];
    model.title = @"新浪微博";
    model.image = @"app_icon_weibo";
    model.sharePlatformType = AVMSharePlatformType_Sina;
    [models addObject:model];
    
    if (self.showMeipai) {
        if ([MPShareSDK isMeipaiInstalled]) {
            AVMShareModel *model1 = [AVMShareModel new];
            model1.title = @"美拍";
            model1.image = @"app_icon_meipai";
            model1.sharePlatformType = AVMSharePlatformType_MeiPai;
            [models addObject:model1];
        }
    }
    
    //支付宝
    if (self.showAlipay) {
        if ([socialManager isInstall:UMSocialPlatformType_AlipaySession]) {
            AVMShareModel *model = [AVMShareModel new];
            model.title = @"支付宝好友";
            model.image = @"app_icon_zhifubao";
            model.sharePlatformType = AVMSharePlatformType_AlipaySession;
            [models addObject:model];
        }
    }
    
    if (self.showCopyLink) {
        AVMShareModel *model = [AVMShareModel new];
        model.title = @"复制链接";
        model.image = @"app_icon_copylink";
        model.sharePlatformType = AVMSharePlatformType_CopyLink;
        [models addObject:model];
    }
    
    [models enumerateObjectsUsingBlock:^(AVMShareModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVMShareButton *button = [AVMShareButton buttonWithType:UIButtonTypeCustom];
        button.sharePlatformType = obj.sharePlatformType;
        button.titleLabel.font =kSystemFont(10);
        [button setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:obj.image] forState:UIControlStateNormal];
        [button setTitle:obj.title forState:UIControlStateNormal];
        [button addTarget:self action:@selector(shareButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.theOperationView addSubview:button];
    }];
    
    //计算位置 top 15  bottom 21.5 left 6 right 6
    
    CGFloat width = (kScreenWidth - 6 * 2 )/5.0;
    CGFloat height = 60;
    CGFloat lineSpace = 15;
    
    //每行5个
    [self.theOperationView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger row = idx/ 5;
        NSInteger column = idx % 5;
        obj.frame = CGRectMake(column * width + 6, 15 + row *height + row * lineSpace, width, height);
    }];
    NSInteger row = models.count / (5 +1) + 1;
    
    [self.theOperationView autoSetDimension:ALDimensionHeight toSize:(15 + 21.5 + row * height + (models.count / (5 +1)) * lineSpace)];
}

- (void)configConstaints {
    [self.theContainerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.theContainerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.theContainerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self.theTopTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.theTopTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:12];
    [self.theTopTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:12];
    [self.theTopTitleLabel autoSetDimension:ALDimensionHeight toSize:37];
    
    [self.theTopLineView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:9.];
    [self.theTopLineView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.theTopLineView autoSetDimension:ALDimensionHeight toSize:0.5];
    [self.theTopLineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.theTopTitleLabel];
    
    [self.theOperationView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.theOperationView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.theOperationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.theTopTitleLabel];
    [self.theOperationView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.theCancelButton];
    
    [self.theCancelButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.theCancelButton autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.theCancelButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.theCancelButton autoSetDimension:ALDimensionHeight toSize:44];
    
}


#pragma mark -public method
- (void)show {
    UIWindow *shareWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    shareWindow.backgroundColor = [UIColor clearColor];
    shareWindow.rootViewController = self;
    shareWindow.windowLevel = UIWindowLevelAlert + 1;
    shareWindow.hidden = NO;
    self.shareWindow = shareWindow;
    
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"position.y"];
    animation.fromValue = @(kScreenHeight);
    animation.duration = 0.15;
    animation.autoreverses = NO;
    animation.repeatCount = 1;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    
    [self.theContainerView.layer addAnimation:animation forKey:@"animation"];
    
    CABasicAnimation *animation_b = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation_b.fromValue = @(0);
    animation_b.toValue = @(1);
    animation_b.duration = 0.15;
    animation_b.autoreverses = NO;
    animation_b.removedOnCompletion = NO;
    
    [self.theBackgroundLayer addAnimation:animation_b forKey:@"opacity"];

}

- (void)dismiss {
    [self dismissCallBlock:nil];
}

- (void)dismissCallBlock:(void (^)()) completion {
    [UIView animateWithDuration:0.15 animations:^{
        
        self.theContainerView.layer.transform = CATransform3DMakeTranslation(1,CGRectGetHeight(self.theContainerView.frame),1);
        self.theBackgroundLayer.opacity = 0.1;
        
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.shareWindow removeFromSuperview];
            self.shareWindow = nil;
            
            if (!completion && self.shareVCDidDisAppearBlock) {
                self.shareVCDidDisAppearBlock();
            }
        });
    }];
}

#pragma mark -property method
- (CALayer *)theBackgroundLayer {
    if (!_theBackgroundLayer) {
        _theBackgroundLayer = [CALayer layer];
        _theBackgroundLayer.frame = [UIScreen mainScreen].bounds;
        _theBackgroundLayer.backgroundColor = kColorWithRGBA(0, 0, 0, 0.35).CGColor;
    }
    return _theBackgroundLayer;
}

- (UIView *)theContainerView {
    if (!_theContainerView) {
        _theContainerView = [[UIView alloc] init];
        _theContainerView.backgroundColor = kThemeBackgroundColor;
        _theContainerView.clipsToBounds = YES;
        _theContainerView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
        [_theContainerView addGestureRecognizer:tapGes];
    }
    return _theContainerView;
}

- (UILabel *)theTopTitleLabel {
    if (!_theTopTitleLabel) {
        _theTopTitleLabel = [UILabel new];
        _theTopTitleLabel.textColor = kColorWithHex(0x666666);
        _theTopTitleLabel.font = kSystemFont(12);
        _theTopTitleLabel.text = @"分享至";
    }
    return _theTopTitleLabel;
}

- (UIView *)theTopLineView {
    if (!_theTopLineView) {
        _theTopLineView = [UIView new];
        _theTopLineView.backgroundColor = kSeparatorLineColor_979797;
    }
    return _theTopLineView;
}

- (UIView *)theOperationView {
    if (!_theOperationView) {
        _theOperationView = [UIView new];
        _theOperationView.backgroundColor = kColorWithHex(0xf6f6f6);
    }
    return _theOperationView;
}

- (UIButton *)theCancelButton {
    if (!_theCancelButton) {
        _theCancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_theCancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_theCancelButton setTitleColor:kTextColor_333333 forState:UIControlStateNormal];
        _theCancelButton.backgroundColor = [UIColor whiteColor];
        _theCancelButton.titleLabel.font = kSystemFont(14);
        [_theCancelButton addTarget:self action:@selector(canceButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _theCancelButton;
}


#pragma mark -private method


- (void)canceButtonOnClick:(UIButton *)sender {
    [self dismiss];
}

#pragma mark -分享响应 action

- (void)shareButtonOnClick:(AVMShareButton *)sender {
    if (![AVMReachabilityManager shareManager].isAvm_reachable) {
        [self showHint:@"当前网络不好，请稍后再试"];
        return;
    }
    
    [self dismissCallBlock:^{
//        if (self.needLogin) {
//            if (![AVMTool isLogin]) {
//                alertTipsString(@"AVM视频需登录后才能分享");
//                return;
//            }
//        }
        
        self.sharePlatformType = sender.sharePlatformType;
        switch (sender.sharePlatformType) {
            case AVMSharePlatformType_WechatSeesion:
                [self shareToWeixin];
                break;
            case AVMSharePlatformType_WechatTimeLine:
                [self shareToWeixin_pengyou];
                break;
            case AVMSharePlatformType_QQ:
                [self shareToQQ];
                break;
            case AVMSharePlatformType_Qzone:
                [self shareToQQZone];
                break;
            case AVMSharePlatformType_Sina:
                [self shareToSina];
                break;
            case AVMSharePlatformType_MeiPai:
                [self shareToMeipai];
                break;
            case AVMSharePlatformType_AlipaySession:
                [self shareToAlipay];
                break;
            case AVMSharePlatformType_CopyLink:
                [self shareToCopy];
                break;
            default:
                break;
        }
    }];
}

- (void)shareToWeixin {
    if (self.isShareApp) {
        [self shareAPP];
        return;
    }
    self.shareUrl = kAVMShareVideoURL(self.filmId,@"2",self.serverUpdateId);
    [self shareVideo:shareFilmToWeChat];
}

- (void)shareToWeixin_pengyou {
    if (self.isShareApp) {
        [self shareAPP];
        return;
    }
    self.shareUrl = kAVMShareVideoURL(self.filmId,@"3",self.serverUpdateId);
    [self shareVideo:shareFilmToFriend];
}

- (void)shareToQQ {
    if (self.isShareApp) {
        [self shareAPP];
        return;
    }
    self.shareUrl = kAVMShareVideoURL(self.filmId,@"4",self.serverUpdateId);
    [self shareVideo:shareFilmToQQ];
}

- (void)shareToQQZone {
    if (self.isShareApp) {
        [self shareAPP];
        return;
    }
    self.shareUrl = kAVMShareVideoURL(self.filmId,@"5",self.serverUpdateId);
    [self shareVideo:shareFilmToQQZone];
}

- (void)shareToSina {
    if (self.isShareApp) {
        [self shareAPP];
        return;
    }
    self.shareUrl = kAVMShareVideoURL(self.filmId,@"6",self.serverUpdateId);
    [self shareVideo:shareFilmToSinaWeibo];
}

- (void)shareToMeipai {
    kWEAKSELF;
    self.maskView = [AVMMaskView loadFromXib];
    [self.maskView showInView:self.view backgroundColor:kColorWithRGBA(0, 0, 0, 0.2) delay:0.3];
    
    [[AVMDownloadFilmManager sharedDownloadFilmManger] downloadFilm:self.filmId filmUrl:self.playUrl downloadProgress:nil completionHandler:^(NSInteger statusCode, NSString *msg, NSString *localFilmUrl, NSError *error) {
        if (localFilmUrl) {
            [weakSelf shareToMeipai:localFilmUrl];
        }else {
            [weakSelf.maskView hide];
            [weakSelf showHint:@"分享失败，请稍后重试" hide:2.f];
        }
    }];
}

- (void)shareToAlipay {
    if (self.isShareApp) {
        [self shareAPP];
        return;
    }
    self.shareUrl = kAVMShareVideoURL(self.filmId,@"15",self.serverUpdateId);
    [self shareVideo:shareFilmToAliPay];
}

- (void)shareToCopy {
    self.shareCopyLink = kAVMShareVideoURL(self.filmId,@"7",self.serverUpdateId);
    [self shareFilmRecordLogToService:shareFilmCopyLink];
    if (kStringIsEmpty(self.shareCopyLink)) {
        [self showHint:@"复制失败"];
        return;
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.shareCopyLink;
    
    [self showHint:@"已复制到剪切板"];
    
}

- (void)shareVideo:(NSInteger)platformType {
    //创建分享消息对象
    UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
    id shareImage = nil;
    if (!self.shareImage) {
        shareImage = self.shareImageUrl;
    }else {
        shareImage = [UMSocialImageUtil scaleImage:self.shareImage ToSize:CGSizeMake(300, 300)];
    }
    if (kStringIsEmpty(self.shareTitle)) {
        self.shareTitle = @"AVM视频";
    }
    if (kStringIsEmpty(self.shareDes)) {
        self.shareDes = kShareContent;
    }
    
    UMShareObject *shareObject = nil;

    if (self.sharePlatformType == AVMSharePlatformType_Sina) {
        shareObject = [UMShareImageObject shareObjectWithTitle:@"" descr:@"" thumImage:shareImage];
        [(UMShareImageObject *)shareObject setShareImage:shareImage];
        messageObject.text = [NSString stringWithFormat:@"%@%@",self.shareTitle,self.shareUrl];
    }else {
        //创建视频内容对象
        shareObject = [UMShareVideoObject shareObjectWithTitle:self.shareTitle descr:self.shareDes thumImage:shareImage];
        
        shareObject.descr = @"　";  //空格为 ‘全角’ 输入法下的空格
    

        //设置视频网页播放地址
        [(UMShareVideoObject *)shareObject setVideoUrl:self.shareUrl];
    }
    
    //分享消息对象设置分享内容对象
    messageObject.shareObject = shareObject;
    //调用分享接口
    kWEAKSELF;
    [[UMSocialManager defaultManager] shareToPlatform:(UMSocialPlatformType)self.sharePlatformType messageObject:messageObject currentViewController:self completion:^(id data, NSError *error) {
        if (error) {
            NSLog(@"************Share fail with error %@*********",error);
            [weakSelf showHint:@"分享失败"];
        }else{
            NSLog(@"response data is %@",data);
        }
    }];
    
    [self shareFilmRecordLogToService:platformType];
}

- (void)shareAPP {
    //创建分享消息对象
    UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
    
    self.shareImage = kShareIcon;
    
    if (kStringIsEmpty(self.shareTitle)) {
        self.shareTitle = @"AVM";
    }
    if (kStringIsEmpty(self.shareDes)) {
        self.shareDes = kShareContent;
    }
    if (self.sharePlatformType == AVMSharePlatformType_WechatTimeLine) {
        self.shareTitle = [NSString stringWithFormat:@"%@\n%@",self.shareTitle,kShareContent];
    }
    
    UMShareObject *shareObject = nil;
    if (self.sharePlatformType == AVMSharePlatformType_Sina) {
        shareObject = [UMShareImageObject shareObjectWithTitle:@"" descr:@"" thumImage:self.shareImage];
        [(UMShareImageObject *)shareObject setShareImage:self.shareImage];
        messageObject.text = [NSString stringWithFormat:@"%@%@",self.shareDes,self.shareUrl];
    }else {
        //创建网页内容对象
        shareObject = [UMShareWebpageObject shareObjectWithTitle:self.shareTitle descr:self.shareDes thumImage:self.shareImage];
        //设置网页地址
        [(UMShareWebpageObject *)shareObject setWebpageUrl:self.shareUrl];
    }
    
    //分享消息对象设置分享内容对象
    messageObject.shareObject = shareObject;
    
    //调用分享接口
    kWEAKSELF;
    [[UMSocialManager defaultManager] shareToPlatform:(UMSocialPlatformType)self.sharePlatformType messageObject:messageObject currentViewController:self completion:^(id data, NSError *error) {
        if (error) {
            NSLog(@"************Share fail with error %@*********",error);
            [weakSelf showHint:@"分享失败"];
        }else{
            NSLog(@"response data is %@",data);
        }
    }];
}

- (void)shareToMeipai:(NSString *)filmUrl {
    kWEAKSELF;
    [AVMSaveVideoToAlbumManager SaveVideoToAlbumWithVideoUrl:[NSURL fileURLWithPath:filmUrl] Sussess:^(NSURL *albutmUrl){
        [[AVMShareToMeipaiManager shareManager] shareToMeipai:albutmUrl compliteBlock:^(BOOL isSuc, NSError *error) {
            [weakSelf.maskView hide];
            if (isSuc) {
                [weakSelf showHint:@"分享成功"];
            }else {
                [weakSelf showHint:@"分享失败"];
            }
        }];
    } Fail:^(BOOL hasNoAuth) {
        [weakSelf.maskView hide];
    }];
}

- (void)shareFilmRecordLogToService:(NSInteger)platformType {
    NSDictionary *params = @{@"filmId":self.filmId,
                             @"shareType":@(platformType),
                             @"from":@(self.shareFilmFrom)};
    [AVMRequestManager mf_shareFilmParamDict:params showHUDInView:nil success:^(NSDictionary *resultDict, NSInteger code, NSString *msg) {
        
    } failure:^(NSError *error) {
        
    }];
}

@end
