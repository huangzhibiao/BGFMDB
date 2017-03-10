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
int,long,signed,float,double,NSInteger,CGFloat,BOOL,NSString,NSMutableString,NSNumber,
NSArray,NSMutableArray,NSDictionary,NSMutableDictionary,NSMapTable,NSHashTable,NSData,
NSMutableData,UIImage,NSDate,NSURL,NSRange,CGRect,CGSize,CGPoint,自定义对象 等的存储.
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
 判断这个类的数据表是否已经存在.
 */
+(BOOL)isExist;
/**
 同步存储.
 */
-(BOOL)save;
/**
 异步存储.
 */
-(void)saveAsync:(Complete_B)complete;
/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 */
-(BOOL)cover;
/**
 异步覆盖存储
 覆盖掉原来的数据,只存储当前的数据.
 */
-(void)coverAsync:(Complete_B)complete;
/**
 同步查询所有结果.
 */
+(NSArray* _Nullable)findAll;
/**
 异步查询所有结果
 */
+(void)findAllAsync:(Complete_A)complete;
/**
 同步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)findAllWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc;
/**
 异步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsyncWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete;
/**
 同步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)findAllWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc;
/**
 异步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsyncWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete;
/**
 同步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(NSArray* _Nullable)findWhere:(NSArray* _Nullable)where;
/**
 异步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(void)findAsyncWhere:(NSArray* _Nullable)where complete:(Complete_A)complete;
/**
 @format 传入sql条件参数,语句来进行查询,方便开发者自由扩展.
 使用规则请看demo或如下事例:
 支持keyPath.
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
 NSArray* arrayConds1 = [People findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",sqlKey(@"age"),sqlValue(@(45)),sqlKey(@"name"),sqlValue(@"爸爸"),sqlKey(@"name"),sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
 [People findFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
 NSArray* arrayConds3 = [People findFormatSqlConditions:@"where %@ and %@=%@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"]),sqlKey(@"name"),sqlValue(@"爸爸")];
 */
+(NSArray* _Nullable)findFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 keyPath查询
 同步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(NSArray* _Nullable)findForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 keyPath查询
 异步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)findAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete;
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(BOOL)updateWhere:(NSArray* _Nullable)where;
/**
 异步更新.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(void)updateAsync:(NSArray* _Nullable)where complete:(Complete_B)complete;
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 此接口不支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾"
 [People updateFormatSqlConditions:@"set %@=%@ where %@=%@",sqlKey(@"name"),sqlValue(@"马化腾"),sqlKey(@"name"),sqlValue(@"马云爸爸")];
 */
+(BOOL)updateFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据.
 [p updateFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据.
 [p updateFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"马云爸爸")];
 */
-(BOOL)updateFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 根据keypath更新数据.
 同步更新.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(BOOL)updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 根据keypath更新数据.
 异步更新.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)updateAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete;
/**
 同步删除数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(BOOL)deleteWhere:(NSArray* _Nonnull)where;
/**
 异步删除.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(void)deleteAsync:(NSArray* _Nonnull)where complete:(Complete_B)complete;
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据
 [People deleteFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据
 [People deleteFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
 [People deleteFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 */
+(BOOL)deleteFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 根据keypath删除数据.
 同步删除.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(BOOL)deleteForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 根据keypath删除数据.
 异步删除.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)deleteAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete;
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
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询条数接口).
 */
+(NSInteger)countWhere:(NSArray* _Nullable)where;
/**
 @format 传入sql条件参数,语句来查询数据条数,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询People类中name等于"美国队长"的数据条数.
 [People countFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
 2.查询People类中user.student.human.body等于"小芳"的数据条数.
 [People countFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
 [People countFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 */
+(NSInteger)countFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 keyPath查询该表中有多少条数据
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象的条数.
 */
+(NSInteger)countForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 获取本类数据表当前版本号.
 */
+(NSInteger)version;
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(dealState)updateVersion:(NSInteger)version;
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)updateVersionAsync:(NSInteger)version complete:(Complete_I)complete;
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(dealState)updateVersion:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict;
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)updateVersionAsync:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(Complete_I)complete;
/**
 将某表的数据拷贝给另一个表
 同步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(dealState)copyToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append;
/**
 将某表的数据拷贝给另一个表
 异步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(void)copyAsyncToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete;
/**
 事务操作.
 @return 返回YES提交事务, 返回NO回滚事务.
 */
+(void)inTransaction:(BOOL (^_Nonnull)())block;
/**
 注册数据变化监听.
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
+(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(ChangeBlock)block;
/**
 移除数据变化监听.
 @name 注册监听的时候使用的名称.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
+(BOOL)removeChangeWithName:(NSString* const _Nonnull)name;
@end
