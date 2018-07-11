//
//  BGDB.h
//  BGFMDB
//
//  Created by biao on 2017/10/18.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BGFMDBConfig.h"
#import "FMDB.h"

@interface BGDB : NSObject
//信号量.
@property(nonatomic, strong)dispatch_semaphore_t _Nullable semaphore;
/**
 调试标志
 */
@property(nonatomic,assign)BOOL debug;
/**
 自定义数据库名称
 */
@property(nonatomic,copy)NSString* _Nonnull sqliteName;
/**
 设置操作过程中不可关闭数据库(即closeDB函数无效).
 */
@property(nonatomic,assign)BOOL disableCloseDB;
/**
 获取单例函数.
 */
+(_Nonnull instancetype)shareManager;
/**
 关闭数据库.
 */
-(void)closeDB;
/**
 删除数据库文件.
 */
+(BOOL)deleteSqlite:(NSString*_Nonnull)sqliteName;
/**
 事务操作.
 */
-(void)inTransaction:(BOOL (^_Nonnull)())block;
/**
 添加操作到线程池
 */
-(void)addToThreadPool:(void (^_Nonnull)())block;
/**
 注册数据变化监听.
 @claName 注册监听的类名.
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
-(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(bg_changeBlock)block;
/**
 移除数据变化监听.
 @name 注册监听的时候使用的名称.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
-(BOOL)removeChangeWithName:(NSString* const _Nonnull)name;

#pragma mark --> 以下是直接存储一个对象的API

/**
 存储一个对象.
 @object 将要存储的对象.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储,nil时全部存储.
 @complete 回调的block.
 */
-(void)saveObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete;
/**
 批量存储.
 */
-(void)saveObjects:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete;
/**
 批量更新.
 over
 */
-(void)updateObjects:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete;
/**
 批量插入或更新.
 */
-(void)bg_saveOrUpateArray:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete;
/**
 根据条件查询对象.
 @tablename 要操作的表名称.
 @cla 代表对应的类.
 @where 条件参数.
 @complete 回调的block.
 */
-(void)queryObjectWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla where:(NSString* _Nullable)where complete:(bg_complete_A)complete;

/**
 根据条件改变对象数据.
 @object 要更新的对象.
 @where 数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部.
 @complete 回调的block
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete;
/**
 根据keyPath改变对象数据.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)updateWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete;
/**
 直接传入条件sql语句更新对象.
 */
-(void)updateObject:(id _Nonnull)object ignoreKeys:(NSArray* const _Nullable)ignoreKeys conditions:(NSString* _Nonnull)conditions complete:(bg_complete_B)complete;
/**
 根据类删除此类所有数据.
 @complete 回调的block
 */
-(void)clearWithObject:(id _Nonnull)object complete:(bg_complete_B)complete;
/**
 根据类,删除这个类的表.
 @complete 回调的block
 */
-(void)dropWithTableName:(NSString* _Nonnull)tablename complete:(bg_complete_B)complete;
/**
 将某表的数据拷贝给另一个表
 @srcTable 源表.
 @destTable 目标表.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,以此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
-(void)copyTable:(NSString* _Nonnull)srcTable to:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(bg_complete_I)complete;

/**----------------------------------华丽分割线---------------------------------------------*/
#pragma mark --> 以下是非直接存储一个对象的API

/**
 数据库中是否存在表.
 @name 表名称.
 @complete 回调的block
 */
- (void)isExistWithTableName:( NSString* _Nonnull)name complete:(bg_complete_B)complete;
- (BOOL)bg_isExistWithTableName:( NSString* _Nonnull)name;
/**
 创建表(如果存在则不创建)
 @name 表名称.
 @keys 数据存放要求@[字段名称1,字段名称2].
 @uniqueKeys '唯一约束'集合.
 @complete 回调的block
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys unionPrimaryKeys:(NSArray* _Nullable)unionPrimaryKeys uniqueKeys:(NSArray* _Nullable)uniqueKeys complete:(bg_complete_B)complete;
/**
 插入数据.
 @name 表名称.
 @dict 插入的数据,只关心key和value 即@{key:value,key:value}.
 @complete 回调的block
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(bg_complete_B)complete;
/**
 直接传入条件sql语句查询.
 @name 表名称.
 @conditions 条件语句.例如:@"where BG_name = '标哥' or BG_name = '小马哥' and BG_age = 26 order by BG_age desc limit 6" 即查询BG_name等于标哥或小马哥和BG_age等于26的数据通过BG_age降序输出,只查询前面6条.
 更多条件语法,请查询sql的基本使用语句.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(bg_complete_A)complete;
/**
 根据条件查询字段.
 @name 表名称.
 @keys 存放的是要查询的哪些key,为nil时代表查询全部.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],条件key属性只能是系统自带的属性,暂不支持自定义类.
 @complete 回调的block,返回的数组元素是字典 @[@{key:value},@{key:value}] .
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(bg_complete_A)complete;
/**
 全部查询.
 @name 表名称.
 @where 条件参数 例如排序 @"order by BG_bg_id desc" 等.
 @complete 回调的block,返回的数组元素是字典 @[@{key:value},@{key:value}] .
 */
