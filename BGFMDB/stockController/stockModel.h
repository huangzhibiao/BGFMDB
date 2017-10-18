//
//  stockModel.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/9.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BGFMDB.h" //引入所需的头文件

@interface stockModel : NSObject

@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* stockData;

+(instancetype)stockWithName:(NSString*)name stockData:(NSNumber*)stockData;
@end
