//
//  BGTool.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "BGTool.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#define SqlText @"text" //数据库的字符类型
#define SqlReal @"real" //数据库的浮点类型
#define SqlInteger @"integer" //数据库的整数类型
//#define SqlBlob @"blob" //数据库的二进制类型

#define BGValue @"BGValue"
#define BGArray @"BGArray"
#define BGSet @"BGSet"
#define BGDictionary @"BGDictionary"
#define BGModel @"BGModel"
#define BGMapTable @"BGMapTable"
#define BGHashTable @"BGHashTable"

Relation const Equal = @"Relation_Equal";
Relation const Contains = @"Relation_Contains";
@implementation BGTool

/**
 封装处理传入数据库的key和value.
 */
NSString* sqlKey(NSString* key){
    return [NSString stringWithFormat:@"%@%@",BG,key];
}
NSString* sqlValue(id value){
    if ([value isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"'%@'",value];
    }else{
        return value;
    }
}
/**
 根据keyPath和Value的数组, 封装成数据库语句，来操作库.
 */
NSString* keyPathValues(NSArray* keyPathValues){
    return [BGTool getLikeWithKeyPathAndValues:keyPathValues where:NO];
}
/**
 json字符转json格式数据 .
 */
+(id)jsonWithString:(NSString*)jsonString {
    NSAssert(jsonString,@"数据不能为空!");
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
+(NSString*)dataToJson:(id)data{
    NSAssert(data,@"数据不能为空!");
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+(NSArray*)getClassIvarList:(__unsafe_unretained Class)cla onlyKey:(BOOL)onlyKey{
    unsigned int numIvars; //成员变量个数
    Ivar *vars = class_copyIvarList(cla, &numIvars);
    NSMutableArray* keys = [NSMutableArray array];
    [keys addObject:[NSString stringWithFormat:@"%@*q",primaryKey]];//手动添加库自带的自动增长主键ID和类型q
    for(int i = 0; i < numIvars; i++) {
        Ivar thisIvar = vars[i];
        NSString* key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名
        if ([key containsString:@"_"]) {
            key = [key substringFromIndex:1];
        }
        if (!onlyKey) {
            //获取成员变量的数据类型
            NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)];
            //NSLog(@"key = %@ , type = %@",key,type);
            key = [NSString stringWithFormat:@"%@*%@",key,type];
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
            [SQL appendFormat:@"%@%@%@?",BG,where[i],where[i+1]];
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
 封装like语句获取函数
 */
+(NSString*)getLikeWithKeyPathAndValues:(NSArray* _Nonnull)keyPathValues where:(BOOL)where{
    NSAssert(keyPathValues,@"集合不能为空!");
    NSAssert(!(keyPathValues.count%3),@"集合格式错误!");
    NSMutableArray* keys = [NSMutableArray array];
    NSMutableArray* values = [NSMutableArray array];
    NSMutableArray* relations = [NSMutableArray array];
    for(int i=0;i<keyPathValues.count;i+=3){
        [keys addObject:keyPathValues[i]];
        [relations addObject:keyPathValues[i+1]];
        [values addObject:keyPathValues[i+2]];
    }
    NSMutableString* likeM = [NSMutableString string];
    !where?:[likeM appendString:@" where "];
    for(int i=0;i<keys.count;i++){
        NSString* keyPath = keys[i];
        id value = values[i];
        NSAssert([keyPath containsString:@"."], @"keyPath错误,正确形式如: user.stident.name");
        NSArray* keypaths = [keyPath componentsSeparatedByString:@"."];
        NSMutableString* keyPathParam = [NSMutableString string];
        for(int i=1;i<keypaths.count;i++){
            i!=1?:[keyPathParam appendString:@"%"];
            [keyPathParam appendFormat:@"%@",keypaths[i]];
            [keyPathParam appendString:@"%"];
        }
        [keyPathParam appendFormat:@"%@",value];
        if ([relations[i] isEqualToString:Contains]){//包含关系
            [keyPathParam appendString:@"%"];
        }else{
            keypaths.count<=2?[keyPathParam appendString:@"\"%"]:[keyPathParam appendString:@"\\%"];
        }
        [likeM appendFormat:@"%@%@ like '%@'",BG,keypaths[0],keyPathParam];
        if(i != (keys.count-1)){
            [likeM appendString:@" and "];
        }
    }
    return likeM;
}

/**
 判断是不是 "唯一约束" 字段.
 */
+(BOOL)isUniqueKey:(NSString*)uniqueKey with:(NSString*)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    return [uniqueKey isEqualToString:key];
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
        NSAssert(NO,@"没有找到匹配的类型!");
    }
    //设置列名(BG_ + 属性名),加BG_是为了防止和数据库关键字发生冲突.
    return [NSString stringWithFormat:@"%@ %@",[NSString stringWithFormat:@"%@%@",BG,key],SqlType];
}

+(NSString*)getSqlType:(NSString*)type{
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
             [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
             [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
             [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
             [type isEqualToString:@"c"]||[type isEqualToString:@"C"]|
             [type isEqualToString:@"l"]||[type isEqualToString:@"L"]) {
        return SqlInteger;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return SqlReal;
    }else{
        return SqlText;
    }
}
//对象转json字符
+(NSString *)jsonStringWithObject:(id)object{
    NSMutableDictionary* keyValueDict = [NSMutableDictionary dictionary];
    NSArray* keyAndTypes = [BGTool getClassIvarList:[object class] onlyKey:NO];
    for(NSString* keyAndType in keyAndTypes){
        NSArray* arr = [keyAndType componentsSeparatedByString:@"*"];
        NSString* propertyName = arr[0];
        NSString* propertyType = arr[1];
        if(![propertyName isEqualToString:primaryKey]){
            id propertyValue = [object valueForKey:propertyName];
            if (propertyValue){
                id Value = [self getSqlValue:propertyValue type:propertyType encode:YES];
                keyValueDict[propertyName] = Value;
            }
        }
    }
    return [self dataToJson:keyValueDict];
}
//根据value类型返回用于数组插入数据库的NSDictionary
+(NSDictionary*)dictionaryForArrayInsert:(id)value{
    
    if ([value isKindOfClass:[NSArray class]]){
        return @{BGArray:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSSet class]]){
        return @{BGSet:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]){
        return @{BGValue:value};
    }else if ([value isKindOfClass:[NSDictionary class]]){
        return @{BGDictionary:[self jsonStringWithDictionary:value]};
    }else if ([value isKindOfClass:[NSMapTable class]]){
        return @{BGMapTable:[self jsonStringWithMapTable:value]};
    }else if([value isKindOfClass:[NSHashTable class]]){
        return @{BGHashTable:[self jsonStringWithNSHashTable:value]};
    }else{
        NSString* modelKey = [NSString stringWithFormat:@"%@*%@",BGModel,NSStringFromClass([value class])];
        return @{modelKey:[self jsonStringWithObject:value]};
    }
    
}
//NSArray,NSSet转json字符
+(NSString*)jsonStringWithArray:(id)array{
    if ([NSJSONSerialization isValidJSONObject:array]) {
        return [self dataToJson:array];
    }else{
        NSMutableArray* arrM = [NSMutableArray array];
        for(id value in array){
            [arrM addObject:[self dictionaryForArrayInsert:value]];
        }
        return [self dataToJson:arrM];
    }
}

//根据value类型返回用于字典插入数据库的NSDictionary
+(NSDictionary*)dictionaryForDictionaryInsert:(id)value{
    if ([value isKindOfClass:[NSArray class]]){
        return @{BGArray:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSSet class]]){
        return @{BGSet:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]){
        return @{BGValue:value};
    }else if ([value isKindOfClass:[NSDictionary class]]){
        return @{BGDictionary:[self jsonStringWithDictionary:value]};
    }else if ([value isKindOfClass:[NSMapTable class]]){
        return @{BGMapTable:[self jsonStringWithMapTable:value]};
    }else if ([value isKindOfClass:[NSHashTable class]]){
        return @{BGHashTable:[self jsonStringWithNSHashTable:value]};
    }else{
        NSString* modelKey = [NSString stringWithFormat:@"%@*%@",BGModel,NSStringFromClass([value class])];
        return @{modelKey:[self jsonStringWithObject:value]};
    }
}
//字典转json字符串.
+(NSString*)jsonStringWithDictionary:(NSDictionary*)dictionary{
    if ([NSJSONSerialization isValidJSONObject:dictionary]) {
        return [self dataToJson:dictionary];
    }else{
        NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
        for(NSString* key in dictionary.allKeys){
            dictM[key] = [self dictionaryForDictionaryInsert:dictionary[key]];
        }
        return [self dataToJson:dictM];
    }

}
//NSMapTable转json字符串.
+(NSString*)jsonStringWithMapTable:(NSMapTable*)mapTable{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    NSArray* objects = mapTable.keyEnumerator.allObjects;
    NSArray* keys = mapTable.objectEnumerator.allObjects;
    for(int i=0;i<objects.count;i++){
        dictM[keys[i]] = [self dictionaryForDictionaryInsert:objects[i]];
    }
    return [self dataToJson:dictM];
}
//NSHashTable转json字符串.
+(NSString*)jsonStringWithNSHashTable:(NSHashTable*)hashTable{
    NSMutableArray* arrM = [NSMutableArray array];
    NSArray* values = hashTable.objectEnumerator.allObjects;
    for(id value in values){
        [arrM addObject:[self dictionaryForArrayInsert:value]];
    }
    return  [self dataToJson:arrM];
}
//NSDate转json字符串.
+(NSString*)jsonStringWithDate:(NSDate*)date{
    NSDateFormatter* formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:date];
}
//跟value和数据类型type 和编解码标志 返回编码插入数据库的值,或解码数据库的值.
+(id)getSqlValue:(id)value type:(NSString*)type encode:(BOOL)encode{
    if(!value || [value isKindOfClass:[NSNull class]])return nil;
    
    if([type containsString:@"NSString"]||[type containsString:@"NSMutableString"]){
        return value;
    }else if([type containsString:@"NSNumber"]||[type containsString:@"NSMutableNumber"]){
        if(encode) {
            return [NSString stringWithFormat:@"%@",value];
        }else{
            return [[NSNumberFormatter new] numberFromString:value];
        }
    }else if([type containsString:@"NSArray"]||[type containsString:@"NSMutableArray"]){
        if(encode){
            return [self jsonStringWithArray:value];
        }else{
            return [self arrayFromJsonString:value];
        }
    }else if([type containsString:@"NSDictionary"]||[type containsString:@"NSMutableDictionary"]){
        if(encode){
            return [self jsonStringWithDictionary:value];
        }else{
            return [self dictionaryFromJsonString:value];
        }
    }else if([type containsString:@"NSSet"]||[type containsString:@"NSMutableSet"]){
        if(encode){
            return [self jsonStringWithArray:value];
        }else{
            return [self arrayFromJsonString:value];
        }
    }else if([type containsString:@"NSData"]||[type containsString:@"NSMutableData"]){
        if(encode){
            NSData* data = value;
            NSNumber* maxLength = @(838860800);
            NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else{
            return [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }
    }else if([type containsString:@"NSMapTable"]){
        if(encode){
            return [self jsonStringWithMapTable:value];
        }else{
            return [self mapTableFromJsonString:value];
        }
    }else if ([type containsString:@"NSHashTable"]){
        if(encode){
            return [self jsonStringWithNSHashTable:value];
        }else{
            return [self hashTableFromJsonString:value];
        }
    }else if ([type containsString:@"NSDate"]){
        if(encode){
            return [self jsonStringWithDate:value];
        }else{
            return [self dateFromJsonString:value];
        }
    }else if ([type containsString:@"NSURL"]){
        if(encode){
            return [value absoluteString];
        }else{
            return [NSURL URLWithString:value];
        }
    }else if ([type containsString:@"UIImage"]){
        if(encode){
            NSData* data = UIImageJPEGRepresentation(value, 1);
            NSNumber* maxLength = @(838860800);
            NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else{
            return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        }
    }else if ([type containsString:@"UIColor"]){
        if(encode){
            CGFloat r, g, b, a;
            [value getRed:&r green:&g blue:&b alpha:&a];
            return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
        }else{
            NSArray<NSString*>* arr = [value componentsSeparatedByString:@","];
            return [UIColor colorWithRed:arr[0].floatValue green:arr[1].floatValue blue:arr[2].floatValue alpha:arr[3].floatValue];
        }
    }else if ([type containsString:@"NSRange"]){
        if(encode){
            return NSStringFromRange([value rangeValue]);
        }else{
            return [NSValue valueWithRange:NSRangeFromString(value)];
        }
    }else if ([type containsString:@"CGRect"]&&[type containsString:@"CGPoint"]&&[type containsString:@"CGSize"]){
        if(encode){
            return NSStringFromCGRect([value CGRectValue]);
        }else{
            return [NSValue valueWithCGRect:CGRectFromString(value)];
        }
    }else if (![type containsString:@"CGRect"]&&[type containsString:@"CGPoint"]&&![type containsString:@"CGSize"]){
        if(encode){
            return NSStringFromCGPoint([value CGPointValue]);
        }else{
            return [NSValue valueWithCGPoint:CGPointFromString(value)];
        }
    }else if (![type containsString:@"CGRect"]&&![type containsString:@"CGPoint"]&&[type containsString:@"CGSize"]){
        if(encode){
            return NSStringFromCGSize([value CGSizeValue]);
        }else{
            return [NSValue valueWithCGSize:CGSizeFromString(value)];
        }
    }else if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
             [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
             [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
             [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
             [type isEqualToString:@"c"]||[type isEqualToString:@"C"]||
             [type isEqualToString:@"l"]||[type isEqualToString:@"L"]){
        return value;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return value;
    }else{
        if(encode){
            NSString* jsonString = [self jsonStringWithObject:value];
            return jsonString;
        }else{
            NSDictionary* dict = [self jsonWithString:value];
            type = [type substringWithRange:NSMakeRange(2,type.length-3)];
            return [self objectFromJsonStringWithClassName:type valueDict:dict];
        }
    }
}

+(id)objectFromJsonStringWithClassName:(NSString*)claName valueDict:(NSDictionary*)valueDict{
    Class cla = NSClassFromString(claName);
    id object = [cla new];
    NSArray* valueDictKeys = valueDict.allKeys;
    NSArray* keyAndTypes = [self getClassIvarList:cla onlyKey:NO];
    for(NSString* keyAndType in keyAndTypes){
        NSArray* arrKT = [keyAndType componentsSeparatedByString:@"*"];
        for(NSString* valueKey in valueDictKeys){
            if ([valueKey isEqualToString:arrKT.firstObject]){
                id ivarValue = [self getSqlValue:valueDict[valueKey] type:arrKT.lastObject encode:NO];
                if(![arrKT.firstObject isEqualToString:primaryKey]){
                    [object setValue:ivarValue forKey:arrKT.firstObject];
                }else{
                    SEL primaryKeySel = NSSelectorFromString([NSString stringWithFormat:@"set%@:",primaryKey]);
                    [object performSelector:primaryKeySel withObject:ivarValue];
                }
            }
        }
    }
    
    return object;
}
//根据NSDictionary转换从数据库读取回来的数组数据
+(id)valueForArrayRead:(NSDictionary*)dictionary{
    
    NSString* key = dictionary.allKeys.firstObject;
    if ([key isEqualToString:BGValue]) {
        return dictionary[key];
    }else if([key isEqualToString:BGSet]){
        return [self arrayFromJsonString:dictionary[key]];
    }else if([key isEqualToString:BGArray]){
        return [self arrayFromJsonString:dictionary[key]];
    }else if ([key isEqualToString:BGDictionary]){
       return [self dictionaryFromJsonString:dictionary[key]];
    }else if ([key containsString:BGModel]){
        NSString* claName = [key componentsSeparatedByString:@"*"].lastObject;
        NSDictionary* valueDict = [self jsonWithString:dictionary[key]];
        id object = [self objectFromJsonStringWithClassName:claName valueDict:valueDict];
        return object;
    }else{
        NSAssert(NO,@"没有找到匹配的解析类型");
        return nil;
    }

}
//json字符串转NSArray
+(NSArray*)arrayFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    if([jsonString containsString:BGModel]){
        NSMutableArray* arrM = [NSMutableArray array];
        NSArray* array = [self jsonWithString:jsonString];
        for(NSDictionary* dict in array){
            [arrM addObject:[self valueForArrayRead:dict]];
        }
        return arrM;
    }else{
        return [self jsonWithString:jsonString];
    }
}

//根据NSDictionary转换从数据库读取回来的字典数据
+(id)valueForDictionaryRead:(NSDictionary*)dictDest{
    
    NSString* keyDest = dictDest.allKeys.firstObject;
    if([keyDest isEqualToString:BGValue]){
        return dictDest[keyDest];
    }else if([keyDest isEqualToString:BGSet]){
        return [self arrayFromJsonString:dictDest[keyDest]];
    }else if([keyDest isEqualToString:BGArray]){
        return [self arrayFromJsonString:dictDest[keyDest]];
    }else if([keyDest isEqualToString:BGDictionary]){
        return [self dictionaryFromJsonString:dictDest[keyDest]];
    }else if([keyDest containsString:BGModel]){
        NSString* claName = [keyDest componentsSeparatedByString:@"*"].lastObject;
        NSDictionary* valueDict = [self jsonWithString:dictDest[keyDest]];
        return [self objectFromJsonStringWithClassName:claName valueDict:valueDict];
    }else{
        NSAssert(NO,@"没有找到匹配的解析类型");
        return nil;
    }

}
//json字符串转NSDictionary
+(NSDictionary*)dictionaryFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    if([jsonString containsString:BGModel]){
        NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
        NSDictionary* dictSrc = [self jsonWithString:jsonString];
        for(NSString* keySrc in dictSrc.allKeys){
            NSDictionary* dictDest = dictSrc[keySrc];
            dictM[keySrc]= [self valueForDictionaryRead:dictDest];
        }
        return dictM;
    }else{
        return [self jsonWithString:jsonString];
    }
}
//json字符串转NSMapTable
+(NSMapTable*)mapTableFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    NSDictionary* dict = [self jsonWithString:jsonString];
    NSMapTable* mapTable = [NSMapTable new];
    for(NSString* key in dict.allKeys){
        id value = [self valueForDictionaryRead:dict[key]];
        [mapTable setObject:value forKey:key];
    }
    return mapTable;
}
//json字符串转NSHashTable
+(NSHashTable*)hashTableFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    NSArray* arr = [self jsonWithString:jsonString];
    NSHashTable* hashTable = [NSHashTable new];
    for (id obj in arr) {
        id value = [self valueForArrayRead:obj];
        [hashTable addObject:value];
    }
    return hashTable;
}
//json字符串转NSDate
+(NSDate*)dateFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    NSDate *date = [formatter dateFromString:jsonString];
    return date;
}
//转换从数据库中读取出来的数据.
+(NSArray*)tansformDataFromSqlDataWithTableName:(NSString*)tableName array:(NSArray*)array{
    NSMutableArray* arrM = [NSMutableArray array];
    for(NSDictionary* dict in array){
        NSArray* allNewKeys = dict.allKeys;
        NSMutableDictionary* newDictM = [NSMutableDictionary dictionary];
        for(NSString* newKey in allNewKeys){
            NSString* newDictKey = [newKey stringByReplacingOccurrencesOfString:BG withString:@""];
            newDictM[newDictKey] = dict[newKey];
        }
        id object = [BGTool objectFromJsonStringWithClassName:tableName valueDict:newDictM];
        [arrM addObject:object];
    }
    return arrM;
}
/**
 获取"唯一约束"
 */
+(NSString*)getUnique:(id)object{
    NSString* uniqueKey = nil;
    if([object respondsToSelector:NSSelectorFromString(@"uniqueKey")]){
        SEL uniqueKeySeltor = NSSelectorFromString(@"uniqueKey");
        uniqueKey = [object performSelector:uniqueKeySeltor];
    }
    return uniqueKey;
}
+(BOOL)getBoolWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}
+(void)setBoolWithKey:(NSString*)key value:(BOOL)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}
+(NSString*)getStringWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:key];
}
+(void)setStringWithKey:(NSString*)key value:(NSString*)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}
+(NSInteger)getIntegerWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:key];
}
+(void)setIntegerWithKey:(NSString*)key value:(NSInteger)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

@end
