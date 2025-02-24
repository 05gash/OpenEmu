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

@import Foundation;
#import "OEDBItem.h"

@class OEDBGame, OESystemPlugin, OELibraryDatabase;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OEDBSystemsDidChangeNotification;

@interface OEDBSystem : OEDBItem

+ (NSInteger)systemsCountInContext:(NSManagedObjectContext *)context;
+ (NSInteger)systemsCountInContext:(NSManagedObjectContext *)context error:(NSError **)error;

+ (nullable NSArray <OEDBSystem *> *)allSystemsInContext:(NSManagedObjectContext *)context;
+ (nullable NSArray <OEDBSystem *> *)allSystemsInContext:(NSManagedObjectContext *)context error:(NSError **)error;

+ (NSArray <NSString *> *)allSystemIdentifiersInContext:(NSManagedObjectContext *)context;

+ (nullable NSArray <OEDBSystem *> *)enabledSystemsinContext:(NSManagedObjectContext *)context;
+ (nullable NSArray <OEDBSystem *> *)enabledSystemsinContext:(NSManagedObjectContext *)context error:(NSError **)outError;

+ (NSArray <OEDBSystem *> *)systemsForFileWithURL:(NSURL *)fileURL inContext:(NSManagedObjectContext *)context;
+ (NSArray <OEDBSystem *> *)systemsForFileWithURL:(NSURL *)fileURL inContext:(NSManagedObjectContext *)context error:(NSError**)error;

+ (NSString *)headerForFileWithURL:(NSURL *)URL forSystem:(NSString *)identifier;
+ (NSString *)serialForFileWithURL:(NSURL *)URL forSystem:(NSString *)identifier;

+ (instancetype)systemForPlugin:(OESystemPlugin *)plugin inContext:(NSManagedObjectContext *)context;
+ (instancetype)systemForPluginIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;

#pragma mark - Core Data utilities

@property (nonatomic, readonly) CGFloat coverAspectRatio;

#pragma mark - Data Model Properties

@property(nonatomic, retain, nullable) NSString *lastLocalizedName;
@property(nonatomic, retain, nullable) NSString *shortname;
@property(nonatomic, retain, nullable) NSString *systemIdentifier;
@property(nonatomic, retain, nullable) NSNumber *enabled;

#pragma mark - Data Model Relationships

@property(nonatomic, retain, nullable)   NSSet          <OEDBGame *> *games;
@property(nonatomic, readonly, nullable) NSMutableSet  <OEDBGame *> *mutableGames;

#pragma mark -

@property(readonly) OESystemPlugin *plugin;

@property(readonly) NSImage  *icon;
@property(readonly) NSString *name;

@end

NS_ASSUME_NONNULL_END
