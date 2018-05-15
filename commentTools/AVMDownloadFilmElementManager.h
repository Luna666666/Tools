//
//  AVMDownloadFilmElementManager.h
//  AVM
//
//  Created by Changxu Zhuang on 2017/8/23.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AVMDownloadFilmElementOneCompliteBlock)(NSString *elementLocalPath, NSError *error);
typedef void(^AVMDownloadFilmElementAllCompliteProgressBlock) (BOOL isFinish, NSError *error, int64_t receivedBytes, int64_t totalExpectedBytes);


@class AVMFilmElementModel;
@interface AVMDownloadFilmElementManager : NSObject
+ (instancetype)sharedManger;

/** 清空下载缓存，最好在调用downloadFilmElement: complite：之前调用一次 */
+ (void)clearCache;

/** 下载进度回调 */
@property (nonatomic, copy) AVMDownloadFilmElementAllCompliteProgressBlock downloadAllProgressBlock;

- (void)downloadFilmElement:(AVMFilmElementModel *)filmElementModel complite:(AVMDownloadFilmElementOneCompliteBlock)compliteBlock;

@end
