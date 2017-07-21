//
//  BGFMDBConfig.h
//  BGFMDB
//
//  Created by biao on 2017/7/19.
//  Copyright © 2017年 Biao. All rights reserved.
//

#ifndef BGFMDBConfig_h
#define BGFMDBConfig_h

#define SQLITE_NAME @"BGFMDB.sqlite"

// 过期
#define BGFMDBDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)

// 日志输出
#ifdef DEBUG
#define BGLog(...) NSLog(__VA_ARGS__)
#else
#define BGLog(...)
#endif

#define debug(param) do{\
if(self.debug){BGLog(@"调试输出: %@",param);}\
}while(0)

#define BG @"BG_"
#define BGPrimaryKey @"bg_id"
#define BGCreateTime @"bg_createTime"
#define BGUpdateTime @"bg_updateTime"

//keyPath查询用的关系，bg_equal:等于的关系；bg_contains：包含的关系.
#define bg_equal @"Relation_Equal"
#define bg_contains @"Relation_Contains"

#define Complete_B void(^_Nullable)(BOOL isSuccess)
#define Complete_I void(^_Nullable)(bg_dealState result)
#define Complete_A void(^_Nullable)(NSArray* _Nullable array)
#define ChangeBlock void(^_Nullable)(bg_changeState result)

typedef NS_ENUM(NSInteger,bg_changeState){//数据改变状态
    bg_insert,//插入
    bg_update,//更新
    bg_delete,//删除
    bg_drop//删表
};

typedef NS_ENUM(NSInteger,bg_dealState){//处理状态
    bg_error = -1,//处理失败
    bg_incomplete = 0,//处理不完整
    bg_complete = 1//处理完整
};

typedef NS_ENUM(NSInteger,bg_sqliteMethodType){//sqlite数据库原生方法枚举
    bg_min,//求最小值
    bg_max,//求最大值
    bg_sum,//求总和值
    bg_avg//求平均值
};

typedef NS_ENUM(NSInteger,bg_dataTimeType){
    bg_createTime,//存储时间
    bg_updateTime,//更新时间
};

/**
 封装处理传入数据库的key和value.
 */
extern NSString* _Nonnull bg_sqlKey(NSString* _Nonnull key);
extern NSString* _Nonnull bg_sqlValue(id _Nonnull value);
/**
 根据keyPath和Value的数组, 封装成数据库语句，来操作库.
 */
extern NSString* _Nonnull bg_keyPathValues(NSArray* _Nonnull keyPathValues);

/**
 自定义数据库名称.
 */
extern void bg_setSqliteName(NSString*_Nonnull sqliteName);
/**
 删除数据库文件
 */
extern BOOL bg_deleteSqlite(NSString*_Nonnull sqliteName);
/**
 设置操作过程中不可关闭数据库(即closeDB函数无效).
 默认是NO.
 */
extern void bg_setDisableCloseDB(BOOL disableCloseDB);
/**
 设置调试模式
 @debug YES:打印调试信息, NO:不打印调试信息.
 */
extern void bg_setDebug(BOOL debug);

#endif /* BGFMDBConfig_h */
