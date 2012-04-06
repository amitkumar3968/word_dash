//
//  Multiplayer.m
//  HundredSeconds
//
//  Created by Jae Kim on 12/12/11.
//  Copyright (c) 2011 experiencesquad. All rights reserved.
//

#import "Multiplayer.h"
#import "Cell.h"
#import "Dictionary.h"
#import "GameManager.h"
#import "ResultsLayer.h"
#import "PauseLayer.h"
#import "SimpleAudioEngine.h"
#import "AIDictionary.h"
#import "Parse/Parse.h"
#import "CCNotifications.h"
#import "PauseMenu.h"
#import "HundredSecondsAppDelegate.h"
#import "RootViewController.h"
#import "Util.h"
#import "HowToPlay.h"


@implementation Multiplayer

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	Multiplayer *layer = [Multiplayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
    
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) { 
        CGSize windowSize = [[CCDirector sharedDirector] winSize];
        passButton2.visible = NO;
        solveButton2.visible = NO;
        transparentBoundingBox2.visible = NO;
		greySolveButton2.visible = NO; 
        self.tapToChangeLeft.visible = NO;
        self.tapToChangeRight.visible = NO;
        pauseState = FALSE;
        pauseMenuPlayAndPass = [[PauseMenu alloc] init];
        [pauseMenuPlayAndPass addToMyScene:self];
        [[GCHelper sharedInstance] authenticateLocalUser];
        HundredSecondsAppDelegate *delegate = (HundredSecondsAppDelegate *) [UIApplication sharedApplication].delegate;  
        [[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 viewController:delegate.viewController delegate:self];
        
        ourRandom = arc4random();
        [self setGameState:kGameStateWaitingForMatch];
        myTurn = NO;
        self.playButton.visible = NO;
        [player1Name setString:@""];
        [player2Name setString:@""];
        

        
	}
	return self;
}

- (void) fadeOutLetters {
	for(int r = 0; r < rows ; r++) {
		for(int c = 0; c < cols; c++) {
			Cell *cell = [[wordMatrix objectAtIndex:r] objectAtIndex:c];
			if (r != rows - 1 || c != cols - 1) {
				[cell.letterSprite runAction:[CCSequence actions:[CCFadeOut actionWithDuration:3], [CCCallFuncN actionWithTarget:self selector:@selector(hideLetter:)], [CCFadeIn actionWithDuration:0.1], nil]];
			} else {
				[cell.letterSprite runAction:[CCSequence actions:[CCFadeOut actionWithDuration:3], [CCCallFuncN actionWithTarget:self selector:@selector(hideLetter:)], [CCFadeIn actionWithDuration:0.1], [CCCallFunc actionWithTarget:self selector:@selector(fadeInLetters)], nil]];
			}
		}
	}
}
 
 - (void) setStarPoints {
 
     int n = 0;
     
     if ([starPoints count] > 0) {
         return;
     }
 
     while (n < currentStarPoints) {
         NSLog(@"setting star points");
         int randomRow = arc4random() % rows;
         int randomCol = arc4random() % cols;
         Cell *cell = [[wordMatrix objectAtIndex:randomRow] objectAtIndex:randomCol];
     
         if (![self isThisStarPoint:cell]) {
             [starPoints addObject:cell];
             [self sendStarPointAtRow:randomRow atCol:randomCol];
             n++;
         }
     }
 }

- (void) openRandomLetters:(int) n {
	int openedLetters = 0;
	
	int closedLetters = 0;
	
	Cell *cell;
	
	for(int r = 0; r < rows; r++) {
		for(int c = 0; c < cols; c++) {
			cell = [[wordMatrix objectAtIndex:r] objectAtIndex:c];
			if (!cell.letterSprite.visible) {
				closedLetters++;
			}
		}
	}
	
	int maxOpenable = (n <= closedLetters)? n : closedLetters;
		
	while(openedLetters < maxOpenable) {
		int randomRow = arc4random() % rows;
		int randomCol = arc4random() % cols;
		cell = [[wordMatrix objectAtIndex:randomRow] objectAtIndex:randomCol];
        [self sendOpenCellAtRow:randomRow atCol:randomCol countScore:NO];
		if (!cell.letterSprite.visible) {
			cell.letterSprite.visible = YES;
			openedLetters++;
			if ([self isThisStarPoint:cell]) {
				cell.star.visible = YES;
			}
		}
	}
}

- (void) hideLetter:(id) sender {
    CCSprite *letter = (CCSprite *) sender;
    letter.visible = NO;
}

