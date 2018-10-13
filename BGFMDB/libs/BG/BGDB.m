//
//  BGDB.m
//  BGFMDB
//
//  Created by biao on 2017/10/18.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "BGDB.h"
#import "BGTool.h"
#import "NSCache+BGCache.h"

/**
 默认数据库名称
 */
#define SQLITE_NAME @"BGFMDB.db"

#define bg_debug(param) do{\
if(self.debug){bg_log(@"调试输出: %@",param);}\
}while(0)

#define MaxQueryPageNum 50

#define CachePath(name) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:name]

static const void * const BGFMDBDispatchQueueSpecificKey = &BGFMDBDispatchQueueSpecificKey;

@interface BGDB()
/**
 数据库队列
 */
@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) FMDatabase* db;
@property (nonatomic, assign) BOOL inTransaction;
/**
 多线程池
 */
@property(nonatomic,strong)NSMutableArray* _Nullable mulThreadPool;
@property(nonatomic,strong)dispatch_queue_t mulThreadPoolQueue;
/**
 线程池执行状态标识
 */
@property(nonatomic,assign)BOOL threadPoolFlag;
/**
 递归锁.
 */
//@property (nonatomic, strong) NSRecursiveLock *threadLock;
/**
 记录注册监听数据变化的block.
 */
@property (nonatomic,strong) NSMutableDictionary* changeBlocks;
/**
 存放当队列处于忙时的事务block
 */
@property (nonatomic,strong) NSMutableArray* transactionBlocks;

@end

static BGDB* BGdb = nil;
@implementation BGDB

-(void)dealloc{
    //烧毁数据.
    [self destroy];
}


-(void)destroy{
    if (self.changeBlocks){
        [self.changeBlocks removeAllObjects];//清除所有注册列表.
        _changeBlocks = nil;
    }
    if (_semaphore) {
        _semaphore = 0x00;
    }
    [self closeDB];
    if (BGdb) {
        BGdb = nil;
    }
    
}
-(NSMutableArray *)mulThreadPool{
    if (_mulThreadPool == nil) {
        _mulThreadPool = [NSMutableArray array];
    }
    return _mulThreadPool;
}
-(dispatch_queue_t)mulThreadPoolQueue{
    if (_mulThreadPoolQueue == nil) {
        _mulThreadPoolQueue = dispatch_queue_create("BGFMDB.excuteThreadPool", DISPATCH_QUEUE_SERIAL);
    }
    return _mulThreadPoolQueue;
}
/**
 关闭数据库.
 */
-(void)closeDB{
    if(_disableCloseDB)return;//不关闭数据库
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if(!_inTransaction && _queue) {//没有事务的情况下就关闭数据库.
        [_queue close];//关闭数据库.
        _queue = nil;
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 删除数据库文件.
 */
+(BOOL)deleteSqlite:(NSString*)sqliteName{
    NSString* filePath = CachePath(([NSString stringWithFormat:@"%@.db",sqliteName]));
    NSFileManager * file_manager = [NSFileManager defaultManager];
    NSError* error;
    if ([file_manager fileExistsAtPath:filePath]) {
        [file_manager removeItemAtPath:filePath error:&error];
    }
    return error==nil;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        //创建递归锁.
        //self.threadLock = [[NSRecursiveLock alloc] init];
        //创建信号量.
        self.semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

-(FMDatabaseQueue *)queue{
    if(_queue)return _queue;
    //获得沙盒中的数据库文件名
    NSString* name;
    if(_sqliteName) {
        name = [NSString stringWithFormat:@"%@.db",_sqliteName];
    }else{
        name = SQLITE_NAME;
    }
    NSString *filename = CachePath(name);
    //NSLog(@"数据库路径 = %@",filename);
    _queue = [FMDatabaseQueue databaseQueueWithPath:filename];
    return _queue;
}

-(NSMutableDictionary *)changeBlocks{
    if (_changeBlocks == nil) {
        @synchronized(self){
            if(_changeBlocks == nil){
            _changeBlocks = [NSMutableDictionary dictionary];
            }
        }
    }
    return _changeBlocks;
}

-(NSMutableArray *)transactionBlocks{
    if (_transactionBlocks == nil){
        @synchronized(self){
            if(_transactionBlocks == nil){
            _transactionBlocks = [NSMutableArray array];
            }
        }
    }
    return _transactionBlocks;
}

/**
 获取单例函数.
 */
+(_Nonnull instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BGdb = [[BGDB alloc] init];
    });
    return BGdb;
}

/**
 添加操作到线程池
 */
-(void)addToThreadPool:(void (^_Nonnull)())block{
    NSAssert(block, @"block is nil!");
    dispatch_async(self.mulThreadPoolQueue, ^{
        NSString* key = [NSString stringWithFormat:@"b_%@_%@",@([[NSDate new] timeIntervalSince1970]),@(random())];
        NSDictionary* dict = @{key:block};
        [self.mulThreadPool addObject:dict];
        [self excuteThreadPool];
    });
}
/**
 执行线程池操作
 */
-(void)excuteThreadPool{
    if (!_threadPoolFlag) {
        _threadPoolFlag = YES;
            do{
                if(self.mulThreadPool.count>0){
                    NSDictionary* dict = self.mulThreadPool.firstObject;
                    NSString* key = [dict.allKeys firstObject];
                    void(^block)(void) = dict[key];
                    if(block){
                        block();
                    }
                    [self.mulThreadPool removeObjectAtIndex:0];//移除任务
                }
            }while(self.mulThreadPool.count>0);
        _threadPoolFlag = NO;
    }
}

//事务操作
-(void)inTransaction:(BOOL (^_Nonnull)())block{
    NSAssert(block, @"block is nil!");
    if([NSThread currentThread].isMainThread){//主线程直接执行
        [self executeTransation:block];
    }else{//子线程则延迟执行
        [self.transactionBlocks addObject:block];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self executeTransationBlocks];
        });
    }

}

/*
 执行事务操作
 */
-(void)executeTransation:(BOOL (^_Nonnull)())block{
    [self executeDB:^(FMDatabase * _Nonnull db) {
        _inTransaction = db.isInTransaction;
        if (!_inTransaction) {
            _inTransaction = [db beginTransaction];
        }
        BOOL isCommit = NO;
        isCommit = block();
        if (_inTransaction){
            if (isCommit) {
                [db commit];
            }else {
                [db rollback];
            }
            _inTransaction = NO;
        }
    }];
}

-(void)executeTransationBlocks{
   //[self.threadLock lock];
    @synchronized(self){
        if(_inTransaction || _queue){
            if(self.transactionBlocks.count) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self executeTransationBlocks];
                });
            }
            return;
        }

        while(self.transactionBlocks.count) {
            BOOL (^block)() = [self.transactionBlocks lastObject];
            [self executeTransation:block];
            [self.transactionBlocks removeLastObject];
        }
    }
    //[self.threadLock unlock];
}

