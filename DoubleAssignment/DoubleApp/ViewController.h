//
//  ViewController.h
//  DoubleAssignment
//
//  Created by Tommaso Elia on 03/02/18.
//  Copyright © 2018 DoubleTeam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpeechSDK/SpeechRecognitionService.h"
#import <SpeechSDK/SpeechRecognitionService.h>
#import <DoubleControlSDK/DoubleControlSDK.h>
//#import "ESTConfig.h"
#import "EILIndoorLocationManager.h"
#import "EILRequestFetchLocation.h"
#import "EILOrientedPoint.h"

@interface ViewController : UIViewController <SpeechRecognitionProtocol>
{
//    NSMutableString * textOnScreen;
    MicrophoneRecognitionClient* micClient;
}

//@property(nonatomic, strong) IBOutlet UNIVERSAL_TEXTVIEW* quoteText;

/*! \name Labels
 */
///@{
@property (weak, nonatomic) IBOutlet UILabel* headerText;
@property (weak, nonatomic) IBOutlet UILabel* myResultsLabel;
@property (weak, nonatomic) IBOutlet UILabel* myIntentsLabel;
@property (weak, nonatomic) IBOutlet UILabel* myEntitiesLabel;
@property (strong, nonatomic) IBOutlet UILabel *PositionOrientation;
///@}

/*! \name Buttons 
 */
///@{
@property (strong, nonatomic) IBOutlet UIButton *DriveForward;
@property (strong, nonatomic) IBOutlet UIButton *DriveLeft;
@property (strong, nonatomic) IBOutlet UIButton *DriveRight;
@property (strong, nonatomic) IBOutlet UIButton *DriveBackward;
@property (strong, nonatomic) IBOutlet UIButton *Restract;
@property (strong, nonatomic) IBOutlet UIButton *Deploy;

@property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* startRecButton;
@property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* stopRecButton;
///@}
- (IBAction)PoleUp:(id)sender;
- (IBAction)PoleStop:(id)sender;
- (IBAction)PoleDown:(id)sender;
- (IBAction)Retract:(id)sender;
- (IBAction)Deploy:(id)sender;


@end