- (void) fadeInLetters {
    if (isPlayer1) {
        [self setStarPoints];
        [self openRandomLetters:3];
        gameCountdown = YES;
    }
}

- (void) playButtonPressed {
    

    
    if (isPlayer1) {
        [self sendGameBegin];
    }
    [self fadeOutLetters];
    self.playButton.visible = NO;
    playButtonReady = NO;
    [self schedule:@selector(updateTimer:) interval:1.0f];   
    
    //GET THE PLAYER WIN-LOSE-TIE HISTORY TO ADDRESS RACE CONDITION ISSUE IF RETRIEVE IT JUST IN TIME (SAVE CURRENT VS RETRIEVE W-L-T)
    [self getPlayersWinLoseTieHistory];
}

- (void) deselectCellsAt:(Cell *) cell {
    int startIndex = [userSelection indexOfObject:cell];
    int arrayLength = [userSelection count];
    for(int i = startIndex; i < arrayLength; i++) {
        Cell *cl = (Cell *) [userSelection objectAtIndex:i];
        cl.letterSelected.visible = NO;
        [self sendCellUnSelectedAtRow:cl.row atCol:cl.col];
    }
    [userSelection removeObjectsInRange:NSMakeRange(startIndex, arrayLength - startIndex)];
}

- (BOOL) ccTouchBegan:(UITouch *) touch withEvent:(UIEvent *) event {
    
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    
    if(CGRectContainsPoint(pauseMenuPlayAndPass.pauseButton.boundingBox, touchLocation) && !pauseState){
        pauseState = TRUE;
        [pauseMenuPlayAndPass showPauseMenu:self];
    }
    
    //CCLOG(@"In a pause state.");
    if(pauseState && CGRectContainsPoint([pauseMenuPlayAndPass mainMenuButton].boundingBox, touchLocation)){
        pauseState = NO;
        [self matchDisconnected];
        [[GameManager sharedGameManager] runSceneWithId:kMainMenuScene];
    } else if(pauseState && CGRectContainsPoint([pauseMenuPlayAndPass rematchButton].boundingBox, touchLocation)){
        pauseState = NO;
        [self matchDisconnected];
        [[GameManager sharedGameManager] runSceneWithId:kMutiPlayerScene];
    } else if(pauseState && CGRectContainsPoint([pauseMenuPlayAndPass howToPlayButton].boundingBox, touchLocation)){
        [[CCDirector sharedDirector] pushScene:[HowToPlay scene]];
    } else if(pauseState && CGRectContainsPoint([pauseMenuPlayAndPass resumeButton].boundingBox, touchLocation)){
        pauseState = NO;
        [pauseMenuPlayAndPass hidePauseMenu:self];
    }
    
    //MCH - JAE PROGRAMMING STYLE QUESTION, ONE RETURN POINT OR MULTIPLE?
    //DON'T EXECUTE GAME SCREEN FUNCTIONS FURTHER IF IN A PAUSE STATE
    if (pauseState) return TRUE;
    
    if (!myTurn) return;
    
    //PLAY BUTTON PRESSED
    if (playButtonReady && CGRectContainsPoint(_playButton.boundingBox, touchLocation)) {
        [self playButtonPressed];
        
    }
    
    if (!gameOver && !enableTouch) return TRUE;
    
	if (playerTurn == 1 && CGRectContainsPoint(transparentBoundingBox1.boundingBox, touchLocation)) {
		if ([userSelection count] > 0) {
			[self checkAnswer];
            [self sendCheckAnswer];
			[self switchTo:2 countFlip:NO notification:YES];
		} else {
            // JK - penalty
            [self openRandomLetters:1];
			[self switchTo:2 countFlip:YES notification:YES];
		}
	}
    
	for(int r = 0; r < rows; r++) {
		for(int c = 0; c < cols; c++) {
			Cell *cell = [[wordMatrix objectAtIndex:r] objectAtIndex:c];
			BOOL cellSelected = cell.letterSelected.visible;
			if (CGRectContainsPoint(cell.letterBackground.boundingBox, touchLocation)) {
				if (cell.letterSprite.visible && cellSelected) {
					[self deselectCellsAt:cell];
					[self updateAnswer];
				} else if (cell.letterSprite.visible && !cellSelected) {
                        if ([self allLettersOpened] && touch.tapCount > 2 && !tripleTabUsed) {
                            [self handleTripleTapWithCell:cell AtRow:r Col:c];
                            [self sendTripleTabAtRow:r atCol:c];
                        } else {
                            cell.letterSelected.visible = YES;
                            [userSelection addObject:cell];
                            [self updateAnswer];
                            [self sendCellSelectedAtRow:r atCol:c];
                        }
				} else {
					if (!player1TileFlipped) {
						cell.letterSprite.visible = YES;
						player1TileFlipped = YES;
                        [self sendOpenCellAtRow:r atCol:c countScore:YES];
						if ([self isVowel:cell.value]) {
							[self addScore:8 toPlayer:1 anchorCell:cell];
						}
						if ([self isThisStarPoint:cell]) {
							cell.star.visible = YES;
						}
					}
				}
			}
		}
	}
    
	return TRUE;
}

