//
//  NSObject+BGModel.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/28.
//  Copyright © 2017年 Biao. All rights reserved.
//
/**
BGFMDB全新升级->>
完美支持:
int,long,signed,float,double,NSInteger,CGFloat,BOOL,NSString,NSNumber,NSArray,NSDictionary,NSMapTable,NSHashTable,NSData,UIImage,NSDate,NSURL,NSRange,CGRect,CGSize,CGPoint,自定义对象 等的存储.
 */
#import <Foundation/Foundation.h>
#import "BGTool.h"

@interface NSObject (BGModel)

@property(nonatomic,strong)NSNumber*_Nullable ID;//本库自带的自动增长主键.

//同步：线程阻塞；异步：线程非阻塞;
/**
 设置调试模式
 @debug YES:打印SQL语句, NO:不打印SQL语句.
 */
+(void)setDebug:(BOOL)debug;
/**
 自定义 “唯一约束” 函数,如果需要 “唯一约束”字段,则在自定类中自己实现该函数.
 @return 返回值是 “唯一约束” 的字段名(即相对应的变量名).
 */
-(NSString* _Nonnull)uniqueKey;
/**
 同步存储.
 */
-(BOOL)save;
/**
 异步存储.
 */
-(void)saveAsync:(Complete_B)complete;
/**
 覆盖掉原来的数据,只存储当前的数据.
 @async YES:异步存储,NO:同步存储.
 */
-(void)coverAsync:(BOOL)async complete:(Complete_B)complete;
/**
 同步查询所有结果.
 */
+(NSArray* _Nullable)findAll;
/**
 异步查询所有结果
 */
+(void)findAllAsync:(Complete_A)complete;
/**
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsync:(BOOL)async limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete;
/**
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsync:(BOOL)async range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete;
/**
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
+(void)findAsync:(BOOL)async where:(NSArray* _Nullable)where complete:(Complete_A)complete;
/**
 keyPath查询
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @keyPath 形式 @"user.student.name".
 @value 值,形式 @“小芳”
 说明: 即查询 user.student.name=小芳的对象数据 (用于嵌套的自定义类)
 */
+(void)findAsync:(BOOL)async forKeyPath:(NSString* _Nonnull)keyPath value:(id _Nonnull)value complete:(Complete_A)complete;
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(BOOL)updateWhere:(NSArray* _Nullable)where;
/**
 异步更新.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(void)updateAsync:(NSArray* _Nullable)where complete:(Complete_B)complete;
/**
 同步删除数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(BOOL)deleteWhere:(NSArray* _Nonnull)where;
/**
 异步删除.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(void)deleteAsync:(NSArray* _Nonnull)where complete:(Complete_B)complete;
/**
 同步清除所有数据
 */
+(BOOL)clear;
/**
 异步清除所有数据.
 */
+(void)clearAsync:(Complete_B)complete;
/**
 同步删除这个类的数据表
 */
+(BOOL)drop;
/**
 异步删除这个类的数据表.
 */
+(void)dropAsync:(Complete_B)complete;
/**
 查询该表中有多少条数据
 @name 表名称.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.
 */
+(NSInteger)countWhere:(NSArray* _Nullable)where;
/**
 获取本类数据表当前版本号.
 */
+(NSInteger)version;
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 @async YES:异步刷新,NO:同步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)updateVersionAsync:(BOOL)async version:(NSInteger)version complete:(Complete_I)complete;
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 @async YES:异步刷新,NO:同步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)updateVersionAsync:(BOOL)async version:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(Complete_I)complete;
/**
 将某表的数据拷贝给另一个表
 @async YES:异步复制,NO:同步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(void)copyAsync:(BOOL)async toClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete;
/**
 事务操作.
 @return 返回YES提交事务, 返回NO回滚事务.
 */
+(void)inTransaction:(BOOL (^_Nonnull)())block;
@end
