//
//  InAppPurchase.m
//  WonderfulLive
//
//  Created by 张旭 on 2016/11/4.
//  Copyright © 2016年 CNLive. All rights reserved.
//

#import "InAppPurchase.h"
#import "NSData-Base64.h"

#ifdef DEBUG

#define IAP_URL             @"https://sandbox.itunes.apple.com/verifyReceipt"
#else

#define IAP_URL               @"https://buy.itunes.apple.com/verifyReceipt"
#endif

//在内购项目中创的商品单号
#define ProductID_IAP6p6000 @"com.cnlive.SPZG.6000"//6 com.cnlive.mijialiveshow.sixty
#define ProductID_IAP12p12000 @"com.cnlive.SPZG.12000" //12 com.cnlive.mijialiveshow.threehundred
#define ProductID_IAP30p30000 @"com.cnlive.SPZG.30000" //30 com.cnlive.mijialiveshow.ninehundred
@interface InAppPurchase ()<SKProductsRequestDelegate,SKPaymentTransactionObserver,NSURLConnectionDataDelegate>
{
    NSString *currentProID;//当前产品ID com.cnlive.SPZG.6000
    NSURLConnection *_connection;
    NSMutableData *_appStoreData;
}

@property (nonatomic ,strong) UIView *baseView;
@property (nonatomic ,assign) buyCoinsType type;
@end

@implementation InAppPurchase

- (instancetype)initWithCoinType:(buyCoinsType)type baseView:(UIView *)baseView
{
    self = [super init];
    if (self) {
        self.type = type;
        self.baseView = baseView;

        //监听购买结果
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [self RequestProductData];
        
    }
    return self;
}

//请求对应的产品信息
- (void)RequestProductData
{
    NSArray *product = nil;
    switch (_type) {
        case IAP6p6000:
        {
            product = [[NSArray alloc] initWithObjects:ProductID_IAP6p6000, nil];
            currentProID = ProductID_IAP6p6000;
        }
            break;
        case IAP12p12000:
        {
            product = [[NSArray alloc] initWithObjects:ProductID_IAP12p12000, nil];
            currentProID = ProductID_IAP12p12000;
        }
            break;
        case IAP30p30000:
        {
            product = [[NSArray alloc] initWithObjects:ProductID_IAP30p30000, nil];
            currentProID = ProductID_IAP30p30000;
        }
            break;
        default:
            break;
    }
    
    NSSet *nsset = [NSSet setWithArray:product];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    [request start];
}

#pragma mark -SKProductsRequestDelegate请求协议
//收到的产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    NSLog(@"产品Product ID:%@",response.invalidProductIdentifiers);
    NSLog(@"产品付费数量: %d", (int)[products count]);
    // populate UI
    for(SKProduct *product in products){
        NSLog(@"product info");
        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"Product id: %@" , product.productIdentifier);
    }
    SKProduct *product = [products lastObject];
    if(!product)return;
    
    //获得产品信息,开始购买
    if ([SKPaymentQueue canMakePayments]) {
        
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else
    {
        [self alert:@"您的设备版本过低,无法完成购买"];
    }
    
}

#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request
{
    
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    [self alert:[error localizedDescription]];
}

#pragma mark - SKPaymentTransactionObserver监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: //交易完成
                //发送到苹果服务器验证凭证
                [self completedPurchaseTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                 [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed: //交易失败、交易取消
                [self handleFailedTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing://商品添加进列表
                break;
            default: 
                break;
        }
    }   
}

#pragma mark - 交易方法
/**
 *  验证购买，避免越狱软件模拟苹果请求达到非法购买问题
 *
 */
