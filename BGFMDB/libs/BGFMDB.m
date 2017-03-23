//
//  BGFMDB.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "BGFMDB.h"

#define MaxQueryPageNum 50

static const void * const BGFMDBDispatchQueueSpecificKey = &BGFMDBDispatchQueueSpecificKey;

@interface BGFMDB()
{
    dispatch_queue_t    serialQueue;
}
@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) FMDatabase* db;
@property (nonatomic, strong) NSRecursiveLock *threadLock;

@property (nonatomic,strong) NSMutableDictionary* changeBlocks;//记录注册监听数据变化的block.

@end

static BGFMDB* BGFmdb;

@implementation BGFMDB

-(void)dealloc{
    if (self.changeBlocks){
        [self.changeBlocks removeAllObjects];//清除所有注册列表.
        self.changeBlocks = nil;
    }
    if (serialQueue) {
        FMDBDispatchQueueRelease(serialQueue);
        serialQueue = 0x00;
    }
    if(self.queue) {
        [self.queue close];//关闭数据库.
        self.queue = nil;
    }
    if (BGFmdb) {
        BGFmdb = nil;
    }
}

-(instancetype)init{
    self = [super init];
    if (self) {
        // 0.获得沙盒中的数据库文件名
        NSString *filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SQLITE_NAME];
        // 1.创建数据库队列
        self.queue = [FMDatabaseQueue databaseQueueWithPath:filename];
        self.threadLock = [[NSRecursiveLock alloc] init];
        self.changeBlocks = [NSMutableDictionary dictionary];
        //初始化串行队列,用于解决多线程问题,模仿FMDB的FMDatabaseQueue处理.
        serialQueue = dispatch_queue_create([[NSString stringWithFormat:@"BGFMDB.%@", self] UTF8String], NULL);
        dispatch_queue_set_specific(serialQueue, BGFMDBDispatchQueueSpecificKey, (__bridge void *)self, NULL);
    }
    return self;
}
/**
 获取单例函数.
 */
+(_Nonnull instancetype)shareManager{
    if(BGFmdb == nil){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            BGFmdb = [[BGFMDB alloc] init];
        });
    }
    return BGFmdb;
}
//事务操作
-(void)inTransaction:(BOOL (^_Nonnull)())block{
    NSAssert(block, @"block is nil!");
    [self executeDB:^(FMDatabase * _Nonnull db) {
        BOOL inTransacttion = db.inTransaction;
        if (!inTransacttion) {
            [db beginTransaction];
        }
        BOOL isCommit = NO;
        isCommit = block();
        if (!inTransacttion) {
            if (isCommit) {
                [db commit];
            }
            else {
                [db rollback];
            }
        }
    }];
}
/**
 为了对象层的事物操作而封装的函数.
 */
-(void)executeDB:(void (^_Nonnull)(FMDatabase *_Nonnull db))block{
    NSAssert(block, @"block is nil!");
    [self.threadLock lock];//加锁
    
    if (_db){//为了事务操作防止死锁而设置.
        block(_db);
        return;
    }
    __weak typeof(self) BGSelf = self;
    [self.queue inDatabase:^(FMDatabase *db) {
        BGSelf.db = db;
        block(db);
        BGSelf.db = nil;
    }];
    
    [self.threadLock unlock];//解锁
}

/**
 注册数据变化监听.
 */
-(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(ChangeBlock)block{
    if ([_changeBlocks.allKeys containsObject:name]){
        NSArray* array = [name componentsSeparatedByString:@"*"];
        NSString* reason = [NSString stringWithFormat:@"%@类注册监听名称%@重复,注册监听失败!",array.firstObject,array.lastObject];
        debug(reason);
        return NO;
    }else{
        [_changeBlocks setObject:block forKey:name];
        return YES;
    }
}
/**
 移除数据变化监听.
 */
-(BOOL)removeChangeWithName:(NSString* const _Nonnull)name{
    if ([_changeBlocks.allKeys containsObject:name]){
        [_changeBlocks removeObjectForKey:name];
        return YES;
    }else{
        NSArray* array = [name componentsSeparatedByString:@"*"];
        NSString* reason = [NSString stringWithFormat:@"没有找到类%@对应的%@名称监听,移除监听失败!",array.firstObject,array.lastObject];
        debug(reason);
        return NO;
    }
}
-(void)doChangeWithName:(NSString* const _Nonnull)name flag:(BOOL)flag state:(changeState)state{
    if(flag){
        [_changeBlocks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
            NSArray* array = [key componentsSeparatedByString:@"*"];
            if([name isEqualToString:array.firstObject]){
                void(^block)(changeState) = obj;
                block(state);
            }
        }];
    }
}

