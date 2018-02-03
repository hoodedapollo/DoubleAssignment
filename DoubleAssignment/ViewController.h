//
//  ViewController.h
//  DoubleAssignment
//
//  Created by Tommaso Elia on 03/02/18.
//  Copyright © 2018 DoubleTeam. All rights reserved.
//

#import <UIKit/UIKit.h>

// @interface ViewController : UNIVERSAL_VIEWCONTROLLER <SpeechRecognitionProtocol>
@interface ViewController : UIViewController <SpeechRecognitionProtocol>
{
    NSMutableString * textOnScreen;
    // DataRecognitionClient * dataClient;
    MicrophoneRecognitionClient* micClient;
}

// @property(nonatomic, strong) IBOutlet UNIVERSAL_VIEW*   radioGroup;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* startButton;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* micRadioButton;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* micDictationRadioButton;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* micIntentRadioButton;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* dataShortRadioButton;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* dataLongRadioButton;
// @property(nonatomic, strong) IBOutlet UNIVERSAL_BUTTON* dataShortIntentRadioButton;
@property(nonatomic, strong) IBOutlet UITextView* quoteText;

@property(nonatomic, strong) IBOutlet UIButton* startRecButton;
@property(nonatomic, strong) IBOutlet UIButton* stopRecButton;

// -(IBAction)StartButton_Click:(id)sender;
// -(IBAction)RadioButton_Click:(id)sender;
// -(IBAction)ChangeModeButton_Click:(id)sender;

-(IBAction)StartRecButton_Click:(id)sender;
-(IBAction)StopRecButton_Click:(id)sender;

@end
