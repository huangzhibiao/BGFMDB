//
//  BGFMDB.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//


#import "BGFMDB.h"

#define debug(param) if(self.debug){NSLog(@"调试输出: %@",param);}

@interface BGFMDB()

@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) FMDatabase* db;
@property (nonatomic, strong) NSRecursiveLock *threadLock;

@property (nonatomic,strong) NSMutableDictionary* changeBlocks;//记录注册监听数据变化的block.

@end

static BGFMDB* BGFmdb;

@implementation BGFMDB

-(void)dealloc{
    if (self.changeBlocks) {
        [self.changeBlocks removeAllObjects];
        self.changeBlocks = nil;
    }
    if (self.queue) {
        [self.queue close];//关闭数据库
        self.queue = nil;
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
        NSString* reason = @"注册名称name重复,注册监听失败!";
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
        NSString* reason = @"没有找到name对应的监听,移除监听失败!";
        debug(reason);
        return NO;
    }
}
-(void)doChange:(BOOL)flag state:(changeState)state{
    if(flag){
        for(id obj in _changeBlocks.allValues){
            void(^block)(changeState) = obj;
            !block?:block(state);
        }
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
                }else if ([[keys[i] componentsSeparatedByString:@"*"][0] isEqualToString:primaryKey]){
                    [sql appendFormat:@"%@ primary key autoincrement",[BGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[BGTool keyAndType:keys[i]]];
                }
            }else{
                if ([[keys[i] componentsSeparatedByString:@"*"][0] isEqualToString:primaryKey]){
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
    [self doChange:result state:Insert];
    if (complete) {
        complete(result);
    }
}
/**
 直接传入条件sql语句查询
 */
-(void)queryWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_A)complete{
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
    [self doChange:result state:Update];
    if (complete) {
        complete(result);
    }
}
/**
 直接传入条件sql语句更新.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nullable)valueDict conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete{
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
    [self doChange:result state:Update];
    if (complete) {
        complete(result);
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
    [self doChange:result state:Update];
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
    [self doChange:result state:Delete];
    if (complete){
        complete(result);
    }
}
/**
 直接传入条件sql语句删除.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name conditions:(NSString* _Nonnull)conditions complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(conditions||conditions.length,@"查询条件不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@ %@",name,conditions];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    
    //数据监听执行函数
    [self doChange:result state:Delete];
    if (complete){
        complete(result);
    }
}
//根据keypath删除表内容.
-(void)deleteWithTableName:(NSString* _Nonnull)name forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
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
    [self doChange:result state:Delete];
    if (complete){
        complete(result);
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
    [self doChange:result state:Delete];
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
    [self doChange:result state:Drop];
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
/**
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name keys:(NSArray<NSString*>* const _Nonnull)keys complete:(Complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    __block dealState refreshstate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    //先查询出旧表数据
    [self queryWithTableName:name keys:nil where:nil complete:^(NSArray * _Nullable array){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        //接着删掉旧表
        [BGSelf dropTable:name complete:^(BOOL isSuccess){
            __strong typeof(BGSelf) secondSelf = strongSelf;
            if (isSuccess){
                //获取"唯一约束"字段名
                NSString* uniqueKey = [BGTool getUnique:[NSClassFromString(name) new]];
                //创建新表
                [strongSelf createTableWithTableName:name keys:keys uniqueKey:uniqueKey complete:^(BOOL isSuccess){
                    if(isSuccess){
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
                            [secondSelf insertIntoTableName:name Dict:newDict complete:^(BOOL isSuccess){
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
                    }
                    
                }];
            }
        }];
    }];
    
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

-(void)refreshTable:(NSString* _Nonnull)name keyDict:(NSDictionary* const _Nonnull)keyDict complete:(Complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keyDict,@"变量名影射集合不能为空!");
    __block NSArray* keys = [BGTool getClassIvarList:NSClassFromString(name) onlyKey:YES];
    NSArray* newKeys = keyDict.allKeys;
    NSArray* oldKeys = keyDict.allValues;
    for(int i=0;i<newKeys.count;i++){
        if (![keys containsObject:newKeys[i]]){
            NSString* result = [NSString stringWithFormat:@"新变量出错名称 = %@",newKeys[i]];
            debug(result);
            @throw [NSException exceptionWithName:@"类新变量名称写错" reason:@"请检查keydict中的 新Key 是否书写正确!" userInfo:nil];
        }
    }
    __block dealState refreshstate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    //先查询出旧表数据
    [self queryWithTableName:name keys:nil where:nil complete:^(NSArray<NSDictionary*> * _Nullable array){
        NSArray* tableKeys = array.firstObject.allKeys;
        NSString* tableKey;
        for(int i=0;i<oldKeys.count;i++){
           tableKey = [NSString stringWithFormat:@"%@%@",BG,oldKeys[i]];
            if (![tableKeys containsObject:tableKey]){
                NSString* result = [NSString stringWithFormat:@"旧变量出错名称 = %@",oldKeys[i]];
                debug(result);
//                @throw [NSException exceptionWithName:@"类旧变量名称写错" reason:@"请检查keydict中的 旧Key 是否书写正确!" userInfo:nil];
            }
        }
        //重新获取类变量名和类型的数组
        keys = [BGTool getClassIvarList:NSClassFromString(name) onlyKey:NO];
        __strong typeof(BGSelf) strongSelf = BGSelf;
        //接着删掉旧表
        [BGSelf dropTable:name complete:^(BOOL isSuccess){
            __strong typeof(BGSelf) secondSelf = strongSelf;
            if (isSuccess){
                //获取"唯一约束"字段名
                NSString* uniqueKey = [BGTool getUnique:[NSClassFromString(name) new]];
                //创建新表
                [strongSelf createTableWithTableName:name keys:keys uniqueKey:uniqueKey complete:^(BOOL isSuccess){
                    if(isSuccess){
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
                            [secondSelf insertIntoTableName:name Dict:newDict complete:^(BOOL isSuccess){
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
                    }
                    
                }];
            }
        }];
    }];
    
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

//判断类的变量名是否变更,然后改变表字段结构.
-(void)changeTableWhenClassIvarChange:(__unsafe_unretained Class)cla{
    NSString* tableName = NSStringFromClass(cla);
    NSMutableArray* newKeys = [NSMutableArray array];
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSArray* keys = [BGTool getClassIvarList:cla onlyKey:NO];
        for (NSString* keyAndtype in keys){
            NSString* key = [[keyAndtype componentsSeparatedByString:@"*"] firstObject];
            key = [NSString stringWithFormat:@"%@%@",BG,key];
            if(![db columnExists:key inTableWithName:tableName]){
                [newKeys addObject:keyAndtype];
            }
        }
    }];
    
    //写在外面是为了防止数据库队列发生死锁.
    for(NSString* key in newKeys){
        //添加新字段
        [self addTable:tableName key:key complete:^(BOOL isSuccess){}];
    }
}

/**
 处理插入的字典数据并返回
 */
-(void)insertDictWithObject:(id)object complete:(Complete_B)complete{
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:object];
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    for(BGModelInfo* info in infos){
        dict[info.sqlColumnName] = info.sqlColumnValue;
    }
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    __weak typeof(self) BGSelf = self;
    [self insertIntoTableName:tableName Dict:dict complete:^(BOOL isSuccess){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (isSuccess) {
            if (complete) {
                complete(isSuccess);
            }
        }else{
            //检查表字段是否有改变
            [strongSelf changeTableWhenClassIvarChange:[object class]];
            [strongSelf insertIntoTableName:tableName Dict:dict complete:complete];
        }
    }];

}
/**
 存储一个对象.
 */
