/*
 *  BasicScanViewController.m
 *  BasicScan
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

#import "BasicScanViewController.h"
#import "FLLogging.h"
#import "FLECUSensor.h"

@interface BasicScanViewController(Private)
- (void) scan;
- (void) stopScan;
@end


#pragma mark -
@implementation BasicScanViewController

@synthesize statusLabel;
@synthesize scanToolNameLabel;
@synthesize rpmLabel;
@synthesize speedLabel;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self scan];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self stopScan];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[_scanTool release];
	[statusLabel release];
	[scanToolNameLabel release];
	[rpmLabel release];
	[speedLabel release];
    [super dealloc];
}

#pragma mark -
#pragma mark ScanToolDelegate Methods

- (void)scanDidStart:(FLScanTool*)scanTool {
	FLINFO(@"STARTED SCAN")
}

- (void)scanDidPause:(FLScanTool*)scanTool {
	FLINFO(@"PAUSED SCAN")
}

- (void)scanDidCancel:(FLScanTool*)scanTool {
	FLINFO(@"CANCELLED SCAN")
}

- (void)scanToolDidConnect:(FLScanTool*)scanTool {
	FLINFO(@"SCANTOOL CONNECTED")
}

- (void)scanToolDidDisconnect:(FLScanTool*)scanTool {
	FLINFO(@"SCANTOOL DISCONNECTED")
}


- (void)scanToolWillSleep:(FLScanTool*)scanTool {
	FLINFO(@"SCANTOOL SLEEP")
}

- (void)scanToolDidFailToInitialize:(FLScanTool*)scanTool {
	FLINFO(@"SCANTOOL INITIALIZATION FAILURE")
	FLDEBUG(@"scanTool.scanToolState: %@", scanTool.scanToolState)
	FLDEBUG(@"scanTool.supportedSensors count: %d", [scanTool.supportedSensors count])
}


- (void)scanToolDidInitialize:(FLScanTool*)scanTool {
	FLINFO(@"SCANTOOL INITIALIZATION COMPLETE")
	FLDEBUG(@"scanTool.scanToolState: %08X", scanTool.scanToolState)
	FLDEBUG(@"scanTool.supportedSensors count: %d", [scanTool.supportedSensors count])
	
	statusLabel.text			= @"Scanning...";
	
	[_scanTool setSensorScanTargets:[NSArray arrayWithObjects:
									 [NSNumber numberWithInt:0x0C], // Engine RPM
									 [NSNumber numberWithInt:0x0D], // Vehicle Speed
									 nil]];
	
	scanToolNameLabel.text	= _scanTool.scanToolName;
}


- (void)scanTool:(FLScanTool*)scanTool didSendCommand:(FLScanToolCommand*)command {
	FLINFO(@"DID SEND COMMAND")
}


- (void)scanTool:(FLScanTool*)scanTool didReceiveResponse:(NSArray*)responses {
	FLINFO(@"DID RECEIVE RESPONSE")
	[responses retain];	
	
	FLECUSensor* sensor	=	nil;
	
	for (FLScanToolResponse* response in responses) {
		
		sensor			= [FLECUSensor sensorForPID:response.pid];
		[sensor setCurrentResponse:response];
		
		if (response.pid == 0x0C) {
			// Update RPM Display
			rpmLabel.text	= [NSString stringWithFormat:@"%@ %@", [sensor valueStringForMeasurement1:NO], [sensor imperialUnitString]];
			[rpmLabel setNeedsDisplay];
		}
		else if(response.pid == 0x0D) {
			// Update Speed Display
			speedLabel.text	= [NSString stringWithFormat:@"%@ %@", [sensor valueStringForMeasurement1:NO], [sensor imperialUnitString]];
			[speedLabel setNeedsDisplay];
		}
	}
	
	[responses release];
}


- (void)scanTool:(FLScanTool*)scanTool didReceiveVoltage:(NSString*)voltage {
	FLTRACE_ENTRY
}


- (void)scanTool:(FLScanTool*)scanTool didTimeoutOnCommand:(FLScanToolCommand*)command {
	FLINFO(@"DID TIMEOUT")
}


- (void)scanTool:(FLScanTool*)scanTool didReceiveError:(NSError*)error {
	FLINFO(@"DID RECEIVE ERROR")
	FLNSERROR(error)
}

#pragma mark -
#pragma mark Private Methods

- (void) scan {
	
	statusLabel.text			= @"Initializing...";
	
	[_scanTool release];
	
	_scanTool					= [FLScanTool scanToolForDeviceType:kScanToolDeviceTypeELM327];
	[_scanTool retain];
	
	_scanTool.useLocation		= YES;
	_scanTool.delegate			= self;
	
	if(_scanTool.isWifiScanTool ) {
		// These are the settings for the PLX Kiwi WiFI, your Scan Tool may
		// require different.
		[_scanTool setHost:@"192.168.0.10"];
		[_scanTool setPort:35000];
	}
	
	[_scanTool startScan];
}

- (void) stopScan {
	if(_scanTool.isWifiScanTool) {
		[_scanTool cancelScan];
	}
	
	_scanTool.sensorScanTargets		= nil;
	_scanTool.delegate				= nil;
}

@end
