//
//  AVMTool.m
//  AVM
//
//  Created by sunzongtang on 2017/6/13.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMTool.h"
#import "AppDelegate+AVMFileManager.h"

#import "AVMUserInfoModel.h"
#import "AVMRequestBaseModel.h"
#import "UIImage+YYAdd.h"
#import "UIColor+YYAdd.h"
#import "UIImage+Resize.h"

#import "AVMChooseElementViewController.h"
#import "AVMMakeFilmEditVideoViewController.h"
#import "AVMMakeFilmEditImageViewController.h"
#import "AVMEditPhotoViewController.h"
#import "AVMLoginViewController.h"
#import "AVMMineSettingViewController.h"
#import "AVMMineFilmListViewController.h"
#import "AppDelegate.h"

#import "AVMFilePathManager.h"
#import "AVMMakeFilmManager.h"
#import "WYLJsonUtils.h"
#import "AVMCompressImageUtil.h"

#import "AVMDBManager.h"
#import "AVMFilmElementModel.h"
#import "AVMMineFilmMakingProgressManager.h"
#import "AVMSyncService.h"

#import <YYModel/YYModel.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

#pragma mark -阴影
void kAVMShadowView(UIView *view,UIColor *shadowColor,CGSize offset,CGFloat radius) {
    view.layer.shadowColor = shadowColor.CGColor;
    view.layer.shadowOffset = offset;
    view.layer.shadowRadius = radius;
    view.layer.shadowOpacity = 0.8;
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    view.clipsToBounds = NO;
}

NSString *kAVMFilmLenghtTransformToTime(id filmLength) {
    NSInteger filmTimeLength = 0;
    if ([filmLength isKindOfClass:[NSString class]]) {
        if (((NSString *)filmLength).length == 0) {
            return @"00:00";
        }
    }
    if ([filmLength respondsToSelector:@selector(floatValue)]) {
        filmTimeLength = ceil([filmLength floatValue]);
    }else {
        if ([filmLength isKindOfClass:[NSNumber class]]) {
            filmTimeLength = ceil(((NSNumber *)filmLength).floatValue);
        }
    }
    if (filmTimeLength < 0) {
        filmTimeLength = 0;
    }
    
    NSInteger sec = filmTimeLength % 60;
    NSInteger min = filmTimeLength / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld",min,sec];
}

NSString *kAVMStringFromCGFloat(CGFloat tFloat) {
    return [NSString stringWithFormat:@"%.2f",tFloat];
}
NSString *kAVMStringFromNSInteger(NSInteger tInteger) {
    return [NSString stringWithFormat:@"%ld",tInteger];
}

NSComparisonResult kAVMFloatSort(CGFloat f1, CGFloat f2) {
    if (fabs(f1 - f2) <= 0.001) {
        return NSOrderedSame;
    }
    if (f1 < f2) {
        return NSOrderedAscending;
    }
    
    return NSOrderedDescending;
}

UIImage *kFilmCoverDeaflutImage() {
    static UIImage *defautImage = nil;
    if (!defautImage) {
        defautImage = [kFilmCoverImage imageByResizeToSize:CGSizeMake(kScreenWidth, kScreenWidth / 16.0 *9.0) contentMode:UIViewContentModeScaleAspectFit];
    }
    return defautImage;
}


@implementation AVMTool

+ (BOOL)isLogin {
    if (AVMUserInfo.isLogin) {
        return YES;
    }
    return NO;
}

