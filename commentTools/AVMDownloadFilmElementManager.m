//
//  AVMDownloadFilmElementManager.m
//  AVM
//
//  Created by Changxu Zhuang on 2017/8/23.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMDownloadFilmElementManager.h"
#import "AVMFilmElementModel.h"
#import "AVMFilePathManager.h"

@interface AVMDownloadElementModel : NSObject

@property (nonatomic, copy) NSString *netPath; //网络请求 path
@property (nonatomic, copy) NSString *localPath; //本地存储path

@property (nonatomic, copy) AVMDownloadFilmElementOneCompliteBlock compliteBlock;

@property (nonatomic, assign) long long fileSize;

@end
@implementation AVMDownloadElementModel

@end


@interface AVMDownloadFilmElementManager ()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) NSURLSession *sessionManager;

@property (nonatomic, strong) NSMutableDictionary *needRequestCaches;
@property (nonatomic, strong) NSMutableDictionary *requestingCaches;

@property (nonatomic, assign) NSUInteger downloadingCount; //正在下载的素材数

@property (nonatomic, assign) int64_t receivedSize; //收到的全部字节数
@property (nonatomic, assign) int64_t totalExpectedReceivedSize; //需要下载的全部字节数

@end

static NSUInteger maxDownloadElementCount = 3;

@implementation AVMDownloadFilmElementManager

static AVMDownloadFilmElementManager *_downloadFilmManager = nil;

#pragma mark -实例化
+ (instancetype)sharedManger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadFilmManager = [[AVMDownloadFilmElementManager alloc] init];
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
        _fileManager = [NSFileManager defaultManager];
        
        NSTimeInterval timeoutInterval = 1 *60; //超时间隔 1分钟
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest  = 30;
        //接收到数据，时间间隔，（不是 响应最大时长）
        config.timeoutIntervalForResource = timeoutInterval;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        NSOperationQueue *delegateQueue = [NSOperationQueue new];
        delegateQueue.name = @"avm.download.filmElement.queue";
        delegateQueue.maxConcurrentOperationCount = 1;
        _sessionManager = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:delegateQueue];
        
        _needRequestCaches = [NSMutableDictionary dictionary];
        _requestingCaches  = [NSMutableDictionary dictionaryWithCapacity:maxDownloadElementCount];
    }
    return self;
}

+ (void)clearCache {
    _downloadFilmManager.downloadAllProgressBlock = nil;
    [_downloadFilmManager.needRequestCaches removeAllObjects];
    [_downloadFilmManager.requestingCaches removeAllObjects];
    
    [_downloadFilmManager.sessionManager getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        [dataTasks makeObjectsPerformSelector:@selector(cancel)];
        [uploadTasks makeObjectsPerformSelector:@selector(cancel)];
        [downloadTasks makeObjectsPerformSelector:@selector(cancel)];
    }];
    _downloadFilmManager.receivedSize = 0;
    _downloadFilmManager.downloadingCount = 0;
    _downloadFilmManager.totalExpectedReceivedSize = 0;
}

- (void)downloadFilmElement:(AVMFilmElementModel *)filmElementModel complite:(AVMDownloadFilmElementOneCompliteBlock)compliteBlock {

    if (!filmElementModel || kStringIsEmpty(filmElementModel.filmElementId)) {
        NSAssert(NO, @"filmElement can't nil");
    }
    NSString *elementNetPath   = nil;
    NSString *elementLocalPath = nil;
    if (filmElementModel.elementType == AVMFilmElementTypeImage) {
        elementLocalPath = [self filmElementLocalPath:filmElementModel.filmElementId ofType:filmElementModel.suffix];
        elementNetPath   = [self filmElmentNetPath:filmElementModel.filmElementId ofType:filmElementModel.suffix userId:filmElementModel.userId];
        
    }else if (filmElementModel.elementType == AVMFilmElementTypeVideo) {
        elementLocalPath = [self filmElementLocalPath:filmElementModel.filmElementId ofType:filmElementModel.suffix];
        elementNetPath   = [self filmElmentNetPath:filmElementModel.filmElementId ofType:filmElementModel.suffix userId:filmElementModel.userId];
    }else {
        NSLog(@"---非下载素材-----");
        return;
    }
    long long fileSize = [filmElementModel.fileSize longLongValue];
    
    self.totalExpectedReceivedSize += fileSize;
    
    if (!self.needRequestCaches[elementNetPath] && ![self checkFilmElementLocalFileIsExist:elementLocalPath]) {
        //本地不存在，且没有准备下载数据
        AVMDownloadElementModel *downloadModel = [AVMDownloadElementModel new];
        downloadModel.netPath   = elementNetPath;
        downloadModel.localPath = elementLocalPath;
        downloadModel.fileSize  = fileSize;
        downloadModel.compliteBlock = compliteBlock;
        self.needRequestCaches[elementNetPath] = downloadModel;
        
        [self nextRequst];
    }else {
        self.receivedSize += fileSize;
        if (self.downloadAllProgressBlock) {
            self.downloadAllProgressBlock(NO, nil, self.receivedSize, self.totalExpectedReceivedSize);
        }
        if ([self checkFilmElementLocalFileIsExist:elementLocalPath]) {
            if (compliteBlock) {
                compliteBlock(elementLocalPath, nil);
            }
        }
    }
}

