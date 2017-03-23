//
//  ViewController.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "ViewController.h"
#import "NHIAP.h"
#import "CommonCrypto/CommonDigest.h"


#define CNLiveUserAppID         @"118_itdr6ijv09"
#define CNLiveUserAppKey        @"24557a1060598e010749ec11b43ac9d62e8a765d3463cf"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, copy  ) NSArray  *proudctIDS;
@property (nonatomic, strong) NSString *coustomTransactionID;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController
//- (NSArray *)proudctIDS{
//    if (!_proudctIDS) {
//        _proudctIDS = @[
//                        @"com.facebac.BaiKeTheVoice.number01",
//                        @"com.facebac.BaiKeTheVoice.number02",
//                        @"com.facebac.BaiKeTheVoice.number03",
//                        @"com.facebac.BaiKeTheVoice.number04",
//                        @"com.facebac.BaiKeTheVoice.number05",
//                        @"com.facebac.BaiKeTheVoice.number06"
//                        ];
//    }
//    return _proudctIDS;
//}

- (NSArray *)proudctIDS{
    if (!_proudctIDS) {
        _proudctIDS = @[
                        @"com.cnlive.mijialiveshow.sixty",
                        @"com.cnlive.mijialiveshow.threehundred",
                        @"com.cnlive.mijialiveshow.ninehundred",
                        ];
    }
    return _proudctIDS;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    __weak __typeof(self)weakself = self;
    [NHIAP requestProducts:self.proudctIDS success:^(NSArray *products, NSArray *invalidIdentifiers) {
        weakself.proudctIDS = products.copy;
        [weakself.tableView reloadData];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"查询成功:%@--%@",products,invalidIdentifiers);
    } failure:^(NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (error) {
            tipWithMessage([NSString stringWithFormat:@"查询失:%@",error.localizedDescription]);
            NSLog(@"查询失败:%@",error);
        }
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.proudctIDS.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    SKProduct *product = _proudctIDS[indexPath.row];
    cell.textLabel.text = product.productIdentifier;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    
}



- (IBAction)buyEvent:(UIButton *)sender {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    __weak __typeof(self)weakself = self;
    
    NHIAP *iap = [[NHIAP sharedNHIAP] addPayment:self.proudctIDS[sender.tag -1] payObjectID:@"698" success:^(SKPaymentTransaction *transaction) {
        
        NSDictionary *parameter =@{
                                   @"sp_id":CNLiveUserAppID,
                                   @"appId":CNLiveUserAppID,
                                   @"out_trade_no":weakself.coustomTransactionID,
                                   @"type":@"1001"
                                   };
        NSString *sigSting = [NSString stringWithFormat:@"%@&key=%@",[NHPayApi signvalue:parameter],CNLiveUserAppKey];
        NSString *shaString = [[NHPayApi sha1:sigSting] uppercaseString];
        NSMutableDictionary *parameter_sig = parameter.mutableCopy;
        [parameter_sig setObject:shaString forKey:@"sign"];
        
        [NHPayApi apiRequestMeLive:parameter_sig urlString:@"payed" complete:^(id resultObject, NSError *error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (!error) {
                [NHOrderManage deleteTransactionIdentifier:transaction.transactionIdentifier];
            }
            NSLog(@"购买成功：\n订单号：%@  \nbody:%@   \nerror:%@",transaction.transactionIdentifier,resultObject,error);
        }];
        
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (error) {
            NSLog(@"购买错误：订单号：%@--error:%@",transaction.transactionIdentifier,error.localizedDescription);
        }
    }];
    [self sendinfoToMeServe:iap.currentProduct.productIdentifier price:[iap.currentProduct.price intValue]];
}

- (void)sendinfoToMeServe:(NSString *)identifier price:(int)price{
    if (identifier == nil) {
        return;
    }
    _coustomTransactionID = [NSString stringWithFormat:@"%@-%@",[NHPayApi getCurrentDateBaseStyle:nil],identifier];
    NSDictionary *parameter = @{
                                @"sp_id":@"118_itdr6ijv09",
                                @"appId":@"118_itdr6ijv09",
                                @"out_trade_no":_coustomTransactionID,
                                @"total_fee":[NSString stringWithFormat:@"%d",price*100],
                                @"notify_url":@"http://apps.pay.cnlive.com/upappnotify/notify/updateCnCoin",
                                @"type":@"1001",
                                @"attach.value":[NSString stringWithFormat:@"%d",price],
                                @"attach.prdId":@"chinacoin",
                                @"user_id":@"698",
                                @"attach.sid":@"698",
                                @"frmId":@"apple",
                                @"attach.plat":@"i",
                                @"attach.payChannelId": @"4300",
                                @"body":@"中国币"
                                };
    NSString *signParameterStr = [NSString stringWithFormat:@"%@&key=%@",[NHPayApi signvalue:parameter], CNLiveUserAppKey];
    NSString *shaParameterStr = [[NHPayApi sha1:signParameterStr] uppercaseString];
    
    NSMutableDictionary *parameter_sig = parameter.mutableCopy;
    [parameter_sig setObject:shaParameterStr forKey:@"sign"];
    
    [NHPayApi apiRequestMeLive:parameter_sig urlString:@"prepay" complete:^(id resultObject, NSError *error) {
        NSLog(@"%@   \n%@",resultObject,error);
        
    }];
}





@end