+ (BOOL)isLoginByThirdPlatform {
    if ([AVMTool isLogin] && ![[AVMUserInfo.userBean.userAccountType lowercaseString] isEqualToString:mobile]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isVIP {
    return AVMUserInfo.userBean.isVIP;
}

+ (BOOL)needShowNotWIFINotice {
    if (kAVMReachabilityManager.isAvm_reachableViaWiFi) {
        return NO;
    }
    NSTimeInterval lastNotNoticNum = [kNSUserDefaults doubleForKey:@"kAVMShowNotWIFINotice"];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval chaTimeNum = currentTime - lastNotNoticNum;
    if (chaTimeNum > 24*60*60) {
        [kNSUserDefaults setDouble:currentTime forKey:@"kAVMShowNotWIFINotice"];
        return YES;
    }
    return NO;
}

+ (NSString *)changeColorToString:(UIColor *) textColor{
    return [textColor hexString];
}

+ (UIColor *)getColorFromString:(NSString *)colorString {
    return [UIColor colorWithHexString:colorString];
}


+ (BOOL)isAutoPlayWIFI {
    return [kNSUserDefaults boolForKey:kWIFIIsAutoPlay];
}

+ (void)setAutoPlayInWIFI:(BOOL)isAuto {
    [kNSUserDefaults setBool:isAuto forKey:kWIFIIsAutoPlay];
    [kNSUserDefaults synchronize];
}

+ (UIWindow *)mainWindow {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    return window;
}
+ (UIViewController *)rootViewController {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    return window.rootViewController;
}

+ (AVMNavigationController *)createNewNavigationController:(UIViewController *)viewController {
    return [[AVMNavigationController alloc] initWithRootViewController:viewController];
}

+ (NSString *)miPushAlias {
    NSString *userId = [kAVMCurrentUserId copy];
    NSString *alias = [userId stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    return alias;
}

+ (void)saveCheckAppVerInstantMakeFilmInfo:(NSDictionary *)resultDict {
    AVMInstantMakeFilmInfoModel *instantInfoModel = [AVMInstantMakeFilmInfoModel yy_modelWithJSON:resultDict[@"data"][@"instantMakeFilmInfo"]];
    AVMUserInfo.instantMakeFilmInfoModel = instantInfoModel;
    [AVMUserInfoModel saveUserInfoToNSUserDeafult];
}

+ (void)saveGetUserAccountData:(NSDictionary *)resultDict {
    NSDictionary *data = resultDict[@"data"];
    NSInteger filmCount = AVMUserInfo.userBean.userFilmCount;
    AVMUserInfo.userBean.userFilmCount = [data[@"userFilmCount"] integerValue];
    AVMUserInfo.userBean.noticeNotReadCount = [data[@"noticeNotReadCount"] integerValue];
    AVMUserInfo.userBean.isVIP = [data[@"isVIP"] boolValue];
    if (filmCount != AVMUserInfo.userBean.userFilmCount && !AVMUserInfo.hasNewFilm) {
        AVMUserInfo.hasNewFilm = YES;
        [kNSNotificationCenter postNotificationName:KAVMFilmMakeStatusChangedNotification object:nil];
    }
    [AVMUserInfoModel saveUserInfoToNSUserDeafult];
}

+ (void)presentLoginVC:(void (^)(BOOL))loginSuccessBlock {
    AVMLoginViewController *loginVC = [AVMLoginViewController new];
    loginVC.loginSuccessBlock = ^(BOOL isLoginSuccess) {
        if (isLoginSuccess) {
            [AppDelegateConst loginSuc];
            [[SDImageCache sharedImageCache] clearDisk];
            [[AVMMineFilmMakingProgressManager shareManager] start];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //避免键盘随UIAlertView 弹出
                [[AVMSyncService shareService] startSyncService];
            });
        }
        (loginSuccessBlock != nil)?loginSuccessBlock(isLoginSuccess):nil;
    };
    [[AVMTool rootViewController] presentViewController:[AVMTool createNewNavigationController:loginVC] animated:YES completion:nil];
}

+ (void)pushToFilmListVC {
    [self pushToFilmListVC:YES];
}

+ (void)pushToFilmDraftVC {
    [self pushToFilmListVC:NO];
}

+ (void)pushToFilmListVC:(BOOL)isFilmList {
    AVMNavigationController *rootNav = (AVMNavigationController *)[AVMTool rootViewController];
    
    __block BOOL hasFilmListVC = NO;
    __block AVMMineSettingViewController *settingVC = nil;
    [rootNav.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AVMMineFilmListViewController class]]) {
            hasFilmListVC = YES;
            *stop = YES;
        }else if ([obj isKindOfClass:[AVMMineSettingViewController class]  ]) {
            settingVC = obj;
        }
    }];
    
    if (hasFilmListVC) {
        [rootNav popToViewController:settingVC animated:NO];
        
    }else {
        [rootNav popToRootViewControllerAnimated:NO];
        AVMMineSettingViewController *settingVC = [AVMMineSettingViewController new];
        [rootNav pushViewController:settingVC animated:NO];
    }
    AVMMineFilmListViewController *filmListVC = [AVMMineFilmListViewController new];
    filmListVC.type =isFilmList?AVMMineFilmListTypeProduction:AVMMineFilmListTypeDraft;
    [rootNav pushViewController:filmListVC animated:NO];
}

