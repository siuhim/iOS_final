//
//  EndScene.m
//  midtermGayProtestor
//
//  Created by Jimmy Tang on 4/29/14.
//  Copyright (c) 2014 Jimmy Tang. All rights reserved.
//

#import "EndScene.h"
#import "MyScene.h"

@implementation EndScene

-(instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        //Blackground
        self.backgroundColor = [SKColor blackColor];
        
        //Game Over
        SKLabelNode *label = [[SKLabelNode alloc] initWithFontNamed:@"Minecraftia"];
        label.text = @"GAME OVER";
        label.fontColor = [SKColor whiteColor];
        label.fontSize = 44;
        label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addChild:label];
        
        // Restart
        SKLabelNode *restartLabel = [[SKLabelNode alloc] initWithFontNamed:@"Minecraftia"];
        restartLabel.text = @"PLAY AGAIN?";
        restartLabel.fontColor = [SKColor whiteColor];
        restartLabel.fontSize = 30;
        restartLabel.position = CGPointMake(self.frame.size.width/2, -50);
        
        SKAction *movelabel = [SKAction moveToY:(self.frame.size.height * 0.3) duration:1.0];
        [restartLabel runAction:movelabel];
        
        [self addChild:restartLabel];

    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
                MyScene *level1 = [MyScene sceneWithSize:self.size];
                [self.view presentScene:level1 transition:[SKTransition doorsOpenHorizontalWithDuration:1.5]];

            

}


@end
