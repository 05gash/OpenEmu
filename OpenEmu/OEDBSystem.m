/*
 Copyright (c) 2015, OpenEmu Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OEDBSystem.h"
#import "OESystemPlugin.h"
#import "OELibraryDatabase.h"

#import <OpenEmuSystem/OpenEmuSystem.h>

NS_ASSUME_NONNULL_BEGIN

NSString * const OEDBSystemsDidChangeNotification = @"OEDBSystemsDidChangeNotification";

@implementation OEDBSystem

+ (NSInteger)systemsCountInContext:(NSManagedObjectContext*)context
{
    return [self systemsCountInContext:context error:nil];
}

+ (NSInteger)systemsCountInContext:(NSManagedObjectContext*)context error:(NSError**)outError
{
    NSEntityDescription    *descr    = [self entityDescriptioninContext:context];
    NSFetchRequest         *req      = [[NSFetchRequest alloc] init];

    req.entity = descr;

    NSError    *error = outError != NULL ? *outError : nil;
    NSUInteger result = [context countForFetchRequest:req error:&error];
    if(result == NSNotFound)
    {
        result = 0;
        DLog(@"Error: %@", error);
    }
    return result;
}

+ (nullable NSArray <OEDBSystem *> *)allSystemsInContext:(NSManagedObjectContext *)context
{
    return [self allSystemsInContext:context error:nil];
}

+ (nullable NSArray <OEDBSystem *> *)allSystemsInContext:(NSManagedObjectContext *)context error:(NSError **)outError;
{
    NSArray <NSSortDescriptor *> *sortDesc = @[[NSSortDescriptor sortDescriptorWithKey:@"lastLocalizedName" ascending:YES]];

    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    req.sortDescriptors = sortDesc;

    NSArray *result = [context executeFetchRequest:req error:outError];
    if(result == nil && outError != nil)
        DLog(@"Error: %@", *outError);
    
    return result;
}

+ (NSArray <NSString *> *)allSystemIdentifiersInContext:(NSManagedObjectContext *)context
{
    NSArray <OEDBSystem *> *allSystems = [self allSystemsInContext:context];
    NSMutableArray <NSString *> *allSystemIdentifiers = [NSMutableArray arrayWithCapacity:allSystems.count];

    for(OEDBSystem *system in allSystems)
    {
        [allSystemIdentifiers addObject:system.systemIdentifier];
    }

    return allSystemIdentifiers;
}

+ (nullable NSArray <OEDBSystem *> *)enabledSystemsinContext:(NSManagedObjectContext *)context
{
    return [self enabledSystemsinContext:context error:nil];
}

+ (nullable NSArray <OEDBSystem *> *)enabledSystemsinContext:(NSManagedObjectContext *)context error:(NSError**)outError
{
    NSArray <NSSortDescriptor *> *sortDesc = @[[NSSortDescriptor sortDescriptorWithKey:@"lastLocalizedName" ascending:YES]];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"enabled = YES"];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    request.predicate = pred;
    request.sortDescriptors = sortDesc;

    NSArray *result = [context executeFetchRequest:request error:outError];
    if(result == nil && outError != nil)
        DLog(@"Error: %@", *outError);
    
    return result;
}

+ (NSArray <OEDBSystem *> *)systemsForFileWithURL:(NSURL *)url inContext:(NSManagedObjectContext *)context
{
    return [self systemsForFileWithURL:url inContext:context error:nil];
}

+ (NSArray <OEDBSystem *> *)systemsForFileWithURL:(NSURL *)url inContext:(NSManagedObjectContext *)context error:(NSError**)error
{
    __block OESystemPlugin *theOneAndOnlySystemThatGetsAChanceToHandleTheFile = nil;
    NSMutableArray         *otherSystemsThatMightBeAbleToHandleTheFile = [NSMutableArray array];
    
    NSString *fileExtension = url.pathExtension.lowercaseString;
    
    for(OESystemPlugin *systemPlugin in [OESystemPlugin allPlugins])
    {
        OESystemController *controller = systemPlugin.controller;

        if([controller canHandleFileExtension:fileExtension])
        {
            OECanHandleState handleState = [controller canHandleFile:url.path];
            
            if (handleState == OECanHandleYes)
            {
                theOneAndOnlySystemThatGetsAChanceToHandleTheFile = systemPlugin;
                break;
            }
            else if (handleState != OECanHandleNo)
            {
                [otherSystemsThatMightBeAbleToHandleTheFile addObject:systemPlugin];
            }
        }
    }
    
    if(theOneAndOnlySystemThatGetsAChanceToHandleTheFile != nil)
    {
        NSString *systemIdentifier = theOneAndOnlySystemThatGetsAChanceToHandleTheFile.systemIdentifier;
        OEDBSystem *system = [self systemForPluginIdentifier:systemIdentifier inContext:context];
        if([system.enabled boolValue])
            return @[ system ];
    }
    else
    {
        NSMutableArray <OEDBSystem *> *validSystems = [NSMutableArray arrayWithCapacity:otherSystemsThatMightBeAbleToHandleTheFile.count];
        for(OESystemPlugin *obj in otherSystemsThatMightBeAbleToHandleTheFile)
        {
             NSString *systemIdentifier = obj.systemIdentifier;
             OEDBSystem *system = [self systemForPluginIdentifier:systemIdentifier inContext:context];
             if([system.enabled boolValue])
                 [validSystems addObject:system];
        };
        return validSystems;
    }
    
    return [NSArray array];
}

+ (NSString *)headerForFileWithURL:(NSURL *)url forSystem:(NSString *)identifier
{
    OESystemPlugin *systemPlugin = [OESystemPlugin systemPluginForIdentifier:identifier];
    NSString *header = [systemPlugin.controller headerLookupForFile:url.path];
    
    return header;
}

+ (NSString *)serialForFileWithURL:(NSURL *)url forSystem:(NSString *)identifier
{
    OESystemPlugin *systemPlugin = [OESystemPlugin systemPluginForIdentifier:identifier];
    NSString *serial = [systemPlugin.controller serialLookupForFile:url.path];
    
    return serial;
}

+ (instancetype)systemForPlugin:(OESystemPlugin *)plugin inContext:(NSManagedObjectContext *)context
{
    NSString *systemIdentifier = plugin.systemIdentifier;
    __block OEDBSystem *system = [self systemForPluginIdentifier:systemIdentifier inContext:context];

    if(system) return system;

    [context performBlockAndWait:^{
        system = [OEDBSystem createObjectInContext:context];
        system.systemIdentifier = systemIdentifier;
        system.lastLocalizedName = system.name;

        [system save];
    }];

    return system;
}

+ (instancetype)systemForPluginIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context
{
    NSError    *error = nil;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"systemIdentifier == %@", identifier];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    request.predicate = pred;
    request.fetchLimit = 1;

    NSArray *result = [context executeFetchRequest:request error:&error];
    if(result == nil)
        DLog(@"Error: %@", error);
    
    return result.lastObject;
}

- (CGFloat)coverAspectRatio
{
    if(self.plugin != nil)
    {
        CGFloat aspectRatio = self.plugin.coverAspectRatio;
        if(aspectRatio != 0)
            return aspectRatio;
    }

    // in case system plugin has been removed return a default value
    return 1.365385;
}

#pragma mark - Core Data utilities

+ (NSString *)entityName
{
    return @"System";
}

+ (NSEntityDescription *)entityDescriptioninContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
}

#pragma mark - Data Model Properties

@dynamic lastLocalizedName, shortname, systemIdentifier, enabled;

#pragma mark - Data Model Relationships

@dynamic games;

- (nullable NSMutableSet <OEDBGame *> *)mutableGames
{
    return [self mutableSetValueForKey:@"games"];
}

#pragma mark -

- (OESystemPlugin *)plugin
{
    NSString *systemIdentifier = self.systemIdentifier;
    OESystemPlugin *plugin = [OESystemPlugin systemPluginForIdentifier:systemIdentifier];
    
    return plugin;
}

- (NSImage *)icon
{
    return self.plugin.systemIcon;
}

- (NSString *)name
{
    return self.plugin.systemName ?: self.lastLocalizedName;
}

#pragma mark - Debug

- (void)dump
{
    [self dumpWithPrefix:@"---"];
}

- (void)dumpWithPrefix:(NSString *)prefix
{
    NSString *subPrefix = [prefix stringByAppendingString:@"-----"];
    NSLog(@"%@ Beginning of system dump", prefix);

    NSLog(@"%@ System last localized name is %@", prefix, self.lastLocalizedName);
    NSLog(@"%@ short name is %@", prefix, self.shortname);
    NSLog(@"%@ system identifier is %@", prefix, self.systemIdentifier);
    NSLog(@"%@ enabled? %s", prefix, BOOL_STR(self.enabled));

    NSLog(@"%@ Number of games in this system is %lu", prefix, (unsigned long)self.games.count);

    for(id game in self.games)
    {
        if([game respondsToSelector:@selector(dumpWithPrefix:)]) [game dumpWithPrefix:subPrefix];
        else NSLog(@"%@ Game is %@", subPrefix, game);
    }

    NSLog(@"%@ End of system dump\n\n", prefix);
}

@end

NS_ASSUME_NONNULL_END
