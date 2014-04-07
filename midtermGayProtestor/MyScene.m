//
//  MyScene.m
//  midtermGayProtestor
//
//  Created by Jimmy Tang on 3/31/14.
//  Copyright (c) 2014 Jimmy Tang. All rights reserved.
//

@import CoreMotion;

#import "MyScene.h"
#import "FMMParallaxNode.h"

#define kNumAsteroids   15
#define kNumLasers      5

typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;


@implementation MyScene
{
    SKSpriteNode *_ship;    //1
    
    FMMParallaxNode *_parallaxNodeBackgrounds;
    FMMParallaxNode *_parallaxSpaceDust;
    
    CMMotionManager *_motionManager;
    
    NSMutableArray *_asteroids;
    int _nextAsteroid;
    double _nextAsteroidSpawn;
    
    NSMutableArray *_shipLasers;
    int _nextShipLaser;
    
    int _lives;
    
    double _gameOverTime;
    bool _gameOver;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        //2
        NSLog(@"SKScene:initWithSize %f x %f",size.width,size.height);
        
        //3
        self.backgroundColor = [SKColor blackColor];
        
        //Define your physics body around the screen - used by your ship to not bounce off the screen
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        
#pragma mark - Game Backgrounds
//        //1
//        NSArray *parallaxBackgroundNames = @[@"bg_galaxy.png", @"bg_planetsunrise.png",
//                                             @"bg_spacialanomaly.png", @"bg_spacialanomaly2.png"];
//        CGSize planetSizes = CGSizeMake(200.0, 200.0);
//        //2
//        _parallaxNodeBackgrounds = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackgroundNames
//                                                                           size:planetSizes
//                                                           pointsPerSecondSpeed:10.0];
//        //3
//        _parallaxNodeBackgrounds.position = CGPointMake(size.width/2.0, size.height/2.0);
//        //4
//        [_parallaxNodeBackgrounds randomizeNodesPositions];
//        
//        //5
//        [self addChild:_parallaxNodeBackgrounds];
//        
//        //6
//        NSArray *parallaxBackground2Names = @[@"bg_front_spacedust.png",@"bg_front_spacedust.png"];
//        _parallaxSpaceDust = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackground2Names
//                                                                     size:size
//                                                     pointsPerSecondSpeed:25.0];
//        _parallaxSpaceDust.position = CGPointMake(0, 0);
//        [self addChild:_parallaxSpaceDust];
        
        
        
#pragma mark - Setup Sprite for the ship
        //Create space sprite, setup position on left edge centered on the screen, and add to Scene
        //4
        _ship = [SKSpriteNode spriteNodeWithImageNamed:@"blondie-01.png"];
        _ship.position = CGPointMake(self.frame.size.width * 0.1, CGRectGetMidY(self.frame));
        
        
        //move the ship using Sprite Kit's Physics Engine
        //1
        _ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_ship.frame.size];
        
        //2
        _ship.physicsBody.dynamic = YES;
        
        //3
        _ship.physicsBody.affectedByGravity = NO;
        
        //4
        _ship.physicsBody.mass = 0.02;
        
        [self addChild:_ship];
        
#pragma mark - TBD - Setup the asteroids
        
        _asteroids = [[NSMutableArray alloc] initWithCapacity:kNumAsteroids];
        for (int i = 0; i < kNumAsteroids; ++i) {
            SKSpriteNode *asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"police-01"];
            asteroid.hidden = YES;
            [asteroid setXScale:0.5];
            [asteroid setYScale:0.5];
            [_asteroids addObject:asteroid];
            [self addChild:asteroid];
        }
        
#pragma mark - TBD - Setup the lasers
        _shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
        for (int i = 0; i < kNumLasers; ++i) {
            SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"laserbeam_rainbow"];
            shipLaser.hidden = YES;
            [_shipLasers addObject:shipLaser];
            [self addChild:shipLaser];
        }
        
#pragma mark - TBD - Setup the Accelerometer to move the ship
        
        _motionManager = [[CMMotionManager alloc] init];
        
#pragma mark - TBD - Setup the stars to appear as particles
        
//        [self addChild:[self loadEmitterNode:@"stars1"]];
//        [self addChild:[self loadEmitterNode:@"stars2"]];
//        [self addChild:[self loadEmitterNode:@"stars3"]];
        
#pragma mark - TBD - Start the actual game
        [self startTheGame];
        
    }
    return self;
}

//- (SKEmitterNode *)loadEmitterNode:(NSString *)emitterFileName
//{
//    NSString *emitterPath = [[NSBundle mainBundle] pathForResource:emitterFileName ofType:@"sks"];
//    SKEmitterNode *emitterNode = [NSKeyedUnarchiver unarchiveObjectWithFile:emitterPath];
//    
//    //do some view specific tweaks
//    emitterNode.particlePosition = CGPointMake(self.size.width/2.0, self.size.height/2.0);
//    emitterNode.particlePositionRange = CGVectorMake(self.size.width+100, self.size.height);
//    
//    return emitterNode;
//}

- (void)startTheGame
{
    
    _lives = 3;
    double curTime = CACurrentMediaTime();
    _gameOverTime = curTime + 30.0;
    _gameOver = NO;
    
    _nextAsteroidSpawn = 0;
    
    for (SKSpriteNode *asteroid in _asteroids) {
        asteroid.hidden = YES;
    }
    
    _ship.hidden = NO;
    
    //reset ship position for new game
    _ship.position = CGPointMake(self.frame.size.width * 0.1, CGRectGetMidY(self.frame));
    
    for (SKSpriteNode *laser in _shipLasers) {
        laser.hidden = YES;
    }
    
    //setup to handle accelerometer readings using CoreMotion Framework
    [self startMonitoringAcceleration];
    
    
}

