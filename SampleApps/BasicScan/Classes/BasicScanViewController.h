/*
 *  BasicScanViewController.h
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

#import <UIKit/UIKit.h>
#import "FLScanTool.h"


@interface BasicScanViewController : UIViewController <FLScanToolDelegate> {
	FLScanTool*			_scanTool;
	
	
	UILabel*			statusLabel;
	UILabel*			scanToolNameLabel;
	UILabel*			rpmLabel;
	UILabel*			speedLabel;
}

@property (nonatomic, retain) IBOutlet UILabel* statusLabel;
@property (nonatomic, retain) IBOutlet UILabel* scanToolNameLabel;
@property (nonatomic, retain) IBOutlet UILabel* rpmLabel;
@property (nonatomic, retain) IBOutlet UILabel* speedLabel;

@end

