//
//  NSObject+BGModel.m
//  BGDB
//
//  Created by huangzhibiao on 17/2/28.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "NSObject+BGModel.h"
#import "BGDB.h"
#import "BGTool.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>

#define bg_getIgnoreKeys [BGTool executeSelector:bg_ignoreKeysSelector forClass:[self class]]

@implementation NSObject (BGModel)

//分类中只生成属性get,set函数的声明,没有声称其实现,所以要自己实现get,set函数.
-(NSNumber *)bg_id{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setBg_id:(NSNumber *)bg_id{
    objc_setAssociatedObject(self,@selector(bg_id),bg_id,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSString *)bg_createTime{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setBg_createTime:(NSString *)bg_createTime{
    objc_setAssociatedObject(self,@selector(bg_createTime),bg_createTime,OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(NSString *)bg_updateTime{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setBg_updateTime:(NSString *)bg_updateTime{
    objc_setAssociatedObject(self,@selector(bg_updateTime),bg_updateTime,OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(NSString *)bg_tableName{
    return objc_getAssociatedObject(self, _cmd);
}
-(void)setBg_tableName:(NSString *)bg_tableName{
    objc_setAssociatedObject(self,@selector(bg_tableName),bg_tableName,OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/**
 @tablename 此参数为nil时，判断以当前类名为表名的表是否存在; 此参数非nil时,判断以当前参数为表名的表是否存在.
 */
+(BOOL)bg_isExistForTableName:(NSString *)tablename{
    if(tablename == nil){
        tablename = NSStringFromClass([self class]);
    }
    BOOL result = [[BGDB shareManager] bg_isExistWithTableName:tablename];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同步存储.
 */
-(BOOL)bg_save{
    __block BOOL result;
    [[BGDB shareManager] saveObject:self ignoredKeys:bg_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 异步存储.
 */
-(void)bg_saveAsync:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL result = [self bg_save];
        bg_completeBlock(result);
    }];
}
/**
 同步存储或更新.
 当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
 提示：“唯一约束”优先级高于"主键".
 */
-(BOOL)bg_saveOrUpdate{
    return [[self class] bg_saveOrUpdateArray:@[self]];
}
/**
 同上条件异步.
 */
-(void)bg_saveOrUpdateAsync:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL result = [self bg_saveOrUpdate];
        bg_completeBlock(result);
    }];
}

/**
同步 存储或更新 数组元素.
@array 存放对象的数组.(数组中存放的是同一种类型的数据)
当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
提示：“唯一约束”优先级高于"主键".
*/
+(BOOL)bg_saveOrUpdateArray:(NSArray* _Nonnull)array{
    NSAssert(array && array.count,@"数组没有元素!");
    __block BOOL result;
    [[BGDB shareManager] bg_saveOrUpateArray:array ignoredKeys:bg_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)bg_saveOrUpdateArrayAsync:(NSArray* _Nonnull)array complete:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL result = [self bg_saveOrUpdateArray:array];
        bg_completeBlock(result);
    }];
}

/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 */
-(BOOL)bg_cover{
    __block BOOL result;
    [[BGDB shareManager] clearWithObject:self complete:nil];
    [[BGDB shareManager] saveObject:self ignoredKeys:bg_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
-(void)bg_coverAsync:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL result = [self bg_cover];
        bg_completeBlock(result);
    }];
}

/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 温馨提示: 当数据量巨大时,请用范围接口进行分页查询,避免查询出来的数据量过大导致程序崩溃.
 */
+(NSArray* _Nullable)bg_findAll:(NSString* _Nullable)tablename{
    if (tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block NSArray* results;
    [[BGDB shareManager] queryObjectWithTableName:tablename class:[self class] where:nil complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)bg_findAllAsync:(NSString* _Nullable)tablename complete:(bg_complete_A)complete{
    [[BGDB shareManager] addToThreadPool:^{
        NSArray* array = [self bg_findAll:tablename];
        bg_completeBlock(array);
    }];
}
/**
 查找第一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 */
+(id _Nullable)bg_firstObjet:(NSString* _Nullable)tablename{
    NSArray* array = [self bg_find:tablename limit:1 orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 查找最后一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 */
+(id _Nullable)bg_lastObject:(NSString* _Nullable)tablename{
    NSArray* array = [self bg_find:tablename limit:1 orderBy:nil desc:YES];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 查询某一行数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @row 从第1行开始算起.
 */
+(id _Nullable)bg_object:(NSString* _Nullable)tablename row:(NSInteger)row{
    NSArray* array = [self bg_find:tablename range:NSMakeRange(row,1) orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)bg_find:(NSString* _Nullable)tablename limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* where = [NSMutableString string];
    orderBy?[where appendFormat:@"order by %@%@ ",BG,orderBy]:[where appendFormat:@"order by %@ ",bg_rowid];
    desc?[where appendFormat:@"desc"]:[where appendFormat:@"asc"];
    !limit?:[where appendFormat:@" limit %@",@(limit)];
    __block NSArray* results;
    [[BGDB shareManager] queryObjectWithTableName:tablename class:[self class] where:where complete:^(NSArray * _Nullable array) {
         results = array;
     }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)bg_findAsync:(NSString* _Nullable)tablename limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(bg_complete_A)complete{
    [[BGDB shareManager] addToThreadPool:^{
        NSArray* array = [self bg_find:tablename limit:limit orderBy:orderBy desc:desc];
        bg_completeBlock(array);
    }];
}
/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @range 查询的范围(从location开始的后面length条，localtion要大于0).
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)bg_find:(NSString* _Nullable)tablename range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* where = [NSMutableString string];
    orderBy?[where appendFormat:@"order by %@%@ ",BG,orderBy]:[where appendFormat:@"order by %@ ",bg_rowid];
    desc?[where appendFormat:@"desc"]:[where appendFormat:@"asc"];
    NSAssert((range.location>0)&&(range.length>0),@"range参数错误,location应该大于零,length应该大于零");
    [where appendFormat:@" limit %@,%@",@(range.location-1),@(range.length)];
    __block NSArray* results;
    [[BGDB shareManager] queryObjectWithTableName:tablename class:[self class] where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)bg_findAsync:(NSString* _Nullable)tablename range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(bg_complete_A)complete{
    [[BGDB shareManager] addToThreadPool:^{
        NSArray* array = [self bg_find:tablename range:range orderBy:orderBy desc:desc];
        bg_completeBlock(array);
    }];
}
/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @where 条件参数，可以为nil,nil时查询所有数据.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     where = [NSString stringWithFormat:@"where %@=%@ and %@=%@ or %@=%@",bg_sqlKey(@"age"),bg_sqlValue(@(45)),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸"),bg_sqlKey(@"name"),bg_sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
     where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
     where = [NSString stringWithFormat:@"where %@ and %@=%@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"]),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸")];
 */
+(NSArray* _Nullable)bg_find:(NSString* _Nullable)tablename where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block NSArray* results;
    [[BGDB shareManager] queryWithTableName:tablename conditions:where complete:^(NSArray * _Nullable array) {
        results = [BGTool tansformDataFromSqlDataWithTableName:tablename class:[self class] array:array];
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return results;
}
/**
 同上条件异步.
 */
+(void)bg_findAsync:(NSString* _Nullable)tablename where:(NSString* _Nullable)where complete:(bg_complete_A)complete{
    [[BGDB shareManager] addToThreadPool:^{
        NSArray* array = [self bg_find:tablename where:where];
        bg_completeBlock(array);
    }];
}


/**
 查询某一时间段的数据.(存入时间或更新时间)
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @dateTime 参数格式：
 2017 即查询2017年的数据
 2017-07 即查询2017年7月的数据
 2017-07-19 即查询2017年7月19日的数据
 2017-07-19 16 即查询2017年7月19日16时的数据
 2017-07-19 16:17 即查询2017年7月19日16时17分的数据
 2017-07-19 16:17:53 即查询2017年7月19日16时17分53秒的数据
 2017-07-19 16:17:53.350 即查询2017年7月19日16时17分53秒350毫秒的数据
 */
+(NSArray* _Nullable)bg_find:(NSString* _Nullable)tablename type:(bg_dataTimeType)type dateTime:(NSString* _Nonnull)dateTime{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* like = [NSMutableString string];
    [like appendFormat:@"'%@",dateTime];
    [like appendString:@"%'"];
    NSString* where;
    if(type == bg_createTime){
        where = [NSString stringWithFormat:@"where %@ like %@",bg_sqlKey(bg_createTimeKey),like];
    }else{
        where = [NSString stringWithFormat:@"where %@ like %@",bg_sqlKey(bg_updateTimeKey),like];
    }
    return [self bg_find:tablename where:where];
}
/**
 @where 条件参数,不能为nil.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据:
     where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据:
     where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")];
 */
-(BOOL)bg_updateWhere:(NSString* _Nonnull)where{
    NSAssert(where && where.length,@"条件语句不能为空!");
    NSDictionary* valueDict = [BGTool getDictWithObject:self ignoredKeys:bg_getIgnoreKeys filtModelInfoType:bg_ModelInfoSingleUpdate];
    __block BOOL result;
    [[BGDB shareManager] updateWithObject:self valueDict:valueDict conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
-(void)bg_updateAsyncWhere:(NSString* _Nonnull)where complete:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL flag = [self bg_updateWhere:where];
        bg_completeBlock(flag);
    }];
}
/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，更新以此参数为表名的数据.
 @where 条件参数,不能为nil.
 不支持keyPath.
 where使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾":
     where = [NSString stringWithFormat:@"set %@=%@ where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马化腾"),bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")];
 */
+(BOOL)bg_update:(NSString* _Nullable)tablename where:(NSString* _Nonnull)where{
    NSAssert(where && where.length,@"条件不能为空!");
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block BOOL result;
    id object = [[self class] new];
    [object setBg_tableName:tablename];
    [[BGDB shareManager] updateWithObject:object valueDict:nil conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}


/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 @where 条件参数,可以为nil，nil时删除所有以tablename为表名的数据.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据.
     where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据.
     where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据.
     where = [NSString stringWithFormat:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
+(BOOL)bg_delete:(NSString* _Nullable)tablename where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block BOOL result;
    [[BGDB shareManager] deleteWithTableName:tablename conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)bg_deleteAsync:(NSString* _Nullable)tablename where:(NSString* _Nullable)where complete:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL flag = [self bg_delete:tablename where:where];
        bg_completeBlock(flag);
    }];
}


/**
 删除某一行数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 @row 第几行，从第1行算起.
 */
+(BOOL)bg_delete:(NSString* _Nullable)tablename row:(NSInteger)row{
    NSAssert(row,@"row要大于0");
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSString* where = [NSString stringWithFormat:@"where %@ in(select %@ from %@  limit 1 offset %@)",bg_rowid,bg_rowid,tablename,@(row-1)];
    return [self bg_delete:tablename where:where];
}
/**
 删除第一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 */
+(BOOL)bg_deleteFirstObject:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSString* where = [NSString stringWithFormat:@"where %@ in(select %@ from %@  limit 1 offset 0)",bg_rowid,bg_rowid,tablename];
    return [self bg_delete:tablename where:where];
}
/**
 删除最后一条数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 */
+(BOOL)bg_deleteLastObject:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSString* where = [NSString stringWithFormat:@"where %@ in(select %@ from %@ order by %@ desc limit 1 offset 0)",bg_rowid,bg_rowid,tablename,bg_rowid];
    return [self bg_delete:tablename where:where];
}

/**
 同步清除所有数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，清除以此参数为表名的数据.
 */
+(BOOL)bg_clear:(NSString* _Nullable)tablename{
    return [self bg_delete:tablename where:nil];
}
/**
 同上条件异步.
 */
+(void)bg_clearAsync:(NSString* _Nullable)tablename complete:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL flag = [self bg_delete:tablename where:nil];
        bg_completeBlock(flag);
    }];
}


/**
 同步删除这个类的数据表.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，清除以此参数为表名的数据.
 */
+(BOOL)bg_drop:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block BOOL result;
    [[BGDB shareManager] dropWithTableName:tablename complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)bg_dropAsync:(NSString* _Nullable)tablename complete:(bg_complete_B)complete{
    [[BGDB shareManager] addToThreadPool:^{
        BOOL flag = [self bg_drop:tablename];
        bg_completeBlock(flag);
    }];
}



/**
 查询该表中有多少条数据.
 @tablename 当此参数为nil时,查询以此类名为表名的数据条数，非nil时，查询以此参数为表名的数据条数.
 @where 条件参数,nil时查询所有以tablename为表名的数据条数.
  支持keyPath.
  使用规则请看demo或如下事例:
  1.查询People类中name等于"美国队长"的数据条数.
     where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
  2.查询People类中user.student.human.body等于"小芳"的数据条数.
     where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
  3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
     where = [NSString stringWithFormat:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
+(NSInteger)bg_count:(NSString* _Nullable)tablename where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger count = [[BGDB shareManager] countForTable:tablename conditions:where];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return count;
}


/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @key -> 要操作的属性,不支持keyPath.
 @where -> 条件参数,支持keyPath.
 */
+(double)bg_sqliteMethodWithTableName:(NSString* _Nullable)tablename type:(bg_sqliteMethodType)methodType key:(NSString* _Nonnull)key where:(NSString* _Nullable)where{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    double num = [[BGDB shareManager] sqliteMethodForTable:tablename type:methodType key:key where:where];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return num;
}
/**
 获取数据表当前版本号.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 */
+(NSInteger)bg_version:(NSString* _Nullable)tablename{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    return [BGTool getIntegerWithKey:tablename];
}

/**
 刷新,当类'唯一约束','联合主键','属性类型'发生改变时,调用此接口刷新一下.
 同步刷新.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(bg_dealState)bg_update:(NSString* _Nullable)tablename version:(NSInteger)version{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [BGTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tablename value:version];
        NSArray* keys = [BGTool bg_filtCreateKeys:[BGTool getClassIvarList:[self class] Object:nil onlyKey:NO] ignoredkeys:bg_getIgnoreKeys];
        __block bg_dealState state;
        [[BGDB shareManager] refreshTable:tablename class:[self class] keys:keys complete:^(bg_dealState result) {
            state = result;
        }];
        //关闭数据库
        [[BGDB shareManager] closeDB];
        return state;
    }else{
        return  bg_error;
    }
}
/**
 同上条件异步.
 */
+(void)bg_updateAsync:(NSString* _Nullable)tablename version:(NSInteger)version complete:(bg_complete_I)complete{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [BGTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tablename value:version];
        [[BGDB shareManager] addToThreadPool:^{
            bg_dealState state = [self bg_update:tablename version:version];
            bg_completeBlock(state);
        }];
    }else{
        bg_completeBlock(bg_error);;
    }
}
/**
 刷新,当类'唯一约束','联合主键','属性类型'发生改变时,调用此接口刷新一下.
 同步刷新.
 @tablename 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(bg_dealState)bg_update:(NSString* _Nullable)tablename version:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [BGTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tablename value:version];
        NSArray* keys = [BGTool bg_filtCreateKeys:[BGTool getClassIvarList:[self class] Object:nil onlyKey:NO] ignoredkeys:bg_getIgnoreKeys];
        __block bg_dealState state;
        [[BGDB shareManager] refreshTable:tablename class:[self class] keys:keys keyDict:keydict complete:^(bg_dealState result) {
            state = result;
        }];
        //关闭数据库
        [[BGDB shareManager] closeDB];
        return state;
    }else{
        return bg_error;
    }

}
/**
 同上条件异步.
 */
+(void)bg_updateAsync:(NSString* _Nullable)tablename version:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(bg_complete_I)complete{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSInteger oldVersion = [BGTool getIntegerWithKey:tablename];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tablename value:version];
        [[BGDB shareManager] addToThreadPool:^{
            bg_dealState state = [self bg_update:tablename version:version keyDict:keydict];
            bg_completeBlock(state);
        }];
    }else{
        bg_completeBlock(bg_error);;
    }
}
/**
 将某表的数据拷贝给另一个表
 同步复制.
 @tablename 源表名,当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @destCla 目标表名.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(bg_dealState)bg_copy:(NSString* _Nullable)tablename toTable:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    __block bg_dealState state;
    [[BGDB shareManager] copyTable:tablename to:destTable keyDict:keydict append:append complete:^(bg_dealState result) {
        state = result;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return state;
}
/**
 同上条件异步.
 */
