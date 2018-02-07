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
    self.noRecCounter = 0; // initialize the counter of the empty response due to silence
    
    // set the values as defined in the key.h header file
    self.subscriptionKey = SUBSCRIPTION_KEY; // set the subscription key as the one defined in the header file
    self.authenticationUri = AUTHENTICATION_URI;
    self.mode = SPEECH_RECOGNITION_MODE;
    self.luisAppID = LUIS_APP_ID;
    self.luisSubscriptionID = LUIS_SUBSCRIPTION_ID;
    
    self.wantIntent = YES; // specify you want also intent recognition besides speech recognition
    self.defaultLocale =@"en-us"; // speech recognition language
    
    // declare strings to print text on UI labeles
    self.myResults = [ NSMutableString  stringWithCapacity:  1000 ];
    self.myIntentsList = [ NSMutableString  stringWithCapacity:  1000 ];
    self.myEntitiesList = [ NSMutableString  stringWithCapacity:  1000 ];
    
    [[self stopRecButton] setEnabled: NO]; // disable stopRecButton
/*** END ***/
}

// this method handles the Click event of the startRecButton control
// @param sender The event sender

-(IBAction)StartRecButton_Click:(id)sender {
    
    [[self startRecButton] setEnabled: NO]; // disable stopRecButton
/*** [SpeechAndIntentRecognizer startRecording] ***/
    self.headerText.text = @"SPEECH RECOGNITION WITH INTENT DETECTION ENABLED"; // set the header label text
    
    if (micClient == nil) // if there is no MicrophoneClientWithIntent create it
    {
        micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:(self.defaultLocale)
                                                                              withKey:(self.subscriptionKey)
                                                                        withLUISAppID:(self.luisAppID)
                                                                       withLUISSecret:(self.luisSubscriptionID)
                                                                         withProtocol:(self)];
    }

    self.stopRecButtonFlag = NO; // enable continous recording behaviour (see onFinalResponse method)
    [micClient startMicAndRecognition];  //
/*** END ***/
    
    [[self stopRecButton] setEnabled: YES];  // enable the stopRecButton
    
}

// this method handles the Click event of the stopRecButton control
// @param sender The event sender
-(IBAction)StopRecButton_Click:(id)sender {
    
    self.noRecCounter = 0; // reinitialize the counter of empty response due to silence
    [[self stopRecButton] setEnabled: NO]; // disable stopRecButton
    
/*** [SpeechAndIntentRecognizer stopRecording] ***/
    self.stopRecButtonFlag = YES; // disable continuous recording behaviour (see onFinalResponse method)
    [micClient endMicAndRecognition]; // disable the microphone and disconnect from the server
    self.headerText.text = @"SPEECH RECOGNITION DISABLED"; // set the Header lable
/*** END ***/
    
    [[ self startRecButton ] setEnabled: YES ]; // enable startRecButton
    
}

// ALL THE FUNCTIONS AND THE PROTOCOL METHODS MUST BE INCLUDED IN THE SpeechAndIntentRecognizer CLASS AS IS

// Called when a final response is received.
// @param response The final result.
-(void)onFinalResponseReceived:(RecognitionResult*)response {
    
    if ([response.RecognizedPhrase count] == 0)  // if the chunks sent were just silence
    {
        self.noRecCounter++; // increase the noRec counter
        NSLog(@"Number of NOREC request: %ld", self.noRecCounter);
    }
    else // the response contains recognized phrases with the related confidence
    {
        // convert all the recognized results in one string to be shown in the corresponding UIlabel
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.myResults setString: @"Final n-BEST Results:\n\n"];
            for (int i = 0; i < [response.RecognizedPhrase count]; i++)
            {
                RecognizedPhrase* phrase = response.RecognizedPhrase[i];
                [self.myResults appendString: [NSString stringWithFormat:(@"[%d] Confidence: %@ Text: \"%@\"\n"),
                                               i,ConvertSpeechRecoConfidenceEnumToString(phrase.Confidence),
                                               phrase.DisplayText]];
            }
            
            self.myResultsLabel.text = self.myResults;
        });
    }
    if (!self.stopRecButtonFlag) // if the stop button was not clicked
    {
        [micClient startMicAndRecognition]; // reactivate the microphone after the response is recieved (continous behaviuour)
    }
}


