//
//  NHIAP.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHIAP.h"
#import "CommonCrypto/CommonDigest.h"

//获取BundleID
#define NHGetBundleID [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]


@interface NHIAP ()<SKProductsRequestDelegate,SKPaymentTransactionObserver,SKRequestDelegate>
@property (nonatomic, copy  ) NSString *currentProductIdentifier; //当前的产品ID
@property (nonatomic, copy  ) NSString *transactionIdentifier; //订单号
@property (nonatomic, copy  ) NSString *proudctPrice; //产品价格
@property (nonatomic, copy  ) NSArray  *proudctIDS; //外界传入的所有产品ID
@property (nonatomic, copy, ) NSString *payObjectID; //支付者id
@property (nonatomic, copy, ) NSNumber *payTimeStamp; //支付时间(这里以时间戳格式保存)

@property (nonatomic, copy  ) NSString *receiptDataStr; //apple返回的receiptData数据
@property (nonatomic, copy  ) NSArray <SKProduct *> *allProducts; //store查询到的所有有效产品
@property (nonatomic, copy  ) NSArray <NSString *> *invalidProductsIdentifier; //store查询到的无效产品ID
@property (nonatomic, strong) NSMutableDictionary *storeAllProducts; //键：store查询的具体产品, key：产品ID
@property (nonatomic, copy  ) NHSKProductsRequestSuccessBlock productSuccessBlock;
@property (nonatomic, copy  ) NHSKProductsRequestFailureBlock productFailureBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionSuccessBlock transactionSuccessBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionFailureBlock transactionFailureBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionDidReceiveResponse receiveResponse;
@property (nonatomic, strong) SKPaymentTransaction *paymentTransaction;
@end

@implementation NHIAP
NSSingletonM(NHIAP)

- (NSMutableDictionary *)storeAllProducts{
    if (!_storeAllProducts) {
        _storeAllProducts = [[NSMutableDictionary alloc] init];
    }
    return _storeAllProducts;
}

+ (NSArray<NHOrderInfo *> *)checkUnfinishedOrder{
    return [NHOrderManage checkUnfinishedOrder];
}

//从apple查询可供销售购买产品的信息
+ (instancetype)requestProducts:(NSArray *)identifiers
                        success:(NHSKProductsRequestSuccessBlock)successBlock
                        failure:(NHSKProductsRequestFailureBlock)failureBlock {
    
    return [[NHIAP sharedNHIAP] requestProducts:identifiers
                                        success:successBlock
                                        failure:failureBlock];
}

- (instancetype)requestProducts:(NSArray *)proudctIDS
                        success:(NHSKProductsRequestSuccessBlock)successBlock
                        failure:(NHSKProductsRequestFailureBlock)failureBlock {
    self.productSuccessBlock = successBlock;
    self.productFailureBlock = failureBlock;
    self.proudctIDS = proudctIDS;
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:proudctIDS]];
    productRequest.delegate = self;
    [productRequest start];
    
    return self;
}


- (instancetype)addPayment:(NSString *)productIdentifier
               payObjectID:(NSString *)payObjectID
                   success:(NHSKPaymentTransactionSuccessBlock)successBlock
                   failure:(NHSKPaymentTransactionFailureBlock)failureBlock {
    if (!_storeAllProducts) {
        tipWithMessage(@"请调用：从apple查询可供销售购买产品的信息 访求");
        return nil;
    }
    
    if (![SKPaymentQueue canMakePayments]) {
        tipWithMessage(@"您的手机没有打开程序内付费购买");
        return nil;
    }
    
    self.transactionSuccessBlock = successBlock;
    self.transactionFailureBlock = failureBlock;
    
    //发送购买请求
    _currentProductIdentifier = productIdentifier;
    _currentProduct = [_storeAllProducts objectForKey:productIdentifier];
    _proudctPrice = [NSString stringWithFormat:@"%@",_currentProduct.price];
    _payObjectID = payObjectID;

    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    SKPayment *payment = [SKPayment paymentWithProduct:_currentProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    return self;
}

#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request{
    tipWithMessage(@"获取产品成功");
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestDidFinish:error:)]) {
        [self.delegate requestDidFinish:_allProducts error:nil];
    }
    if (self.productSuccessBlock) {
        self.productSuccessBlock(_allProducts, _invalidProductsIdentifier);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    tipWithMessage(error.localizedDescription);
    NSLog(@"%@",@"请求产品信息失败");
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestDidFinish:error:)]) {
        [self.delegate requestDidFinish:nil error:error];
    }
    if (self.productFailureBlock) {
        self.productFailureBlock(error);
    }
}


