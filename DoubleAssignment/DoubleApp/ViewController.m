/*!
     Software Architecture Assignment
 
    The core of the project is in this file:
    - Speech Recognition with Microsoft Bing Speech API
    - Intent detection with Luis.ai (Language Understanding Intelligent Service).
    - Bluetooth Localization with Estimote Indoor Location SDK
    - Double motion Control with Basic Control SDK
 
*/

//  Created by Tommaso Elia on 03/02/18.
//  Copyright © 2018 DoubleTeam. All rights reserved.
//


#include "key.h"
#include "precomp.h"
#import <DoubleControlSDK/DoubleControlSDK.h>
#import "EILIndoorSDK.h"
#import <EstimoteSDK/EstimoteSDK.h>
#import <EstimoteProximitySDK/EstimoteProximitySDK.h>
#import <AVFoundation/AVFoundation.h>

#define IPHONE 0 ///< 1 means iphone, 0 means ipad
#define SHORT_SLEEP 2
#define LONG_SLEEP 0
#define DISABLED 400  ///< Double rotation disabled flag
                      /*!<
                             The amount of degrees the double must rotates is used also as a flag were 400 (>360) means disabled
                       */

#define INTENT_PRECISION 0.2  ///< Minimum score required for an intent to be recognized as a valid one


#define IS_DOUBLE_VELOCITY 0.27 ///< Double velocity [m/s]
                                /*!<
                                    The variable velocity to be given to the double is a value within the range [-1;+1]; A value of 0.5 corresponds approximately (speed tests) to a velocity of 0.27 m/s
                                 */

#define SDK_DOUBLE_VELOCITY 0.5  ///< Value in the range [-1;+1]; 0.5 corresponds approximately to 0.27 [m/s]
#define STOP_DISTANCE_FROM_GOAL 0.3 ///< Distance from the goal below which the Double stops [m]
#define POSITION_UNKOWN -10
#define NOT_YET_FOUNDED @""
#define MAP_FROM_CLOUD 1 ///< flag to specify is building a location or dowloading one
                         /*!< if 1 the location is downloaded from the cloud, if it is 0 the loaction is builded using the loactionBuilder and uploaded to the server
                          */

@interface ViewController (/*private*/) <DRDoubleDelegate, EILIndoorLocationManagerDelegate>

/*! \name Speech Recognition Properties
 */
///@{
@property (nonatomic)  NSString*               subscriptionKey; ///< subscription key for the Bing Speech API
@property (nonatomic)  NSString*               subscriptionKey2;
@property (nonatomic)  NSString*               subscriptionKey3;
@property (nonatomic)  NSString*               luisAppID;
@property (nonatomic)  NSString*               luisSubscriptionID;
@property (nonatomic)  NSString*               authenticationUri;
@property (nonatomic)  bool                    wantIntent;
@property (nonatomic)  SpeechRecognitionMode   mode;
@property (nonatomic)  NSString*               defaultLocale;




@property (nonatomic) bool stopRecButtonFlag;  ///< flag that asseses if the stop button has been pushed
                                               /*!<Responses from the server are recieved asynchronously and by default the audio recording stops after a resonse is recieved. Thus we need to explicitly restart the microphone after each response is recieved. In order to stop the recording for good, after the stop button is pushed, we must not reactivate the audio recording after a response is recieved. This behaviour is implemented through this flag, which states if the stop button was pushed (YES) or not (NO).
                                               */

@property (nonatomic) NSInteger noRecCounter; ///< counter of empty responses due to silence
@property (nonatomic) NSInteger noRecPartialCounter; ///< counter needed to reset the speech recognition client (short sleep)
@property (nonatomic) NSInteger notEmptyCounter; ///< counter of not empty responses
@property (nonatomic) NSInteger allResponsesCounter; ///< total number of responses (sum of empty responses and not empty ones)
@property (nonatomic) NSInteger allResponsesPartialCounter; ///< counter needed to reset the speech recognition client (long sleep)
@property (nonatomic) NSMutableString *myResults; ///< string to be published on myResultLabel
@property (nonatomic) NSMutableString *myIntentsList; ///< string to be published on myIntentsLabel
@property (nonatomic) NSMutableString *myEntitiesList; ///< string to be published on MyEntities Label
@property (nonatomic) NSString *actualSubscriptionKey; ///< it can be switched among different subscription keys trying to extend the web socket connection time
///@}

/*! \name Estimote Indoor Location SDK properties
 */
