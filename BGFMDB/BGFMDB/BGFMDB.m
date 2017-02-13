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
 json字符转json格式数据 .
 */
-(id )jsonWithString:(NSString* _Nonnull)jsonString {
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
 字典转json字符 .
 */
-(NSString*)dataToJson:(id _Nonnull)data
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


-(instancetype)init{
    self = [super init];
    if (self) {
        // 0.获得沙盒中的数据库文件名
        NSString *filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SQLITE_NAME];
        // 1.创建数据库队列
        self.queue = [FMDatabaseQueue databaseQueueWithPath:filename];
        //NSLog(@"数据库初始化-----");
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

/**
 数据库中是否存在表.
 */
-(void)isExistWithTableName:(NSString* _Nonnull)name complete:(void (^_Nonnull)(BOOL isExist))complete{
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
 创建表(如果存在则不创建).
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray* _Nonnull)keys primaryKey:(NSString* _Nullable)primarykey complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
    [self.queue inDatabase:^(FMDatabase *db){
        NSString* header = [NSString stringWithFormat:@"create table if not exists %@ (",name];
        NSMutableString* sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        for(int i=0;i<keys.count;i++){
            
            if(primarykey){
                if([primarykey isEqualToString:keys[i]]){
                    [sql appendFormat:@"%@ text primary key",keys[i]];
                }else{
                    [sql appendFormat:@"%@ text",keys[i]];
                }
            }else{
                [sql appendFormat:@"%@ text",keys[i]];
            }
            
            if (i == (keys.count-1)) {
                [sql appendString:@");"];
            }else{
                [sql appendString:@","];
            }
        }NSLog(@"建表语句 = %@",sql);
        result = [db executeUpdate:sql];
    }];
    if (complete){
        complete(result);
    }
}
/**
 插入数据.
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 根据条件查询字段.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray* _Nullable)keys where:(NSArray* _Nullable)where complete:(void (^_Nonnull)(NSArray* _Nullable array))complete{
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
 全部查询.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name param:(NSString* _Nullable)param complete:(void (^ _Nonnull )(NSArray*_Nullable array))complete{
    if (name==nil){
        NSLog(@"表名不能为空!");
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    __block NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL;
        if (param) {
            SQL = [NSString stringWithFormat:@"select * from %@ %@",name,param];
        }else{
            SQL = [NSString stringWithFormat:@"select * from %@",name];
        }
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
 更新数据.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 根据条件删除数据.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 根据表名删除表格全部内容.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 删除表.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 动态添加表字段.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
//根据类获取变量名列表.
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
//判断类的变量名是否变更,然后改变表字段结构.
-(void)changeTableWhenClassIvarChange:(__unsafe_unretained Class)cla{
    NSString* tableName = [NSString stringWithFormat:@"%@",cla];
    NSMutableArray* newKeys = [NSMutableArray array];
    __weak typeof(self) BGSelf = self;
    [self.queue inDatabase:^(FMDatabase *db){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        NSArray* keys = [strongSelf getClassIvarList:cla];
        for (NSString* key in keys) {
            if(![db columnExists:key inTableWithName:tableName]){
                [newKeys addObject:key];
            }
        }
    }];
    
    //写在外面是为了防止数据库队列发生死锁.
    for(NSString* key in newKeys){
        //添加新字段
        [self addTable:tableName key:key complete:^(BOOL isSuccess){
            if (isSuccess) {
                NSLog(@"添加表字段成功 = %@",key);
            }else{
                NSLog(@"添加表字段失败! = %@",key);
            }
        }];
    }
}
/**
 处理插入的字典数据并返回
 */
-(void)insertDictWithObject:(id)object complete:(void (^_Nonnull)(BOOL isSuccess))complete{
    
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
        //获取成员变量的数据类型
        NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)];
        if ([type containsString:@"@"]) {
            type = [type substringWithRange:NSMakeRange(2,type.length-3)];
        }
        //NSLog(@"key = %@ , type : %@", key,type);
        if([type isEqualToString:@"NSArray"]){
            NSString* jsonStr = [NSString stringWithFormat:@"NSArray%@",[self dataToJson:[object valueForKey:key]]];
            [dictM setValue:jsonStr forKey:key];
        }else if([type isEqualToString:@"NSDictionary"]){
            NSString* jsonStr = [NSString stringWithFormat:@"NSDictionary%@",[self dataToJson:[object valueForKey:key]]];
            [dictM setValue:jsonStr forKey:key];
        }else{
            Class cla = NSClassFromString(type);
            //NSLog(@"父类 = %@",NSStringFromClass([cla superclass]));
            if ([@"BGManageObject" isEqualToString:NSStringFromClass([cla superclass])]){
                NSString* jsonString = [self jsonWithObject:[object valueForKey:key]];
                [dictM setValue:jsonString forKey:key];
            }else{
                //setObject:ForKey: object cannot be nil but setValue:ForKey: can;
                [dictM setValue:([object valueForKey:key]==nil)?@"0":[object valueForKey:key] forKey:key];
            }
        }
        
    }
    free(vars);//释放资源
    
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    __weak typeof(self) BGSelf = self;
    [self insertIntoTableName:tableName Dict:dictM complete:^(BOOL isSuccess){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (isSuccess) {
            if (complete) {
                complete(isSuccess);
            }
        }else{
            //检查表字段是否有改变
            [strongSelf changeTableWhenClassIvarChange:[object class]];
            [strongSelf insertIntoTableName:tableName Dict:dictM complete:complete];
        }
    }];

}
//转换变量数据(插入时)
-(NSString*)jsonWithObject:(id)object{
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
        //获取成员变量的数据类型
        NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)];
        if ([type containsString:@"@"]) {
            type = [type substringWithRange:NSMakeRange(2,type.length-3)];
        }
        //NSLog(@"variable type :%@", type);
        if([type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSDictionary"]){
            NSString* jsonStr = [self dataToJson:[object valueForKey:key]];
            [dictM setValue:[NSString stringWithFormat:@"BGJSON%@",jsonStr] forKey:key];
        }else{
            Class cla = NSClassFromString(type);
            //NSLog(@"父类 = %@",NSStringFromClass([cla superclass]));
            if ([@"BGManageObject" isEqualToString:NSStringFromClass([cla superclass])]){
                NSString* jsonString = [self jsonWithObject:[object valueForKey:key]];
                [dictM setValue:jsonString forKey:key];
            }else{
                //setValue:ForKey: object cannot be nil
                [dictM setValue:([object valueForKey:key]==nil)?@"0":[object valueForKey:key] forKey:key];
            }
        }
        
    }
    free(vars);//释放资源
    NSString* result = [NSString stringWithFormat:@"BGManageObject%@%@",NSStringFromClass([object class]),[self dataToJson:dictM]];
    //NSLog(@"结果 = %@",result);
    return result;
}
/**
 存储一个对象.
 */
