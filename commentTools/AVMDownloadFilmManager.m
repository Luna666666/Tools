//
//  AVMDownloadFilmManager.m
//  AVM
//
//  Created by sunzongtang on 2017/7/12.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMDownloadFilmManager.h"

#import "AVMGobalPaths.h"
#import <AFNetworking.h>

#define kAVMDownloadFilmCompletionBlock(statusCode,msg,localFilmUrl,error) if (completionHandler) {\
completionHandler(statusCode,msg,localFilmUrl,error);\
}

static NSString *kAVMDownloadFilmCacheDirectory(void) {
    return ITTPathForCacheResource(@"avmcache/download");
}
static NSString *kAVMDownloadFilmCachePath(NSString *filmId) {
    return [NSString stringWithFormat:@"%@/%@.mp4",kAVMDownloadFilmCacheDirectory(),filmId];
}
static NSString *kAVMDownloadFilmCacheTempPath(NSString *filmId) {
    return [NSString stringWithFormat:@"%@/%@_cache.temp",kAVMDownloadFilmCacheDirectory(),filmId];
}
static NSString *kAVMDownloadFilmCacheTempPlistPath(NSString *filmId) {
    return [NSString stringWithFormat:@"%@/%@_cache.plist",kAVMDownloadFilmCacheDirectory(),filmId];
}

@interface AVMDownloadFilmManager ()<NSCopying>

@property (nonatomic, strong)AFURLSessionManager *sessionManager;
@property (nonatomic, strong)NSFileManager *fileManager;
@property (nonatomic, strong)NSMutableDictionary *filmUrlCache;

@end

@implementation AVMDownloadFilmManager

static AVMDownloadFilmManager *_downloadFilmManager = nil;
static int operationMaxCount = 3; //最大可以同时下载三个，当超过时，会取消第一个

#pragma mark -实例化
+ (instancetype)sharedDownloadFilmManger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadFilmManager = [[AVMDownloadFilmManager alloc] init];
    });
    return _downloadFilmManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadFilmManager = [super allocWithZone:zone];
    });
    return _downloadFilmManager;
}

- (instancetype)init {
    if (self = [super init]) {
        NSTimeInterval timeoutInterval = 5 *60; //超时间隔 5分钟
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest  = 30;
        //接收到数据，时间间隔，（不是 响应最大时长）
        config.timeoutIntervalForResource = timeoutInterval;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
        self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        kWEAKSELF;
        [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
            [weakSelf dataTaskDidReceiveData:session task:dataTask data:data];
        }];
        
        self.fileManager = [NSFileManager defaultManager];
        self.filmUrlCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return _downloadFilmManager;
}

#pragma mark -下载

#define kLocalFilmTempPath @"localFilmTempPath"
#define kFileHandle @"fileHandle"

- (NSString *)filmLocalPath:(NSString *)filmId {
    NSString *localFilmPath = kAVMDownloadFilmCachePath(filmId);
    if ([self.fileManager fileExistsAtPath:localFilmPath]) {
        return localFilmPath;
    }
    return nil;
}

