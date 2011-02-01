/*
 *  ELM327Command.m
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

#import "ELM327Command.h"
#import "FLLogging.h"

NSString *const kCarriageReturn						= @"\r";

// Common Commands
NSString *const kELM327Reset						= @"AT WS";
NSString *const kELM327HeadersOn					= @"AT H1";
NSString *const kELM327EchoOff						= @"AT E0";
NSString *const kELM327ReadVoltage					= @"AT RV";
NSString *const kELM327ReadProtocol					= @"AT DP";
NSString *const kELM327ReadProtocolNumber			= @"AT DPN";
NSString *const kELM327ReadVersionID				= @"AT I";
NSString *const kELM327ReadDeviceDescription		= @"AT @1";
NSString *const kELM327ReadDeviceIdentifier			= @"AT @2";
NSString *const kELM327SetDeviceIdentifier			= @"AT @3";



@implementation ELM327Command

@synthesize commandString	= _command;



+ (ELM327Command*) commandForOBD2:(FLScanToolMode)mode pid:(NSUInteger)pid data:(NSData*)data {
	
	ELM327Command* cmd = nil;
	
	if (pid >= 0x00 && pid <= 0x4E) {
		cmd = [[ELM327Command alloc] initWithCommandString:[NSString stringWithFormat:@"%02x %02x", (NSUInteger)mode, pid]];	
	}
	else {
		cmd = [[ELM327Command alloc] initWithCommandString:[NSString stringWithFormat:@"%02x", (NSUInteger)mode]];	
	}

	if(data) {
		cmd.data = data;
	}
	
	return [cmd autorelease];
}


+ (ELM327Command*) commandForReset {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327Reset];
	return [cmd autorelease];
}

+ (ELM327Command*) commandForHeadersOn {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327HeadersOn];
	return [cmd autorelease];
}


+ (ELM327Command*) commandForEchoOff {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327EchoOff];
	return [cmd autorelease];	
}


+ (ELM327Command*) commandForReadVoltage {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327ReadVoltage];
	return [cmd autorelease];	
}


+ (ELM327Command*) commandForReadProtocol {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327ReadProtocolNumber];
	return [cmd autorelease];
}


+ (ELM327Command*) commandForReadVersionID {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327ReadVersionID];
	return [cmd autorelease];
}


+ (ELM327Command*) commandForReadDeviceDescription {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327ReadDeviceDescription];
	return [cmd autorelease];
}


+ (ELM327Command*) commandForReadDeviceIdentifier {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:kELM327ReadDeviceIdentifier];
	return [cmd autorelease];
}


+ (ELM327Command*) commandForSetDeviceIdentifier:(NSString*)identifier {
	ELM327Command* cmd = [[ELM327Command alloc] initWithCommandString:[NSString stringWithFormat:@"%@ %@", kELM327SetDeviceIdentifier, identifier]];
	return [cmd autorelease];
}


- initWithCommandString:(NSString*)command {
	
	if(self = [super init]) {
		_command = [[NSMutableString alloc] initWithString:command];
	}
	
	return self;
}


- (void) dealloc {
	[_command release];
	[super dealloc];
}


- (NSData*) data {
	[_command appendString:kCarriageReturn];
	FLDEBUG(@"Flushing command: %@", _command)
	return [_command dataUsingEncoding:NSASCIIStringEncoding];
}

@end
