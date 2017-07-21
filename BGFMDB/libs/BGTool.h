//
//  BGTool.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define bg_completeBlock(obj) !complete?:complete(obj);

@interface BGTool : NSObject

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
//NSDate转字符串,格式: yyyy-MM-dd HH:mm:ss
+(NSString* _Nonnull)stringWithDate:(NSDate* _Nonnull)date;
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
 转换从数据库中读取出来的数据.
 @claName 类名.
 @valueDict 传入要转换的字典数据.
 */
+(id _Nonnull)objectFromJsonStringWithClassName:(NSString* _Nonnull)claName valueDict:(NSDictionary* _Nonnull)valueDict;
/**
 字典或json格式字符转模型用的处理函数.
 */
+(id _Nonnull)bg_objectWithClass:(__unsafe_unretained _Nonnull Class)cla value:(id _Nonnull)value;
/**
 模型转字典.
 */
+(NSMutableDictionary* _Nonnull)bg_keyValuesWithObject:(id _Nonnull)object ignoredKeys:(NSArray* _Nullable)ignoredKeys;
/**
 判断类是否实现了某个类方法.
 */
+(id _Nonnull)isRespondsToSelector:(SEL _Nonnull)selector forClass:(__unsafe_unretained _Nonnull Class)cla;
/**
 判断对象是否实现了某个方法.
 */
+(id _Nonnull)isRespondsToSelector:(SEL _Nonnull)selector forObject:(id _Nonnull)object;
/**
 根据对象获取要更新或插入的字典.
 */
+(NSDictionary* _Nonnull)getDictWithObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys isUpdate:(BOOL)update;
/**
 如果表格不存在就新建.
 */
+(BOOL)ifNotExistWillCreateTableWithObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys;
/**
 整形判断
 */
+ (BOOL)isPureInt:(NSString* _Nonnull)string;
/**
 浮点形判断
 */
+ (BOOL)isPureFloat:(NSString* _Nonnull)string;
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