- (void) switchTo:(int) player countFlip:(BOOL) flag notification:(BOOL) notify {
	[self clearLetters];
    player1TileFlipped = NO;
    player2TileFlipped = NO;
        
    if (player == 1 && [[player1Timer string] intValue] > 0) {
        playerTurn = 1;	
        myTurn = YES;
        greySolveButton1.visible = NO;
        //[self showLeftChecker];
        [self turnOnPassButtonForPlayer1];
        waitForYourTurn.visible = NO;
    } else if (player == 2 && [[player2Timer string] intValue] > 0) {
        [self sendEndTurn];
        myTurn = NO;
        greySolveButton1.visible = YES;
        waitForYourTurn.visible = YES;
        //[self hideLeftChecker];
    }
}

-(BOOL) stopTimer {
    [self unschedule:@selector(updateTimer:)];
    
    return TRUE;
}

-(BOOL) startTimer {
    if (!playButtonReady) {
        [self schedule:@selector(updateTimer:) interval:1.0f];
    }
    
    return TRUE;
}

- (BOOL) getResultsPressed
{
    [[GameManager sharedGameManager] setPlayer1Score:[player1Score string]];
    [[GameManager sharedGameManager] setPlayer2Score:[player2Score string]];
    [[GameManager sharedGameManager] setPlayer1Words:player1Words];
    [[GameManager sharedGameManager] setPlayer2Words:player2Words];
    [[GameManager sharedGameManager] setGameMode:kMultiplayer];
    
    [[GameManager sharedGameManager] runLoadingSceneWithTargetId:kWordSummaryScene];
    
    return TRUE;
}

- (BOOL) rematchBtnPressed
{
    [[GameManager sharedGameManager] runLoadingSceneWithTargetId:kMutiPlayerScene];
    return TRUE;
}

- (BOOL) getPlayersWinLoseTieHistory
{
    
    NSArray *playersNameArray = [NSArray arrayWithObjects:self.player1LongName, self.player2LongName, nil];

    NSArray *sortedPlayersArray = [playersNameArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    NSString *firstOrderedPlayer = [sortedPlayersArray objectAtIndex:0];
    NSString *secondOrderedPlayer = [sortedPlayersArray objectAtIndex:1];

    CCLOG(@"First: %@ Second %@", firstOrderedPlayer,secondOrderedPlayer);

    CCLOG(@"%@",[NSString stringWithFormat:@"%@|%@",firstOrderedPlayer,secondOrderedPlayer]);
    PFQuery *query = [PFQuery queryWithClassName:@"GameHistorySummary"];
    [query whereKey:@"hashKey" equalTo:[NSString stringWithFormat:@"%@|%@",firstOrderedPlayer,secondOrderedPlayer]];
    [query whereKey:@"gameType" equalTo:@"Multiplayer"];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *gameResultsSummary, NSError *error) {
        if (!gameResultsSummary) {
            // failed.
            CCLOG(@"Failed to getFirstObject.");
            //IF THERE IS NO RECORD SET WIN, LOSS, TIE to zero
            currentPlayerVersusPlayerWins = 0;
            currentPlayerVersusPlayerLosses = 0;
            currentPlayerVersusPlayerTies = 0;
        } 
        else {
            // find succeeded
            NSLog(@"Find succeeded");
            
            if(![self.player1LongName compare:firstOrderedPlayer]){
                currentPlayerVersusPlayerWins = [[gameResultsSummary objectForKey:@"win"] intValue];
                currentPlayerVersusPlayerLosses = [[gameResultsSummary objectForKey:@"lose"] intValue];
                currentPlayerVersusPlayerTies = [[gameResultsSummary objectForKey:@"tie"] intValue];
            }
            else {
                currentPlayerVersusPlayerWins = [[gameResultsSummary objectForKey:@"lose"] intValue];
                currentPlayerVersusPlayerLosses = [[gameResultsSummary objectForKey:@"win"] intValue];
                currentPlayerVersusPlayerTies = [[gameResultsSummary objectForKey:@"tie"] intValue];
            }
        }
    }];

    return TRUE;
    
}
    
    