//执行下一个请求
- (void)nextRequst {
    if (self.downloadingCount >= maxDownloadElementCount) return;
    
    AVMDownloadElementModel *downloadModel = [[self.needRequestCaches allValues] firstObject];
    if (!downloadModel && self.requestingCaches.count == 0) {
        //全部请求完成
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.downloadAllProgressBlock) {
                self.downloadAllProgressBlock(YES, nil, 1, 1);
            }
        });
        [AVMDownloadFilmElementManager clearCache];
        return;
    }else if (!downloadModel) {
        
        return;
    }
    [self requestFilmElement:downloadModel.netPath localPath:downloadModel.localPath];
}

- (void)requestFilmElement:(NSString *)netPath localPath:(NSString *)localPath {
    
    BOOL isExist = [self checkFilmElementLocalFileIsExist:localPath];
    if (isExist) {
        [self nextRequst];
        return;
    }
    self.downloadingCount ++;
    
    AVMDownloadElementModel *downloadModel = self.needRequestCaches[netPath];
    [self.needRequestCaches removeObjectForKey:netPath];
    self.requestingCaches[netPath] = downloadModel;
    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithURL:[NSURL URLWithString:netPath]];
    [downloadTask resume];
}

- (void)requestOneComplite:(AVMDownloadElementModel *)downloadModel error:(NSError *)error {
    dispatch_block_t block_t = ^() {
        if (downloadModel.compliteBlock && downloadModel) {
            downloadModel.compliteBlock(error?nil:downloadModel.localPath, error);
        }
        if (error) {
            if (self.downloadAllProgressBlock) {
                self.downloadAllProgressBlock(YES, error, 0, 1);
            }
            NSLog(@"下载出错--：%@",error);
            [AVMDownloadFilmElementManager clearCache];
            return ;
        }
        [self.requestingCaches removeObjectForKey:downloadModel.netPath];
        self.downloadingCount --;
        [self nextRequst];
    };
    dispatch_main_async_safe_avm(block_t);
}

#pragma mark -NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (error) {
        NSString *netPath = [task.originalRequest.URL absoluteString];
        AVMDownloadElementModel *downloadModel = self.requestingCaches[netPath];
        [self requestOneComplite:downloadModel error:[NSError errorWithDomain:@"error" code:-1011 userInfo:nil]];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSString *netPath = [downloadTask.originalRequest.URL absoluteString];
    AVMDownloadElementModel *downloadModel = self.requestingCaches[netPath];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)downloadTask.response;
    if (downloadTask.error || httpResponse.statusCode != 200 ) {
        [self requestOneComplite:downloadModel error:[NSError errorWithDomain:@"error" code:-1011 userInfo:nil]];
        return ;
    }
    NSError *fileError;
    [self.fileManager copyItemAtURL:location toURL:[NSURL fileURLWithPath:downloadModel.localPath] error:&fileError];
    if (fileError) {
        [self requestOneComplite:downloadModel error:[NSError errorWithDomain:@"error" code:-1011 userInfo:nil]];
        return;
    }
    [self.fileManager removeItemAtURL:location error:nil];
    [self requestOneComplite:downloadModel error:nil];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.receivedSize += totalBytesWritten;
        if (self.downloadAllProgressBlock) {
            self.downloadAllProgressBlock(NO, nil, self.receivedSize, self.totalExpectedReceivedSize);
        }
    });
}

#pragma mark - 获取本地路径的方法
- (NSString *)filmElementLocalPath:(NSString *)filmElementId  ofType:(NSString *)ext{
    return ITTPathForAVMResource([NSString stringWithFormat:@"%@/%@.%@",kAVMCurrentUserId,filmElementId,ext]);
}

- (NSString *)filmElmentNetPath:(NSString *)filmElementId ofType:(NSString *)ext userId:(NSString *)userId {
    if (kStringIsEmpty(userId)) {
        userId = kAVMCurrentUserId;
    }
    return [AVMFilePathManager getElementContentWithElementId:filmElementId elementType:ext userId:userId serverUpdateId:nil];
}

- (BOOL)checkFilmElementLocalFileIsExist:(NSString *)localPath {
    BOOL isExist = NO;
    isExist = [self.fileManager fileExistsAtPath:localPath];
    return isExist;
}

@end
