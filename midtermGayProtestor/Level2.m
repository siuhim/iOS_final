//
//  Level2.m
//  midtermGayProtestor
//
//  Created by Jimmy Tang on 4/29/14.
//  Copyright (c) 2014 Jimmy Tang. All rights reserved.
//

@import CoreMotion;

#import "Level2.h"
#import "Level3.h"
#import "MyScene.h"
#import "WelcomeScene.h"
#import "EndScene.h"

#import "FMMParallaxNode.h"

#define kNumAsteroids   25
#define kNumLasers      5

extern int globalScore;
extern int globalLive;


typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;


@implementation Level2

{
    SKSpriteNode *_ship;
    SKSpriteNode *_asteroid;
    
    SKLabelNode *_myScore;
    SKLabelNode *_myLive;
    
    CMMotionManager *_motionManager;
    
    NSMutableArray *_asteroids;
    int _nextAsteroid;
    double _nextAsteroidSpawn;
    
    SKAction *_hit;
    SKAction *_end;
    
    NSMutableArray *_shipLasers;
    int _nextShipLaser;
    
    int _levels;
    int _levelScoreInterval;
    
    float _beginTime;
    float _endTime;
    
    double _gameOverTime;
    bool _gameOver;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        //Background
        SKSpriteNode* background = [SKSpriteNode spriteNodeWithImageNamed:@"b-2"];
        background.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [background setXScale:0.5];
        [background setYScale:0.5];
        [self addChild:background];
        
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        
        //Main Character
        [self addCharacter];
        //Enemy
        [self addCop];
        //Laser
        [self addLaser];
        
        //Score
        _myScore = [[SKLabelNode alloc] initWithFontNamed:@"Minecraftia"];
        _myScore.text = @"Score: 0";
        _myScore.fontSize = 14;
        _myScore.fontColor = [SKColor blackColor];
        _myScore.position = CGPointMake(60, 20);
        [self addChild:_myScore];
        
        //Live
        _myLive = [[SKLabelNode alloc] initWithFontNamed:@"Minecraftia"];
        _myLive.text = @"Live: 0";
        _myLive.fontSize = 14;
        _myLive.fontColor = [SKColor blackColor];
        _myLive.position = CGPointMake(150, 20);
        [self addChild:_myLive];
        
        //Sound
        _hit = [SKAction playSoundFileNamed:@"hit.caf" waitForCompletion:NO];
        _end = [SKAction playSoundFileNamed:@"end.caf" waitForCompletion:NO];
        
        _motionManager = [[CMMotionManager alloc] init];
        
        //Start game
        [self startTheGame];
        
    }
    return self;
}

//////////Setup//////////

- (void) addCharacter {
    _ship = [SKSpriteNode spriteNodeWithImageNamed:@"main-2"];
    _ship.position = CGPointMake(self.frame.size.width * 0.15, CGRectGetMidY(self.frame));
    _ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_ship.frame.size];
    _ship.physicsBody.dynamic = YES;
    _ship.physicsBody.affectedByGravity = NO;
    _ship.physicsBody.mass = 0.1;
    [_ship setXScale:0.5];
    [_ship setYScale:0.5];
    [self addChild:_ship];
}

- (void) addCop {
    _asteroids = [[NSMutableArray alloc] initWithCapacity:kNumAsteroids];
    for (int i = 0; i < kNumAsteroids; ++i) {
        _asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"enemy-2"];
        _asteroid.hidden = YES;
        [_asteroids addObject:_asteroid];
        [_asteroid setXScale:0.5];
        [_asteroid setYScale:0.5];
        [self addChild:_asteroid];
    }
}

- (void) addLaser {
    _shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
    for (int i = 0; i < kNumLasers; ++i) {
        SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"laserbeam_rainbow"];
        shipLaser.hidden = YES;
        [_shipLasers addObject:shipLaser];
        [self addChild:shipLaser];
    }
}

- (void)startTheGame {
    _beginTime = 1.8;
    _endTime = 1.6;
    
    _levels = 1;
    _levelScoreInterval = 5;
    
    _nextAsteroidSpawn = 0;
    
    for (_asteroid in _asteroids) {
        _asteroid.hidden = YES;
    }
    
    _ship.hidden = NO;
    _myLive.hidden = NO;
    
    //reset ship position for new game
    _ship.position = CGPointMake(self.frame.size.width * 0.15, CGRectGetMidY(self.frame));
    
    for (SKSpriteNode *laser in _shipLasers) {
        laser.hidden = YES;
    }
    
    //setup to handle accelerometer readings using CoreMotion Framework
    [self startMonitoringAcceleration];
}

