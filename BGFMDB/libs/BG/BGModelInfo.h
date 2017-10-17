//
//  BGModelInfo.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/2/22.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BGModelInfo : NSObject

//属性名
@property (nonatomic, copy, readonly) NSString *propertyName;
//属性的类型
@property (nonatomic, copy, readonly) NSString *propertyType;
//属性值
@property (nonatomic, strong, readonly) id propertyValue;

//保存到数据库的列名
@property (nonatomic, copy, readonly) NSString *sqlColumnName;
//保存到数据库的类型
@property (nonatomic, copy, readonly) NSString *sqlColumnType;
//保存到数据库的值
@property (nonatomic, strong, readonly) id sqlColumnValue;

//获取对象相关信息
+(NSArray<BGModelInfo*>*)modelInfoWithObject:(id)object;

@end

NS_ASSUME_NONNULL_END
