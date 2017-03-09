//
//  stockModel.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/9.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+BGModel.h"

@interface stockModel : NSObject

@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* stockData;

+(instancetype)stockWithName:(NSString*)name stockData:(NSNumber*)stockData;
@end
