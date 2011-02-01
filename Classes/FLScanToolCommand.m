/*
 *  FLScanToolCommand.m
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

#import "FLScanToolCommand.h"
#import "FLScanTool.h"

@implementation FLScanToolCommand

@synthesize mode	= _mode,
			pid		= _pid;

- (NSData*) data {
	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void) setData:(NSData *)data {
	[_data release];
	_data = nil;
	_data = [[NSData alloc] initWithData:data];
}


+ (FLScanToolCommand*) commandForMode:(int)mode 
								pid:(NSUInteger)pid 
							   data:(NSData*)data {

	// Abstract method
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
