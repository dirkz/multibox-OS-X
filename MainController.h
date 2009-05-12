//
//  MainController.h
//  MultiBoxOSX
//
//  Created by dirk on 4/25/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

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
