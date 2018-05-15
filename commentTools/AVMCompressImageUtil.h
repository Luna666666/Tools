//
//  AVMCompressImageUtil.h
//  AVM
//
//  Created by Changxu Zhuang on 2017/6/9.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AVMFilmElementModel;
typedef void (AVMCompressImageCompressBigImageComplite)(CGSize finalSize);

@interface AVMCompressImageUtil : NSObject

/**
 *  压缩图片素材大图到规定的大小。同时如果素材的尺寸变化，也会自动调节素材的adjust参数
 */
+ (CGSize)compressImageWithOrignalImage:(UIImage *)orignalImage descSavePath:(NSString *)descSavePath filmElementModel:(AVMFilmElementModel *)filmElementModel complite:(AVMCompressImageCompressBigImageComplite)complite;

/**
 *  压缩小图
 */
+ (void)compressSmallImageWithOrignalImage:(UIImage *)orignalImage filmElementModel:(AVMFilmElementModel *)filmElementModel descSavePath:(NSString *)descSavePath;

+(UIImage *)compressImageWithOrignalImage:(UIImage *)originalImage targetSize:(CGSize)targetSize;

/**
 计算图片的size (保持原始图片的比例)
 
 @param maxSize 边界的最大值
 @param orignalImageSize 原始图片的size
 @return 生成size
 */
+ (CGSize)newImageSizeMaxSize:(CGFloat)maxSize orignalImageSize:(CGSize)orignalImageSize;
@end
