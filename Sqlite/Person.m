//
//  Person.m
//  Sqlite
//
//  Created by mac book on 16/1/22.
//  Copyright © 2016年 mac book. All rights reserved.
//

#import "Person.h"

@implementation Person
- (NSDictionary *)columnPropertyMapping
{
    return @{@"id": @"peopleId",
             @"str1": @"name",
             @"str2": @"gender",
             @"float1": @"weight",
             @"double1": @"height",
             @"short1": @"age",
             @"long1": @"score",
             @"date1": @"createTime",
             @"bool1": @"married",
             @"data1": @"desc"};
}
@end
