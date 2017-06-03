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
    
    [[NHIAP sharedNHIAP] addPayment:self.proudctIDS[sender.tag -1]
                        payObjectID:@""
                    paymentComplete:^(SKPaymentTransaction *transaction) {
                        //苹果支付成功后，但还未验证完成
                        // do something
                        
                    } success:^(SKPaymentTransaction *transaction, NSDictionary *resultObject) {
                        //苹果支付成功后，并验证完成
                        tipWithMessage(@"充值成功！");
                        
                    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
                        //购买失败
                        if (error) {
                            NSLog(@"购买错误：订单号：%@--error:%@",transaction.transactionIdentifier,error.localizedDescription);
                        }
                    }];
    
}


@end