+ (void)presentChooseElementVC:(void(^)(AVMFilmElementModel *filmElementModel ,NSError *error)) completion {
    UINavigationController *nav =(UINavigationController *) [AVMTool rootViewController];
    if (![nav isKindOfClass:[UINavigationController class]]) {
        completion(nil, [NSError errorWithDomain:@"error" code:1001 userInfo:nil]);
        return;
    }
    UIViewController *lastVC = nav.viewControllers.lastObject;
    AVMChooseElementViewController *chooseVC = [AVMChooseElementViewController new];
    [chooseVC viewOutWithChooseType:AVMEditPhotoVCEditTypeChooseElement elementCount:1];
    chooseVC.chooseAndEditElementBlock = ^(UIImage *snapImage,AVMFilmElementModel *filmElementModel) {
        completion(filmElementModel, nil);
    };
    [lastVC presentViewController:[AVMTool createNewNavigationController:chooseVC] animated:YES completion:nil];
}

+ (void)presentEditElementVC:(AVMFilmElementModel *)elementModel completion:(void(^)(AVMFilmElementModel *filmElementModel ,NSError *error))completion {
    UINavigationController *nav =(UINavigationController *) [AVMTool rootViewController];
    if (![nav isKindOfClass:[UINavigationController class]]) {
        completion(nil, [NSError errorWithDomain:@"error" code:1001 userInfo:nil]);
        return;
    }
    UIViewController *lastVC = nav.viewControllers.lastObject;
    UIViewController *editVC = nil;
    if (elementModel.elementType == AVMFilmElementTypeVideo) {
        AVMMakeFilmEditVideoViewController * editVideoVC = [AVMMakeFilmEditVideoViewController new];
        editVideoVC.view.backgroundColor = kThemeBackgroundColor;
        editVideoVC.chooseAndEditElementBlock = ^(UIImage *snapImage,AVMFilmElementModel *filmElementModel) {
            completion(filmElementModel, nil);
        };
        dispatch_async(dispatch_get_main_queue(), ^{
            [editVideoVC viewOutWithVideoFilmElementModel:elementModel editVideoElementType:AVMEditVideoElementTypePIPElement isRecreat:NO];
        });
        editVC = editVideoVC;
    }else if (elementModel.elementType == AVMFilmElementTypeImage) {
        AVMMakeFilmEditImageViewController *editImageVC = [[AVMMakeFilmEditImageViewController alloc] init];
        editImageVC.view.backgroundColor = kThemeBackgroundColor;
        editImageVC.chooseAndEditElementBlock = ^(UIImage *snapImage,AVMFilmElementModel *filmElementModel) {
            completion(filmElementModel, nil);
        };
        dispatch_async(dispatch_get_main_queue(), ^{
            [editImageVC viewOutWithImageModel:elementModel editElementUseType:AVMEditImageElementTypeFilmElement isRecreat:NO];
        });
        editVC = editImageVC;
    }
     [lastVC presentViewController:[AVMTool createNewNavigationController:editVC] animated:YES completion:nil];
}

+ (void)presentCropPhotoVC:(AVMFilmElementModel *)elementModel
                  editType:(AVMEditPhotoVCEditType)editType
                completion:(void (^)(UIImage *resultImage, AVMFilmElementModel *filmElementModel)) completion{
    AVMEditPhotoViewController *editPhotoVC = [AVMEditPhotoViewController new];
    editPhotoVC.editElementType = editType;
    editPhotoVC.filmElementModel = elementModel;
    
    editPhotoVC.cropImage = ^(AVMEditPhotoVCEditType editImageType, UIImage *resultImage, AVMFilmElementModel *filmElementModel) {
        if (completion) {
            completion(resultImage,filmElementModel);
        }
    };
    
    UINavigationController *nav =(UINavigationController *) [AVMTool rootViewController];
    if (![nav isKindOfClass:[UINavigationController class]]) {
        completion(nil,nil);
        return;
    }
    UIViewController *lastVC = nav.viewControllers.lastObject;
    [lastVC presentViewController:[AVMTool createNewNavigationController:editPhotoVC] animated:YES completion:nil];
}

