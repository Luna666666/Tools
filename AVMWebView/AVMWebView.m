//
//  AVMWebView.m
//  AVM
//
//  Created by sunzongtang on 2017/9/1.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMWebView.h"
#import <WebKit/WebKit.h>
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"
#define isCanWebKit NSClassFromString(@"WKWebView")

#pragma mark - AVMWKWebView
@interface AVMWKWebView : WKWebView<AVMWebViewProtocol>

@end

#pragma mark - AVMUIWebView
@interface AVMUIWebView : UIWebView<AVMWebViewProtocol>

@end

#pragma mark -AVMWebJS
@interface AVMWebViewJS : NSObject
+(NSString *)scalesPageToFitJS;
+(NSString *)imgsElement;
@end

#pragma mark -AVMWebView
@interface AVMWebView () <WKNavigationDelegate,UIWebViewDelegate,UIScrollViewDelegate,NJKWebViewProgressDelegate>
@property (nonatomic,strong)  id<AVMWebViewProtocol>   webView;
@property (nonatomic, strong) UILabel                 *supportLabel;
@property (nonatomic,strong)  NJKWebViewProgressView  *progressView; //进度条
@property (nonatomic,copy)    NSString                *title;
@property (nonatomic,assign)  double                   estimatedProgress;
@property (nonatomic,assign)  float                    pageHeight;
@property (nonatomic,copy)    NJKWebViewProgress      *webViewProgress;
@property (nonatomic,strong)  UIActivityIndicatorView *indicatorView;
@property (nonatomic,strong)  AVMWebViewConfiguration *configuration;
@property (nonatomic,copy)    NSArray                 *images;

@end
@implementation AVMWebView

- (void)destory {
    self.delegate = nil;
    
    [_webView loadHTMLString:@"" baseURL:nil];
    [_webView stopLoading];
    
    if (!isCanWebKit) {
        [(AVMUIWebView *)_webView setDelegate:nil];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitDiskImageCacheEnabled"];//自己添加的，原文没有提到。
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitOfflineWebApplicationCacheEnabled"];//自己添加的，原文没有提到。
        [[NSUserDefaults standardUserDefaults] synchronize];

        [(AVMUIWebView *)_webView setDelegate:nil];
        [(AVMUIWebView *)_webView removeFromSuperview];
    }else {
        //移除代理，否则在iOS8 上会报错
//[WKScrollViewDelegateForwarder release]: message sent to deallocated instance 
        [(AVMWKWebView *)_webView setUIDelegate:nil];
        [(AVMWKWebView *)_webView setNavigationDelegate:nil];
        [[(AVMWKWebView *)_webView scrollView] setDelegate:nil];
        [(AVMWKWebView *)_webView removeFromSuperview];
    }
    [self removeObserverWebKit];
    
    [_progressView removeFromSuperview];
    _progressView = nil;
    
    _webView = nil;
}


