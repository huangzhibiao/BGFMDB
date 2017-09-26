//
//  NSObject+BGModel.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/28.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "NSObject+BGModel.h"
#import "BGFMDB.h"
#import "BGTool.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>

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

/**
 判断这个类的数据表是否已经存在.
 */
+(BOOL)bg_isExist{
    __block BOOL result;
    [[BGFMDB shareManager] isExistWithTableName:NSStringFromClass([self class]) complete:^(BOOL isSuccess) {
        result  = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 同步存储.
 */
-(BOOL)bg_save{
    __block BOOL result;
    [[BGFMDB shareManager] saveObject:self ignoredKeys:nil complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 异步存储.
 */
-(void)bg_saveAsync:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_save];
        bg_completeBlock(flag);
    });
}
/**
 同步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(BOOL)bg_saveArray:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    NSAssert(array||array.count,@"数组没有元素!");
    __block BOOL result = YES;
        [[BGFMDB shareManager] saveObjects:array ignoredKeys:ignoreKeys complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 异步存入对象数组.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 */
+(void)bg_saveArrayAsync:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys complete:(bg_complete_B)complete{
    NSAssert(array||array.count,@"数组没有元素!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_saveArray:array IgnoreKeys:ignoreKeys];
        bg_completeBlock(flag);
    });
}
/**
 同步存储或更新数组.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
+(void)bg_saveOrUpdateArray:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    NSAssert(array||array.count,@"数组没有元素!");
    NSString* uniqueKey = [BGTool isRespondsToSelector:NSSelectorFromString(bg_uniqueKeySelector) forClass:[self class]];
    if (uniqueKey) {
        id uniqueKeyVlaue = [array.lastObject valueForKey:uniqueKey];
        NSInteger count = [[array.lastObject class] bg_countWhere:@[uniqueKey,@"=",uniqueKeyVlaue]];
        if (count){//有数据存在就更新.
            //此处更新数据.
            [[BGFMDB shareManager] updateObjects:array ignoredKeys:ignoreKeys complete:nil];
        }else{//没有就存储.
            [self bg_saveArray:array IgnoreKeys:ignoreKeys];
        }
    }else{
        [self bg_saveArray:array IgnoreKeys:ignoreKeys];
    }
}
/**
 异步存储或更新数组.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
+(void)bg_saveOrUpdateAsyncArray:(NSArray*)array IgnoreKeys:(NSArray* const _Nullable)ignoreKeys{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [self bg_saveOrUpdateArray:array IgnoreKeys:ignoreKeys];
    });
}
/**
 同步存储或更新.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
-(BOOL)bg_saveOrUpdate{
    NSString* uniqueKey = [BGTool isRespondsToSelector:NSSelectorFromString(bg_uniqueKeySelector) forClass:[self class]];//[BGTool getUnique:self];
    if (uniqueKey) {
        id uniqueKeyVlaue = [self valueForKey:uniqueKey];
        NSInteger count = [[self class] bg_countWhere:@[uniqueKey,@"=",uniqueKeyVlaue]];
        if (count){//有数据存在就更新.
            return [self bg_updateWhere:@[uniqueKey,@"=",uniqueKeyVlaue]];
        }else{//没有就存储.
            return [self bg_save];
        }
    }else{
        return [self bg_save];
    }
}
/**
 异步存储或更新.
 当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
 */
-(void)bg_saveOrUpdateAsync:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL result = [self bg_saveOrUpdate];
        bg_completeBlock(result);
    });
}
/**
 同步存储.
 @ignoreKeys 忽略掉模型中的哪些key(即模型变量)不要存储.
 */