- (void)completedPurchaseTransaction:(SKPaymentTransaction *)transaction
{
     //从沙盒中获取交易凭证并且拼接成请求体数据
//    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
//    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
//    NSString *receiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];//转为base64字符串
//    NSString *bodyString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", receiptString];//拼接请求数据
//    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
//    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]];
    
    NSString *recepitData = [transaction.transactionReceipt base64Encoding];
    NSDictionary *recepitDic = [NSDictionary dictionaryWithObject:recepitData forKey:@"receipt-data"];
    
    NSString *recepitJSON = [recepitDic JSONRepresentation];
    
//    将数据post到appstore验证交易收据
    NSData *postData = [NSData dataWithBytes:[recepitJSON UTF8String] length:[recepitJSON length]];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    //创建请求到苹果官方进行购买验证
    NSURL *url=[NSURL URLWithString:IAP_URL];
    NSMutableURLRequest *requestM=[NSMutableURLRequest requestWithURL:url];
    requestM.HTTPBody=postData;
    requestM.HTTPMethod=@"POST";
    [requestM setValue:postLength forHTTPHeaderField:@"Content-Length"];//
    [requestM setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];//
    _connection = [NSURLConnection connectionWithRequest:requestM delegate:self];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

//    //创建连接并发送同步请求
//    NSError *error = nil;
//    NSData *responseData = [NSURLConnection sendSynchronousRequest:requestM returningResponse:nil error:&error];
//    if (error) {
//        NSLog(@"验证购买过程中发生错误,错误信息 %@",error.localizedDescription);
//        return;
//    }
//    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
//    NSLog(@"%@",dic);
//    if ([dic[@"status"] intValue] == 0) {
//        NSLog(@"购买成功");
//        NSDictionary *dicReceipt = dic[@"receipt"];
//        NSDictionary *dicInApp = [dicReceipt[@"in_app"]firstObject];
//        NSString *productIdentifier = dicInApp[@"product_id"];//读取产品标识
//        //如果是消耗品则记录购买数量，非消耗品则记录是否购买过
//        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
//        if ([productIdentifier isEqualToString:currentProID]) {
//            long purchasedCount=[defaults integerForKey:productIdentifier];//已购买数量
//            [[NSUserDefaults standardUserDefaults] setInteger:(purchasedCount+1) forKey:productIdentifier];
//        }else{
//            [defaults setBool:YES forKey:productIdentifier];
//        }
//        //在此处对购买记录进行存储，可以存储到开发商的服务器端
//    }else{
//        NSLog(@"购买失败，未通过验证！");
//    }
//    
}

- (void)handleFailedTransaction:(SKPaymentTransaction *)transaction
{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:HidHud object:nil];
    if (transaction.error.code != SKErrorPaymentCancelled) {
        UIAlertView *errorMsg = [[UIAlertView alloc] initWithTitle:@"交易发生错误" message:transaction.error.localizedDescription delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [errorMsg show];
        
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

#pragma mark -NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == _connection) {
        _appStoreData = [NSMutableData data];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == _connection) {
        [_appStoreData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HidHud object:nil];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *errorMsg = [[UIAlertView alloc] initWithTitle:@"发生错误" message:@"链接失败，请稍候重试!" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [errorMsg show];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HidHud object:nil];
    if (connection == _connection) {
        NSDictionary *appResultDic = [NSJSONSerialization JSONObjectWithData:_appStoreData options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"dic = %@",appResultDic);
        
        NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
        [accountDefaults setObject:appResultDic forKey:@"china_coin_post"];
        [accountDefaults synchronize];
        
//#warning sandbox调试
//        if ([[appResultDic objectForKey:@"environment"] isEqualToString:@"Sandbox"]) {//沙盒购买
//            if ([[appResultDic objectForKey:@"status"] intValue] == 0)
//            {//沙盒测试成功
//                NSDictionary *receiptDic = [NSDictionary dictionaryWithDictionary:[appResultDic objectForKey:@"receipt"]];
//                
//                NSArray *in_appArr = [receiptDic objectForKey:@"in_app"];
//                NSString *product_id = [in_appArr lastObject][@"product_id"];
//                [[NSNotificationCenter defaultCenter] postNotificationName:BuySuccessNotify object:product_id];
//            }
//        }else//真实购买
//        {
//            NSDictionary *receiptDic = [NSDictionary dictionaryWithDictionary:[appResultDic objectForKey:@"receipt"]];
//            NSArray *in_appArr = [receiptDic objectForKey:@"in_app"];
//            NSString *product_id = [in_appArr lastObject][@"product_id"];

//            [[NSNotificationCenter defaultCenter] postNotificationName:BuySuccessNotify object:product_id];
//        }
#warning 真实购买
        if ([[appResultDic objectForKey:@"status"] intValue] == 21007) {
            NSDictionary *receiptDic = [NSDictionary dictionaryWithDictionary:[appResultDic objectForKey:@"receipt"]];
            NSString *product_id = [receiptDic objectForKey:@"product_id"];
            [[NSNotificationCenter defaultCenter] postNotificationName:BuySuccessNotify object:product_id];
        }
#warning sandbox调试
        if ([[appResultDic objectForKey:@"status"] intValue] == 0) {
            NSDictionary *receiptDic = [NSDictionary dictionaryWithDictionary:[appResultDic objectForKey:@"receipt"]];
            
            NSString *product_id = [receiptDic objectForKey:@"product_id"];
            [[NSNotificationCenter defaultCenter] postNotificationName:BuySuccessNotify object:product_id];
        }
    }
}

#pragma mark - alert
- (void)alert:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HidHud object:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil, nil];
    
    [alert show];
}

- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
@end
