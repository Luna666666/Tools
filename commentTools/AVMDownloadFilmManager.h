//
//  AVMDownloadFilmManager.h
//  AVM
//
//  Created by sunzongtang on 2017/7/12.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//下载视频

#import <Foundation/Foundation.h>

@interface AVMDownloadFilmManager : NSObject

+ (instancetype)sharedDownloadFilmManger;

- (void)downloadFilm:(NSString *)filmId
             filmUrl:(NSString *)filmUrl
    downloadProgress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
   completionHandler:(void (^)(NSInteger statusCode, NSString * msg,NSString * localFilmUrl, NSError *error))completionHandler;

//判断本地是否已经下载 -如果下载了返回本地路径，否则返回nil
- (NSString *)filmLocalPath:(NSString *)filmId;

@end