/**
 为了对象层的事物操作而封装的函数.
 */
-(void)executeDB:(void (^_Nonnull)(FMDatabase *_Nonnull db))block{
    NSAssert(block, @"block is nil!");
    
        if (_db){//为了事务操作防止死锁而设置.
            block(_db);
            return;
        }
        __weak typeof(self) weakSelf = self;
        [self.queue inDatabase:^(FMDatabase *db){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.db = db;
            block(db);
            strongSelf.db = nil;
        }];
    
}

/**
 注册数据变化监听.
 */
-(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(bg_changeBlock)block{
    if ([self.changeBlocks.allKeys containsObject:name]){
        NSString* reason = [NSString stringWithFormat:@"%@表注册监听重复,注册监听失败!",name];
        bg_debug(reason);
        return NO;
    }else{
        [self.changeBlocks setObject:block forKey:name];
        return YES;
    }
}
/**
 移除数据变化监听.
 */
-(BOOL)removeChangeWithName:(NSString* const _Nonnull)name{
    if ([self.changeBlocks.allKeys containsObject:name]){
        [self.changeBlocks removeObjectForKey:name];
        return YES;
    }else{
        NSString* reason = [NSString stringWithFormat:@"%@表还没有注册监听,移除监听失败!",name];
        bg_debug(reason);
        return NO;
    }
}
-(void)doChangeWithName:(NSString* const _Nonnull)name flag:(BOOL)flag state:(bg_changeState)state{
    if(flag && self.changeBlocks.count>0){
        //开一个子线程去执行block,防止死锁.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
            [self.changeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
                NSString* tablename = [key componentsSeparatedByString:@"*"].firstObject;
                if([name isEqualToString:tablename]){
                    void(^block)(bg_changeState) = obj;
                    //返回主线程回调.
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        block(state);
                    });
                }
            }];
        });
    }
}

/**
 数据库中是否存在表.
 */
-(void)isExistWithTableName:(NSString* _Nonnull)name complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        result = [db tableExists:name];
    }];
    bg_completeBlock(result);
}
/**
 对用户暴露的
 */
-(BOOL)bg_isExistWithTableName:( NSString* _Nonnull)name{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        result = [db tableExists:name];
    }];
    dispatch_semaphore_signal(self.semaphore);
    return result;
}

/**
 创建表(如果存在则不创建).
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys unionPrimaryKeys:(NSArray* _Nullable)unionPrimaryKeys uniqueKeys:(NSArray* _Nullable)uniqueKeys complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    //创表
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* header = [NSString stringWithFormat:@"create table if not exists %@ (",name];
        NSMutableString* sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        NSInteger uniqueKeyFlag = uniqueKeys.count;
        NSMutableArray* tempUniqueKeys = [NSMutableArray arrayWithArray:uniqueKeys];
        for(int i=0;i<keys.count;i++){
            NSString* key = [keys[i] componentsSeparatedByString:@"*"][0];
            
            if(tempUniqueKeys.count && [tempUniqueKeys containsObject:key]){
                for(NSString* uniqueKey in tempUniqueKeys){
                    if([BGTool isUniqueKey:uniqueKey with:keys[i]]){
                        [sql appendFormat:@"%@ unique",[BGTool keyAndType:keys[i]]];
                        [tempUniqueKeys removeObject:uniqueKey];
                        uniqueKeyFlag--;
                        break;
                    }
                }
            }else{
                if ([key isEqualToString:bg_primaryKey] && !unionPrimaryKeys.count){
                    [sql appendFormat:@"%@ primary key autoincrement",[BGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[BGTool keyAndType:keys[i]]];
                }
            }
            
            if (i == (keys.count-1)) {
                if(unionPrimaryKeys.count){
                    [sql appendString:@",primary key ("];
                    [unionPrimaryKeys enumerateObjectsUsingBlock:^(id  _Nonnull unionKey, NSUInteger idx, BOOL * _Nonnull stop) {
                        if(idx == 0){
                            [sql appendString:bg_sqlKey(unionKey)];
                        }else{
                            [sql appendFormat:@",%@",bg_sqlKey(unionKey)];
                        }
                    }];
                    [sql appendString:@")"];
                }
                [sql appendString:@");"];
            }else{
                [sql appendString:@","];
            }
            
        }//for over
            
        if(uniqueKeys.count){
            NSAssert(!uniqueKeyFlag,@"没有找到设置的'唯一约束',请检查模型类.m文件的bg_uniqueKeys函数返回值是否正确!");
        }
        
        bg_debug(sql);
        result = [db executeUpdate:sql];
    }];
    
    bg_completeBlock(result);
}
-(NSInteger)getKeyMaxForTable:(NSString*)name key:(NSString*)key db:(FMDatabase*)db{
    __block NSInteger num = 0;
    [db executeStatements:[NSString stringWithFormat:@"select max(%@) from %@",key,name] withResultBlock:^int(NSDictionary *resultsDictionary){
        id dbResult = [resultsDictionary.allValues lastObject];
        if(dbResult && ![dbResult isKindOfClass:[NSNull class]]) {
            num = [dbResult integerValue];
        }
        return 0;
    }];
    return num;
}
/**
 插入数据.
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(dict,@"插入值字典不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSArray* keys = dict.allKeys;
        if([keys containsObject:bg_sqlKey(bg_primaryKey)]){
           NSInteger num = [self getKeyMaxForTable:name key:bg_sqlKey(bg_primaryKey) db:db];
           [dict setValue:@(num+1) forKey:bg_sqlKey(bg_primaryKey)];
        }
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
        
        bg_debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:values];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_insert];
    bg_completeBlock(result);
}
/**
 批量插入
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name DictArray:(NSArray<NSDictionary*>* _Nonnull)dictArray complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        [db beginTransaction];
        __block NSInteger counter = 0;
        [dictArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
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
                bg_debug(SQL);
                BOOL flag = [db executeUpdate:SQL withArgumentsInArray:values];
                if(flag){
                    counter++;
                }else{
                    *stop=YES;
                }
            }
        }];
        
        if(dictArray.count == counter){
            result = YES;
            [db commit];
        }else{
            result = NO;
            [db rollback];
        }
        
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_insert];
    bg_completeBlock(result);
}
/**
 批量更新
 over
 */