#pragma mark - SKProductsRequestDelegate
//查询成功后的回调（收到产品返回信息）
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    _allProducts = response.products;
    _invalidProductsIdentifier = response.invalidProductIdentifiers;
    
    if (_invalidProductsIdentifier.count > 0) {
        NSString *sting = [NSString stringWithFormat:@"无效的ProductID:%@",response.invalidProductIdentifiers];
        tipWithMessages(sting, nil, @"确定", @"知道了");
    }
    
    if (_allProducts.count == 0) {//无法获取产品信
        tipWithMessage(@"获取产品个数：0");
        NSLog(@"获取产品个数：0");
//        if (_receiveResponse) {
//            _receiveResponse(response);
//        }
        return;
    }
    
    for(SKProduct *product in _allProducts){
        [self.storeAllProducts setObject:product forKey:product.productIdentifier];
    }
}


#pragma mark - SKPaymentTransactionObserver
//当下载状态更改时发送。
//- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads{}

//购买操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *paymentTransaction in transactions) {
        NSLog(@"payTransaction = %@",paymentTransaction.transactionIdentifier);
        switch (paymentTransaction.transactionState) {
            case SKPaymentTransactionStatePurchased: //交易完成
                [queue finishTransaction:paymentTransaction];
                [self compaleteTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStateFailed:  //交易失败
                [queue finishTransaction:paymentTransaction];
                [self failedTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStateRestored:  //已经购买过该商品
                //恢复购买成功
                [queue finishTransaction:paymentTransaction];
                [self resroreTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStatePurchasing: //商品添加进列表
                //正在请求付费信息

                break;
            default:
                break;
        }
    }
}


//恢复操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"恢复操作后的回调%@",queue);
    tipWithMessage(@"恢复操作后的回调");
}

//恢复已购买商品
- (void)resroreTransaction:(SKPaymentTransaction *)paymentTransaction{
    tipWithMessage(@"恢复已购买商品");
    NSLog(@"恢复已购买商品:%@",paymentTransaction);
    [[SKPaymentQueue defaultQueue] finishTransaction:paymentTransaction];
}

//交易完成调用
- (void)compaleteTransaction:(SKPaymentTransaction *)paymentTransaction{
    tipWithMessage(@"交易完成");
    _paymentTransaction = paymentTransaction;
    _transactionIdentifier = paymentTransaction.transactionIdentifier;
    [self verifyPurchaseWithPaymentTransaction:paymentTransaction];
    
    [NHOrderManage addTransactionIdentifier:_transactionIdentifier
                             receiptDataStr:_receiptDataStr
                               proudctPrice:_proudctPrice
                                payObjectID:_payObjectID];
    
    NSLog(@"交易完成:%@",paymentTransaction);
    NSString * productIdentifier = paymentTransaction.payment.productIdentifier;
    if ([productIdentifier length] > 0) {
        // 向自己的服务器验证购买凭证
       
    }
}

//交易失败后调用
- (void)failedTransaction:(SKPaymentTransaction *)paymentTransaction{
    NSLog(@"交易失败:%@",paymentTransaction.error.localizedDescription);
    NSString *errString;
    switch (paymentTransaction.error.code) {
        case SKErrorUnknown:
            errString = @"交易失败，请重试";
            break;
        case SKErrorClientInvalid:
            errString = @"当前appleID无法购买商品,请联系苹果客服！";
            break;
        case SKErrorPaymentCancelled:
            errString = @"订单已取消";
            break;
        case SKErrorPaymentInvalid:
            errString = @"订单无效!";
            break;
        case SKErrorPaymentNotAllowed:
            errString = @"当前设备无法购买商品,请联系苹果客服！";
            break;
        case SKErrorCloudServicePermissionDenied:
            errString = @"当前appleID无法购买商品,请联系苹果客服！";
            break;
        case SKErrorCloudServiceNetworkConnectionFailed:
            errString = @"当前设备无法连接到网络！";
            break;
        case SKErrorStoreProductNotAvailable:
            errString = @"当前商品不可用";
            break;
        default:
            errString = @"发生一个未知的错误！";
            break;
    }
    if (self.transactionFailureBlock) {
        self.transactionFailureBlock(_paymentTransaction, paymentTransaction.error);
    }
    tipWithMessage(errString);
}


