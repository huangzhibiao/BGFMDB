//
//  BGModelInfo.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/22.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "BGModelInfo.h"
#import "BGTool.h"
#import "BGFMDBConfig.h"

@implementation BGModelInfo

+(NSArray<BGModelInfo*>*)modelInfoWithObject:(id)object{
    NSMutableArray* modelInfos = [NSMutableArray array];
    NSArray* keyAndTypes = [BGTool getClassIvarList:[object class] onlyKey:NO];
    for(NSString* keyAndType in keyAndTypes){
        NSArray* keyTypes = [keyAndType componentsSeparatedByString:@"*"];
        NSString* propertyName = keyTypes[0];
        NSString *propertyType = keyTypes[1];
        BGModelInfo* info = [BGModelInfo new];
        //设置属性名
        [info setValue:propertyName forKey:@"propertyName"];
        //设置属性类型
        [info setValue:propertyType forKey:@"propertyType"];
        //设置列名(BG_ + 属性名),加BG_是为了防止和数据库关键字发生冲突.
        [info setValue:[NSString stringWithFormat:@"%@%@",BG,propertyName] forKey:@"sqlColumnName"];
        //设置列属性
        NSString* sqlType = [BGTool getSqlType:propertyType];
        [info setValue:sqlType forKey:@"sqlColumnType"];
        //读取属性值
        if(![propertyName isEqualToString:bg_primaryKey]){
            
            id propertyValue;
            id sqlValue;
            //crateTime和updateTime两个额外字段单独处理.
            if([propertyName isEqualToString:bg_createTimeKey] ||
               [propertyName isEqualToString:bg_updateTimeKey]){
                propertyValue = [BGTool stringWithDate:[NSDate new]];
            }else{
                propertyValue = [object valueForKey:propertyName];
            }
            
            if(propertyValue){
                //设置属性值
                [info setValue:propertyValue forKey:@"propertyValue"];
                sqlValue = [BGTool getSqlValue:propertyValue type:propertyType encode:YES];        
                //设置将要存储到数据库的值
                [info setValue:sqlValue forKey:@"sqlColumnValue"];
                [modelInfos addObject:info];
            }
        }
        
    }
    NSAssert(modelInfos.count,@"对象变量数据为空,不能存储!");
    return modelInfos;
}


@end