//Called when a final response is received and its intent is parsed
//@param result The intent result.
-(void)onIntentReceived:(IntentResult*) result {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Convert the string sent by the LUIS server into a (id) json, equivalent to a NSDictionary
        NSString *jsonString = result.Body;
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        // store intents and entities in the corresponding arrays
        NSArray *myIntents = [json objectForKey:@"intents"];
        NSArray *myEntities = [json objectForKey:@"entities"];
        
        // show the top scoring intent in the correspondin UILabel
        self.myIntentsLabel.text = [[NSString alloc] initWithFormat:@"--- Intents Detected ---\n\nTop Scoring Intent: %@\nwith score: %@",
                                    [myIntents[0] objectForKey:@"intent"],
                                    [myIntents[0] objectForKey:@"score"]];
        
        // store alle the entities (types adn values) in a single string
        [self.myEntitiesList setString:@"--- Entities Detected ---\n\n"];
        for (int i = 0; i < [myEntities count]; i++)
        {
            [self.myEntitiesList appendString:[[NSString alloc] initWithFormat:@"Entity: %@ Type: %@ \n",
                                               [myEntities[i] objectForKey:@"entity"],
                                               [myEntities[i] objectForKey:@"type"]]];
            
        }
        
        // and show them all in the corresponding UILabel
        self.myEntitiesLabel.text = self.myEntitiesList;
        
    });
}

// Called when the microphone status has changed.
// @param recording The current recording state
-(void)onMicrophoneStatus:(Boolean)recording {
    if (!self.stopRecButtonFlag) // if the stop button was not clicked
    {
        [micClient startMicAndRecognition]; // reactivate the microphone after the connection is closed due to too many empty response (silence)
    }
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [self WriteLine:[[NSString alloc] initWithFormat:(@"********* Microphone status: %d *********"), recording]];});
}

// method called when partial response is received
// @param response is the partial result

-(void)onPartialResponseReceived:(NSString*) response {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.headerText.text = @"--- LISTENING ---";}); // while recieving partial responses show the message: LISTENING in the header UILabel
    
}

// Called when an error is received
// @param errorMessage The error message.
// @param errorCode The error code.  Refer to SpeechClientStatus for details.

-(void)onError:(NSString*)errorMessage withErrorCode:(int)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ self  startRecButton ] setEnabled: YES ]; // enable the startRecButton
        // show the error code and relative message in the Header Lable
        self.headerText.text = [[NSString alloc] initWithFormat:(@"--- Error received by onError ---/n%@ %@"), errorMessage, ConvertSpeechErrorToString(errorCode)];
        
    });
    [micClient startMicAndRecognition]; // reactivate the microphone after the response is recieved (continous behaviuour)
}

// Converts an integer error code to an error string.
// @param errorCode The error code
// @return The string representation of the error code.
NSString* ConvertSpeechErrorToString(int errorCode) {
    switch ((SpeechClientStatus)errorCode) {
        case SpeechClientStatus_SecurityFailed:         return @"SpeechClientStatus_SecurityFailed";
        case SpeechClientStatus_LoginFailed:            return @"SpeechClientStatus_LoginFailed";
        case SpeechClientStatus_Timeout:                return @"SpeechClientStatus_Timeout";
        case SpeechClientStatus_ConnectionFailed:       return @"SpeechClientStatus_ConnectionFailed";
        case SpeechClientStatus_NameNotFound:           return @"SpeechClientStatus_NameNotFound";
        case SpeechClientStatus_InvalidService:         return @"SpeechClientStatus_InvalidService";
        case SpeechClientStatus_InvalidProxy:           return @"SpeechClientStatus_InvalidProxy";
        case SpeechClientStatus_BadResponse:            return @"SpeechClientStatus_BadResponse";
        case SpeechClientStatus_InternalError:          return @"SpeechClientStatus_InternalError";
        case SpeechClientStatus_AuthenticationError:    return @"SpeechClientStatus_AuthenticationError";
        case SpeechClientStatus_AuthenticationExpired:  return @"SpeechClientStatus_AuthenticationExpired";
        case SpeechClientStatus_LimitsExceeded:         return @"SpeechClientStatus_LimitsExceeded";
        case SpeechClientStatus_AudioOutputFailed:      return @"SpeechClientStatus_AudioOutputFailed";
        case SpeechClientStatus_MicrophoneInUse:        return @"SpeechClientStatus_MicrophoneInUse";
        case SpeechClientStatus_MicrophoneUnavailable:  return @"SpeechClientStatus_MicrophoneUnavailable";
        case SpeechClientStatus_MicrophoneStatusUnknown:return @"SpeechClientStatus_MicrophoneStatusUnknown";
        case SpeechClientStatus_InvalidArgument:        return @"SpeechClientStatus_InvalidArgument";
    }
    return [[NSString alloc] initWithFormat:@"Unknown error: %d\n", errorCode];
}

// Converts a Confidence value to a string
// @param confidence The confidence value.
// @return The string representation of the confidence enumeration.
NSString* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence) {
    switch (confidence) {
        case SpeechRecoConfidence_None:
            return @"None";
            
        case SpeechRecoConfidence_Low:
            return @"Low";
            
        case SpeechRecoConfidence_Normal:
            return @"Normal";
            
        case SpeechRecoConfidence_High:
            return @"High";
    }
}


//Action for low memory
-(void)didReceiveMemoryWarning {
#if !defined(TARGET_OS_MAC)
    [ super  didReceiveMemoryWarning ];
# endif
}

@end