- (void)downloadFilm:(NSString *)filmId filmUrl:(NSString *)filmUrl downloadProgress:(void (^)(NSProgress *))downloadProgressBlock completionHandler:(void (^)(NSInteger, NSString *,NSString *, NSError *))completionHandler {
    NSAssert(filmId != nil, @"filmId can't nil");
    NSAssert(filmUrl != nil, @"filmUrl can't nil");
    
    if (self.sessionManager.tasks) {
        for (NSURLSessionDataTask *dataTask in self.sessionManager.tasks) {
            if ([[dataTask.originalRequest.URL absoluteString] isEqualToString:filmUrl]) {
                kAVMDownloadFilmCompletionBlock(-100, @"视频正在下载", nil, [NSError errorWithDomain:@"视频正在下载" code:-100 userInfo:nil]);
                return;
            }
        }
        if (self.sessionManager.tasks.count >= operationMaxCount) {
            [[self.sessionManager.tasks firstObject] cancel];
        }
    }
    
    NSString *localFilmDirectory = kAVMDownloadFilmCacheDirectory();
    NSString *localFilmPath = kAVMDownloadFilmCachePath(filmId);
    NSString *localFilmTempPath = kAVMDownloadFilmCacheTempPath(filmId);
    NSString *localFilmTempPlistPath = kAVMDownloadFilmCacheTempPlistPath(filmId);
    if ([self.fileManager fileExistsAtPath:localFilmPath]) {
        kAVMDownloadFilmCompletionBlock(200, @"文件已经存在", localFilmPath, nil);
        return;
    }
    
    if (![self.fileManager fileExistsAtPath:localFilmTempPath]) {
        [self.fileManager createDirectoryAtPath:localFilmDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        BOOL create1 =  [self.fileManager createFileAtPath:localFilmTempPath contents:nil attributes:nil];
        BOOL create2 = [self.fileManager createFileAtPath:localFilmTempPlistPath contents:nil attributes:nil];
        if (!create1 || !create2) {
            kAVMDownloadFilmCompletionBlock(-101, @"文件操作失败", nil, [NSError errorWithDomain:@"文件操作失败" code:-101 userInfo:nil]);
            return;
        }
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:localFilmTempPath];
    long long offset = [fileHandle seekToEndOfFile];
    
    NSMutableURLRequest *request = [self urlRequest:filmUrl];
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:localFilmTempPlistPath];
    __block unsigned long long hdFilmSize = [dict[@"fileMaxLength"] longLongValue];
    
    NSProgress *downloadProgress_t = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    downloadProgress_t.totalUnitCount = NSURLSessionTransferSizeUnknown;
    
    if (offset != 0) {//断点下载
        [request addValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"Range"];
    }
    //设置进度
    if (downloadProgressBlock) {
        downloadProgress_t.completedUnitCount = offset;
        downloadProgress_t.totalUnitCount = hdFilmSize+1;
        downloadProgressBlock(downloadProgress_t);
    }
    
    //缓存localFilmTempPath 与 filmUrl
    self.filmUrlCache[filmUrl] = @{kLocalFilmTempPath:localFilmTempPath,
                                   kFileHandle:fileHandle};
    kWEAKSELF;
    NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (downloadProgressBlock) {
                downloadProgress_t.completedUnitCount = downloadProgress.completedUnitCount + offset;
                downloadProgress_t.totalUnitCount = downloadProgress.totalUnitCount + offset;
                downloadProgressBlock(downloadProgress_t);
            }
            int64_t totalBytesExpectedToRead = downloadProgress.totalUnitCount+offset;
            if (hdFilmSize != totalBytesExpectedToRead) {
                NSDictionary *tDict = @{@"fileMaxLength":@(totalBytesExpectedToRead)};
                [tDict writeToFile:localFilmTempPlistPath atomically:YES];
                hdFilmSize = totalBytesExpectedToRead;
            }
        });
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.filmUrlCache removeObjectForKey:filmUrl];
            if (error && (statusCode != 206 && statusCode != 416 && statusCode != 200)) {
                [fileHandle closeFile];
                if (statusCode != NSURLErrorCancelled) {
                    [[NSFileManager defaultManager] removeItemAtPath:localFilmTempPath error:nil]; //删除临时文件
                    [[NSFileManager defaultManager] removeItemAtPath:localFilmTempPlistPath error:nil];
                    kAVMDownloadFilmCompletionBlock(statusCode, @"下载失败",nil, error);
                }else {
                    kAVMDownloadFilmCompletionBlock(statusCode, @"取消下载",nil, error);
                }
                return ;
            }else if (statusCode == 206) {//断点续传成功
                
            }else if (statusCode == 416) { //range超出--
                NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:localFilmTempPlistPath];
                unsigned long long tHdFilmSize = [plistDict[@"fileMaxLength"] longLongValue];
                if ([fileHandle seekToEndOfFile] > tHdFilmSize) {
                    [fileHandle truncateFileAtOffset:tHdFilmSize];
                }else {
                    kAVMDownloadFilmCompletionBlock(statusCode, @"视频下载失败",nil, error);
                    [fileHandle closeFile];
                    return;
                }
            }
            
            [fileHandle closeFile];
            
            NSError *fileError;
            [[NSFileManager defaultManager] copyItemAtPath:localFilmTempPath toPath:localFilmPath error:&fileError];
            if (fileError) {
                kAVMDownloadFilmCompletionBlock(statusCode, @"视频拷贝出错",nil, error);
                return;
            }
            [[NSFileManager defaultManager] removeItemAtPath:localFilmTempPath error:nil]; //删除临时文件
            [[NSFileManager defaultManager] removeItemAtPath:localFilmTempPlistPath error:nil];
            
            if (statusCode == 206 || statusCode == 416 || statusCode == 200) {
                kAVMDownloadFilmCompletionBlock(statusCode, @"下载成功",localFilmPath, nil);
                return;
            }
            kAVMDownloadFilmCompletionBlock(statusCode, @"下载",nil, error);
        });
    }];
    [dataTask resume];
}

#pragma mark -接收到数据
- (void)dataTaskDidReceiveData:(NSURLSession *)session task:( NSURLSessionDataTask *)dataTask data:(NSData *)data {
    NSDictionary *dict = self.filmUrlCache[[dataTask.originalRequest.URL absoluteString]];
    NSString *localFilmTempPath = dict[kLocalFilmTempPath];
    NSFileHandle *fileHandle = dict[kFileHandle];
    if (!localFilmTempPath || !fileHandle) {
        [dataTask cancel];
        return ;
    }
    if (![self.fileManager fileExistsAtPath:localFilmTempPath]) {
        //文件已经删除 --取消下载
        [dataTask cancel];
        return ;
    }
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle synchronizeFile];
}

#pragma mark -下载相关help
- (NSMutableURLRequest *)urlRequest:(NSString *)filmUrl {
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:filmUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    //异常请求缓存
    NSURLCache *urlCache = [NSURLCache sharedURLCache];
    [urlCache removeCachedResponseForRequest:request];
    request.HTTPShouldHandleCookies = NO;
    return request;
}

@end
