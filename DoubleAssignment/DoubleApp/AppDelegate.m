//
//  AppDelegate.m
//  DoubleAssignment
//
//  Created by Tommaso Elia on 03/02/18.
//  Copyright © 2018 DoubleTeam. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()
@property (nonatomic) EPXProximityObserver *proximityObserver;


@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    EPXCloudCredentials *cloudCredentials =
    [[EPXCloudCredentials alloc] initWithAppID:@"laboratorium-dibris-gmail--kfg" appToken:@"90e1b9d8344624e9c2cd42b9f5fd6392"];
    self.proximityObserver = [[EPXProximityObserver alloc]
                              initWithCredentials:cloudCredentials
                              errorBlock:^(NSError * _Nonnull error) {
                                  NSLog(@"proximity observer error = %@", error);
                              }];
    
    EPXProximityZone *zone1 = [[EPXProximityZone alloc]
                               initWithRange:EPXProximityRange.nearRange  //nearRange = 1 meter;   farRange = 5 meter
                               attachmentKey:@"Person"
                               attachmentValue:@"Mark"];
    zone1.onEnterAction = ^(EPXDeviceAttachment * _Nonnull attachment) {
        NSLog(@"Hi Mark!");
        self.found = @"Mark";
        NSString *string = @"Hi Mark!";
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
        [synthesizer speakUtterance:utterance];

    };
    zone1.onExitAction = ^(EPXDeviceAttachment * _Nonnull attachment) {
        NSLog(@"Bye bye Mark");
        self.found = @"";
        NSString *string = @"Bye bye Mark";
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
        [synthesizer speakUtterance:utterance];
    };
    [self.proximityObserver startObservingZones:@[zone1]];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*!
     * Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     * Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*!
     * Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     * If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*!
     * Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*! 
     * Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*!
     * Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
     */
}


@end