#pragma mark -初始化
+(AVMWebView *)webViewWithFrame:(CGRect)frame configuration:(AVMWebViewConfiguration *)configuration
{
    return [[self alloc] initWithFrame:frame configuration:configuration];
}
-(instancetype)initWithFrame:(CGRect)frame configuration:(AVMWebViewConfiguration *)configuration;
{
    self = [super initWithFrame:frame];
    if (self) {
        _configuration = configuration;
        self.supportLabel.hidden = YES;
        self.progressView.hidden = NO;
        if (isCanWebKit) {
            if (configuration) {
                WKWebViewConfiguration *webViewconfiguration = [[WKWebViewConfiguration alloc] init];
                webViewconfiguration.allowsInlineMediaPlayback = configuration.allowsInlineMediaPlayback;
                webViewconfiguration.mediaPlaybackRequiresUserAction = configuration.mediaPlaybackRequiresUserAction;
                webViewconfiguration.mediaPlaybackAllowsAirPlay = configuration.mediaPlaybackAllowsAirPlay;
                webViewconfiguration.suppressesIncrementalRendering = configuration.suppressesIncrementalRendering;
                WKUserContentController *wkUController = [[WKUserContentController alloc] init];
                if (!configuration.scalesPageToFit) {
                    NSString *jScript = [AVMWebViewJS scalesPageToFitJS];
                    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                    [wkUController addUserScript:wkUScript];
                    WKUserScript *wkScript1 = [[WKUserScript alloc] initWithSource:[AVMWebViewJS imgsElement] injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                    [wkUController addUserScript:wkScript1];
                }
                if (configuration.captureImage) {
                    NSString *jScript = [AVMWebViewJS imgsElement];
                    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                    [wkUController addUserScript:wkUScript];
                    
                }
                webViewconfiguration.userContentController = wkUController;
                _webView = (id)[[AVMWKWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) configuration:webViewconfiguration];
            }
            else{
                _webView = (id)[[AVMWKWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
            }
            [(AVMWKWebView *)_webView setNavigationDelegate:self];
            [(AVMWKWebView *)_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            [(AVMWKWebView *)_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            
        }
        else{
            _webView = (id)[[AVMUIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
            if (configuration) {
                [(AVMUIWebView *)_webView setAllowsInlineMediaPlayback:configuration.allowsInlineMediaPlayback];
                [(AVMUIWebView *)_webView setMediaPlaybackRequiresUserAction:configuration.mediaPlaybackRequiresUserAction];
                [(AVMUIWebView *)_webView setMediaPlaybackAllowsAirPlay:configuration.mediaPlaybackAllowsAirPlay];
                [(AVMUIWebView *)_webView setSuppressesIncrementalRendering:configuration.suppressesIncrementalRendering];
                [(AVMUIWebView *)_webView setScalesPageToFit:configuration.scalesPageToFit];
            }
            _webViewProgress = [[NJKWebViewProgress alloc] init];
            [(AVMUIWebView *)_webView setDelegate:_webViewProgress];
            _webViewProgress.webViewProxyDelegate = self;
            _webViewProgress.progressDelegate = self;
            
        }
        if (configuration.loadingHUD) {
            [(UIView *)_webView addSubview:self.indicatorView];
        }
        _webView.scrollView.delegate = self;
        _webView.scrollView.backgroundColor = [UIColor clearColor];
        [(UIView *)_webView setOpaque:NO];
        [(UIView *)_webView setBackgroundColor:[UIColor clearColor]];
        [(UIView *)_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self addSubview:(UIView *)_webView];
        
        [self bringSubviewToFront:self.progressView];
    }
    return self;
}
-(UIScrollView *)scrollView
{
    return _webView.scrollView;
}
- (void)loadRequest:(NSURLRequest *)request
{
    [_webView loadRequest:request];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    [_webView loadHTMLString:string baseURL:baseURL];
}
- (void)reload
{
    [_webView reload];
}
- (void)stopLoading
{
    [_webView stopLoading];
}
- (void)goBack
{
    [_webView goBack];
}
- (void)goForward
{
    [_webView goForward];
}
-(BOOL)canGoBack
{
    return _webView.canGoBack;
}
-(BOOL)canGoForward
{
    return _webView.canGoForward;
}
-(BOOL)isLoading
{
    return _webView.isLoading;
}
- (void)avm_evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^)(id, NSError*))completionHandler
{
    [_webView avm_evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (void)setEstimatedProgress:(double)estimatedProgress {
    _estimatedProgress = estimatedProgress;
    
    if (!_progressView) {
        return;
    }
    if (estimatedProgress < 1.0) {
        [self.progressView setProgress:estimatedProgress animated:YES];
    }else{
        [self.progressView setProgress:1.0 animated:NO];
    }
}

#pragma mark - NJKWebViewProgressDelegate
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    self.estimatedProgress = progress;
}
#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"title"]) {
        self.title = change[NSKeyValueChangeNewKey];
    }
    else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.estimatedProgress = [change[NSKeyValueChangeNewKey] doubleValue];
    }
}
#pragma mark - WKWebViewNavigation Delegate
- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    [self bringSubviewToFront:_progressView];
    BOOL load = YES;
    if ([navigationAction.request isKindOfClass:[NSMutableURLRequest class]]) {
        [(NSMutableURLRequest *)navigationAction.request setTimeoutInterval:30];
    }
    if ([self.delegate respondsToSelector:@selector(avm_webView:shouldStartLoadWithRequest:navigationType:)]) {
        load = [self.delegate avm_webView:(AVMWebView<AVMWebViewProtocol>*)self shouldStartLoadWithRequest:navigationAction.request navigationType:[self navigationTypeConvert:navigationAction.navigationType]];
    }
    if (load) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    [_indicatorView startAnimating];
    if ([self.delegate respondsToSelector:@selector(avm_webViewDidStartLoad:)]) {
        [self.delegate avm_webViewDidStartLoad:(AVMWebView<AVMWebViewProtocol>*)self];
    }
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    [_indicatorView stopAnimating];
    self.title = webView.title;
    self.supportLabel.text = [NSString stringWithFormat:@"此网页由 %@ 提供",webView.URL.host];
    
    if ([self.delegate respondsToSelector:@selector(avm_webViewDidFinishLoad:)]) {
        [self.delegate avm_webViewDidFinishLoad:(AVMWebView<AVMWebViewProtocol>*)self];
    }
    
    [self avm_evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id heitht, NSError *error) {
        if (!error) {
            self.pageHeight = [heitht floatValue];
        }
    }];
    if (_configuration.captureImage) {
        [self avm_evaluateJavaScript:@"imgsElement()" completionHandler:^(NSString * imgs, NSError *error) {
            if (!error && imgs.length) {
                _images = [imgs componentsSeparatedByString:@","];
            }
        }];
    }
    
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(avm_webView:didFailLoadWithError:)]) {
        [self.delegate avm_webView:(AVMWebView<AVMWebViewProtocol>*)self didFailLoadWithError:error];
    }
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(avm_webView:didFailLoadWithError:)]) {
        [self.delegate avm_webView:(AVMWebView<AVMWebViewProtocol>*)self didFailLoadWithError:error];
    }
}

