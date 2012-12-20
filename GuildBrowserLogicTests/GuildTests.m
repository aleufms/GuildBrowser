//
//  GuildTests.m
//  GuildBrowser
//
//  Created by Alessandro on 19/12/12.
//  Copyright (c) 2012 Charlie Fulton. All rights reserved.
//

#import "GuildTests.h"
#import <OCMock/OCMock.h>
#import "WoWApiClient.h"
#import "Guild.h"
#import "TestSemaphor.h"
#import "Character.h"

@implementation GuildTests{
    Guild *_guild;
    NSDictionary *_testGuildData;
}

- (void)setUp {
    NSURL *dataServiceURL = [[NSBundle bundleForClass:self.class] URLForResource:@"guild" withExtension:@"json"];
    NSData *sampleData = [NSData dataWithContentsOfURL:dataServiceURL];
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:sampleData options:kNilOptions error:&error];
    _testGuildData = json;
}

- (void)tearDown {
    _guild = nil;
    _testGuildData = nil;
}

- (void)testCreatingGuilDataFromWowApiClient {
    id mockWowApiClient = [OCMockObject mockForClass:[WoWApiClient class]];
    
    [[[mockWowApiClient stub] andDo:^(NSInvocation *invocation){
        void (^successBlock)(Guild *guild);
        [invocation getArgument:&successBlock atIndex:4];
        Guild *testData = [[Guild alloc] initWithGuildData:_testGuildData];
        successBlock(testData);
        }]
     guildWithName:[OCMArg any] onRealm:[OCMArg any] success:[OCMArg any] error:[OCMArg any]];
    
    NSString *semaphoreKey = @"membersLoaded";
    
    [mockWowApiClient guildWithName:@"Dream Catchers" onRealm:@"Borean Tundra" success:^(Guild *guild) {
//        sleep(10);
        _guild = guild;
        [[TestSemaphor sharedInstance] lift:semaphoreKey];
    }error:^(NSError *error) {
        [[TestSemaphor sharedInstance] lift:semaphoreKey];
    }];
    
    [[TestSemaphor sharedInstance] waitForKey:semaphoreKey];
    
    STAssertNotNil(_guild, @"");
    STAssertEqualObjects(_guild.name, @"Dream Catchers", nil);
    STAssertTrue([_guild.members count] == [[_testGuildData valueForKey:@"members"] count], nil);
    
    NSArray *characters = [_guild membersByWowClassTypeName:WowClassTypeDeathKnight];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Lixiu", nil);
    
    characters = [_guild membersByWowClassTypeName:WowClassTypeDruid];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Elassa", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Ivymoon", nil);
    STAssertEqualObjects(((Character*)characters[2]).name, @"Everybody", nil);
    
    characters = [_guild membersByWowClassTypeName:WowClassTypeHunter];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Bulldogg", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Bluekat", nil);
//    STAssertEqualObjects(((Character*)characters[2]).name, @"Josephus", nil);
}

@end
