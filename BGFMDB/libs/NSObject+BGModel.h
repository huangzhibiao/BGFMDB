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
#import "BGFMDBConfig.h"

@protocol BGProtocol <NSObject>
//可选择操作
@optional
/**
 自定义 “唯一约束” 函数,如果需要 “唯一约束”字段,则在自定类中自己实现该函数.
 @return 返回值是 “唯一约束” 的字段名(即相对应的变量名).
 */
+(NSString* _Nonnull)bg_uniqueKey;
/**
 *  数组中需要转换的模型类(‘字典转模型’ 或 ’模型转字典‘ 都需要实现该函数)
 *  @return 字典中的key是数组属性名，value是数组中存放模型的Class
 */
+(NSDictionary *_Nonnull)bg_objectClassInArray;
/**
 如果模型中有自定义类变量,则实现该函数对应进行集合到模型的转换.
 字典转模型用.
 */
+(NSDictionary *_Nonnull)bg_objectClassForCustom;
/**
 将模型中对应的自定义类变量转换为字典.
 模型转字典用.
 */
+(NSDictionary *_Nonnull)bg_dictForCustomClass;
/**
替换变量的功能(及当字典的key和属性名不一样时，进行映射对应起来)
*/
+(NSDictionary *_Nonnull)bg_replacedKeyFromPropertyName;
@end

@interface NSObject (BGModel)<BGProtocol>

@property(nonatomic,strong)NSNumber* _Nonnull bg_id;//本库自带的自动增长主键.
/**
 为了方便开发者，特此加入以下两个字段属性供开发者做参考.(自动记录数据的存入时间和更新时间)
 */
@property(nonatomic,copy)NSString* _Nonnull bg_createTime;//数据创建时间(即存入数据库的时间)
@property(nonatomic,copy)NSString* _Nonnull bg_updateTime;//数据最后那次更新的时间.

//同步：线程阻塞；异步：线程非阻塞;
/**
 判断这个类的数据表是否已经存在.
 */
+(BOOL)bg_isExist;
/**
 同步存储.
 */
-(BOOL)bg_save;
/**
 异步存储.
 */
-(void)bg_saveAsync:(bg_complete_B)complete;
/**
 同步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(BOOL)bg_saveArray:(NSArray* _Nonnull)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys;
/**
 异步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(void)bg_saveArrayAsync:(NSArray* _Nonnull)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete;
/**
 同步存储或更新.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
-(BOOL)bg_saveOrUpdate;
/**
 同步存储或更新数组.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
+(void)bg_saveOrUpdateArray:(NSArray* _Nonnull)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys;
/**
 异步存储或更新数组.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
+(void)bg_saveOrUpdateAsyncArray:(NSArray* _Nonnull)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys;
/**
 异步存储或更新.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
-(void)bg_saveOrUpdateAsync:(bg_complete_B)complete;
/**
 同步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)bg_saveIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys;
/**
 异步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(void)bg_saveAsyncIgnoreKeys:(NSArray* const _Nonnull)ignoredKeys complete:(bg_complete_B)complete;
/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 */
-(BOOL)bg_cover;
/**
 异步覆盖存储
 覆盖掉原来的数据,只存储当前的数据.
 */
-(void)bg_coverAsync:(bg_complete_B)complete;
/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)bg_coverIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys;
/**
 异步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(void)bg_coverAsyncIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys complete:(bg_complete_B)complete;
/**
 同步查询所有结果.
 温馨提示: 当数据量巨大时,请用范围接口进行分页查询,避免查询出来的数据量过大导致程序崩溃.
 */
+(NSArray* _Nullable)bg_findAll;
/**
 异步查询所有结果
 温馨提示: 当数据量巨大时,请用范围接口进行分页查询,避免查询出来的数据量过大导致程序崩溃.
 */
+(void)bg_findAllAsync:(bg_complete_A)complete;
/**
 查找第一条数据
 */
+(id _Nullable)bg_firstObjet;
/**
 查找最后一条数据
 */
+(id _Nullable)bg_lastObject;
/**
 查询某一行数据
 @row 从第0行开始算起.
 */