- (void) displayAwardsPopup
{
    //DELAY ENABLING THE BUTTONS (AWARDS MENU) SO THAT THE PLAYER DOES NOT
    //ACCIDENTALLY SELECT A BUTTON WHILE SELECTING THE LAST LETTERS
    [self schedule:@selector(enableAwardsMenuTouch:) interval:1.0f];
    
    //awardsMenu.isTouchEnabled=TRUE;
    awardsMenu.visible=TRUE;
    
    
    awardsState = TRUE;
    
    awardPopupTintedBackground.visible = YES;
    awardPopupFrame.visible = YES; 
    getResultsBtn.visible = YES; 
    rematchBtn.visible = YES;
    mainMenuBtn.visible = YES;
    awardsPopupBanner.visible = YES;
    
    getResultsBtn.position = ccp(210-43+10,125);
    rematchBtn.position = ccp(275-43+10,124);
    mainMenuBtn.position = ccp(340-43+10,124); 
        
    if ([[player1Score string] intValue] == [[player2Score string] intValue]) {
        [awardsPopupBanner setString:@"TIE GAME"];
        currentPlayerVersusPlayerTies++;
    }
    else if ([[player1Score string] intValue] > [[player2Score string] intValue]) {
        [awardsPopupBanner setString:[NSString stringWithFormat:@"WINNER: %@",self.player1LongName]];
        currentPlayerVersusPlayerWins++;
    }
    else{
        [awardsPopupBanner setString:[NSString stringWithFormat:@"WINNER: %@",self.player2LongName]];
        currentPlayerVersusPlayerLosses++;
    }
    
    awardsPopupBanner2.visible = YES;
    awardsPopupBanner3.visible = YES;
        
    [awardsPopupBanner2 setString:[NSString stringWithFormat:@"%@ vs %@:", 
                                   self.player1LongName,
                                   self.player2LongName]];
    [awardsPopupBanner3 setString:[NSString stringWithFormat:@"%i-%i-%i (Win-Lose-Tie)", 
                                   currentPlayerVersusPlayerWins,
                                   currentPlayerVersusPlayerLosses,
                                   currentPlayerVersusPlayerTies]];

    
    //HIDE THE PAUSE BUTTON
    //OPEN ISSUE -- pauseMenu.pauseButton.visible=NO;
    
    
}

- (void) updateTimer:(ccTime) dt {
	int p1 = [[player1Timer string] intValue];
	int p2 = [[player2Timer string] intValue];
	
	BOOL play1Done = NO;
	BOOL play2Done = NO;
	
	if (gameCountdown) {
		CCLOG(@"gameCountdown start");
		NSString *status = [gameCountDownLabel string];
		gameCountDownLabel.visible = YES;
		if ([status isEqualToString:@"Go!"]) {
			gameCountdown = NO;
			gameCountDownLabel.visible = NO;
            enableTouch = YES;
		} else {
			int x = [status intValue];
			if (x > 1) {
				[gameCountDownLabel setString:[NSString stringWithFormat:@"%i", --x]];
			} else {
				[gameCountDownLabel	setString:@"Go!"];
			}
			return;
		}
	}
	
	if (!enableTouch) {
		return;
	}
	
	if (p1+p2 <= 0) {
		gameOver = YES;
	}
    
    if (p1 <= 0) {
        play1Done = YES;
    }
    
    if (p2 <= 0) {
        play2Done = YES;
    }
    
	if (p1 <= 0 && [[player2Score string] intValue] > [[player1Score string] intValue]) {
        gameOver=YES;
	}
	
	if (p2 <= 0 && [[player1Score string] intValue] > [[player2Score string] intValue]) {
        gameOver=YES;
	}
    
	
	if (gameOver) {
        
        waitForYourTurn.visible = NO;
        [self sendGameOver];
        
        if (isPlayer1) {
            [self matchEnded];
        }
		enableTouch = NO;        
        [self stopTimer];
        
        if (isPlayer1) {
            [self saveGameResult];
        }
        
        [self displayAwardsPopup];
        
        
        
	} else {
		if (myTurn) {
			if (!play1Done) {
				--p1;
                if (p1 > 10) {
                    player1Timer.color = ccc3(155, 48, 255);
                } else {
                    player1Timer.color = ccc3(255, 0, 0);
                }
				[player1Timer setString:[NSString stringWithFormat:@"%i", p1]];
                [self sendTimer];
			} else {
				myTurn = NO;
				[self switchTo:2 countFlip:NO notification:YES];
			}
		}
	}	
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
    [otherPlayerID release];
    [pauseMenuPlayAndPass release];
	[super dealloc];
}