+ (void)pushToChooseElementVC {
    AVMChooseElementViewController *chooseElementVC = [AVMChooseElementViewController new];
    [chooseElementVC viewOutWithChooseType:AVMEditPhotoVCEditTypeChooseElement elementCount:AVMUserInfo.instantMakeFilmInfoModel.instantVIPMaxElementCount];
    AVMNavigationController *rootNav = (AVMNavigationController *)[AVMTool rootViewController];
    [rootNav pushViewController:chooseElementVC animated:YES];
}

+ (void)pushToChooseElemenetVCByCompliedFilmJSON:(NSString *)filmJSON filmId:(NSString *)filmId {
    [SCRIPT_MANAGER clearManager];
    SCRIPT_MANAGER.complyFilmId = [filmId copy];
    [SCRIPT_MANAGER instantMakeFilmMangerFromCompliedFilmJSON:filmJSON];
    
    [self pushToChooseElementVC];
}

+ (void)setElementImageView:(UIImageView *)imageView filmElement:(AVMFilmElementModel *)elementModel image:(UIImage *)image frame:(CGRect)frame {
    imageView.image = image;
    CGFloat viewWidth = frame.size.width;
    float orignalWidth = [elementModel.ewidth floatValue];
    float orignalHeight = [elementModel.eheight floatValue];
    float imageViewWidth = orignalWidth*[elementModel.adjustParamModel.zoomScale floatValue] * (viewWidth)/1920;
    float imageViewHeight = imageViewWidth*orignalHeight/orignalWidth;
    float imageViewCenterX = [elementModel.adjustParamModel.centerOffset.offsetX floatValue]* viewWidth/1920;
    float imageViewCenterY = -[elementModel.adjustParamModel.centerOffset.offsetY floatValue]* viewWidth/1920;
    
    imageView.frame = CGRectMake(imageViewCenterX-(imageViewWidth-viewWidth)/2, imageViewCenterY-(imageViewHeight-viewWidth*9/16)/2, imageViewWidth, imageViewHeight);
    
    imageView.transform = CGAffineTransformMakeRotation(-[elementModel.adjustParamModel.rotateScale floatValue]);
    
    imageView.center = CGPointMake(CGRectGetWidth(frame)/2, CGRectGetHeight(frame)/2);
}

+ (UIImageOrientation)caculateVideoTrackOrientation:(AVAssetTrack *)assetVideoTrack {
    UIImageOrientation videoAssetOrientation_up  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait  = NO;
    CGAffineTransform videoTransform = assetVideoTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_up = UIImageOrientationRight;
        isVideoAssetPortrait = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_up =  UIImageOrientationLeft;
        isVideoAssetPortrait = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_up =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_up = UIImageOrientationDown;
    }
    
    return videoAssetOrientation_up;
}

+ (UIImage *)clipImage:(UIImage *)originalImage adjust:(AVMFilmElementAdjustModel *)adjust cropSize:(CGSize) cropSize {
    NSAssert(originalImage != nil, @"image can't = nil...");
    if (cropSize.height ==0 || cropSize.width == 0) {
        NSAssert(1 != 1, @"height or width can't = 0...");
    }
    
    CGRect s_rect = CGRectMake(0, 0, cropSize.width,cropSize.height);
//
    float orignalWidth   = originalImage.size.width;
    float orignalHeight  = originalImage.size.height;

    float e_scale = [adjust.zoomScale floatValue];

    float e_offset_x = [adjust.centerOffset.offsetX floatValue];
    float e_offset_y = [adjust.centerOffset.offsetY floatValue];
//    
    float c_offset_x = e_offset_x/e_scale;
    float c_offset_y = e_offset_y/e_scale;
    
    //裁剪框大小
    float c_width = 1920/e_scale;
    float c_height = (c_width * s_rect.size.height)/s_rect.size.width;
    
    
    float c_x = (orignalWidth -c_width) /2.0 - c_offset_x;
    float c_y = (orignalHeight -c_height) /2.0 + c_offset_y;

    CGImageRef cgImage = CGImageCreateWithImageInRect(originalImage.CGImage, CGRectMake(c_x, c_y, c_width, c_height));
    UIImage *newClipImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return newClipImage;

}