+(id _Nullable)bg_ObjectWithRow:(NSInteger)row;
/**
 同步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)bg_findAllWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc;
/**
 异步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(void)bg_findAllAsyncWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(bg_complete_A)complete;
/**
 同步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)bg_findAllWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc;
/**
 异步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(void)bg_findAllAsyncWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(bg_complete_A)complete;
/**
 同步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(NSArray* _Nullable)bg_findWhere:(NSArray* _Nullable)where;
/**
 异步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(void)bg_findAsyncWhere:(NSArray* _Nullable)where complete:(bg_complete_A)complete;
/**
 @format 传入sql条件参数,语句来进行查询,方便开发者自由扩展.
 使用规则请看demo或如下事例:
 支持keyPath.
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
 NSArray* arrayConds1 = [People findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",bg_sqlKey(@"age"),bg_sqlValue(@(45)),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸"),bg_sqlKey(@"name"),bg_sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
 [People bg_findFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
 NSArray* arrayConds3 = [People bg_findFormatSqlConditions:@"where %@ and %@=%@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"]),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸")];
 */
+(NSArray* _Nullable)bg_findFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 keyPath查询
 同步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(NSArray* _Nullable)bg_findForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 keyPath查询
 异步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)bg_findAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_A)complete;
/**
 查询某一时间段的数据.(存入时间或更新时间)
 @dateTime 参数格式：
 2017 即查询2017年的数据
 2017-07 即查询2017年7月的数据
 2017-07-19 即查询2017年7月19日的数据
 2017-07-19 16 即查询2017年7月19日16时的数据
 2017-07-19 16:17 即查询2017年7月19日16时17分的数据
 2017-07-19 16:17:53 即查询2017年7月19日16时17分53秒的数据
 */
+(NSArray* _Nullable)bg_findWithType:(bg_dataTimeType)type dateTime:(NSString* _Nonnull)dateTime;
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(BOOL)bg_updateWhere:(NSArray* _Nullable)where;
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据.
 可以为nil,nil时更新所有数据;
 @ignoreKeys 忽略哪些key不用更新.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(BOOL)bg_updateWhere:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys;
/**
 异步更新.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(void)bg_updateAsync:(NSArray* _Nullable)where complete:(bg_complete_B)complete;
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 此接口不支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾"
 [People bg_updateFormatSqlConditions:@"set %@=%@ where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马化腾"),bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")];
 */
+(BOOL)bg_updateFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据.
 [p bg_updateFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据.
 [p bg_updateFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")];
 */
-(BOOL)bg_updateFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据(忽略name不要更新).
 NSString* conditions = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 [p bg_updateFormatSqlConditions:conditions IgnoreKeys:@[@"name"]];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据.
 NSString* conditions = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")])];
 [p bg_updateFormatSqlConditions:conditions IgnoreKeys:nil];
 @ignoreKeys 忽略哪些key不用更新.
 */
-(BOOL)bg_updateFormatSqlConditions:(NSString* _Nonnull)conditions IgnoreKeys:(NSArray* const _Nullable)ignoreKeys;
/**
 根据keypath更新数据.
 同步更新.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(BOOL)bg_updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 根据keypath更新数据.
 异步更新.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)bg_updateAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete;
/**
 同步删除数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(BOOL)bg_deleteWhere:(NSArray* _Nonnull)where;
/**
 异步删除.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(void)bg_deleteAsync:(NSArray* _Nonnull)where complete:(bg_complete_B)complete;
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据
 [People bg_deleteFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据
 [People bg_deleteFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
 [People bg_deleteFormatSqlConditions:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
+(BOOL)bg_deleteFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 根据keypath删除数据.
 同步删除.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(BOOL)bg_deleteForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 根据keypath删除数据.
 异步删除.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)bg_deleteAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete;
/**
 删除某一行数据
 @row 从第0行开始算起.
 */
+(BOOL)bg_deleteWithRow:(NSInteger)row;
/**
 删除第一条数据
 */
+(BOOL)bg_deleteFirstObject;
/**
 删除最后一条数据
 */
+(BOOL)bg_deleteLastObject;
/**
 同步清除所有数据
 */
+(BOOL)bg_clear;
/**
 异步清除所有数据.
 */
+(void)bg_clearAsync:(bg_complete_B)complete;
/**
 同步删除这个类的数据表
 */
+(BOOL)bg_drop;
/**
 异步删除这个类的数据表.
 */
+(void)bg_dropAsync:(bg_complete_B)complete;
/**
 查询该表中有多少条数据
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询条数接口).
 */
+(NSInteger)bg_countWhere:(NSArray* _Nullable)where;
/**
 @format 传入sql条件参数,语句来查询数据条数,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询People类中name等于"美国队长"的数据条数.
 [People bg_countFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
 2.查询People类中user.student.human.body等于"小芳"的数据条数.
 [People bg_countFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
 [People bg_countFormatSqlConditions:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
+(NSInteger)bg_countFormatSqlConditions:(NSString* _Nonnull)format,... NS_FORMAT_FUNCTION(1,2);
/**
 keyPath查询该表中有多少条数据
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象的条数.
 */
+(NSInteger)bg_countForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 用法：NSInteger num = [People bg_sqliteMethodWithType:bg_sum key:@"age"];
 提示: @param key -> 不支持keyPath , @param where -> 支持keyPath
 */
+(NSInteger)bg_sqliteMethodWithType:(bg_sqliteMethodType)methodType key:(NSString* _Nonnull)key where:(NSString* _Nullable)where,...;
/**
 获取本类数据表当前版本号.
 */
+(NSInteger)bg_version;
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(bg_dealState)bg_updateVersion:(NSInteger)version;
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)bg_updateVersionAsync:(NSInteger)version complete:(bg_complete_I)complete;
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(bg_dealState)bg_updateVersion:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict;
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)bg_updateVersionAsync:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(bg_complete_I)complete;
/**
 将某表的数据拷贝给另一个表
 同步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(bg_dealState)bg_copyToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append;
/**
 将某表的数据拷贝给另一个表
 异步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(void)bg_copyAsyncToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(bg_complete_I)complete;
/**
 注册数据变化监听.
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
+(BOOL)bg_registerChangeWithName:(NSString* const _Nonnull)name block:(bg_changeBlock)block;
/**
 移除数据变化监听.
 @name 注册监听的时候使用的名称.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
+(BOOL)bg_removeChangeWithName:(NSString* const _Nonnull)name;

#pragma mark 下面附加字典转模型API,简单好用,在只需要字典转模型功能的情况下,可以不必要再引入MJExtension那么多文件,造成代码冗余,缩减安装包.
/**
 字典转模型.
 @keyValues 字典(NSDictionary)或json格式字符.
 说明:如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现objectClassInArray这个函数返回一个字典,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
 */