#pragma mark - UIWebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [self bringSubviewToFront:_progressView];
    
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        [(NSMutableURLRequest *)request setTimeoutInterval:30];
    }
    
    BOOL isLoad = YES;
    if ([self.delegate respondsToSelector:@selector(avm_webView:shouldStartLoadWithRequest:navigationType:)]) {
        isLoad = [self.delegate avm_webView:(AVMWebView<AVMWebViewProtocol>*)self shouldStartLoadWithRequest:request navigationType:[self navigationTypeConvert:navigationType]];
    }
    return isLoad;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_indicatorView startAnimating];
    if ([self.delegate respondsToSelector:@selector(avm_webViewDidStartLoad:)]) {
        [self.delegate avm_webViewDidStartLoad:(AVMWebView<AVMWebViewProtocol>*)self];
    }
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_indicatorView stopAnimating];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.supportLabel.text = [NSString stringWithFormat:@"此网页由 %@ 提供",webView.request.URL.host];
    
    if ([self.delegate respondsToSelector:@selector(avm_webViewDidFinishLoad:)]) {
        [self.delegate avm_webViewDidFinishLoad:(AVMWebView<AVMWebViewProtocol> *)self];
    }
    [self avm_evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id heitht, NSError *error) {
        if (!error) {
            self.pageHeight = [heitht floatValue];
        }
    }];
    if (_configuration.captureImage) {
        [self avm_evaluateJavaScript:[AVMWebViewJS imgsElement] completionHandler:nil];
        [self avm_evaluateJavaScript:@"imgsElement()" completionHandler:^(NSString * imgs, NSError *error) {
            if (!error && imgs.length) {
                _images = [imgs componentsSeparatedByString:@","];
            }
        }];
    }
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(avm_webView:didFailLoadWithError:)]) {
        [self.delegate avm_webView:(AVMWebView<AVMWebViewProtocol>*)self didFailLoadWithError:error];
    }
}

#pragma mark - scrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //下拉隐藏网页提供方
    (scrollView.contentOffset.y >= -30) ? (_supportLabel.hidden = YES) : (_supportLabel.hidden = NO);
}

#pragma mark - Init
-(UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

- (NJKWebViewProgressView *)progressView{
    if (_progressView == nil) {
        CGFloat progressH = 2.f;
        NJKWebViewProgressView *progressView = [[NJKWebViewProgressView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), progressH)];
        _progressView = progressView;
        
        [self addSubview:_progressView];
    }
    return _progressView;
}

