//
//  NHApi.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHPayApi.h"
#import "NHPayHelper.h"
#import <CommonCrypto/CommonDigest.h>


#define PayURL_payed              @"https://api.cnlive.com/open/api2/unifypay/payed"
#define PayURL_prepay             @"https://api.cnlive.com/open/api2/unifypay/prepay"
#define Sandbox_IAPURL            @"https://sandbox.itunes.apple.com/verifyReceipt" //applePay 沙盒环境
#define Production_IAPURL         @"https://buy.itunes.apple.com/verifyReceipt" //applePay 正式环境

@implementation NHPayApi
//去苹果服务器验证
+ (void)IAPVerifyIsSandboxEnvironment:(BOOL)isSandboxEnvironment
                           receiptStr:(NSString *)receiptStr
                             complete:(ResultBlock)complete {

    // Create the JSON object that describes the request
    NSError *error = nil;
    NSDictionary *requestContents = @{
                                      @"receipt-data":receiptStr
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    
    NSString *iapUrl = Sandbox_IAPURL;
    if (!isSandboxEnvironment) {
        iapUrl = Production_IAPURL;
    }
    
    // Create a POST request with the receipt data.
    NSURL *storeURL = [NSURL URLWithString:iapUrl];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    
    // Make a connection to the iTunes Store on a background queue.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:storeRequest
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             NSError *error2;
             NSDictionary *jsonResponse;
             if (data) {
                 jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error2];
             }
             if (complete) {
                 complete(jsonResponse,error);
             }
         });
     }];
}


/** 通知自己的服务器验证*/
+ (void)payVerifyWithReceiptData:(NSString *)receiptData
                  transaction_id:(NSString *)transaction_id
                        totalFee:(NSString *)totalFee
                          userID:(NSString *)userID
                         is_test:(int)is_test
                        complete:(NHPayCompleteBlock)complete {
    NSString *requstUrl;
    if (is_test == 1) {
        requstUrl = @"http://xxxx.abc.com:9283/apple_pay";
    }else{
        requstUrl = @"http://oooo.abc.com:9283/apple_pay";
    }
    
    NSDictionary *parameters = @{
                                 @"receipt":receiptData,
                                 @"userid":userID,
                                 @"total_fee":totalFee,
                                 @"transaction_id":@([transaction_id longLongValue]),
                                 @"is_test":@(is_test),
                                 @"currencyType":@(1)
                                 };
    NSLog(@"\n验证参数：%@-%@-%@-%d",userID,totalFee,transaction_id,is_test);
    NSObject *object = [parameters objectForKey:@"userid"];
    if (object == nil) {
        NSAssert(object != nil, @"参数错误");
        return;
    }
    
    //网络请求请求....
}

//向蜜家服务器发送支付信息
+ (void)sendinfoToMeServePrice:(NSString *)price
                 transactionID:(NSString *)transactionID
                        userID:(NSString *)userID
                       isPayed:(BOOL)isPayed
                      complete:(ResultBlock)complete {
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    NSString *urlStr = PayURL_prepay;
    NSDictionary *parameter = [self prepayInfoPrice:[price intValue] transactionID:transactionID userID:userID];;
    if (isPayed) {
        urlStr = PayURL_payed;
        parameter = [self payedInfoTransactionId:transactionID];
    }
    
    
    NSString *signParameterStr = [NSString stringWithFormat:@"%@&key=%@",[NHPayApi signvalue:parameter], @""];
    NSString *shaParameterStr = [[NHPayApi sha1:signParameterStr] uppercaseString];
    NSMutableDictionary *parameter_sig = parameter.mutableCopy;
    [parameter_sig setObject:shaParameterStr forKey:@"sign"];
    
    NSURL *URL = [NSURL URLWithString:isPayed ? PayURL_payed : PayURL_prepay];
    URL = NSURLByAppendingQueryParameters(URL, parameter_sig);
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *jsonResponse;
        if (error == nil) {
            // Success
            jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            //            NSLog(@"cnlive:\n%@ \nerror:%@",jsonResponse,error);
            NSLog(@"URL Session Task Succeeded: HTTP %ld", (long)((NSHTTPURLResponse*)response).statusCode);
            
        } else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
        if (complete) {
            complete(jsonResponse,error);
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

//MATK:请求参数拼接
//准备支付的参数
+ (NSDictionary *)prepayInfoPrice:(int)price transactionID:(NSString *)transactionID userID:(NSString *)userID{
    NSDictionary *parameter = @{
                                @"sp_id":@"118_itdr6ijv09",
                                @"appId":@"118_itdr6ijv09",
                                @"out_trade_no":transactionID ?: [self getCurrentDateBaseStyle:nil],
                                @"total_fee":[NSString stringWithFormat:@"%d",price *100],
                                @"notify_url":@"http://apps.pay.cnlive.com/upappnotify/notify/updateCnCoin",
                                @"type":@"1001",
                                @"attach.value":[NSString stringWithFormat:@"%d",price],
                                @"attach.prdId":@"chinacoin",
                                @"user_id":userID,
                                @"attach.sid":userID,
                                @"frmId":@"apple",
                                @"attach.plat":@"i",
                                @"attach.payChannelId": @"4300",
                                @"body":@"中国币"
                                };
    
    return parameter;
}

//支付完成的参数
+ (NSDictionary *)payedInfoTransactionId:(NSString *)transactionIdentifier{
    NSDictionary *parameter = @{
                                @"appId":@"",
                                @"out_trade_no":transactionIdentifier ?: [self getCurrentDateBaseStyle:nil] ,
                                @"type":@"1001"
                                };
    
    return parameter;
}


static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];

//        NSString *part = [NSString stringWithFormat: @"%@=%@",key,value];
//        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}


+ (NSString *)getCurrentDateBaseStyle:(NSData *)data{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit |
    NSMonthCalendarUnit |
    NSDayCalendarUnit |
    NSWeekdayCalendarUnit |
    NSHourCalendarUnit |
    NSMinuteCalendarUnit |
    NSSecondCalendarUnit;
    
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    comps = [calendar components:unitFlags fromDate:data ? nil : currentDate];
    NSInteger week = [comps weekday];
    NSInteger year=[comps year];
    NSInteger month = [comps month];
    NSInteger day = [comps day];
    //[formatter setDateStyle:NSDateFormatterMediumStyle];
    //This sets the label with the updated time.
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    NSInteger sec = [comps second];
    NSString *dataString = [NSString stringWithFormat:@"%ld%ld%ld%ld%ld%ld%ld",year,month,week,day,hour,min,sec];
    return dataString;
}


#pragma mark 签名机制
//加密
+ (NSString*)sha1:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    while ([[output substringToIndex:1] isEqualToString:@"0"]) {
        output = [[NSMutableString alloc] initWithString:[output substringFromIndex:1]];
    }
    
    return output;
}


//签名机制
+ (NSString *)signvalue:(NSDictionary*)parameter
{
    //对所有传入参数按照字段名的 ASCII 码从小到大排序
    NSArray *keyArr=[parameter allKeys];
    NSArray *arr = [keyArr sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableString *string1 = [[NSMutableString alloc]init];
    for (int i=0; i<arr.count; i++) {
        
        NSString *parameterString = parameter[[arr objectAtIndex:i]];
        if (parameterString.length > 0) {
            [string1 appendString:[NSString stringWithFormat:@"%@=%@&",[arr objectAtIndex:i],parameter[[arr objectAtIndex:i]]]];
        }
    }
    
    if (string1.length > 0) {
        [string1 deleteCharactersInRange:NSMakeRange(string1.length-1, 1)];
    }
    
    return string1;
}

@end