/**
 数据库中是否存在表.
 */
-(void)isExistWithTableName:(NSString* _Nonnull)name complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        result = [db tableExists:name];
    }];
    if (complete) {
        complete(result);
    }
}


/**
 创建表(如果存在则不创建).
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys uniqueKey:(NSString* _Nullable)uniqueKey complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    //创表
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* header = [NSString stringWithFormat:@"create table if not exists %@ (",name];
        NSMutableString* sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        BOOL uniqueKeyFlag = NO;
        for(int i=0;i<keys.count;i++){
            
            if(uniqueKey){
                if([BGTool isUniqueKey:uniqueKey with:keys[i]]){
                    uniqueKeyFlag = YES;
                    [sql appendFormat:@"%@ unique",[BGTool keyAndType:keys[i]]];
                }else if ([[keys[i] componentsSeparatedByString:@"*"][0] isEqualToString:BGPrimaryKey]){
                    [sql appendFormat:@"%@ primary key autoincrement",[BGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[BGTool keyAndType:keys[i]]];
                }
            }else{
                if ([[keys[i] componentsSeparatedByString:@"*"][0] isEqualToString:BGPrimaryKey]){
                    [sql appendFormat:@"%@ primary key autoincrement",[BGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[BGTool keyAndType:keys[i]]];
                }
            }
            
            if (i == (keys.count-1)) {
                [sql appendString:@");"];
            }else{
                [sql appendString:@","];
            }
        }
        
        if(uniqueKey){
            NSAssert(uniqueKeyFlag,@"没有找到设置的主键,请检查primarykey返回值是否正确!");
        }
        debug(sql);
        result = [db executeUpdate:sql];
    }];
    
    if (complete){
        complete(result);
    }
}
/**
 插入数据.
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(dict,@"插入值字典不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
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
        
        debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:values];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Insert];
    if (complete) {
        complete(result);
    }
}

-(void)queryQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(conditions||conditions.length,@"查询条件不能为空!");
    NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL = [NSString stringWithFormat:@"select * from %@ %@",name,conditions];
        debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        if (rs == nil) {
            debug(@"查询错误,可能是'类变量名'发生了改变或'字段','表格'不存在!,请存储后再读取!");
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
}

/**
 直接传入条件sql语句查询
 */
-(void)queryWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_A)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self queryQueueWithTableName:name conditions:conditions complete:complete];
    });
    }
}
/**
 根据条件查询字段.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    NSMutableArray* arrM = [[NSMutableArray alloc] init];
    __block NSArray* arguments;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendString:@"select"];
        if ((keys!=nil)&&(keys.count>0)) {
            [SQL appendString:@" "];
            for(int i=0;i<keys.count;i++){
                [SQL appendFormat:@"%@%@",BG,keys[i]];
                if (i != (keys.count-1)) {
                    [SQL appendString:@","];
                }
            }
        }else{
            [SQL appendString:@" *"]; 
        }
        [SQL appendFormat:@" from %@",name];
        
        if((where!=nil) && (where.count>0)){
            NSArray* results = [BGTool where:where];
            [SQL appendString:results[0]];
            arguments = results[1];
        }
        
        debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL withArgumentsInArray:arguments];
        if (rs == nil) {
            debug(@"查询错误,可能是'类变量名'发生了改变或'字段','表格'不存在!,请存储后再读取,或检查条件数组'字段名称'是否正确");
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
}

/**
 查询对象.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name param:(NSString* _Nullable)param where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    NSMutableArray* arrM = [[NSMutableArray alloc] init];
    __block NSArray* arguments;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [NSMutableString string];
        [SQL appendFormat:@"select * from %@",name];
        
        if ((where!=nil) && (where.count>0)){
            if((where!=nil) && (where.count>0)){
                NSArray* results = [BGTool where:where];
                [SQL appendString:results[0]];
                arguments = results[1];
            }
        }
        
        !param?:[SQL appendFormat:@" %@",param];
        debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL withArgumentsInArray:arguments];
        if (rs == nil) {
            debug(@"查询错误,'表格'不存在!,请存储后再读取!");
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


-(void)queryWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete{
    NSMutableArray* arrM = [NSMutableArray array];
    NSString* like = [BGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select * from %@%@",name,like];
        debug(SQL);
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
}

/**
 更新数据.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(valueDict,@"更新数据集合不能为空!");
    __block BOOL result;
    NSMutableArray* arguments = [NSMutableArray array];
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@=?",valueDict.allKeys[i]];
            [arguments addObject:valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        if ((where!=nil) && (where.count>0)){
            if((where!=nil) && (where.count>0)){
                NSArray* results = [BGTool where:where];
                [SQL appendString:results[0]];
                [arguments addObjectsFromArray:results[1]];
            }
        }
        debug(SQL);
       result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Update];
    if (complete) {
        complete(result);
    }
}
-(void)updateQueueWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(conditions||conditions.length,@"查询条件不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL;
        if ((valueDict==nil) || !valueDict.allKeys.count) {
            SQL = [NSString stringWithFormat:@"update %@ %@",name,conditions];
        }else{
            NSMutableString* param = [NSMutableString stringWithFormat:@"update %@ set ",name];
            for(int i=0;i<valueDict.allKeys.count;i++){
                NSString* key = valueDict.allKeys[i];
                id value = valueDict[key];
                if ([value isKindOfClass:[NSString class]]) {
                    [param appendFormat:@"%@='%@'",key,value];
                }else{
                    [param appendFormat:@"%@=%@",key,value];
                }
                if(i != (valueDict.allKeys.count-1)) {
                    [param appendString:@","];
                }
            }
            [param appendFormat:@" %@",conditions];
            SQL = param;
        }
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Update];
    if (complete) {
        complete(result);
    }
}
/**
 直接传入条件sql语句更新.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self updateQueueWithTableName:name valueDict:valueDict conditions:conditions complete:complete];
    });
    }
}
/**
 根据keypath更新数据
 */
