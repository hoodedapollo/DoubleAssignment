//
//  ViewController.m
//  DoubleAssignment
//
//  Created by Tommaso Elia on 03/02/18.
//  Copyright © 2018 DoubleTeam. All rights reserved.
//


#include "key.h"
#include "precomp.h"

@interface ViewController (/*private*/)

@property (nonatomic)  NSString*               subscriptionKey;
@property (nonatomic)  NSString*               luisAppID;
@property (nonatomic)  NSString*               luisSubscriptionID;
@property (nonatomic)  NSString*               authenticationUri;
// @property (nonatomic, readonly)  bool                    useMicrophone;
@property (nonatomic)  bool                    wantIntent;
@property (nonatomic)  SpeechRecognitionMode   mode;
@property (nonatomic)  NSString*               defaultLocale;
// @property (nonatomic, readonly)  NSDictionary*           settings;
//@property (nonatomic) NSArray*                 buttonGroup;
// @property (nonatomic, readonly)  NSUInteger              modeIndex;
@property (nonatomic) bool stopRecButtonFlag;
@property (nonatomic) NSInteger noRecCounter;
@property (nonatomic) NSMutableString *myResults;
@property (nonatomic) NSMutableString *myIntentsList;
@property (nonatomic) NSMutableString *myEntitiesList;
@property (nonatomic) NSObject* SpeechMachine; 
@end

NSString* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence);
NSString* ConvertSpeechErrorToString(int errorCode);


// The Main App ViewController

@implementation ViewController


@synthesize startRecButton;
@synthesize stopRecButton;

// Initializazion to be done when app starts

-(void)viewDidLoad {
    [super viewDidLoad];
/*** [SpeechAndIntentRecognizer initializer] (initialize method)***/
SpeechMachine = SpeechAndIntentRecognizerFactory;
/*** END ***/
}

// this method handles the Click event of the startRecButton control
// @param sender The event sender

-(IBAction)StartRecButton_Click:(id)sender {
    
    [[self startRecButton] setEnabled: NO]; // disable stopRecButton
    self.headerText.text = @"SPEECH RECOGNITION WITH INTENT DETECTION ENABLED"; // set the header label text
    
/*** [SpeechAndIntentRecognizer startRecording] ***/
    [SpeechMachine startRecording];
/*** END ***/
    
    [[self stopRecButton] setEnabled: YES];  // enable the stopRecButton
    
}

// this method handles the Click event of the stopRecButton control
// @param sender The event sender
-(IBAction)StopRecButton_Click:(id)sender {
    
    [[self stopRecButton] setEnabled: NO]; // disable stopRecButton
    
/*** [SpeechAndIntentRecognizer stopRecording] ***/
    [SpeechMachine stopRecording];
/*** END ***/
    
    self.headerText.text = @"SPEECH RECOGNITION DISABLED"; // set the Header lable
    [[ self startRecButton ] setEnabled: YES ]; // enable startRecButton
    
}


//Action for low memory
-(void)didReceiveMemoryWarning {
#if !defined(TARGET_OS_MAC)
    [ super  didReceiveMemoryWarning ];
# endif
}

@end
