//
//  LNWebViewController.m
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/22.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import "LNWebViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
@interface LNWebViewController () <UIWebViewDelegate>

{
    UIWebView *_webView;
    
    //UIActivityIndicatorView     *_indicatorView;
    
}

@property (nonatomic, strong) NSURL *aUrl;

@end

@implementation LNWebViewController
@synthesize aUrl;
- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [super init]) {
        self.aUrl = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [SVProgressHUD showWithStatus:@"Load..."];
    if (_webView == nil) {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        webView.backgroundColor = [UIColor whiteColor];
        webView.delegate = self;
        [self.view addSubview:webView];
        _webView = webView;
        _webView.dataDetectorTypes = UIDataDetectorTypeLink;
        //UIActivityIndicatorView
//        {
//            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//            _indicatorView.frame = CGRectMake((CGRectGetWidth(self.view.frame) - CGRectGetWidth(_indicatorView.frame)) / 2, (CGRectGetHeight(self.view.frame) - CGRectGetHeight(_indicatorView.frame)) / 2, CGRectGetWidth(_indicatorView.frame), CGRectGetHeight(_indicatorView.frame));
//            [self.view addSubview:_indicatorView];
//            
//        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:self.aUrl];
        
        [_webView loadRequest:request];
    }
    
}

- (void)back
{
    _webView.delegate = nil;
    [_webView stopLoading];
    
    if (self.presentingViewController.presentedViewController == self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)goBack
{
    [_webView stopLoading];
    [_webView goBack];
}

#pragma mark - UIWebView delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    //[_indicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [SVProgressHUD dismiss];
   // [_indicatorView stopAnimating];
    
   
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [SVProgressHUD dismiss];
    //[_indicatorView stopAnimating];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