- (UILabel *)supportLabel{
    if (_supportLabel == nil) {
        _supportLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - 2 * 50, 50)];
        //网页来源提示居中
        CGPoint center = _supportLabel.center;
        center.x = self.frame.size.width / 2;
        _supportLabel.center = center;
        
        _supportLabel.font = [UIFont systemFontOfSize:12];
        _supportLabel.textAlignment = NSTextAlignmentCenter;
        _supportLabel.textColor = [UIColor lightGrayColor];
        _supportLabel.numberOfLines = 0;

        [self sendSubviewToBack:_supportLabel];
        [self addSubview:_supportLabel];
    }
    return _supportLabel;
}

#pragma mark -Privity
-(NSInteger)navigationTypeConvert:(NSInteger)type;
{
    NSInteger navigationType;
    if (isCanWebKit) {
        switch (type) {
            case WKNavigationTypeLinkActivated:
                navigationType = AVMWebViewNavigationLinkClicked;
                break;
            case WKNavigationTypeFormSubmitted:
                navigationType = AVMWebViewNavigationFormSubmitted;
                break;
            case WKNavigationTypeBackForward:
                navigationType = AVMWebViewNavigationBackForward;
                break;
            case WKNavigationTypeReload:
                navigationType = AVMWebViewNavigationReload;
                break;
            case WKNavigationTypeFormResubmitted:
                navigationType = AVMWebViewNavigationResubmitted;
                break;
            case WKNavigationTypeOther:
                navigationType = AVMWebViewNavigationOther;
                break;
            default:
                navigationType = AVMWebViewNavigationOther;
                break;
        }
    }
    else{
        switch (type) {
            case UIWebViewNavigationTypeLinkClicked:
                navigationType = AVMWebViewNavigationLinkClicked;
                break;
            case UIWebViewNavigationTypeFormSubmitted:
                navigationType = AVMWebViewNavigationFormSubmitted;
                break;
            case UIWebViewNavigationTypeBackForward:
                navigationType = AVMWebViewNavigationBackForward;
                break;
            case UIWebViewNavigationTypeReload:
                navigationType = AVMWebViewNavigationReload;
                break;
            case UIWebViewNavigationTypeFormResubmitted:
                navigationType = AVMWebViewNavigationResubmitted;
                break;
            case UIWebViewNavigationTypeOther:
                navigationType = AVMWebViewNavigationOther;
                break;
                
            default:
                navigationType = AVMWebViewNavigationOther;
                break;
        }
    }
    return navigationType;
}
-(void)layoutSubviews
{
    _indicatorView.frame = CGRectMake(0, 0, 20, 20);
    _indicatorView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    [super layoutSubviews];
}
-(void)setNeedsLayout
{
    [super setNeedsLayout];
    [(UIView *)_webView setNeedsLayout];
}
-(void)dealloc
{
    kNSLog_dealloc_class;
    if (_webView) {
        [self destory];
    }
}

- (void)removeObserverWebKit {
    if (isCanWebKit) {
        [(AVMWebView *)_webView removeObserver:self forKeyPath:@"title"];
        [(AVMWebView *)_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    }
}

@end


@implementation AVMWKWebView

-(void)avm_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    [self evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}
@end

@implementation AVMUIWebView
-(void)avm_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSString* result = [self stringByEvaluatingJavaScriptFromString:javaScriptString];
    if (completionHandler) {
        completionHandler(result,nil);
    }
}
@end

@implementation AVMWebViewConfiguration

+ (instancetype)defaultWebViewConfiguration {
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allowsInlineMediaPlayback       = NO;
        _mediaPlaybackRequiresUserAction = YES;
        _mediaPlaybackAllowsAirPlay      = YES;
        _suppressesIncrementalRendering  = NO;
    }
    return self;
}
@end

@implementation AVMWebViewJS
+(NSString *)scalesPageToFitJS
{
    return @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
}
+(NSString *)imgsElement
{
    return @"function imgsElement(){\
    var imgs = document.getElementsByTagName(\"img\");\
    var imgScr = '';\
    for(var i=0;i<imgs.length;i++){\
    imgs[i].onclick=function(){\
    document.location='img'+this.src;\
    };\
    if(i == imgs.length-1){\
    imgScr = imgScr + imgs[i].src;\
    break;\
    }\
    imgScr = imgScr + imgs[i].src + ',';\
    };\
    return imgScr;\
    };";
}

@end