-(BOOL)bg_saveIgnoredKeys:(NSArray* const _Nonnull)ignoredKeys{
    __block BOOL result;
    [[BGFMDB shareManager] saveObject:self ignoredKeys:ignoredKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
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
 */
-(BOOL)bg_cover{
    __block BOOL result;
    [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess) {
        if(isSuccess)
            [[BGFMDB shareManager] saveObject:self ignoredKeys:nil complete:^(BOOL isSuccess) {
                result = isSuccess;
            }];
        else
            result = NO;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}

/**
 异步覆盖存储.
 覆盖掉原来的数据,只存储当前的数据.
 */
-(void)bg_coverAsync:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_cover];
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
    [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess) {
        if(isSuccess)
            [[BGFMDB shareManager] saveObject:self ignoredKeys:ignoredKeys complete:^(BOOL isSuccess) {
                result = isSuccess;
            }];
        else
            result = NO;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
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
 同步查询所有结果.
 温馨提示: 当数据量巨大时,请用范围接口进行分页查询,避免查询出来的数据量过大导致程序崩溃.
 */
+(NSArray* _Nullable)bg_findAll{
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:nil complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 异步查询所有结果.
 温馨提示: 当数据量巨大时,请用范围接口进行分页查询,避免查询出来的数据量过大导致程序崩溃.
 */
+(void)bg_findAllAsync:(bg_complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* array = [self bg_findAll];
        bg_completeBlock(array);
    });
}
/**
 查找第一条数据
 */
+(id _Nullable)bg_firstObjet{
    NSArray* array = [self bg_findAllWithLimit:1 orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 查找最后一条数据
 */
+(id _Nullable)bg_lastObject{
    NSArray* array = [self bg_findAllWithLimit:1 orderBy:bg_primaryKey desc:YES];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 查询某一行数据
 */
+(id _Nullable)bg_ObjectWithRow:(NSInteger)row{
    NSArray* array = [self bg_findAllWithRange:NSMakeRange(row,1) orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}
/**
 同步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)bg_findAllWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    NSMutableString* param = [NSMutableString string];
    !(orderBy&&desc)?:[param appendFormat:@"order by %@%@ desc",BG,orderBy];
    !param.length?:[param appendString:@" "];
    !limit?:[param appendFormat:@"limit %@",@(limit)];
    param = param.length?param:nil;
    __block NSArray* results;
     [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:^(NSArray * _Nullable array) {
         results = array;
     }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 异步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(void)bg_findAllAsyncWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(bg_complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* results = [self bg_findAllWithLimit:limit orderBy:orderBy desc:desc];
        bg_completeBlock(results);
    });
}
/**
 同步查询所有结果.
 @range 查询的范围(从location开始的后面length条).
 @desc YES:降序，NO:升序.
 */
+(NSArray* _Nullable)bg_findAllWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    NSMutableString* param = [NSMutableString string];
    !(orderBy&&desc)?:[param appendFormat:@"order by %@%@ desc ",BG,orderBy];
    NSAssert((range.location>=0)&&(range.length>0),@"range参数错误,location应该大于或等于零,length应该大于零");
    [param appendFormat:@"limit %@,%@",@(range.location),@(range.length)];
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 异步查询所有结果.
 @range 查询的范围(从location(大于或等于零)开始的后面length(大于零)条).
 @desc YES:降序，NO:升序.
 */
+(void)bg_findAllAsyncWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(bg_complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* results = [self bg_findAllWithRange:range orderBy:orderBy desc:desc];
        bg_completeBlock(results);
    });
}
/**
 同步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(NSArray* _Nullable)bg_findWhere:(NSArray* _Nullable)where{
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] keys:nil where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 异步条件查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;
 可以为nil,为nil时查询所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).
 */
+(void)bg_findAsyncWhere:(NSArray* _Nullable)where complete:(bg_complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* array = [self bg_findWhere:where];
        bg_completeBlock(array);
    });
}
/**
 @format 传入sql条件参数,语句来进行查询,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
    NSArray* arrayConds1 = [People bg_findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",bg_sqlKey(@"age"),bg_sqlValue(@(45)),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸"),bg_sqlKey(@"name"),bg_sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
    [People bg_findFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
    NSArray* arrayConds3 = [People bg_findFormatSqlConditions:@"where %@ and %@=%@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"]),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸")];
 */
+(NSArray* _Nullable)bg_findFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    __block NSArray* results;
    [[BGFMDB shareManager] queryWithTableName:tableName conditions:conditions complete:^(NSArray * _Nullable array) {
        results = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 keyPath查询
 同步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(NSArray* _Nullable)bg_findForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    __block NSArray* results;
    [[BGFMDB shareManager] queryObjectWithClass:[self class] forKeyPathAndValues:keyPathValues complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 keyPath查询
 异步查询所有keyPath条件结果.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)bg_findAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_A)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray* array = [self bg_findForKeyPathAndValues:keyPathValues];
        bg_completeBlock(array);
    });
}
/**
 查询某一时间段的数据.(存入时间或更新时间)
 @dateTime 参数格式：
 2017 即查询2017年的数据
 2017-07 即查询2017年7月的数据
 2017-07-19 即查询2017年7月19日的数据
 2017-07-19 16 即查询2017年7月19日16时的数据
 2017-07-19 16:17 即查询2017年7月19日16时17分的数据
 2017-07-19 16:17:53 即查询2017年7月19日16时17分53秒的数据
 */