-(void)updateSetTableName:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla DictArray:(NSArray<NSDictionary*>* _Nonnull)dictArray complete:(bg_complete_B)complete{
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        [db beginTransaction];
        __block NSInteger counter = 0;
        [dictArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSArray* uniqueKeys = [BGTool executeSelector:bg_uniqueKeysSelector forClass:cla];
                NSMutableDictionary* tempDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                NSMutableString* where = [NSMutableString new];
                if(uniqueKeys.count > 1){
                    [where appendString:@" where"];
                    [uniqueKeys enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
                        NSString* uniqueKey = bg_sqlKey(obj);
                        id uniqueKeyVlaue = tempDict[uniqueKey];
                        if(idx < (uniqueKeys.count-1)){
                            [where appendFormat:@" %@=%@ or",uniqueKey,bg_sqlValue(uniqueKeyVlaue)];
                        }else{
                            [where appendFormat:@" %@=%@",uniqueKey,bg_sqlValue(uniqueKeyVlaue)];
                        }
                        [tempDict removeObjectForKey:uniqueKey];
                    }];
                }else if(uniqueKeys.count == 1){
                    NSString* uniqueKey = bg_sqlKey([uniqueKeys firstObject]);
                    id uniqueKeyVlaue = tempDict[uniqueKey];
                    [where appendFormat:@" where %@=%@",uniqueKey,bg_sqlValue(uniqueKeyVlaue)];
                    [tempDict removeObjectForKey:uniqueKey];
                }else if([dict.allKeys containsObject:bg_sqlKey(bg_primaryKey)]){
                    NSString* primaryKey = bg_sqlKey(bg_primaryKey);
                    id primaryKeyVlaue = tempDict[primaryKey];
                    [where appendFormat:@" where %@=%@",primaryKey,bg_sqlValue(primaryKeyVlaue)];
                    [tempDict removeObjectForKey:primaryKey];
                }else;
                
                NSMutableArray* arguments = [NSMutableArray array];
                NSMutableString* SQL = [[NSMutableString alloc] init];
                [SQL appendFormat:@"update %@ set ",name];
                [tempDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [SQL appendFormat:@"%@=?,",key];
                    [arguments addObject:obj];
                }];
                SQL = [NSMutableString stringWithString:[SQL substringToIndex:SQL.length-1]];
                if(where.length) {
                    [SQL appendString:where];
                }
                bg_debug(SQL);
                BOOL flag = [db executeUpdate:SQL withArgumentsInArray:arguments];
                if(flag){
                    counter++;
                }
            }
        }];
        
        if (dictArray.count == counter){
            result = YES;
            [db commit];
        }else{
            result = NO;
            [db rollback];
        }
        
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    bg_completeBlock(result);
}

/**
 批量插入或更新.
 */
-(void)bg_saveOrUpdateWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla DictArray:(NSArray<NSDictionary*>* _Nonnull)dictArray complete:(bg_complete_B)complete{
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        [db beginTransaction];
        __block NSInteger counter = 0;
        [dictArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString* bg_id = bg_sqlKey(bg_primaryKey);
                //获得"唯一约束"
                NSArray* uniqueKeys = [BGTool executeSelector:bg_uniqueKeysSelector forClass:cla];
                //获得"联合主键"
                NSArray* unionPrimaryKeys =[BGTool executeSelector:bg_unionPrimaryKeysSelector forClass:cla];
                NSMutableDictionary* tempDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                NSMutableString* where = [NSMutableString new];
                BOOL isSave = NO;//是否存储还是更新.
                if(uniqueKeys.count || unionPrimaryKeys.count){
                    NSArray* tempKeys;
                    NSString* orAnd;
                    
                    if(unionPrimaryKeys.count){
                        tempKeys = unionPrimaryKeys;
                        orAnd = @"and";
                    }else{
                        tempKeys = uniqueKeys;
                        orAnd = @"or";
                    }
                    
                    if(tempKeys.count == 1){
                        NSString* tempkey = bg_sqlKey([tempKeys firstObject]);
                        id tempkeyVlaue = tempDict[tempkey];
                        [where appendFormat:@" where %@=%@",tempkey,bg_sqlValue(tempkeyVlaue)];
                    }else{
                        [where appendString:@" where"];
                        [tempKeys enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
                            NSString* tempkey = bg_sqlKey(obj);
                            id tempkeyVlaue = tempDict[tempkey];
                            if(idx < (tempKeys.count-1)){
                                [where appendFormat:@" %@=%@ %@",tempkey,bg_sqlValue(tempkeyVlaue),orAnd];
                            }else{
                                [where appendFormat:@" %@=%@",tempkey,bg_sqlValue(tempkeyVlaue)];
                            }
                        }];
                    }
                    NSString* dataCountSql = [NSString stringWithFormat:@"select count(*) from %@%@",tablename,where];
                    __block NSInteger dataCount = 0;
                    [db executeStatements:dataCountSql withResultBlock:^int(NSDictionary *resultsDictionary) {
                        dataCount = [[resultsDictionary.allValues lastObject] integerValue];
                        return 0;
                    }];
                    bg_debug(dataCountSql);
                    if(dataCount){
                        //更新操作
                        [tempKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            [tempDict removeObjectForKey:bg_sqlKey(obj)];
                        }];
                    }else{
                        //插入操作
                        isSave = YES;
                    }
                }else{
                    if([tempDict.allKeys containsObject:bg_id]){
                        //更新操作
                        id primaryKeyVlaue = tempDict[bg_id];
                        [where appendFormat:@" where %@=%@",bg_id,bg_sqlValue(primaryKeyVlaue)];
                    }else{
                        //插入操作
                        isSave = YES;
                    }
                }
                
                NSMutableString* SQL = [[NSMutableString alloc] init];
                NSMutableArray* arguments = [NSMutableArray array];
                if(isSave){//存储操作
                    NSInteger num = [self getKeyMaxForTable:tablename key:bg_id db:db];
                    [tempDict setValue:@(num+1) forKey:bg_id];
                    [SQL appendFormat:@"insert into %@(",tablename];
                    NSArray* keys = tempDict.allKeys;
                    NSArray* values = tempDict.allValues;
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
                        [arguments addObject:values[i]];
                    }
                }else{//更新操作
                    if([tempDict.allKeys containsObject:bg_id]){
                        [tempDict removeObjectForKey:bg_id];//移除主键
                    }
                    [tempDict removeObjectForKey:bg_sqlKey(bg_createTimeKey)];//移除创建时间
                    [SQL appendFormat:@"update %@ set ",tablename];
                    [tempDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        [SQL appendFormat:@"%@=?,",key];
                        [arguments addObject:obj];
                    }];
                    SQL = [NSMutableString stringWithString:[SQL substringToIndex:SQL.length-1]];
                    if(where.length) {
                        [SQL appendString:where];
                    }
                }
                
                
                bg_debug(SQL);
                BOOL flag = [db executeUpdate:SQL withArgumentsInArray:arguments];
                if(flag){
                    counter++;
                }
            }
        }];
        
        if (dictArray.count == counter){
            result = YES;
            [db commit];
        }else{
            result = NO;
            [db rollback];
        }
        
    }];
    //数据监听执行函数
    [self doChangeWithName:tablename flag:result state:bg_update];
    bg_completeBlock(result);
}

