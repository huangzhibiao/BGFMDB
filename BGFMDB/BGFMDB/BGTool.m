//
//  BGTool.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "BGTool.h"
#import "BGManageObject.h"
#import <objc/runtime.h>

@implementation BGTool

/**
 json字符转json格式数据 .
 */
+(id)jsonWithString:(NSString* _Nonnull)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    
    NSAssert(!err,@"json解析失败");
    return dic;
}
/**
 字典转json字符 .
 */
+(NSString*)dataToJson:(id _Nonnull)data
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


//转换变量数据(插入时)
+(NSString*)jsonWithObject:(id)object{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    unsigned int numIvars; //成员变量个数
    Ivar *vars = class_copyIvarList([object class], &numIvars);
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        NSString *key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名字
        if ([key containsString:@"_"]) {
            key = [key substringFromIndex:1];
        }
        if (![object valueForKey:key])continue;
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
        }else if(type.length==1){//assign类型的
            [dictM setValue:[object valueForKey:key]?[object valueForKey:key]:0 forKey:key];
        }else{
            //判断是不是BGManageObject的子类
            if ([NSClassFromString(type) isSubclassOfClass:[BGManageObject class]]){
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
 将一个对象的变量值转化为字典返回
 */
+(NSDictionary*)dictionaryWithObject:(id)object{
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
        }else if(type.length==1){//assign类型的
            [dictM setValue:[object valueForKey:key]?[object valueForKey:key]:0 forKey:key];
        }else{
            //判断是不是BGManageObject的子类
            if ([NSClassFromString(type) isSubclassOfClass:[BGManageObject class]]){
                NSString* jsonString = [self jsonWithObject:[object valueForKey:key]];
                [dictM setValue:jsonString forKey:key];
            }else{
                //setObject:ForKey: object cannot be nil but setValue:ForKey: can;
                [dictM setValue:([object valueForKey:key]==nil)?@"0":[object valueForKey:key] forKey:key];
            }
        }
        
    }
    free(vars);//释放资源
    return dictM;
}


//数组转换(读取数据时).
+(NSArray*)translateResult:(__unsafe_unretained Class)cla with:(NSArray*)array{
    
    NSArray* keys = [self getClassIvarList:cla onlyKey:NO];
    NSMutableArray* arrM = [NSMutableArray array];
    for(NSDictionary* dict in array){
        id claObj = [[cla alloc] init];
        for(NSString* keyAndType in keys){
            NSArray* arrs = [keyAndType componentsSeparatedByString:@"*"];
            NSString* key = arrs[0];
            NSString* type = arrs[1];
            
            if (!dict[key] ||[dict[key] isKindOfClass:[NSNull class]])continue;
            
            if ([type containsString:@"@"]) {
                type = [type substringWithRange:NSMakeRange(2,type.length-3)];
            }
            
            if([type isEqualToString:@"NSArray"]){
                NSArray* tempArrM = [self jsonWithString:[[NSString stringWithFormat:@"%@",dict[key]] stringByReplacingOccurrencesOfString:@"NSArray" withString:@""]];
                [claObj setValue:tempArrM forKey:key];
            }else if ([type isEqualToString:@"NSDictionary"]){
                NSDictionary* jsonDict = [self jsonWithString:[[NSString stringWithFormat:@"%@",dict[key]] stringByReplacingOccurrencesOfString:@"NSDictionary" withString:@""]];
                [claObj setValue:jsonDict forKey:key];
            }else if([NSClassFromString(type) isSubclassOfClass:[BGManageObject class]]){
                [claObj setValue:[self objectWithJsonString:dict[key]] forKey:key];
            }else if([type isEqualToString:@"NSNumber"]){
                [claObj setValue:[[NSNumberFormatter new] numberFromString:dict[key]] forKey:key];
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
+(id)objectWithJsonString:(NSString*)jsonString{
    
    NSString* str = [jsonString stringByReplacingOccurrencesOfString:@"BGManageObject" withString:@""];
    NSString* claName = [str substringToIndex:[str rangeOfString:@"{"].location];
    str = [jsonString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"BGManageObject%@",claName] withString:@""];
    NSDictionary* dict = [self jsonWithString:str];
    Class cla = NSClassFromString(claName);
    id claObject = [[cla alloc] init];
    NSArray* keys = [self getClassIvarList:cla onlyKey:YES];
    for(NSString* key in keys){
        if (!dict[key] ||[dict[key] isKindOfClass:[NSNull class]])continue;
        
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
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+(NSArray*)getClassIvarList:(__unsafe_unretained Class)cla onlyKey:(BOOL)onlyKey{
    unsigned int numIvars; //成员变量个数
    Ivar *vars = class_copyIvarList(cla, &numIvars);
    NSMutableArray* keys = [NSMutableArray array];
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        NSString* key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名
        if ([key containsString:@"_"]) {
            key = [key substringFromIndex:1];
        }
        if (!onlyKey) {
            //获取成员变量的数据类型
            NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)];
            key = [NSString stringWithFormat:@"%@*%@",key,type];
            //NSLog(@"key = %@ , type = %@",key,type);
        }
        [keys addObject:key];//存储对象的变量名
    }
    free(vars);//释放资源
    return keys;
}

/**
 抽取封装条件数组处理函数
 */
+(NSArray*)where:(NSArray*)where{
    NSMutableArray* results = [NSMutableArray array];
    NSMutableString* SQL = [NSMutableString string];
    if(!(where.count%3)){
        [SQL appendString:@" where "];
        for(int i=0;i<where.count;i+=3){
            [SQL appendFormat:@"%@%@?",where[i],where[i+1]];
            if (i != (where.count-3)) {
                [SQL appendString:@" and "];
            }
        }
    }else{
        //NSLog(@"条件数组错误!");
        NSAssert(NO,@"条件数组错误!");
    }
    NSMutableArray* wheres = [NSMutableArray array];
    for(int i=0;i<where.count;i+=3){
        [wheres addObject:where[i+2]];
    }
    [results addObject:SQL];
    [results addObject:wheres];
    return results;
}

/**
 判断是不是主键
 */
+(BOOL)isPrimary:(NSString*)primary with:(NSString*)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    return [param isEqualToString:key];
}
/**
 判断并获取字段类型
 */
+(NSString*)keyAndType:(NSString*)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    NSString* type = array[1];
    NSString* SqlType;
    type = [self getSqlType:type];
    if ([SqlText isEqualToString:type]) {
        SqlType = SqlText;
    }else if ([SqlReal isEqualToString:type]){
        SqlType = SqlReal;
    }else if ([SqlInteger isEqualToString:type]){
        SqlType = SqlInteger;
    }else{
        SqlType = SqlText;
    }
    return [NSString stringWithFormat:@"%@ %@",key,SqlType];
}

+(NSString*)getSqlType:(NSString*)type{
    if ([type containsString:@"@"]) {
        return SqlText;
    }else{
        if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
           [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
           [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]) {
            return SqlInteger;
        }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
                 [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
            return SqlReal;
        }else{
            return SqlText;
        }
    }
}

@end
