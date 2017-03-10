//
//  MineAccountController.m
//  WonderfulLive
//
//  Created by cnlive on 2016/10/21.
//  Copyright © 2016年 CNLive. All rights reserved.
//

#import "MineAccountController.h"
#import "InAppPurchase.h"
#import "NSNumber+ScaleHeight.h"
#import "CommonCrypto/CommonDigest.h"
#import "ZXLabel.h"
@interface MineAccountController ()
{
    BOOL isSelectedGold;//选择一种金额
    long selectedIndex;//选择的index
    NSString *_signValue;//预支付订单签名串
    NSString *_signValue1;//苹果内购支付订单签名串
    BOOL _isBuying;//正在购买中
    InAppPurchase *purchase;//内购类
}
@property (nonatomic ,strong) UILabel *cnCoinLabel;
@property (nonatomic ,strong) UILabel *cnCoinNumLabel;
@property (nonatomic ,strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic ,strong) UIImageView *goldCoinView;
@property (nonatomic ,strong) UIImageView *moreGoldView1;
@property (nonatomic ,strong) UIImageView *moreGoldView2;
@property (nonatomic ,strong) ZXLabel *goldLabel;
@property (nonatomic ,strong) ZXLabel *moreGoldLabel1;
@property (nonatomic ,strong) ZXLabel *moreGoldLabel2;
@property (nonatomic ,strong) UIButton *goldBtn;
@property (nonatomic ,strong) UIButton *moreGoldBtn1;
@property (nonatomic ,strong) UIButton *moreGoldBtn2;
@property (nonatomic ,strong) UIButton *payBtn;
@property (nonatomic ,strong) UIButton *chooseBtn;
@property (nonatomic ,strong) UILabel *agreeLabel;

@property (nonatomic ,assign) buyCoinsType type;

@property (nonatomic ,strong) NSMutableArray *goods;//商品列表数组
@property (nonatomic ,copy) NSString *tradeNo;//交易流水号

@end

@implementation MineAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = CommonBgColor;

    self.title = @"我的账户";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buyCNCoinSuccess:) name:BuySuccessNotify object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideHud) name:HidHud object:nil];

}
- (NSMutableArray *)goods
{
    if (!_goods) {
        _goods = [NSMutableArray arrayWithObjects:@{@"pkg":@"com.cnlive.SPZG.6000" ,@"price":@"6",@"title":@"6000"},@{@"pkg":@"com.cnlive.SPZG.12000",@"price":@"12",@"title":@"12000"},@{@"pkg":@"com.cnlive.SPZG.30000",@"price":@"30",@"title":@"30000"}, nil];
    }
    return _goods;
}

