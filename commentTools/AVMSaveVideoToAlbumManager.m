//
//  AVMSaveVideoToAlbumManager.m
//  AVM
//
//  Created by sunzongtang on 2017/6/19.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMSaveVideoToAlbumManager.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

static NSString* kDownFilmAlbumName = @"AVM";

@implementation AVMSaveVideoToAlbumManager

+ (void)SaveVideoToAlbumWithVideoUrl:(NSURL *)videoUrl Sussess:(void (^)(NSURL *albutmUrl))Sussess Fail:(void (^)(BOOL hasNoAuth))Fail {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            [self reloadGroupListWithAssetsLibraryWithUrl:videoUrl Sussess:^(NSURL *assetUrl) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (Sussess) {
                        Sussess(assetUrl);
                    }
                });
            } Fail:^(BOOL hasNoAuth) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (Fail) {
                        Fail(hasNoAuth);
                    }
                });
            }];
        }else {
            [self reloadGroupListWithPhotoKitWithVideoUrl:videoUrl Sussess:^(NSURL *albutmUrl){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (Sussess) {
                        Sussess(albutmUrl);
                    }
                });
            } Fail:^(BOOL hasNoAuth) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (Fail) {
                        Fail(hasNoAuth);
                    }
                });
            }];
        }
    });
}

#pragma mark - ios 7
+ (void)reloadGroupListWithAssetsLibraryWithUrl:(NSURL *)videoUrl Sussess:(void(^)(NSURL *assetUrl))sussess Fail:(void(^)(BOOL hasNoAuth))fail{
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    switch (author) {
        case ALAuthorizationStatusNotDetermined:{
            
        }
            break;
            
        case ALAuthorizationStatusRestricted:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:textTips message:kText_Photo_Unavailable delegate:nil cancelButtonTitle:textIKnow otherButtonTitles: nil] show];
                if (fail) {
                    fail(YES);
                }
            });
            
        }
            break;
        case ALAuthorizationStatusDenied:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:textTips message:kText_Photo_Unavailable delegate:nil cancelButtonTitle:textIKnow otherButtonTitles: nil] show];
                if (fail) {
                    fail(YES);
                }
            });
            
        }
            break;
        case ALAuthorizationStatusAuthorized:{
            NSLog(@"有权限啊！ALAuthorizationStatusAuthorized");
            [self createAlbumInPhoneAlbumWithUrl:videoUrl Sussess:^(NSURL *assetUrl) {
                
                if (sussess) {
                    sussess(assetUrl);
                }
            } Fail:^{
                if (fail) {
                    fail(NO);
                }
            }];
        }
            break;
            
        default:
            break;
    }
    
}

+ (void)createAlbumInPhoneAlbumWithUrl:(NSURL *)videoUrl Sussess:(void(^)(NSURL *assetUrl))sussess Fail:(void(^)(void))fail{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    NSMutableArray *groups=[[NSMutableArray alloc]init];
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop)
    {
        
        if (group)
        {
            NSLog(@"%@",[group valueForProperty:ALAssetsGroupPropertyName]);
            [groups addObject:group];
        }
        else
        {
            BOOL haveTargetGroup = NO;
            
            for (ALAssetsGroup *gp in groups)
            {
                NSString *name =[gp valueForProperty:ALAssetsGroupPropertyName];
                
                if ([name isEqualToString:kDownFilmAlbumName])
                {
                    haveTargetGroup = YES;
                    [self savealbumIdentifier:[gp valueForProperty:ALAssetsGroupPropertyName]];
                    
                    
                    [self saveToAlbumWithMetadata:nil videoUrl:videoUrl customAlbumName:[[NSUserDefaults standardUserDefaults] objectForKey:@"collection"] completionBlock:^(NSURL *assetUrl) {
                        
                        //这里可以创建添加成功的方法
                        sussess(assetUrl);
                    }
                                     failureBlock:^(NSError *error)
                     {
                         fail();
                     }];
                    
                }
            }
            
            if (!haveTargetGroup)
            {
                //do add a group named "XXXX"
                [assetsLibrary addAssetsGroupAlbumWithName:kDownFilmAlbumName
                                               resultBlock:^(ALAssetsGroup *group)
                 {
                     [groups addObject:group];
                     [self savealbumIdentifier:[group valueForProperty:ALAssetsGroupPropertyName]];
                     
                     
                     [self saveToAlbumWithMetadata:nil videoUrl:videoUrl customAlbumName:[[NSUserDefaults standardUserDefaults] objectForKey:@"collection"] completionBlock:^(NSURL *assetUrl) {
                         
                         //这里可以创建添加成功的方法
                         sussess(assetUrl);
                     }failureBlock:^(NSError *error) {
                         fail();
                     }];
                 }
                 
                                              failureBlock:nil];
                haveTargetGroup = YES;
            }
        }
        
    };
    
    //创建相簿
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:listGroupBlock failureBlock:nil];
    
    
}

