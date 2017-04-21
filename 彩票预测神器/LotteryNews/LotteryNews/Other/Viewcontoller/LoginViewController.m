//
//  LoginViewController.m
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/20.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import "LoginViewController.h"
#import "ControlsView.h"
#import "ForgetPsswordVC.h"
#import "WXApiRequestHandler.h"
#import "WXApiManager.h"
#import "NSString+Extension.h"
#import "UIScrollView+UITouch.h"
#import "LNScodeCountBtn.h"
#import "LNLottoryConfig.h"
#import "UserStore.h"
#import "KBRoundedButton.h"
#import "ProgressHUD.h"
typedef NS_ENUM(NSInteger, TYPEVIEW) {
    LN_LOGINVIEW,
    LN_RSGISTVIEW
};
@interface LoginViewController ()<UITextFieldDelegate,WXApiManagerDelegate,LNScodeCountBtnDelegate>
{

    UITextField     *_phoneNumberText;
    UITextField     *_registVerifiText;
    KBRoundedButton        *_registBtn;
    UIImageView     *_registBackImageView;
    UILabel         *_registVerfiLable;
    LNScodeCountBtn *_registVerfiBtn;
}
@property (nonatomic)TYPEVIEW typeView;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WXApiManager sharedManager].delegate = self;
    self.view.backgroundColor = [UIColor whiteColor];
    // 去消息通知中心订阅一条消息（当键盘将要显示时UIKeyboardWillShowNotification）执行相应的方法
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    //隐藏键盘
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
   
    self.view.backgroundColor = [UIColor whiteColor];
    [self setBasice];
    
    // Do any additional setup after loading the view.
}
//适配
- (void)setBasice{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scrollView = [[UIScrollView alloc]init];
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-KScalwh(10));
    }];
    self.scrollView.alwaysBounceVertical=YES;
    self.scrollView.scrollEnabled=YES;
    self.scrollView.showsVerticalScrollIndicator=NO;
    self.viewContent=[[UIView alloc]init];
    [self.scrollView addSubview:self.viewContent];
    [self.viewContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    [self createView:self.viewContent];
    if (self.viewContent.subviews.count>0){
        [self.viewContent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.viewContent.subviews.lastObject).offset(KScalwh(10));
        }];
    }
    
}
- (void)createView:(UIView*)contentView
{ if (_isFirstPage) {
    //返回按钮
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 23*kScreenWidthP, 50*kScreenWidthP, 50*kScreenWidthP)];
    backView.backgroundColor = [UIColor clearColor];
    [contentView addSubview:backView];
    UITapGestureRecognizer *backTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(registBackBtn:)];
    [backView addGestureRecognizer:backTap];
    _registBackImageView = [ControlsView createImageViewFrame:CGRectMake(18*kScreenWidthP, 10*kScreenWidthP, 9*kScreenWidthP, 17*kScreenWidthP) imageName:@"back"];
    [backView addSubview:_registBackImageView];
    
    
}
   
    //logoView
    UIImageView *logoView = [ControlsView createImageViewFrame:CGRectMake(152*kScreenWidthP, 78*kScreenWidthP, 97*kScreenWidthP, 97*kScreenWidthP) imageName:@"Icon-Small"];
    logoView.layer.masksToBounds = YES;
    logoView.layer.cornerRadius = 97*kScreenWidthP/2;
   // [contentView addSubview:logoView];
    
    // 创建手机号TextField以及下面的线
    _phoneNumberText = [[UITextField alloc]initWithFrame:CGRectMake(90*kScreenWidthP, 188*kScreenWidthP, 280*kScreenWidthP, 26*kScreenWidthP)];
    _phoneNumberText.borderStyle = UITextBorderStyleNone;
    _phoneNumberText.font = [UIFont systemFontOfSize:15*kScreenWidthP];
    // 编辑时方框右边出现叉叉
    _phoneNumberText.clearButtonMode = UITextFieldViewModeWhileEditing;
    // 再次编辑是否清空
    _phoneNumberText.clearsOnBeginEditing = YES;
    // 密码的形式
    _phoneNumberText.secureTextEntry = NO;
    _phoneNumberText.delegate = self;
    [contentView addSubview:_phoneNumberText];
    
    // 手机号里面label
    UILabel *phoneleftLabel = [ControlsView createLabelFrame:CGRectMake(38*kScreenWidthP, 191*kScreenWidthP, 45*kScreenWidthP, 21*kScreenWidthP) backgroundColor:[UIColor whiteColor] title:@"手机号" font:15*kScreenWidthP];
    phoneleftLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15*kScreenWidthP];
    phoneleftLabel.textColor = RGBA(34, 34, 34, 0.8);
    phoneleftLabel.backgroundColor = [UIColor clearColor];
    [contentView addSubview:phoneleftLabel];
    
    UILabel *phoneLabel = [ControlsView createLabelFrame:CGRectMake(40*kScreenWidthP, 219*kScreenWidthP, 295*kScreenWidthP, 0.5*kScreenWidthP) backgroundColor:RGBA(34, 34, 34, 1) title:nil font:0];
    [contentView addSubview:phoneLabel];
    
    // 创建验证码TextField以及下面的线
    _registVerifiText = [[UITextField alloc]initWithFrame:CGRectMake(90*kScreenWidthP, 255*kScreenWidthP, 150*kScreenWidthP, 20*kScreenWidthP)];
    _registVerifiText.borderStyle = UITextBorderStyleNone;
    _registVerifiText.font = [UIFont systemFontOfSize:15*kScreenWidthP];
    // 编辑时方框右边出现叉叉
    _registVerifiText.clearButtonMode = UITextFieldViewModeWhileEditing;
    // 再次编辑是否清空
    _registVerifiText.clearsOnBeginEditing = YES;
    // 密码的形式
    _registVerifiText.secureTextEntry = NO;
    _registVerifiText.delegate = self;
    [contentView addSubview:_registVerifiText];
    
    // 里面label的颜色
    UILabel *registVerifileftLabel = [[UILabel alloc]initWithFrame:CGRectMake(38*kScreenWidthP, 255*kScreenWidthP, 45*kScreenWidthP, 20*kScreenWidthP)];
    registVerifileftLabel.backgroundColor = [UIColor clearColor];
    registVerifileftLabel.text = @"验证码";
    registVerifileftLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15*kScreenWidthP];
    registVerifileftLabel.textColor = RGBA(34, 34, 34, 0.8);
    [contentView addSubview:registVerifileftLabel];
    
    UILabel *registVerifiLabel = [ControlsView createLabelFrame:CGRectMake(40*kScreenWidthP, 283*kScreenWidthP,200*kScreenWidthP, 0.5*kScreenWidthP) backgroundColor:RGBA(34,34, 34, 0.8) title:nil font:0];
    [contentView addSubview:registVerifiLabel];
    
    // 验证码
    _registVerfiBtn = [[LNScodeCountBtn alloc]initWithFrame:CGRectMake(256*kScreenWidthP, 254*kScreenWidthP, 80*kScreenWidthP, 30*kScreenWidthP)];
    _registVerfiBtn.delegate = self;
    [contentView addSubview:_registVerfiBtn];
    
    // 创建登录按钮
    _registBtn = [[KBRoundedButton alloc]initWithFrame:CGRectMake(53*kScreenWidthP, 435*kScreenWidthP, 270*kScreenWidthP, 45*kScreenWidthP)];
    [_registBtn setTitle:@"登录" forState:UIControlStateNormal];
    [_registBtn setTitleColorForStateNormal:RGBA(34, 34, 34, 1)];
    [_registBtn addTarget:self action:@selector(loginAction) forControlEvents:UIControlEventTouchUpInside];
    _registBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15*kScreenWidthP];
    _registBtn.layer.borderWidth = 1*kScreenWidthP;
    _registBtn.layer.borderColor = RGBA(34, 34, 34, 1).CGColor;
    _registBtn.layer.masksToBounds = YES;
    [contentView addSubview:_registBtn];
    
    
    
    UIImageView *wechatImage = [ControlsView createImageViewFrame:CGRectMake(124*kScreenWidthP, 607*kScreenWidthP, 18.5*1.2*kScreenWidthP, 15.6*1.2*kScreenWidthP) imageName:@"login-wechat.png"];
    [contentView addSubview:wechatImage];
    
    // 创建微信登陆按钮
    UIButton *weichatBtn = [ControlsView createButtonFrame:CGRectMake(161*kScreenWidthP, 606*kScreenWidthP, 90*kScreenWidthP, 21*kScreenWidthP) title:@"微信账号登入" selectTitle:@"微信登入" titleColor:RGBA(67, 181, 223, 1) bgImageName:nil selectImageName:nil backgroundColor:RGBA(255, 255, 255, 1) layerCornerRadius:0.f  target:self action:NSSelectorFromString(@"weichatBtn")];
    weichatBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15*kScreenWidthP];
    weichatBtn.backgroundColor = [UIColor clearColor];
    weichatBtn.titleLabel.backgroundColor = [UIColor clearColor];
    [contentView addSubview:weichatBtn];
    

    
}
/**
 返回
 */