+ (void)saveFilmCoverImageToSanbox:(UIImage *)filmCoverImage isTemp:(BOOL)isTemp {
    NSString *filmCoverPath = nil;
    if (isTemp) {
        filmCoverPath = [AVMTool filmElementLocalPath:[NSString stringWithFormat:@"%@_temp",SCRIPT_MANAGER.filmId] suffix:kJPEG];
    }else {
        filmCoverPath = [AVMTool filmElementLocalPath:SCRIPT_MANAGER.filmId suffix:kJPEG];
    }
    CGSize newSaveSize = [AVMCompressImageUtil newImageSizeMaxSize:640 orignalImageSize:filmCoverImage.size];
    UIGraphicsBeginImageContextWithOptions(newSaveSize, NO, 1.0);
    [filmCoverImage drawInRect:CGRectMake(0, 0, newSaveSize.width, newSaveSize.height)];
    filmCoverImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *jpegData = UIImageJPEGRepresentation(filmCoverImage, 0.5);
    [jpegData writeToFile:filmCoverPath atomically:YES];
}

+ (BOOL)checkImageIsQR:(UIImage *)image {
    if (!image) {
        return NO;
    }
    if (!IsiOS8AndLater) {
        return YES;
    }
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    NSData*imageData =UIImagePNGRepresentation(image);
    CIImage*ciImage = [CIImage imageWithData:imageData];
    NSArray*features = [detector featuresInImage:ciImage];
    if (!features || features.count == 0) {
        return NO;
    }
    CIQRCodeFeature*feature = [features objectAtIndex:0];
    NSString*scannedResult = feature.messageString;
    if (scannedResult && scannedResult.length > 0) {
        return YES;
    }
    return NO;
}

+ (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}

#pragma mark 路径拼接

+ (NSString *)filmCoverLocalImage:(NSString *)filmId {
    NSString *coverPath = [AVMTool filmElementLocalPath:filmId suffix:kJPEG];
    if (![[NSFileManager defaultManager] fileExistsAtPath:coverPath]) {
        coverPath = nil;
    }
    return coverPath;
}

+ (NSString *)filmElementLocalPath:(NSString *)filmElementId suffix:(NSString *)suffix {
    return ITTPathForAVMResource([NSString stringWithFormat:@"%@/%@.%@",kAVMCurrentUserId,filmElementId,suffix]);
}

+ (NSString *)filmElementThumbnailLocalPath:(NSString *)filmElementId suffix:(NSString *)suffix{
    if ([suffix isEqualToString:kMP4]) {
        suffix = kJPEG;
    }
    return ITTPathForAVMResource([NSString stringWithFormat:@"%@/%@_s.%@",kAVMCurrentUserId,filmElementId,suffix]);
}

+ (NSString *)getHTMLUrlWithApiUrl:(NSString *)apiUrl {
    AVMRequestBaseModel *requestBaseModel = [AVMRequestBaseModel defaultModel];
    NSString *appStr = nil;
    appStr = [NSString stringWithFormat:@"APPVer=%@&APPCH=%@&APPOS=%@",requestBaseModel.APPVer,requestBaseModel.APPCH,requestBaseModel.APPOS];
    NSString *url = [NSString stringWithFormat:@"%@&userId=%@&%@",apiUrl,[AVMTool isLogin]?kAVMCurrentUserId:AVMUserInfo.touristID,appStr];
    return url;
}

#pragma mark -解析url参数
+ (NSDictionary *)analyzedURLParameter:(NSString *)urlString {
    NSString *parameterString = [[urlString componentsSeparatedByString:@"?"] lastObject];
    NSArray *parameters = [parameterString componentsSeparatedByString:@"&"];
    NSMutableDictionary *paramtersDict = [NSMutableDictionary dictionaryWithCapacity:parameters.count];
    for (NSString *param in parameters) {
        NSArray *p = [param componentsSeparatedByString:@"="];
        if (p && p.count == 2) {
            paramtersDict[[p firstObject]] = [p lastObject];
        }
    }
    return paramtersDict;
}

