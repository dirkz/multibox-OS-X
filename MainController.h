//
//  MainController.h
//  MultiBoxOSX
//
//  Created by dirk on 4/25/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

// This file is part of Multibox-OS-X.
//
// Multibox-OS-X is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// Multibox-OS-X is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Multibox-OS-X.  If not, see <http://www.gnu.org/licenses/>.

#import <Cocoa/Cocoa.h>

@interface MainController : NSObject {

	IBOutlet NSButton *toggleButton;
	IBOutlet NSWindow *mainWindow;

	CFMachPortRef machPortKeyboard;
	CFRunLoopSourceRef machPortRunLoopSourceRefKeyboard;
	CFMachPortRef machPortMouse;
	CFRunLoopSourceRef machPortRunLoopSourceRefMouse;
	
	BOOL ignoreEvents;
	ProcessSerialNumber lastFrontPsn;
	
}

- (CGEventRef) tapKeyboardCallbackWithProxy:(CGEventTapProxy)proxy type:(CGEventType)type event:(CGEventRef)event;
- (CGEventRef) tapMouseCallbackWithProxy:(CGEventTapProxy)proxy type:(CGEventType)type event:(CGEventRef)event;
- (void) setUpEventTaps;
- (void) shutDownEventTaps;
- (NSString *) processNameFromPSN:(ProcessSerialNumber *)psn;
//- (void) cycleThroughProcesses;

// returns YES if this PSN belongs to an application that we should temper with
- (BOOL) shouldTemperWithPSN:(ProcessSerialNumber *)psn;

// taken from clone keys
- (void) focusFirstWindowOfPid:(pid_t)pid;

- (NSString *) stringFromEvent:(CGEventRef)event;

- (void) updateUI;
- (IBAction) enableButton:(id)sender;

@end
