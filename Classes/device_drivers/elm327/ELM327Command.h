/*
 *  ELM327Command.h
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
#import "FLScanTool.h"
#import "FLScanToolCommand.h"

extern NSString *const kCarriageReturn;

// Common Commands
extern NSString *const kELM327Reset;
extern NSString *const kELM327EchoOff;
extern NSString *const kELM327HeadersOn;
extern NSString *const kELM327ReadVoltage;
extern NSString *const kELM327ReadProtocol;
extern NSString *const kELM327ReadProtocolNumber;
extern NSString *const kELM327ReadVersionID;
extern NSString *const kELM327ReadDeviceDescription;
extern NSString *const kELM327ReadDeviceIdentifier;
extern NSString *const kELM327SetDeviceIdentifier;


typedef enum {
	kELM327ATCommand				= 0x01,
	kELM327OBDCommand				= 0x02
} ELM327CommandType;


@interface ELM327Command : FLScanToolCommand {
	ELM327CommandType		_commandType;
	NSMutableString*		_command;
}


@property(nonatomic, retain) NSString* commandString;


+ (ELM327Command*) commandForReset;
+ (ELM327Command*) commandForEchoOff;
+ (ELM327Command*) commandForReadVoltage;
+ (ELM327Command*) commandForReadProtocol;
+ (ELM327Command*) commandForReadVersionID;
+ (ELM327Command*) commandForReadDeviceDescription;
+ (ELM327Command*) commandForReadDeviceIdentifier;
+ (ELM327Command*) commandForSetDeviceIdentifier:(NSString*)identifier;
+ (ELM327Command*) commandForHeadersOn;

+ (ELM327Command*) commandForOBD2:(FLScanToolMode)mode pid:(NSUInteger)pid data:(NSData*)data;


- initWithCommandString:(NSString*)command;


@end