///@{
@property (nonatomic) EILIndoorLocationManager *locationManager;
//@property (nonatomic, assign) BOOL provideOrientationForLightMode;
@property (nonatomic) EILLocation *location; ///< it is the map (do not confuse it with the position)
@property (nonatomic) EILOrientedPoint* doublePosition; ///< posistion evaluated by the Blutooth Beacons
@property (nonatomic) EILPositionAccuracy positionAccuracy;
@property (nonatomic) EILPoint *goal; ///< position to be reached

///@}


/*! \name Navigation Properties
 */
///@{
@property (nonatomic) NSString* intent;  ///< Intent property is used to determine which taske the Double must accomplish
                                        /*!< Intent examples:
                                             <ul>
                                               <li>GoToAction: Double must reach a position specified by the Entity
                                               <li>PoleUp: Double must elong the pole
                                               <li>...
                                            </ul>
                                         */
                                         
@property (nonatomic) NSString* entity; ///< given an intent, the entity it is used to univocally determine the task the Double must performe
@property (nonatomic) float degreesToBeRotated; ///< The degrees the double needs to rotate in order to point in the right direction
                                                /*!<
                                                 This quantity is evaluated in such away that the rotation performed is alwasys the minimum required
                                                 */

//@property (nonatomic) float avaragePosition;
@property (nonatomic) NSDate *startTime; ///< time at which the double starts moving toward the goal
@property (nonatomic) double travelTime; ///< amount of time is required to reach the goal
                                         /*!<
                                          Given the Double velocity in meters per second and the distance from the goal it is possible to evaluate this quantity.
                                          */
@property (nonatomic) NSArray *room;            ///< Room entities that can be returned by the Intent Detection
                                                /*!<
                                                 The NSArray pointed by room is initialized as follows:
                                                 <ul>
                                                    <li>room[0] = living room
                                                    <li>room[1] = kitchen
                                                    <li>room[2] = dinner room
                                                 </ul>
                                                 */

@property (nonatomic) NSArray *person;  ///< Person entities that can be returned by the Intent Detection
                                        /*!<
                                        The NSArray pointed by person is initialized as follows:
                                         <ul>
                                            <li>person[0] = Mark
                                            <li>person[1] = Thomas
                                         </ul>
                                        */

@property (nonatomic) bool forward; ///< flag used to enable continous autonomous forward motion
@property (nonatomic) bool backward; ///< flag used to enable continous autonomous backward motion

///@}

@end

NSString* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence);
NSString* ConvertSpeechErrorToString(int errorCode);


// The Main App ViewController

@implementation ViewController

@synthesize startRecButton;
@synthesize stopRecButton;


/// Initializazion to be done when app starts
/*!
 <ul>
    <li> Estimote Localization
    <ul>
        <li> Initialize the EILIndoorLocationManager delegate (different for iphone or ipad)
        <li> If MAP_FROM_CLOUD == 0 build and upload the loaction to the cloud
        <li> If MAP_FROM_CLOUD == 1 download the loaction from the cloud and start monitoring the position
        <li> Initialize the entity arrays for each type: person, room, ...
    </ul>
    <li> Double Control
    <ul>
        <li> Initialize the DRDouble delegate
    </ul>
    <li> Speech Recognition and Intent Detection
    <ul>
        <li> set all the parameters as defined in the key.h file
        <li> disable teh stop button
    </ul>
 </ul>
 
 */

