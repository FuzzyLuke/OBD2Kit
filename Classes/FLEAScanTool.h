/*
 *  FLEAScanTool.h
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
#import "FLScanTool.h"

@interface FLEAScanTool : FLScanTool <EAAccessoryDelegate, NSStreamDelegate> {
	EAAccessory*		_accessory;
    EASession*			_session;
    NSString*			_protocolString;
	
	NSMutableData*		_cachedWriteData;
	BOOL				_spaceAvailable;
}

@property (nonatomic, retain, readonly) EAAccessory* accessory;
@property (nonatomic, copy, readonly) NSString* protocolString;

- (void) configureScanToolAccessory:(EAAccessory*)accessory 
						forProtocol:(NSString*)protocol;
- (BOOL)openSession;
- (void)closeSession;
- (void)accessoryDidDisconnect:(EAAccessory *)accessory;
- (void)handleReadData;


@end
