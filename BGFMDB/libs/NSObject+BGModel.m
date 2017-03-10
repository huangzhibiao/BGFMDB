//
//  NSObject+BGModel.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/28.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "NSObject+BGModel.h"
#import "BGFMDB.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>

static const char IDKey;

@implementation NSObject (BGModel)


-(NSNumber*)ID{
    return objc_getAssociatedObject(self, &IDKey);
}

-(void)setID:(NSNumber*)ID{
    objc_setAssociatedObject(self,&IDKey,ID,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 设置调试模式
 */
+(void)setDebug:(BOOL)debug{
    if ([BGFMDB shareManager].debug != debug){//防止重复设置.
        [BGFMDB shareManager].debug = debug;
    }
}
/**
 自定义 “唯一约束” 函数,如果需要 “唯一约束”,则在自定类中自己实现该函数.
 @return 返回值是 “唯一约束” 的字段名(即相对应的变量名).
 */
-(NSString *)uniqueKey{
    return nil;
}
/**
 判断这个类的数据表是否已经存在.
 */
+(BOOL)isExist{
    __block BOOL result;
    [[BGFMDB shareManager] isExistWithTableName:NSStringFromClass([self class]) complete:^(BOOL isSuccess) {
        result  = isSuccess;
    }];
    return result;
}
/**
 同步存储.
 */
-(BOOL)save{
    __block BOOL result;
    [[BGFMDB shareManager] saveObject:self complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 @async YES:异步存储,NO:同步存储.
 */
-(void)saveAsync:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] saveObject:self complete:complete];
    });
}

/**
 同步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 */
-(BOOL)cover{
    __block BOOL result;
    [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess) {
        if(isSuccess)
            [[BGFMDB shareManager] saveObject:self complete:^(BOOL isSuccess) {
                result = isSuccess;
            }];
        else
            result = NO;
    }];
    return result;
}

/**
 覆盖掉原来的数据,只存储当前的数据.
 @async YES:异步存储,NO:同步存储.
 */
-(void)coverAsync:(Complete_B)complete{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess){
            if(isSuccess)
            [[BGFMDB shareManager] saveObject:self complete:complete];
            else
            !complete?:complete(isSuccess);
        }];
    });
    
}

/**
 同步查询所有结果.
 */
+(NSArray* _Nullable)findAll{
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:nil complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    return results;
}
/**
 异步查询所有结果.
 */
+(void)findAllAsync:(Complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:nil complete:complete];
    });
}

/**
 同步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)findAllWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    NSMutableString* param = [NSMutableString string];
    !(orderBy&&desc)?:[param appendFormat:@"order by %@%@ desc",BG,orderBy];
    !param.length?:[param appendString:@" "];
    !limit?:[param appendFormat:@"limit %ld",limit];
    param = param.length?param:nil;
    __block NSArray* results;
     [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:^(NSArray * _Nullable array) {
         results = array;
     }];
    return results;
}

/**
 异步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsyncWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* results = [NSObject findAllWithLimit:limit orderBy:orderBy desc:desc];
        !complete?:complete(results);
    });
}
/**
 同步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)findAllWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    NSMutableString* param = [NSMutableString string];
    !(orderBy&&desc)?:[param appendFormat:@"order by %@%@ desc ",BG,orderBy];
    NSAssert((range.location>=0)&&(range.length>0),@"range参数错误,location应该大于或等于零,length应该大于零");
    [param appendFormat:@"limit %ld,%ld",range.location,range.length];
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    return results;
}
/**
 异步查询所有结果.
 @range 查询的范围(从location(大于或等于零)开始的后面length(大于零)条).
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsyncWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* results = [NSObject findAllWithRange:range orderBy:orderBy desc:desc];
        !complete?:complete(results);
    });
}
/**
 同步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(NSArray* _Nullable)findWhere:(NSArray* _Nullable)where{
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] keys:nil where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    return results;
}
/**
 异步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(void)findAsyncWhere:(NSArray* _Nullable)where complete:(Complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] keys:nil where:where complete:complete];
    });
}
/**
 @format 传入sql条件参数,语句来进行查询,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
    NSArray* arrayConds1 = [People findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",sqlKey(@"age"),sqlValue(@(45)),sqlKey(@"name"),sqlValue(@"爸爸"),sqlKey(@"name"),sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
    [People findFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
    NSArray* arrayConds3 = [People findFormatSqlConditions:@"where %@ and %@=%@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"]),sqlKey(@"name"),sqlValue(@"爸爸")];
 */
+(NSArray* _Nullable)findFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    __block NSArray* results;
    [[BGFMDB shareManager] queryWithTableName:tableName conditions:conditions complete:^(NSArray * _Nullable array) {
        results = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
    }];
    return results;
}
/**
 keyPath查询
 同步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(NSArray* _Nullable)findForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] forKeyPathAndValues:keyPathValues complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    return results;
}
/**
 keyPath查询
 异步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)findAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] forKeyPathAndValues:keyPathValues complete:complete];
    });
}
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据.
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(BOOL)updateWhere:(NSArray* _Nullable)where{
    __block BOOL result;
    [[BGFMDB shareManager] updateWithObject:self where:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 异步更新.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(void)updateAsync:(NSArray* _Nullable)where complete:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] updateWithObject:self where:where complete:complete];
    });
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 此接口不支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾"
 [People updateFormatSqlConditions:@"set %@=%@ where %@=%@",sqlKey(@"name"),sqlValue(@"马化腾"),sqlKey(@"name"),sqlValue(@"马云爸爸")];
 */