- (void)buttonClick:(UIButton *)button
{
    isSelectedGold = YES;
    selectedIndex = button.tag - 1000;
    switch (button.tag) {
        case 1000://goldBtn
        {
            button.backgroundColor = [UIColor yellowColorCNLive];
            self.moreGoldBtn1.backgroundColor = [UIColor clearColor];
            self.moreGoldBtn2.backgroundColor = [UIColor clearColor];
            self.type = IAP6p6000;
        }
            break;
        case 1001://moreGoldBtn1
        {
            self.goldBtn.backgroundColor = [UIColor clearColor];
            button.backgroundColor = [UIColor yellowColorCNLive];
            self.moreGoldBtn2.backgroundColor = [UIColor clearColor];
            self.type = IAP12p12000;
        }
            break;
        case 1002://moreGoldBtn2
        {
            self.goldBtn.backgroundColor = [UIColor clearColor];
            button.backgroundColor = [UIColor yellowColorCNLive];
            self.moreGoldBtn1.backgroundColor = [UIColor clearColor];
            self.type = IAP30p30000;
        }
            break;
        default:
            break;
    }
}
#pragma mark - 充值按钮action
- (void)payBtnClick
{
    if (!isSelectedGold) {//没选金额
        [Tools showHUDInView:self.view withString:@"请选择充值的金额" autoHide:YES];
        return;
    }
    if (!self.chooseBtn.selected) {//没同意
        [Tools showHUDInView:self.view withString:@"请阅读充值协议并确认" autoHide:YES];
        return;
    }
    //充值
    _tradeNo = [Tools generateTradeNO];
    NSString *fee = [[NSString stringWithFormat:@"%@00",self.goods[selectedIndex][@"price"]] copy];//fee是6元-->600分单位
    if(!fee)fee = @"";
    NSString *attach_value = [self.goods[selectedIndex][@"title"] copy];
    
    NSDictionary *parameter=@{@"sp_id":SpId,@"appId":SpId,
                              @"out_trade_no":_tradeNo?_tradeNo:@"",
                              @"total_fee":fee,
                            @"notify_url":@"http://apps.pay.cnlive.com/upappnotify/notify/updateCnCoin",
                              @"type":@"1001",
                              @"attach.value":attach_value,
                              @"attach.prdId":@"chinacoin",
                              @"user_id":[UserInformationModel manager].uid,
                              @"attach.sid":[UserInformationModel manager].uid,
                              @"frmId":@"apple",
                              @"attach.plat":@"i",
                              @"attach.payChannelId": @"4300",
                              @"body":@"中国币"
                              };
    NSString *string1 = [NSString stringWithFormat:@"%@&key=%@", [self signvalue:parameter], SxyAppKey];
    NSString *signString1 = [[self sha1:string1] uppercaseString];
    
//    NSString *videourl = [NSString stringWithFormat:@"%@?%@&sign=%@", prepay, [self signvalue:parameter], signString1];
    _signValue = signString1;
    _signValue1 = signString1;
    NSDictionary *parameters=@{@"sp_id":SpId,
                               @"appId":SpId,
                               @"out_trade_no":_tradeNo?_tradeNo:@"",
                               @"total_fee":fee,
                               @"notify_url":@"http://apps.pay.cnlive.com/upappnotify/notify/updateCnCoin",
                               @"type":@"1001",
                               @"attach.value":attach_value,
                               @"attach.prdId":@"chinacoin",
                               @"user_id":[UserInformationModel manager].uid,
                               @"attach.sid":[UserInformationModel manager].uid,
                               @"frmId":@"apple",
                               @"attach.plat":@"i",
                               @"sign":_signValue?_signValue:@"",
                               @"attach.payChannelId": @"4300",
                               @"body":@"中国币"
                               };
    if(!_isBuying)
    {
        _isBuying = YES;
        [[AFHTTPRequestOperationManager manager] POST:prepay parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            responseObject = [responseObject validatedDictionary];
            NSLog(@"responseObject = %@",responseObject);
            if ([[NSString stringWithFormat:@"%@", responseObject[@"errorCode"]] isEqualToString:@"0"])
            {
                _isBuying = NO;
                purchase = [[InAppPurchase alloc] initWithCoinType:_type baseView:self.view];
                purchase.signValue = _signValue;
                purchase.tradeNo=_tradeNo;
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                [SVProgressHUD showWithStatus:@"正在购买"];
            }
            else {
                [Tools showHUDInView:self.view withString:[responseObject objectForKey:@"errorMessage"] autoHide:YES];
                _isBuying = NO;
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            _isBuying = NO;
            
            [Tools showHUDInView:self.view withString:@"加载失败，再踹（try）一下吧" autoHide:YES];
        }];
    }
}

