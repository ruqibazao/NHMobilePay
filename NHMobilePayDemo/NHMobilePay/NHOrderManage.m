//
//  NHOrderManage.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/9.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHOrderManage.h"
#import <CommonCrypto/CommonDigest.h>


//获取沙盒 Library
#define NHPathLibrary   [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject]
#define TranscationInfo @"noitcasnartinfo.db"

NSString * const MCDownloadCacheFolderName = @"om";

static NSString * cacheFolder() {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    static NSString *cacheFolder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!cacheFolder) {
            NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
            cacheFolder = [cacheDir stringByAppendingPathComponent:MCDownloadCacheFolderName];
        }
        NSError *error = nil;
        if(![filemgr createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            //            kNSLog(@"Failed to create cache directory at %@", cacheFolder);
            printf("Failed to create cache directory at %p", cacheFolder);
            cacheFolder = nil;
        }
    });
    return cacheFolder;
}


static NSString * LocalOrderCachePath(NSString *fileName, BOOL suffix){
    NSString *name = fileName;
    if (suffix) {
        name = [NSString stringWithFormat:@"%@.db",fileName];
    }
    return [cacheFolder() stringByAppendingPathComponent:name];
}

static NSString * getMD5String(NSString *str) {
    
    if (str == nil) return nil;
    
    const char *cstring = str.UTF8String;
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstring, (CC_LONG)strlen(cstring), bytes);
    
    NSMutableString *md5String = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", bytes[i]];
    }
    return md5String;
}

@interface NHOrderInfo ()<NSCoding>
@property (nonatomic, copy) NSString *receiptDataStr; //apple返回的receiptData数据
@property (nonatomic, copy) NSString *transactionIdentifier; //订单号
@property (nonatomic, copy) NSString *proudctPrice; //产品价格
@property (nonatomic, copy) NSString *payObjectID; //支付者id
@property (nonatomic, copy) NSString *payTimeStamp; //支付时间(这里以时间戳格式保存)
@end
@implementation NHOrderInfo

#define ReceiptData           @"receiptDataStr"
#define TransactionIdentifier @"transactionIdentifier"
#define ProudctPrice          @"proudctPrice"
#define PayObjectID           @"payObjectID"
#define PayTimeStamp          @"payTimeStamp"

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_receiptDataStr forKey:getMD5String(ReceiptData)];
    [aCoder encodeObject:_transactionIdentifier forKey:getMD5String(TransactionIdentifier)];
    [aCoder encodeObject:_proudctPrice forKey:getMD5String(ProudctPrice)];
    [aCoder encodeObject:_payObjectID forKey:getMD5String(PayObjectID)];
    [aCoder encodeObject:_payTimeStamp forKey:getMD5String([NSString stringWithFormat:@"%@",PayTimeStamp])];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.receiptDataStr        = [coder decodeObjectForKey:getMD5String(ReceiptData)];
        self.transactionIdentifier = [coder decodeObjectForKey:getMD5String(TransactionIdentifier)];
        self.proudctPrice          = [coder decodeObjectForKey:getMD5String(ProudctPrice)];
        self.payObjectID           = [coder decodeObjectForKey:getMD5String(PayObjectID)];
        self.payTimeStamp = [coder decodeObjectForKey:getMD5String([NSString stringWithFormat:@"%@",PayTimeStamp])];
    }
    return self;
}

@end



@interface NHOrderManage ()
@end

@implementation NHOrderManage

+ (BOOL)saveOrderInfo:(NHOrderInfo *)orderinfo fileName:(NSString *)fileName{
    return [NSKeyedArchiver archiveRootObject:orderinfo toFile:LocalOrderCachePath(fileName,YES)];
}


+ (BOOL)addTransactionIdentifier:(NSString *)transactionIdentifier
                  receiptDataStr:(NSString *)receiptDataStr
                    proudctPrice:(NSString *)proudctPrice
                     payObjectID:(NSString *)payObjectID {

    NHOrderInfo *orderinfo = [[NHOrderInfo alloc] init];
    orderinfo.transactionIdentifier = transactionIdentifier;
    orderinfo.receiptDataStr = receiptDataStr;
    orderinfo.proudctPrice = proudctPrice;
    orderinfo.payObjectID = payObjectID;
    orderinfo.payTimeStamp = [self getCurrentDateBaseStyleWithData:nil];
    NSLog(@"保存订单:\n%@,\n%@,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr,orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);

   return [self saveOrderInfo:orderinfo fileName:transactionIdentifier];
}


+ (BOOL)deleteTransactionIdentifier:(NSString *)transactionIdentifier {
    NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(transactionIdentifier,YES)];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDircetory;
    BOOL isExists = [fileManager fileExistsAtPath:LocalOrderCachePath(transactionIdentifier,YES) isDirectory:&isDircetory];
    if (isExists) {
        NSError *error;
        [fileManager removeItemAtPath:LocalOrderCachePath(transactionIdentifier,YES) error:&error];
        NSLog(@"删除订单：\n%@,\n%@,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr,orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);
        if (error) {
            NSLog(@"\n订单删除失败:%@",error.localizedDescription);
        }
    }
    return isExists;
}


+ (NSArray<NHOrderInfo *> *)checkUnfinishedOrder{
    NSError *error;
    NSString *filePath = cacheFolder();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager subpathsOfDirectoryAtPath:filePath error:&error];
    NSMutableArray *orders = [[NSMutableArray alloc] init];
    
    for (NSString *name in files) {
        @autoreleasepool {
            NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(name,NO)];
            [orders addObject:orderinfo];
            NSLog(@"检查订单:\n%@,\n%@,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr,orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);
        }
    }
    return orders;
}


+ (NHOrderInfo *)getOrderInfoTransactionIdentifier:(NSString *)transactionIdentifier {
    NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(transactionIdentifier,YES)];
    return orderinfo;
}


+ (NSString *)getCurrentDateBaseStyleWithData:(NSData *)data{
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
@end