#pragma mark multiplayer

- (void)setGameState:(GameState)state {
    gameState = state;
}

- (void)sendData:(NSData *)data {
    NSError *error;
    BOOL success = [[GCHelper sharedInstance].match sendDataToAllPlayers:data withDataMode:GKMatchSendDataReliable error:&error];
    if (!success && gameState != kGameStateDone) {
        CCLOG(@"Error sending init packet");
        [self matchDisconnected];
    }
}

- (void)sendRandomNumber {
    
    MessageRandomNumber message;
    message.message.messageType = kMessageTypeRandomNumber;
    message.randomNumber = ourRandom;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageRandomNumber)];    
    [self sendData:data];
}

- (void)sendGameBegin {
    
    MessageGameBegin message;
    message.message.messageType = kMessageTypeGameBegin;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageGameBegin)];    
    [self sendData:data];
    
}

- (void) sendStarPointAtRow:(int) r atCol:(int) c {
    MessageCell message;
    message.message.messageType = kMessageTypeSetStarPoint;
    message.row = r;
    message.col = c;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
    [self sendData:data];
}

-(void) sendOpenCellAtRow:(int) r atCol:(int) c countScore:(BOOL)flag {
    MessageCell message;
    message.message.messageType = kMessageTypeOpenCell;
    message.row = r;
    message.col = c;
    message.countScore = flag;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
    [self sendData:data];
}

-(void) sendTimer {
    MessageTimer message;
    message.message.messageType = kMessageTypeSendTimer;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageTimer)];
    [self sendData:data];
}

-(void) sendTripleTabAtRow:(int) r atCol:(int) c {
    MessageCell message;
    message.message.messageType = kMessageTypeTripleTab;
    message.row = r;
    message.col = c;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
    [self sendData:data];
}

- (void) sendCellSelectedAtRow:(int) r atCol:(int) c {
    MessageCell message;
    message.message.messageType = kMessageTypeCellSelected;
    message.row = r;
    message.col = c;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
    [self sendData:data];
}

- (void) sendCellUnSelectedAtRow:(int) r atCol:(int) c {
    MessageCell message;
    message.message.messageType = kMessageTypeCellUnSelected;
    message.row = r;
    message.col = c;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
    [self sendData:data];
}

- (void) sendCheckAnswer {
    MessageCheckAnswer message;
    message.message.messageType = kMessageTypeCheckAnswer;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCheckAnswer)];
    [self sendData:data];
}

- (void) sendTileFlipCount:(int)cnt {
    MessageSendTileFlipCount message;
    message.message.messageType = kMessageTypeSendTileFlipCount;
    message.count = cnt;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageSendTileFlipCount)];
    [self sendData:data];
}

- (void) sendResetTileFlipCount {
    MessageResetTileFlipCount message;
    message.message.messageType = kMessageTypeResetTileFlipCount;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageResetTileFlipCount)];
    [self sendData:data];
}

- (void) sendEndTurn {
    MessageSendEndTurn message;
    message.message.messageType = kMessageTypeSendEndTurn;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageSendEndTurn)];
    [self sendData:data];
}

- (void)sendMove {
    
    MessageMove message;
    message.message.messageType = kMessageTypeMove;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageMove)];    
    [self sendData:data];
    
}

- (void)sendGameOver {
    
    MessageGameOver message;
    message.message.messageType = kMessageTypeGameOver;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageGameOver)];    
    [self sendData:data];
    
}

- (void) sendReadyToStartGame {
    MessageReadyToStartGame message;
    message.message.messageType = kMessageTypeReadyToStartGame;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageReadyToStartGame)];
    [self sendData:data];
}