//加密
- (NSString*)sha1:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    while ([[output substringToIndex:1] isEqualToString:@"0"]) {
        output = [[NSMutableString alloc] initWithString:[output substringFromIndex:1]];
    }
    
    return output;
}
#pragma mark 签名机制
- (NSString *)signvalue:(NSDictionary*)parameter
{
    //对所有传入参数按照字段名的 ASCII 码从小到大排序
    NSArray *keyArr=[parameter allKeys];
    NSArray *arr = [keyArr sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableString *string1 = [[NSMutableString alloc]init];
    for (int i=0; i<arr.count; i++) {
        
        NSString *parameterString = parameter[[arr objectAtIndex:i]];
        if (parameterString.length > 0) {
            [string1 appendString:[NSString stringWithFormat:@"%@=%@&",[arr objectAtIndex:i],parameter[[arr objectAtIndex:i]]]];
        }
    }
    
    if (string1.length > 0) {
        [string1 deleteCharactersInRange:NSMakeRange(string1.length-1, 1)];
    }
    
    return string1;
}
    /*
     dic = {
     topups =     (
     {
     pkg = "com.cnlive4.6";
     price = 6;
     title = 6000;
     },
     {
     pkg = "com.cnlive4.12";
     price = 12;
     title = 12000;
     },
     {
     pkg = "com.cnlive4.thirty";
     price = 30;
     title = 30000;
     }
     );
     }
     */
#pragma mark - 购买结果回调
- (void)buyCNCoinSuccess:(NSNotification *)notification
{
    [SVProgressHUD showWithStatus:@"正在验证购买"];
    NSString *price;
    NSString *count;
    NSString *product_id = notification.object;
    for (NSDictionary *dic in self.goods) {
        if ([dic[@"pkg"] isEqual:product_id]) {
            price = dic[@"price"];
            count = dic[@"title"];
        }
    }
//    NSLog(@"price = %@",price);
//    NSLog(@"count = %@",count);
    //支付完成，告诉后台修改个人信息中的中国币数量。跳到个人中心展示个人信息
    NSDictionary *parameter =@{@"sp_id":SpId,@"appId":SpId,
                        @"out_trade_no":_tradeNo?_tradeNo:@"",
                        @"type":@"1001"
                        };
    
    NSString *string1 = [NSString stringWithFormat:@"%@&key=%@", [self signvalue:parameter], SxyAppKey];
    NSString *signString1 = [[self sha1:string1] uppercaseString];
    
    //    NSString *videourl = [NSString stringWithFormat:@"%@?%@&sign=%@", prepay, [self signvalue:parameter], signString1];
    _signValue1 = signString1;
    
    NSDictionary *parameters = @{@"sp_id":SpId,@"appId":SpId,@"out_trade_no":_tradeNo?_tradeNo:@"",@"type":@"1001",@"sign":_signValue1?_signValue1:@""};
    weakself;
    
    [[AFHTTPRequestOperationManager manager] POST:payed parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"responseObject = %@",responseObject);
        _isBuying = NO;
        
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD showWithStatus:@"正在更新中国币"];

        [UserTools getChinaCoinSuccess:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            [SVProgressHUD dismiss];
            NSString *chinaCoin = (NSString *)responseObject[@"china_coin"];
            [UserTools setLocalUserInfo:chinaCoin withKey:@"chinaCoin"];
            weakSelf.cnCoinNumLabel.text = chinaCoin;
            CGSize cnCoinNumSize = [weakSelf.cnCoinNumLabel labelSize];
            weakSelf.cnCoinNumLabel.width = cnCoinNumSize.width;
            weakSelf.cnCoinNumLabel.centerX = SCREEN_W * 0.5;
//            NSLog(@"responseObject = %@",responseObject);
            
        } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
//            NSLog(@"%@",error);
            [SVProgressHUD setMinimumDismissTimeInterval:1.0];
            [SVProgressHUD showErrorWithStatus:error.description];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        [Tools showHUDInView:self.view withString:@"服务器异常或请求超时" autoHide:YES];
    }];
}

- (void)hideHud
{
    [SVProgressHUD dismiss];
}

#pragma mark - 同意按钮action
- (void)chooseBtnClick:(UIButton *)button
{
    if (!button.selected) {//同意
        
        
    }else//没同意
    {
        
    }
    button.selected = !button.selected;
}