+(NSArray* _Nullable)bg_findWithType:(bg_dataTimeType)type dateTime:(NSString* _Nonnull)dateTime{
    NSMutableString* like = [NSMutableString string];
    [like appendFormat:@"'%@",dateTime];
    [like appendString:@"%'"];
    if(type == bg_createTime){
        return [self bg_findFormatSqlConditions:@"where %@ like %@",bg_sqlKey(bg_createTimeKey),like];
    }else{
        return [self bg_findFormatSqlConditions:@"where %@ like %@",bg_sqlKey(bg_updateTimeKey),like];
    }
}
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据.
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(BOOL)bg_updateWhere:(NSArray* _Nullable)where{
    __block BOOL result;
    [[BGFMDB shareManager] updateWithObject:self where:where ignoreKeys:nil complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
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
    [[BGFMDB shareManager] updateWithObject:self where:where ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}

/**
 异步更新.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath更新接口).
 */
-(void)bg_updateAsync:(NSArray* _Nullable)where complete:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_updateWhere:where];
        bg_completeBlock(flag);
    });
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 此接口不支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾"
 [People bg_updateFormatSqlConditions:@"set %@=%@ where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马化腾"),bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")];
 */
+(BOOL)bg_updateFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSAssert([conditions hasPrefix:@"set"],@"更新条件要以set开头!");
    NSString* setAppend = [NSString stringWithFormat:@"set %@=%@,",bg_sqlKey(bg_updateTimeKey),bg_sqlValue([BGTool stringWithDate:[NSDate new]])];
    conditions = [conditions stringByReplacingOccurrencesOfString:@"set" withString:setAppend];
    NSString* tableName = NSStringFromClass([self class]);
    //加入更新时间字段值.
    __block BOOL result;
    [[BGFMDB shareManager] updateWithTableName:tableName valueDict:nil conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据.
 [p bg_updateFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 2.将People类中name等于"马云爸爸"的数据更新为当前对象的数据.
 [p bg_updateFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马云爸爸")];
 */
-(BOOL)bg_updateFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    NSDictionary* valueDict = [BGTool getDictWithObject:self ignoredKeys:nil isUpdate:YES];
    __block BOOL result;
    [[BGFMDB shareManager] updateWithTableName:tableName valueDict:valueDict conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
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
    [[BGFMDB shareManager] updateObject:self ignoreKeys:ignoreKeys conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}

/**
 根据keypath更新数据.
 同步更新.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(BOOL)bg_updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    __block BOOL result;
    [[BGFMDB shareManager] updateWithObject:self forKeyPathAndValues:keyPathValues ignoreKeys:nil complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
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
    [[BGFMDB shareManager] updateWithObject:self forKeyPathAndValues:keyPathValues ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}

/**
 根据keypath更新数据.
 异步更新.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
-(void)bg_updateAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_updateForKeyPathAndValues:keyPathValues];
        bg_completeBlock(flag);
    });
}
/**
 同步删除数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath删除接口).
 */
+(BOOL)bg_deleteWhere:(NSArray* _Nonnull)where{
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithClass:[self class] where:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 异步删除.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath删除接口).
 */
+(void)bg_deleteAsync:(NSArray* _Nonnull)where complete:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_deleteWhere:where];
        bg_completeBlock(flag);
    });
}
/**
 @format 传入sql条件参数,语句来进行更新,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据
 [People bg_deleteFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据
 [People bg_deleteFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
 [People bg_deleteFormatSqlConditions:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
+(BOOL)bg_deleteFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString* tableName = NSStringFromClass([self class]);
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithTableName:tableName conditions:conditions complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 根据keypath删除数据.
 同步删除.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(BOOL)bg_deleteForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithTableName:NSStringFromClass([self class]) forKeyPathAndValues:keyPathValues complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 根据keypath删除数据.
 异步删除.
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.
 */
