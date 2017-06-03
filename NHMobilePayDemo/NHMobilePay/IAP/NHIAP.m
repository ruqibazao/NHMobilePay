//
//  NHIAP.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHIAP.h"
#import "NHPaymentVerify.h"



NSString *const NHIAPcompleteRecharge = @"completeRecharge";


@interface NHIAP ()<SKProductsRequestDelegate,SKPaymentTransactionObserver,SKRequestDelegate>
@property (nonatomic, copy  ) NHSKProductsRequestSuccessBlock productSuccessBlock;
@property (nonatomic, copy  ) NHSKProductsRequestFailureBlock productFailureBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionSuccessBlock transactionSuccessBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionFailureBlock transactionFailureBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionDidReceiveResponse receiveResponse;
@property (nonatomic, copy  ) NHSKPaymentCompleteBlock paymentCompleteBlock;

@property (nonatomic, copy  ) NSString *currentProductIdentifier; //当前的产品ID
@property (nonatomic, copy  ) NSString *proudctPrice; //产品价格
@property (nonatomic, copy  ) NSArray  *proudctIDS; //外界传入的所有产品ID
@property (nonatomic, copy  ) NSString *payObjectID; //支付者id
@property (nonatomic, copy  ) NSNumber *payTimeStamp; //支付时间(这里以时间戳格式保存)
@property (nonatomic, copy  ) NSArray <SKProduct *> *allProducts; //store查询到的所有有效产品
@property (nonatomic, copy  ) NSArray <NSString *> *invalidProductsIdentifier; //store查询到的无效产品ID
@property (nonatomic, strong) NSMutableDictionary *storeAllProducts; //键：store查询的具体产品, key：产品ID
@property (nonatomic, strong) NSDictionary *productsPrice; //key：产品ID, value：价格
@property (nonatomic, strong) NSString *coustomTransactionID;

@end

@implementation NHIAP
NSSingletonM(NHIAP)

- (NSMutableDictionary *)storeAllProducts{
    if (!_storeAllProducts) {
        _storeAllProducts = [[NSMutableDictionary alloc] init];
    }
    return _storeAllProducts;
}

- (NSDictionary *)productsPrice {
    if (!_productsPrice) {
        _productsPrice = @{
                           @"com.cnlive.mijialiveshow01" : @6,
                           @"com.cnlive.mijialiveshow02" : @30,
                           @"com.cnlive.mijialiveshow03" : @88,
                           @"com.cnlive.mijialiveshow04" : @588,
                           @"com.cnlive.mijialiveshow05" : @1590,
                           @"com.cnlive.mijialiveshow06" : @1998,
                        };
    }
    return _productsPrice;
}

- (NSArray<NHOrderInfo *> *)checkAllUnfinishedOrder {
    
    _payObjectID = @"123";
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    return [NHOrderManage checkHistyUnfinishedOrder];
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
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    _isRequestProudct = YES;
    self.productSuccessBlock = successBlock;
    self.productFailureBlock = failureBlock;
    self.proudctIDS = proudctIDS;
    NSSet *productSet = [NSSet setWithArray:proudctIDS ?: [self.productsPrice allKeys]];
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productSet];
    productRequest.delegate = self;
    [productRequest start];
    return self;
}


