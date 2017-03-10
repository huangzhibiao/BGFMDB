//
//  BGFMDB.h
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//
/** 
 使用提示:
 1.存储对象时,如果变量名改变了,请先存储再查询,不然可能查询不到新增的变量名(字段名).
 2.存储对象时,对象中的 数组或字典变量 中的元素目前只支持系统自带的类型.
 */
#import <Foundation/Foundation.h>
#import "BGTool.h"

@interface BGFMDB : NSObject
@property(nonatomic,assign)BOOL debug;
/**
 获取单例函数.
 */
+(_Nonnull instancetype)shareManager;
//事务操作
-(void)inTransaction:(BOOL (^_Nonnull)())block;
/**
 为了对象层的事物操作而封装的函数.
 */
-(void)executeDB:(void (^_Nonnull)(FMDatabase *_Nonnull db))block;
/**
 注册数据变化监听.
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
-(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(ChangeBlock)block;
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
 @complete 回调的block.
 */
-(void)saveObject:(id _Nonnull)object complete:(Complete_B)complete;
/**
 根据条件查询对象.
 @cla 代表对应的类.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"] .
 @param 额外条件参数 例如排序 @"order by id desc" 等.
 @complete 回调的block.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nullable)where param:(NSString* _Nullable)param complete:(Complete_A)complete;
/**
 根据条件查询对象.
 @cla 代表对应的类.
 @keys 存放的是要查询的哪些key,为nil时代表查询全部.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"] .
 @complete 回调的block.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete;
/**
 根据keyPath查询对象
 @cla 代表对应的类.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name等于@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete;
/**
 根据条件改变对象数据.
 @object 要更新的对象.
 @where 数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部.
 @complete 回调的block
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where complete:(Complete_B)complete;
/**
 根据keyPath改变对象数据.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)updateWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete;
/**
 根据条件改变对象的部分变量值.
 @cla 代表对应的类.
 @valueDict 存放的是key和value 即@{key:value,key:value}..
 @where 数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部.
 @complete 回调的block
 */
-(void)updateWithClass:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(Complete_B)complete;
/**
 根据条件删除对象表中的对象数据.
 @cla 代表对应的类.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空.
 @complete 回调的block
 */
-(void)deleteWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(Complete_B)complete;
/**
 根据类删除此类所有数据.
 @cla 代表对应的类.
 @complete 回调的block
 */
-(void)clearWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(Complete_B)complete;
/**
 根据类,删除这个类的表.
 @cla 代表对应的类.
 @complete 回调的block
 */
-(void)dropWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(Complete_B)complete;
/**
 将某表的数据拷贝给另一个表
 @srcCla 源类.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,以此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
-(void)copyClass:(__unsafe_unretained _Nonnull Class)srcCla to:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete;

/**----------------------------------华丽分割线---------------------------------------------*/
#pragma mark --> 以下是非直接存储一个对象的API

/** 
 数据库中是否存在表.
 @name 表名称.
 @complete 回调的block
 */
- (void)isExistWithTableName:( NSString* _Nonnull)name complete:(Complete_B)complete;
/**
 创建表(如果存在则不创建)
 @name 表名称.
 @keys 数据存放要求@[字段名称1,字段名称2].
 @primaryKey 主键字段,可以为nil.
 @complete 回调的block
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys uniqueKey:(NSString* _Nullable)uniqueKey complete:(Complete_B)complete;
/**
 插入数据.
 @name 表名称.
 @dict 插入的数据,只关心key和value 即@{key:value,key:value}.
 @complete 回调的block
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(Complete_B)complete;
/**
 直接传入条件sql语句查询.
 @name 表名称.
 @conditions 条件语句.例如:@"where name = '标哥' or name = '小马哥' and age = 26 order by age desc limit 6" 即查询name等于标哥或小马哥和age等于26的数据通过age降序输出,只查询前面6条. 
 更多条件语法,请查询sql的基本使用语句.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_A)complete;
/** 
 根据条件查询字段.
 @name 表名称.
 @keys 存放的是要查询的哪些key,为nil时代表查询全部.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],条件key属性只能是系统自带的属性,暂不支持自定义类.
 @complete 回调的block,返回的数组元素是字典 @[@{key:value},@{key:value}] .
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete;
/**
 全部查询.
 @name 表名称.
 @param 额外条件参数 例如排序 @"order by id desc" 等.
 @complete 回调的block,返回的数组元素是字典 @[@{key:value},@{key:value}] .
 */
-(void)queryWithTableName:(NSString* _Nonnull)name param:(NSString* _Nullable)param where:(NSArray* _Nullable)where complete:(Complete_A)complete;
/**
 keyPath查询.
 @name 表名称.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete;
/**
 更新数据.
 @name 表名称.
 @valueDict 将要更新的数据,存放的是key和value 即@{key:value,key:value}..
 @where 条件数组,形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部,条件key属性只能是系统自带的属性,暂不支持自定义类.
 @complete 回调的block.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(Complete_B)complete;
/**
 直接传入条件sql语句更新.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete;
/**
 根据keypath更新数据.
 @name 表名称.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues valueDict:(NSDictionary* _Nonnull)valueDict complete:(Complete_B)complete;
/**
 根据表名和条件删除表内容.
 @name 表名称.
 @where 条件数组,形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空.
 @complete 回调的block.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(Complete_B)complete;
/**
 直接传入条件sql语句删除.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete;
/**
 根据keypath删除表内容.
 @name 表名称.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete;
/**
 根据表名删除表格全部内容.
 @name 表名称.
 @complete 回调的block.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(Complete_B)complete;
/**
 删除表.
 @name 表名称.
 @complete 回调的block.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(Complete_B)complete;
/**
 动态添加表字段.
 @name 表名称.
 @key 将要增加的字段.
 @complete 回调的block.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(Complete_B)complete;
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
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 @name 表名称.
 @keys 新表的数组字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name keys:(NSArray<NSString*>* const _Nonnull)keys complete:(Complete_I)complete;
-(void)refreshTable:(NSString* _Nonnull)name keyDict:(NSDictionary* const _Nonnull)keyDict complete:(Complete_I)complete;
@end
