//
//  Animal.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/14.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "Animal.h"

@implementation Animal

@end

@implementation Dog


@end

@implementation Body


@end

@implementation My

//如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现该函数,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
-(NSDictionary *)objectClassInArray{
    return @{@"dogs":[Dog class],@"bodys":[Body class]};
}

@end