+(id _Nonnull)bg_objectWithKeyValues:(id const _Nonnull)keyValues;
+(id _Nonnull)bg_objectWithDictionary:(NSDictionary* const _Nonnull)dictionary;
/**
 直接传数组批量处理;
 注:array中的元素是字典,否则出错.
 */
+(NSArray* _Nonnull)bg_objectArrayWithKeyValuesArray:(NSArray* const _Nonnull)array;
/**
 模型转字典.
 @ignoredKeys 忽略掉模型中的哪些key(即模型变量)不要转,nil时全部转成字典.
 */
-(NSMutableDictionary* _Nonnull)bg_keyValuesIgnoredKeys:(NSArray* _Nullable)ignoredKeys;
@end

#pragma mark 直接存储数组.
@interface NSArray (BGModel)
/**
 存储数组.
 @name 唯一标识名称.
 **/
-(BOOL)bg_saveArrayWithName:(NSString* const _Nonnull)name;
/**
 添加数组元素.
 @name 唯一标识名称.
 @object 要添加的元素.
 */
+(BOOL)bg_addObjectWithName:(NSString* const _Nonnull)name object:(id const _Nonnull)object;
/**
 获取数组元素数量.
 @name 唯一标识名称.
 */
+(NSInteger)bg_countWithName:(NSString* const _Nonnull)name;
/**
 查询整个数组
 */
+(NSArray* _Nullable)bg_arrayWithName:(NSString* const _Nonnull)name;
/**
 获取数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(id _Nullable)bg_objectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index;
/**
 更新数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)bg_updateObjectWithName:(NSString* const _Nonnull)name Object:(id _Nonnull)object Index:(NSInteger)index;
/**
 删除数组的某个元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)bg_deleteObjectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index;
/**
 清空数组元素.
 @name 唯一标识名称.
 */
+(BOOL)bg_clearArrayWithName:(NSString* const _Nonnull)name;
@end

#pragma mark 直接存储字典.
@interface NSDictionary (BGModel)
/**
 存储字典.
 */
-(BOOL)bg_saveDictionary;
/**
 添加字典元素.
 */
+(BOOL)bg_setValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key;
/**
 更新字典元素.
 */
+(BOOL)bg_updateValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key;
/**
 获取字典元素.
 */
+(id _Nullable)bg_valueForKey:(NSString* const _Nonnull)key;
/**
 遍历字典元素.
 */
+(void)bg_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block;
/**
 移除字典某个元素.
 */
+(BOOL)bg_removeValueForKey:(NSString* const _Nonnull)key;
/**
 清空字典.
 */
+(BOOL)bg_clearDictionary;
@end
