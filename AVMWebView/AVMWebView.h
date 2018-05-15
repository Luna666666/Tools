//
//  AVMWebView.h
//  AVM
//
//  Created by sunzongtang on 2017/9/1.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,AVMWebViewNavigationType) {
    AVMWebViewNavigationLinkClicked,
    AVMWebViewNavigationFormSubmitted,
    AVMWebViewNavigationBackForward,
    AVMWebViewNavigationReload,
    AVMWebViewNavigationResubmitted,
    AVMWebViewNavigationOther = -1
};
@class AVMWebView;
@protocol AVMWebViewProtocol <NSObject>
@optional
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;
// use KVO
@property (nonatomic, readonly, copy) NSString *title;
// use KVO
@property (nonatomic, readonly) double estimatedProgress;
// use KVO
@property (nonatomic, readonly) float pageHeight;
@property (nonatomic, readonly, copy) NSArray * images;  // webview's images when captureImage is NO images = nil
- (void)loadRequest:(NSURLRequest *)request;
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;
- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;
- (void)avm_evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^)(id result, NSError* error))completionHandler;
@end

@protocol AVMWebViewDelegate <NSObject>
@optional
- (BOOL)avm_webView:(id<AVMWebViewProtocol>)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(AVMWebViewNavigationType)navigationType;
- (void)avm_webViewDidStartLoad:(id<AVMWebViewProtocol>)webView;
- (void)avm_webViewDidFinishLoad:(id<AVMWebViewProtocol>)webView;
- (void)avm_webView:(id<AVMWebViewProtocol>)webView didFailLoadWithError:(NSError *)error;
@end

@interface AVMWebViewConfiguration : NSObject

+ (instancetype)defaultWebViewConfiguration;

@property (nonatomic) BOOL allowsInlineMediaPlayback; // iPhone Safari defaults to NO. iPad Safari defaults to YES
@property (nonatomic) BOOL mediaPlaybackRequiresUserAction; // iPhone and iPad Safari both default to YES
@property (nonatomic) BOOL mediaPlaybackAllowsAirPlay; // iPhone and iPad Safari both default to YES
@property (nonatomic) BOOL suppressesIncrementalRendering; // iPhone and iPad Safari both default to NO
@property (nonatomic) BOOL scalesPageToFit;
@property (nonatomic) BOOL loadingHUD;          //default NO ,if YES webview will add HUD when loading
@property (nonatomic) BOOL captureImage;        //default NO ,if YES webview will capture all image in content;
@end

@interface AVMWebView : UIView <AVMWebViewProtocol>
+(AVMWebView *)webViewWithFrame:(CGRect)frame configuration:(AVMWebViewConfiguration *)configuration;
@property (nonatomic,weak) id<AVMWebViewDelegate> delegate;

//当时UIWebView的时候，主动销毁
- (void)destory;

//--不可使用--//
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (void)setFrame:(CGRect)frame NS_UNAVAILABLE;
- (void)setBounds:(CGRect)bounds NS_UNAVAILABLE;

@end