-(void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)payTransaction {
    NSLog(@"\n\n订单号：%@",payTransaction.transactionIdentifier);

    //从沙盒中获取交易凭证并且拼接成请求体数据
    NSURL *receiptUrl   = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];// Sent to the server by the device
    _receiptDataStr     = [receiptData base64EncodedStringWithOptions:0];

    if (receiptData.length == 0) {
        /* ... Handle error ... */
        tipWithMessage(@"充值验证失败！");
        return;
    }
    
    //去苹果服务器验证
    [self verifyPurchaseInAppleServeUrlIsProduct:YES];
}

- (void)verifyPurchaseInAppleServeUrlIsProduct:(BOOL)isProduct {
    __weak __typeof(self)weakself = self;
    [NHPayApi IAPVerifyIsProductEnvironment:isProduct receiptStr:_receiptDataStr complete:^(id resultObject, NSError *error) {
        
        if (error) {/* ... Handle error ... */
            tipWithMessage(error.localizedDescription);
        }else{
            static NSString  *statusKey  = @"status";
            static NSInteger successCode = 0;
            static NSInteger sandboxCode = 21007;
            static NSString  *sandbox    = @"Sandbox";
            static int isTextEnvironment = 1;
            NSString  *environment = [NSString stringWithFormat:@"%@",[resultObject objectForKey:@"environment"]];
            NSInteger statusCode   = [resultObject[statusKey] integerValue];
            
            if (!resultObject || error) {/* ... Handle error ...*/
                tipWithMessage(@"充值失败！");
                if (self.transactionFailureBlock) {
                    self.transactionFailureBlock(_paymentTransaction, error);
                }
                
            } else {/* ... Send a response back to the device ... */
                //验证信息是否匹配
                if (statusCode == successCode && [self verifyAppReceipt:resultObject]) {
                    //通过自己的服务器验证
                    if ([environment isEqualToString:sandbox]) {
                        isTextEnvironment = 1;
                    }else{
                        isTextEnvironment = 0;
                    }
                    
                    [weakself verifyPurchaseInServe:_receiptDataStr error:error];
                    NSLog(@"\nverifyPurchaseInApple:%@",[resultObject objectForKey:@"status"]);

                } else if (statusCode == sandboxCode){
                    //验证环境反了，重新验证一次
                    [weakself verifyPurchaseInAppleServeUrlIsProduct:NO];
                    NSLog(@"\nverifyPurchaseInApple:\n%@",resultObject);

                } else {
                    if (self.transactionFailureBlock) {
                        self.transactionFailureBlock(_paymentTransaction, error);
                    }
                    tipWithMessage(@"充值失败,请重试！");
                }
            }
        }
    }];
}

//通知自己的服务验证,app内验证成功才通知
- (void)verifyPurchaseInServe:(NSString *)receiptData error:(NSError *)error {
    if (self.transactionSuccessBlock) {
        self.transactionSuccessBlock(_paymentTransaction);
    }
}

- (BOOL)verifyAppReceipt:(NSDictionary*)jsonResponse {
    NSDictionary *receipt = [jsonResponse objectForKey:@"receipt"];
    NSString *bundle_id = [receipt objectForKey:@"bundle_id"];
    NSString *product_id = [receipt objectForKey:@"in_app"][0][@"product_id"];
    NSString *transaction_id = [receipt objectForKey:@"in_app"][0][@"original_transaction_id"];
    
    if (!receipt) return NO;
    
    if (![bundle_id isEqualToString:NHGetBundleID]) return NO;
    
    if (![product_id isEqualToString:_currentProductIdentifier]) return NO;
    
    if (![transaction_id isEqualToString:_transactionIdentifier]) return NO;
    
    return YES;
}

//打印产品信息
- (void)printfProductinfos:(SKProduct *)product {
    NSLog(@"产品付费数量: %d", (int)[_allProducts count]);
    NSLog(@"product info");
    NSLog(@"SKProduct 描述信息%@", [product description]);
    NSLog(@"产品标题 %@" , product.localizedTitle);
    NSLog(@"产品描述信息: %@" , product.localizedDescription);
    NSLog(@"价格: %@" , product.price);
    NSLog(@"Product id: %@" , product.productIdentifier);
}

- (void)removeTransactionObserver{
//    [[SKPaymentQueue defaultQueue] finishTransaction:_paymentTransaction];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    _currentProduct = nil;
    _paymentTransaction = nil;
    self.delegate = nil;
}

- (void)dealloc{
    [self removeTransactionObserver];
}


@end
