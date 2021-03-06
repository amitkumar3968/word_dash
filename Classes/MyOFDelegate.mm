//
//  OFDelegate.m
//  HundredSeconds
//
//  Created by Jae Kim on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyOFDelegate.h"
#import "cocos2d.h"
#import "OpenFeint.h"
#import "OFMultiplayer.h"
#import "OFMultiplayerService.h"
#import "OFMultiplayerService+Advanced.h"
#import "OFMultiplayerGame.h"
#import "OpenFeint+UserOptions.h"
#import "OFUser.h"
#import "OFUserService.h"
#import "Multiplayer.h"
#import "OFHighScoreService.h"
#import "OpenFeint+Dashboard.h"
#import "GameManager.h"
#import "ChallengeRequestDialog.h"
#import "MainMenuLayer.h"
#import "PauseLayer.h"

@implementation MyOFDelegate

static BOOL readyToStart = NO;
static BOOL challengeAcceptSelected = NO;
static BOOL playerIsChallenger = NO;
static BOOL inGame = NO;
static BOOL firstTime = YES;

@synthesize localPlayerName;
@synthesize challengerName;
@synthesize challengeeName;

-(void) dashboardWillAppear {
}

-(void) dashboardDidAppear {
	CCLOG(@"OF dashboard did appear");
	[[CCDirector sharedDirector] pause];
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) dashboardWillDisappear {
}

-(void) dashboardDidDisappear {
	CCLOG(@"OF dashboard did disappear");
	[[CCDirector sharedDirector] resume];
	[[CCDirector sharedDirector] startAnimation];
}

-(void) userLoggedIn:(NSString *)userId {
	OFLog(@"New user logged in! Hello %@", [OpenFeint lastLoggedInUserName]);
	if (self.localPlayerName == nil) {
		[self.localPlayerName release];
	}
	self.localPlayerName = [OpenFeint lastLoggedInUserName];
}

-(BOOL) showCustomOpenFeintApprovalScreen {
	return NO;
}

#pragma mark OFMultiplayerDelegate

-(void) gameDidStart:(OFMultiplayerGame *)game {
	CCLOG(@"GAME DID START");
}
//these are only required since the sample isn't using OpenGL and has to be manually updated
-(void) gameDidFinish:(OFMultiplayerGame *)game {
	CCLOG(@"GAME DID FINISH");
}

-(void) playerLeftGame:(unsigned int)playerNumber {
	CCLOG(@"player %i left the game", playerNumber);
}

- (void)networkDidUpdateLobby {
	OFMultiplayerGame *game = [OFMultiplayerService getSlot:0];
	CCLOG(@"--------------------------------------------");
	CCLOG(@"Network Did Update Lobby");
	CCLOG(@"GameManager Challenger Id = %@", [GameManager sharedGameManager].challengerId);
	CCLOG(@"GameManager Challengee Id = %@", [GameManager sharedGameManager].challengeeId);
	CCLOG(@"Game State (Unknown, Waiting to Start, Playing, Finished) = %i", [game state]);
	CCLOG(@"Slot Close State (Available, Closed, Rematch) = %i", [game slotCloseState]);
	CCLOG(@"Client Game Slot State (None, Creating Game ...) = %i", [game clientGameSlotState]);
	CCLOG(@"OF Challenger Id = %@", [game challengerOFUserId]);
	CCLOG(@"Player Count = %i", [game playerCount]);
	CCLOG(@"--------------------------------------------");
	
	if (!firstTime) {
		CCLOG(@"READY TO START");
		if ([game hasBeenChallenged]) {
			playerIsChallenger = NO;
			CCLOG(@"has been challenged. accept the challenge");
			[OFUser getUser:[[game playerOFUserIds] objectAtIndex:0]];
			//[NSThread sleepForTimeInterval:5];
			[OFMultiplayerService stopViewingGames];
		} else if ([game isStarted]) {
			CCLOG(@"game has started");
			if (![GameManager sharedGameManager].gameFinished) {
				CCLOG(@"Game not finished");
				return;
			}
			ChallengeRequestDialog *crd = (ChallengeRequestDialog *) [[[CCDirector sharedDirector] runningScene] getChildByTag:100];
			if (crd) {
				CCLOG(@"CRD IS NOT NULL && GAME STARTING");
				[crd okButtonPressed:self];
			}
			CCLOG(@"Entering game");
			[OFMultiplayerService stopViewingGames];
			[OFMultiplayerService enterGame:game];
			[GameManager sharedGameManager].isChallenger = NO;
			CCLOG(@"Starting game scene");
			[[GameManager sharedGameManager] runSceneWithId:kMutiPlayerScene];
			if (challengeAcceptSelected) {
				CCLOG(@"Reset Challenge Accepted to NO");
				challengeAcceptSelected = NO;
			}
		} else {
			if (challengeAcceptSelected) {
				CCLOG(@"CHALLENGER CANCELLED THE GAME");
				MainMenuLayer *mmLayer = (MainMenuLayer *) [[[CCDirector sharedDirector] runningScene] getChildByTag:1];
				[mmLayer showCancelChallengeMsg];
				challengeAcceptSelected = NO;
			}
		}
	} else {
		CCLOG(@"First Time, Closing any existing games");
		if (![GameManager sharedGameManager].gameStartedFromPushNotification) {
			[[GameManager sharedGameManager] closeGame];
		}
		firstTime = NO;
	}
}