+(void)bg_deleteAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_deleteForKeyPathAndValues:keyPathValues];
        bg_completeBlock(flag);
    });
}
/**
 删除某一行数据
 */
+(BOOL)bg_deleteWithRow:(NSInteger)row{
    return [self bg_deleteFormatSqlConditions:@"where %@ in(select %@ from %@  limit %@,1)",bg_sqlKey(bg_primaryKey),bg_sqlKey(bg_primaryKey),NSStringFromClass([self class]),@(row)];
}
/**
 删除第一条数据
 */
+(BOOL)bg_deleteFirstObject{
    return [self bg_deleteFormatSqlConditions:@"where %@ in(select %@ from %@  limit 0,1)",bg_sqlKey(bg_primaryKey),bg_sqlKey(bg_primaryKey),NSStringFromClass([self class])];
}
/**
 删除最后一条数据
 */
+(BOOL)bg_deleteLastObject{
    return [self bg_deleteFormatSqlConditions:@"where %@ in(select %@ from %@ order by %@ desc limit 0,1)",bg_sqlKey(bg_primaryKey),bg_sqlKey(bg_primaryKey),NSStringFromClass([self class]),bg_sqlKey(bg_primaryKey)];
}

/**
 同步清除所有数据
 */
+(BOOL)bg_clear{
    __block BOOL result;
    [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess){
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 异步清除所有数据.
 */
+(void)bg_clearAsync:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_clear];
        bg_completeBlock(flag);
    });
}
/**
 同步删除这个类的数据表
 */
+(BOOL)bg_drop{
    __block BOOL result;
    [[BGFMDB shareManager] dropWithClass:[self class] complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 异步删除这个类的数据表.
 */
+(void)bg_dropAsync:(bg_complete_B)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL flag = [self bg_drop];
        bg_completeBlock(flag);
    });
}
/**
 查询该表中有多少条数据
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询条数接口).
 */
+(NSInteger)bg_countWhere:(NSArray* _Nullable)where{
    NSUInteger count = [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) where:where];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return count;
}
/**
 @format 传入sql条件参数,语句来查询数据条数,方便开发者自由扩展.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询People类中name等于"美国队长"的数据条数.
 [People bg_countFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
 2.查询People类中user.student.human.body等于"小芳"的数据条数.
 [People bg_countFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
 [People bg_countFormatSqlConditions:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
+(NSInteger)bg_countFormatSqlConditions:(NSString*)format,... NS_FORMAT_FUNCTION(1,2){
    va_list ap;
    va_start (ap, format);
    NSString *conditions = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSInteger count = [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) conditions:conditions];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return count;
}

/**
 keyPath查询该表中有多少条数据
 @keyPathValues数组,形式@[@"user.student.name",bg_equal,@"小芳",@"user.student.conten",bg_contains,@"书"]
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象的条数.
 */