+(void)bg_copyAsync:(NSString* _Nullable)tablename toTable:(NSString* _Nonnull)destTable keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(bg_complete_I)complete{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    [[BGDB shareManager] addToThreadPool:^{
        bg_dealState state = [self bg_copy:tablename toTable:destTable keyDict:keydict append:append];
        bg_completeBlock(state);
    }];
}

/**
 注册数据库表变化监听.
 @tablename 表名称，当此参数为nil时，监听以当前类名为表名的数据表，当此参数非nil时，监听以此参数为表名的数据表。
 @identify 唯一标识，,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
+(BOOL)bg_registerChangeForTableName:(NSString* _Nullable)tablename identify:(NSString* _Nonnull)identify block:(bg_changeBlock)block{
    NSAssert(identify && identify.length,@"唯一标识不能为空!");
    if (tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    tablename = [NSString stringWithFormat:@"%@*%@",tablename,identify];
    return [[BGDB shareManager] registerChangeWithName:tablename block:block];
}
/**
 移除数据库表变化监听.
 @tablename 表名称，当此参数为nil时，监听以当前类名为表名的数据表，当此参数非nil时，监听以此参数为表名的数据表。
 @identify 唯一标识，,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
+(BOOL)bg_removeChangeForTableName:(NSString* _Nullable)tablename identify:(NSString* _Nonnull)identify{
    NSAssert(identify && identify.length,@"唯一标识不能为空!");
    if (tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    tablename = [NSString stringWithFormat:@"%@*%@",tablename,identify];
    return [[BGDB shareManager] removeChangeWithName:tablename];
}

/**
 直接执行sql语句;
 @tablename nil时以cla类名为表名.
 @cla 要操作的类,nil时返回的结果是字典.
 提示：字段名要增加BG_前缀
 */