#pragma mark - Open url
+ (void)openURL:(NSURL *)url completionHandler:(void (^ _Nullable)(BOOL success))completionHandler {
    if (!url) {
        completionHandler(NO);
        return;
    }
    BOOL canOpen = [kUIApplication canOpenURL:url];
    if (canOpen) {
        BOOL opened = NO;
        if ([kUIApplication respondsToSelector:@selector(openURL: options:completionHandler:)]) {
            [kUIApplication openURL:url options:@{} completionHandler:^(BOOL success) {
//                completionHandler(success);
            }];
        }else {
            opened = [kUIApplication openURL:url];
//            completionHandler(opened);
        }
        completionHandler(YES);
    }else {
        completionHandler(NO);
    }
}

+ (UIViewController *)currentViewController {
    UIViewController * currentViewController = nil;
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    if (window != nil){
        currentViewController = window.rootViewController;
    }
    return [self scanCurrentController: currentViewController];
}
/**
 扫描获取最前面的控制器

 @param viewController viewController: 要扫描的控制器
 @return 返回最上面的控制器
 */
+ (UIViewController *)scanCurrentController:(UIViewController *)viewController {
    UIViewController * currentViewController = nil;
    if (viewController) {
        if ([viewController isKindOfClass:[UINavigationController class]] && ((UINavigationController *)viewController).topViewController != nil) {
            currentViewController = ((UINavigationController *)viewController).topViewController;
            currentViewController = [self scanCurrentController:currentViewController];
        }else if ([viewController isKindOfClass:[UITabBarController class]] && ((UITabBarController *)viewController).selectedViewController != nil) {
            currentViewController = ((UITabBarController *)viewController).selectedViewController;
            currentViewController = [self scanCurrentController:currentViewController];
        }else {
            currentViewController = viewController;
            BOOL hasPresentController = NO;
            UIViewController * presentedController = currentViewController.presentedViewController;
            while (presentedController) {
                currentViewController = presentedController;
                hasPresentController = YES;
                presentedController = currentViewController.presentedViewController;
            }
            if (hasPresentController) {
                currentViewController = [self scanCurrentController: currentViewController];
            }
        }
    }
    return currentViewController;
}

+ (UIView *)blurView {
    UIView *blurView = nil;
    if (IsiOS8AndLater) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        blurView = effectView;
    }else {
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.barStyle = UIBarStyleDefault;
        blurView = toolbar;
    }
    blurView.userInteractionEnabled = NO;
    blurView.backgroundColor = [UIColor whiteColor];
    blurView.alpha = 0.85;
//    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
//    gradientLayer.colors = @[(__bridge id)kColorWithHex_alpha(0x040012, 0.76).CGColor,(__bridge id)kColorWithHex_alpha(0x040012, 0.28).CGColor];
//    gradientLayer.startPoint = CGPointMake(0, 0);
//    gradientLayer.endPoint = CGPointMake(0, 1.0);
//    [self.alertView.layer addSublayer:gradientLayer];
    return blurView;
}

+ (void)clearAVMFileData:(BOOL)deleteDB {
    NSString *dataPath = ITTPathForAVMResource(nil);
    [self removeCachePath:dataPath deleteDB:deleteDB];
    [AppDelegate restoreAVMFileSystem];
    if (deleteDB) {
        [AVMDBManager restoreInit];
    }
}

+ (void) removeCachePath:(NSString *)path deleteDB:(BOOL)deleteDB{
    NSFileManager* manager = [NSFileManager defaultManager];
    [[manager subpathsAtPath:path] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (deleteDB) {
            NSString* fileAbsolutePath = [path stringByAppendingPathComponent:obj];
            [manager removeItemAtPath:fileAbsolutePath error:nil];
        }else {
            if (![obj isEqualToString:dbName]) {
                NSString* fileAbsolutePath = [path stringByAppendingPathComponent:obj];
                [manager removeItemAtPath:fileAbsolutePath error:nil];
            }
        }
    }];
}

@end