-(void)updateWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues valueDict:(NSDictionary* _Nonnull)valueDict complete:(Complete_B)complete{
    NSString* like = [BGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    NSMutableArray* arguments = [NSMutableArray array];
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@=?",valueDict.allKeys[i]];
            [arguments addObject:valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        [SQL appendString:like];
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
        debug(SQL);
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Update];
    if (complete) {
        complete(result);
    }
}
/**
 根据条件删除数据.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(where,@"条件数组错误! 不能为空");
    __block BOOL result;
    NSMutableArray* arguments = [NSMutableArray array];
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@",name];
        
        if ((where!=nil) && (where.count>0)){
            if((where!=nil) && (where.count>0)){
                NSArray* results = [BGTool where:where];
                [SQL appendString:results[0]];
                [arguments addObjectsFromArray:results[1]];
            }
        }
        debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Delete];
    if (complete){
        complete(result);
    }
}

-(void)deleteQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(conditions||conditions.length,@"查询条件不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@ %@",name,conditions];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Delete];
    if (complete){
        complete(result);
    }
}

/**
 直接传入条件sql语句删除.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self deleteQueueWithTableName:name conditions:conditions complete:complete];
    });
    }
}

-(void)deleteQueueWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSString* like = [BGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@%@",name,like];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Delete];
    if (complete){
        complete(result);
    }
}

//根据keypath删除表内容.
-(void)deleteWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self deleteQueueWithTableName:name forKeyPathAndValues:keyPathValues complete:complete];
    });
    }

}
/**
 根据表名删除表格全部内容.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@",name];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Delete];
    if (complete) {
        complete(result);
    }
}

/**
 删除表.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"drop table %@",name];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:Drop];
    if (complete){
        complete(result);
    }
}
/**
 动态添加表字段.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"alter table %@ add %@",name,[BGTool keyAndType:key]];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    if (complete) {
        complete(result);
    }

}
/**
 查询该表中有多少条数据
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where{
    NSAssert(name,@"表名不能为空!");
    NSAssert(!(where.count%3),@"条件数组错误!");
    NSMutableString* strM = [NSMutableString string];
    !where?:[strM appendString:@" where "];
    for(int i=0;i<where.count;i+=3){
        if ([where[i+2] isKindOfClass:[NSString class]]) {
            [strM appendFormat:@"%@%@%@'%@'",BG,where[i],where[i+1],where[i+2]];
        }else{
            [strM appendFormat:@"%@%@%@%@",BG,where[i],where[i+1],where[i+2]];
        }
        
        if (i != (where.count-3)) {
            [strM appendString:@" and "];
        }
    }
    __block NSUInteger count=0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select count(*) from %@%@",name,strM];
        debug(SQL);
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] integerValue];
            return 0;
        }];
    }];
    return count;
}
/**
 直接传入条件sql语句查询数据条数.
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions{
    NSAssert(name,@"表名不能为空!");
    NSAssert(conditions||conditions.length,@"查询条件不能为空!");
    __block NSUInteger count=0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select count(*) from %@ %@",name,conditions];
        debug(SQL);
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] integerValue];
            return 0;
        }];
    }];
    return count;
}
/**
 keyPath查询数据条数.
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    NSString* like = [BGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    __block NSUInteger count=0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select count(*) from %@%@",name,like];
        debug(SQL);
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] integerValue];
            return 0;
        }];
    }];
    return count;
}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B keys:(NSArray<NSString*>* const _Nonnull)keys complete:(Complete_I)complete{
    //获取"唯一约束"字段名
    NSString* uniqueKey = [BGTool getUnique:[NSClassFromString(A) new]];
    //建立一张临时表
    __block BOOL createFlag;
    [self createTableWithTableName:B keys:keys uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        debug(@"数据库更新失败!")
        !complete?:complete(Error);
        return;
    }
    __block dealState refreshstate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    NSInteger count = [self countForTable:A where:nil];
    for(NSInteger i=0;i<count;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:A param:param where:nil complete:^(NSArray * _Nullable array) {
                for(NSDictionary* oldDict in array){
                    NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
                    for(NSString* keyAndType in keys){
                        NSString* key = [keyAndType componentsSeparatedByString:@"*"][0];
                        //字段名前加上 @"BG_"
                        key = [NSString stringWithFormat:@"%@%@",BG,key];
                        if (oldDict[key]){
                            newDict[key] = oldDict[key];
                        }
                    }
                    //将旧表的数据插入到新表
                    [BGSelf insertIntoTableName:B Dict:newDict complete:^(BOOL isSuccess){
                        if (isSuccess){
                            if (!recordSuccess) {
                                recordSuccess = YES;
                            }
                        }else{
                            if (!recordError) {
                                recordError = YES;
                            }
                        }
                        
                    }];
                }
                }];
                }
            }
    
    if (complete){
        if (recordError && recordSuccess) {
            refreshstate = Incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = Error;
        }else if (recordSuccess && !recordError){
            refreshstate = Complete;
        }else;
        complete(refreshstate);
    }

}

-(void)refreshQueueTable:(NSString* _Nonnull)name keys:(NSArray<NSString*>* const _Nonnull)keys complete:(Complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    [self isExistWithTableName:name complete:^(BOOL isSuccess){
        if (!isSuccess){
            debug(@"没有数据存在,数据库更新失败!")
            !complete?:complete(Error);
            return;
        }
    }];
    NSString* BGTempTable = @"BGTempTable";
    //事务操作.
    __block int recordFailCount = 0;
    [self inTransaction:^BOOL{
        [self copyA:name toB:BGTempTable keys:keys complete:^(dealState result) {
            if(result == Complete){
                recordFailCount++;
            }
        }];
        [self dropTable:name complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:name keys:keys complete:^(dealState result) {
            if(result == Complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if(recordFailCount != 4){
            debug(@"发生错误，更新数据库失败!");
        }
        return recordFailCount==4;
    }];
    
    //回调结果.
    if (recordFailCount==0) {
        !complete?:complete(Error);
    }else if (recordFailCount>0&&recordFailCount<4){
        !complete?:complete(Incomplete);
    }else{
        !complete?:complete(Complete);
    }
}

/**
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name keys:(NSArray<NSString*>* const _Nonnull)keys complete:(Complete_I)complete{
    
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self refreshQueueTable:name keys:keys complete:complete];
    });
    }

}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B keyDict:(NSDictionary* const _Nullable)keyDict complete:(Complete_I)complete{
    //获取"唯一约束"字段名
    NSString* uniqueKey = [BGTool getUnique:[NSClassFromString(A) new]];
    __block NSArray* keys = [BGTool getClassIvarList:NSClassFromString(A) onlyKey:NO];
    NSArray* newKeys = keyDict.allKeys;
    NSArray* oldKeys = keyDict.allValues;
    //建立一张临时表
    __block BOOL createFlag;
    [self createTableWithTableName:B keys:keys uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        debug(@"数据库更新失败!")
        !complete?:complete(Error);
        return;
    }
    
    __block dealState refreshstate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    NSInteger count = [self countForTable:A where:nil];
    for(NSInteger i=0;i<count;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:A param:param where:nil complete:^(NSArray * _Nullable array) {
                __strong typeof(BGSelf) strongSelf = BGSelf;
                for(NSDictionary* oldDict in array){
                    NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
                    for(NSString* keyAndType in keys){
                        NSString* key = [keyAndType componentsSeparatedByString:@"*"][0];
                        //字段名前加上 @"BG_"
                        key = [NSString stringWithFormat:@"%@%@",BG,key];
                        if (oldDict[key]){
                            newDict[key] = oldDict[key];
                        }
                    }
                    for(int i=0;i<oldKeys.count;i++){
                        //字段名前加上 @"BG_"
                        NSString* oldkey = [NSString stringWithFormat:@"%@%@",BG,oldKeys[i]];
                        NSString* newkey = [NSString stringWithFormat:@"%@%@",BG,newKeys[i]];
                        if (oldDict[oldkey]){
                            newDict[newkey] = oldDict[oldkey];
                        }
                    }
                    //将旧表的数据插入到新表
                    [strongSelf insertIntoTableName:B Dict:newDict complete:^(BOOL isSuccess){
                      
                        if (isSuccess){
                            if (!recordSuccess) {
                                recordSuccess = YES;
                            }
                        }else{
                            if (!recordError) {
                                recordError = YES;
                            }
                        }
                    }];
                }

            }];
        }
    }

    if (complete){
        if (recordError && recordSuccess) {
            refreshstate = Incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = Error;
        }else if (recordSuccess && !recordError){
            refreshstate = Complete;
        }else;
        complete(refreshstate);
    }

    
}

-(void)refreshQueueTable:(NSString* _Nonnull)name keyDict:(NSDictionary* const _Nonnull)keyDict complete:(Complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keyDict,@"变量名影射集合不能为空!");
    [self isExistWithTableName:name complete:^(BOOL isSuccess){
        if (!isSuccess){
            debug(@"没有数据存在,数据库更新失败!")
            !complete?:complete(Error);
            return;
        }
    }];
    __block NSArray* keys = [BGTool getClassIvarList:NSClassFromString(name) onlyKey:YES];
    NSArray* newKeys = keyDict.allKeys;
    NSArray* oldKeys =keyDict.allValues;
    for(int i=0;i<newKeys.count;i++){
        if (![keys containsObject:newKeys[i]]){
            NSString* result = [NSString stringWithFormat:@"新变量出错名称 = %@",newKeys[i]];
            debug(result);
            @throw [NSException exceptionWithName:@"类新变量名称写错" reason:@"请检查keydict中的 新Key 是否书写正确!" userInfo:nil];
        }
    }

    [self queryWithTableName:name param:@"limit 0,1" where:nil complete:^(NSArray<NSDictionary*> * _Nullable array) {
        NSArray* tableKeys = array.firstObject.allKeys;
        NSString* tableKey;
        for(int i=0;i<oldKeys.count;i++){
            tableKey = [NSString stringWithFormat:@"%@%@",BG,oldKeys[i]];
            if (![tableKeys containsObject:tableKey]){
                NSString* result = [NSString stringWithFormat:@"旧变量出错名称 = %@",oldKeys[i]];
                debug(result);
                @throw [NSException exceptionWithName:@"类旧变量名称写错" reason:@"请检查keydict中的 旧Key 是否书写正确!" userInfo:nil];
            }
        }

    }];
    //事务操作.
    NSString* BGTempTable = @"BGTempTable";
    __block int recordFailCount = 0;
    [self inTransaction:^BOOL{
        [self copyA:name toB:BGTempTable keyDict:keyDict complete:^(dealState result) {
            if(result == Complete){
                recordFailCount++;
            }
        }];
        [self dropTable:name complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:name keys:[BGTool getClassIvarList:NSClassFromString(name) onlyKey:NO] complete:^(dealState result) {
            if(result == Complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if (recordFailCount != 4) {
            debug(@"发生错误，更新数据库失败!");
        }
        return recordFailCount==4;
    }];
    
    //回调结果.
    if (recordFailCount==0) {
        !complete?:complete(Error);
    }else if (recordFailCount>0&&recordFailCount<4){
        !complete?:complete(Incomplete);
    }else{
        !complete?:complete(Complete);
    }

}

-(void)refreshTable:(NSString* _Nonnull)name keyDict:(NSDictionary* const _Nonnull)keyDict complete:(Complete_I)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    dispatch_sync(serialQueue, ^() {
        [self refreshQueueTable:name keyDict:keyDict complete:complete];
    });

}

////判断类的变量名是否变更,然后改变表字段结构.
//-(void)changeTableWhenClassIvarChange:(__unsafe_unretained Class)cla{
//    NSString* tableName = NSStringFromClass(cla);
//    NSMutableArray* copyKeys = [NSMutableArray array];
//    //先把相同的列拷贝.
//    [self executeDB:^(FMDatabase * _Nonnull db){
//        NSArray* currentKeys = [BGTool getClassIvarList:cla onlyKey:YES];
//        NSString* SQL = [NSString stringWithFormat:@"select * from %@ limit 0,1",tableName];
//        // 1.查询数据
//        debug(SQL);
//        FMResultSet *rs = [db executeQuery:SQL];
//        for (int i=0; i<[rs columnCount]; i++) {
//            NSString * columnName = [rs columnNameForIndex:i];
//            [currentKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                NSString* currentKey = [NSString stringWithFormat:@"%@%@",BG,obj];
//                if([columnName isEqualToString:currentKey]){
//                    if([obj isEqualToString:primaryKey]){
//                      currentKey = [NSString stringWithFormat:@"%@ primary key autoincrement integer",currentKey];
//                    }
//                    [copyKeys addObject:currentKey];
//                    *stop = YES;
//                }
//            }];
//        }
//    }];
//    //事务操作.
//    [self inTransaction:^BOOL{
//        __block int recordFailCount = 0;
//        [self executeDB:^(FMDatabase * _Nonnull db){
//            NSMutableString* param = [NSMutableString string];
//            for(int i=0;i<copyKeys.count;i++){
//                [param appendString:copyKeys[i]];
//                if (i != (copyKeys.count-1)){
//                    [param appendString:@","];
//                }
//            }
//            NSString* SQL = [NSString stringWithFormat:@"create table BGTempTable as select %@ from %@;",param,tableName];
//            debug(SQL);
//            if([db executeUpdate:SQL])recordFailCount++;
//        }];
//        [self dropTable:tableName complete:^(BOOL isSuccess) {
//            if(isSuccess)recordFailCount++;
//        }];
//        [self executeDB:^(FMDatabase * _Nonnull db){
//            NSString* SQL = [NSString stringWithFormat:@"alter table BGTempTable rename to %@;",tableName];
//            debug(SQL);
//            if([db executeUpdate:SQL])recordFailCount++;
//        }];
//        return recordFailCount==3;
//    }];
//    
//    NSMutableArray* newKeys = [NSMutableArray array];
//    [self executeDB:^(FMDatabase * _Nonnull db){
//        NSArray* keys = [BGTool getClassIvarList:cla onlyKey:NO];
//        for (NSString* keyAndtype in keys){
//            NSString* key = [[keyAndtype componentsSeparatedByString:@"*"] firstObject];
//            key = [NSString stringWithFormat:@"%@%@",BG,key];
//            if(![db columnExists:key inTableWithName:tableName]){
//                [newKeys addObject:keyAndtype];
//            }
//        }
//    }];
//    
//    //写在外面是为了防止数据库队列发生死锁.
//    for(NSString* key in newKeys){
//        //添加新字段
//        [self addTable:tableName key:key complete:^(BOOL isSuccess){}];
//    }
//}

/**
 处理插入的字典数据并返回
 */
-(void)insertDictWithObject:(id)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(Complete_B)complete{
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:object];
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    if (ignoredKeys) {
        for(BGModelInfo* info in infos){
            if(![ignoredKeys containsObject:info.propertyName]){
                dictM[info.sqlColumnName] = info.sqlColumnValue;
            }
        }
    }else{
        for(BGModelInfo* info in infos){
            dictM[info.sqlColumnName] = info.sqlColumnValue;
        }
    }
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    __weak typeof(self) BGSelf = self;
    [self insertIntoTableName:tableName Dict:dictM complete:^(BOOL isSuccess){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (isSuccess){
            !complete?:complete(isSuccess);
        }else{
            //检查表字段是否有改变
            //[strongSelf changeTableWhenClassIvarChange:[object class]];
            //刷新表数据库.
            [strongSelf refreshQueueTable:tableName keys:[BGTool getClassIvarList:[object class] onlyKey:NO] complete:nil];
            [strongSelf insertIntoTableName:tableName Dict:dictM complete:complete];
        }
    }];

}
/**
 存储一个对象.
 */