-(void)viewDidLoad {
    [super viewDidLoad];
    
    /*** Estimote Location] ***/    
    // instantiate the location manager & set its delegate
    self.locationManager = [EILIndoorLocationManager new];
    self.locationManager.delegate = self;
    if (IPHONE == 1)
    {
        self.locationManager.mode = EILIndoorLocationManagerModeExperimentalWithInertia;
    }
    else
    {
        self.locationManager.provideOrientationForLightMode = YES;
    }
    
    //IF WE WANT USE A MANUAL MAP
    if (!MAP_FROM_CLOUD){
        EILLocationBuilder *locationBuilder = [EILLocationBuilder new];
        [locationBuilder setLocationName:@"XalongNorthDirection"];
        [locationBuilder setLocationBoundaryPoints:@[
                                                     [EILPoint pointWithX:0 y:0],
                                                     [EILPoint pointWithX:3.45 y:0],
                                                     [EILPoint pointWithX:3.45 y:4.7],
                                                     [EILPoint pointWithX:0 y:4.7]]];
        
        [locationBuilder setLocationOrientation:30];
        
        [locationBuilder addBeaconWithIdentifier:@"244d360132cb9d298460820895b64523" withPosition:[[EILOrientedPoint alloc] initWithX:1.725 y:4.7]];
        
        [locationBuilder addBeaconWithIdentifier:@"0eef0a74e1554232068d06b2ae75710f" withPosition:[[EILOrientedPoint alloc] initWithX:0 y:2.35]];
        
        [locationBuilder addBeaconWithIdentifier:@"3de2fadd238dedd46a704a7f9135a218" withPosition:[[EILOrientedPoint alloc] initWithX:1.725 y:0]];
        
        [locationBuilder addBeaconWithIdentifier:@"f6f687da1cfcceee5b5260a5c4952718" withPosition:[[EILOrientedPoint alloc] initWithX:3.45 y:2.35]];
        
        EILLocation *location = [locationBuilder build];
        
        [ESTConfig setupAppID:@"doubleapp-cro" andAppToken:@"b379fd64cde52dbb79770b6c44ce1505"];
        EILRequestAddLocation *addLocationRequest = [[EILRequestAddLocation alloc] initWithLocation:location];
        [addLocationRequest sendRequestWithCompletion:^(EILLocation *location, NSError *error) {
            if (error) {
                NSLog(@"Error when saving location: %@", error);
            } else {
                NSLog(@"Location saved successfully: %@", location.identifier);
            }
        }];
        
    }
    //IF WE WANT USE A MAP FROM THE CLOUD
    else{
        [ESTConfig setupAppID:@"doubleapp-cro" andAppToken:@"b379fd64cde52dbb79770b6c44ce1505"]; //connection with the estimote cloud
        
        // to fetch of our location
        EILRequestFetchLocation *fetchLocationRequest =
        [[EILRequestFetchLocation alloc] initWithLocationIdentifier:@"xalongnorthdirection-bau"];
        [fetchLocationRequest sendRequestWithCompletion:^(EILLocation *location,
                                                          NSError *error) {
            if (location != nil) {
                self.location = location;
                [self.locationManager startPositionUpdatesForLocation:self.location];
            } else {
                NSLog(@"can't fetch location: %@", error);
            }
        }];
    }
    
    //self.locationManager.mode = EILIndoorLocationManagerModeLight;
    //NSLog(@"***************MODE: %d", self.locationManager.mode);
    self.degreesToBeRotated = DISABLED;
    self.room = [[NSArray alloc] initWithObjects:[[EILPoint alloc] initWithX:0.3 y:0.3],[[EILPoint alloc] initWithX:2.8 y:2], [[EILPoint alloc] initWithX:4 y:0.3],nil];
    self.person = [[NSArray alloc] initWithObjects:[[EILPoint alloc] initWithX:POSITION_UNKOWN y:POSITION_UNKOWN],[[EILPoint alloc] initWithX:POSITION_UNKOWN y:POSITION_UNKOWN], nil];
    theAppDelegate.found = NOT_YET_FOUNDED;
    
    /*** END ***/
    
    /*** [DoubleControl] ***/
    [DRDouble sharedDouble].delegate = self;
    self.forward = false;
    self.backward = false;
    /*** END ***/
    
    /*** [SpeechAndIntentRecognizer initializer] (initialize method)***/
    // counters initialization
    self.notEmptyCounter = 0;
    self.noRecCounter = 0;
    self.noRecPartialCounter = 0;
    self.allResponsesCounter = 0;
    self.allResponsesPartialCounter = 0;
    
    // set the values as defined in the key.h header file
    self.subscriptionKey = SUBSCRIPTION_KEY; // set the subscription key as the one defined in the header file
    self.subscriptionKey2 = SUBSCRIPTION_KEY2;
    self.subscriptionKey3 = SUBSCRIPTION_KEY3;
    self.authenticationUri = AUTHENTICATION_URI;
    self.mode = SPEECH_RECOGNITION_MODE;
    self.luisAppID = LUIS_APP_ID;
    self.luisSubscriptionID = LUIS_SUBSCRIPTION_ID;
    
    self.actualSubscriptionKey = self.subscriptionKey2; // the first subscribtion key to be used at laoding time
    
    self.wantIntent = YES; // specify you want also intent recognition besides speech recognition
    self.defaultLocale =@"en-us"; // speech recognition language
    
    // declare strings to print text on UI labeles
    self.myResults = [ NSMutableString  stringWithCapacity:  1000 ];
    self.myIntentsList = [ NSMutableString  stringWithCapacity:  1000 ];
    self.myEntitiesList = [ NSMutableString  stringWithCapacity:  1000 ];
    
    [[self stopRecButton] setEnabled: NO]; // disable stopRecButton
    /*** END ***/
}