#pragma mark - 加载视图
- (void)bindView
{
    isSelectedGold = NO;
    
    [self.btnRight setFrame:CGRectMake(self.btnRight.x, self.btnRight.y, 100, self.btnRight.height)];
//    self.btnRight.hidden = NO;
    [self.btnRight setTitle:@"我的账单" forState:UIControlStateNormal];
    [self.btnRight setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    self.cnCoinLabel.text = @"中国币";
    CGSize cnCoinSize = [self.cnCoinLabel labelSize];
//    self.cnCoinLabel.center = CGPointMake(SCREEN_W * 0.5 - cnCoinSize.width * 0.5, 33);
    self.cnCoinLabel.centerX = SCREEN_W * 0.5 - cnCoinSize.width * 0.5;
//    self.cnCoinLabel.top =  [Tools getTargetDeviceScaleHeight:33];
    self.cnCoinLabel.top =  [@33 ScaH];
    self.cnCoinLabel.width = cnCoinSize.width;//100;
    self.cnCoinLabel.height = cnCoinSize.height;//30;

    self.cnCoinNumLabel.text = @"0";
    CGSize cnCoinNumSize = [self.cnCoinNumLabel labelSize];
    self.cnCoinNumLabel.center = CGPointMake(SCREEN_W * 0.5 - cnCoinNumSize.width * 0.5, self.cnCoinLabel.bottom + [@28 ScaH]);
    self.cnCoinNumLabel.width = cnCoinNumSize.width;//100;
    self.cnCoinNumLabel.height = cnCoinNumSize.height;//30;
    
    self.goldCoinView.frame = CGRectMake(50, _cnCoinNumLabel.bottom + [@41 ScaH], 144 / 3, 120 / 3);
    self.goldCoinView.image = [UIImage imageNamed:@"Gold COINS"];
    self.goldLabel.text = @"6000";
    CGSize size = [self.goldLabel labelSize];
    self.goldLabel.frame = CGRectMake(_goldCoinView.right + 24, _cnCoinNumLabel.bottom + [@57 ScaH], size.width, size.height);
    self.goldLabel.centerY = self.goldCoinView.centerY;
    self.goldBtn.frame = CGRectMake(SCREEN_W - 50 - 146 /2, _cnCoinNumLabel.bottom + [@50 ScaH], 146 /2, 60 / 2);
    self.goldBtn.centerY = self.goldCoinView.centerY;
    
    self.moreGoldView1.frame = CGRectMake(_goldCoinView.left, _goldCoinView.bottom + [@36 ScaH], _goldCoinView.width, _goldCoinView.height);
    self.moreGoldView1.image = [UIImage imageNamed:@"More gold COINS"];
    self.moreGoldLabel1.text = @"12000";
    CGSize moreGoldSize = [self.moreGoldLabel1 labelSize];
    self.moreGoldLabel1.frame = CGRectMake(_goldCoinView.right + 24, _cnCoinNumLabel.bottom + [@57 ScaH] + [@60 ScaH], moreGoldSize.width, moreGoldSize.height);
    self.moreGoldLabel1.centerY = self.moreGoldView1.centerY;
    self.moreGoldBtn1.frame = CGRectMake(SCREEN_W - 50 - 146 /2, _goldBtn.bottom + [@43 ScaH], 146 /2, 60 / 2);
    self.moreGoldBtn1.centerY = self.moreGoldView1.centerY;
    
    self.moreGoldView2.frame = CGRectMake(_moreGoldView1.left, _moreGoldView1.bottom + [@36 ScaH], _moreGoldView1.width, _moreGoldView1.height);
    self.moreGoldView2.image = [UIImage imageNamed:@"More gold COINS"];
    self.moreGoldLabel2.text = @"30000";
    CGSize moreGoldSize2 = [self.moreGoldLabel2 labelSize];
    self.moreGoldLabel2.frame = CGRectMake(_goldCoinView.right + 24, _cnCoinNumLabel.bottom + [@57 ScaH] + [@120 ScaH], moreGoldSize2.width, moreGoldSize2.height);
    self.moreGoldLabel2.centerY = self.moreGoldView2.centerY;
    self.moreGoldBtn2.frame = CGRectMake(SCREEN_W - 50 - 146 /2, _moreGoldBtn1.bottom + [@43 ScaH], 146 /2, 60 / 2);
    self.moreGoldBtn2.centerY = self.moreGoldView2.centerY;

    self.payBtn.frame = CGRectMake(20, self.moreGoldView2.bottom + [@36 ScaH], SCREEN_W - 40, [@50 ScaH]);
    
    self.chooseBtn.frame = CGRectMake(126 / 2, self.payBtn.bottom + [@29 ScaH], 60 / 3, 60 / 3);
    self.chooseBtn.selected = YES;
    
    self.agreeLabel.text = @"我已阅读并同意《用户充值协议》";
    CGSize agreeSize = [self.agreeLabel labelSize];
    self.agreeLabel.frame = CGRectMake(self.chooseBtn.right + 16 / 2, self.payBtn.bottom + [@32 ScaH],agreeSize.width,agreeSize.height);
    
    CGFloat left = (SCREEN_W - agreeSize.width - 20 - 8) * 0.5;
    self.chooseBtn.centerX = left+ 10;
    self.agreeLabel.left = self.chooseBtn.right + 16 / 2;
}

- (AFHTTPRequestOperationManager *)manager
{
    if (!_manager) {
        _manager = [AFHTTPRequestOperationManager manager];
    }
    return _manager;
}
-(void)bindModel
{
    weakself
    [UserTools getChinaCoinSuccess:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSString *chinaCoin = (NSString *)responseObject[@"china_coin"];
        [UserTools setLocalUserInfo:chinaCoin withKey:@"chinaCoin"];
        
        weakSelf.cnCoinNumLabel.text = chinaCoin;
        CGSize cnCoinNumSize = [weakSelf.cnCoinNumLabel labelSize];
        weakSelf.cnCoinNumLabel.width = cnCoinNumSize.width;
        weakSelf.cnCoinNumLabel.centerX = SCREEN_W * 0.5;
//        NSLog(@"%@",responseObject);

    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
//        NSLog(@"%@",error);

    }];
        /* 
         {
         aid = "";
         alevel = 1;
         avatar = "http://120.92.63.41:8080/mobile/images/mobilehead/default/face_60X60.jpg";
         "china_coin" = 0;
         ctaddress = "";
         ctemail = "";
         ctid = "";
         ctmobile = "";
         ctpostcode = "";
         ctrealname = "";
         email = "";
         emailVerify = false;
         gender = n;
         "gift_rec" = 0;
         "gift_sent" = 0;
         integrity = 0;
         level = 0;
         levelName = "\U8d2b\U6c11";
         liveStatuts = false;
         location = "";
         mobile = 18346665610;
         nickname = "183xxxx5610_135";
         openId = "";
         point = 0;
         redPackage = 0;
         type = 0;
         uid = 1464965;
         uname = 18346665610;
         uniqueId = "";
         }
         */

}

