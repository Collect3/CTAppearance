//
//  CTAppearance+UIKit.m
//  AppearanceTest
//
//  Created by David Fumberger on 12/09/2013.
//  Copyright (c) 2013 Collect3 Pty Ltd. All rights reserved.
//

#import "CTAppearance+UIKit.h"
#import "CTAppearance.h"
#import <objc/runtime.h>

NSString const *_property_hasAppliedKey = @"CTAppearance_UIView_hasApplied";

@implementation UIView (CTAppearanceUIKitAdditions)
static void _CTAppearanceReplaceClassSelector(Class klass, SEL srcSelector, SEL dstSelector) {
    Method srcMethod = class_getClassMethod(klass, srcSelector);
    Method dstMethod = class_getClassMethod(klass, dstSelector);
    method_exchangeImplementations(dstMethod, srcMethod);
}

static void _CTAppearanceReplaceInstanceSelector(Class klass, SEL srcSelector, SEL dstSelector) {
    Method srcMethod = class_getInstanceMethod(klass, srcSelector);
    Method dstMethod = class_getInstanceMethod(klass, dstSelector);
    method_exchangeImplementations(dstMethod, srcMethod);
}

// Dynamically install the 'CT' appearance methods. These replace the native ones.
// If swizzling is wish to be avoided, then this can be disabled with the CTAPPEARANCE_DISABLE_AUTO_INSTALL macro and just
// call [view appearanceCT] and [view appearanceCTWhenContainedIn:] manually.
#ifndef CTAPPEARANCE_DISABLE_AUTO_INSTALL
+ (void)load {
    if ([UIApplication respondsToSelector:@selector(registerObjectForStateRestoration:restorationIdentifier:)]) {
        [CTAppearance setIsEnabled: YES];
        _CTAppearanceReplaceClassSelector([self class], @selector(appearance), @selector(appearanceCT));
        _CTAppearanceReplaceClassSelector([self class], @selector(appearanceWhenContainedIn:), @selector(appearanceCTWhenContainedIn:));
    } else {
        [CTAppearance setIsEnabled: NO];
    }
}
#endif

+ (id)appearanceCT {
    return [CTAppearance appearanceForClass: [self class]];
}

+ (id)appearanceCTWhenContainedIn:(__unsafe_unretained Class)containedIn, ... NS_REQUIRES_NIL_TERMINATION {
    va_list args;
    va_start(args, containedIn);
    id obj = [CTAppearance appearanceForClass:[self class] whenContainedIn:containedIn extra: args];
    va_end(args);
    return obj;
}

- (void)applyAppearanceForSuperview:(UIView*)superview {
    if (![CTAppearance isEnabled]) { return; }
    
    //NSLog(@"CTAppearance %@", NSStringFromClass([self class]));
    
    // Apply the appearances that dont rely on hiearchy only once
    if (![self hasAppliedAppearance]) {
        [CTAppearance applyTo: self];
        [self setHasAppliedAppearance:YES];
    }
    
    // Always apply the hierarchy appearances when moving superviews
    [CTAppearance applyContainedInTo: self forSuperview: superview];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (![CTAppearance isEnabled]) { return; }
    
    [self applyAppearanceForSuperview: newSuperview];
}

- (void)didMoveToSuperview {
    if (![CTAppearance isEnabled]) { return; }
    
    // Sanity check to apply appearance for anything that might not super'ing in willMoveToSuperview.
    if (![self hasAppliedAppearance]) {
        [self applyAppearanceForSuperview: self.superview];
    }
}

#pragma mark -
#pragma mark Associatd Objects
#pragma mark -
- (void)setHasAppliedAppearance:(BOOL)hasApplied {
    objc_setAssociatedObject(self, &_property_hasAppliedKey, [NSNumber numberWithBool:hasApplied], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hasAppliedAppearance {
    return [objc_getAssociatedObject(self, &_property_hasAppliedKey) boolValue];
}
@end