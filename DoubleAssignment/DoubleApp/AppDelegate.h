//
//  AppDelegate.h
//  DoubleAssignment
//
//  Created by Tommaso Elia on 03/02/18.
//  Copyright © 2018 DoubleTeam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EstimoteProximitySDK/EstimoteProximitySDK.h>
#import <AVFoundation/AVFoundation.h>

#define theAppDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *found;


@end