-(void)queryQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(bg_complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    __block NSMutableArray* arrM = nil;
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL = conditions?[NSString stringWithFormat:@"select * from %@ %@",name,conditions]:[NSString stringWithFormat:@"select * from %@",name];
        bg_debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        if (rs == nil) {
            bg_debug(@"查询错误,可能是'类变量名'发生了改变或'字段','表格'不存在!,请存储后再读取!");
        }else{
            arrM = [[NSMutableArray alloc] init];
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    
    bg_completeBlock(arrM);
}

/**
 直接传入条件sql语句查询
 */
-(void)queryWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(bg_complete_A)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:conditions complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 根据条件查询字段.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(bg_complete_A)complete{
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
        
        if(where && (where.count>0)){
            NSArray* results = [BGTool where:where];
            [SQL appendString:results[0]];
            arguments = results[1];
        }
        
        bg_debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL withArgumentsInArray:arguments];
        if (rs == nil) {
            bg_debug(@"查询错误,可能是'类变量名'发生了改变或'字段','表格'不存在!,请存储后再读取,或检查条件数组'字段名称'是否正确");
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    
    bg_completeBlock(arrM);
}

/**
 查询对象.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name where:(NSString* _Nullable)where complete:(bg_complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [NSMutableString string];
        [SQL appendFormat:@"select * from %@",name];
        !where?:[SQL appendFormat:@" %@",where];
        bg_debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        if (rs == nil) {
            bg_debug(@"查询错误,'表格'不存在!,请存储后再读取!");
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    
    bg_completeBlock(arrM);
}

/**
 更新数据.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(bg_complete_B)complete{
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
        
        if(where && (where.count>0)){
            NSArray* results = [BGTool where:where];
            [SQL appendString:results[0]];
            [arguments addObjectsFromArray:results[1]];
        }
        
        bg_debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    bg_completeBlock(result);
}
-(void)updateQueueWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL;
        if (!valueDict || !valueDict.count) {
            SQL = [NSString stringWithFormat:@"update %@ %@",name,conditions];
        }else{
            NSMutableString* param = [NSMutableString stringWithFormat:@"update %@ set ",name];
            for(int i=0;i<valueDict.allKeys.count;i++){
                NSString* key = valueDict.allKeys[i];
                [param appendFormat:@"%@=?",key];
                if(i != (valueDict.allKeys.count-1)) {
                    [param appendString:@","];
                }
            }
            [param appendFormat:@" %@",conditions];
            SQL = param;
        }
        bg_debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:valueDict.allValues];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    bg_completeBlock(result);
}
/**
 直接传入条件sql语句更新.
 */
-(void)updateWithObject:(id _Nonnull)object valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:[BGTool executeSelector:bg_ignoreKeysSelector forClass:[object class]]];
        NSString* tablename = [BGTool getTableNameWithObject:object];
        [self updateQueueWithTableName:tablename valueDict:valueDict conditions:conditions complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 直接传入条件sql语句更新对象.
 */
-(void)updateObject:(id _Nonnull)object ignoreKeys:(NSArray* const _Nullable)ignoreKeys conditions:(NSString* _Nonnull)conditions complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSString* tableName = [BGTool getTableNameWithObject:object];
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:ignoreKeys];
        NSDictionary* valueDict = [BGTool getDictWithObject:self ignoredKeys:ignoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
        [self updateQueueWithTableName:tableName valueDict:valueDict conditions:conditions complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 根据keypath更新数据
 */
-(void)updateWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues valueDict:(NSDictionary* _Nonnull)valueDict complete:(bg_complete_B)complete{
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
        bg_debug(SQL);
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_update];
    bg_completeBlock(result);
}
/**
 根据条件删除数据.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(where,@"条件数组错误! 不能为空");
    __block BOOL result;
    NSMutableArray* arguments = [NSMutableArray array];
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@",name];
        
        if(where && (where.count>0)){
            NSArray* results = [BGTool where:where];
            [SQL appendString:results[0]];
            [arguments addObjectsFromArray:results[1]];
        }
        
        bg_debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    bg_completeBlock(result);
}

-(void)deleteQueueWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = conditions?[NSString stringWithFormat:@"delete from %@ %@",name,conditions]:[NSString stringWithFormat:@"delete from %@",name];
        bg_debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    bg_completeBlock(result);
}

/**
 直接传入条件sql语句删除.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self deleteQueueWithTableName:name conditions:conditions complete:complete];
    dispatch_semaphore_signal(self.semaphore);
}

-(void)deleteQueueWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSString* like = [BGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@%@",name,like];
        bg_debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    bg_completeBlock(result);
}

//根据keypath删除表内容.
-(void)deleteWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self deleteQueueWithTableName:name forKeyPathAndValues:keyPathValues complete:complete];
    dispatch_semaphore_signal(self.semaphore);
}
/**
 根据表名删除表格全部内容.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@",name];
        bg_debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_delete];
    bg_completeBlock(result);
}

/**
 删除表.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"drop table %@",name];
        bg_debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:bg_drop];
    bg_completeBlock(result);
}

/**
 删除表(线程安全).
 */
-(void)dropSafeTable:(NSString* _Nonnull)name complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self dropTable:name complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 动态添加表字段.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(bg_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"alter table %@ add %@;",name,[BGTool keyAndType:key]];
        bg_debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    bg_completeBlock(result);
}
/**
 查询该表中有多少条数据
 */
-(NSInteger)countQueueForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where{
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
        bg_debug(SQL);
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] integerValue];
            return 0;
        }];
    }];
    return count;
}
/**
 查询该表中有多少条数据
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSInteger count = 0;
    @autoreleasepool {
        count = [self countQueueForTable:name where:where];
    }
    dispatch_semaphore_signal(self.semaphore);
    return count;
}
/**
 直接传入条件sql语句查询数据条数.
 */
