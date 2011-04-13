//
//  Dictionary.h
//  HundredSeconds
//
//  Created by Jae Kim on 3/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Dictionary : NSObject {

	NSMutableArray *_allWords;
	NSMutableDictionary *_dictionary;
}

@property (nonatomic, retain) NSMutableArray *allWords;
@property (nonatomic, retain) NSMutableDictionary *dict;

+(Dictionary*) sharedDictionary;
-(void) loadDictionary;

@end