-(void)saveQueueObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(Complete_B)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass([object class]);
    //获取"唯一约束"字段名
    NSString* uniqueKey = [BGTool getUnique:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就新建
            NSMutableArray* createKeys = [NSMutableArray arrayWithArray:[BGTool getClassIvarList:[object class] onlyKey:NO]];
            //判断是否有需要忽略的key集合.
            if (ignoredKeys){
                for(__block int i=0;i<createKeys.count;i++){
                    NSString* createKey = [createKeys[i] componentsSeparatedByString:@"*"][0];
                    [ignoredKeys enumerateObjectsUsingBlock:^(id  _Nonnull ignoreKey, NSUInteger idi, BOOL * _Nonnull stop) {
                        if([createKey isEqualToString:ignoreKey]){
                            [createKeys removeObjectAtIndex:i];
                            i--;
                            *stop = YES;
                        }
                    }];
                }
            }
            [strongSelf createTableWithTableName:tableName keys:createKeys uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
                if (isSuccess){
                    NSString* successInfo = [NSString stringWithFormat:@"建表成功 第一次建立 %@ 对应的表",tableName];
                    debug(successInfo);
                }
            }];
        }
        
        //插入数据
        [strongSelf insertDictWithObject:object ignoredKeys:ignoredKeys complete:complete];
    }];

}
-(void)saveObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
        dispatch_sync(serialQueue, ^() {
            [self saveQueueObject:object ignoredKeys:ignoredKeys complete:complete];
        });
    }
}

