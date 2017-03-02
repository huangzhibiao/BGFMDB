//
//  BGTool.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BGModelInfo.h"

#define SQLITE_NAME @"BGFMDB.sqlite"

#define BG @"BG_"

#define Complete_B void(^_Nullable)(BOOL isSuccess)
#define Complete_I void(^_Nullable)(dealState result)
#define Complete_A void(^_Nullable)(NSArray* _Nullable array)

typedef NS_ENUM(NSInteger,dealState){//处理状态
    Error = -1,//处理失败
    Incomplete = 0,//处理不完整
    Complete = 1//处理完整
};

@interface BGTool : NSObject
/**
 json字符转json格式数据 .
 */
+(id)jsonWithString:(NSString*)jsonString;
/**
 字典转json字符 .
 */
+(NSString*)dataToJson:(id)data;
/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+(NSArray*)getClassIvarList:(__unsafe_unretained Class)cla onlyKey:(BOOL)onlyKey;

/**
 抽取封装条件数组处理函数.
 */
+(NSArray*)where:(NSArray*)where;
/**
 判断是不是主键.
 */
+(BOOL)isUniqueKey:(NSString*)uniqueKey with:(NSString*)param;
/**
 判断并获取字段类型.
 */
+(NSString*)keyAndType:(NSString*)param;
/**
 根据类属性类型返回数据库存储类型.
 */
+(NSString*)getSqlType:(NSString*)type;
/**
 根据类属性值和属性类型返回数据库存储的值.
 @value 数值.
 @type 数组value的类型.
 @encode YES:编码 , NO:解码.
 */
+(id)getSqlValue:(id)value type:(NSString*)type encode:(BOOL)encode;
/**
 转换从数据库中读取出来的数据.
 @tableName 表名(即类名).
 @array 传入要转换的数组数据.
 */
+(NSArray*)tansformDataFromSqlDataWithTableName:(NSString*)tableName array:(NSArray*)array;
@end