- (void)setupStringsWithOtherPlayerId:(NSString *)playerID {
    self.player1LongName = [[GKLocalPlayer localPlayer] alias];
    //MCH - issue #16 not showing player names on result screens
    [[GameManager sharedGameManager] saveToUserDefaultsForKey:@"player1_name" Value:self.player1LongName];
    [player1Name setString:[Util formatName:self.player1LongName withLimit:8]];
    
    
    self.player2LongName = [[[GCHelper sharedInstance].playersDict objectForKey:playerID] alias];
    //MCH - issue #16 not showing player names on result screens
    [[GameManager sharedGameManager] saveToUserDefaultsForKey:@"player2_name" Value:self.player2LongName];
    [player2Name setString:[Util formatName:self.player2LongName withLimit:8]];
    
}


- (void) setCellAtRow:(int) r Col:(int) c Value:(NSString *) v Visible:(BOOL) isVisible StartPoint:(BOOL) isThisStarPoint EndTurn:(BOOL) endTurn {
    MessageCell message;
    message.message.messageType = kMessageTypeCell;
    message.row = r;
    message.col = c;
    message.isVisible = isVisible;
    message.isStarPoint = isThisStarPoint;
    message.endTurn = endTurn;
    message.ch = [v characterAtIndex:0];
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
    [self sendData:data];
}

- (void) sendPlayer1Board {
    for(int r = 0; r < self.rows; r++) {
        for(int c = 0; c < self.cols; c++) {
            Cell *cell = [[wordMatrix objectAtIndex:r] objectAtIndex:c];
            MessageCell message;
            message.message.messageType = kMessageTypeBoard;
            message.ch = [[cell.value lowercaseString] characterAtIndex:0];
            message.row = r;
            message.col = c;
            message.isVisible = cell.letterSprite.visible;
            message.isStarPoint = cell.star.visible;
            message.endTurn = NO;
            NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageCell)];
            [self sendData:data];
        }
    }
    MessageEndOfBoard endOfBoardMessage;
    endOfBoardMessage.message.messageType = kMessageTypeEndOfBoard;
    NSData *data = [NSData dataWithBytes:&endOfBoardMessage length:sizeof(MessageEndOfBoard)];
    [self sendData:data];
}

- (void)tryStartGame {
    
    if (isPlayer1 && gameState == kGameStateWaitingForStart) {
        [self sendPlayer1Board];
        [self setGameState:kGameStateActive];
    }
    [self setupStringsWithOtherPlayerId:otherPlayerID];
    
}

#pragma mark GCHelperDelegate

- (void) matchStarted {    
    CCLOG(@"################ Match started ###########################");   
    

    
    if (receivedRandom) {
        [self setGameState:kGameStateWaitingForStart];
    } else {
        [self setGameState:kGameStateWaitingForRandomNumber];
    }
    [self sendRandomNumber];
    [self tryStartGame];
}

