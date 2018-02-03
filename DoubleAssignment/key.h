#include "TargetConditionals.h"

#if !TARGET_OS_IPHONE

#import <Cocoa/Cocoa.h> 

#else

#import <UIKit/UIKit.h> 

#endif 

#import <Foundation/Foundation.h>
#import "SpeechSDK/SpeechRecognitionService.h"

#import "AppDelegate.h"
#import "ViewController.h"

#define SUBSCRIPTION_KEY 56550e71d61e4d40a894c266e2b82b4c
#define AUTHENTICATION_URL  https://api.cognitive.microsoft.com/sts/v1.0
