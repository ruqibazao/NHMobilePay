//
//  NHAliPay.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NHPayHelper.h"


//支付宝支付状态
typedef NS_ENUM(NSInteger ,AliPayResultState) {
    AliPay_Result_State_Deal = 8000, //订单处理中
    AliPay_Result_State_Failure = 4000, //订单支付失败
    AliPay_Result_State_Successful = 9000, //支付成功
    AliPay_Result_State_Cacel = 6001, //订单取消
    AliPay_Result_State_NetWorkEoor = 6002, //网络连接出错
};

@interface NHAliPay : NHPayHelper

@end
