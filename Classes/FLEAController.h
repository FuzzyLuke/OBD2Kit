/*
 *  FLEAController.h
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

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>


extern NSString* const GoLinkScanToolConnectedNotification;
extern NSString* const GoLinkScanToolDisconnectedNotification;
extern NSString* const GoLinkScanToolProtocol;

@interface FLEAController : NSObject {
	EAAccessory*		_currentAccessory;	
	NSMutableArray*		_connectedAccessoryList;
	NSString*			_protocolSearchString;
}

// If you specify a protocol search string (e.g. "com.gopoint.p1"), then
// EAController will only provide delegate callbacks for the specified protocol.
// Otherwise, all devices that connect will generate callbacks.
@property (nonatomic, retain) NSString* protocolSearchString;


// EAController is a Singleton object
+ (FLEAController*) sharedController;


- (NSArray*) connectedAccessories;
- (EAAccessory*) accessoryForProtocol:(NSString*)protocol;

- (void) registerForNotifications;
- (void) loadConnectedAccessories;


@end