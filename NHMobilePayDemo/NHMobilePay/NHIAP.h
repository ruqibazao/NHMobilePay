//
//  NHIAP.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NHPayHelper.h"
#import <StoreKit/StoreKit.h>
#import "NHOrderManage.h"

typedef void (^NHSKPaymentTransactionFailureBlock)(SKPaymentTransaction *transaction, NSError *error);
typedef void (^NHSKPaymentTransactionDidReceiveResponse)(SKProductsResponse *response);
typedef void (^NHSKPaymentTransactionSuccessBlock)(SKPaymentTransaction *transaction);
typedef void (^NHSKProductsRequestFailureBlock)(NSError *error);
typedef void (^NHSKProductsRequestSuccessBlock)(NSArray <SKProduct *> *products, NSArray <NSString *> *invalidIdentifiers);
typedef void (^NHStoreFailureBlock)(NSError *error);
typedef void (^NHStoreSuccessBlock)();

@protocol NHIAPDelegate <NSObject>
- (void)requestDidFinish:(NSArray *)productIdentifiers error:(NSError *)error;
- (void)compaleteTransaction:(SKPaymentTransaction *)transaction error:(NSError *)error;
@end

@interface NHIAP : NHPayHelper
@property (nonatomic, assign)id<NHIAPDelegate> delegate;

/**
 *  当前请求/正在购买的产品
 */
@property (nonatomic, strong, readonly) SKProduct *currentProduct;
@property (nonatomic, strong, readonly) NHOrderInfo *orderinfo;
NSSingletonH(NHIAP)
/**
 *  从苹果服务器请求可出售的产品
 *
 *  @param proudctIDS  产品id
 */
+ (instancetype)requestProducts:(NSArray *)proudctIDS
                        success:(NHSKProductsRequestSuccessBlock)successBlock
                        failure:(NHSKProductsRequestFailureBlock)failureBlock;

/**
 *  添加需要购买的产品
 *
 *  @param productIdentifier  产品id
 *  @param successBlock      交易成功
 *  @param failureBlock      交易失败
 */
- (instancetype)addPayment:(NSString*)productIdentifier
               payObjectID:(NSString *)payObjectID
                   success:(NHSKPaymentTransactionSuccessBlock)successBlock
                   failure:(NHSKPaymentTransactionFailureBlock)failureBlock;

/**
 *  结束交易
 */
- (void)removeTransactionObserver;

/**
 *  检查上一次未完成的订单
 *  如用户在支付完后，但还未向自己的服务成功通知时，出现的一系列异常(断网，断电...)
 *  @return 所有未完成的订单信息
 */
+ (NSArray <NHOrderInfo *>*)checkUnfinishedOrder;

@end