/*! \name Buttons Methods
 */
///@{

/// this method handles the Click event of the startRecButton control
/*!
 @param sender The event sender
 
 When the start button is pushed
 <ul>
    <li> disable the start button
    <li> show in the app interface the speech recognition is enabled
    <li> initialize the client for the speech recognition
    <li> set the stopButtonFlag to NO
    <li> activate the microphone and start the speech recognition
    <li> enable the stop button
 </ul>
 */
-(IBAction)StartRecButton_Click:(id)sender {
    
    [[self startRecButton] setEnabled: NO]; // disable startRecButton
    self.headerText.text = @"SPEECH RECOGNITION WITH INTENT DETECTION ENABLED"; // set the header label text
    
    /*** [SpeechAndIntentRecognizer startRecording] ***/
    if (micClient == nil) // if there is no MicrophoneClientWithIntent create it
    {
        micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:(self.defaultLocale)
                                                                              withKey:(self.actualSubscriptionKey)
                                                                        withLUISAppID:(self.luisAppID)
                                                                       withLUISSecret:(self.luisSubscriptionID)
                                                                         withProtocol:(self)];
    }
    
    self.stopRecButtonFlag = NO; // (stop button was not pushed yet) enable continous recording behaviour (see onFinalResponse method)
    [micClient startMicAndRecognition];  // activates the microphone and start the speech recognition with intent detection
    /*** END ***/
    
    [[self stopRecButton] setEnabled: YES];  // enable the stopRecButton
    
}

/// this method handles the Click event of the stopRecButton control
/*!
 @param sender The event sender
 
 When the stop button is pushed
 <ul>
    <li> disable the stop button
    <li> reinitialize the counters
    <li> set the stopButtonFlag to YES
    <li> disable the microphone and disconnect from the server
    <li> enable the start button
 </ul>
 */
-(IBAction)StopRecButton_Click:(id)sender {
    
    [[self stopRecButton] setEnabled: NO]; // disable stopRecButton
    
    /*** [SpeechAndIntentRecognizer stopRecording] ***/
    // reinitialize the counters at each execution
    self.notEmptyCounter = 0;
    self.noRecCounter = 0;
    self.allResponsesCounter = 0;
    self.noRecPartialCounter = 0;
    
    self.stopRecButtonFlag = YES; // (stop button pusheed set the flag accordingly) disable continuous recording behaviour (see onFinalResponse method)
    
    [micClient endMicAndRecognition]; // disable the microphone and disconnect from the server
    /*** END ***/
    
    self.headerText.text = @"SPEECH RECOGNITION DISABLED"; // set the Header lable
    [[ self startRecButton ] setEnabled: YES ]; // enable startRecButton
}


/// this method handles the Click event of the PoleUp control
- (IBAction)PoleUp:(id)sender {
     [[DRDouble sharedDouble] poleUp];
}

/// this method handles the Click event of the PoleStop control
- (IBAction)PoleStop:(id)sender {
     [[DRDouble sharedDouble] poleStop];
}

/// this method handles the Click event of the PoleDown control
- (IBAction)PoleDown:(id)sender {
     [[DRDouble sharedDouble] poleDown];
}

/// this method handles the Click event of the Retract control
- (IBAction)Retract:(id)sender {
    [[DRDouble sharedDouble] retractKickstands];
}

/// this method handles the Click event of the Deploy control
- (IBAction)Deploy:(id)sender {
    [[DRDouble sharedDouble] deployKickstands];
}

///@}


/*! \name Speech Recognition Methods
 */
///@{

/// Called when a final response is received.
/*!
@param response The final result.
 
 When a final response is recieved the default behavior of the client is to disable the microphone and disconect from the server. For this reason, within this method, we need to call the startMicAndRecognition method to re-enable the speech recognition.
 
 Furthermore this method updates the interface of the app with the results of the Speech Recognition recieved from the server (Bing Speech API): just the text since the Intent dectection is performed by another server (LUIS).
 */
