//
//  NHOrderManage.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/9.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NHOrderInfo : NSObject
@property (nonatomic, copy, readonly) NSString *receiptDataStr; //apple返回的receiptData数据
@property (nonatomic, copy, readonly) NSString *transactionIdentifier; //订单号
@property (nonatomic, copy, readonly) NSString *proudctPrice; //产品价格
@property (nonatomic, copy, readonly) NSString *payObjectID; //支付者id
@property (nonatomic, copy, readonly) NSString *payTimeStamp; //支付时间(这里以时间戳格式保存)
@end


@interface NHOrderManage : NSObject

/**
 *  添加订单信息
 *
 *  @param transactionIdentifier apple返回的订单号
 *  @param receiptDataStr        订单data信息
 *  @param proudctPrice          充值金额
 *  @param payObjectID           充值用户DI(根据自己的项目需要来定)，这里只为保存订单信息时用到
 *
 */
+ (BOOL)addTransactionIdentifier:(NSString *)transactionIdentifier
                  receiptDataStr:(NSString *)receiptDataStr
                    proudctPrice:(NSString *)proudctPrice
                     payObjectID:(NSString *)payObjectID;

/**
 通过订单号删除相应的订单信息
 @param transactionIdentifier apple返回的订单号
 */
+ (BOOL)deleteTransactionIdentifier:(NSString *)transactionIdentifier;


/**
 *  检查上一次未完成的订单
 *  如用户在支付完后，但还未向自己的服务成功通知时，出现的一系列异常(断网，断电...)
 *  @return 所有未完成的订单信息
 */
+ (NSArray <NHOrderInfo *>*)checkUnfinishedOrder;


/**
 通过订单号获取订单信息
 @param transactionIdentifier apple返回的订单号
 */
+ (NHOrderInfo *)getOrderInfoTransactionIdentifier:(NSString *)transactionIdentifier;



@end