- (void) inviteReceived {
    CCLOG(@"################ Invite Received ###########################"); 
    HundredSecondsAppDelegate *delegate = (HundredSecondsAppDelegate *) [UIApplication sharedApplication].delegate;  
    [[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 viewController:delegate.viewController delegate:self];
}

- (void) matchEnded {    
    CCLOG(@"Match ended");
    [self endScene:kEndReasonDisconnect];
    if (![self isGameOver]) {
        [self showGameDisconnectedAlert];
    }
    
    [[GCHelper sharedInstance].match disconnect];
    [GCHelper sharedInstance].match = nil;

}

- (void) matchDisconnected  {
    CCLOG(@"Match disconnected");
    [self stopTimer];

    [self endScene:kEndReasonDisconnect];
    
    [[GCHelper sharedInstance].match disconnect];
    [GCHelper sharedInstance].match = nil;
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    CCLOG(@"########### didReceiveData:fromPlayer ###########");
    // Store away other player ID for later
    if (otherPlayerID == nil) {
        otherPlayerID = [playerID retain];
    }
    
    Message *message = (Message *) [data bytes];
    
    if (message->messageType == kMessageTypeRandomNumber) {
        
        MessageRandomNumber * messageInit = (MessageRandomNumber *) [data bytes];
        CCLOG(@"Received random number: %ud, ours %ud", messageInit->randomNumber, ourRandom);
        bool tie = false;
        
        if (messageInit->randomNumber == ourRandom) {
            CCLOG(@"TIE!");
            tie = true;
            ourRandom = arc4random();
            [self sendRandomNumber];
        } else if (ourRandom > messageInit->randomNumber) {            
            CCLOG(@"We are player 1");
            isPlayer1 = YES;
            myTurn = YES;
            //self.playButton.visible = YES;
        } else {
            CCLOG(@"We are player 2");
            isPlayer1 = NO;
        }
        
        if (!tie) {
            receivedRandom = YES;    
            if (gameState == kGameStateWaitingForRandomNumber) {
                [self setGameState:kGameStateWaitingForStart];
            }
            [self tryStartGame];        
        }
        
    } else if (message->messageType == kMessageTypeGameBegin) {

        
        [self playButtonPressed];
        [self setGameState:kGameStateActive];
        //[self setupStringsWithOtherPlayerId:playerID];
        
    } else if (message->messageType == kMessageTypeSetStarPoint) {
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        CCLOG(@"[set star point messsage] row = %i", messageCell.row);
        CCLOG(@"[set star point messsage] col = %i", messageCell.col);
        Cell *cell = [[wordMatrix objectAtIndex:messageCell.row] objectAtIndex:messageCell.col];
        [starPoints addObject:cell];
    } else if (message->messageType == kMessageTypeOpenCell) {
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        CCLOG(@"[open cell] (row,col) = (%i,%i)", messageCell.row, messageCell.col);
        Cell *cell = [[wordMatrix objectAtIndex:messageCell.row] objectAtIndex:messageCell.col];
        cell.letterSprite.visible = YES;
        if ([self isThisStarPoint:cell]) {
            cell.star.visible = YES;
        }
        
        if (messageCell.countScore && [self isVowel:cell.value]) {
            [self addScore:8 toPlayer:2 anchorCell:cell];
        }
    } else if (message->messageType == kMessageTypeSendTimer) {
        CCLOG(@"Received Send Timer");
        [player2Timer setString:[NSString stringWithFormat:@"%i", [[player2Timer string] intValue]-1]];
    } else if (message->messageType == kMessageTypeMove) {     
        
        CCLOG(@"Received move");
              
    } else if (message->messageType == kMessageTypeBoard) {
        CCLOG(@"Received Board Definition");
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        CCLOG(@"row = %i", messageCell.row);
        CCLOG(@"col = %i", messageCell.col);
        CCLOG(@"visible = %i", messageCell.isVisible);
        CCLOG(@"starpoint = %i", messageCell.isStarPoint);
        CCLOG(@"end turn = %i", messageCell.endTurn);
        NSString *tmp = [NSString stringWithFormat:@"%c", messageCell.ch];
        CCLOG(@"tmp = %@", tmp); 
        [self removeCellAtRow:messageCell.row Col:messageCell.col];
        Cell *cell = [self cellWithCharacter:messageCell.ch atRow:messageCell.row atCol:messageCell.col];
        cell.letterSprite.visible = YES;
        [[wordMatrix objectAtIndex:messageCell.row] insertObject:cell atIndex:messageCell.col];
        [self switchTo:2 countFlip:NO notification:NO];
    } else if (message->messageType == kMessageTypeCellSelected) {
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        CCLOG(@"[select cell] (row,col) = (%i,%i)", messageCell.row, messageCell.col);
        Cell *cell = [[wordMatrix objectAtIndex:messageCell.row] objectAtIndex:messageCell.col];
        cell.letterSelected.visible = YES;
        [userSelection addObject:cell];
        [self updateAnswer];
    } else if (message->messageType == kMessageTypeCellUnSelected) {
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        CCLOG(@"[unselect cell] (row,col) = (%i,%i)", messageCell.row, messageCell.col);
        Cell *cell = [[wordMatrix objectAtIndex:messageCell.row] objectAtIndex:messageCell.col];
        cell.letterSelected.visible = NO;
        [userSelection removeObject:cell];
        [self updateAnswer];
    } else if (message->messageType == kMessageTypeTripleTab) {
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        Cell *cell = [[wordMatrix objectAtIndex:messageCell.row] objectAtIndex:messageCell.col];
        [self handleTripleTapWithCell:cell AtRow:messageCell.row Col:messageCell.col];
    } else if (message->messageType == kMessageTypeCheckAnswer) {
        playerTurn = 2;
        [self checkAnswerNoPenalty];
        [self switchTo:1 countFlip:NO notification:YES];
    } else if (message->messageType == kMessageTypeCell) {
        CCLOG(@"Received Set Cell");
        MessageCell messageCell;
        [data getBytes:&messageCell length:sizeof(MessageCell)];
        CCLOG(@"row = %i", messageCell.row);
        CCLOG(@"col = %i", messageCell.col);
        CCLOG(@"visible = %i", messageCell.isVisible);
        CCLOG(@"starpoint = %i", messageCell.isStarPoint);
        CCLOG(@"end turn = %i", messageCell.endTurn);
        NSString *tmp = [NSString stringWithFormat:@"%c", messageCell.ch];
        CCLOG(@"tmp = %@", tmp);        
    } else if (message->messageType == kMessageTypeSendTileFlipCount) {
        MessageSendTileFlipCount message;
        [data getBytes:&message length:sizeof(MessageSendTileFlipCount)];
        CCLOG(@"[set tile flip count] count = %i", message.count);
        countNoTileFlips = message.count;
    } else if (message->messageType == kMessageTypeResetTileFlipCount) {
        CCLOG(@"[reset tile flip count]");
        countNoTileFlips = 1;
    } else if (message->messageType == kMessageTypeSendEndTurn) {
        CCLOG(@"[end turn]");
        [self switchTo:1 countFlip:NO notification:YES];
    } else if (message->messageType == kMessageTypeGameOver) {   
        CCLOG(@"[game over]");
        gameOver = YES;
        [self matchEnded];     
    } else if (message->messageType == kMessageTypeEndOfBoard) {
        CCLOG(@"[end of board message received]");
        [self sendReadyToStartGame];
    } else if (message->messageType == kMessageTypeReadyToStartGame) {
        CCLOG(@"[ready to start game message received]");
        [self playButtonPressed];
    }
}

- (void) endScene:(EndReason)endReason {
    
    if (gameState == kGameStateDone) return;
    
    [self setGameState:kGameStateDone];
    
    /*
    if (isPlayer1) {
        if (endReason == kEndReasonDisconnect) {
            [self sendGameOver];
        }
    }
    */
}

- (void) checkAnswerNoPenalty {
	
	[midDisplay setString:@""];
	[midDisplay runAction:[CCFadeIn actionWithDuration:0.1f]];
    
	NSString *s = [NSString string];
	for(Cell *c in userSelection) {
		s = [s stringByAppendingString:c.value];
		c.letterSelected.visible = NO;
	}
	
	NSLog(@"user selection = %@", s);
	
	if ([foundWords objectForKey:s]) {
        // MCH -- play invalid word sound
        //[soundEngine playEffect:@"dull_bell.mp3"];
        [[[GameManager sharedGameManager] soundEngine] playEffect:@"dull_bell.mp3"];
		[midDisplay setString:@"Already Used"];
	} else {
		if ([s length] >= 3 && [dictionary objectForKey:s]) {
            [currentAnswer setColor:ccc3(124, 205, 124)];
			[foundWords setObject:s forKey:s];
            
            // MCH -- play success sound
            //[soundEngine playEffect:@"success.mp3"];
            [ [[GameManager sharedGameManager] soundEngine] playEffect:@"success.mp3"];
            
            
            //MCH -- add to each player's word's array for results scene
            if (playerTurn == 1) {
                [player1Words addObject:s];
            }
            else {
                [player2Words addObject:s];
            }
            
			int starCount = [self countStarPointandRemoveStars];
			int newPoint = pow(2, [s length]);
			[self addScore:newPoint toPlayer:playerTurn anchorCell: [userSelection objectAtIndex:0]];
            [self addMoreTime:(starCount * 10) toPlayer:playerTurn];
            if (starCount > 0 && playerTurn == 1) {
                [[CCNotifications sharedManager] addNotificationTitle:@"Time Extended !!" 
                                                              message:[NSString stringWithFormat:@"Congratulations, %i more seconds added.", starCount * 10] 
                                                                image:@"watchIcon.png" 
                                                                  tag:0 
                                                              animate:YES];
            }
		} else {
            [currentAnswer setColor:ccc3(238, 44, 44)];
            //[soundEngine playEffect:@"dull_bell.mp3"];
            [[[GameManager sharedGameManager] soundEngine] playEffect:@"dull_bell.mp3"];
            
			[midDisplay setString:@"Not a word"];
		}
	}
	[midDisplay runAction:[CCFadeOut actionWithDuration:1]];
	[userSelection removeAllObjects];
}


-(void) showGameDisconnectedAlert {
    UIAlertView *dialog = [[UIAlertView alloc] init];
    [dialog setDelegate:self];
    [dialog setTitle:@"Player Disconnected"];
    [dialog setMessage:[NSString stringWithFormat:@"%@ has been disconnected. Do you want to start over?", self.player2LongName]];
    [dialog addButtonWithTitle:@"Yes"];
    [dialog addButtonWithTitle:@"No"];
    [dialog show];
    [dialog release];
}
 
-(void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[GameManager sharedGameManager] runSceneWithId:kMainMenuScene];
    }
}

@end
