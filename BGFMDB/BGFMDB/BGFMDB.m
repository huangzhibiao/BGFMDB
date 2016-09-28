//
//  BGFMDB.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "BGFMDB.h"
#import "FMDB.h"
#import "MJExtension.h"
#import <objc/runtime.h>

#define SQLITE_NAME @"BGSqlite.sqlite"

@interface BGFMDB()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end

static BGFMDB* BGFmdb;

#warning 键值只能传NSString
@implementation BGFMDB

-(instancetype)init{
    self = [super init];
    if (self) {
        // 0.获得沙盒中的数据库文件名
        NSString *filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SQLITE_NAME];
        // 1.创建数据库队列
        self.queue = [FMDatabaseQueue databaseQueueWithPath:filename];
        NSLog(@"数据库初始化-----");
    }
    return self;
}

/**
 获取单例函数
 */
+(instancetype)intance{
    if(BGFmdb == nil){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            BGFmdb = [[BGFMDB alloc] init];
        });
    }
    return BGFmdb;
}

/**
 数据库中是否存在表
 */
-(void)isExistWithTableName:(NSString*)name complete:(void (^)(BOOL isExist))complete{
    if (name==nil){
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db){
        result = [db tableExists:name];
    }];
    if (complete) {
        complete(result);
    }
}

/**
 默认建立主键id
 创建表(如果存在则不创建) keys 数据存放要求@[字段名称1,字段名称2]
 */
-(void)createTableWithTableName:(NSString*)name keys:(NSArray*)keys complete:(void (^)(BOOL isSuccess))complete{
    if (name == nil) {
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }else if (keys == nil){
        NSLog(@"字段数组不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }else;
    
    //创表
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* header = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key autoincrement",name];//,name text,age integer);
        NSMutableString* sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        for(int i=0;i<keys.count;i++){
            [sql appendFormat:@",%@ text",keys[i]];
            if (i == (keys.count-1)) {
                [sql appendString:@");"];
            }
        }
        result = [db executeUpdate:sql];
    }];
    if (complete){
        complete(result);
    }
}
/**
 插入值
 */
-(void)insertIntoTableName:(NSString*)name Dict:(NSDictionary*)dict complete:(void (^)(BOOL isSuccess))complete{
    if (name == nil) {
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }else if (dict == nil){
        NSLog(@"插入值字典不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }else;
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSArray* keys = dict.allKeys;
        NSArray* values = dict.allValues;
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"insert into %@(",name];
        for(int i=0;i<keys.count;i++){
            [SQL appendFormat:@"%@",keys[i]];
            if(i == (keys.count-1)){
                [SQL appendString:@") "];
            }else{
                [SQL appendString:@","];
            }
        }
        [SQL appendString:@"values("];
        for(int i=0;i<values.count;i++){
            [SQL appendString:@"?"];
            if(i == (keys.count-1)){
                [SQL appendString:@");"];
            }else{
                [SQL appendString:@","];
            }
        }
        result = [db executeUpdate:SQL withArgumentsInArray:values];
        //NSLog(@"插入 -- %d",result);
    }];
    if (complete) {
        complete(result);
    }
}
/**
 根据条件查询字段
 */
-(void)queryWithTableName:(NSString*)name keys:(NSArray*)keys where:(NSArray*)where complete:(void (^)(NSArray* array))complete{
    if (name == nil) {
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    __block NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendString:@"select"];
        if ((keys!=nil)&&(keys.count>0)) {
            [SQL appendString:@" "];
            for(int i=0;i<keys.count;i++){
                [SQL appendFormat:@"%@",keys[i]];
                if (i != (keys.count-1)) {
                    [SQL appendString:@","];
                }
            }
        }else{
            [SQL appendString:@" *"]; 
        }
        [SQL appendFormat:@" from %@",name];
        if ((where!=nil) && (where.count>0)){
            if(!(where.count%3)){
                [SQL appendString:@" where "];
                for(int i=0;i<where.count;i+=3){
                    [SQL appendFormat:@"%@%@'%@'",where[i],where[i+1],where[i+2]];
                    if (i != (where.count-3)) {
                        [SQL appendString:@" and "];
                    }
                }
            }else{
              NSLog(@"条件数组错误!");
            }
        }
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
    }];
    if (complete) {
        complete(arrM);
    }
    //NSLog(@"查询 -- %@",arrM);
}

/**
 全部查询
 */
-(void)queryWithTableName:(NSString*)name complete:(void (^)(NSArray* array))complete{
    if (name==nil){
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    __block NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL = [NSString stringWithFormat:@"select * from %@",name];
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
    }];
    if (complete) {
        complete(arrM);
    }
    //NSLog(@"查询 -- %@",arrM);
}

/**
 根据key更新value
 */
