//
//  BGTool.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SqlText @"text" //数据库的字符类型
#define SqlReal @"real" //数据库的浮点类型
#define SqlInteger @"integer" //数据库的整数类型

#define SQLITE_NAME @"BGFMDB.sqlite"

#define Complete_B void(^_Nullable)(BOOL isSuccess)
#define Complete_I void(^_Nullable)(dealState result)
#define Complete_A void(^_Nullable)(NSArray* _Nullable array)

typedef NS_ENUM(NSInteger,dealState){//处理状态
    Error = -1,//处理失败
    Incomplete = 0,//处理不完整
    Complete = 1//处理完整
};

@interface BGTool : NSObject

//转换变量数据(插入时)
+(NSString*)jsonWithObject:(id)object;
/**
 将一个对象的变量值转化为字典返回
 */
+(NSDictionary*)dictionaryWithObject:(id)object;
/**
 数组转换(读取数据时).
 */
+(NSArray*)translateResult:(__unsafe_unretained Class)cla with:(NSArray*)array;
/**
 转换变量对象数据(读取数据时)
 */
+(id)objectWithJsonString:(NSString*)jsonString;
/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+(NSArray*)getClassIvarList:(__unsafe_unretained Class)cla onlyKey:(BOOL)onlyKey;

/**
 抽取封装条件数组处理函数
 */
+(NSArray*)where:(NSArray*)where;
/**
 判断是不是主键
 */
+(BOOL)isPrimary:(NSString*)primary with:(NSString*)param;
/**
 判断并获取字段类型
 */
+(NSString*)keyAndType:(NSString*)param;
+(NSString*)getSqlType:(NSString*)type;
@end
