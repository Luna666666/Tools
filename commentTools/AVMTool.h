//
//  AVMTool.h
//  AVM
//
//  Created by sunzongtang on 2017/6/13.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AVMNavigationController.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "AVMFilePathManager.h"
#import "UIImageView+WebCache.h"

//给view添加阴影
extern void kAVMShadowView(UIView *view,UIColor *shadowColor,CGSize offset,CGFloat radius);
//服务器返回时长转成 分:秒 格式
extern NSString *kAVMFilmLenghtTransformToTime(id filmLength);

//把浮点数转成string
extern NSString *kAVMStringFromCGFloat(CGFloat tFloat);
extern NSString *kAVMStringFromNSInteger(NSInteger tInteger);

//判断一个浮点数对比

extern NSComparisonResult kAVMFloatSort(CGFloat f1, CGFloat f2);

extern UIImage *kFilmCoverDeaflutImage();


@class AVMNavigationController;
@class AVMFilmElementAdjustModel;
@class AVAssetTrack;
@interface AVMTool : NSObject

/**
 是否已经登录

 @return <#return value description#>
 */
+ (BOOL)isLogin;

/**
 第三方账号登录

 @return <#return value description#>
 */
+ (BOOL)isLoginByThirdPlatform;

/**
 是否是会员

 @return <#return value description#>
 */
+ (BOOL)isVIP;

+ (BOOL)needShowNotWIFINotice;

/** 颜色与字符串相互转换 */
+ (NSString *)changeColorToString:(UIColor *) textColor;
+ (UIColor *)getColorFromString:(NSString *)colorString;

+ (BOOL)isAutoPlayWIFI;
+ (void)setAutoPlayInWIFI:(BOOL)isAuto;

+ (UIWindow *)mainWindow;
+ (UIViewController *)rootViewController;

+ (AVMNavigationController *)createNewNavigationController:(UIViewController *)viewController;

#pragma mark -设置小米推送别名
+ (NSString *)miPushAlias;

#pragma mark -保存用户信息--
/** 保存一键制作相关信息 */
+ (void)saveCheckAppVerInstantMakeFilmInfo:(NSDictionary *)resultDict;
/** 保存用户信息*/
+ (void)saveGetUserAccountData:(NSDictionary *)resultDict;

#pragma mark -界面跳转相关
/** 跳转到登录界面 */
+ (void)presentLoginVC:(void (^)(BOOL isLoginSuccess)) loginSuccessBlock;

/** 跳转到作品列表界面 */
+ (void)pushToFilmListVC;

/** 跳转到草稿箱 */
+ (void)pushToFilmDraftVC;

/** 跳转到选择素材界面 */
+ (void)presentChooseElementVC:(void(^)(AVMFilmElementModel *filmElementModel ,NSError *error)) completion;

/** 跳转到素材编辑界面 */
+ (void)presentEditElementVC:(AVMFilmElementModel *)elementModel completion:(void(^)(AVMFilmElementModel *filmElementModel ,NSError *error))completion;

/** 跳转到素材裁剪*/
+ (void)presentCropPhotoVC:(AVMFilmElementModel *)elementModel
                  editType:(AVMEditPhotoVCEditType)editType
                completion:(void (^)(UIImage *resultImage, AVMFilmElementModel *filmElementModel)) completio;

/** 照做-跳到素材选择 */
+ (void)pushToChooseElementVC;

/** 照做- 根据filmJSON初始化 AVMMakeFilmManager （照做 -只保留数据的音乐和样式 ） */
+ (void)pushToChooseElemenetVCByCompliedFilmJSON:(NSString *)filmJSON filmId:(NSString *)filmId;

/** 设置素材缩放位置 */
+ (void)setElementImageView:(UIImageView *)imageView filmElement:(AVMFilmElementModel *)elementModel image:(UIImage *)image frame:(CGRect)frame;
/** 获取track的方向 */
+ (UIImageOrientation)caculateVideoTrackOrientation:(AVAssetTrack *)assetVideoTrack;
/** 根据adjust 裁剪cropsize大小图片  */
+ (UIImage *)clipImage:(UIImage *)originalImage adjust:(AVMFilmElementAdjustModel *)adjust cropSize:(CGSize) cropSize;

/** 保存裁剪后的封面图至沙盒 */
+ (void)saveFilmCoverImageToSanbox:(UIImage *)filmCoverImage isTemp:(BOOL)isTemp;

/** 检测图片是否包含二维码 */
+ (BOOL)checkImageIsQR:(UIImage *)image;

#pragma mark -判断对象是否为【NSNULL null】
+ (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

#pragma mark -路径拼接

/** 封面本地地址 */
+ (NSString *)filmCoverLocalImage:(NSString *)filmId;

/**
 获取素材本地路径

 @param filmElementId 素材ID
 @param suffix 后缀，jpg pnd mp4等
 @return <#return value description#>
 */
+ (NSString *)filmElementLocalPath:(NSString *)filmElementId suffix:(NSString *)suffix;

/**
 获取素材本地小图路径

 @param filmElementId <#filmElementId description#>
 @param suffix 后缀，jpg pnd mp4等
 @return <#return value description#>
 */
+ (NSString *)filmElementThumbnailLocalPath:(NSString *)filmElementId suffix:(NSString *)suffix;

#pragma mark -拼接HTML 地址
+ (NSString *)getHTMLUrlWithApiUrl:(NSString *)apiUrl;

#pragma mark -解析url参数
+ (NSDictionary *)analyzedURLParameter:(NSString *)urlString;

#pragma mark - Open url

/**
 打开网页

 @param url <#url description#>
 @param completionHandler <#completionHandler description#>
 */
+ (void)openURL:(NSURL *)url completionHandler:(void (^ _Nullable)(BOOL success))completionHandler;

#pragma mark -获取当前显示的控制器

/**
 获取app当前显示的控制器

 @return app当前显示的控制器
 */
+ (UIViewController *)currentViewController;

#pragma mark —返回毛玻璃View

/**
 毛玻璃View

 @return <#return value description#>
 */
+ (UIView *)blurView;


/**
 清空AVM本地文件
 */
+ (void)clearAVMFileData:(BOOL)deleteDB;

@end
