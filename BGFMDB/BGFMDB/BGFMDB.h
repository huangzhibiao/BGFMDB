//
//  BGFMDB.h
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BGFMDB : NSObject

/**
 获取单例函数
 */
+(instancetype)intance;
/** 
 数据库中是否存在表 
 */
- (void)isExistWithTableName:(NSString*)name complete:(void (^)(BOOL isExist))complete;
/**
 默认建立主键id
 创建表(如果存在则不创建) keys 数据存放要求@[字段名称1,字段名称2]
 */
-(void)createTableWithTableName:(NSString*)name keys:(NSArray*)keys complete:(void (^)(BOOL isSuccess))complete;
/**
 插入 只关心key和value @{key:value,key:value}
 */
-(void)insertIntoTableName:(NSString*)name Dict:(NSDictionary*)dict complete:(void (^)(BOOL isSuccess))complete;
/** 
 keys存放的是要查询的哪些key,为nil时代表查询全部
 根据条件查询字段 
 返回的数组是字典( @[@{key:value},@{key:value}] ) 
 where形式 @[@"key",@"=",@"value",@"key",@">=",@"value"]
 */
-(void)queryWithTableName:(NSString*)name keys:(NSArray*)keys where:(NSArray*)where complete:(void (^)(NSArray* array))complete;
/**
 全部查询 返回的数组是字典( @[@{key:value},@{key:value}] )
 */
-(void)queryWithTableName:(NSString*)name complete:(void (^)(NSArray* array))complete;
/**
 根据key更新value
 valueDict 存放的是key和value
 where数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部
 */
-(void)updateWithTableName:(NSString*)name valueDict:(NSDictionary*)valueDict where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete;
/**
 根据表名和条件删除表内容
 where形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空
 */
-(void)deleteWithTableName:(NSString*)name where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete;
/**
 根据表名删除表格全部内容
 */
-(void)clearTable:(NSString*)name complete:(void (^)(BOOL isSuccess))complete;
/**
 删除表
 */
-(void)dropTable:(NSString*)name complete:(void (^)(BOOL isSuccess))complete;

/**----------------------------------华丽分割线---------------------------------------------*/
#pragma mark --> 以下是存储一个对象的API

/**
 存储一个对象
 */
-(void)saveObject:(id)object complete:(void (^)(BOOL isSuccess))complete;
/**
 查询全部对象
 */
-(void)queryAllObject:(__unsafe_unretained Class)cla complete:(void (^)(NSArray* array))complete;
/**
 cla代表对应的类
 根据条件查询某个对象
 keys存放的是要查询的哪些key,为nil时代表查询全部
 where形式 @[@"key",@"=",@"value",@"key",@">=",@"value"]
 */
-(void)queryObjectWithClass:(__unsafe_unretained Class)cla keys:(NSArray*)keys where:(NSArray*)where complete:(void (^)(NSArray* array))complete;
/**
 cla代表对应的类
 根据条件改变对象的值
 valueDict 存放的是key和value
 where数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],为nil时设置全部
 */
-(void)updateWithClass:(__unsafe_unretained Class)cla valueDict:(NSDictionary*)valueDict where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete;
/**
 cla代表对应的类
 根据条件删除对象表中的对象数据
 where形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空
 */
-(void)deleteWithClass:(__unsafe_unretained Class)cla where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete;
/**
 根据类删除此类所有表数据
 */
-(void)clearWithClass:(__unsafe_unretained Class)cla complete:(void (^)(BOOL isSuccess))complete;
/**
 根据类,删除这个类的表
 */
-(void)dropWithClass:(__unsafe_unretained Class)cla complete:(void (^)(BOOL isSuccess))complete;
@end