-(void)queryObjectQueueWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nullable)where param:(NSString* _Nullable)param complete:(Complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [strongSelf queryWithTableName:tableName param:param where:where complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
                if (complete) {
                    complete(resultArray);
                }
            }];
        }
    }];
}
/**
 查询对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nullable)where param:(NSString* _Nullable)param complete:(Complete_A)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self queryObjectQueueWithClass:cla where:where param:param complete:complete];
    });
    }
}
-(void)queryObjectQueueWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [strongSelf queryWithTableName:tableName keys:keys where:where complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
                if (complete) {
                    complete(resultArray);
                }
            }];
        }
    }];
}
/**
 根据条件查询对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self queryObjectQueueWithClass:cla keys:keys where:where complete:complete];
    });
    }
}

-(void)queryObjectQueueWithClass:(__unsafe_unretained _Nonnull Class)cla forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [strongSelf queryWithTableName:tableName forKeyPathAndValues:keyPathValues complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
                if (complete) {
                    complete(resultArray);
                }
            }];
        }
    }];
}

//根据keyPath查询对象
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self queryObjectQueueWithClass:cla forKeyPathAndValues:keyPathValues complete:complete];
    });
    }
}

-(void)updateQueueWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSDictionary* valueDict = [BGTool getUpdateDictWithObject:object];
    NSString* tableName = NSStringFromClass([object class]);
    __block BOOL result = NO;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        result = isExist;
    }];
    
    if (!result){
        //如果不存在就返回NO
        !complete?:complete(NO);
    }else{
        __block BOOL success = NO;
        [self updateWithTableName:tableName valueDict:valueDict where:where complete:^(BOOL isSuccess) {
            success = isSuccess;
        }];
        if (success){
            !complete?:complete(success);
        }else{
            [self refreshQueueTable:tableName keys:[BGTool getClassIvarList:[object class] onlyKey:NO] complete:nil];
            [self updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
        }
    }

}

/**
 根据条件改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self updateQueueWithObject:object where:where complete:complete];
    });
    }
}

-(void)updateQueueWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    NSDictionary* valueDict = [BGTool getUpdateDictWithObject:object];
    NSString* tableName = NSStringFromClass([object class]);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf updateWithTableName:tableName forKeyPathAndValues:keyPathValues valueDict:valueDict complete:complete];
        }
    }];
}

/**
 根据keyPath改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self updateQueueWithObject:object forKeyPathAndValues:keyPathValues complete:complete];
    });
    }
}


/**
 根据条件改变对象的部分变量值.
 */