-(void) networkFailureWithReason:(NSUInteger)reason {
}

//there are two methods of processing moves, either use the delegate or scan for moves in the game's tick
//see MPGameController.mm processNetMove to see the two options
-(BOOL)gameMoveReceived:(OFMultiplayerMove *)move {
	CCLOG(@"game move received");
	CCLOG(@"move object = %@", [move data]);
	NSString *text = [[NSString alloc] initWithData:[move data] encoding:NSUTF8StringEncoding];
	CCLOG(@"parsed string = %@", text);
	NSArray *tokens = [text componentsSeparatedByString:@"|"];
	NSString *command = [tokens objectAtIndex:0];
	int row = 0;
	int col = 0;
	NSString *val;
	
	Multiplayer *mp = (Multiplayer*) [[[CCDirector sharedDirector] runningScene] getChildByTag:0];
    
    //MCH
    PauseLayer *pauseLayer = (PauseLayer*) [[[CCDirector sharedDirector] runningScene] getChildByTag:2];

	
	if ([command isEqualToString:@"TILE_FLIP"]) {
		row = [[tokens objectAtIndex:1] intValue];
		col = [[tokens objectAtIndex:2] intValue];
		[mp tileFlipRow:row Col:col checkScore:YES];
	}
    
    if ([command isEqualToString:@"TILE_FLIP_NO_CHECK_SCORE"]) {
		row = [[tokens objectAtIndex:1] intValue];
		col = [[tokens objectAtIndex:2] intValue];
		[mp tileFlipRow:row Col:col checkScore:NO];
	}
	
	if ([command isEqualToString:@"INIT_MATRIX"]) {
		row = [[tokens objectAtIndex:1] intValue];
		col = [[tokens objectAtIndex:2] intValue];
		val = [tokens objectAtIndex:3];
		[mp setCellRow:row Col:col withValue:val];
	}
	
	if ([command isEqualToString:@"SELECT_TILE"]) {
		row = [[tokens objectAtIndex:1] intValue];
		col = [[tokens objectAtIndex:2] intValue];	
		[mp selectCellRow:row Col:col];
	}
	
	if ([command isEqualToString:@"DESELECT_TILE"]) {
		row = [[tokens objectAtIndex:1] intValue];
		col = [[tokens objectAtIndex:2] intValue];
		[mp deselectCellRow:row Col:col];
	}
	
	if ([command isEqualToString:@"INIT_END"]) {
		[mp scheduleUpdateTimer];
	}
	
	if ([command isEqualToString:@"START_GAME"]) {
		CCLOG(@"++++++++++++++++++++++GAME IS STARTING++++++++++++++++++++++");
	}
	
	if ([command isEqualToString:@"SOLVE_COUNTFLIP_NO"]) {
		[mp checkAnswer];
	}
	
	if ([command isEqualToString:@"INIT_STAR_POINT"]) {
		[mp clearStarPoints];
	}
	
	if ([command isEqualToString:@"STAR_POINT"]) {
		row = [[tokens objectAtIndex:1] intValue];
		col = [[tokens objectAtIndex:2] intValue];
		[mp setSPRow:row Col:col];
	}
	
	if ([command isEqualToString:@"TIMER_COUNTDOWN"]) {
        val = [tokens objectAtIndex:3];
		[mp setTimer:val];
	}
    //MCH -- game start countdown
	if ([command isEqualToString:@"GAMESTART_COUNTDOWN"]) {
		val = [tokens objectAtIndex:3];
		[mp setGameStartCountdownTimer:val];
	}
    //MCH -- supporting pause messages
    if ([command isEqualToString:@"TIMER_COUNTDOWN_TIMEOUT"]) {
		val = [tokens objectAtIndex:3];
		[pauseLayer processTimeoutCountdownRequest:val];
    }
    
    if ([command isEqualToString:@"PAUSE_GAME"]) {
		[mp pauseGame];
	}
    
    if ([command isEqualToString:@"RESUME_GAME"]) {
		[pauseLayer remoteResumeRequest];
	}
    
    if ([command isEqualToString:@"RESTART_GAME"]) {
		[pauseLayer restartGame];
	}

	
	return YES;
}


