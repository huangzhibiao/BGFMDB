//
//  BGFMDBConfig.h
//  BGFMDB
//
//  Created by biao on 2017/7/19.
//  Copyright © 2017年 Biao. All rights reserved.
//

#ifndef BGFMDBConfig_h
#define BGFMDBConfig_h

// 过期方法注释
#define BGFMDBDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)

#define bg_primaryKey @"bg_id"
#define bg_createTimeKey @"bg_createTime"
#define bg_updateTimeKey @"bg_updateTime"

//keyPath查询用的关系，bg_equal:等于的关系；bg_contains：包含的关系.
#define bg_equal @"Relation_Equal"
#define bg_contains @"Relation_Contains"

#define bg_complete_B void(^_Nullable)(BOOL isSuccess)
#define bg_complete_I void(^_Nullable)(bg_dealState result)
#define bg_complete_A void(^_Nullable)(NSArray* _Nullable array)
#define bg_changeBlock void(^_Nullable)(bg_changeState result)

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
/**
 转换OC对象成数据库数据.
 */
extern NSString* _Nonnull bg_sqlValue(id _Nonnull value);
/**
 根据keyPath和Value的数组, 封装成数据库语句，来操作库.
 */
extern NSString* _Nonnull bg_keyPathValues(NSArray* _Nonnull keyPathValues);
/**
 直接执行sql语句;
 @tablename nil时以cla类名为表名.
 @cla 要操作的类,nil时返回的结果是字典.
 提示：字段名要增加BG_前缀
 */
extern id _Nullable bg_executeSql(NSString* _Nonnull sql,NSString* _Nullable tablename,__unsafe_unretained _Nullable Class cla);
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
 手动关闭数据库.
 */
extern void bg_closeDB();
/**
 设置调试模式
 @debug YES:打印调试信息, NO:不打印调试信息.
 */
extern void bg_setDebug(BOOL debug);

/**
 事务操作.
 @return 返回YES提交事务, 返回NO回滚事务.
 */
extern void bg_inTransaction(BOOL (^ _Nonnull block)());

/**
 清除缓存
 */
extern void bg_cleanCache();

#endif /* BGFMDBConfig_h */