- (void)registBackBtn:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 点击下面的登入
 */
- (void)loginAction{
    if (_phoneNumberText.text.length <= 0 || _phoneNumberText.text == nil) {
        [[ProgressHUD sharedInstance]showInfoWithStatus:@"请输入手机号"];
        return;
    }
    if (_registVerifiText.text.length <= 0 || _registVerifiText.text == nil) {
        [[ProgressHUD sharedInstance] showInfoWithStatus:@"请输入正确的验证码"];
        return;
    }
    NSDictionary *dict = @{@"phone_number":_phoneNumberText.text,@"scode":_registVerifiText.text};
    _registBtn.working = YES;
    [self keyResignFirstResponder];
    [self loginUser:dict login_type:@"1"];
    
    [_registVerfiBtn closeTimer];
}
// 获取验证码
- (void)scodeCountBtnClicked{
    if (_phoneNumberText.text.length <= 0 || _phoneNumberText.text == nil) {
        [[ProgressHUD sharedInstance]showInfoWithStatus:@"请输入手机号"];
        return;
    }
    [_registVerfiBtn initWithCountdownBeginNumber];
    _registVerfiBtn.countdownBeginNumber = 60;
    [[UserStore sharedInstance]getScode:_phoneNumberText.text sucess:^(NSURLSessionDataTask *task, id responseObject) {
        NSNumber *codeNum = [responseObject objectForKey:@"code"];
        NSString *message = [responseObject objectForKey:@"message"];
        if (codeNum) {
           NSInteger code = [codeNum integerValue];
            if (code == 1) {
                [[ProgressHUD sharedInstance]showErrorOrSucessWithStatus:NO message:message];
            }else{
                [[ProgressHUD sharedInstance]showErrorOrSucessWithStatus:YES message:message];
            }
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
}


- (void)weichatBtn{
    if ([WXApi isWXAppInstalled]) {
        
        [WXApiRequestHandler sendAuthRequestScope:kAuthScope State:kAuthState OpenID:kAuthOpenID InViewController:self];
    }
}
- (void)managerDidRecvAuthResponse:(SendAuthResp *)response{
    if (response.code) {
        [[UserStore sharedInstance] getAccess_token:response.code sucess:^(NSDictionary *dict) {
            [self uploadUserInfo:dict];
        }];

    }else{
        NSLog(@"微信登录失败");
    }
}

#pragma mark -上传用户信息
- (void)uploadUserInfo:(NSDictionary *)userInfo{
 
    [self loginUser:userInfo login_type:@"0"];
}


- (void)loginUser:(NSDictionary *)loginUserInfo login_type:(NSString *)login_type{
    kWeakSelf(self)
    [[UserStore sharedInstance]loginUser:loginUserInfo login_type:login_type sucess:^(NSURLSessionDataTask *task, id responseObject) {
        NSNumber *numberCode = [responseObject objectForKey:@"code"];
        NSString *message = [responseObject objectForKey:@"message"];
        NSInteger code = [numberCode integerValue];
        if (code == 1) {
            NSNumber *login_typeNum = [responseObject objectForKey:@"is_bind"];
            NSString *login_types = [NSString stringWithFormat:@"%@",login_typeNum];
            NSString *userid = [responseObject objectForKey:@"userid"];
            UserDefaultSetObjectForKey(userid, LOTTORY_AUTHORIZATION_UID);
            UserDefaultSetObjectForKey(login_types, @"is_bind");
            if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(userLoginSucess)]) {
                [weakself.delegate userLoginSucess];
            }
           
            
        }else{
            [[ProgressHUD sharedInstance]showErrorOrSucessWithStatus:YES message:message];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _registBtn.working = NO;
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
    
 
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"收回键盘");
    [self keyResignFirstResponder];
    
}
- (void)keyResignFirstResponder{
    [_phoneNumberText resignFirstResponder];
    [_registVerifiText resignFirstResponder];
}
#pragma UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
//当键盘将要显示时，将底部的view向上移到键盘的上面
-(void)keyboardWillShow:(NSNotification*)notification{
    //通过消息中的信息可以获取键盘的frame对象
    NSValue *keyboardObj = [[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey];
    // 获取键盘的尺寸,也即是将NSValue转变为CGRect
    CGRect keyrect;
    [keyboardObj getValue:&keyrect];
    CGRect rect=self.view.frame;
  
        //如果键盘的高度大于底部控件到底部的高度，将_scrollView往上移 也即是：-（键盘的高度-底部的空隙）
        if (CGRectGetMaxY(_registBtn.frame) > keyrect.origin.y) {
            rect.origin.y=-(CGRectGetMaxY(_registBtn.frame) - keyrect.origin.y);
            self.view.frame = rect;
    }
}

//当键盘将要隐藏时（将原来移到键盘上面的视图还原）
-(void)keyboardWillHide:(NSNotification *)notification{
    CGRect rect=self.view.frame;
    NSValue *keyboardObj = [[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey];
    // 获取键盘的尺寸,也即是将NSValue转变为CGRect
    CGRect keyrect;
    [keyboardObj getValue:&keyrect];
    rect.origin.y= 0;
    self.view.frame = rect;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)prefersStatusBarHidden{
    return YES;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