-(void)queryWithTableName:(NSString* _Nonnull)name where:(NSString* _Nullable)where complete:(bg_complete_A)complete;
/**
 直接传入条件sql语句更新.
 */
-(void)updateWithObject:(id _Nonnull)object valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(bg_complete_B)complete;
/**
 根据表名和条件删除表内容.
 @name 表名称.
 @where 条件数组,形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空.
 @complete 回调的block.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(bg_complete_B)complete;
/**
 直接传入条件sql语句删除.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(bg_complete_B)complete;
/**
 根据keypath删除表内容.
 @name 表名称.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete;
/**
 根据表名删除表格全部内容.
 @name 表名称.
 @complete 回调的block.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(bg_complete_B)complete;
/**
 删除表.
 @name 表名称.
 @complete 回调的block.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(bg_complete_B)complete;
/**
 删除表(线程安全).
 */
-(void)dropSafeTable:(NSString* _Nonnull)name complete:(bg_complete_B)complete;
/**
 动态添加表字段.
 @name 表名称.
 @key 将要增加的字段.
 @complete 回调的block.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(bg_complete_B)complete;
/**
 查询该表中有多少条数据
 @name 表名称.
 @where 条件数组,形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时返回全部数据的条数.
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where;
/**
 直接传入条件sql语句查询数据条数.
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions;
/**
 keyPath查询数据条数.
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;
/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 */
-(double)sqliteMethodForTable:(NSString* _Nonnull)name type:(bg_sqliteMethodType)methodType key:(NSString* _Nonnull)key where:(NSString* _Nullable)where;
/**
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 @name 表名称.
 @keys 新表的数组字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(bg_complete_I)complete;
-(void)refreshTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* const _Nonnull)keys keyDict:(NSDictionary* const _Nonnull)keyDict complete:(bg_complete_I)complete;
/**
 直接执行sql语句.
 @tablename 要操作的表名.
 @cla 要操作的类.
 */
-(id _Nullable)bg_executeSql:(NSString* const _Nonnull)sql tablename:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla;
#pragma mark 存储数组.
/**
 直接存储数组.
 */
-(void)saveArray:(NSArray* _Nonnull)array name:(NSString* _Nonnull)name complete:(bg_complete_B)complete;
/**
 读取数组.
 */
-(void)queryArrayWithName:(NSString* _Nonnull)name complete:(bg_complete_A)complete;
/**
 读取数组某个元素.
 */
-(id _Nullable)queryArrayWithName:(NSString* _Nonnull)name index:(NSInteger)index;
/**
 更新数组某个元素.
 */
-(BOOL)updateObjectWithName:(NSString* _Nonnull)name object:(id _Nonnull)object index:(NSInteger)index;
/**
 删除数组某个元素.
 */
-(BOOL)deleteObjectWithName:(NSString* _Nonnull)name index:(NSInteger)index;


#pragma mark 存储字典.
/**
 直接存储字典.
 */
-(void)saveDictionary:(NSDictionary* _Nonnull)dictionary complete:(bg_complete_B)complete;
/**
 添加字典元素.
 */
-(BOOL)bg_setValue:(id _Nonnull)value forKey:(NSString* const _Nonnull)key;
/**
 更新字典元素.
 */
-(BOOL)bg_updateValue:(id _Nonnull)value forKey:(NSString* const _Nonnull)key;
/**
 遍历字典元素.
 */
-(void)bg_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block;
/**
 获取字典元素.
 */
-(id _Nullable)bg_valueForKey:(NSString* const _Nonnull)key;
/**
 删除字典元素.
 */
-(BOOL)bg_deleteValueForKey:(NSString* const _Nonnull)key;
@end
