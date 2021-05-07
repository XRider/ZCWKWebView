//
//  ZCWebViewController.m
//  iOSProject
//
//  Created by 肖志超 on 2021/4/26.
//

#import "ZCWebViewController.h"
#import <WebKit/WebKit.h>
#import "ViewController.h"


//wkwebview内存不释放的问题

@interface WeakScriptMessageHandler : NSObject<WKScriptMessageHandler>
//WKScriptMessageHandler 这个协议专门用来处理JavaScript调用Native方法。
@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

-(instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;

@end

@implementation WeakScriptMessageHandler

-(instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate
{
    if (self = [super init]) {
        _scriptDelegate = delegate;
    }
    return self;
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([self.scriptDelegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

@interface ZCWebViewController ()<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) UIProgressView *progressView;//进度条

@end

@implementation ZCWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //设置导航栏按钮
    [self setupNavigationItem];
    
    [self.view addSubview:self.webView];
    //添加在self.view上当手机连接热点时有UI bug。
//    [self.view addSubview:self.progressView];
    [kKeyWindow addSubview:self.progressView];
    
    //添加监测网页title变化的观察者（self） 被观察者（self.webView）
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    //添加监测网页加载进度变化的观察者
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}
#pragma mark - 设置Navigation
-(void)setupNavigationItem
{
    UIBarButtonItem *ocToJs = [[UIBarButtonItem alloc] initWithTitle:@"OC调用JS" style:UIBarButtonItemStyleDone target:self action:@selector(OCtoJS)];
    self.navigationItem.rightBarButtonItem = ocToJs;
    
//    UIBarButtonItem *jump = [[UIBarButtonItem alloc] initWithTitle:@"跳转" style:UIBarButtonItemStyleDone target:self action:@selector(jump)];
//    self.navigationItem.leftBarButtonItem = jump;
    
    
    self.navigationController.navigationBar.translucent = YES;
}

-(void)jump
{
    [self.navigationController pushViewController:[[ViewController alloc] init] animated:YES];
}

-(void)dealloc
{
    //移除注册的JS方法
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"JStoOCNoParams"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"JStoOCWithParams"];
    //移除观察者
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - 观察者的监听方法
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"title"] && object == _webView) {
        self.title = change[@"new"];
    }else if ([keyPath isEqualToString:@"estimatedProgress"] && object == _webView){
        self.progressView.progress = _webView.estimatedProgress;
        if (_webView.estimatedProgress >= 1.0f) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.progress = 0.0f;
            });
        }
    }
}

#pragma mark - Native调用JS方法
-(void)OCtoJS
{
    //action:changeColor 更换背景颜色
    [_webView evaluateJavaScript:[[NSString alloc] initWithFormat:@"changeColor('')"] completionHandler:nil];
    
    //id:pictureId  action:changePicture path:图片路径 根据id更换图片
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"girl.png" ofType:nil];
    NSString *jsString = [[NSString alloc] initWithFormat:@"changePicture('pictureId','%@')",imgPath];
    [_webView evaluateJavaScript:jsString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        NSLog(@"完成更换图片");
    }];
    
    //改变字体大小
    NSString *jsFont = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'", arc4random()%99 + 20];
    [_webView evaluateJavaScript:jsFont completionHandler:nil];
}


#pragma mark - 处理JS调用Native方法的代理方法。通过message.name来区分。
//注意：遵守WKScriptMessageHandler协议，代理由WKUserContentController设置
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSString *actionName = message.name;
    NSDictionary *params = message.body;
    if (actionName.length >0) {
        if ([actionName isEqualToString:@"JStoOCNoParams"]) {
            
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"无参数" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
            [alertC addAction:action];
            [self presentViewController:alertC animated:YES completion:nil];
            
            
        }else if ([actionName isEqualToString:@"JStoOCWithParams"]){
            
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:params[@"params"] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
            [alertC addAction:action];
            [self presentViewController:alertC animated:YES completion:nil];
            
            
        }
    }
}

#pragma mark - Getter
-(UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 2)];
        _progressView.tintColor = [UIColor blueColor];//加载进度颜色
        _progressView.trackTintColor = [UIColor colorWithWhite:1 alpha:0];//默认颜色
    }
    return _progressView;
}

