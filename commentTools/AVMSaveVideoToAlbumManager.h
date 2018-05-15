//
//  AVMSaveVideoToAlbumManager.h
//  AVM
//
//  Created by sunzongtang on 2017/6/19.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVMSaveVideoToAlbumManager : NSObject

+ (void)SaveVideoToAlbumWithVideoUrl:(NSURL *)videoUrl Sussess:(void(^)(NSURL *albutmUrl))Sussess Fail:(void(^)(BOOL hasNoAuth))Fail; //权限

@end
