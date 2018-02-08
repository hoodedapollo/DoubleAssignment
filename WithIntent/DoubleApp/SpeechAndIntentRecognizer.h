#import <Foundation/Foundation.h>
#import <SpeechSDK/SpeechRecognitionService.h>

@interface SpeechAndIntentRecognitioner : NSObject <SpeechRecognitionProtocol>

+ SpeechAndIntentRecognitionerFactory(UILable * resultsLabel, UILabel * intentsLabel, UILabel * entitiesLabel) // allocate memory for an instance of the class and initialize it 

-(void)startRecording
-(void)stopRecording
-(NSArray *)getIntents
-(NSArray *)getEntities
-(NSString *)getResultsLableString
-(NSString *)getIntentsLableString
-(NSString *)getEntitiesLableString

@end