-(NSInteger)countQueueForTable:(NSString* _Nonnull)name conditions:(NSString* _Nullable)conditions{
    NSAssert(name,@"表名不能为空!");
    __block NSUInteger count=0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = conditions?[NSString stringWithFormat:@"select count(*) from %@ %@",name,conditions]:[NSString stringWithFormat:@"select count(*) from %@",name];
        bg_debug(SQL);
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
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSInteger count = 0;
    @autoreleasepool {
        count = [self countQueueForTable:name conditions:conditions];
    }
    dispatch_semaphore_signal(self.semaphore);
    return count;
}
/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 */
-(double)sqliteMethodQueueForTable:(NSString* _Nonnull)name type:(bg_sqliteMethodType)methodType key:(NSString*)key where:(NSString* _Nullable)where{
    NSAssert(name,@"表名不能为空!");
    NSAssert(key,@"属性名不能为空!");
    __block double num = 0.0;
    NSString* method;
    switch (methodType) {
        case bg_min:
            method = [NSString stringWithFormat:@"min(%@%@)",BG,key];
            break;
        case bg_max:
            method = [NSString stringWithFormat:@"max(%@%@)",BG,key];
            break;
        case bg_sum:
            method = [NSString stringWithFormat:@"sum(%@%@)",BG,key];
            break;
        case bg_avg:
            method = [NSString stringWithFormat:@"avg(%@%@)",BG,key];
            break;
        default:
            NSAssert(NO,@"请传入方法类型!");
            break;
    }
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL;
        if(where){
            SQL = [NSString stringWithFormat:@"select %@ from %@ %@",method,name,where];
        }else{
            SQL = [NSString stringWithFormat:@"select %@ from %@",method,name];
        }
        bg_debug(SQL);
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary){
            id dbResult = [resultsDictionary.allValues lastObject];
            if(dbResult && ![dbResult isKindOfClass:[NSNull class]]) {
                num = [dbResult doubleValue];
            }
            return 0;
        }];
    }];
    return num;
}

/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 */
-(double)sqliteMethodForTable:(NSString* _Nonnull)name type:(bg_sqliteMethodType)methodType key:(NSString*)key where:(NSString* _Nullable)where{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    double num = 0.0;
    @autoreleasepool {
        num = [self sqliteMethodQueueForTable:name type:methodType key:key where:where];
    }
    dispatch_semaphore_signal(self.semaphore);
    return num;
}

/**
 keyPath查询数据条数.
 */
-(NSInteger)countQueueForTable:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    NSString* like = [BGTool getLikeWithKeyPathAndValues:keyPathValues where:YES];
    __block NSUInteger count=0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"select count(*) from %@%@",name,like];
        bg_debug(SQL);
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
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSInteger count = 0;
    @autoreleasepool {
        count = [self countQueueForTable:name forKeyPathAndValues:keyPathValues];
    }
    dispatch_semaphore_signal(self.semaphore);
    return count;
}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(bg_complete_I)complete{
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [BGTool executeSelector:bg_uniqueKeysSelector forClass:cla];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [BGTool executeSelector:bg_unionPrimaryKeysSelector forClass:cla];
    //建立一张临时表
    __block BOOL createFlag;
    [self createTableWithTableName:B keys:keys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        bg_debug(@"数据库更新失败!");
        bg_completeBlock(bg_error);
        return;
    }
    __block bg_dealState refreshstate = bg_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    NSInteger count = [self countQueueForTable:A where:nil];
    for(NSInteger i=0;i<count;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:A where:param complete:^(NSArray * _Nullable array) {
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
            refreshstate = bg_incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = bg_error;
        }else if (recordSuccess && !recordError){
            refreshstate = bg_complete;
        }else;
        complete(refreshstate);
    }
    
}

