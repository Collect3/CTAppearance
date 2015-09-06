//
//  CTApperance.m
//  AppearanceTest
//
//  Created by David Fumberger on 11/09/2013.
//  Copyright (c) 2013 Collect3 Pty Ltd. All rights reserved.
//
#import <objc/runtime.h>
#import "CTAppearance.h"

static NSArray *CTAppearanceHierarchyForClass(Class klass) {
    NSMutableArray *classes = [[NSMutableArray alloc] initWithCapacity:0];
    while ([(id)klass conformsToProtocol:@protocol(CTAppearance)]) {
        [classes insertObject:klass atIndex:0];
        klass = [klass superclass];
    }
    return  classes;
}

static NSMutableDictionary *_CTAppearanceContainedDict = nil;
static NSMutableDictionary *_CTAppearanceDict = nil;
BOOL _CTAppearanceEnabled = YES;

@implementation CTAppearance
+ (void)initialize {
    _CTAppearanceContainedDict = [[NSMutableDictionary alloc] init];
    _CTAppearanceDict = [[NSMutableDictionary alloc] init];
}

+ (BOOL)isEnabled {
    return _CTAppearanceEnabled;
}

+ (void)setIsEnabled:(BOOL)isEnabled {
    _CTAppearanceEnabled = isEnabled;
}

+ (CTAppearance*)appearanceForClass:(Class)cls {
    id key = NSStringFromClass(cls);
    CTAppearance *a = [_CTAppearanceDict objectForKey: key];
    if (a == nil) {
        a = [[CTAppearance alloc] init];
        a.customizableClass = cls;
        [_CTAppearanceDict setObject:a forKey: key];
    }
    return a;
}

+ (CTAppearance*)appearanceForClass:(Class)cls whenContainedIn:(Class)containedIn extra:(va_list)args {
    Class classArg = containedIn;
    
    // Build up list of classes
    NSMutableArray *s = [NSMutableArray array];
    [s addObject: classArg];
    while( (classArg = va_arg( args, Class )) )  {
        [s addObject: classArg];
    }
    
    id key = cls;
    NSMutableArray *items = [_CTAppearanceContainedDict objectForKey: key];
    CTAppearance *a = nil;
    for (CTAppearance *item in items) {
        if ([item.containedIn isEqualToArray: s]) {
            a = item;
            break;
        }
    }
    if (a == nil) {
        a = [[CTAppearance alloc] init];
        a.customizableClass = cls;
        a.containedIn = s;
        if (items == nil) {
            [_CTAppearanceContainedDict setObject:[NSMutableArray arrayWithObject:a] forKey:key];
        } else {
            [items addObject: a];
        }
    }

    return a;
}

+ (NSArray*)appearanceParentsForClass:(Class)cls {
    NSArray *items = [_CTAppearanceContainedDict objectForKey: cls];
    return items;
}

// Invocations which retain arguments also retain all targets it is invoked with,
// and keeps them until the NSInvocation is dealloced (they are stored perpetually in
// an internal NSArray). Since all of our captured invocations are basically retained
// forever, we have to use a copy of the NSInvocation to do the actual perform lest
// we leak all of the objects we perform on.  We can avoid making the copy if the
// NSInvocation does not retain arguments.
+ (void)_performInvocation:(NSInvocation *)invocation onTarget:(id)target
{
    NSInvocation *invocationToUse = invocation;

    if (invocation.argumentsRetained)
    {
        NSMethodSignature *sig = invocation.methodSignature;
        NSInvocation *invokeCopy = [NSInvocation invocationWithMethodSignature:sig];
        invokeCopy.selector = invocation.selector;

        for (NSUInteger arg=2; arg<sig.numberOfArguments; arg++) {
            const char *objcType = [sig getArgumentTypeAtIndex:arg];
            NSUInteger valueSize;
            NSGetSizeAndAlignment(objcType, &valueSize, NULL);
            uint8_t buffer[valueSize];
            [invocation getArgument:buffer atIndex:arg];
            [invokeCopy setArgument:buffer atIndex:arg];
        }
        
        invocationToUse = invokeCopy;
    }
    
    [invocationToUse invokeWithTarget:target];
}

+ (void)_applyInvocations:(NSArray*)invocations target:(id)target {
    for (NSInvocation *invocation in invocations) {
        [self _performInvocation:invocation onTarget:target];
    }
}

+ (void)applyTo:(id)arg1 {
    NSArray *classes = CTAppearanceHierarchyForClass([arg1 class]);
    for (Class klass in classes) {
        CTAppearance *a = [self appearanceForClass: klass];
        [self _applyInvocations:a.invocations target: arg1];
    }
}

+ (void)applyContainedInTo:(id)arg1 forSuperview:(id)superview {
    NSMutableArray *superviews = nil;
    
    NSArray *hierarchyClasses = CTAppearanceHierarchyForClass([arg1 class]);
    
    for (Class klass in hierarchyClasses) {
        
        NSArray *parents = [self appearanceParentsForClass: klass];
        if (parents) {
            
            if (superviews == nil) {
                superviews = [NSMutableArray array];
                [self collateSuperviews: superview intoArray:superviews];
            }
            
            for (CTAppearance *a in parents) {
                BOOL valid = YES;
                for (Class c in a.containedIn) {
                    
                    BOOL found = NO;
                    for (UIView *sv in superviews) {
                        if ([sv isKindOfClass: c] || [sv isMemberOfClass:c]) {
                            found = YES;
                        }
                    }
                    
                    if (!found) {
                        valid = NO;
                        break;
                    }
                }
                if (valid) {
                    [self _applyInvocations:a.invocations target: arg1];
                }
            }
        }
    }
}

+ (void)collateSuperviews:(UIView*)superview intoArray:(NSMutableArray*)svs {
    if (superview) {
        [svs addObject: superview];
        [self collateSuperviews:superview.superview intoArray:svs];
    }
}

- (NSString*)description {
    NSString *d = [super description];
    NSString *containedIn = self.containedIn ? [NSString stringWithFormat:@" when contained in %@ ",  self.containedIn] : @"";
    return [NSString stringWithFormat:@"%@ <Customizable class: %@>%@ with invocations %@", d , NSStringFromClass(self.customizableClass), containedIn, self.invocations];
}

// If there are no object arguments, we don't need to have the invocation retain arguments.
// We use that fact to optimize invocation later on.
- (BOOL)_needsRetainArguments:(NSInvocation *)invocation
{
    NSMethodSignature *sig = [invocation methodSignature];

    for (NSUInteger i = 2; i < [sig numberOfArguments]; i++) {
        const char *objcType = [sig getArgumentTypeAtIndex:i];
        if (objcType[0] == _C_ID)
            return YES;
    }
    
    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (self.invocations == nil) {
        self.invocations = [NSMutableArray array];
    }
    [self.invocations addObject: anInvocation];
    if ([self _needsRetainArguments:anInvocation])
        [anInvocation retainArguments];
}

- (BOOL)instanceRespondToSelector:(SEL)aSelector {
    return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [self.customizableClass instanceMethodSignatureForSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self;
}

@end