-(void)updateWithClass:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
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

-(void)deleteQueueWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
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
 根据条件删除对象表中的对象数据.
 */
-(void)deleteWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    @autoreleasepool {
    dispatch_sync(serialQueue, ^() {
        [self deleteQueueWithClass:cla where:where complete:complete];
    });
    }
}
/**
 根据类删除此类所有表数据.
 */
-(void)clearWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
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
 根据类,删除这个类的表.
 */
-(void)dropWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
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

-(void)copyQueueClass:(__unsafe_unretained _Nonnull Class)srcCla to:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete{
    NSAssert(srcCla,@"源类不能为空!");
    NSAssert(destCla,@"目标类不能为空!");
    NSString* srcTable = NSStringFromClass(srcCla);
    NSString* destTable = NSStringFromClass(destCla);
    NSAssert(![srcTable isEqualToString:destTable],@"不能将本类数据拷贝给自己!");
    NSArray* destKeys = keydict.allValues;
    NSArray* srcKeys = keydict.allKeys;
    //检测用户的key是否写对了,否则抛出异常
    NSArray* srcOnlyKeys = [BGTool getClassIvarList:srcCla onlyKey:YES];
    NSArray* destOnlyKeys = [BGTool getClassIvarList:destCla onlyKey:YES];
    for(int i=0;i<srcKeys.count;i++){
        if (![srcOnlyKeys containsObject:srcKeys[i]]){
            NSString* result = [NSString stringWithFormat:@"源类变量名称写错 = %@",srcKeys[i]];
            debug(result);
            @throw [NSException exceptionWithName:@"源类变量名称写错" reason:@"请检查keydict中的srcKey是否书写正确!" userInfo:nil];
        }else if(![destOnlyKeys containsObject:destKeys[i]]){
            NSString* result = [NSString stringWithFormat:@"目标类变量名称写错 = %@",destKeys[i]];
            debug(result);
            @throw [NSException exceptionWithName:@"目标类变量名称写错" reason:@"请检查keydict中的destKey字段是否书写正确!" userInfo:nil];
        }else;
    }
    [self isExistWithTableName:srcTable complete:^(BOOL isExist) {
        NSAssert(isExist,@"原类中还没有数据,不能复制");
    }];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:destTable complete:^(BOOL isExist) {
        if (!isExist){
            NSMutableArray* destKeyAndTypes = [NSMutableArray array];
            NSArray* destClassKeys = [BGTool getClassIvarList:destCla onlyKey:NO];
            for(NSString* destKey in destKeys){
                for(NSString* destClassKey in destClassKeys){
                    if ([destClassKey containsString:destKey]) {
                        [destKeyAndTypes addObject:destClassKey];
                    }
                }
            }
            //获取"唯一约束"字段名
            NSString* uniqueKey = [BGTool getUnique:[destCla new]];
            [BGSelf createTableWithTableName:destTable keys:destKeyAndTypes uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
                NSAssert(isSuccess,@"目标表创建失败,复制失败!");
            }];
        }else{
            if (!append){//覆盖模式,即将原数据删掉,拷贝新的数据过来
                [BGSelf clearTable:destTable complete:nil];
            }
        }
    }];
    __block dealState copystate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    NSInteger srcCount = [self countForTable:srcTable where:nil];
    for(NSInteger i=0;i<srcCount;i+=MaxQueryPageNum){
    @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
        NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
        [self queryWithTableName:srcTable param:param where:nil complete:^(NSArray * _Nullable array) {
            for(NSDictionary* srcDict in array){
                NSMutableDictionary* destDict = [NSMutableDictionary dictionary];
                for(int i=0;i<srcKeys.count;i++){
                    //字段名前加上 @"BG_"
                    NSString* destSqlKey = [NSString stringWithFormat:@"%@%@",BG,destKeys[i]];
                    NSString* srcSqlKey = [NSString stringWithFormat:@"%@%@",BG,srcKeys[i]];
                    destDict[destSqlKey] = srcDict[srcSqlKey];
                }
                [BGSelf insertIntoTableName:destTable Dict:destDict complete:^(BOOL isSuccess) {
                    if (isSuccess){
                        if (!recordSuccess) {
                            recordSuccess = YES;
                        }
                    }else{
                        if (!recordError) {
                            recordError = YES;
                        }
                    }
                }];
            }
        }];
    }
    }
    
    if (complete){
        if (recordError && recordSuccess) {
            copystate = Incomplete;
        }else if(recordError && !recordSuccess){
            copystate = Error;
        }else if (recordSuccess && !recordError){
            copystate = Complete;
        }else;
        complete(copystate);
    }

}

/**
 将某类表的数据拷贝给另一个类表
 */
-(void)copyClass:(__unsafe_unretained _Nonnull Class)srcCla to:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete{
    BGFMDB *currentSyncQueue = (__bridge id)dispatch_get_specific(BGFMDBDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
        dispatch_sync(serialQueue, ^(){
            //事务操作其过程.
            [self inTransaction:^BOOL{
                __block BOOL success = NO;
                [self copyQueueClass:srcCla to:destCla keyDict:keydict append:append complete:^(dealState result) {
                    if (result == Complete) {
                        success = YES;
                    }
                }];
                return success;
            }];
        });
}

@end
