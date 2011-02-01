/*
 *  FLECUSensor.m
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

#import "FLECUSensor.h"
#import "FLLogging.h"

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Global Sensor Table


static MultiSensorDescriptor g_sensorDescriptorTable[] = {
	{
		0x00,
		/*Description							Short Description		Units Metric	Min Metric	Max Metric	Units Imperial	Min Imperial	Max Imperial	Calc Function	Convert Function*/	
		{ "Supported PIDs $00",					"",						NULL,			INT_MAX,	INT_MAX,	NULL,			INT_MAX,		INT_MAX,		NULL,			NULL },
 		{ }
	},
	{
		0x01,
		{ "Monitor status since DTCs cleared",	"Includes Malfunction Indicator Lamp (MIL) status and number of DTCs.",	NULL,	INT_MAX,	INT_MAX,	NULL,			INT_MAX,		INT_MAX,		NULL,			NULL },
		{ }		
	},
	{
		0x02,
		{ "Freeze Frame Status",				"",						NULL,			INT_MAX,	INT_MAX,	NULL,			INT_MAX,		INT_MAX,		NULL,			NULL },
		{ }
	},
	{
		0x03,
		/* PID $03 decodes to a string description, not a numeric value */
		{ "Fuel System Status", "Fuel Status", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x04,
		{ "Calculated Engine Load Value", "Eng. Load", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ }
	},
	{
		0x05,
		{ "Engine Coolant Temperature", "ECT", "˚C", -40, 215, "˚F", -40, 419, &calcTemp, &convertTemp },
		{ }
	},
	{
		0x06,
		{ "Short term fuel trim: Bank 1", "SHORTTF1", "%", -100, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage, NULL },
		{ }
	},
	{
		0x07,
		{ "Long term fuel trim: Bank 1", "LONGTF1", "%", -100, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage, NULL },	
		{ }
	},
	{
		0x08,
		{ "Short term fuel trim: Bank 2", "SHORTTF2", "%", -100, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage, NULL },
		{ }
	},
	{
		0x09,
		{ "Long term fuel trim: Bank 2", "LONGTF2", "%", -100, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage, NULL },
		{ }
	},
	{
		0x0A,
		{ "Fuel Pressure", "Fuel Pressure", "kPa", 0, 765, "inHg", 0, 222, NULL, &convertPressure },
		{ }
	},
	{
		0x0B,
		{ "Intake Manifold Pressure", "IMP", "kPa", 0, 255, "inHg", 0, 74, &calcInt, &convertPressure },
		{ }
	},
	{
		0x0C,
		{ "Engine RPM", "RPM", "RPM", 0, 16384, NULL, INT_MAX, INT_MAX, &calcEngineRPM, NULL },	
		{ }
	},
	{
		0x0D,
		{ "Vehicle Speed", "Speed", "km/h", 0, 255, "MPH", 0,	159, &calcInt, &convertSpeed },
		{ }
	},
	{
		0x0E,
		{ "Timing Advance", "Time Adv.", "i", -64, 64, NULL, INT_MAX, INT_MAX, &calcTimingAdvance, NULL },
		{ }
	},
	{			
		0x0F,
		{ "Intake Air Temperature", "IAT", "C", -40, 215, "F", -40, 419, &calcTemp, &convertTemp },
		{ }
	},
	{
		0x10,
		{ "Mass Air Flow", "MAF", "g/s", 0, 656, "lbs/min", 0, 87, &calcMassAirFlow, &convertAir },
		{ }
	},
	{
		0x11,
		{ "Throttle Position", "ATP", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ }
	},
	{
		0x12,
		/* PID $12 decodes to a string description, not a numeric value */
		{ "Secondary Air Status", "Sec Air", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x13,
		/* PID $13 decodes to a string description, not a numeric value	*/		
		{ "Oxygen Sensors Present", "O2 Sensors", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x14,
		{ "Oxygen Voltage: Bank 1, Sensor 1", "OVB1S1", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 1, Sensor 1", "STFB1S1", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x15,
		{ "Oxygen Voltage: Bank 1, Sensor 2", "OVB1S2", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 1, Sensor 2", "STFB1S2", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x16,
		{ "Oxygen Voltage: Bank 1, Sensor 3", "OVB1S3", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 1, Sensor 3", "STFB1S3", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x17,
		{ "Oxygen Voltage: Bank 1, Sensor 4", "OVB1S4", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 1, Sensor 4", "STFB1S4", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x18,
		{ "Oxygen Voltage: Bank 2, Sensor 1", "OVB1S1", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 2, Sensor 1", "STFB1S1", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x19,
		{ "Oxygen Voltage: Bank 2, Sensor 2", "OVB1S1", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 2, Sensor 2", "STFB1S2", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x1A,
		{ "Oxygen Voltage: Bank 2, Sensor 3", "OVB1S1", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 2, Sensor 3", "STFB1S3", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x1B,
		{ "Oxygen Voltage: Bank 2, Sensor 4", "OVB1S1", "V", 0, 2, NULL, INT_MAX, INT_MAX, &calcOxygenSensorVoltage, NULL },
		{ "Short Term Fuel Trim: Bank 2, Sensor 4", "STFB1S4", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcFuelTrimPercentage2, NULL }
	},
	{
		0x1C,
		/* PID $1C decodes to a string description, not a numeric value	*/
		{ "OBD standards to which this vehicle conforms", "OBD Standard", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x1D,
		/* PID $1D decodes to a string description, not a numeric value	*/
		{ "Oxygen Sensors Present", "O2 Sensors", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x1E,
		/* PID $1E decodes to a string description, not a numeric value	*/
		{ "Auxiliary Input Status", "Aux Input", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x1F,
		{ "Run Time Since Engine Start", "Run Time", "sec", 0, 65535, NULL, INT_MAX, INT_MAX, &calcTime, NULL },
		{ }
	},
	{
		0x20,
		/* PID 0x20: List Supported PIDs 0x21-0x3F */
		/* No calculation or conversion */
		{ },
		{ }
	},
	{
		0x21,
		{ "Distance traveled with malfunction indicator lamp (MIL) on", "MIL Traveled", "Km", 0, 65535, "miles", 0, 40717, &calcDistance, &convertDistance },
		{ }
	},
	{
		0x22,
		{ "Fuel Rail Pressure (Manifold Vacuum)", "Fuel Rail V.", "kPa", 0, 5178, "inHg", 0, 1502, &calcPressure, &convertPressure },
		{ }
	},
	{
		0x23,
		{ "Fuel Rail Pressure (Diesel)", "Fuel Rail D.", "kPa", 0, 655350, "inHg", 0, 190052, &calcPressureDiesel, &convertPressure },
		{ }
	},
	{
		0x24,
		{ "Equivalence Ratio: O2S1", "R O2S1", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S1", "V O2S1", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x25,
		{ "Equivalence Ratio: O2S2", "R O2S2", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S2", "V O2S2", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x26,
		{ "Equivalence Ratio: O2S3", "R O2S3", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S3", "V O2S3", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x27,
		{ "Equivalence Ratio: O2S4", "R O2S4", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S4", "V O2S4", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x28,
		{ "Equivalence Ratio: O2S5", "R O2S5", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S5", "V O2S5", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x29,
		{ "Equivalence Ratio: O2S6", "R O2S6", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S6", "V O2S6", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x2A,
		{ "Equivalence Ratio: O2S7", "R O2S7", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S7", "V O2S7", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x2B,
		{ "Equivalence Ratio: O2S8", "R O2S8", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Voltage: O2S8", "V O2S8", "V", 0, 8, NULL, INT_MAX, INT_MAX, &calcEquivalenceVoltage, NULL }
	},
	{
		0x2C,
		{ "Commanded EGR", "EGR", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ }
	},
	{
		0x2D,
		{ "EGR Error", "EGR Error", "%", -100, 100, NULL, INT_MAX, INT_MAX, &calcEGRError, NULL },
		{ }
	},
	{
		0x2E,
		{ "Commanded Evaporative Purge", "Cmd Purge", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ }
	},
	{
		0x2F,
		{ "Fuel Level Input", "Fuel Level", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ }
	},
	{
		0x30,
		{ "Number of Warm-Ups Since Codes Cleared", "# Warm-Ups", "", 0, 255, NULL, INT_MAX, INT_MAX, &calcInt, NULL },
		{ }
	},
	{
		0x31,
		{ "Distance Traveled Since Codes Cleared", "Cleared Traveled", "Km", 0, 65535, "miles", 0, 40717, &calcDistance, &convertDistance },
		{ }
	},
	{
		0x32,
		{ "Evaporative System Vapor Pressure", "Vapor Pressure", "Pa", -8192, 8192, "inHg", -3, 3, &calcVaporPressure, &convertPressure2 },
		{ }
	},
	{
		0x33,
		{ "Barometric Pressure", "Bar. Pressure", "kPa", 0, 255, "inHg", 0, 76, &calcInt, &convertPressure },
		{ }
	},
	{
		0x34,
		{ "Equivalence Ratio: O2S1", "R O2S1", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S1", "C O2S1", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x35,
		{ "Equivalence Ratio: O2S2", "R O2S2", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S2", "C O2S2", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x36,
		{ "Equivalence Ratio: O2S3", "R O2S3", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S3", "C O2S3", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x37,
		{ "Equivalence Ratio: O2S4", "R O2S4", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S4", "C O2S4", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x38,
		{ "Equivalence Ratio: O2S5", "R O2S5", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S5", "C O2S5", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x39,
		{ "Equivalence Ratio: O2S6", "R O2S6", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S6", "C O2S6", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x3A,
		{ "Equivalence Ratio: O2S7", "R O2S7", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S7", "C O2S7", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x3B,
		{ "Equivalence Ratio: O2S8", "R O2S8", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ "Current: O2S8", "C O2S8", "mA", -128, 128, NULL, INT_MAX, INT_MAX, &calcEquivalenceCurrent, NULL }
	},
	{
		0x3C,
		{ "Catalyst Temperature: Bank 1, Sensor 1", "CT B1S1", "C",-40, 6514, "F", -40, 11694, &calcCatalystTemp, &convertTemp },
		{ }
	},
	{
		0x3D,
		{ "Catalyst Temperature: Bank 2, Sensor 1", "CT B2S1", "C",-40, 6514, "F", -40, 11694, &calcCatalystTemp, &convertTemp },
		{ }
	},
	{
		0x3E,
		{ "Catalyst Temperature: Bank 1, Sensor 2", "CT B1S2", "C",-40, 6514, "F", -40, 11694, &calcCatalystTemp, &convertTemp },
		{ }
	},
	{
		0x3F,
		{ "Catalyst Temperature: Bank 2, Sensor 2", "CT B2S2", "C",-40, 6514, "F", -40, 11694, &calcCatalystTemp, &convertTemp },
		{ }
	},
	{
		0x40,
		/* PID 0x40: List Supported PIDs 0x41-0x5F */
		/* No calculation or conversion */
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x41,
		// TODO: Decode PID $41 correctly
		{ "Monitor status this drive cycle", "Monitor status", NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL },
		{ }
	},
	{
		0x42,
		{ "Control Module Voltage", "Ctrl Voltage", "V", 0, 66, NULL, INT_MAX, INT_MAX, &calcControlModuleVoltage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x43,
		{ "Absolute Load Value", "Abs Load Val", "%", 0, 25700, NULL, INT_MAX, INT_MAX, &calcAbsoluteLoadValue, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x44,
		{ "Command Equivalence Ratio", "Cmd Equiv Ratio", "", 0, 2, NULL, INT_MAX, INT_MAX, &calcEquivalenceRatio, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x45,
		{ "Relative Throttle Position", "Rel Throttle Pos", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},	
	{		
		0x46,
		{ "Ambient Air Temperature", "Amb Air Temp", "C", -40, 215, "F", -104, 355, &calcTemp, &convertTemp },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x47,
		{ "Absolute Throttle Position B", "Abs Throt Pos B", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x48,
		{ "Absolute Throttle Position C", "Abs Throt Pos C", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x49,
		{ "Accelerator Pedal Position D", "Abs Throt Pos D", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x4A,
		{ "Accelerator Pedal Position E", "Abs Throt Pos E", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x4B,
		{ "Accelerator Pedal Position F", "Abs Throt Pos F", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x4C,
		{ "Commanded Throttle Actuator", "Cmd Throttle Act", "%", 0, 100, NULL, INT_MAX, INT_MAX, &calcPercentage, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x4D,
		{ "Time Run With MIL On", "MIL Time On", "min", 0, 65535, NULL, INT_MAX, INT_MAX, &calcTime, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	},
	{
		0x4E,
		{ "Time Since Trouble Codes Cleared", "DTC Cleared Time", "min", 0, 65535, NULL, INT_MAX, INT_MAX, &calcTime, NULL },
		{ NULL, NULL, NULL, INT_MAX, INT_MAX, NULL, INT_MAX, INT_MAX, NULL, NULL }
	}	
};

#pragma mark -
#pragma mark Private Methods
@interface FLECUSensor(StringValueMethods)
- (NSString*) calculateStringForData:(NSData*)data;
- (NSString*) calculateAuxiliaryInputStatus:(NSData*)data;
- (NSString*) calculateDesignRequirements:(NSData*)data;
- (NSString*) calculateOxygenSensorsPresent:(NSData*)data;
- (NSString*) calculateOxygenSensorsPresentB:(NSData*)data;
- (NSString*) calculateFuelSystemStatus:(NSData*)data;
- (NSString*) calculateSecondaryAirStatus:(NSData*)data;

- (void) addValueHistoryForCurrentResponse;
@end


#pragma mark -
@implementation FLECUSensor

+ (FLECUSensor*) sensorForPID:(NSUInteger)pid {
	FLECUSensor* sensor		= nil;
	
	if(pid >= 0x0 && pid <= 0x4E) {
		sensor			= [[FLECUSensor alloc] initWithDescriptor:&g_sensorDescriptorTable[pid]];
	}
	
	return [sensor autorelease];
}

+ (NSArray*) troubleCodesForResponse:(FLScanToolResponse*)response {
	
	const char systemCode[4]	= { 'P', 'C', 'B', 'U' };	
	uint8_t* data				= (uint8_t*)[response.data bytes];
	int dataLength				= [response.data length];	
	NSMutableArray* codes		= nil;
	
	@try {
		FLDEBUG(@"dataLength = %d", dataLength)
		
		if(NULL == data || dataLength < 2) {
			//(dataLength % 2) != 0) {
			// We have changed the dataLength check to allow for cases in
			// which an ECU returns a data stream that is not a multiple of 2.
			// Though technically an error condition, in real world testing this
			// appears to be more common than previously anticipated.
			// - mgile 08-Feb-2010
			
			FLERROR(@"data (0x%08X) is NULL or dataLength is not a multiple of 2 (%d)", data, dataLength)
			// data length must be a multiple of 2
			// each DTC is encoded in 2 bytes of data
			return nil;
		}
		else {
			codes				= [[NSMutableArray alloc] initWithCapacity:(dataLength / 2)];
		}

		
		for(int i=0; i < dataLength; i+=2) {
			[codes addObject:[NSString stringWithFormat:@"%c%02X%02X",
														systemCode[(data[i] & DTC_SYSTEM_MASK)], 
														(data[i] & DTC_DIGIT_0_1_MASK),
														(data[i+1] & DTC_DIGIT_2_3_MASK)]];
			
			
			// We do a check here to make sure that the remaining
			// data is either greater than 2 bytes (a DTC size),
			// or is a multiple of 2, otherwise we exit the loop
			if((dataLength - (i+2)) < 2 &&
			   (dataLength - (i+2)) % 2 != 0) {
				break;
			}
		}
	}
	@catch (NSException * e) {
		FLEXCEPTION(e)
	}
	@finally {
		;
	}
	
	
	return [NSArray arrayWithArray:[codes autorelease]];
}


- initWithDescriptor:(MultiSensorDescriptor*)descriptor {
	
	if(self = [super init]) {
		_sensorDescriptor = descriptor;
	}
	
	return self;
}


- (void)dealloc {
	[_sensorValueHistory release];
	[_currentResponse release];
	
	[super dealloc];
}


- (FLScanToolResponse*) currentResponse {
	return _currentResponse;
}

- (void) setCurrentResponse:(FLScanToolResponse*)response {
		
	if(response) {		
		if(response.pid == self.pid) {
			[_currentResponse release];
			_currentResponse = [response retain];
			[self addValueHistoryForCurrentResponse];
		}		
	}	
}

- (NSArray*) valueHistory {
	
	// TODO: Figure out why this doesn't respect the NSRange length value when count > 32
	//return [_sensorValueHistory objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_valueHistoryHead, (_valueHistoryTail + 1))]];
	
	if([_sensorValueHistory count] > 0) {
		NSMutableArray* values = [[NSMutableArray arrayWithCapacity:(_valueHistoryTail - _valueHistoryHead - 1)] retain];
		
		for(NSUInteger idx = _valueHistoryHead; idx <= _valueHistoryTail; idx++) {
			[values addObject:[_sensorValueHistory objectAtIndex:idx]];
		}
		
		return [NSArray arrayWithArray:[values autorelease]];
	}
	
	return nil;	
}


- (BOOL) isAlphaValue {	
	return IS_ALPHA_VALUE(self.pid);
}

- (BOOL) isMultiValue {
	return IS_MULTI_VALUE_SENSOR(self.pid);
}


- (NSUInteger) pid {
	return _sensorDescriptor->pid;
}


- (NSData*) data {
	return _currentResponse.data;
}


- (void) addValueHistoryForCurrentResponse {
	
	@try {
		
		if(!_sensorValueHistory) {
			_sensorValueHistory = [[NSMutableArray arrayWithCapacity:64] retain];
			_valueHistoryHead	= 0;
			_valueHistoryTail	= 0;
		}
		
		if([_sensorValueHistory count] >= 64) {
			const NSUInteger removalList[] = {
				0, 1, 2, 3, 4, 5, 6, 7, 8,
				9, 10, 11, 12, 13, 14, 15,
				16, 17, 18, 19, 20, 21, 22,
				23, 24, 25, 26, 27, 28, 29,
				30, 31
			};
			
			[_sensorValueHistory removeObjectsFromIndices:(NSUInteger*)removalList numIndices:32];
			//[_sensorValueHistory removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 32)]];
			_valueHistoryHead = 0;
			_valueHistoryTail = 32;
		}


			
		[_sensorValueHistory addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										   [self valueForMeasurement1:YES], @"measurement1Metric", 
										   [self valueForMeasurement1:NO], @"measurement1Imperial", 
										   [self valueForMeasurement2:YES], @"measurement2Metric", 
										   [self valueForMeasurement2:NO], @"measurement2Imperial", 
										   nil]];
		
		NSUInteger count	= [_sensorValueHistory count];
		_valueHistoryHead	= (count > 32) ? (count - 32) : 0;
		_valueHistoryTail	= count - 1;
	}
	@catch (NSException * e) {
		FLEXCEPTION(e)
	}
	@finally {

	}
}

- (BOOL) isMILActive {
	if(self.pid == 0x01) {
		if(calcMILActive([_currentResponse.data bytes], [_currentResponse.data length])) {
			return YES;
		}
	}
	
	return NO;
}


- (NSInteger) troubleCodeCount {
	if(self.pid == 0x01) {
		return calcNumTroubleCodes([_currentResponse.data bytes], [_currentResponse.data length]);
	}
	
	return 0;
}


- (id) valueForMeasurement1:(BOOL)metric {
	
	if (!_currentResponse.data) {
		return nil;
	}
	
	if(self.isAlphaValue) {
		return [self calculateStringForData:_currentResponse.data];
	}
	
	if(_sensorDescriptor->sensorDescriptor1.calcFunction) {
		
		float val = _sensorDescriptor->sensorDescriptor1.calcFunction(_currentResponse.data.bytes, _currentResponse.data.length);
		
		if(!metric && _sensorDescriptor->sensorDescriptor1.convertFunction) {
			val = _sensorDescriptor->sensorDescriptor1.convertFunction(val);			
		}
		
		return [NSNumber numberWithFloat:val];
	}
	else {
		return nil;
	}
}

- (id) valueForMeasurement2:(BOOL)metric {
	
	if(!!_currentResponse.data || !self.isMultiValue) {
		return nil;
	}
	
	if(_sensorDescriptor->sensorDescriptor2.calcFunction) {
		float val = _sensorDescriptor->sensorDescriptor2.calcFunction(_currentResponse.data.bytes, _currentResponse.data.length);
		
		if(!metric && _sensorDescriptor->sensorDescriptor2.convertFunction) {
			val = _sensorDescriptor->sensorDescriptor2.convertFunction(val);			
		}
		
		return [NSNumber numberWithFloat:val];
	}
	else {
		return nil;
	}
}



- (NSString*) valueStringForMeasurement1:(BOOL)metric {
	NSObject* value = [self valueForMeasurement1:metric];
	
	if([value isKindOfClass:[NSString class]]) {
		return (NSString*)value;
	}
	else {
		NSNumber* numVal = (NSNumber*)value;
		if(IS_INT_VALUE(self.pid, 1)) {
			return [NSString stringWithFormat:@"%d", [numVal intValue]];
		}
		else {
			return [NSString stringWithFormat:@"%0.3f", [numVal floatValue]];
		}		
	}
}

- (NSString*) valueStringForMeasurement2:(BOOL)metric {
	
	if(!self.isMultiValue) {
		return nil;
	}	
	
	NSObject* value = [self valueForMeasurement2:metric];
	
	if([value isKindOfClass:[NSString class]]) {
		return (NSString*)value;
	}
	else {		
		NSNumber* numVal = (NSNumber*)value;		
		if(IS_INT_VALUE(self.pid, 2)) {
			return [NSString stringWithFormat:@"%d", [numVal intValue]];
		}
		else {
			return [NSString stringWithFormat:@"%0.3f", [numVal floatValue]];
		}		
	}
}


- (NSString*) unitStringForMeasurement1:(BOOL)metric {	
	
	if(!metric && _sensorDescriptor->sensorDescriptor1.imperialUnit) {
		return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor1.imperialUnit encoding:NSUTF8StringEncoding];
	}
	else if(_sensorDescriptor->sensorDescriptor1.metricUnit) {
		return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor1.metricUnit encoding:NSUTF8StringEncoding];
	}
	else {
		return nil;
	}
}

- (NSString*) unitStringForMeasurement2:(BOOL)metric {	
	
	if(!self.isMultiValue) {
		return nil;
	}
	else {
		if(!metric && _sensorDescriptor->sensorDescriptor2.imperialUnit) {
			return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor2.imperialUnit encoding:NSUTF8StringEncoding];
		}
		else if(_sensorDescriptor->sensorDescriptor2.metricUnit) {
			return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor2.metricUnit encoding:NSUTF8StringEncoding];
		}
		else {
			return nil;
		}
	}
}


- (NSString*) descriptionStringForMeasurement1 {
	
	if(NULL != _sensorDescriptor->sensorDescriptor1.description) {
		return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor1.description encoding:NSUTF8StringEncoding];
	}
	else {
		return @"";
	}
}


- (NSString*) shortDescriptionStringForMeasurement1 {
	
	if(NULL != _sensorDescriptor->sensorDescriptor1.shortDescription) {
		return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor1.shortDescription encoding:NSUTF8StringEncoding];
	}
	else {
		return @"";
	}	
}


- (NSString*) descriptionStringForMeasurement2 {	
	if(self.isMultiValue) {
		
		if(NULL != _sensorDescriptor->sensorDescriptor2.description) {
			return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor2.description encoding:NSUTF8StringEncoding];
		}
		else {
			return @"";
		}	
	}
	else {
		return nil;
	}
}

- (NSString*) shortDescriptionStringForMeasurement2 {
	if(self.isMultiValue) {
		
		if(NULL != _sensorDescriptor->sensorDescriptor2.shortDescription) {
			return [NSString stringWithCString:_sensorDescriptor->sensorDescriptor2.shortDescription encoding:NSUTF8StringEncoding];
		}
		else {
			return @"";
		}	
	}
	else {
		return nil;
	}
}


- (NSString*) metricUnitString {
	NSString* rvString1	= [NSString stringWithCString:_sensorDescriptor->sensorDescriptor1.metricUnit encoding:NSUTF8StringEncoding];	
	
	if(self.isMultiValue) {		
		NSString* rvString2	= @"";
		if(_sensorDescriptor->sensorDescriptor1.metricUnit) {
			rvString2		= [NSString stringWithCString:_sensorDescriptor->sensorDescriptor1.metricUnit encoding:NSUTF8StringEncoding];			
		}
		
		return [NSString stringWithFormat:@"%@ / %@", rvString1, rvString2];
	}
	else {
		return rvString1;
	}	
}

- (NSString*) imperialUnitString {
	
	const char* unitString = (_sensorDescriptor->sensorDescriptor1.imperialUnit) ? _sensorDescriptor->sensorDescriptor1.imperialUnit : _sensorDescriptor->sensorDescriptor1.metricUnit;
	
	if(unitString) {
		NSString* rvString1	= [NSString stringWithCString:unitString encoding:NSUTF8StringEncoding];
		
		if(self.isMultiValue) {
			const char* unitString2 = (_sensorDescriptor->sensorDescriptor2.imperialUnit) ? _sensorDescriptor->sensorDescriptor2.imperialUnit : _sensorDescriptor->sensorDescriptor2.metricUnit;
			NSString* rvString2		= @"";
			if(unitString2) {
				rvString2 = [NSString stringWithCString:unitString2 encoding:NSUTF8StringEncoding];
			}			
			
			return [NSString stringWithFormat:@"%@ / %@", rvString1, rvString2];
		}
		else {
			return rvString1;
		}	
	}
	else {
		return nil;
	}	
}


- (NSInteger) minValueForMeasurement1:(BOOL)metric {
	
	NSInteger minValue = INT_MAX;
	
	if(self.isAlphaValue) {
		return minValue;
	}
	
	if(!metric && self.minValueForImperialMeasurement1 != INT_MAX) {
		minValue = self.minValueForImperialMeasurement1;
	}
	else {
		minValue = self.minValueForMetricMeasurement1;
	}
	
	return minValue;
}


- (NSInteger) minValueForMeasurement2:(BOOL)metric {
	NSInteger minValue = INT_MAX;
	
	if(self.isAlphaValue || !self.isMultiValue) {
		return minValue;
	}
	
	if(!metric && self.minValueForImperialMeasurement2 != INT_MAX) {
		minValue = self.minValueForImperialMeasurement2;
	}
	else {
		minValue = self.minValueForMetricMeasurement2;
	}
	
	return minValue;
}


- (NSInteger) maxValueForMeasurement1:(BOOL)metric {
	NSInteger maxValue = INT_MAX;
	
	if(self.isAlphaValue) {
		return maxValue;
	}
	
	if(!metric && self.maxValueForImperialMeasurement1 != INT_MAX) {
		maxValue = self.maxValueForImperialMeasurement1;
	}
	else {
		maxValue = self.maxValueForMetricMeasurement1;
	}
	
	return maxValue;
}


- (NSInteger) maxValueForMeasurement2:(BOOL)metric {
	NSInteger maxValue = INT_MAX;
	
	if(self.isAlphaValue || !self.isMultiValue) {
		return maxValue;
	}
	
	if(!metric && self.maxValueForImperialMeasurement2 != INT_MAX) {
		maxValue = self.maxValueForImperialMeasurement2;
	}
	else {
		maxValue = self.maxValueForMetricMeasurement2;
	}
	
	return maxValue;
}



- (NSString*) minValueStringForMeasurement1:(BOOL)metric {
	if(self.isAlphaValue) {
		return nil;
	}
	
	NSInteger minValue = [self minValueForMeasurement1:metric];
	
	if(minValue != INT_MAX) {
		return [NSString stringWithFormat:@"%0.1d", minValue];
	}
	else {
		return nil;
	}
}


- (NSString*) minValueStringForMeasurement2:(BOOL)metric {
	
	if(self.isAlphaValue || !self.isMultiValue) {
		return nil;
	}
	
	NSInteger minValue = [self minValueForMeasurement2:metric];
	
	if(minValue != INT_MAX) {
		return [NSString stringWithFormat:@"%0.1d", minValue];
	}
	else {
		return nil;
	}
}


- (NSString*) maxValueStringForMeasurement1:(BOOL)metric {
	
	if(self.isAlphaValue) {
		return nil;
	}
	
	NSInteger maxValue = [self maxValueForMeasurement1:metric];
	
	if(maxValue != INT_MAX) {
		if(maxValue > 1000) {
			float f = (float)(maxValue / 1000);
			return [NSString stringWithFormat:@"%0.1fk", f];
		}
		else {
			return [NSString stringWithFormat:@"%0.1d", maxValue];
		}		
	}
	else {
		return nil;
	}
}


- (NSString*) maxValueStringForMeasurement2:(BOOL)metric {
	if(self.isAlphaValue || !self.isMultiValue) {
		return nil;
	}
	
	NSInteger maxValue = [self maxValueForMeasurement2:metric];
	
	if(maxValue != INT_MAX) {
		return [NSString stringWithFormat:@"%0.1d", maxValue];
	}
	else {
		return nil;
	}
}


- (NSInteger) minValueForMetricMeasurement1 {
	return _sensorDescriptor->sensorDescriptor1.minMetricValue;
}

- (NSInteger) minValueForMetricMeasurement2 {
	return _sensorDescriptor->sensorDescriptor2.minMetricValue;
}

- (NSInteger) maxValueForMetricMeasurement1 {
	return _sensorDescriptor->sensorDescriptor1.maxMetricValue;
}

- (NSInteger) maxValueForMetricMeasurement2 {
	return _sensorDescriptor->sensorDescriptor2.maxMetricValue;
}

- (NSInteger) minValueForImperialMeasurement1 {
	return _sensorDescriptor->sensorDescriptor1.minImperialValue;
}

- (NSInteger) minValueForImperialMeasurement2 {
	return _sensorDescriptor->sensorDescriptor2.minImperialValue;
}

- (NSInteger) maxValueForImperialMeasurement1 {
	return _sensorDescriptor->sensorDescriptor1.maxImperialValue;
}

- (NSInteger) maxValueForImperialMeasurement2 {
	return _sensorDescriptor->sensorDescriptor2.maxImperialValue;
}


#pragma mark -
#pragma mark String Calculation Methods

- (NSString*) calculateStringForData:(NSData*)data {
	
	switch(_currentResponse.pid) {
		case 0x03:
			return [self calculateFuelSystemStatus:data];
			break;
		case 0x12:
			return [self calculateSecondaryAirStatus:data];
			break;
		case 0x13:
			return [self calculateOxygenSensorsPresent:data];
			break;
		case 0x1C:
			return [self calculateDesignRequirements:data];
			break;
		case 0x1D:
			return @"";
			break;
		case 0x1E:
			return [self calculateAuxiliaryInputStatus:data];
		default:
			return nil;
	}
}




- (NSString*) calculateAuxiliaryInputStatus:(NSData*)data {
	unsigned char dataA = 0;	
	[data getBytes:&dataA length:1];
	
	dataA = dataA & ~0x7F; // only bit 0 is valid
	
	if(dataA & 0x01 != 0) {
		return @"PTO_STATE: ON";
	}
	else if(dataA & 0x02 != 0) {
		return @"PTO_STATE: OFF";
	}
	else {
		return nil;
	}
}


- (NSString*) calculateDesignRequirements:(NSData*)data {
	
	NSString* returnString	= nil;
	unsigned char dataA		= 0;
	
	[data getBytes:&dataA length:1];
	
	switch(dataA) {
		case 0x01:
			returnString	= @"OBD II";
			break;
		case 0x02:
			returnString	= @"OBD";
			break;
		case 0x03:
			returnString	= @"OBD I and OBD II";
			break;
		case 0x04:
			returnString	= @"OBD I";
			break;
		case 0x05:
			returnString	= @"NO OBD";
			break;
		case 0x06:
			returnString	= @"EOBD";
			break;
		case 0x07:
			returnString	= @"EOBD and OBD II";
			break;
		case 0x08:
			returnString	= @"EOBD and OBD";
			break;
		case 0x09:
			returnString	= @"EOBD, OBD and OBD II";
			break;
		case 0x0A:
			returnString	= @"JOBD";
			break;
		case 0x0B:
			returnString	= @"JOBD and OBD II";
			break;
		case 0x0C:
			returnString	= @"JOBD and EOBD";
			break;
		case 0x0D:
			returnString	= @"JOBD, EOBD, and OBD II";
			break;
		default:
			returnString	= @"N/A";
			break;
	}
	
	return returnString;
}





- (NSString*) calculateOxygenSensorsPresent:(NSData*)data {
	NSString* returnString	= nil;
	unsigned char dataA		= 0;
	[data getBytes:&dataA length:1];
	
	if(dataA & 0x01 != 0)
		returnString		= [NSString stringWithFormat:@"O2S11", returnString];
	
	if(dataA & 0x02 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S12", returnString];
	
	if(dataA & 0x04 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S13", returnString];
	
	if(dataA & 0x08 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S14", returnString];
	
	if(dataA & 0x10 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S21", returnString];
	
	if(dataA & 0x20 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S22", returnString];
	
	if(dataA & 0x40 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S23", returnString];
	
	if(dataA & 0x80 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S24", returnString];
	
	
	return returnString;
}


- (NSString*) calculateOxygenSensorsPresentB:(NSData*)data {
	
	NSString* returnString	= nil;
	unsigned char dataA		= 0;
	[data getBytes:&dataA length:1];
	
	
	if(dataA & 0x01 != 0)
		returnString		= [NSString stringWithFormat:@"O2S11", returnString];
	
	if(dataA & 0x02 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S12", returnString];
	
	if(dataA & 0x04 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S21", returnString];
	
	if(dataA & 0x08 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S22", returnString];
	
	if(dataA & 0x10 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S31", returnString];
	
	if(dataA & 0x20 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S32", returnString];
	
	if(dataA & 0x40 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S41", returnString];
	
	if(dataA & 0x80 != 0)
		returnString		= [NSString stringWithFormat:@"%@, O2S42", returnString];


	return returnString;
}



- (NSString*) calculateFuelSystemStatus:(NSData*)data {

	NSString* rvString		= nil;
	unsigned char dataA		= 0;
	[data getBytes:&dataA length:1];
	
	switch (dataA) {
		case 0x01:
			rvString		= @"Open Loop";
			break;
		case 0x02:
			rvString		= @"Closed Loop";
			break;
		case 0x04:
			rvString		= @"OL-Drive";
			break;
		case 0x08:
			rvString		= @"OL-Fault";
			break;
		case 0x10:
			rvString		= @"CL-Fault";
			break;
		default:
			break;
	}
	
	return rvString;
}



- (NSString*) calculateSecondaryAirStatus:(NSData*)data {
	
	NSString* rvString		= nil;
	unsigned char dataA		= 0;
	[data getBytes:&dataA length:1];
	
	switch (dataA) {
		case 0x01:
			rvString		= @"AIR_STAT: UPS";
			break;
		case 0x02:
			rvString		= @"AIR_STAT: DNS";
			break;
		case 0x04:
			rvString		= @"AIR_STAT: OFF";
			break;
		default:
			break;
	}
	
	return rvString;
}

@end