+(NSInteger)bg_countForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues{
    NSInteger count = [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) forKeyPathAndValues:keyPathValues];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return count;
}
/**
 直接调用sqliteb的原生函数计算sun,min,max,avg等.
 用法：NSInteger num = [People bg_sqliteMethodWithType:bg_sum key:@"age"];
 提示: @param key -> 不支持keyPath , @param where -> 支持keyPath
 */
+(NSInteger)bg_sqliteMethodWithType:(bg_sqliteMethodType)methodType key:(NSString* _Nonnull)key where:(NSString* _Nullable)where,...{
    va_list ap;
    va_start (ap,where);
    NSString *conditions = where?[[NSString alloc] initWithFormat:where arguments:ap]:nil;
    va_end (ap);
    NSInteger num = [[BGFMDB shareManager] sqliteMethodForTable:NSStringFromClass([self class]) type:methodType key:key where:conditions];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return num;
}
/**
 获取本类数据表当前版本号.
 */
+(NSInteger)bg_version{
    return [BGTool getIntegerWithKey:NSStringFromClass([self class])];
}

/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(bg_dealState)bg_updateVersion:(NSInteger)version{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        __block bg_dealState state;
        [[BGFMDB shareManager] refreshTable:tableName keys:[BGTool getClassIvarList:[self class] onlyKey:NO] complete:^(bg_dealState result) {
            state = result;
        }];
        //关闭数据库
        [[BGFMDB shareManager] closeDB];
        return state;
    }else{
        return  bg_error;
    }
}
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)bg_updateVersionAsync:(NSInteger)version complete:(bg_complete_I)complete{
        NSString* tableName = NSStringFromClass([self class]);
        NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
        if(version > oldVersion){
            [BGTool setIntegerWithKey:tableName value:version];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                bg_dealState state = [self bg_updateVersion:version];
                bg_completeBlock(state);
                });
        }else{
            bg_completeBlock(bg_error);;
        }
}
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 同步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(bg_dealState)bg_updateVersion:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        __block bg_dealState state;
        [[BGFMDB shareManager] refreshTable:tableName keyDict:keydict complete:^(bg_dealState result) {
            state = result;
        }];
        //关闭数据库
        [[BGFMDB shareManager] closeDB];
        return state;
    }else{
        return bg_error;
    }

}
/**
 刷新,当类"唯一约束"改变时,调用此接口刷新一下.
 异步刷新.
 @version 版本号,从1开始,依次往后递增.
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
+(void)bg_updateVersionAsync:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(bg_complete_I)complete{
    NSString* tableName = NSStringFromClass([self class]);
    NSInteger oldVersion = [BGTool getIntegerWithKey:tableName];
    if(version > oldVersion){
        [BGTool setIntegerWithKey:tableName value:version];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            bg_dealState state = [self bg_updateVersion:version keyDict:keydict];
            bg_completeBlock(state);
        });
    }else{
        bg_completeBlock(bg_error);;
    }
}
/**
 将某表的数据拷贝给另一个表
 同步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(bg_dealState)bg_copyToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append{
    __block bg_dealState state;
    [[BGFMDB shareManager] copyClass:[self class] to:destCla keyDict:keydict append:append complete:^(bg_dealState result) {
        state = result;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return state;
}
/**
 将某表的数据拷贝给另一个表
 异步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(void)bg_copyAsyncToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(bg_complete_I)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        bg_dealState state = [self bg_copyToClass:destCla keyDict:keydict append:append];
        bg_completeBlock(state);
    });
}

/**
 注册数据变化监听.
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.
 @return YES: 注册监听成功; NO: 注册监听失败.
 */
+(BOOL)bg_registerChangeWithName:(NSString* const _Nonnull)name block:(bg_changeBlock)block{
    NSString* uniqueName = [NSString stringWithFormat:@"%@*%@",NSStringFromClass([self class]),name];
    return [[BGFMDB shareManager] registerChangeWithName:uniqueName block:block];
}
/**
 移除数据变化监听.
 @name 注册监听的时候使用的名称.
 @return YES: 移除监听成功; NO: 移除监听失败.
 */