-(void)onFinalResponseReceived:(RecognitionResult*)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"RESPONSE");
        self.headerText.text = @"SPEECH RECOGNITION WITH INTENT DETECTION ENABLED"; // reset the header label text upon recieving a final response
        self.allResponsesCounter++;
        self.allResponsesPartialCounter++;
        
        if ([response.RecognizedPhrase count] == 0)  // if the chunks sent were just silence
        {
            self.noRecCounter++; // increase the noRec counter
            self.noRecPartialCounter++;
        }
        else // the response contains recognized phrases with the related confidence
        {
            self.notEmptyCounter++;
            
            // convert all the recognized results in one string to be shown in the corresponding UIlabel
            [self.myResults setString: @"Final n-BEST Results:\n\n"];
            for (int i = 0; i < [response.RecognizedPhrase count]; i++)
            {
                RecognizedPhrase* phrase = response.RecognizedPhrase[i];
                [self.myResults appendString: [NSString stringWithFormat:(@"[%d] Confidence: %@ Text: \"%@\"\n"),
                                               i,ConvertSpeechRecoConfidenceEnumToString(phrase.Confidence),
                                               phrase.DisplayText]];
            }
            
            self.myResultsLabel.text = self.myResults; // publish the composed string on myResultsLabel
            
        }
        
        //display the counters in the log
        NSLog(@"Number of NOTEMPTY requests: %ld", self.notEmptyCounter);
        NSLog(@"Number of NOREC requests: %ld", self.noRecCounter);
        NSLog(@"Number of TOTAL requests: %ld", self.allResponsesCounter);
        NSLog(@"Number of NORECPARTIAL requests: %ld", self.noRecPartialCounter);
        NSLog(@"ACTUAL KEY %@", self.actualSubscriptionKey);
        
        int waitTime;
        
        if (self.stopRecButtonFlag == NO) // if the stop button was not pushed then continuous recording behaviour
        {
            if ((self.allResponsesCounter % 40) == 0) // if total responses since last reset of client reset it with a long sleep time for reinitialization
            {
                self.allResponsesPartialCounter = 0;
                waitTime = LONG_SLEEP;
            }
            else
            {
                waitTime = SHORT_SLEEP;
            }
            
            if ((self.noRecCounter % 10) == 0) {
                
                    [micClient startMicAndRecognition]; // reactivate the microphone after the response is recieved (continous behaviuour)
            }
            else // else reinitialize the micClient
            {
                // change the subscription key following the order 1 -> 2 -> 3 -> 1 and so on
                //if ([self.actualSubscriptionKey isEqualToString: self.subscriptionKey])
                //{
                //    self.actualSubscriptionKey = self.subscriptionKey2;
                //}
                //else if ([self.actualSubscriptionKey isEqualToString: self.subscriptionKey2])
                //{
                //    self.actualSubscriptionKey = self.subscriptionKey3;
                //}
                //else
                //{
                //    self.actualSubscriptionKey = self.subscriptionKey;
                //}
                
                [micClient endMicAndRecognition]; // Turns the microphone off and breaks the connection to the speech recognition service.
                //NSLog(@"going to sleep for %d seconds", waitTime);
                //sleep(waitTime); // sleeps for the time set previously according to the allResponsesPartialCounter
                self.noRecPartialCounter = 0;
                micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:(self.defaultLocale)
                                                                                      withKey:(self.actualSubscriptionKey)
                                                                                withLUISAppID:(self.luisAppID)
                                                                               withLUISSecret:(self.luisSubscriptionID)
                                                                                 withProtocol:(self)];
                [micClient startMicAndRecognition]; // Turns the microphone on and begins streaming data from the microphone to the speech recognition service.
            }
        }
    });
}


///Called when a final response is received and its intent is parsed
/*!
@param result The intent result.
 
 The top scoring Intent and the relative Entities:
 <ul>
    <li> are stored in two different properties
    <li> are shown in the interface of the App
  </ul>
 
 Then the method which is responsible for making the double act according to the intent parsed, is called
 */
 -(void)onIntentReceived:(IntentResult*) result {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Convert the string sent by the LUIS server into a (id) json, equivalent to a NSDictionary
        NSString *jsonString = result.Body;
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        // store intents and entities in the corresponding arrays
        NSArray *myIntents = [json objectForKey:@"intents"];
        NSArray *myEntities = [json objectForKey:@"entities"];
        
        //Don't update if there is no intent, don't care about entities without intents
        if([myIntents count] > 0)
        {
            // show the top scoring intent in the corresponding UILabel
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
            [self motorIntentMyIntent: myIntents  motorIntentMyEntities:myEntities];
            //NSLog(@"******* myEntities: %d", [myEntities count]);
        }
    });
}


-(void)onLogEvent:(unsigned long) eventId {
    //NSLog(@" -------ONLOG %ld", eventId);
}

/// Called when the microphone status has changed.
/*!
 *  @param recording The current recording state
 */
-(void)onMicrophoneStatus:(Boolean)recording {
}

/// method called when partial response is received
/*!
 * @param response is the partial result
 * while recieving partial responses shows the message: LISTENING in the App interface
 */