//////////Accelerator//////////

- (void)startMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
    }
}

- (void)stopMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
        [_motionManager stopAccelerometerUpdates];
    }
}

- (void)updateShipPositionFromMotionManager
{
    CMAccelerometerData* data = _motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.2) {
        [_ship.physicsBody applyForce:CGVectorMake(0.0, -40.0 * data.acceleration.x)];
    }
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

//////////Touch//////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //Shoot laser
    SKSpriteNode *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) {
        _nextShipLaser = 0;
    }
    
    shipLaser.position = CGPointMake(_ship.position.x+shipLaser.size.width/2,_ship.position.y+0);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    CGPoint location = CGPointMake(self.frame.size.width, _ship.position.y);
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^() {
        //NSLog(@"Animation Completed");
        shipLaser.hidden = YES;
    }];
    
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserMoveAction,laserDoneAction]];
    [shipLaser runAction:moveLaserActionWithDone withKey:@"laserFired"];
    
}

//////////Update//////////

-(void)update:(NSTimeInterval)currentTime {
    
    [self updateShipPositionFromMotionManager];
    
    //Win and Lose
    if (globalLive <= 0) {
        
        SKAction * loseAction = [SKAction runBlock:^{
            EndScene *endscene = [EndScene sceneWithSize:self.size];
            [self.view presentScene:endscene transition:[SKTransition doorsCloseHorizontalWithDuration:0.5]];
        }];
        
        [self runAction: loseAction];
        
    } else if (globalScore  >= 20) {
        
        SKAction * Level3Action = [SKAction runBlock:^{
            Level3 *level3 = [Level3 sceneWithSize:self.size];
            [self.view presentScene:level3 transition:[SKTransition crossFadeWithDuration:1.0]];
        }];
        
        [self runAction: Level3Action];
        
    }
    
    
    //Score, Live, Level
    [_myScore setText:[NSString stringWithFormat:@"SCORE: %d", globalScore]];
    [_myLive setText:[NSString stringWithFormat:@"LIVE: %d", globalLive]];
    
    
    //Cop Appeal
    double curTime = CACurrentMediaTime();
    if (curTime > _nextAsteroidSpawn) {
        float randSecs = [self randomValueBetween:_beginTime andValue:_endTime];
        
        _nextAsteroidSpawn = randSecs + curTime;
        
        float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];
        float randDuration = [self randomValueBetween:3.0 andValue:10.0];
        
        _asteroid = [_asteroids objectAtIndex:_nextAsteroid];
        _nextAsteroid++;
        
        if (_nextAsteroid >= _asteroids.count) {
            _nextAsteroid = 0;
        }
        
        if (globalScore > _levels * _levelScoreInterval) {
            _levels ++;
            _beginTime -= 0.2;
            _endTime -= 0.2;
        }
        
        [_asteroid removeAllActions];
        _asteroid.position = CGPointMake(self.frame.size.width+_asteroid.size.width/2, randY);
        _asteroid.hidden = NO;
        
        CGPoint location = CGPointMake(-self.frame.size.width-_asteroid.size.width, randY);
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {
            _asteroid.hidden = YES;
        }];
        
        SKAction *moveAsteroidActionWithDone = [SKAction sequence:@[moveAction, doneAction ]];
        [_asteroid runAction:moveAsteroidActionWithDone withKey:@"asteroidMoving"];
    }
    
    //check for laser collision with asteroid
    
    for (_asteroid in _asteroids) {
        if (_asteroid.hidden) {
            continue;
        }
        
        for (SKSpriteNode *shipLaser in _shipLasers) {
            if (shipLaser.hidden) {
                continue;
            }
            
            if ([shipLaser intersectsNode:_asteroid]) {
                globalScore++;
                
                //Sound
                [self runAction:_hit];
                
                shipLaser.hidden = YES;
                _asteroid.hidden = YES;
                
                continue;
            }
        }
        
        if ([_ship intersectsNode:_asteroid]) {
            _asteroid.hidden = YES;
            SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1], [SKAction fadeInWithDuration:0.1]]];
            SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
            [_ship runAction:blinkForTime];
            
            globalLive--;
        }
    }
    
}


@end