+(BOOL)bg_removeChangeWithName:(NSString* const _Nonnull)name{
     NSString* uniqueName = [NSString stringWithFormat:@"%@*%@",NSStringFromClass([self class]),name];
    return [[BGFMDB shareManager] removeChangeWithName:uniqueName];
}

/**
 直接执行sql语句;
 @className 要操作的类名.(如果不传入，那返回的结果是一个字典，里面包含了数据库字段名和字段值)
 提示：字段名要增加BG_前缀
 */
id bg_executeSql(NSString* _Nonnull sql,NSString* _Nullable className){
    id result = [[BGFMDB shareManager] bg_executeSql:sql className:className];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
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
        [[BGFMDB shareManager] saveArray:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[BGFMDB shareManager] closeDB];
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
    [[BGFMDB shareManager] saveArray:@[object] name:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 获取数组元素数量.
 @name 唯一标识名称.
 */
+(NSInteger)bg_countWithName:(NSString* const _Nonnull)name{
    NSUInteger count = [[BGFMDB shareManager] countForTable:name where:nil];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return count;

}
/**
 查询整个数组
 */
+(NSArray*)bg_arrayWithName:(NSString* const _Nonnull)name{
    __block NSMutableArray* results;
    [[BGFMDB shareManager] queryArrayWithName:name complete:^(NSArray * _Nullable array) {
        if(array&&array.count){
            results = [NSMutableArray arrayWithArray:array];
        }
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return results;
}
/**
 获取数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(id _Nullable)bg_objectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index{
    id resultValue = [[BGFMDB shareManager] queryArrayWithName:name index:index];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return resultValue;
}
/**
 更新数组某个位置的元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)bg_updateObjectWithName:(NSString* const _Nonnull)name Object:(id _Nonnull)object Index:(NSInteger)index{
    BOOL result = [[BGFMDB shareManager] updateObjectWithName:name object:object index:index];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 删除数组的某个元素.
 @name 唯一标识名称.
 @index 数组元素位置.
 */
+(BOOL)bg_deleteObjectWithName:(NSString* const _Nonnull)name Index:(NSInteger)index{
    BOOL result = [[BGFMDB shareManager] deleteObjectWithName:name index:index];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 清空数组元素.
 @name 唯一标识名称.
 */
+(BOOL)bg_clearArrayWithName:(NSString* const _Nonnull)name{
    __block BOOL result;
    [[BGFMDB shareManager] dropSafeTable:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
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
        [[BGFMDB shareManager] saveDictionary:self complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[BGFMDB shareManager] closeDB];
        return result;
    }else{
        return NO;
    }

}
/**
 添加字典元素.
 */
+(BOOL)bg_setValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key{
    BOOL result = [[BGFMDB shareManager] bg_setValue:value forKey:key];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 更新字典元素.
 */
+(BOOL)bg_updateValue:(id const _Nonnull)value forKey:(NSString* const _Nonnull)key{
    BOOL result = [[BGFMDB shareManager] bg_updateValue:value forKey:key];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 遍历字典元素.
 */
+(void)bg_enumerateKeysAndObjectsUsingBlock:(void (^ _Nonnull)(NSString* _Nonnull key, id _Nonnull value,BOOL *stop))block{
    [[BGFMDB shareManager] bg_enumerateKeysAndObjectsUsingBlock:block];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
}
/**
 获取字典元素.
 */
+(id _Nullable)bg_valueForKey:(NSString* const _Nonnull)key{
    id value = [[BGFMDB shareManager] bg_valueForKey:key];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return value;
}
/**
 移除字典某个元素.
 */
+(BOOL)bg_removeValueForKey:(NSString* const _Nonnull)key{
    BOOL result = [[BGFMDB shareManager] bg_deleteValueForKey:key];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
/**
 清空字典.
 */
+(BOOL)bg_clearDictionary{
    __block BOOL result;
    NSString* const tableName = @"BG_Dictionary";
    [[BGFMDB shareManager] dropSafeTable:tableName complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[BGFMDB shareManager] closeDB];
    return result;
}
@end
