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
    [BGFMDB shareManager].debug = debug;
}
/**
 自定义 “唯一约束” 函数,如果需要 “唯一约束”,则在自定类中自己实现该函数.
 @return 返回值是 “唯一约束” 的字段名(即相对应的变量名).
 */
-(NSString *)uniqueKey{
    return nil;
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
 覆盖掉原来的数据,只存储当前的数据.
 @async YES:异步存储,NO:同步存储.
 */
-(void)coverAsync:(BOOL)async complete:(Complete_B)complete{
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess){
                if(isSuccess)
                [[BGFMDB shareManager] saveObject:self complete:complete];
                else
                !complete?:complete(isSuccess);
            }];
        });
    }else{
        [[BGFMDB shareManager] clearWithClass:[self class] complete:^(BOOL isSuccess) {
            if(isSuccess)
            [[BGFMDB shareManager] saveObject:self complete:complete];
            else
            !complete?:complete(isSuccess);
        }];
    }
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
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsync:(BOOL)async limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete{
    NSMutableString* param = [NSMutableString string];
    !(orderBy&&desc)?:[param appendFormat:@"order by %@%@ desc",BG,orderBy];
    !param.length?:[param appendString:@" "];
    !limit?:[param appendFormat:@"limit %ld",limit];
    param = param.length?param:nil;
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:complete];
        });
    }else{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:complete];
    }
}
/**
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @range 查询的范围(从location(大于或等于零)开始的后面length(大于零)条).
 @desc YES:降序，NO:升序.
 */
+(void)findAllAsync:(BOOL)async range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete{
    NSMutableString* param = [NSMutableString string];
    !(orderBy&&desc)?:[param appendFormat:@"order by %@%@ desc ",BG,orderBy];
    NSAssert((range.location>=0)&&(range.length>0),@"range参数错误,location应该大于或等于零,length应该大于零");
    [param appendFormat:@"limit %ld,%ld",range.location,range.length];
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:complete];
        });
    }else{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] where:nil param:param complete:complete];
    }
}
/**
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],可以为nil,为nil时查询所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持,keypath有专门的查询接口.
 */
+(void)findAsync:(BOOL)async where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] queryObjectWithClass:[self class] keys:nil where:where complete:complete];
        });
    }else{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] keys:nil where:where complete:complete];
    }
}
/**
 keyPath查询
 @async YES:异步查询所有结果,NO:同步查询所有结果.
 @keyPath 形式 @"user.student.name".
 @value 值,形式 @“小芳”
 说明: 即查询 user.student.name=小芳的对象数据 (用于嵌套的自定义类)
 */
+(void)findAsync:(BOOL)async forKeyPath:(NSString* _Nonnull)keyPath value:(id _Nonnull)value complete:(Complete_A)complete{
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] queryObjectWithClass:[self class] forKeyPath:keyPath value:value complete:complete];
        });
    }else{
        [[BGFMDB shareManager] queryObjectWithClass:[self class] forKeyPath:keyPath value:value complete:complete];
    }
}
/**
 同步更新数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据.
 可以为nil,nil时更新所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(BOOL)updateWhere:(NSArray* _Nullable)where{
    __block BOOL result;
    [[BGFMDB shareManager] updateWithObject:self where:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 @async YES:异步更新,NO:同步更新.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;
 可以为nil,nil时更新所有数据;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.
 */
-(void)updateAsync:(BOOL)async where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    if(async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] updateWithObject:self where:where complete:complete];
        });
    }else{
        [[BGFMDB shareManager] updateWithObject:self where:where complete:complete];
    }
}
/**
 同步删除数据.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持
 */
+(BOOL)deleteWhere:(NSArray* _Nonnull)where{
    __block BOOL result;
    [[BGFMDB shareManager] deleteWithClass:[self class] where:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 @async YES:异步删除,NO:同步删除.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.
 不可以为nil;
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"] 暂不支持
 */
+(void)deleteAsync:(BOOL)async where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    if(async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] deleteWithClass:[self class] where:where complete:complete];
        });
    }else{
        [[BGFMDB shareManager] deleteWithClass:[self class] where:where complete:complete];
    }
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
 @async YES:异步清除所有数据,NO:同步清除所有数据.
 */
+(void)clearAsync:(BOOL)async complete:(Complete_B)complete{
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] clearWithClass:[self class] complete:complete];
        });
    }else{
        [[BGFMDB shareManager] clearWithClass:[self class] complete:complete];
    }
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
 @async YES:异步删除这个类的数据表,NO:同步删除这个类的数据表.
 */
+(void)dropAsync:(BOOL)async complete:(Complete_B)complete{
    if (async) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] dropWithClass:[self class] complete:complete];
        });
    }else{
        [[BGFMDB shareManager] dropWithClass:[self class] complete:complete];
    }
}
/**
 查询该表中有多少条数据
 @name 表名称.
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.
 */
+(NSInteger)countWhere:(NSArray* _Nullable)where{
    return [[BGFMDB shareManager] countForTable:NSStringFromClass([self class]) where:where];
}
/**
 刷新,当类变量名称改变时,调用此接口刷新一下.
 @async YES:异步刷新,NO:同步刷新.
 */
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
 将某表的数据拷贝给另一个表
 @async YES:异步复制,NO:同步复制.
 @destCla 目标类.
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,以此推类.
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.
 */
+(void)copyAsync:(BOOL)async toClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete{
    if(async){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[BGFMDB shareManager] copyClass:[self class] to:destCla keyDict:keydict append:append complete:complete];
        });
    }else{
        [[BGFMDB shareManager] copyClass:[self class] to:destCla keyDict:keydict append:append complete:complete];
    }
}

@end