+(BOOL)updateFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    __block BOOL result;
    [[BGFMDB shareManager] updateWithTableName:tableName valueDict:nil conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    
    return result;
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据.
 [p updateFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据.
 [p updateFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"马云爸爸")];
 */
-(BOOL)updateFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:self];
    NSMutableDictionary* valueDict = [NSMutableDictionary dictionary];
    for(BGModelInfo* info in infos){
        valueDict[info.sqlColumnName] = info.sqlColumnValue;
    }
    __block BOOL result;
    [[BGFMDB shareManager] updateWithTableName:tableName valueDict:valueDict conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    
    return result;
}
/**
 根据keypath更新数据.
 同步更新.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(BOOL)updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    __block BOOL result;
    [[BGFMDB shareManager] updateWithObject:self forKeyPathAndValues:keyPathValues complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 根据keypath更新数据.
 异步更新.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)updateAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] updateWithObject:self forKeyPathAndValues:keyPathValues complete:complete];
    });
}
/**
 同步删除数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath删除接口).
 */
+(BOOL)deleteWhere:(NSArray* _Nonnull)where{
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithClass:[self class] where:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 异步删除.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath删除接口).
 */
+(void)deleteAsync:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] deleteWithClass:[self class] where:where complete:complete];
    });
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据
 [People deleteFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据
 [People deleteFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
 [People deleteFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 */
+(BOOL)deleteFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithTableName:tableName conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 根据keypath删除数据.
 同步删除.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(BOOL)deleteForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithTableName:NSStringFromClass([self class]) forKeyPathAndValues:keyPathValues complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 根据keypath删除数据.
 异步删除.
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)deleteAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] deleteWithTableName:NSStringFromClass([self class]) forKeyPathAndValues:keyPathValues complete:complete];
    });
}
/**
 同步清除所有数据
 */
+(BOOL)clear{
    __block BOOL result;
    [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess){
        result = isSuccess;
    }];
    return result;
}
/**
 异步清除所有数据.
 */
+(void)clearAsync:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] clearWithClass:[self class] complete:complete];
    });
}
/**
 同步删除这个类的数据表
 */
+(BOOL)drop{
    __block BOOL result;
    [[BGFMDB shareManager] dropWithClass:[self class] complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 异步删除这个类的数据表.
 */
+(void)dropAsync:(Complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] dropWithClass:[self class] complete:complete];
    });
}
/**
 查询该表中有多少条数据
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询条数接口).
 */
+(NSInteger)countWhere:(NSArray* _Nullable)where{
    return [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) where:where];
}
/**
 @format 传入sql条件参数,语句来查询数据条数,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询People类中name等于"美国队长"的数据条数.
 [People countFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
 2.查询People类中user.student.human.body等于"小芳"的数据条数.
 [People countFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
 [People countFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
 */
+(NSInteger)countFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    
    return [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) conditions:conditions];
}

/**
 keyPath查询该表中有多少条数据
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象的条数.
 */
+(NSInteger)countForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    return [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) forKeyPathAndValues:keyPathValues];
}
/**
 获取本类数据表当前版本号.
 */
+(NSInteger)version{
    return [BGTool getIntegerWithKey:NSStringFromClass([self class])];
}
+(void)refreshAsync:(BOOL)async complete:(Complete_I)complete{
    NSString* tableName = NSStringFromClass([self class]);
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] refreshTable:tableName keys:[BGTool getClassIvarList:[self class] onlyKey:NO] complete:complete];
        });
    }else{
        [[BGFMDB shareManager] refreshTable:tableName keys:[BGTool getClassIvarList:[self class] onlyKey:NO] complete:complete];
    }
}
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(dealState)updateVersion:(NSInteger)version{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        __block dealState state;
        [self refreshAsync:NO complete:^(dealState result) {
            state = result;
        }];
        return state;
    }else{
        return  Error;
    }
}
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)updateVersionAsync:(NSInteger)version complete:(Complete_I)complete{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        [self refreshAsync:YES complete:complete];
    }else{
        !complete?:complete(Error);
    }
}
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(dealState)updateVersion:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        __block dealState state;
        [[BGFMDB shareManager] refreshTable:tableName keyDict:keydict complete:^(dealState result) {
            state = result;
        }];
        return state;
    }else{
        return Error;
    }

}
/**
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)updateVersionAsync:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(Complete_I)complete{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] refreshTable:tableName keyDict:keydict complete:complete];
        });
    }else{
        !complete?:complete(Error);
    }
}
/**
 将某表的数据拷贝给另一个表
 同步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(dealState)copyToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append{
    __block dealState state;
    [[BGFMDB shareManager] copyClass:[self class] to:destCla keyDict:keydict append:append complete:^(dealState result) {
        state = result;
    }];
    return state;
}
/**
 将某表的数据拷贝给另一个表
 异步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(void)copyAsyncToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[BGFMDB shareManager] copyClass:[self class] to:destCla keyDict:keydict append:append complete:complete];
    });
}
/**
 事务操作.
 @return 返回YES提交事务, 返回NO回滚事务.
 */
+(void)inTransaction:(BOOL (^_Nonnull)())block{
    [[BGFMDB shareManager] inTransaction:block];
}
/**
 注册数据变化监听.
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
+(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(ChangeBlock)block{
    return [[BGFMDB shareManager] registerChangeWithName:name block:block];
}
/**
 移除数据变化监听.
 @name 注册监听的时候使用的名称.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
+(BOOL)removeChangeWithName:(NSString* const _Nonnull)name{
    return [[BGFMDB shareManager] removeChangeWithName:name];
}
@end
