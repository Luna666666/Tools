//
//  AVMCompressImageUtil.m
//  AVM
//
//  Created by Changxu Zhuang on 2017/6/9.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMCompressImageUtil.h"
#import "UIImage+Resize.h"
#import "AVMFilmElementModel.h"

@implementation AVMCompressImageUtil
+ (CGSize)compressImageWithOrignalImage:(UIImage *)orignalImage descSavePath:(NSString *)descSavePath filmElementModel:(AVMFilmElementModel *)filmElementModel complite:(AVMCompressImageCompressBigImageComplite)complite {
    CGSize desImageSize;
    UIImage *imageScaled = orignalImage;
    NSInteger imageWidth = imageScaled.size.width;
    NSInteger imageHeight = imageScaled.size.height;
    CGSize imageSize;
    
    CGFloat maxSize = 1920.f;
    if (imageHeight >= maxSize || imageWidth >= maxSize) { //如果该图长宽有一个大于960，则改变其像素
        
        imageSize = [self newImageSizeMaxSize:maxSize orignalImageSize:orignalImage.size];
        
        
        if ([filmElementModel.suffix isEqualToString:@"png"]) {
            UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
            [orignalImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
            imageScaled = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *imageData = UIImagePNGRepresentation(imageScaled);
            filmElementModel.fileSize = [NSString stringWithFormat:@"%lu",(unsigned long)imageData.length];
            [imageData writeToFile:descSavePath atomically:YES];
        }else {
            UIGraphicsBeginImageContext(imageSize);
            [orignalImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
            imageScaled = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *imageData = UIImageJPEGRepresentation(imageScaled, 0.89f);
            CGFloat compressionQuality = 0.79f;
            while (TRUE) {
                if ([imageData length] > 800*1024 & compressionQuality > 0) {
                    imageData = UIImageJPEGRepresentation(imageScaled, compressionQuality);
                    compressionQuality = compressionQuality - 0.1f;
                } else {
                    break;
                }
            }
            NSLog(@"压缩大图的系数为%f",compressionQuality+0.1);
            filmElementModel.fileSize = [NSString stringWithFormat:@"%lu",(unsigned long)imageData.length];
            [imageData writeToFile:descSavePath atomically:YES];
        }
        
        
    }else {
        if ([filmElementModel.suffix isEqualToString:@"png"]) {
            NSData *imageData = UIImagePNGRepresentation(imageScaled);
            filmElementModel.fileSize = [NSString stringWithFormat:@"%lu",(unsigned long)imageData.length];
            [imageData writeToFile:descSavePath atomically:YES];
        }else {
            
            NSData *imageData = UIImageJPEGRepresentation(imageScaled, 0.89f);
            CGFloat compressionQuality = 0.79f;
            while (TRUE) {
                if ([imageData length] > 800*1024 & compressionQuality > 0) {
                    imageData = UIImageJPEGRepresentation(imageScaled, compressionQuality);
                    compressionQuality = compressionQuality - 0.1f;
                } else {
                    break;
                }
            }
            NSLog(@"压缩大图的系数为%f",compressionQuality+0.1);
            filmElementModel.fileSize = [NSString stringWithFormat:@"%lu",(unsigned long)imageData.length];
            [imageData writeToFile:descSavePath atomically:YES];
        }
    }
    
    
    desImageSize = imageScaled.size;
    return desImageSize;
}

+ (void)compressSmallImageWithOrignalImage:(UIImage *)orignalImage filmElementModel:(AVMFilmElementModel *)filmElementModel descSavePath:(NSString *)descSavePath {
    UIImage *imageScaled = orignalImage;
    NSInteger imageWidth = imageScaled.size.width;
    NSInteger imageHeight = imageScaled.size.height;
    CGSize imageSize;
    CGFloat maxSize = 316.f;
    if (imageHeight >= maxSize && imageWidth >= maxSize) {
        
        imageSize = [self newImageSizeMaxSize:maxSize orignalImageSize:orignalImage.size];
        
        if ([filmElementModel.suffix isEqualToString:@"png"]) {
            UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
            [orignalImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
            imageScaled = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *imageData = UIImagePNGRepresentation(imageScaled);
            
            [imageData writeToFile:descSavePath atomically:YES];
        }else {
            UIGraphicsBeginImageContext(imageSize);
            [orignalImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
            imageScaled = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData *imageData = UIImageJPEGRepresentation(imageScaled, 1.0f);
            CGFloat compressionQuality = 0.9f;
            while (TRUE) {
                if ([imageData length] > 50000 & compressionQuality > 0) {
                    imageData = UIImageJPEGRepresentation(imageScaled, compressionQuality);
                    compressionQuality = compressionQuality - 0.1f;
                } else {
                    break;
                }
            }
            [imageData writeToFile:descSavePath atomically:YES];
        }
        
       
    }else {
        if ([filmElementModel.suffix isEqualToString:@"png"]) {
           
            NSData *imageData = UIImagePNGRepresentation(imageScaled);
            
            [imageData writeToFile:descSavePath atomically:YES];
        }else {
            
            NSData *imageData = UIImageJPEGRepresentation(imageScaled, 1.0f);
            CGFloat compressionQuality = 0.9f;
            while (TRUE) {
                if ([imageData length] > 50000 & compressionQuality > 0) {
                    imageData = UIImageJPEGRepresentation(imageScaled, compressionQuality);
                    compressionQuality = compressionQuality - 0.1f;
                } else {
                    break;
                }
            }
            [imageData writeToFile:descSavePath atomically:YES];
        }
    }
    
    //若全屏图大于30000，则首次按0.9压缩，之后按0.1递减压缩，直至小于30000。
    
    
}

+(UIImage *)compressImageWithOrignalImage:(UIImage *)originalImage targetSize:(CGSize)targetSize {
    float maxSide = MAX(targetSize.width, targetSize.height);
    UIImage *imageScaled = originalImage;
    NSInteger imageWidth = imageScaled.size.width;
    NSInteger imageHeight = imageScaled.size.height;
    CGSize imageSize;
    if (imageHeight >= maxSide || imageWidth >= maxSide) { //如果该图长宽有一个大于960，则改变其像素
        imageSize = [self newImageSizeMaxSize:maxSide orignalImageSize:originalImage.size];
        
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
        [originalImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
        imageScaled = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return imageScaled;
}

/**
 计算图片的size (保持原始图片的比例)

 @param maxSize 边界的最大值
 @param orignalImageSize 原始图片的size
 @return 生成size
 */
+ (CGSize)newImageSizeMaxSize:(CGFloat)maxSize orignalImageSize:(CGSize)orignalImageSize {
    if (orignalImageSize.width < 0.1 || orignalImageSize.height < 0.1) {
        return CGSizeZero;
    }
    CGFloat targetWidth  = 0;
    CGFloat targetHeight = 0;
    if (orignalImageSize.width >= orignalImageSize.height) {
        targetWidth  = maxSize;
        targetHeight = orignalImageSize.height * targetWidth / orignalImageSize.width;
    }else {
        targetHeight = maxSize;
        targetWidth  = orignalImageSize.width * targetHeight / orignalImageSize.height;
    }
    return CGSizeMake((NSUInteger)targetWidth, (NSUInteger)targetHeight);
}

@end