-(void)refreshQueueTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(bg_complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    [self isExistWithTableName:name complete:^(BOOL isSuccess){
        if (!isSuccess){
            bg_debug(@"没有数据存在,数据库更新失败!");
            bg_completeBlock(bg_error);
            return;
        }
    }];
    NSString* BGTempTable = @"BGTempTable";
    //事务操作.
    __block int recordFailCount = 0;
    [self executeTransation:^BOOL{
        [self copyA:name toB:BGTempTable class:cla keys:keys complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:name complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:name class:cla keys:keys complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if(recordFailCount != 4){
            bg_debug(@"发生错误，更新数据库失败!");
        }
        return recordFailCount==4;
    }];
    
    //回调结果.
    if (recordFailCount==0) {
        bg_completeBlock(bg_error);
    }else if (recordFailCount>0&&recordFailCount<4){
        bg_completeBlock(bg_incomplete);
    }else{
        bg_completeBlock(bg_complete);
    }
}

/**
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(bg_complete_I)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self refreshQueueTable:name class:cla keys:keys complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B keyDict:(NSDictionary* const _Nullable)keyDict complete:(bg_complete_I)complete{
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [BGTool executeSelector:bg_uniqueKeysSelector forClass:NSClassFromString(A)];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [BGTool executeSelector:bg_unionPrimaryKeysSelector forClass:NSClassFromString(A)];
    __block NSArray* keys = [BGTool getClassIvarList:NSClassFromString(A) Object:nil onlyKey:NO];
    NSArray* newKeys = keyDict.allKeys;
    NSArray* oldKeys = keyDict.allValues;
    //建立一张临时表
    __block BOOL createFlag;
    [self createTableWithTableName:B keys:keys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        bg_debug(@"数据库更新失败!");
        bg_completeBlock(bg_error);
        return;
    }
    
    __block bg_dealState refreshstate = bg_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    NSInteger count = [self countQueueForTable:A where:nil];
    for(NSInteger i=0;i<count;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:A where:param complete:^(NSArray * _Nullable array) {
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
            refreshstate = bg_incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = bg_error;
        }else if (recordSuccess && !recordError){
            refreshstate = bg_complete;
        }else;
        complete(refreshstate);
    }
    
    
}

-(void)refreshQueueTable:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* const _Nonnull)keys keyDict:(NSDictionary* const _Nonnull)keyDict complete:(bg_complete_I)complete{
    NSAssert(tablename,@"表名不能为空!");
    NSAssert(keyDict,@"变量名影射集合不能为空!");
    [self isExistWithTableName:tablename complete:^(BOOL isSuccess){
        if (!isSuccess){
            bg_debug(@"没有数据存在,数据库更新失败!");
            bg_completeBlock(bg_error);
            return;
        }
    }];
    
    //事务操作.
    NSString* BGTempTable = @"BGTempTable";
    __block int recordFailCount = 0;
    [self executeTransation:^BOOL{
        [self copyA:tablename toB:BGTempTable keyDict:keyDict complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:tablename complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:tablename class:cla keys:keys complete:^(bg_dealState result) {
            if(result == bg_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if (recordFailCount != 4) {
            bg_debug(@"发生错误，更新数据库失败!");
        }
        return recordFailCount==4;
    }];
    
    //回调结果.
    if(recordFailCount==0){
        bg_completeBlock(bg_error);
    }else if (recordFailCount>0&&recordFailCount<4){
        bg_completeBlock(bg_incomplete);
    }else{
        bg_completeBlock(bg_complete);
    }
    
}

-(void)refreshTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* const _Nonnull)keys keyDict:(NSDictionary* const _Nonnull)keyDict complete:(bg_complete_I)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self refreshQueueTable:name class:cla keys:keys keyDict:keyDict complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 判断类属性是否有改变,智能刷新.
 */
-(void)ifIvarChangeForObject:(id)object ignoredKeys:(NSArray*)ignoredkeys{
    //获取缓存的属性信息
    NSCache* cache = [NSCache bg_cache];
    NSString *tableName = [object valueForKey:bg_tableNameKey];
    tableName = tableName.length ? tableName : NSStringFromClass([object class]);
    NSString* cacheKey = [NSString stringWithFormat:@"%@_IvarChangeState",tableName];
    id IvarChangeState = [cache objectForKey:cacheKey];
    if(IvarChangeState){
        return;
    }else{
        [cache setObject:@(YES) forKey:cacheKey];
    }
    
    @autoreleasepool {
        //获取表名
        NSString* tableName = [BGTool getTableNameWithObject:object];
        NSMutableArray* newKeys = [NSMutableArray array];
        NSMutableArray* sqlKeys = [NSMutableArray array];
        [self executeDB:^(FMDatabase * _Nonnull db) {
                NSString* SQL = [NSString stringWithFormat:@"select sql from sqlite_master where tbl_name='%@' and type='table';",tableName];
                NSMutableArray* tempArrayM = [NSMutableArray array];
                //获取表格所有列名.
                [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
                    NSString* allName = [resultsDictionary.allValues lastObject];
                    allName = [allName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    NSRange range1 = [allName rangeOfString:@"("];
                    allName = [allName substringFromIndex:range1.location+1];
                    NSRange range2 = [allName rangeOfString:@")"];
                    allName = [allName substringToIndex:range2.location];
                    NSArray* sqlNames = [allName componentsSeparatedByString:@","];
                    
                    for(NSString* sqlName in sqlNames){
                        NSString* columnName = [[sqlName componentsSeparatedByString:@" "] firstObject];
                        [tempArrayM addObject:columnName];
                    }
                    return 0;
                }];
                NSArray* columNames = tempArrayM.count?tempArrayM:nil;
                NSArray* keyAndtypes = [BGTool getClassIvarList:[object class] Object:object onlyKey:NO];
                for(NSString* keyAndtype in keyAndtypes){
                    NSString* key = [[keyAndtype componentsSeparatedByString:@"*"] firstObject];
                    if(ignoredkeys && [ignoredkeys containsObject:key])continue;
                    
                    key = [NSString stringWithFormat:@"%@%@",BG,key];
                    if (![columNames containsObject:key]) {
                        [newKeys addObject:keyAndtype];
                    }
                }
                
                NSMutableArray* keys = [NSMutableArray arrayWithArray:[BGTool getClassIvarList:[object class] Object:nil onlyKey:YES]];
                if (ignoredkeys) {
                    [keys removeObjectsInArray:ignoredkeys];
                }
                [columNames enumerateObjectsUsingBlock:^(NSString* _Nonnull columName, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString* propertyName = [columName stringByReplacingOccurrencesOfString:BG withString:@""];
                    if(![keys containsObject:propertyName]){
                        [sqlKeys addObject:columName];
                    }
                }];
            
        }];
        
        if((sqlKeys.count==0) && (newKeys.count>0)){
            //此处只是增加了新的列.
            for(NSString* key in newKeys){
                //添加新字段
                [self addTable:tableName key:key complete:^(BOOL isSuccess){}];
            }
        }else if(sqlKeys.count>0){
            //字段发生改变,减少或名称变化,实行刷新数据库.
            NSMutableArray* newTableKeys = [[NSMutableArray alloc] initWithArray:[BGTool getClassIvarList:[object class] Object:nil onlyKey:NO]];
            NSMutableArray* tempIgnoreKeys = [[NSMutableArray alloc] initWithArray:ignoredkeys];
            for(int i=0;i<newTableKeys.count;i++){
                NSString* key = [[newTableKeys[i] componentsSeparatedByString:@"*"] firstObject];
                if([tempIgnoreKeys containsObject:key]) {
                    [newTableKeys removeObject:newTableKeys[i]];
                    [tempIgnoreKeys removeObject:key];
                    i--;
                }
                if(tempIgnoreKeys.count == 0){
                    break;
                }
            }
            [self refreshQueueTable:tableName class:[object class] keys:newTableKeys complete:nil];
        }else;
    }
}


/**
 处理插入的字典数据并返回
 */
-(void)insertWithObject:(id)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    NSDictionary* dictM = [BGTool getDictWithObject:object ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoInsert];
    //自动判断是否有字段改变,自动刷新数据库.
    [self ifIvarChangeForObject:object ignoredKeys:ignoredKeys];
    NSString* tableName = [BGTool getTableNameWithObject:object];
    [self insertIntoTableName:tableName Dict:dictM complete:complete];
    
}

-(NSArray*)getArray:(NSArray*)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys filtModelInfoType:(bg_getModelInfoType)filtModelInfoType{
    NSMutableArray* dictArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary* dict = [BGTool getDictWithObject:object ignoredKeys:ignoredKeys filtModelInfoType:filtModelInfoType];
        [dictArray addObject:dict];
    }];
    return dictArray;
}

/**
 批量插入数据
 */
-(void)insertWithObjects:(NSArray*)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    NSArray* dictArray = [self getArray:array ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoInsert];
    //自动判断是否有字段改变,自动刷新数据库.
    [self ifIvarChangeForObject:array.firstObject ignoredKeys:ignoredKeys];
    NSString* tableName = [BGTool getTableNameWithObject:array.firstObject];
    [self insertIntoTableName:tableName DictArray:dictArray complete:complete];
}
/**
 批量更新数据.
 over
 */
-(void)updateSetWithObjects:(NSArray*)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    NSArray* dictArray = [self getArray:array ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoArrayUpdate];
    NSString* tableName = [BGTool getTableNameWithObject:array.firstObject];
    [self updateSetTableName:tableName class:[array.firstObject class] DictArray:dictArray complete:complete];
}

/**
 批量存储.
 */
-(void)saveObjects:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [BGTool ifNotExistWillCreateTableWithObject:array.firstObject ignoredKeys:ignoredKeys];
        [self insertWithObjects:array ignoredKeys:ignoredKeys complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 批量更新.
 over
 */
-(void)updateObjects:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self updateSetWithObjects:array ignoredKeys:ignoredKeys complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 批量插入或更新.
 */
-(void)bg_saveOrUpateArray:(NSArray* _Nonnull)array ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        //判断是否建表.
        [BGTool ifNotExistWillCreateTableWithObject:array.firstObject ignoredKeys:ignoredKeys];
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:array.firstObject ignoredKeys:ignoredKeys];
        //转换模型数据
        NSArray* dictArray = [self getArray:array ignoredKeys:ignoredKeys filtModelInfoType:bg_ModelInfoNone];
        //获取自定义表名
        NSString* tableName = [BGTool getTableNameWithObject:array.firstObject];
        [self bg_saveOrUpdateWithTableName:tableName class:[array.firstObject class] DictArray:dictArray complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 存储一个对象.
 */
-(void)saveObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [BGTool ifNotExistWillCreateTableWithObject:object ignoredKeys:ignoredKeys];
        [self insertWithObject:object ignoredKeys:ignoredKeys complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

-(void)queryObjectQueueWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla where:(NSString* _Nullable)where complete:(bg_complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tablename complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            bg_completeBlock(nil);
        }else{
            [strongSelf queryWithTableName:tablename where:where complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tablename class:cla array:array];
                bg_completeBlock(resultArray);
            }];
        }
    }];
}
/**
 查询对象.
 */
