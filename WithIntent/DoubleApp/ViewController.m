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
    
    self.noRecCounter = 0;
    
    // defined in a header file
    self.subscriptionKey = SUBSCRIPTION_KEY; // set the subscription key as the one defined in the header file
    self.authenticationUri = AUTHENTICATION_URI;
    self.mode = SPEECH_RECOGNITION_MODE;
    self.luisAppID = LUIS_APP_ID;
    self.luisSubscriptionID = LUIS_SUBSCRIPTION_ID;
    
    self.wantIntent = YES;
    self.defaultLocale =@"en-us"; // microphone language
    
//    self.buttonGroup = [[NSArray alloc] initWithObjects:startRecButton,
//                        stopRecButton,
//                        nil];
    textOnScreen = [ NSMutableString  stringWithCapacity:  1000 ];
    
    [[self stopRecButton] setEnabled: NO];
}

// this method handles the Click event of the startRecButton control
// @param sender The event sender

-(IBAction)StartRecButton_Click:(id)sender {
    //NSString* recStartMsg;
    
    [textOnScreen setString: ( @" ")];
    [self setText : textOnScreen];
    [[self startRecButton] setEnabled: NO];
    
    self.headerText.text = @"SPEECH RECOGNITION WITH INTENT DETECTION ENABLED";
    
    if (micClient == nil)
    {
        micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:(self.defaultLocale)
                                                                              withKey:(self.subscriptionKey)
                                                                        withLUISAppID:(self.luisAppID)
                                                                       withLUISSecret:(self.luisSubscriptionID)
                                                                         withProtocol:(self)];
        
        NSLog(@"micClient created\n");
    }
    
    NSLog(@"micClient already exist\n");
    
    self.stopRecButtonFlag = NO; // enable continous recording behaviour (see onFinalResponse method)
    
    OSStatus startMicStatus = [micClient startMicAndRecognition]; // turns the microphone on and begins streaming data from the microphone to the sèeech recognition service.
    if(startMicStatus)
    {
        [self WriteLine:[[NSString alloc] initWithFormat:(@"Error starting microphone recording. %@", ConvertSpeechErrorToString(startMicStatus))]];
    }
    NSLog(@"startMicStatus %d\n", startMicStatus);
    [[self stopRecButton] setEnabled: YES];
    NSLog(@"stopRecButton ENABLED\n");
}

    // this method handles the Click event of the stopRecButton control
    // @param sender The event sender
-(IBAction)StopRecButton_Click:(id)sender {
    [textOnScreen setString: ( @" ")];
    [self setText : textOnScreen];
    [[self stopRecButton] setEnabled: NO];
    NSLog(@"stopRecButton DISABLED\n");
    
    self.stopRecButtonFlag = YES; // disable continuous recording behaviour (see onFinalResponse method)
    [micClient endMicAndRecognition];
    NSLog(@"stop microphone recording\n");
    
    [[ self startRecButton ] setEnabled: YES ];
    NSLog(@"startRecButton ENABLED\n");
        
    self.headerText.text = @"SPEECH RECOGNITION DISABLED";
    
}
    
    // Called when a final response is received.
    // @param response The final result.
-(void)onFinalResponseReceived:(RecognitionResult*)response {
    NSLog(@"recieved a responsed from the server\n");
    if ([response.RecognizedPhrase count] == 0)
    {
        self.noRecCounter++;
        NSLog(@"Number of NOREC request: %ld", self.noRecCounter);
    }
    else{
        NSLog(@"SENTENCE REQUEST");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self WriteLine:(@"********* Final n-BEST Results *********")];
            for (int i = 0; i < [response.RecognizedPhrase count]; i++)
            {
                RecognizedPhrase* phrase = response.RecognizedPhrase[i];
                [self WriteLine:[[NSString alloc] initWithFormat:(@"[%d] Confidence=%@ Text=\"%@\""),
                                 i,ConvertSpeechRecoConfidenceEnumToString(phrase.Confidence),
                                 phrase.DisplayText]];
                NSLog(@"%@\n",phrase.DisplayText);
            }
            NSLog(@"phrase printed\n");
            [self WriteLine:(@"")];
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
        [self WriteLine:(@"--- Intent received by onIntentReceived ---")];
        [self WriteLine:(result.Body)];
        [self WriteLine:(@"")];
    });
}

// Called when the microphone status has changed.
// @param recording The current recording state
-(void)onMicrophoneStatus:(Boolean)recording {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self WriteLine:[[NSString alloc] initWithFormat:(@"********* Microphone status: %d *********"), recording]];});
}
    
// method called when partial response is received
// @param response is the partial result
    
-(void)onPartialResponseReceived:(NSString*) response {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.headerText.text = @"--- LISTENING ---";});
        
}

// Called when an error is received
// @param errorMessage The error message.
// @param errorCode The error code.  Refer to SpeechClientStatus for details.
    
-(void)onError:(NSString*)errorMessage withErrorCode:(int)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ self  startRecButton ] setEnabled: YES ];
        [self WriteLine:(@"--- Error received by onError ---")];
        [self WriteLine:[[NSString alloc] initWithFormat:(@"%@ %@"), errorMessage, ConvertSpeechErrorToString(errorCode)]];
        [self WriteLine:@""];
    });
    //[micClient startMicAndRecognition]; // reactivate the microphone after the response is recieved (continous behaviuour)
}

// this method writes a line
// @param text is the line to be write
-(void)WriteLine:(NSString*)text {
    [textOnScreen appendString:(text)];
    [textOnScreen appendString:(@"\n")];
    [self setText: textOnScreen];
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
    
// Appends text to the edit control.
// @param text The text to set.
- (void)setText:(NSString*)text {
    UNIVERSAL_TEXTVIEW_SETTEXT(self.quoteText, text);
    [self.quoteText scrollRangeToVisible:NSMakeRange([text length] - 1, 1)];
}
    
@end