-(void) handlePushRequestGame:(OFMultiplayerGame*)game options:(NSDictionary*) options {
	CCLOG(@"handle push request game");
    //const NSSet* gameLaunchTypes = [NSSet setWithObjects:@"accept", @"start", @"finish", @"turn", nil];
    //const NSSet* gameLobbyTypes = [NSSet setWithObjects:@"challenge", nil];
	/*
	 if([gameLaunchTypes containsObject:[options objectForKey:@"type"]]) 
	 [MPClassRegistry showGameControllerWithGame:game];
	 else if([gameLobbyTypes containsObject:[options objectForKey:@"type"]]) {
	 
	 [MPClassRegistry showLobbyForSlot:game.gameSlot];
	 }
	 */
    
}

-(void) gameLaunchedFromPushRequest:(OFMultiplayerGame*)game withOptions:(NSDictionary*) options {
    OFLog(@"This is where we would launch game for slot %d type %s", game.gameSlot, [options objectForKey:@"type"]);
	[GameManager sharedGameManager].gameStartedFromPushNotification = YES;
    [self handlePushRequestGame:game options:options];
}


-(void) gameRequestedFromPushRequest:(OFMultiplayerGame*)game withOptions:(NSDictionary*) options {
}

- (void) gameSlotDidBecomeEmpty:(OFMultiplayerGame *)game {
	CCLOG(@"game slot became empty");
	
	ChallengeRequestDialog *crd = (ChallengeRequestDialog *) [[[CCDirector sharedDirector] runningScene] getChildByTag:100];
	if (crd) {
		CCLOG(@"CRD IS NOT NULL");
		[crd noCancelButtonPressed:self];
	}
}

- (void) gameSlotDidBecomeActive:(OFMultiplayerGame *)game {
	CCLOG(@"game slot became active");
}

- (void) gameDidAdvanceTurnToPlayerNumber:(unsigned int)playerNumber {
	CCLOG(@"game turn switched = %i", playerNumber);
	Multiplayer *mp = (Multiplayer*) [[[CCDirector sharedDirector] runningScene] getChildByTag:0];
	[mp switchTo:1 countFlip:NO];
}


#pragma mark actionsheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	challengeAcceptSelected = NO;
	OFMultiplayerGame *game = [OFMultiplayerService getSlot:0];
	if (buttonIndex == 0) {
		CCLOG(@"Accept Clicked");
		[game sendChallengeResponseWithAccept:YES];
		CCLOG(@"starting multiplayer game");
		[OpenFeint allowErrorScreens:YES];
		[OpenFeint dismissRootControllerOrItsModal];
		challengeAcceptSelected = YES;
	} else {
		CCLOG(@"Reject Clicked");
		[game sendChallengeResponseWithAccept:NO];
	}
	[OFMultiplayerService startViewingGames];
}

