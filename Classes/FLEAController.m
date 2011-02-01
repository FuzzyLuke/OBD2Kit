/*
 *  FLEAController.m
 *  OBD2Kit
 *
 *  Copyright (c) 2009-2011 FuzzyLuke Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import "FLEAController.h"
//#import "UIApplication+Alerts.h"
#import "FLLogging.h"

NSString* const GoLinkScanToolConnectedNotification		= @"GoLinkScanToolConnectedNotification";
NSString* const GoLinkScanToolDisconnectedNotification	= @"GoLinkScanToolDisconnectedNotification";


static FLEAController* g_sharedController = nil;

@interface FLEAController (Private)
- (void) _accessoryConnected:(NSNotification *)notification;
- (void) _accessoryDisconnected:(NSNotification *)notification;
@end

#pragma mark -
@implementation FLEAController

@synthesize protocolSearchString = _protocolSearchString;

#pragma mark -
#pragma mark Singleton

+ (FLEAController*) sharedController {
	@synchronized(self) {
        if (g_sharedController == nil) {
            [[self alloc] init];
			//[g_sharedController registerForNotifications];
			//[g_sharedController loadConnectedAccessories];
        }
    }
    return g_sharedController;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (g_sharedController == nil) {
            g_sharedController = [super allocWithZone:zone];
            return g_sharedController;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release {
	
}

- (id)autorelease {
    return self;
}

- (void) dealloc {
	[_protocolSearchString release];
	[_connectedAccessoryList release];
	[_currentAccessory release];
	[super dealloc];
}


#pragma mark -
#pragma mark Public Methods

- (NSArray*) connectedAccessories {
	return [NSArray arrayWithArray:_connectedAccessoryList];
}

- (EAAccessory*) accessoryForProtocol:(NSString*)protocol {
	
	EAAccessory* accessory = nil;
	
	for (EAAccessory* tempAccessory in _connectedAccessoryList) {
		if ([[tempAccessory protocolStrings] containsObject:protocol]) {
			accessory = tempAccessory;
			break;
		}
	}
	
	return accessory;
}

- (void) registerForNotifications {
	
	FLINFO(@"*** Registering for EA Notifications ***")
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(_accessoryConnected:) 
												 name:EAAccessoryDidConnectNotification 
											   object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(_accessoryDisconnected:) 
												 name:EAAccessoryDidDisconnectNotification 
											   object:nil];
	
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];    
}

- (void) loadConnectedAccessories {
	_connectedAccessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
	
	FLDEBUG(@"Found %d connected accessories", (_connectedAccessoryList) ? [_connectedAccessoryList count] : 0)
}

#pragma mark -
#pragma mark Private Notification Handlers

- (void) _accessoryConnected:(NSNotification *)notification {
	FLTRACE_ENTRY
    EAAccessory* connectedAccessory		= [[notification userInfo] objectForKey:EAAccessoryKey];
    [_connectedAccessoryList addObject:connectedAccessory];    
	
	NSString* accessoryName = [[NSString alloc] initWithString:[connectedAccessory name]];
	FLDEBUG(@"Found external accessory: %@", accessoryName);	
	
	NSRange range = [accessoryName rangeOfString:@"iPhone OBD Viewer"];
	[accessoryName release];
	
	if(range.length == 17) {
		
		[[NSNotificationCenter defaultCenter] postNotificationName:GoLinkScanToolConnectedNotification
															object:self 
														  userInfo:nil];
	}
	
}

- (void) _accessoryDisconnected:(NSNotification *)notification {
	FLTRACE_ENTRY
	EAAccessory* disconnectedAccessory	= [[notification userInfo] objectForKey:EAAccessoryKey];
	
    if (_currentAccessory && 
		[disconnectedAccessory connectionID] == [_currentAccessory connectionID]) {
    }
	
    int disconnectedAccessoryIndex		= 0;
    for(EAAccessory *accessory in _connectedAccessoryList) {
        if ([disconnectedAccessory connectionID] == [accessory connectionID]) {
            break;
        }
        disconnectedAccessoryIndex++;
    }
	
    if (disconnectedAccessoryIndex < [_connectedAccessoryList count]) {
        [_connectedAccessoryList removeObjectAtIndex:disconnectedAccessoryIndex];
		[[NSNotificationCenter defaultCenter] postNotificationName:GoLinkScanToolDisconnectedNotification
															object:self 
														  userInfo:nil];
    } else {
        FLERROR(@"could not find disconnected accessory in accessory list", nil);
    }
}


@end
