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

/**
 如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现该函数,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
(‘字典转模型’ 或 ’模型转字典‘ 都需要实现该函数)
 */
+(NSDictionary *)bg_objectClassInArray{
    return @{@"dogs":[Dog class],@"bodys":[Body class]};
}
/**
 如果模型中有自定义类变量,则实现该函数对应进行集合到模型的转换.
 注:字典转模型用.
 */
+(NSDictionary *)bg_objectClassForCustom{
    return @{@"body":[Body class],@"body.dog":[Dog class]};
}
/**
 将模型中对应的自定义类变量转换为字典.
 模型转字典用.
 */
+(NSDictionary *)bg_dictForCustomClass{
    return @{@"body":[Body class],@"dog":[Dog class]};
}
/**
 替换变量的功能(及当字典的key和属性名不一样时，进行映射对应起来)
 即将字典里key为descri的值 赋给 属性名为intro的变量,性别和sex同理.
 */
+(NSDictionary *)bg_replacedKeyFromPropertyName{
    return @{@"descri":@"intro",@"性别":@"sex"};
}

@end