-(void)onPartialResponseReceived:(NSString*) response {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.headerText.text = @"--- LISTENING ---";});
    
}

/// Called when an error is received
/*!
 * @param errorMessage The error message.
 * @param errorCode The error code.  Refer to SpeechClientStatus for details.
 */
-(void)onError:(NSString*)errorMessage withErrorCode:(int)errorCode {
    
    NSLog(@"**************************************** Error received by onError ---/n%@ %@", errorMessage, ConvertSpeechErrorToString(errorCode));
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ self  startRecButton ] setEnabled: YES ]; // enable the startRecButton
        // show the error code and relative message in the Header Lable
        self.headerText.text = [[NSString alloc] initWithFormat:(@"--- Error received by onError ---/n%@ %@"), errorMessage, ConvertSpeechErrorToString(errorCode)];
        
    });
    
}


/// Converts an integer error code to an error string.
/*!
 * @param errorCode The error code
 * @return The string representation of the error code.
 */
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

/// Converts a Confidence value to a string
/*! 
 * @param confidence The confidence value.
 * @return The string representation of the confidence enumeration.
 */
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


///@}


/*! \name Double Control Methods
 */
///@{

///method responsible for moving the double according to the intent detected
/*!
 @param myIntents The Intent Detected.
 @param myEntities The Entities Detected
 
 
 <table>
 <caption id="multi_row">Intents, related Double actions and Double SDK methods</caption>
 <tr><th>INTENT DETECTED    <th>RELATED ACTION              <th>DOUBLE SDK METHOD       <th> FLAGS
 <tr><td>PoleUp             <td> Elongate the pole          <td> PoleUp                 <td> /
 <tr><td>PoleDown           <td> Shorten the pole           <td> PoleDown               <td> /
 <tr><td>Stop               <td> Stop the Double            <td> PoleStop               <td> <ul>
                                                                                                <li> forward flag = false
                                                                                                <li> backward flag = false
                                                                                             </ul> 
 <tr><td>Forward            <td> Move forward               <td> /                      <td> forward flag = true
 <tr><td>Backward           <td> Move Backward              <td> /                      <td> backward flag = true
 <tr><td>Standby            <td> Deploy the kikcstands      <td> deployKickstands       <td> /
 <tr><td>WakeUp             <td> Retract the kickstands     <td> retractKickstands      <td> /
 <tr><td>GoToAction         <td> reach the goal position    <td> /                      <td> /
 </table>
        
 
 */

-(void)motorIntentMyIntent:(NSArray*)myIntents motorIntentMyEntities:(NSArray*) myEntities{
    float precision = [[myIntents[0] objectForKey:@"score"] floatValue];
    //NSLog(@"*************** Hello my intent = %@  with score: %f",[myIntents[0] objectForKey:@"intent"], precision);
    if([[myIntents[0] objectForKey:@"intent"] isEqual: @"None"]){
        /*
        // diasble microphone
        NSString *string = @"Can you repeat, please";
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
        [synthesizer speakUtterance:utterance];
         // re-enable the microphone
         */
        
    }
    else if(precision >= INTENT_PRECISION){
        
        self.intent = [myIntents[0] objectForKey:@"intent"];
        NSString *type;
        if( [myEntities count] != 0 ){
            self.entity =  [myEntities[0] objectForKey:@"entity"];
            type =  [myEntities[0] objectForKey:@"type"];
        }
        if([self.intent  isEqual: @"PoleUp"])
        {
            [[DRDouble sharedDouble] poleUp];
        }
        else if([self.intent  isEqual: @"PoleDown"])
        {
            [[DRDouble sharedDouble] poleDown];
        }
        else if([self.intent  isEqual: @"Stop"])
        {
            [[DRDouble sharedDouble] poleStop];
            self.forward = false;
            self.backward = false;
        }
        else if([self.intent  isEqual: @"Forward"])
        {
            self.forward = true;
        }
        else if([self.intent  isEqual: @"Backward"])
        {
            self.backward = true;
        }
        else if([self.intent  isEqual: @"Standby"])
        {
            [[DRDouble sharedDouble] deployKickstands];
        }
        else if([self.intent  isEqual: @"Wakeup"])
        {
            [[DRDouble sharedDouble] retractKickstands];
        }
        else if([self.intent  isEqual: @"GoToAction"])
        {
            if([type  isEqual: @"Room"])
            {
                if([self.entity  isEqual: @"living room"] )
                {
                    self.goal = self.room[0];
                    [self goToGoal:self.goal];
                }
                else if([self.entity  isEqual: @"kitchen"])
                {
                    self.goal = self.room[1];
                    [self goToGoal:self.goal];
                }
                else if([self.entity  isEqual: @"dining room"])
                {
                    self.goal = self.room[2];
                    [self goToGoal:self.goal];
                }
                else // Entity value not recognized
                {
                    /*
                     // diasble microphone
                     NSString *string = @"Can you repeat, please";
                     AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
                     utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
                     AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
                     [synthesizer speakUtterance:utterance];
                     // re-enable the microphone
                     */
                }
            }
            else if([type  isEqual: @"Person"])
            {
                if([self.entity  isEqual: @"Mark"])
                {
                    self.goal = self.person[0];
                    if(self.goal.x == POSITION_UNKOWN || self.goal.x == POSITION_UNKOWN)
                    {
                        //TO DO: function to check in any room.
                    }
                    else{
                        self.goal = self.person[0];
                        [self goToGoal:self.goal];
                    }
                }
                else if([self.entity  isEqual: @"Thomas"])
                {
                    self.goal = self.person[1];
                    if(self.goal.x == POSITION_UNKOWN || self.goal.x == POSITION_UNKOWN)
                    {
                        //TO DO: function to check in any room.
                    }
                    else{
                        self.goal = self.person[0];
                        [self goToGoal:self.goal];
                    }
                }
            }
            else{
                /*
                 // diasble microphone
                 NSString *string = @"Can you repeat, please";
                 AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
                 utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
                 AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
                 [synthesizer speakUtterance:utterance];
                 // re-enable the microphone
                 */
            }
        }
    }
    else{ // if intent precision is less then INTENT_PRECISION
        /*
         // diasble microphone
         NSString *string = @"Can you repeat, please";
         AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
         utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
         AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
         [synthesizer speakUtterance:utterance];
         // re-enable the microphone
         */
    }
}