-(void)queryObjectWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla where:(NSString* _Nullable)where complete:(bg_complete_A)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self queryObjectQueueWithTableName:tablename class:cla where:where complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

-(void)updateQueueWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete{
    NSDictionary* valueDict = [BGTool getDictWithObject:object ignoredKeys:ignoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
    NSString* tableName = [BGTool getTableNameWithObject:object];
    __block BOOL result = NO;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        result = isExist;
    }];
    
    if (!result){
        //如果不存在就返回NO
        bg_completeBlock(NO);
    }else{
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:ignoreKeys];
        [self updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
    }
    
}

/**
 根据条件改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self updateQueueWithObject:object where:where ignoreKeys:ignoreKeys complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

-(void)updateQueueWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete{
    NSDictionary* valueDict = [BGTool getDictWithObject:object ignoredKeys:ignoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
    NSString* tableName = [BGTool getTableNameWithObject:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            bg_completeBlock(NO);
        }else{
            [strongSelf updateWithTableName:tableName forKeyPathAndValues:keyPathValues valueDict:valueDict complete:complete];
        }
    }];
}

/**
 根据keyPath改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        //自动判断是否有字段改变,自动刷新数据库.
        [self ifIvarChangeForObject:object ignoredKeys:ignoreKeys];
        [self updateQueueWithObject:object forKeyPathAndValues:keyPathValues ignoreKeys:ignoreKeys complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 根据类删除此类所有表数据.
 */
-(void)clearWithObject:(id _Nonnull)object complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    NSString* tableName = [BGTool getTableNameWithObject:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就相当于清空,返回YES
            bg_completeBlock(YES);
        }else{
            [strongSelf clearTable:tableName complete:complete];
        }
    }];
    
    dispatch_semaphore_signal(self.semaphore);
}
/**
 根据类,删除这个类的表.
 */
-(void)dropWithTableName:(NSString* _Nonnull)tablename complete:(bg_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tablename complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            bg_completeBlock(NO);
        }else{
            [strongSelf dropTable:tablename complete:complete];
        }
    }];
    
    dispatch_semaphore_signal(self.semaphore);
}

-(void)copyQueueTable:(NSString* _Nonnull)srcTable to:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(bg_complete_I)complete{
    NSAssert(![srcTable isEqualToString:destTable],@"不能将本表数据拷贝给自己!");
    NSArray* destKeys = keydict.allValues;
    NSArray* srcKeys = keydict.allKeys;
    [self isExistWithTableName:srcTable complete:^(BOOL isExist) {
        NSAssert(isExist,@"原表中还没有数据,复制失败!");
    }];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:destTable complete:^(BOOL isExist) {
        if(!isExist){
            NSAssert(NO,@"目标表不存在,复制失败!");
        }else{
            if (!append){//覆盖模式,即将原数据删掉,拷贝新的数据过来
                [BGSelf clearTable:destTable complete:nil];
            }
        }
    }];
    __block bg_dealState copystate = bg_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    NSInteger srcCount = [self countQueueForTable:srcTable where:nil];
    for(NSInteger i=0;i<srcCount;i+=MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryWithTableName:srcTable where:param complete:^(NSArray * _Nullable array) {
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
            copystate = bg_incomplete;
        }else if(recordError && !recordSuccess){
            copystate = bg_error;
        }else if (recordSuccess && !recordError){
            copystate = bg_complete;
        }else;
        complete(copystate);
    }
    
}

/**
 将某表的数据拷贝给另一个表
 */
-(void)copyTable:(NSString* _Nonnull)srcTable to:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(bg_complete_I)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self copyQueueTable:srcTable to:destTable keyDict:keydict append:append complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 直接执行sql语句.
 @tablename 要操作的表名.
 @cla 要操作的类.
 */
-(id _Nullable)bg_executeSql:(NSString* const _Nonnull)sql tablename:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla{
    NSAssert(sql,@"sql语句不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block id result;
    [self executeDB:^(FMDatabase * _Nonnull db){
        if([[sql lowercaseString] hasPrefix:@"select"]){
            // 1.查询数据
            FMResultSet *rs = [db executeQuery:sql];
            if (rs == nil) {
                bg_debug(@"查询错误,数据不存在,请存储后再读取!");
                result = nil;
            }else{
                result = [NSMutableArray array];
            }
            result = [NSMutableArray array];
            // 2.遍历结果集
            while (rs.next) {
                NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
                for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                    dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
                }
                [result addObject:dictM];
            }
            //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
            [rs close];
            //转换结果
            result = [BGTool tansformDataFromSqlDataWithTableName:tablename class:cla array:result];
        }else{
            result = @([db executeUpdate:sql]);
        }
        bg_debug(sql);
    }];
    dispatch_semaphore_signal(self.semaphore);
    return result;
}
#pragma mark 存储数组.

/**
 直接存储数组.
 */
