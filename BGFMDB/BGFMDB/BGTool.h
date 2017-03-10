//
//  BGTool.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BGModelInfo.h"
#import "FMDB.h"

#define SQLITE_NAME @"BGFMDB.sqlite"

#define BG @"BG_"
#define primaryKey @"ID"
#define uniquekey @"uniquekey"

#define Complete_B void(^_Nullable)(BOOL isSuccess)
#define Complete_I void(^_Nullable)(dealState result)
#define Complete_A void(^_Nullable)(NSArray* _Nullable array)
#define ChangeBlock void(^_Nullable)(changeState result)

typedef NS_ENUM(NSInteger,changeState){//数据改变状态
    Insert,//插入
    Update,//更新
    Delete,//删除
    Drop//删表
};

typedef NS_ENUM(NSInteger,dealState){//处理状态
    Error = -1,//处理失败
    Incomplete = 0,//处理不完整
    Complete = 1//处理完整
};
//keyPath查询用的关系，Equal:等于的关系；Contains：包含的关系.
typedef NSString* _Nonnull Relation;
extern Relation const Equal;
extern Relation const Contains;
@interface BGTool : NSObject

/**
 封装处理传入数据库的key和value.
 */
extern NSString* _Nonnull sqlKey(NSString* _Nonnull key);
extern NSString* _Nonnull sqlValue(id _Nonnull value);
/**
 根据keyPath和Value的数组, 封装成数据库语句，来操作库.
 */
extern NSString* _Nonnull keyPathValues(NSArray* _Nonnull keyPathValues);
/**
 json字符转json格式数据 .
 */
+(id _Nonnull)jsonWithString:(NSString* _Nonnull)jsonString;
/**
 字典转json字符 .
 */
+(NSString* _Nonnull)dataToJson:(id _Nonnull)data;
/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+(NSArray* _Nonnull)getClassIvarList:(__unsafe_unretained _Nonnull Class)cla onlyKey:(BOOL)onlyKey;

/**
 抽取封装条件数组处理函数.
 */
+(NSArray* _Nonnull)where:(NSArray* _Nonnull)where;
/**
 封装like语句获取函数
 */
+(NSString* _Nonnull)getLikeWithKeyPathAndValues:(NSArray* _Nonnull)keyPathValues where:(BOOL)where;
/**
 判断是不是主键.
 */
+(BOOL)isUniqueKey:(NSString* _Nonnull)uniqueKey with:(NSString* _Nonnull)param;
/**
 判断并获取字段类型.
 */
+(NSString* _Nonnull)keyAndType:(NSString* _Nonnull)param;
/**
 根据类属性类型返回数据库存储类型.
 */
+(NSString* _Nonnull)getSqlType:(NSString* _Nonnull)type;
/**
 根据类属性值和属性类型返回数据库存储的值.
 @value 数值.
 @type 数组value的类型.
 @encode YES:编码 , NO:解码.
 */
+(id _Nonnull)getSqlValue:(id _Nonnull)value type:(NSString* _Nonnull)type encode:(BOOL)encode;
/**
 转换从数据库中读取出来的数据.
 @tableName 表名(即类名).
 @array 传入要转换的数组数据.
 */
+(NSArray* _Nonnull)tansformDataFromSqlDataWithTableName:(NSString* _Nonnull)tableName array:(NSArray* _Nonnull)array;
/**
 获取"唯一约束"
 */
+(NSString* _Nonnull)getUnique:(id _Nonnull)object;
/**
 NSUserDefaults封装使用函数.
 */
+(BOOL)getBoolWithKey:(NSString* _Nonnull)key;
+(void)setBoolWithKey:(NSString* _Nonnull)key value:(BOOL)value;
+(NSString* _Nonnull)getStringWithKey:(NSString* _Nonnull)key;
+(void)setStringWithKey:(NSString* _Nonnull)key value:(NSString* _Nonnull)value;
+(NSInteger)getIntegerWithKey:(NSString* _Nonnull)key;
+(void)setIntegerWithKey:(NSString* _Nonnull)key value:(NSInteger)value;
@end