/// method to determine the degrees the double must turn
/*!
 @return The amount of degrees the double must turn
 @param goal The goal position
 
 Positive angles counted counter-clockwise.
 
 */

-(double)degreesTurn:(EILPoint*)goal{
    double alpha, beta;
    double dx = (goal.x - self.doublePosition.x);
    double dy = (goal.y - self.doublePosition.y);
    
    if(IPHONE == 1){
    beta = 360- self.doublePosition.orientation;
    alpha = self.doublePosition.orientation;
    }
    else{
        alpha = self.doublePosition.orientation + 180;
        if (alpha > 360){
            alpha = alpha - 360;
        }
        beta = 360 -alpha;
    }
    double theta = [self myatanDx:dx Dy:dy];
    if(theta < 0 )
    {
        theta = theta +360;
        if (round(theta) == 360)
        {
            theta = 0;
        }
    }
    NSLog(@"\nPosition x: %f\nPosition y: %f\ndx: %f\ndy: %f\nbeta: %f\nalpha: %f\ntheta: %f\n",self.doublePosition.x, self.doublePosition.y, dx,dy, beta, alpha, theta);
    if(theta<180.0 && beta<180.0 && theta + beta<180.0)
    {
        return (beta + theta);
    }
    else if(theta>180.0 && beta>180.0 && theta-alpha>180.0)
    {
        return (theta-(alpha + 360));
    }
    else {
        return (theta - alpha);
    }
}

/// method to compute the angle given dx and dy
/*!
 @return The angle between 0 and 360 degrees
 @param dx difference between final and initial position along x axis
 @param dy difference between final and initial position along y axis
  */
-(double)myatanDx:(double) dx Dy:(double) dy {
    double result = atan(dy/dx)*(180/M_PI);
    if (dx < 0 ){
        result = result + 180;
    }
    return result;
}

/// method responsible for starting the motion of the Double
/*!
    @param goal The goal position

    This method
    <ul>
        <li> uses the degreesTurn method to determine the rotation needed to point to the goal
        <li> gets the time when the motion starts and stores it in startTime
        <li> computes the time required to reach the goal
        <li> sets the flag to enable the autonomous motion  
    </ul>


 */
-(void)goToGoal:(EILPoint*)goal{
    self.degreesToBeRotated=round([self degreesTurn: goal]);
    NSLog(@"********************* double orientation: %f degreesToBeRotated: %f", _doublePosition.orientation, self.degreesToBeRotated );
    self.startTime = [NSDate date];
    self.travelTime = (([self.doublePosition distanceToPoint:goal])/IS_DOUBLE_VELOCITY);
    self.forward = true;
}
/// method that loops and establishes what the Double does at each cycle
/*!
 *  act according to the intent detected by the speech recognition
 *  while moving toward a goal stops if the goal is within a certain range or equivalent travel time has elapsed 
 *  if any button is pushed disable the autonomous mode, if activatd, and act accordingly 
 */