-(void)saveObject:(id _Nonnull)object complete:(Complete_B)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass([object class]);
    //获取"唯一约束"字段名
    NSString* uniqueKey = [BGTool getUnique:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就新建
            [strongSelf createTableWithTableName:tableName keys:[BGTool getClassIvarList:[object class] onlyKey:NO] uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
                if (isSuccess){
                    NSLog(@"建表成功 第一次建立 %@ 对应的表",tableName);
                }
            }];
        }
        
        //插入数据
        [strongSelf insertDictWithObject:object complete:complete];
    }];
}



/**
 查询对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nullable)where param:(NSString* _Nullable)param complete:(Complete_A)complete{
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
 根据条件查询对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete{
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

//根据keyPath查询对象
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete{
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
/**
 根据条件改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:object];
    NSMutableDictionary* valueDict = [NSMutableDictionary dictionary];
    for(BGModelInfo* info in infos){
        valueDict[info.sqlColumnName] = info.sqlColumnValue;
    }
    NSString* tableName = NSStringFromClass([object class]);
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
 根据keyPath改变对象数据.
 */
-(void)updateWithObject:(id _Nonnull)object forKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:object];
    NSMutableDictionary* valueDict = [NSMutableDictionary dictionary];
    for(BGModelInfo* info in infos){
        valueDict[info.sqlColumnName] = info.sqlColumnValue;
    }
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
/**
 根据条件删除对象表中的对象数据.
 */
-(void)deleteWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
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
/**
 将某类表的数据拷贝给另一个类表
 */
-(void)copyClass:(__unsafe_unretained _Nonnull Class)srcCla to:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete{
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
    [self queryWithTableName:srcTable keys:srcKeys where:nil complete:^(NSArray * _Nullable array) {
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

@end
