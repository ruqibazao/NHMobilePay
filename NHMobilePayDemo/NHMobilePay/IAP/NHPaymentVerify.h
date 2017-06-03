//
//  NHPaymentVerify.h
//  BaiKeMiJiaLive
//
//  Created by neghao on 2017/5/26.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


@class NHOrderInfo;
//获取BundleID
#define NHGetBundleID [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]

typedef  void(^NHVerifyPaymentResult)(id result, SKPaymentTransaction *payTransaction, NSInteger successCode, NSError *error);

@interface NHPaymentVerify : NSObject

/**
 快速初始化
 */
+ (instancetype)createVerify;


/**
 去苹果服务器验证

 @param sandbox 是否为沙盒环境
 @param payObjectID 支付者ID
 @param customTransactionID 自定义订单ID(蜜家服务需要用到)
 @param handleRestore 是否为恢复购买
 */
- (void)verifyPaymentResultSandbox:(BOOL)sandbox
                paymentTransaction:(SKPaymentTransaction *)payTransaction
                     productsPrice:(NSString *)productsPrice
                       payObjectID:(NSString *)payObjectID
               customTransactionID:(NSString *)customTransactionID
                     handleRestore:(BOOL)handleRestore
                     paymentResult:(NHVerifyPaymentResult)paymentResult;

/**
 发送支付信息到蜜家服务器
 */
+ (void)sendinfoToMeServeTransactionInfoWithPrice:(NSString *)price
                                          isPayed:(BOOL)isPayed
                                        payUserID:(NSString *)payUserID
                              customTransactionID:(NSString *)customTransactionID;

/**
 恢复充值的验证
 */
+ (void)verifyPaymentResultWithNHOrderInfo:(NHOrderInfo *)orderInfo;

@end