- (void)doubleDriveShouldUpdate:(DRDouble *)theDouble {
    float drive = 0.0;
    //NSLog(@"\nself.forward %d\ninten is a goToAction: %d",self.forward, [self.intent  isEqual: @"GoToAction"]);
    //NSLog(@"\n*************Distance = %f", [self.doublePosition distanceToPoint:self.kitchen]);
    
    //Check if any button is pressed. If it's pressed, I cancel the priority of voice command, becouse worst respons 
    if(self.DriveForward.highlighted || self.DriveBackward.highlighted || self.DriveRight.highlighted || self.DriveLeft.highlighted || self.Deploy.highlighted || self.Restract.highlighted)
    {
        float drive = (self.DriveForward.highlighted) ? SDK_DOUBLE_VELOCITY : ((self.DriveBackward.highlighted) ? -SDK_DOUBLE_VELOCITY : kDRDriveDirectionStop);
        float turn = (self.DriveRight.highlighted) ? 1.0 : ((self.DriveLeft.highlighted) ? -1.0 : 0.0);
        [theDouble variableDrive:drive turn:turn];
        self.forward = false;
        self.backward = false;
    }
    else if(self.forward  || self.backward || (self.degreesToBeRotated != DISABLED)){
        if(self.degreesToBeRotated == DISABLED){
            if(self.forward == true && self.backward == false)
            {
                if([self.intent  isEqual: @"GoToAction"])
                {
                    
                    NSLog(@"TravelTime: %f\tElapsedTime: %f", self.travelTime,[[NSDate date] timeIntervalSinceDate:self.startTime] );
                    if (([self.doublePosition distanceToPoint:self.goal] > STOP_DISTANCE_FROM_GOAL ) && ([[NSDate date] timeIntervalSinceDate:self.startTime] < self.travelTime))
                    {
                        drive = SDK_DOUBLE_VELOCITY;
                    }
                    else{
                        self.forward=false;
                    }
                }
                else{
                    drive = SDK_DOUBLE_VELOCITY;
                }
            }
            else if (self.forward == false && self.backward == true)
            {
                drive = -SDK_DOUBLE_VELOCITY;
            }
            [theDouble variableDrive:drive turn:0];
        }
        else{
            [theDouble turnByDegrees:self.degreesToBeRotated];
            self.degreesToBeRotated = DISABLED;
        }
    }
    else
    {
        drive = kDRDriveDirectionStop;
    }
}

///@}


/*! \name Estimote (Bluetooth Positioning ) Methods
 */
///@{
-    (void)indoorLocationManager:(EILIndoorLocationManager *)manager didFailToUpdatePositionWithError:(NSError *)error {
    NSLog(@"failed to update position: %@", error);
}

- (void)indoorLocationManager:(EILIndoorLocationManager *)manager
            didUpdatePosition:(EILOrientedPoint *)position
                 withAccuracy:(EILPositionAccuracy)positionAccuracy
                   inLocation:(EILLocation *)location
    {
        //NSLog(@"+++++++++++++ FOUND??: %@",theAppDelegate.found);
        
        
        NSString *accuracy;
        self.doublePosition = position;
        self.positionAccuracy = positionAccuracy;
        switch (positionAccuracy)
        {
            case EILPositionAccuracyVeryHigh: accuracy = @"+/- 1.00m"; break;
            case EILPositionAccuracyHigh:     accuracy = @"+/- 1.62m"; break;
            case EILPositionAccuracyMedium:   accuracy = @"+/- 2.62m"; break;
            case EILPositionAccuracyLow:      accuracy = @"+/- 4.24m"; break;
            case EILPositionAccuracyVeryLow:  accuracy = @"+/- ? :-("; break;
            case EILPositionAccuracyUnknown:  accuracy = @"unknown"; break;
        }
        self.PositionOrientation.text = [[NSString alloc] initWithFormat:(@"x: %5.2f, y: %5.2f, orientation: %3.0f, accuracy: %@"), position.x, position.y, position.orientation, accuracy];
        //NSLog(@"x: %5.2f, y: %5.2f, orientation: %3.0f, accuracy: %@", position.x, position.y, position.orientation, accuracy);
}
///@}


///Action for low memory
-(void)didReceiveMemoryWarning {
#if !defined(TARGET_OS_MAC)
    [ super  didReceiveMemoryWarning ];
# endif
}
@end