- (void) showActionSheet {
	NSString *titleText;
	
	if (self.challengerName == nil) {
		titleText = [NSString stringWithFormat:@"You have been challenged"];
	} else {
		titleText = [NSString stringWithFormat:@"You have been challenged by %@", self.challengerName];
	}
	
	UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:titleText delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Accept Challenge", @"Reject Challenge", nil];
	popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[popupQuery showInView:[CCDirector sharedDirector].openGLView];
	[popupQuery release];
}

#pragma mark friend picker
- (void)pickerFinishedWithSelectedUser:(OFUser*)selectedUser {
	[[GameManager sharedGameManager] sendChallengeToUserId:[selectedUser userId]];
	MainMenuLayer *mmLayer = (MainMenuLayer *) [[[CCDirector sharedDirector] runningScene] getChildByTag:1];
	[mmLayer disableMainMenu];
}

-(void) cancelChallenge {
	CCLOG(@"CANCEL CHALLENGE CALLED");
	[[GameManager sharedGameManager] closeGame];
    [GameManager sharedGameManager].isChallenger = NO;
	MainMenuLayer *mmLayer = (MainMenuLayer *) [[[CCDirector sharedDirector] runningScene] getChildByTag:1];
	[mmLayer enableMainMenu];
}

#pragma mark user_handling
-(void) didGetUser:(OFUser *)user {
	if ([GameManager sharedGameManager].isChallenger) {
		CCLOG(@"THIS PLAYER IS A CHALLENGER SO GETTING A CHALLENGEE NAME, NAME = %@", [user name]);
		self.challengeeName = [user name];
		ChallengeRequestDialog *challengeRequest = [[[ChallengeRequestDialog alloc] initWithActivityInd:YES 
																								 target:self 
																							   selector:@selector(cancelChallenge)] 
													autorelease];
		[[[CCDirector sharedDirector] runningScene] addChild:challengeRequest z:10 tag:100];
	} else {
		CCLOG(@"THIS PLAYER IS A CHALLENGEE SO GETTING A CHALLENGER NAME, NAME = %@", [user name]);
		self.challengerName = [user name];
		[self showActionSheet];
	}
}

-(void) didFailGetUser {
	CCLOG(@"fail to get user name");
	if (playerIsChallenger) {
		ChallengeRequestDialog *challengeRequest = [[[ChallengeRequestDialog alloc] initWithActivityInd:YES 
																								 target:self 
																							   selector:@selector(cancelChallenge)] 
													autorelease];
		[[[CCDirector sharedDirector] runningScene] addChild:challengeRequest z:10 tag:100];
	} else {
		[self showActionSheet];
	}
}

-(void) didGetFriendsWithThisApplication:(NSArray *)follows OFUser:(OFUser *)user {
    CCLOG(@"didGetFriendsWithThisApplication called");
    CCLOG(@"Number of Friends are = %i", [follows count]);
    CCLOG(@"Friends are = %@", follows);
    [GameManager sharedGameManager].hasFriendsWithThisApp = YES;
}

-(void) didFailGetFriendsWithThisApplicationOFUser:(OFUser *)user {
    CCLOG(@"Fail to Get Friends with This Applications");
}

#pragma mark OpenFeint Notification Delegate methods
-(BOOL) isOpenFeintNotificationAllowed:(OFNotificationData *)notificationData {
    CCLOG(@"Notification Data = %@", notificationData);
     if ([GameManager sharedGameManager].noTimeLeft) {
         CCLOG(@"No time left");
         return NO;
     }
    return YES;
}

-(void) handleDisallowedNotification:(OFNotificationData *)notificationData {
    /*
    if (!([notificationData notificationCategory] == kNotificationCategoryForeground && [GameManager sharedGameManager].noTimeLeft)) {
        [[CCNotifications sharedManager] addNotificationTitle:@"OpenFeint" message:[notificationData notificationText] image:@"Icon-Small.png" tag:1 animate:YES];
    }
    */
}

#pragma mark dealloc
- (void)dealloc {
	CCLOG(@"MyOFDelegate Dealloc Called");
	[challengeeName release];
	[challengerName release];
    [super dealloc];
	CCLOG(@"MyOFDelegate Dealloc End");
}

@end
