//
//  people.h
//  BGFMDB
//
//  Created by huangzhibiao on 16/9/27.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BGFMDB.h" //添加该头文件,本类就具有了存储功能.
@class People;
@interface Human : NSObject

@property(nonatomic,copy)NSString* sex;
@property(nonatomic,copy)NSString* body;
@property(nonatomic,assign)NSInteger humanAge;
@property(nonatomic,assign)int age;
@property(nonatomic,assign)int num;
@property(nonatomic,assign)int counts;
@property(nonatomic,copy)NSString* food;
@property(nonatomic,strong)NSData* data;
@property(nonatomic,strong)NSArray* array;
@property(nonatomic,strong)NSDictionary* dict;
@end

@interface Student : NSObject

@property(nonatomic,copy)NSString* num;
@property(nonatomic,strong)NSArray* names;
@property(nonatomic,strong)Human* human;
@property(nonatomic,assign)int count;
@end

@interface User : NSObject

@property(nonatomic,strong)NSDictionary* attri;
@property(nonatomic,strong)NSNumber* userNumer;
@property(nonatomic,strong)Student* student;//第二层类嵌套 , 可以无穷嵌套...
@property(nonatomic,strong)People *userP;
@property(nonatomic,assign)int userAge;
@property(nonatomic,copy)NSString* name;
@end

@interface People : NSObject
{
    @public
    int testAge;
    NSString* testName;
}


@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* num;
@property(nonatomic,assign)int age;
@property(nonatomic,copy)NSString* sex;
@property(nonatomic,copy)NSString* eye;
@property(nonatomic,copy)NSString* sex_old;
@property(nonatomic,strong)NSArray* students;
@property(nonatomic,strong)NSDictionary* infoDic;
@property(nonatomic,strong)User* user;//第一层类嵌套
@property(nonatomic,strong)User* user1;

@property(nonatomic,assign)int bint1;
@property(nonatomic,assign)short bshort;
@property(nonatomic,assign)signed bsigned;
@property(nonatomic,assign)long long blonglong;
@property(nonatomic,assign)unsigned bunsigned;
@property(nonatomic,assign)float bfloat;
@property(nonatomic,assign)double bdouble;
@property(nonatomic,assign)CGFloat bCGFloat;
@property(nonatomic,assign)NSInteger bNSInteger;
@property(nonatomic,assign)long blong;
@property(nonatomic,assign)BOOL addBool;

@property(nonatomic,assign)CGRect rect;
@property(nonatomic,assign)CGPoint point;
@property(nonatomic,assign)CGSize size;
@property(nonatomic,assign)NSRange range;

@property(nonatomic,strong)NSMutableArray* arrM;
@property(nonatomic,strong)NSMutableArray* datasM;
@property(nonatomic,strong)NSMutableDictionary* dictM;
@property(nonatomic,strong)NSSet* nsset;
@property(nonatomic,strong)NSMutableSet* setM;
@property(nonatomic,strong)NSMapTable* mapTable;
@property(nonatomic,strong)NSHashTable* hashTable;

@property(nonatomic,strong)NSDate* date;
@property(nonatomic,strong)NSData* data2;
//@property(nonatomic,strong)NSMutableData* dataM;
@property(nonatomic,strong)UIImage* image;
@property(nonatomic,strong)UIColor* color;
@property(nonatomic,strong)NSAttributedString* attriStr;

@property(nonatomic,strong)NSURL* Url;
@end

@interface Man : NSObject

@property(nonatomic,copy)NSString* Man_name;
@property(nonatomic,strong)NSNumber* Man_num;
@property(nonatomic,assign)int Man_age;
@property(nonatomic,strong)UIImage* image;

@end

@class T1;
@interface testT:NSObject
@property(nonatomic,strong) id t1;
@end

@interface T1:  NSObject
@property(nonatomic,copy) NSString* name;
@end

@interface T2: T1
@property(nonatomic,copy) NSString* t2;
@end

@interface T3 : T1
@property(nonatomic,copy) NSString* t3;
@property(nonatomic,strong) id t2;
@end