#pragma mark - getter 方法
-(UILabel *)cnCoinLabel
{
    if (!_cnCoinLabel) {
        UILabel* label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor blackColorCNLive];
        label.font = [UIFont systemFontOfSize:19.0f];
        label.textAlignment = NSTextAlignmentCenter;
        _cnCoinLabel = label;
        [self.view addSubview:_cnCoinLabel];
    }
    return _cnCoinLabel;
}

-(UILabel *)cnCoinNumLabel
{
    if (!_cnCoinNumLabel) {
        UILabel* label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor blackColorCNLive];
        label.font = [UIFont systemFontOfSize:35.0f];
        label.textAlignment = NSTextAlignmentCenter;
        _cnCoinNumLabel = label;
        [self.view addSubview:_cnCoinNumLabel];
    }
    return _cnCoinNumLabel;
}
-(ZXLabel *)goldLabel
{
    if (!_goldLabel) {
        
//        UILabel* label = [[UILabel alloc]init];
//        label.backgroundColor = [UIColor clearColor];
//        label.textColor = [UIColor blackColorCNLive];
//        label.font = [UIFont systemFontOfSize:17.0f];
//        label.textAlignment = NSTextAlignmentCenter;
//        _goldLabel = label;
        _goldLabel = [ZXUIKit labelTypeGold];
        [self.view addSubview:_goldLabel];
    }
    return _goldLabel;
}
-(ZXLabel *)moreGoldLabel1
{
    if (!_moreGoldLabel1) {
//        UILabel* label = [[UILabel alloc]init];
//        label.backgroundColor = [UIColor clearColor];
//        label.textColor = [UIColor blackColorCNLive];
//        label.font = [UIFont systemFontOfSize:17.0f];
//        label.textAlignment = NSTextAlignmentCenter;
//        _moreGoldLabel1 = label;
        _moreGoldLabel1 = [ZXUIKit labelTypeGold];
        [self.view addSubview:_moreGoldLabel1];
    }
    return _moreGoldLabel1;
}
-(ZXLabel *)moreGoldLabel2
{
    if (!_moreGoldLabel2) {
//        UILabel* label = [[UILabel alloc]init];
//        label.backgroundColor = [UIColor clearColor];
//        label.textColor = [UIColor blackColorCNLive];
//        label.font = [UIFont systemFontOfSize:17.0f];
//        label.textAlignment = NSTextAlignmentCenter;
//        _moreGoldLabel2 = label;
        _moreGoldLabel2 = [ZXUIKit labelTypeGold];
        [self.view addSubview:_moreGoldLabel2];
    }
    return _moreGoldLabel2;
}
-(UILabel *)agreeLabel
{
    if (!_agreeLabel) {
        UILabel* label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor blackColorCNLive];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentLeft;
        _agreeLabel = label;
        [self.view addSubview:_agreeLabel];
    }
    return _agreeLabel;
}