- (instancetype)addPayment:(NSString *)productIdentifier
               payObjectID:(NSString *)payObjectID
           paymentComplete:(NHSKPaymentCompleteBlock)paymentComplete
                   success:(NHSKPaymentTransactionSuccessBlock)successBlock
                   failure:(NHSKPaymentTransactionFailureBlock)failureBlock {
    
    self.transactionSuccessBlock = successBlock;
    self.transactionFailureBlock = failureBlock;
    self.paymentCompleteBlock = paymentComplete;

    //发送购买请求
    _currentProductIdentifier = productIdentifier;
    _currentProduct = [_storeAllProducts objectForKey:productIdentifier];
    _proudctPrice = [NSString stringWithFormat:@"%@",_currentProduct.price];
    _payObjectID = payObjectID;
    _coustomTransactionID = [NHPayApi getCurrentDateBaseStyle:nil];
    
    if (!_storeAllProducts) {
        tipWithMessage(@"正在更新商品信息...");
        return nil;
    }
    
    if (![SKPaymentQueue canMakePayments]) {
        tipWithMessage(@"您的手机没有打开程序内付费购买");
        return nil;
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    SKPayment *payment = [SKPayment paymentWithProduct:_currentProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    return self;
}


#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(requestDidFinish:error:)]) {
        [self.delegate requestDidFinish:_allProducts error:nil];
    }
    if (self.productSuccessBlock) {
        self.productSuccessBlock(_allProducts, _invalidProductsIdentifier);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    kNSLog(@"%@",@"请求产品信息失败");
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
    _isRequestProudct = NO;

    _allProducts = response.products;
    _invalidProductsIdentifier = response.invalidProductIdentifiers;
    
    if (_invalidProductsIdentifier.count > 0) {
        NSString *sting = [NSString stringWithFormat:@"无效的商品:%@",response.invalidProductIdentifiers];
        tipWithMessages(sting, nil, @"确定", @"知道了");
    }
    
    if (_allProducts.count == 0) {//无法获取产品信
        tipWithMessage(@"暂无可出售商品");
        NSLog(@"获取产品个数：0");
        return;
    }
    
    for(SKProduct *product in _allProducts){
        [self  printfProductinfos:product];
        [self.storeAllProducts setObject:product forKey:product.productIdentifier];
    }
}


#pragma mark - SKPaymentTransactionObserver
//购买操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *paymentTransaction in transactions) {
        NSLog(@"payTransaction = %@",paymentTransaction.transactionIdentifier);
        switch (paymentTransaction.transactionState) {
            case SKPaymentTransactionStatePurchased: //交易完成
                [self compaleteTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStateFailed:  //交易失败
                [self failedTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStateRestored:  //已经购买过该商品
                //恢复购买
                [self resroreTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStatePurchasing: //商品添加进列表
                //添加正在请求付费信息
                [NHPaymentVerify sendinfoToMeServeTransactionInfoWithPrice:_proudctPrice
                                                                   isPayed:NO
                                                                 payUserID:_payObjectID 
                                                       customTransactionID:_coustomTransactionID];
                kNSLog(@"\n请求付费信息:\n订单号:%@",paymentTransaction.transactionIdentifier);
                break;
                
            case SKPaymentTransactionStateDeferred:
                kNSLog(@"\n订单挂起:\n订单号:%@",paymentTransaction.transactionIdentifier);
                break;
                
            default:
                break;
        }
    }
}

//恢复已购买商品
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    for (SKPaymentTransaction *paymentTransaction in queue.transactions) {
        kNSLog(@"%ld  --  %@",queue.transactions.count,paymentTransaction.transactionIdentifier);
        if (paymentTransaction.transactionIdentifier) {
            [self verifyPurchaseWithPaymentTransaction:paymentTransaction handleRestore:YES];
        }
    }
}

//恢复已购买商品
- (void)resroreTransaction:(SKPaymentTransaction *)paymentTransaction {
    tipWithMessage(@"恢复已购买商品");
    NSLog(@"恢复已购买商品:%@",paymentTransaction.transactionIdentifier);
    [self verifyPurchaseWithPaymentTransaction:paymentTransaction handleRestore:YES];
}


//删除完成的交易
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    kNSLog(@"removedTransactions:%ld",transactions.count);
}

//恢复操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"恢复操作后的回调%@",queue.transactions.firstObject.transactionIdentifier);
#if DEBUG
    tipWithMessage(@"恢复操作后的回调");
#endif
}

//当下载状态更改时发送。
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads{
    kNSLog(@"%@",queue.transactions.firstObject.transactionIdentifier)
}

