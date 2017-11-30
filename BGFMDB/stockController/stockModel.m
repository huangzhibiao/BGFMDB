//
//  stockModel.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/9.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "stockModel.h"

@implementation stockModel

+(instancetype)stockWithName:(NSString*)name stockData:(NSNumber*)stockData{
    stockModel* stock = [stockModel new];
    stock.name = name;
    stock.stockData = stockData;
    return stock;
}

//实现该函数,返回指定的 “唯一约束” name.
+(NSArray *)bg_uniqueKeys{
    return @[@"name"];
}
@end
