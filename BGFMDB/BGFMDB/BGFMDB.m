//
//  BGFMDB.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "BGFMDB.h"
#import "FMDB.h"
#import <objc/runtime.h>

#define SQLITE_NAME @"BGSqlite.sqlite"

@interface BGFMDB()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end

static BGFMDB* BGFmdb;

@implementation BGFMDB

/**
 json字符转字典
 */
-(id )dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
    
}
/**
 字典转json字符
 */
-(NSString*)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


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
    //__weak typeof(self) BGSelf = self;
    [self.queue inDatabase:^(FMDatabase *db) {
        //__strong typeof(BGSelf) strongSelf = BGSelf;
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
        if(!rs){//查询错误
            NSLog(@"查询错误,可能是类变量名发生了改变或字段不存在!,请存储后再读取");
            if (complete) {
                complete(nil);
            }
            return;
        }
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
 动态添加表字段
 */
-(void)addTable:(NSString*)name key:(NSString*)key complete:(void (^)(BOOL isSuccess))complete{
    if (name==nil){
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(NO);
        }
        return;
    }
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:[NSString stringWithFormat:@"alter table %@ add %@ text",name,key]];
    }];
    if (complete) {
        complete(result);
    }

}
//根据类获取变量名列表
-(NSArray*)getClassIvarList:(__unsafe_unretained Class)cla{
    unsigned int numIvars; //成员变量个数
    Ivar *vars = class_copyIvarList(cla, &numIvars);
    NSMutableArray* keys = [NSMutableArray array];
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        NSString* key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名
        if ([key containsString:@"_"]) {
            key = [key substringFromIndex:1];
        }
        [keys addObject:key];//存储对象的变量名
    }
    free(vars);//释放资源
    return keys;
}
//判断类的变量名是否变更,然后改变表字段结构
-(void)changeTableWhenClassIvarChange:(__unsafe_unretained Class)cla{
    NSMutableArray* newKeys = [NSMutableArray array];
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    __weak typeof(self) BGSelf = self;
    [self.queue inDatabase:^(FMDatabase *db){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        for (NSString* key in [strongSelf getClassIvarList:cla]) {
            if(![db columnExists:key inTableWithName:tableName]){
                //记录下不存在的字段
                [newKeys addObject:key];
                NSLog(@"表字段发生了改变...");
            }
        }
    }];
    for(NSString* key in newKeys){
        [self addTable:tableName key:key complete:^(BOOL isSuccess) {
            if (isSuccess) {
                NSLog(@"添加表字段成功");
            }else{
                NSLog(@"添加表字段失败!");
            }
        }];
    }
}
/**
 存储一个对象
 */
