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
//@property (nonatomic, readonly)  NSString*               luisAppId;
// @property (nonatomic, readonly)  NSString*               luisSubscriptionID;
@property (nonatomic)  NSString*               authenticationUri;
// @property (nonatomic, readonly)  bool                    useMicrophone;
// @property (nonatomic, readonly)  bool                    wantIntent;
@property (nonatomic)  SpeechRecognitionMode   mode;
@property (nonatomic)  NSString*               defaultLocale;
// @property (nonatomic, readonly)  NSDictionary*           settings;
@property (nonatomic) NSArray*                 buttonGroup;
// @property (nonatomic, readonly)  NSUInteger              modeIndex;

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
    
    // defined in a header file
    self.subscriptionKey = SUBSCRIPTION_KEY; // set the subscription key as the one defined in the header file
    self.authenticationUri = AUTHENTICATION_URL;
    self.mode = SPEECH_RECOGNITION_MODE;
    
    self.defaultLocale =@"en-us"; // microphone language
    
    self.buttonGroup = [[NSArray alloc] initWithObjects:startRecButton,
                        stopRecButton,
                        nil];
    textOnScreen = [ NSMutableString  stringWithCapacity:  1000 ];
}

// this method handles the Click event of the startRecButton control
// @param sender The event sender

-(IBAction)StartRecButton_Click:(id)sender {
    NSString* recStartMsg;
    
    [textOnScreen setString: ( @" ")];
    [self setText : textOnScreen];
    [[self startRecButton] setEnabled: NO];
    
    [self WriteLine: [[NSString alloc] initWithFormat:(@"\n--- Start speech recognition using microphone with %@ mode in %@ language ---\n\n"),
                      self.mode == SpeechRecognitionMode_ShortPhrase ? @"Short" : @"Long",
                      self.defaultLocale]];
    
    if (micClient == nil)
    {
        micClient = [SpeechRecognitionServiceFactory createMicrophoneClient:(self.mode)
                                                               withLanguage:(self.defaultLocale)
                                                                    withKey:(self.subscriptionKey)
                                                               withProtocol:(self)];
        
        [[self stopRecButton] setEnabled: YES];
    }
}

    // this method handles the Click event of the stopRecButton control
    // @param sender The event sender
-(IBAction)StopRecButton_Click:(id)sender {
    [textOnScreen setString: ( @" ")];
    [self setText : textOnScreen];
    [[self stopRecButton] setEnabled: NO];
    
    [micClient endMicAndRecognition];
    
    [[ self startRecButton ] setEnabled: YES ];
        
    [self WriteLine: [[NSString alloc] initWithFormat:(@"\n--- Stop speech recognition using microphone with Short mode ---\n\n"),                                      self.mode == SpeechRecognitionMode_ShortPhrase ? @"Short" : @"Long"]];
        
}
    
    // Called when a final response is received.
    // @param response The final result.
-(void)onFinalResponseReceived:(RecognitionResult*)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self WriteLine:(@"********* Final n-BEST Results *********")];
        for (int i = 0; i < [response.RecognizedPhrase count]; i++)
        {
            RecognizedPhrase* phrase = response.RecognizedPhrase[i];
            [self WriteLine:[[NSString alloc] initWithFormat:(@"[%d] Confidence=%@ Text=\"%@\""),
                i,ConvertSpeechRecoConfidenceEnumToString(phrase.Confidence),
                phrase.DisplayText]];
        }
            
            [self WriteLine:(@"")];
        });
}
// Called when the microphone status has changed.
// @param recording The current recording state
-(void)onMicrophoneStatus:(Boolean)recording {
    if (!recording) {
        [micClient endMicAndRecognition];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!recording) {
            [[ self  startRecButton ] setEnabled: YES ];
        }
        [self WriteLine:[[NSString alloc] initWithFormat:(@"********* Microphone status: %d *********"), recording]];
        });
}
    
// method called when partial response is received
// @param response is the partial result
    
-(void)onPartialResponseReceived:(NSString*) response {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self WriteLine:(@"--- Partial result received by onPartialResponseReceived ---")];
        [self WriteLine:response];
    });
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
