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

@interface BGFMDB : NSObject

/**
 获取单例函数.
 */
+(_Nonnull instancetype)shareManager;

#pragma mark --> 以下是直接存储一个对象的API

/**
 存储一个对象.
 @object 将要存储的对象.
 @complete 回调的block.
 */
-(void)saveObject:(id _Nonnull)object complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 查询全部对象.
 @cla 要查询对象的类
 @param 额外条件参数 例如排序 @"order by id desc" 等.
 @complete 回调的block.
 */
-(void)queryAllObject:(__unsafe_unretained _Nonnull Class)cla param:(NSString* _Nullable)param complete:(void (^_Nonnull)(NSArray* _Nullable array))complete;
/**
 根据条件查询某个对象.
 @cla 代表对应的类.
 @keys 存放的是要查询的哪些key,为nil时代表查询全部.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"] .
 @complete 回调的block.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* _Nullable)keys where:(NSArray* _Nullable)where complete:(void (^_Nullable)(NSArray* _Nullable array))complete;
/**
 根据条件改变对象的值.
 @cla 代表对应的类.
 @valueDict 存放的是key和value 即@{key:value,key:value}..
 @where 数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部.
 @complete 回调的block
 */
-(void)updateWithClass:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 根据条件删除对象表中的对象数据.
 @cla 代表对应的类.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空.
 @complete 回调的block
 */
-(void)deleteWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 根据类删除此类所有数据.
 @cla 代表对应的类.
 @complete 回调的block
 */
-(void)clearWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 根据类,删除这个类的表.
 @cla 代表对应的类.
 @complete 回调的block
 */
-(void)dropWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(void (^_Nonnull)(BOOL isSuccess))complete;

/**----------------------------------华丽分割线---------------------------------------------*/
#pragma mark --> 以下是非直接存储一个对象的API

/** 
 数据库中是否存在表.
 @name 表名称.
 @complete 回调的block
 */
- (void)isExistWithTableName:( NSString* _Nonnull)name complete:(void (^_Nonnull)(BOOL isExist))complete;
/**
 创建表(如果存在则不创建)
 @name 表名称.
 @keys 数据存放要求@[字段名称1,字段名称2].
 @primaryKey 主键字段,可以为nil.
 @complete 回调的block
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray* _Nonnull)keys primaryKey:(NSString* _Nullable)primarykey complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 插入数据.
 @name 表名称.
 @dict 插入的数据,只关心key和value 即@{key:value,key:value}.
 @complete 回调的block
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/** 
 根据条件查询字段.
 @name 表名称.
 @keys 存放的是要查询的哪些key,为nil时代表查询全部.
 @where 形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],条件key属性只能是系统自带的属性,暂不支持自定义类
 @complete 回调的block,返回的数组元素是字典 @[@{key:value},@{key:value}] .
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray* _Nullable)keys where:(NSArray* _Nullable)where complete:(void (^_Nonnull)(NSArray* _Nullable array))complete;
/**
 全部查询.
 @name 表名称.
 @param 额外条件参数 例如排序 @"order by id desc" 等.
 @complete 回调的block,返回的数组元素是字典 @[@{key:value},@{key:value}] .
 */
-(void)queryWithTableName:(NSString* _Nonnull)name param:(NSString* _Nullable)param complete:(void (^ _Nonnull )(NSArray*_Nullable array))complete;
/**
 更新数据.
 @name 表名称.
 @valueDict 将要更新的数据,存放的是key和value 即@{key:value,key:value}..
 @where 条件数组,形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部,条件key属性只能是系统自带的属性,暂不支持自定义类.
 @complete 回调的block.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 根据表名和条件删除表内容.
 @name 表名称.
 @where 条件数组,形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空,条件key属性只能是系统自带的属性,暂不支持自定义类.
 @complete 回调的block.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 根据表名删除表格全部内容.
 @name 表名称.
 @complete 回调的block.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 删除表.
 @name 表名称.
 @complete 回调的block.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(void (^_Nonnull)(BOOL isSuccess))complete;
/**
 动态添加表字段.
 @name 表名称.
 @key 将要增加的字段.
 @complete 回调的block.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(void (^_Nonnull)(BOOL isSuccess))complete;

@end