-(void)saveArray:(NSArray* _Nonnull)array name:(NSString*)name complete:(bg_complete_B)complete{
    NSAssert(array&&array.count,@"数组不能为空!");
    NSAssert(name,@"唯一标识名不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        __weak typeof(self) BGSelf = self;
        [self isExistWithTableName:name complete:^(BOOL isSuccess) {
            if (!isSuccess) {
                [BGSelf createTableWithTableName:name keys:@[[NSString stringWithFormat:@"%@*i",bg_primaryKey],@"param*@\"NSString\"",@"index*i"] unionPrimaryKeys:nil uniqueKeys:nil complete:nil];
            }
        }];
        __block NSInteger sqlCount = [self countQueueForTable:name where:nil];
        
        __block NSInteger num = 0;
        [self executeTransation:^BOOL{
            for(id value in array){
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [BGTool getSqlValue:value type:type encode:YES];
                sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
                NSDictionary* dict = @{@"BG_param":sqlValue,@"BG_index":@(sqlCount++)};
                [self insertIntoTableName:name Dict:dict complete:^(BOOL isSuccess) {
                    if(isSuccess) {
                        num++;
                    }
                }];
            }
            return YES;
        }];
        bg_completeBlock(array.count==num);
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 读取数组.
 */
-(void)queryArrayWithName:(NSString*)name complete:(bg_complete_A)complete{
    NSAssert(name,@"唯一标识名不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSString* condition = [NSString stringWithFormat:@"order by %@ asc",bg_sqlKey(bg_primaryKey)];
        [self queryQueueWithTableName:name conditions:condition complete:^(NSArray * _Nullable array) {
            NSMutableArray* resultM = nil;
            if(array&&array.count){
                resultM = [NSMutableArray array];
                for(NSDictionary* dict in array){
                    NSArray* keyAndTypes = [dict[@"BG_param"] componentsSeparatedByString:@"$$$"];
                    id value = [keyAndTypes firstObject];
                    NSString* type = [keyAndTypes lastObject];
                    value = [BGTool getSqlValue:value type:type encode:NO];
                    [resultM addObject:value];
                }
            }
            bg_completeBlock(resultM);
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 读取数组某个元素.
 */
-(id _Nullable)queryArrayWithName:(NSString* _Nonnull)name index:(NSInteger)index{
    NSAssert(name,@"唯一标识名不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block id resultValue = nil;
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:[NSString stringWithFormat:@"where BG_index=%@",@(index)] complete:^(NSArray * _Nullable array){
            if(array&&array.count){
                NSDictionary* dict = [array firstObject];
                NSArray* keyAndTypes = [dict[@"BG_param"] componentsSeparatedByString:@"$$$"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                resultValue = [BGTool getSqlValue:value type:type encode:NO];
            }
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
    return resultValue;
}
/**
 更新数组某个元素.
 */
-(BOOL)updateObjectWithName:(NSString* _Nonnull)name object:(id _Nonnull)object index:(NSInteger)index{
    NSAssert(name,@"唯一标识名不能为空!");
    NSAssert(object,@"元素不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([object class])];
        id sqlValue = [BGTool getSqlValue:object type:type encode:YES];
        sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
        NSDictionary* dict = @{@"BG_param":sqlValue};
        [self updateWithTableName:name valueDict:dict where:@[@"index",@"=",@(index)] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
    return result;
}
/**
 删除数组某个元素.
 */
-(BOOL)deleteObjectWithName:(NSString* _Nonnull)name index:(NSInteger)index{
    NSAssert(name,@"唯一标识名不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block NSInteger flag = 0;
    @autoreleasepool {
        [self executeTransation:^BOOL{
            [self deleteQueueWithTableName:name conditions:[NSString stringWithFormat:@"where BG_index=%@",@(index)] complete:^(BOOL isSuccess) {
                if(isSuccess) {
                    flag++;
                }
            }];
            if(flag){
                [self updateQueueWithTableName:name valueDict:nil conditions:[NSString stringWithFormat:@"set BG_index=BG_index-1 where BG_index>%@",@(index)] complete:^(BOOL isSuccess) {
                    if(isSuccess) {
                        flag++;
                    }
                }];
            }
            return flag==2;
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
    return flag==2;
}
#pragma mark 存储字典.
/**
 直接存储字典.
 */
-(void)saveDictionary:(NSDictionary* _Nonnull)dictionary complete:(bg_complete_B)complete{
    NSAssert(dictionary||dictionary.allKeys.count,@"字典不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        __weak typeof(self) BGSelf = self;
        NSString* const tableName = @"BG_Dictionary";
        [self isExistWithTableName:tableName complete:^(BOOL isSuccess) {
            if (!isSuccess) {
                [BGSelf createTableWithTableName:tableName keys:@[[NSString stringWithFormat:@"%@*i",bg_primaryKey],@"key*@\"NSString\"",@"value*@\"NSString\""] unionPrimaryKeys:nil uniqueKeys:@[@"key"] complete:nil];
            }
        }];
        __block NSInteger num = 0;
        [self executeTransation:^BOOL{
            [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop){
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [BGTool getSqlValue:value type:type encode:YES];
                sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
                NSDictionary* dict = @{@"BG_key":key,@"BG_value":sqlValue};
                [self insertIntoTableName:tableName Dict:dict complete:^(BOOL isSuccess) {
                    if(isSuccess) {
                        num++;
                    }
                }];
            }];
            return YES;
        }];
        bg_completeBlock(dictionary.allKeys.count==num);
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 添加字典元素.
 */
-(BOOL)bg_setValue:(id _Nonnull)value forKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key不能为空!");
    NSAssert(value,@"value不能为空!");
    NSDictionary* dict = @{key:value};
    __block BOOL result;
    [self saveDictionary:dict complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 更新字典元素.
 */
-(BOOL)bg_updateValue:(id _Nonnull)value forKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key不能为空!");
    NSAssert(value,@"value不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
        id sqlvalue = [BGTool getSqlValue:value type:type encode:YES];
        sqlvalue = [NSString stringWithFormat:@"%@$$$%@",sqlvalue,type];
        NSDictionary* dict = @{@"BG_value":sqlvalue};
        NSString* const tableName = @"BG_Dictionary";
        [self updateWithTableName:tableName valueDict:dict where:@[@"key",@"=",key] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
    return result;
}
/**
 遍历字典元素.
 */
-(void)bg_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool{
        NSString* const tableName = @"BG_Dictionary";
        NSString* condition = [NSString stringWithFormat:@"order by %@ asc",bg_sqlKey(bg_primaryKey)];
        [self queryQueueWithTableName:tableName conditions:condition complete:^(NSArray * _Nullable array) {
            BOOL stopFlag = NO;
            for(NSDictionary* dict in array){
                NSArray* keyAndTypes = [dict[@"BG_value"] componentsSeparatedByString:@"$$$"];
                NSString* key = dict[@"BG_key"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                value = [BGTool getSqlValue:value type:type encode:NO];
                !block?:block(key,value,&stopFlag);
                if(stopFlag){
                    break;
                }
            }
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
}
/**
 获取字典元素.
 */
-(id _Nullable)bg_valueForKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block id resultValue = nil;
    @autoreleasepool {
        NSString* const tableName = @"BG_Dictionary";
        [self queryQueueWithTableName:tableName conditions:[NSString stringWithFormat:@"where BG_key='%@'",key] complete:^(NSArray * _Nullable array){
            if(array&&array.count){
                NSDictionary* dict = [array firstObject];
                NSArray* keyAndTypes = [dict[@"BG_value"] componentsSeparatedByString:@"$$$"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                resultValue = [BGTool getSqlValue:value type:type encode:NO];
            }
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
    return resultValue;
}
/**
 删除字典元素.
 */
-(BOOL)bg_deleteValueForKey:(NSString* const _Nonnull)key{
    NSAssert(key,@"key不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool {
        NSString* const tableName = @"BG_Dictionary";
        [self deleteQueueWithTableName:tableName conditions:[NSString stringWithFormat:@"where BG_key='%@'",key] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
    return result;
}

@end
