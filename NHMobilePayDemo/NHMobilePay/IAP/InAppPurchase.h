//
//  InAppPurchase.h
//  WonderfulLive
//
//  Created by 张旭 on 2016/11/4.
//  Copyright © 2016年 CNLive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef enum{
    IAP6p6000 = 6, //6¥6000
    IAP12p12000,   //12¥12000
    IAP30p30000    //30¥30000
}buyCoinsType;

@interface InAppPurchase : NSObject

@property (nonatomic ,copy) NSString *tradeNo;
@property (nonatomic ,copy) NSString *signValue;

- (instancetype)initWithCoinType:(buyCoinsType)type baseView:(UIView *)baseView;
@end
