//
//  Person.h
//  Sqlite
//
//  Created by mac book on 16/1/22.
//  Copyright © 2016年 mac book. All rights reserved.
//

#import <Foundation/Foundation.h>


//实现数据库列名到model属性名的映射
@protocol ColumnPropertyMappingDelegate <NSObject>

@required
- (NSDictionary *)columnPropertyMapping;

@end

@interface Person : NSObject<ColumnPropertyMappingDelegate>

@property (nonatomic, assign) NSInteger peopleId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *gender;
@property (nonatomic, assign) float weight;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) short age;
@property (nonatomic, assign) long score;
@property (nonatomic, strong) NSDate *createTime;
@property (nonatomic, assign) BOOL married;
@property (nonatomic, strong) NSData *desc;

@end