extern id _Nullable bg_executeSql(NSString* _Nonnull sql,NSString* _Nullable tablename,__unsafe_unretained _Nullable Class cla){
    if (tablename == nil) {
        tablename = NSStringFromClass(cla);
    }
    id result = [[BGDB shareManager] bg_executeSql:sql tablename:tablename class:cla];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}

#pragma mark 下面附加字典转模型API,简单好用,在只需要字典转模型功能的情况下,可以不必要再引入MJExtension那么多文件,造成代码冗余,缩减安装包.
/**
 字典转模型.
 @keyValues 字典(NSDictionary)或json格式字符.
 说明:如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现objectClassInArray这个函数返回一个字典,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
 */
+(id)bg_objectWithKeyValues:(id)keyValues{
    return [BGTool bg_objectWithClass:[self class] value:keyValues];
}
+(id)bg_objectWithDictionary:(NSDictionary *)dictionary{
    return [BGTool bg_objectWithClass:[self class] value:dictionary];
}
/**
 直接传数组批量处理;
 注:array中的元素是字典,否则出错.
 */
+(NSArray* _Nonnull)bg_objectArrayWithKeyValuesArray:(NSArray* const _Nonnull)array{
    NSMutableArray* results = [NSMutableArray array];
    for (id value in array) {
        id obj = [BGTool bg_objectWithClass:[self class] value:value];
        [results addObject:obj];
    }
    return results;
}
/**
 模型转字典.
 @ignoredKeys 忽略掉模型中的哪些key(即模型变量)不要转,nil时全部转成字典.
 */
