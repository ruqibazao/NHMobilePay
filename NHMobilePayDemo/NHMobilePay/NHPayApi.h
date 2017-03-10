//
//  NHApi.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ResultBlock)(id resultObject, NSError *error);

@interface NHPayApi : NSObject

+ (void)IAPVerifyIsProductEnvironment:(BOOL)isProductEnvironment
                           receiptStr:(NSString *)receiptStr
                             complete:(ResultBlock)complete;


+ (void)apiRequestMeLive:(NSDictionary *)parameter urlString:(NSString *)urlString complete:(ResultBlock)complete;




+ (NSString *)getCurrentDateBaseStyle:(NSData *)data;

//加密
+ (NSString*)sha1:(NSString *)string;

//签名机制
+ (NSString *)signvalue:(NSDictionary*)parameter;

@end
