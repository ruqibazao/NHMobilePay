//
//  NHPayHelper.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NHSingleton.h"
#import "NHPayApi.h"
#import "NHOrderManage.h"

//自定提醒窗口
NS_INLINE void tipWithMessage(NSString *message){
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alerView show];
        [alerView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:@[@0, @1] afterDelay:1.5];
    });
}

//自定提醒窗口
NS_INLINE void tipWithMessages(NSString *message, id delegate, NSString *cancelTitle, NSString *otherTitle){
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
        [alerView show];
        //        [alerView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:@[@0, @1] afterDelay:0.9];
    });
}


typedef NS_ENUM(NSInteger,PayType) {
    PayType_WeChatpay = 0,  //微信支付
    PayType_Alipay = 1,     //支付宝支付
    PayType_ApplePay = 2,   //苹果支付
};

//支付结果
typedef NS_ENUM(NSInteger,PayResultType){
    PayType_Result_Failure = 0, // 支付失败
    PayType_Result_Successful = 1, // 支付成功
    PayType_Result_Cancel = 2, //支付取消
    PayType_Result_RecharsgeFailure = 3, //充值失败
    PayType_Result_RecharsgeNetworkEorr = 4, //支付后查询网络异常
    PayType_Result_ServerFailure = 5,  //支付前到服务器获取参数失败
    PayType_Result_OrderDeal = 6,       //订单交易中
};

typedef void (^PayCompleteBlock)(id result, NSString *transactionIdentifier, NSError *error);

@interface NHPayHelper : NSObject
@property (nonatomic, copy) PayCompleteBlock completeBlock;
@end