//交易完成调用
- (void)compaleteTransaction:(SKPaymentTransaction *)paymentTransaction {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (_paymentCompleteBlock) {
        _paymentCompleteBlock(paymentTransaction);
    }
    
    kNSLog(@"支付完成订单号: %@",paymentTransaction.transactionIdentifier);
    NSString * productIdentifier = paymentTransaction.transactionIdentifier;
    if (productIdentifier) {
        [self verifyPurchaseWithPaymentTransaction:paymentTransaction handleRestore:NO];
    }
}


//交易失败后调用
- (void)failedTransaction:(SKPaymentTransaction *)paymentTransaction {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //交易结束了，可以删除正在支付的订单
    [[SKPaymentQueue defaultQueue] finishTransaction:paymentTransaction];
        
    NSLog(@"交易失败:%@",paymentTransaction.error.localizedDescription);
    NSString *errString;
    switch (paymentTransaction.error.code) {
        case SKErrorUnknown:
            errString = @"发送交易请求失败，请重试";
            break;
        case SKErrorClientInvalid:
            errString = @"当前appleID无法购买商品!";
            break;
        case SKErrorPaymentCancelled:
            errString = @"用户主动取消支付";
            break;
        case SKErrorPaymentInvalid:
            errString = @"订单无效!";
            break;
        case SKErrorPaymentNotAllowed:
            errString = @"无法购买商品，当前设备不允许付款！";
            break;
        case SKErrorCloudServicePermissionDenied:
            errString = @"当前appleID无法购买商品!";
            break;
        case SKErrorCloudServiceNetworkConnectionFailed:
            errString = @"当前设备无法连接到网络！";
            break;
        case SKErrorStoreProductNotAvailable:
            errString = @"当前商品不可用";
            break;
        default:
            errString = nil;
            break;
    }
    if (self.transactionFailureBlock) {
        self.transactionFailureBlock(paymentTransaction, ERROR_MSG(paymentTransaction.error.code, ERROR_INFO(errString ?: @"", nil, nil)));
    }
    if (errString) {
//        tipWithMessage(errString);
    }
}


/**
 服务器验证

 @param paymentTransaction 当前交易对象
 @param handleRestore 是否为恢复购买
 */
-(void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)paymentTransaction handleRestore:(BOOL)handleRestore{
    NSLog(@"\n\n订单号：%@",paymentTransaction.transactionIdentifier);
    
    //去服务器验证
    __weak __typeof(self)weakself = self;
    BOOL isHandleRestore;
    if (handleRestore) {
        isHandleRestore = YES;
    } else {
        isHandleRestore = NO;
    }
    NSString *productsPrice = [NSString stringWithFormat:@"%@",[self.productsPrice objectForKey:paymentTransaction.payment.productIdentifier]];
    [[NHPaymentVerify createVerify] verifyPaymentResultSandbox:NO
                                            paymentTransaction:paymentTransaction
                                                 productsPrice:productsPrice
                                                   payObjectID:_payObjectID
                                           customTransactionID:_coustomTransactionID
                                                 handleRestore:isHandleRestore
                                                 paymentResult:^(id result,
                                                                 SKPaymentTransaction *payTransaction,
                                                                 NSInteger successCode,
                                                                 NSError *error)
     {
         if (successCode == 0 && !error) {
             [[SKPaymentQueue defaultQueue] finishTransaction:payTransaction];
             if (self.transactionSuccessBlock && !isHandleRestore) {
                 self.transactionSuccessBlock(paymentTransaction, result);
             }
             
         } else {
             if (weakself.transactionFailureBlock && !isHandleRestore) {
                 weakself.transactionFailureBlock(paymentTransaction, error);
             }
         }
    }];
}

//打印产品信息
- (void)printfProductinfos:(SKProduct *)product {
    NSLog(@"product info");
    NSLog(@"SKProduct 描述信息%@", [product description]);
    NSLog(@"产品标题 %@" , product.localizedTitle);
    NSLog(@"产品描述信息: %@" , product.localizedDescription);
    NSLog(@"价格: %@" , product.price);
    NSLog(@"Product id: %@\n\n" , product.productIdentifier);
}

- (void)removeTransactionObserver {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    _currentProduct = nil;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
