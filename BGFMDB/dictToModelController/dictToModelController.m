//
//  dictToModelController.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/14.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "dictToModelController.h"
#import "Animal.h"

@interface dictToModelController ()
- (IBAction)beginTransformAction:(id)sender;
- (IBAction)backAction:(id)sender;


@end

@implementation dictToModelController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)beginTransformAction:(id)sender{
    NSDictionary* dictDog = [self getDogDict];
    //一代码搞定字典转模型.
    Dog* dog = [Dog bg_objectWithKeyValues:dictDog];
    NSDictionary* dictMy = [self getMyDict];
    //一代码搞定字典转模型.
    My* my = [My bg_objectWithDictionary:dictMy];
    
    /**
     批量转化.
     */
    NSArray* mys = [My bg_objectArrayWithKeyValuesArray:@[dictMy,dictMy,dictMy]];
    
    Body* body = [Body new];
    body.hand = @"手";
    body.leg = @"脚";
    //一句代码搞定模型转字典.
    NSDictionary* dictBodyAll = [my bg_keyValuesIgnoredKeys:nil];
    
    //忽略掉hand不转.
    NSDictionary* dictBody = [my bg_keyValuesIgnoredKeys:@[@"foods"]];
    
    [my bg_save];
    
    NSArray* myArr = [My bg_findAll:nil];
    
    NSLog(@"断点察看结果");
}

- (IBAction)backAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSDictionary*)getDogDict{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    dictM[@"foods"] = @[@"肉",@"骨头",@"屎",@"狗粮",@"米饭",@{@"蔬菜":@"狗菜"}];
    dictM[@"body"] = @{@"leg":@"两条腿",@"hand":@"两只手",@"head":@(1)};
    dictM[@"name"] = @"逗逼";
    dictM[@"age"] = @(2);
    dictM[@"specy"] = @"哈士奇";
    return dictM;
}
-(NSDictionary*)getBodyDict{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    dictM[@"hand"] = @"手";
    dictM[@"leg"] = @"脚";
    dictM[@"dog"] = [self getDogDict];
    return dictM;
}
-(NSDictionary*)getMyDict{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    dictM[@"name"] = @"小明";
    dictM[@"descri"] = @"标哥最帅了...";
    dictM[@"性别"] = @"男";
    dictM[@"dogs"] = @[[self getDogDict],[self getDogDict],[self getDogDict]];
    dictM[@"bodys"] = @[[self getBodyDict],[self getBodyDict]];
    dictM[@"foods"] = @[@"米饭",@"水果",@"蔬菜"];
    dictM[@"body"] = [self getBodyDict];
    return dictM;
}
@end