-(void)saveObject:(id _Nonnull)object complete:(void (^_Nonnull)(BOOL isSuccess))complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就新建
            [strongSelf createTableWithTableName:tableName keys:[strongSelf getClassIvarList:[object class]] primaryKey:nil complete:^(BOOL isSuccess) {
                if (isSuccess){
                    NSLog(@"建表成功 第一次建立 %@ 对应的表",tableName);
                }
            }];
        }
        
        //插入数据
        [strongSelf insertDictWithObject:object complete:complete];
    }];
}

//数组转换(读取数据时).
-(NSArray*)translateResult:(__unsafe_unretained Class)cla with:(NSArray*)array{
    
    NSArray* keys = [self getClassIvarList:cla];
    NSMutableArray* arrM = [NSMutableArray array];
    for(NSDictionary* dict in array){
        id claObj = [[cla alloc] init];
        for(NSString* key in keys){
            if (!dict[key])continue;
            
            if([[NSString stringWithFormat:@"%@",dict[key]] containsString:@"NSArray"]){
                NSArray* tempArrM = [self jsonWithString:[[NSString stringWithFormat:@"%@",dict[key]] stringByReplacingOccurrencesOfString:@"NSArray" withString:@""]];
                [claObj setValue:tempArrM forKey:key];
            }else if ([[NSString stringWithFormat:@"%@",dict[key]] containsString:@"NSDictionary"]){
                NSDictionary* jsonDict = [self jsonWithString:[[NSString stringWithFormat:@"%@",dict[key]] stringByReplacingOccurrencesOfString:@"NSDictionary" withString:@""]];
                [claObj setValue:jsonDict forKey:key];
            }else if([[NSString stringWithFormat:@"%@",dict[key]] containsString:@"BGManageObject"]){
                [claObj setValue:[self objectWithJsonString:dict[key]] forKey:key];
            }else{
             [claObj setValue:dict[key] forKey:key];
            }
        }
        [arrM addObject:claObj];
    }
    
    return arrM;
}

/**
 转换变量对象数据(读取数据时)
 */

-(id)objectWithJsonString:(NSString*)jsonString{
    
    NSString* str = [jsonString stringByReplacingOccurrencesOfString:@"BGManageObject" withString:@""];
    NSString* claName = [str substringToIndex:[str rangeOfString:@"{"].location];
    str = [jsonString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"BGManageObject%@",claName] withString:@""];
    NSDictionary* dict = [self jsonWithString:str];
    Class cla = NSClassFromString(claName);
    id claObject = [[cla alloc] init];
    NSArray* keys = [self getClassIvarList:cla];
    for(NSString* key in keys){
        if (!dict[key])continue;
        
        NSString* value = [NSString stringWithFormat:@"%@",dict[key]];
        if([value containsString:@"BGManageObject"]){
            [claObject setValue:[self objectWithJsonString:value] forKey:key];
        }else if([value containsString:@"BGJSON"]){
            [claObject setValue:[self jsonWithString:[value stringByReplacingOccurrencesOfString:@"BGJSON" withString:@""]] forKey:key];
        }else{
            [claObject setValue:dict[key] forKey:key];
        }
    }
    return claObject;
}

/**
 查询全部对象.
 */
-(void)queryAllObject:(__unsafe_unretained _Nonnull Class)cla param:(NSString* _Nullable)param complete:(void (^_Nonnull)(NSArray* _Nullable array))complete{
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
            [strongSelf queryWithTableName:tableName param:param complete:^(NSArray *array) {
                NSArray* arrM = [secondSelf translateResult:cla with:array];
                if (complete) {
                    complete(arrM);
                }
            }];
        }
    }];
}
/**
 根据条件查询某个对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray* _Nullable)keys where:(NSArray* _Nullable)where complete:(void (^_Nullable)(NSArray* _Nullable array))complete{
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
 根据条件改变对象的值.
 */
-(void)updateWithClass:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 根据条件删除对象表中的对象数据.
 */
-(void)deleteWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 根据类删除此类所有表数据.
 */
-(void)clearWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
 根据类,删除这个类的表.
 */
-(void)dropWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(void (^_Nonnull)(BOOL isSuccess))complete{
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