+ (void)saveToAlbumWithMetadata:(NSDictionary *)metadata
                       videoUrl:(NSURL *)videoUrl
                customAlbumName:(NSString *)customAlbumName
                completionBlock:(void (^)(NSURL *assetUrl))completionBlock
                   failureBlock:(void (^)(NSError *error))failureBlock
{
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    void (^AddAsset)(ALAssetsLibrary *, NSURL *) = ^(ALAssetsLibrary *assetsLibrary, NSURL *assetURL) {
        [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:customAlbumName]) {
                    [group addAsset:asset];
                    if (completionBlock) {
                        completionBlock(assetURL);
                    }
                }
            } failureBlock:^(NSError *error) {
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        } failureBlock:^(NSError *error) {
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    };
    
    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:videoUrl completionBlock:^(NSURL *assetURL, NSError *error) {
        if (customAlbumName) {
            __weak id alssetsLibraryWeak = assetsLibrary;
            [assetsLibrary addAssetsGroupAlbumWithName:customAlbumName resultBlock:^(ALAssetsGroup *group) {
                if (group) {
                    [alssetsLibraryWeak assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        [group addAsset:asset];
                        if (completionBlock) {
                            completionBlock(assetURL);
                        }
                    } failureBlock:^(NSError *error) {
                        if (failureBlock) {
                            failureBlock(error);
                        }
                    }];
                } else {
                    AddAsset(alssetsLibraryWeak, assetURL);
                }
            } failureBlock:^(NSError *error) {
                AddAsset(alssetsLibraryWeak, assetURL);
            }];
        } else {
            if (completionBlock) {
                completionBlock(assetURL);
            }
        }
    }];
}


#pragma mark -ios 8 -Later

+ (void)reloadGroupListWithPhotoKitWithVideoUrl:(NSURL *)videoUrl Sussess:(void(^)(NSURL *albutmUrl))sussess Fail:(void(^)(BOOL hasNoAuth))fail{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusNotDetermined:
            {
            }
                break;
            case PHAuthorizationStatusRestricted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:textTips message:kText_Photo_Unavailable delegate:nil cancelButtonTitle:textIKnow otherButtonTitles: nil] show];
                    NSLog(@"PHAuthorizationStatusRestricted");
                });
                if (fail) {
                    fail(YES);
                }
                
            }
                break;
            case PHAuthorizationStatusDenied:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:textTips message:kText_Photo_Unavailable delegate:nil cancelButtonTitle:textIKnow otherButtonTitles: nil] show];
                    NSLog(@"PHAuthorizationStatusDenied");
                });
                if (fail) {
                    fail(YES);
                }
            }
                break;
            case PHAuthorizationStatusAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"PHAuthorizationStatusAuthorized");
                    [self hasAuthorizedReloadPhotoGroupWithVideoUrl:videoUrl Sussess:^(NSURL *albutmUrl){
                        if (sussess) {
                            sussess(albutmUrl);
                        }
                    } Fail:^{
                        if (fail) {
                            fail(NO);
                        }
                    }];
                });
            }
                break;
                
            default:
                break;
        }
    }];
}