-(UIImageView *)goldCoinView
{
    if (!_goldCoinView) {
        _goldCoinView = [UIImageView new];
        [self.view addSubview:_goldCoinView];
    }
    return _goldCoinView;
}
-(UIImageView *)moreGoldView1
{
    if (!_moreGoldView1) {
        _moreGoldView1 = [UIImageView new];
        [self.view addSubview:_moreGoldView1];
    }
    return _moreGoldView1;
}

-(UIImageView *)moreGoldView2
{
    if (!_moreGoldView2) {
        _moreGoldView2 = [UIImageView new];
        [self.view addSubview:_moreGoldView2];
    }
    return _moreGoldView2;
}

- (UIButton *)goldBtn
{
    if (!_goldBtn) {
//        _goldBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_goldBtn setTitle:@"¥6" forState:UIControlStateNormal];
//        _goldBtn.layer.borderWidth = 1.0f;//设置边框宽度
//        _goldBtn.layer.borderColor = [UIColor colorWithHexString:@"202020"].CGColor;//设置边框颜色
//        _goldBtn.layer.cornerRadius = 15.0f;
//        _goldBtn.clipsToBounds = YES;
//        _goldBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
//        _goldBtn.titleLabel.font = [UIFont systemFontOfSize:20];
//        [_goldBtn setTitleColor:[UIColor colorWithHexString:@"202020"] forState:UIControlStateNormal];
        _goldBtn = [UIButton buttonWithTitle:@"¥6" titleColor:[UIColor colorWithHexString:@"202020"] labelFontSize:20 labelTextAlginment:NSTextAlignmentCenter cornerRadius:15.0f borderWidth:1.0f borderColor:[UIColor colorWithHexString:@"202020"]];
        _goldBtn.tag = 1000;
        [_goldBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_goldBtn];
    }
    return _goldBtn;
}
- (UIButton *)moreGoldBtn1
{
    if (!_moreGoldBtn1) {
//        _moreGoldBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_moreGoldBtn1 setTitle:@"¥12" forState:UIControlStateNormal];
//        _moreGoldBtn1.layer.borderWidth = 1.0f;//设置边框宽度
//        _moreGoldBtn1.layer.borderColor = [UIColor colorWithHexString:@"202020"].CGColor;//设置边框颜色
//        _moreGoldBtn1.layer.cornerRadius = 15.0f;
//        _moreGoldBtn1.clipsToBounds = YES;
//        
//        _moreGoldBtn1.titleLabel.textAlignment = NSTextAlignmentCenter;
//        _moreGoldBtn1.titleLabel.font = [UIFont systemFontOfSize:20];
//        [_moreGoldBtn1 setTitleColor:[UIColor colorWithHexString:@"202020"] forState:UIControlStateNormal];
//        
        _moreGoldBtn1 = [UIButton buttonWithTitle:@"¥12" titleColor:[UIColor colorWithHexString:@"202020"] labelFontSize:20 labelTextAlginment:NSTextAlignmentCenter cornerRadius:15.0f borderWidth:1.0f borderColor:[UIColor colorWithHexString:@"202020"]];
        _moreGoldBtn1.tag = 1001;
        [_moreGoldBtn1 addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_moreGoldBtn1];
    }
    return _moreGoldBtn1;
}
- (UIButton *)moreGoldBtn2
{
    if (!_moreGoldBtn2) {
//        _moreGoldBtn2 = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_moreGoldBtn2 setTitle:@"¥30" forState:UIControlStateNormal];
//        _moreGoldBtn2.layer.borderWidth = 1.0f;//设置边框宽度
//        _moreGoldBtn2.layer.borderColor = [UIColor colorWithHexString:@"202020"].CGColor;//设置边框颜色
//        _moreGoldBtn2.layer.cornerRadius = 15.0f;
//        _moreGoldBtn2.clipsToBounds = YES;
//        
//        _moreGoldBtn2.titleLabel.textAlignment = NSTextAlignmentCenter;
//        _moreGoldBtn2.titleLabel.font = [UIFont systemFontOfSize:20];
//        [_moreGoldBtn2 setTitleColor:[UIColor colorWithHexString:@"202020"] forState:UIControlStateNormal];
        _moreGoldBtn2 = [UIButton buttonWithTitle:@"¥30" titleColor:[UIColor colorWithHexString:@"202020"] labelFontSize:20 labelTextAlginment:NSTextAlignmentCenter cornerRadius:15.0f borderWidth:1.0f borderColor:[UIColor colorWithHexString:@"202020"]];
        _moreGoldBtn2.tag = 1002;
        [_moreGoldBtn2 addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_moreGoldBtn2];
    }
    return _moreGoldBtn2;
}
- (UIButton *)payBtn
{
    if (!_payBtn) {
//        _payBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_payBtn setTitle:@"立即充值" forState:UIControlStateNormal];
//        _payBtn.layer.borderWidth = 1.5f;//设置边框宽度
//        _payBtn.layer.borderColor = [UIColor colorWithHexString:@"202020"].CGColor;//设置边框颜色
//        _payBtn.layer.cornerRadius = [@50 ScaH] * 0.5;
//        _payBtn.clipsToBounds = YES;
//        _payBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
//        _payBtn.titleLabel.font = [UIFont systemFontOfSize:22];
//        [_payBtn setTitleColor:[UIColor colorWithHexString:@"202020"] forState:UIControlStateNormal];
//        [_payBtn setBackgroundImage:[UIImage imageWithColor:[UIColor yellowColorCNLive]] forState:UIControlStateHighlighted];
        _payBtn = [UIButton buttonWithTitle:@"立即充值" titleColor:[UIColor colorWithHexString:@"202020"] labelFontSize:22 labelTextAlginment:NSTextAlignmentCenter cornerRadius:[@50 ScaH] * 0.5 borderWidth:1.5f borderColor:[UIColor colorWithHexString:@"202020"] backgroundImageHighlight:[UIImage imageWithColor:[UIColor yellowColorCNLive]]];
        [_payBtn addTarget:self action:@selector(payBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_payBtn];
    }
    return _payBtn;
}
- (UIButton *)chooseBtn
{
    if (!_chooseBtn) {
//        _chooseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_chooseBtn setImage:[UIImage imageNamed:@"not choose"] forState:UIControlStateNormal];
//        [_chooseBtn setImage:[UIImage imageNamed:@"choose"] forState:UIControlStateSelected];
        _chooseBtn = [UIButton buttonWithBackgroundImageNormal:[UIImage imageNamed:@"not choose"] backgroundImageSelected:[UIImage imageNamed:@"choose"]];
        [_chooseBtn addTarget:self action:@selector(chooseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_chooseBtn];
    }
    return _chooseBtn;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

@end