-(NSMutableDictionary*)bg_keyValuesIgnoredKeys:(NSArray*)ignoredKeys{
    return [BGTool bg_keyValuesWithObject:self ignoredKeys:ignoredKeys];
}

#warning mark 过期方法(能正常使用,但不建议使用)
/**
 判断这个类的数据表是否已经存在.
 */
+(BOOL)bg_isExist{
    BOOL result = [[BGDB shareManager] bg_isExistWithTableName:NSStringFromClass([self class])];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}

/**
 同步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(BOOL)bg_saveArray:(NSArray* _Nonnull)array{
    return [self bg_saveArray:array IgnoreKeys:bg_getIgnoreKeys];
}
/**
 同上条件异步.
 */
+(void)bg_saveArrayAsync:(NSArray* _Nonnull)array complete:(bg_complete_B)complete{
    [self bg_saveArrayAsync:array IgnoreKeys:bg_getIgnoreKeys complete:complete];
}
/**
 同步更新对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据).
 当类中定义了"唯一约束" 或 "主键"有值时,使用此API才有意义.
 提示：“唯一约束”优先级高于"主键".
 */
+(BOOL)bg_updateArray:(NSArray* _Nonnull)array{
    NSAssert(array && array.count,@"数组没有元素!");
    __block BOOL result;
    [[BGDB shareManager] updateObjects:array ignoredKeys:bg_getIgnoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 同上条件异步.
 */
+(void)bg_updateArrayAsync:(NSArray* _Nonnull)array complete:(bg_complete_B)complete{
    NSAssert(array && array.count,@"数组没有元素!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGDB shareManager] updateObjects:array ignoredKeys:bg_getIgnoreKeys complete:complete];
    });
}

/**
 同步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(BOOL)bg_saveArray:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    NSAssert(array && array.count,@"数组没有元素!");
    __block BOOL result = YES;
    [[BGDB shareManager] saveObjects:array ignoredKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}

/**
 异步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(void)bg_saveArrayAsync:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete{
    NSAssert(array && array.count,@"数组没有元素!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_saveArray:array IgnoreKeys:ignoreKeys];
        bg_completeBlock(flag);
    });
}

/**
 同步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)bg_saveIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys{
    __block BOOL result;
    [[BGDB shareManager] saveObject:self ignoredKeys:ignoredKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 异步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(void)bg_saveAsyncIgnoreKeys:(NSArray* const _Nonnull)ignoredKeys complete:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_saveIgnoredKeys:ignoredKeys];
        bg_completeBlock(flag);
    });
    
}
/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)bg_coverIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys{
    __block BOOL result;
    [[BGDB shareManager] clearWithObject:self complete:nil];
    [[BGDB shareManager] saveObject:self ignoredKeys:ignoredKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 异步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(void)bg_coverAsyncIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys complete:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_coverIgnoredKeys:ignoredKeys];
        bg_completeBlock(flag);
    });
}
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据.
 可以为nil,nil时更新所有数据;
 @ignoreKeys 忽略哪些key不用更新.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(BOOL)bg_updateWhere:(NSArray* _Nullable)where ignoreKeys:(NSArray* const _Nullable)ignoreKeys{
    __block BOOL result;
    [[BGDB shareManager] updateWithObject:self where:where ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
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
 */
-(BOOL)bg_updateFormatSqlConditions:(NSString*)conditions IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    __block BOOL result;
    [[BGDB shareManager] updateObject:self ignoreKeys:ignoreKeys conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 根据keypath更新数据.
 同步更新.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 @ignoreKeys 即或略哪些key不用更新.
 */
-(BOOL)bg_updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues ignoreKeys:(NSArray* const _Nullable)ignoreKeys{
    __block BOOL result;
    [[BGDB shareManager] updateWithObject:self forKeyPathAndValues:keyPathValues ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
@end

#pragma mark 直接存储数组.
@implementation NSArray (BGModel)
/**
 存储数组.
 @name 唯一标识名称.
 **/
-(BOOL)bg_saveArrayWithName:(NSString* const _Nonnull)name{
    if([self isKindOfClass:[NSArray class]]) {
        __block BOOL result;
        [[BGDB shareManager] saveArray:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[BGDB shareManager] closeDB];
        return result;
    }else{
        return NO;
    }
}
/**
 添加数组元素.
 @name 唯一标识名称.
 @object 要添加的元素.
 */
+(BOOL)bg_addObjectWithName:(NSString* const _Nonnull)name object:(id const _Nonnull)object{
    NSAssert(object,@"元素不能为空!");
    __block BOOL result;
    [[BGDB shareManager] saveArray:@[object] name:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 获取数组元素数量.
 @name 唯一标识名称.
 */
+(NSInteger)bg_countWithName:(NSString* const _Nonnull)name{
    NSUInteger count = [[BGDB shareManager] countForTable:name where:nil];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return count;

}
/**
 查询整个数组
 */
+(NSArray*)bg_arrayWithName:(NSString* const _Nonnull)name{
    __block NSMutableArray* results;
    [[BGDB shareManager] queryArrayWithName:name complete:^(NSArray * _Nullable array) {
        if(array&&array.count){
            results = [NSMutableArray arrayWithArray:array];
        }
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return results;
}
/**
 获取数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(id _Nullable)bg_objectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index{
    id resultValue = [[BGDB shareManager] queryArrayWithName:name index:index];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return resultValue;
}
/**
 更新数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)bg_updateObjectWithName:(NSString* const _Nonnull)name Object:(id _Nonnull)object Index:(NSInteger)index{
    BOOL result = [[BGDB shareManager] updateObjectWithName:name object:object index:index];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 删除数组的某个元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)bg_deleteObjectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index{
    BOOL result = [[BGDB shareManager] deleteObjectWithName:name index:index];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 清空数组元素.
 @name 唯一标识名称.
 */
+(BOOL)bg_clearArrayWithName:(NSString* const _Nonnull)name{
    __block BOOL result;
    [[BGDB shareManager] dropSafeTable:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
@end

#pragma mark 直接存储字典.
@implementation NSDictionary (BGModel)
/**
 存储字典.
 */
-(BOOL)bg_saveDictionary{
    if([self isKindOfClass:[NSDictionary class]]) {
        __block BOOL result;
        [[BGDB shareManager] saveDictionary:self complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[BGDB shareManager] closeDB];
        return result;
    }else{
        return NO;
    }

}
/**
 添加字典元素.
 */
+(BOOL)bg_setValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key{
    BOOL result = [[BGDB shareManager] bg_setValue:value forKey:key];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 更新字典元素.
 */
+(BOOL)bg_updateValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key{
    BOOL result = [[BGDB shareManager] bg_updateValue:value forKey:key];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 遍历字典元素.
 */
+(void)bg_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block{
    [[BGDB shareManager] bg_enumerateKeysAndObjectsUsingBlock:block];
    //关闭数据库
    [[BGDB shareManager] closeDB];
}
/**
 获取字典元素.
 */
+(id _Nullable)bg_valueForKey:(NSString* const _Nonnull)key{
    id value = [[BGDB shareManager] bg_valueForKey:key];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return value;
}
/**
 移除字典某个元素.
 */
+(BOOL)bg_removeValueForKey:(NSString* const _Nonnull)key{
    BOOL result = [[BGDB shareManager] bg_deleteValueForKey:key];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
/**
 清空字典.
 */
+(BOOL)bg_clearDictionary{
    __block BOOL result;
    NSString* const tableName = @"BG_Dictionary";
    [[BGDB shareManager] dropSafeTable:tableName complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGDB shareManager] closeDB];
    return result;
}
@end