- (void)startMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
        NSLog(@"accelerometer updates on...");
    }
}

- (void)stopMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
        [_motionManager stopAccelerometerUpdates];
        NSLog(@"accelerometer updates off...");
    }
}

- (void)updateShipPositionFromMotionManager
{
    CMAccelerometerData* data = _motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.2) {
        [_ship.physicsBody applyForce:CGVectorMake(0.0, 40.0 * data.acceleration.x)];
    }
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //check if they touched your Restart Label
    for (UITouch *touch in touches) {
        SKNode *n = [self nodeAtPoint:[touch locationInNode:self]];
        if (n != self && [n.name isEqual: @"restartLabel"]) {
            [[self childNodeWithName:@"restartLabel"] removeFromParent];
            [[self childNodeWithName:@"winLoseLabel"] removeFromParent];
            [self startTheGame];
            return;
        }
    }
    
    //do not process anymore touches since it's game over
    if (_gameOver) {
        return;
    }
    
    /* Called when a touch begins */
    //1
    SKSpriteNode *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) {
        _nextShipLaser = 0;
    }
    
    //2
    shipLaser.position = CGPointMake(_ship.position.x+shipLaser.size.width/2,_ship.position.y+0);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    //3
    CGPoint location = CGPointMake(self.frame.size.width, _ship.position.y);
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    //4
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^() {
        //NSLog(@"Animation Completed");
        shipLaser.hidden = YES;
    }];
    
    //5
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserMoveAction,laserDoneAction]];
    //6
    [shipLaser runAction:moveLaserActionWithDone withKey:@"laserFired"];
    
}


-(void)update:(NSTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    //Update background (parallax) position
    [_parallaxSpaceDust update:currentTime];
    [_parallaxNodeBackgrounds update:currentTime];
    
    [self updateShipPositionFromMotionManager];
    
    double curTime = CACurrentMediaTime();
    if (curTime > _nextAsteroidSpawn) {
        //NSLog(@"spawning new asteroid");
        float randSecs = [self randomValueBetween:0.20 andValue:1.0];
        _nextAsteroidSpawn = randSecs + curTime;
        
        float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];
        float randDuration = [self randomValueBetween:2.0 andValue:10.0];
        
        SKSpriteNode *asteroid = [_asteroids objectAtIndex:_nextAsteroid];
        _nextAsteroid++;
        
        if (_nextAsteroid >= _asteroids.count) {
            _nextAsteroid = 0;
        }
        
        [asteroid removeAllActions];
        asteroid.position = CGPointMake(self.frame.size.width+asteroid.size.width/2, randY);
        asteroid.hidden = NO;
        
        CGPoint location = CGPointMake(-self.frame.size.width-asteroid.size.width, randY);
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {
            //NSLog(@"Animation Completed");
            asteroid.hidden = YES;
        }];
        
        SKAction *moveAsteroidActionWithDone = [SKAction sequence:@[moveAction, doneAction ]];
        [asteroid runAction:moveAsteroidActionWithDone withKey:@"asteroidMoving"];
    }
    
    //check for laser collision with asteroid
    for (SKSpriteNode *asteroid in _asteroids) {
        if (asteroid.hidden) {
            continue;
        }
        for (SKSpriteNode *shipLaser in _shipLasers) {
            if (shipLaser.hidden) {
                continue;
            }
            
            if ([shipLaser intersectsNode:asteroid]) {
                shipLaser.hidden = YES;
                asteroid.hidden = YES;
                
                NSLog(@"you just destroyed an asteroid");
                continue;
            }
        }
        if ([_ship intersectsNode:asteroid]) {
            asteroid.hidden = YES;
            SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],
                                                   [SKAction fadeInWithDuration:0.1]]];
            SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
            [_ship runAction:blinkForTime];
            _lives--;
            NSLog(@"your ship has been hit!");
        }
    }
    
    // Add at end of update loop
    if (_lives <= 0) {
        NSLog(@"you lose...");
        [self endTheScene:kEndReasonLose];
    } else if (curTime >= _gameOverTime) {
        NSLog(@"you won...");
        [self endTheScene:kEndReasonWin];
    }
}

- (void)endTheScene:(EndReason)endReason {
    if (_gameOver) {
        return;
    }
    
    [self removeAllActions];
    [self stopMonitoringAcceleration];
    _ship.hidden = YES;
    _gameOver = YES;
    
    NSString *message;
    if (endReason == kEndReasonWin) {
        message = @"You win!";
    } else if (endReason == kEndReasonLose) {
        message = @"You lost!";
    }
    
    SKLabelNode *label;
    label = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    label.name = @"winLoseLabel";
    label.text = message;
    label.scale = 0.1;
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height * 0.6);
    label.fontColor = [SKColor yellowColor];
    [self addChild:label];
    
    SKLabelNode *restartLabel;
    restartLabel = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    restartLabel.name = @"restartLabel";
    restartLabel.text = @"Play Again?";
    restartLabel.scale = 0.5;
    restartLabel.position = CGPointMake(self.frame.size.width/2, self.frame.size.height * 0.4);
    restartLabel.fontColor = [SKColor yellowColor];
    [self addChild:restartLabel];
    
    SKAction *labelScaleAction = [SKAction scaleTo:1.0 duration:0.5];
    
    [restartLabel runAction:labelScaleAction];
    [label runAction:labelScaleAction];
    
}


@end
