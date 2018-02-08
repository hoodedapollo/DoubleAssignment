#import "SpeechAndIntentRecognizer.h"


// the interface here contains the private attributes of the class
@interface SpeechAndIntentRecognitioner 

@property (nonatomic) NSString*               subscriptionKey;
@property (nonatomic) NSString*               luisAppID;
@property (nonatomic) NSString*               luisSubscriptionID;
@property (nonatomic) NSString*               authenticationUri;
@property (nonatomic) bool                    wantIntent;
@property (nonatomic) SpeechRecognitionMode   mode;
@property (nonatomic) NSString*               defaultLocale;
@property (nonatomic) bool                    stopRecButtonFlag;
@property (nonatomic) NSInteger               noRecCounter;
@property (nonatomic) NSMutableString*        myResults;
@property (nonatomic) NSMutableString*        myIntentsList;
@property (nonatomic) NSMutableString*        myEntitiesList;
@property (nonatomic) NSArray*                myIntents;
@property (nonatomic) NSArray*                myEntities;
@property (nonatomic) UILable* myResultsLabel;
@property (nonatomic) UILable* myIntentsLabel;
@property (nonatomic) UILable* myEntitiesLabel;
@end

// in between the interface and the implementation all the functions that are no methods must be declared
NSString* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence);
NSString* ConvertSpeechErrorToString(int errorCode);

@implementation SpeechAndIntentRecognizer

+ (id) SpeechAndIntentRecognizerFactory:(UILable * resultsLabel, UILabel * intentsLabel, UILabel * entitiesLabel) {  // allocate memory for an instance of the class and initialize it 

        [[self alloc] init];

        self.myResultsLabel = resultsLabel;
        self.myIntentsLabel = intentsLabel;
        self.myEntitiesLabel = entitiesLabel;

        self.noRecCounter = 0; // initialize the counter of the empty response due to silence

        // set the values as defined in the key.h header file
        self.subscriptionKey = SUBSCRIPTION_KEY; // set the subscription key as the one defined in the header
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
        
        return [self autorelease];
}


-(void)startRecording{
        if (micClient == nil) // if there is no MicrophoneClientWithIntent create it
        {
                micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:(self.defaultLocale
                                                                                      withKey:(self.subscriptionK
                                                                                withLUISAppID:(self.luisAppID)
                                                                               withLUISSecret:(self.luisSubscript
                                                                                withProtocol:(self)];
        }

        self.stopRecButtonFlag = NO; // enable continous recording behaviour (see onFinalResponse method)
        [micClient startMicAndRecognition]; 
}

-(void)stopRecording {
        self.noRecCounter = 0; // reinitialize the counter of empty response due to silence
        self.stopRecButtonFlag = YES; // disable continuous recording behaviour (see onFinalResponse method)
        [micClient endMicAndRecognition]; // disable the microphone and disconnect from the server
            
}

-(NSArray *)getIntents {
        return self.myIntents;
}

-(NSArray *)getEntities {
        return self.myENtities;
}

-(NSString *)getResultsLableString {
        return self.myResults;
} 

-(NSString *)getIntentsLableString {
        return.myIntentsList;
}
-(NSString *)getEntitiesLableString {
        return.myENtitiesList;
}

// ALL THE FUNCTIONS AND THE PROTOCOL METHODS MUST BE INCLUDED IN THE SpeechAndIntentRecognizer CLASS AS 
//
// // Called when a final response is received.
// // @param response The final result.

-(void)onFinalResponseReceived:(RecognitionResult*)response {

        if ([response.RecognizedPhrase count] == 0)  // if the chunks sent were just silence
        {
                self.noRecCounter++; // increase the noRec counter
                NSLog(@"Number of NOREC request: %ld", self.noRecCounter);
        }
        else // the response contains recognized phrases with the related confidence
        {
             //   convert all the recognized results in one string to be shown in the corresponding UIlabel
                        dispatch_async(dispatch_get_main_queue(), ^{

                                        [self.myResults setString: @"Final n-BEST Results:\n\n"];
                                        for (int i = 0; i < [response.RecognizedPhrase count]; i++)
                                        {
                                        RecognizedPhrase* phrase = response.RecognizedPhrase[i];
                                        [self.myResults appendString: [NSString stringWithFormat:(@"[%d] Confidence: %@ Text: \"%@\"\n"),
                                                        i,ConvertSpeechRecoConfidenceEnumToString(phrase.Confidenc
                                                                phrase.DisplayText]];
                                                                }

                                                                self.myResultsLabel.text = self.myResults;
                                                                });
                                                        }
                                                        if (!self.stopRecButtonFlag) // if the stop button was not clicked
                                                        {
                                                        [micClient startMicAndRecognition]; // reactivate the microphone after the response is recieved (
                                                        }
                                                        }

//Called when a final response is received and its intent is parsed
////@param result The intent result.

-(void)onIntentReceived:(IntentResult*) result {
            dispatch_async(dispatch_get_main_queue(), ^{
                            // Convert the string sent by the LUIS server into a (id) json, equivalent to a NSDictionary
                            
                            NSString *jsonString = result.Body;
                                    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                                            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                                            // store intents and entities in the corresponding arrays
                                            
                                            self.myIntents = [json objectForKey:@"intents"];
                                            self.myEntities = [json objectForKey:@"entities"];

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
// // @param recording The current recording state

-(void)onMicrophoneStatus:(Boolean)recording {
            if (!self.stopRecButtonFlag) // if the stop button was not clicked
                        {
                                        [micClient startMicAndRecognition]; // reactivate the microphone after the connection is closed d
                                            }
                //    dispatch_async(dispatch_get_main_queue(), ^{
                //        //        [self WriteLine:[[NSString alloc] initWithFormat:(@"********* Microphone status: %d *******
                        }

// method called when partial response is received
// // @param response is the partial result

-(void)onPartialResponseReceived:(NSString*) response {
            dispatch_async(dispatch_get_main_queue(), ^{
                                    self.headerText.text = @"--- LISTENING ---";}); // while recieving partial responses show the mes

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
                                                            [micClient startMicAndRecognition]; // reactivate the microphone after the response is recieved (cont
                                                            }
                                           

// Converts an integer error code to an error string.
// // @param errorCode The error code
// // @return The string representation of the error code.

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
// // @param confidence The confidence value.
// // @return The string representation of the confidence enumeration.

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

@end