-(void)updateWithTableName:(NSString*)name valueDict:(NSDictionary*)valueDict where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete{
    if (name == nil) {
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@='%@'",valueDict.allKeys[i],valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        if ((where!=nil) && (where.count>0)){
            if(!(where.count%3)){
                [SQL appendString:@" where "];
                for(int i=0;i<where.count;i+=3){
                    [SQL appendFormat:@"%@%@'%@'",where[i],where[i+1],where[i+2]];
                    if (i != (where.count-3)) {
                        [SQL appendString:@" and "];
                    }
                }
            }else{
                NSLog(@"条件数组格式错误!");
            }
        }
        result = [db executeUpdate:SQL];
        //NSLog(@"更新:  %@",SQL);
    }];
    if (complete) {
        complete(result);
    }
}

/**
 删除
 */
-(void)deleteWithTableName:(NSString*)name where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete{
    if (name == nil) {
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }else if (where==nil || (where.count%3)){
        NSLog(@"条件数组错误!");
        if (complete) {
            complete(NO);
        }
        return;
    }else;
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@ where ",name];
        for(int i=0;i<where.count;i+=3){
            [SQL appendFormat:@"%@%@'%@'",where[i],where[i+1],where[i+2]];
            if (i != (where.count-3)) {
                [SQL appendString:@" and "];
            }
        }
        result = [db executeUpdate:SQL];
    }];
    if (complete){
        complete(result);
    }
}
/**
 根据表名删除表格全部内容
 */
-(void )clearTable:(NSString *)name complete:(void (^)(BOOL isSuccess))complete{
    if (name==nil){
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@",name];
        result = [db executeUpdate:SQL];
    }];
    if (complete) {
        complete(result);
    }
}

/**
 删除表
 */
-(void)dropTable:(NSString*)name complete:(void (^)(BOOL isSuccess))complete{
    if (name==nil){
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL = [NSString stringWithFormat:@"drop table %@",name];
        result = [db executeUpdate:SQL];
    }];
    if (complete) {
        complete(result);
    }
}

/**
 存储一个对象
 */
-(void)saveObject:(id)object complete:(void (^)(BOOL isSuccess))complete{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    unsigned int numIvars; //成员变量个数
    Ivar *vars = class_copyIvarList([object class], &numIvars);
    NSString *key=nil;
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];  //获取成员变量的名字
        key = [key substringFromIndex:1];
        [dictM setObject:[object valueForKey:key] forKey:key];
        //NSLog(@"variable name :%@ = %@", key,[object valueForKey:key]);
        //key = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)]; //获取成员变量的数据类型
        //NSLog(@"variable type :%@", key);
    }
    free(vars);
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就新建
            [self createTableWithTableName:tableName keys:dictM.allKeys complete:^(BOOL isSuccess) {
                if (isSuccess) {
                    NSLog(@"建表成功 第一次建立 %@ 对应的表",tableName);
                }
            }];
        }
    }];
    [self insertIntoTableName:tableName Dict:dictM complete:complete];
}
/**
 查询全部对象
 */
-(void)queryAllObject:(__unsafe_unretained Class)cla complete:(void (^)(NSArray* array))complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [self queryWithTableName:tableName complete:^(NSArray *array) {
                NSMutableArray* arrM = [NSMutableArray array];
                for(NSDictionary* dict in array){
                    id claObj = [cla objectWithKeyValues:dict];
                    [arrM addObject:claObj];
                }
                if (complete) {
                    complete(arrM);
                }
            }];
        }
    }];
}
/**
 根据条件查询某个对象
 keys存放的是要查询的哪些key,为nil时代表查询全部
 where形式 @[@"key",@"=",@"value",@"key",@">=",@"value"]
 */
-(void)queryObjectWithClass:(__unsafe_unretained Class)cla keys:(NSArray*)keys where:(NSArray*)where complete:(void (^)(NSArray* array))complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [self queryWithTableName:tableName keys:keys where:where complete:^(NSArray *array) {
                NSMutableArray* arrM = [NSMutableArray array];
                for(NSDictionary* dict in array){
                    id claObj = [cla objectWithKeyValues:dict];
                    [arrM addObject:claObj];
                }
                if (complete) {
                    complete(arrM);
                }
            }];
        }
    }];
}
/**
 根据条件改变对象的值
 valueDict 存放的是key和value
 where数组的形式 @[@"key",@"=",@"value",@"key",@">=",@"value"]
 */
-(void)updateWithClass:(__unsafe_unretained Class)cla valueDict:(NSDictionary*)valueDict where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
          [self updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
        }
    }];
}
/**
 cla代表对应的类
 根据条件删除对象表中的对象数据
 where形式 @[@"key",@"=",@"value",@"key",@">=",@"value"],where要非空
 */
-(void)deleteWithClass:(__unsafe_unretained Class)cla where:(NSArray*)where complete:(void (^)(BOOL isSuccess))complete{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [self deleteWithTableName:tableName where:where complete:complete];
        }
    }];
    
}
/**
 根据类删除此类所有表数据
 */
-(void)clearWithClass:(__unsafe_unretained Class)cla complete:(void (^)(BOOL isSuccess))complete{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [self clearTable:tableName complete:complete];
        }
    }];
}
/**
 根据类,删除这个类的表
 */
-(void)dropWithClass:(__unsafe_unretained Class)cla complete:(void (^)(BOOL isSuccess))complete{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [self dropTable:tableName complete:complete];
        }
    }];
}
@end