-(WKWebView *)webView
{
    if (!_webView) {
        //创建网页配置对象
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        //创建设置对象
        WKPreferences *preferences = [[WKPreferences alloc] init];
        //最小字体大小 当将javaScriptEnable
        preferences.minimumFontSize = 0;
        //设置是否支持javascript,默认是YES。
        if (@available(iOS 14.0, *)) {
            //iOS13后新增的类,allowsContentJavaScript是iOS14后新增的方法。
            WKWebpagePreferences *webpagePreferences = [[WKWebpagePreferences alloc] init];
            webpagePreferences.allowsContentJavaScript = YES;
            config.defaultWebpagePreferences = webpagePreferences;
        }else{
            preferences.javaScriptEnabled = YES;
        }
        //是否允许不经过用户交互由JavaScript自动打开窗口，默认为NO
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        config.preferences = preferences;
        //YES是使用h5的视频播放器在线播放，NO是使用原生播放器全屏播放，默认为NO
        config.allowsInlineMediaPlayback = YES;
        //设置视频是否需要手动播放，设置为NO会自动播放。
        config.requiresUserActionForMediaPlayback = YES;
        //设置是否允许画中画播放，默认为YES
        config.allowsPictureInPictureMediaPlayback = YES;
        //设置请求的User-Agent信息中的应用程序名称 iOS9后可用
        config.applicationNameForUserAgent = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        
        
        WeakScriptMessageHandler *weakScriptMessageHandler = [[WeakScriptMessageHandler alloc] initWithDelegate:self];
        //主要用来管理native与JavaScript的交互管理
        WKUserContentController * userContentC = [[WKUserContentController alloc] init];
        //注册name为JStoOCNoParams的js方法，设置处理接收JS方法的对象self
        [userContentC addScriptMessageHandler:weakScriptMessageHandler name:@"JStoOCNoParams"];
        //注册name为JStoOCWithParams的js方法，设置处理接收JS方法的对象self
        [userContentC addScriptMessageHandler:weakScriptMessageHandler name:@"JStoOCWithParams"];
        
        config.userContentController = userContentC;
        
        //适配字体大小
        NSString *jSString = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
        //用于JS注入
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [config.userContentController addUserScript:userScript];
        
        //设置配置对象
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREENH_HEIGHT) configuration:config];
        //UI 代理
        _webView.UIDelegate = self;
        //navigation delegate
        _webView.navigationDelegate = self;
        //是否允许手势左滑返回上一级, 默认为NO
        _webView.allowsBackForwardNavigationGestures = YES;
        //可返回的页面列表, 存储已打开过的网页
        WKBackForwardList *backList = [_webView backForwardList];
        NSLog(@"可返回页面列表：%@",backList);
        //加载URL
//        NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
//        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
//        [_webView loadRequest:request];
        
        //加载本地HTML
        NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"JStoOC" ofType:@"html"];
        NSString *htmlString = [[NSString alloc] initWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
        [_webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
    return _webView;
}

/**
 * UIDelegate 主要处理JS脚本、确认框、警告框等
 * NaviagationDelegate 主要处理跳转、加载处理等操作
 */

#pragma mark - NavigationDelegate

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    //加载结束
}

-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    //加载内容开始返回时
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    //开始加载
}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    //加载时发生错误
    [self.progressView setProgress:0.0 animated:YES];
}

-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    //接收到服务器跳转请求即服务重定向时调用
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    //提交时发生错误
    [self.progressView setProgress:0.0 animated:YES];
}

//根据webview对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlString = navigationAction.request.URL.absoluteString;
    
    NSString *htmlHeadString = @"github://callName_";
    
    if ([urlString hasPrefix:htmlHeadString]) {
        //进行客户端代码
        
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"是否跳转到该页面？" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //Safari打开url
                NSURL *url = [NSURL URLWithString:[urlString stringByReplacingOccurrencesOfString:@"github://callName_?" withString:@""]];
                
                [[UIApplication sharedApplication] openURL:url];
            });
           
            
        }];
        
        [alertC addAction:cancelAction];
        [alertC addAction:okAction];
        
        [self presentViewController:alertC animated:YES completion:nil];
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

//根据客户端收到的服务器响应头信息和Response相关信息来决定是否跳转
-(void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSString *urlString = navigationResponse.response.URL.absoluteString;
    NSLog(@"%@",urlString);
    //根据URL来进行拦截或者阻止跳转
    decisionHandler(WKNavigationResponsePolicyAllow);//允许跳转
    
//    decisionHandler(WKNavigationResponsePolicyCancel);//不允许跳转
}

//需要相应身份验证是调用 在block中需要传入用户身份凭证
-(void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    //用户身份信息
    NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:@"User" password:@"Password" persistence:NSURLCredentialPersistenceNone];
    //为challenge的发送方提供credential
    [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];

    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    
}

#pragma mark - UI Delegate

-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    
}

-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    
}

-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    
}

-(WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    return nil;
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