+ (void)hasAuthorizedReloadPhotoGroupWithVideoUrl:(NSURL *)videoUrl Sussess:(void(^)(NSURL *albutmUrl))sussess Fail:(void(^)(void))fail{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeHiddenAssets = NO;
    options.includeAllBurstAssets = NO;
    BOOL iscameraAlbumExist = NO;
    
    
    
    //获取相机相册
    PHFetchResult *cameraAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    for (NSInteger i = 0; i < cameraAlbums.count; i++) {
        // 获取一个相册（PHAssetCollection）
        
        PHCollection *collection = cameraAlbums[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            NSLog(@"name = %@",assetCollection.localizedTitle);
            if ([assetCollection.localizedTitle isEqualToString:assetCollection.localIdentifier]) {
                iscameraAlbumExist = YES;
                [self savealbumIdentifier:assetCollection.localizedTitle];
            }
        }
    }
    
    //获取用户自己创建的相册
    PHFetchResult *itunesAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:options];
    for (NSInteger i = 0; i < itunesAlbums.count; i++) {
        // 获取一个相册（PHAssetCollection）
        PHCollection *collection = itunesAlbums[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            NSLog(@"name = %@",assetCollection.localizedTitle);
            if ([assetCollection.localizedTitle isEqualToString:kDownFilmAlbumName]) {
                iscameraAlbumExist = YES;
                [self savealbumIdentifier:assetCollection.localIdentifier];
                
            }
        }
    }
    
    //获取iteunes相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:options];
    for (NSInteger i = 0; i < userAlbums.count; i++) {
        // 获取一个相册（PHAssetCollection）
        PHCollection *collection = userAlbums[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            NSLog(@"name = %@",assetCollection.localizedTitle);
            if ([assetCollection.localizedTitle isEqualToString:kDownFilmAlbumName]) {
                iscameraAlbumExist = YES;
                [self savealbumIdentifier:assetCollection.localIdentifier];
            }
        }
    }
    
    
    
    PHPhotoLibrary* photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    __block PHObjectPlaceholder *placeholderAsset = nil;
    [photoLibrary performChanges:^{
        PHFetchResult* fetchCollectionResult;
        __block PHAssetCollectionChangeRequest* collectionRequest;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *albumIdentifier = [ud objectForKey:@"collection"];
        if(iscameraAlbumExist){
            fetchCollectionResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumIdentifier] options:nil];
            PHAssetCollection* exisitingCollection = fetchCollectionResult.firstObject;
            collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:exisitingCollection];
            
        }else{
            fetchCollectionResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[kDownFilmAlbumName] options:nil];
            // Create a new album
            if ( !fetchCollectionResult || fetchCollectionResult.count==0 ){
                collectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kDownFilmAlbumName];
                [self savealbumIdentifier:collectionRequest.placeholderForCreatedAssetCollection.localIdentifier];
            }
        }
        
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
        [collectionRequest addAssets:@[createAssetRequest.placeholderForCreatedAsset]];
        placeholderAsset = createAssetRequest.placeholderForCreatedAsset;
        
    } completionHandler:^(BOOL success, NSError *error){
        if (success) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[placeholderAsset.localIdentifier] options:nil];
            PHAsset *phAsset = fetchResult.firstObject;
            
            PHVideoRequestOptions *options = [PHVideoRequestOptions new];
            options.version = PHVideoRequestOptionsVersionOriginal;
            PHImageManager *manager = [PHImageManager defaultManager];
            [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                AVURLAsset *urlAsset = (AVURLAsset *)asset;
                sussess(urlAsset.URL);
            }];

        }else{
            fail();
        }
    }];
    
}

+ (void)savealbumIdentifier:(NSString *)ID{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:ID forKey:@"collection"];
    [ud synchronize];
}

@end
