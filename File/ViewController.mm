/*
 * Copyright (c) Microsoft. All rights reserved.
 * Licensed under the MIT license.
 *
 * Project Oxford: http://ProjectOxford.ai
 *
 * ProjectOxford SDK Github:
 * https://github.com/Microsoft/ProjectOxford-ClientSDK
 *
 * Copyright (c) Microsoft Corporation
 * All rights reserved.
 *
 * With license:
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#include "key.h"

// #ifdef TARGET_OS_IPHONE
// #import <UIKit/UIImage.h>
// typedef UIImage XXImage;
// #else
// #import <AppKit/NSImage.h>
// typedef NSImage XXImage;
// #endif

@interface ViewController (/*private*/)

@property (nonatomic, readonly)  NSString*               subscriptionKey;
//@property (nonatomic, readonly)  NSString*               luisAppId;
// @property (nonatomic, readonly)  NSString*               luisSubscriptionID;
@property (nonatomic, readonly)  NSString*               authenticationUri;
// @property (nonatomic, readonly)  bool                    useMicrophone;
// @property (nonatomic, readonly)  bool                    wantIntent;
@property (nonatomic, readonly)  SpeechRecognitionMode   mode;
@property (nonatomic, readonly)  NSString*               defaultLocale;
// @property (nonatomic, readonly)  NSDictionary*           settings;
@property (nonatomic, readwrite) NSArray*                buttonGroup;
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
    subscriptionKey = SUBSCRIPTION_KEY; // set the subscription key as the one defined in the header file
    authenticationUri = AUTHENTICATION_URL;

    mode = SpeechRecognitionMode_ShortPhrase;
    defaultLocale =@"en-us"; // microphone language

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

    [self WriteLine: [[NSString alloc] initWithFormat:i(@"\n--- Start speech recognition using microphone with %@ mode in %@ language ---\n\n"),
        self.mode == SpeechRecognitionMode_ShortPhrase ? @"Short" : @"Long",
        self.defaultLocale]];
    
    if (micClient == nil) 
    {
        micClient = [SpeechRecognitionServiceFactory createMicrophoneClient:(self.mode)
                                                     withLanguage:(self.defaultLocale)   
                                                     withKey:(self.subscriptionKey)
                                                     withProtocol:(self)];
        
    [[self stopRecButton] setEnabled YES]
}

// this method handles the Click event of the stopRecButton control
// @param sender The event sender
-(IBAction)StopRecButton_Click:(id)sender {
    [textOnScreen setString: ( @" ")];
    [self setText : textOnScreen];
    [[self stopRecButton] setEnabled: NO];

    [micClient endMicAndRecognition];

    [[ self startRecButton ] setEnabled: YES ];

    [self WriteLine: [[NSString alloc] initWithFormat:(@"\n--- Stop speech recognition using microphone with Short mode ---\n\n"),
        self.mode == SpeechRecognitionMode_ShortPhrase ? @"Short" : @"Long"]];
    
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
                                  i,
                                  ConvertSpeechRecoConfidenceEnumToString(phrase.Confidence),
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
            [[ self  startButton ] setEnabled: YES ];
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
        [[ self  startButton ] setEnabled: YES ];
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
String* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence) {
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
    [self.quoteText setString: text];
    [self.quoteText scrollRangeToVisible:NSMakeRange([text length] - 1, 1)]; 
}

@end