-(void)saveObject:(id)object complete:(void (^)(BOOL isSuccess))complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就新建
            [strongSelf createTableWithTableName:tableName keys:[strongSelf getClassIvarList:[object class]] complete:^(BOOL isSuccess) {
                if (isSuccess) {
                    NSLog(@"建表成功 第一次建立 %@ 对应的表",tableName);
                }
            }];
        }
        NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
        unsigned int numIvars; //成员变量个数
        Ivar *vars = class_copyIvarList([object class], &numIvars);
        for(int i = 0; i < numIvars; i++) {
            Ivar thisIvar = vars[i];
            NSString *key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名字
            if ([key containsString:@"_"]) {
                key = [key substringFromIndex:1];
            }
            
            //NSLog(@"variable name :%@ = %@", key,[object valueForKey:key]);
            NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)]; //获取成员变量的数据类型
            NSLog(@"variable type :%@", type);
            if([type isEqualToString:[NSString stringWithFormat:@"@\"%@\"",@"NSArray"]]){
                NSArray* arr = [object valueForKey:key];
                NSMutableDictionary* dM = [NSMutableDictionary dictionary];
                for(int i=0;i<arr.count;i++){
                    dM[[NSString stringWithFormat:@"%d",i]] = arr[i];
                }
                NSString* jsonStr = [NSString stringWithFormat:@"NSArray%@",[self dictionaryToJson:dM]];
                [dictM setObject:jsonStr forKey:key];
            }else if([type isEqualToString:[NSString stringWithFormat:@"@\"%@\"",@"NSDictionary"]]){
                NSString* jsonStr = [NSString stringWithFormat:@"NSDictionary%@",[self dictionaryToJson:[object valueForKey:key]]];
                [dictM setObject:jsonStr forKey:key];
            }else{
                //setObjectForKey: object cannot be nil
                [dictM setObject:([object valueForKey:key]==nil)?@"0":[object valueForKey:key] forKey:key];
            }
    
        }
        free(vars);//释放资源
        __weak typeof(BGSelf) secondSelf = strongSelf;
        [strongSelf insertIntoTableName:tableName Dict:dictM complete:^(BOOL isSuccess) {
            if (isSuccess) {
                if (complete) {
                    complete(isSuccess);
                }
            }else{
                //检查表字段是否有改变
                [secondSelf changeTableWhenClassIvarChange:[object class]];
                [secondSelf insertIntoTableName:tableName Dict:dictM complete:complete];
            }
        }];
    }];
    
}

//数组转换
-(NSArray*)translateResult:(__unsafe_unretained Class)cla with:(NSArray*)array{
    
    NSArray* keys = [self getClassIvarList:cla];
    NSMutableArray* arrM = [NSMutableArray array];
    for(NSDictionary* dict in array){
        id claObj = [[cla alloc] init];
        for(NSString* key in keys){
            if([[NSString stringWithFormat:@"%@",dict[key]] containsString:@"NSArray"]){
                NSDictionary* jsonDict = [self dictionaryWithJsonString:[[NSString stringWithFormat:@"%@",dict[key]] stringByReplacingOccurrencesOfString:@"NSArray" withString:@""]];
                NSMutableArray* tempArrM = [NSMutableArray array];
                for(id obj in jsonDict.allValues){
                    [tempArrM addObject:obj];
                }
                [claObj setValue:tempArrM forKey:key];
            }else if ([[NSString stringWithFormat:@"%@",dict[key]] containsString:@"NSDictionary"]){
                NSDictionary* jsonDict = [self dictionaryWithJsonString:[[NSString stringWithFormat:@"%@",dict[key]] stringByReplacingOccurrencesOfString:@"NSDictionary" withString:@""]];
                [claObj setValue:jsonDict forKey:key];
            }else{
             [claObj setValue:dict[key] forKey:key];
            }
        }
        [arrM addObject:claObj];
    }
    
    return arrM;
}

/**
 查询全部对象
 */
-(void)queryAllObject:(__unsafe_unretained Class)cla complete:(void (^)(NSArray* array))complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            __weak typeof(BGSelf) secondSelf = strongSelf;
            [strongSelf queryWithTableName:tableName complete:^(NSArray *array) {
                NSArray* arrM = [secondSelf translateResult:cla with:array];
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
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            __weak typeof(BGSelf) secondSelf = strongSelf;
            [strongSelf queryWithTableName:tableName keys:keys where:where complete:^(NSArray *array) {
                NSArray* arrM = [secondSelf translateResult:cla with:array];
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
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
          [strongSelf updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
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
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf deleteWithTableName:tableName where:where complete:complete];
        }
    }];
    
}
/**
 根据类删除此类所有表数据
 */
-(void)clearWithClass:(__unsafe_unretained Class)cla complete:(void (^)(BOOL isSuccess))complete{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf clearTable:tableName complete:complete];
        }
    }];
}
/**
 根据类,删除这个类的表
 */
-(void)dropWithClass:(__unsafe_unretained Class)cla complete:(void (^)(BOOL isSuccess))complete{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf dropTable:tableName complete:complete];
        }
    }];
}
@end
