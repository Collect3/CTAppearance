//
//  CTApperance.h
//  AppearanceTest
//
//  Created by David Fumberger on 11/09/2013.
//  Copyright (c) 2013 Collect3 Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CTAppearance <NSObject>
+ (id)appearanceCT;
+ (id)appearanceCTWhenContainedIn:(__unsafe_unretained Class)cls, ... NS_REQUIRES_NIL_TERMINATION;
@end

@interface CTAppearance : NSObject
@property (nonatomic, assign) Class customizableClass;
@property (nonatomic, strong) NSMutableArray *invocations;
@property (nonatomic, strong) NSMutableArray *containedIn;
+ (void)setIsEnabled:(BOOL)isEnabled;
+ (BOOL)isEnabled;
+ (CTAppearance*)appearanceForClass:(Class)cls;
+ (CTAppearance*)appearanceForClass:(Class)cls whenContainedIn:(Class)containedIn extra:(va_list)list;
+ (void)applyTo:(id)arg1;
+ (void)applyContainedInTo:(id)arg1 forSuperview:(id)superview;
@end
