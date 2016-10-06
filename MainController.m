//
//  MainController.m
//  MultiBoxOSX
//
//  Created by dirk on 4/25/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
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

#include <ApplicationServices/ApplicationServices.h>

#import "MainController.h"

CGEventRef MyKeyboardEventTapCallBack (CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	MainController *mc = (MainController *) refcon;
	return [mc tapKeyboardCallbackWithProxy:proxy type:type event:event];
}

CGEventRef MyMouseEventTapCallBack (CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	MainController *mc = (MainController *) refcon;
	return [mc tapMouseCallbackWithProxy:proxy type:type event:event];
}

@implementation MainController

- (void) awakeFromNib {
	[NSApplication sharedApplication].delegate = self;
	[self setUpEventTaps];
	[self updateUI];
	//[self cycleThroughProcesses];
}

- (CGEventRef) tapKeyboardCallbackWithProxy:(CGEventTapProxy)proxy type:(CGEventType)type event:(CGEventRef)event {
	//NSLog(@"tapCallbackWithProxy");
	ProcessSerialNumber current;
	OSErr err = GetFrontProcess(&current);
	if (!err) {
		//NSLog(@"foreground psn %ld,%ld", current.highLongOfPSN, current.lowLongOfPSN);
		if ([self shouldTemperWithPSN:&current]) {
			//NSLog(@"foreground app should be tempered with");
			
			NSString *eventString = nil;
			// check for ignore key
			if (type == kCGEventKeyDown) {
				eventString = [self stringFromEvent:event];
				//NSLog(@"string %@", eventString);
				if ([eventString isEqual:@"#"]) {
					ignoreEvents = !ignoreEvents;
					[self updateUI];
				}
				//CGEventField field = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
				//NSLog(@"keycode %d", field);
			}
			
			//NSLog(@"ignoreEvents %d in instance %@", ignoreEvents, self);
			if (!ignoreEvents) {
				ProcessSerialNumber psn = { 0, kNoProcess };
				err = 0;
				while ((err = GetNextProcess(&psn)) != procNotFound) {
					Boolean same;
					SameProcess(&psn, &current, &same);
					//NSLog(@"%@ same %d", pn, same);
					if (!same) {
						if ([self shouldTemperWithPSN:&psn]) {
							SameProcess(&psn, &lastFrontPsn, &same);
							if (!same) {
								pid_t cur_pid;
								GetProcessPID(&psn, &cur_pid);
								//NSLog(@"focusing %d", cur_pid);
								[self focusFirstWindowOfPid:cur_pid];
								lastFrontPsn = psn;
							}
							
							// basic macro ability
							// stop follow
							/*
							if (type == kCGEventKeyDown) {
								NSString *eventString = [self stringFromEvent:event];
								if ([eventString isEqual:@"r"]) {
									//NSLog(@"attack");
									// arrow down is 125
									CGEventRef ev1 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode) 125, YES);
									CGEventPostToPSN(&psn, ev1);
									CGEventRef ev2 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode) 125, NO);
									CGEventPostToPSN(&psn, ev2);
									CFRelease(ev1);
									CFRelease(ev2);
								}
							}
							*/
							//NSString *pn = [self processNameFromPSN:&psn];
							//NSLog(@"copy to %@", pn);
							
							// ignore movement keys
							BOOL ignoreThisEvent = NO;
							if (eventString && eventString.length == 1) {
								char c = (char) [eventString characterAtIndex:0];
								switch (c) {
									case 'e':
									case 'd':
									case 's':
									case 'f':
										ignoreThisEvent = YES;
										//NSLog(@"ignored key %c", c);
										break;
									default:
										break;
								}
							}
							if (!ignoreThisEvent) {
								CGEventPostToPSN(&psn, event);
							}
						}
					}
				}
			}
		}
		/*
		 NSLog(@"psn %ld,%ld", current.highLongOfPSN, current.lowLongOfPSN);
		 NSString *pn = [self processNameFromPSN:&current];
		 if (pn) {
		 NSLog(@"foreground process %@", pn);
		 }
		 */
	} else {
		NSLog(@"could not determine current process");
	}
	
	return event;
}

- (CGEventRef) tapMouseCallbackWithProxy:(CGEventTapProxy)proxy type:(CGEventType)type event:(CGEventRef)event {
	ProcessSerialNumber current;
	OSErr err = GetFrontProcess(&current);
	ProcessSerialNumber psn = { 0, kNoProcess };
	err = 0;
	while ((err = GetNextProcess(&psn)) != procNotFound) {
		Boolean same;
		SameProcess(&psn, &current, &same);
		//NSLog(@"%@ same %d", pn, same);
		if (!same) {
			if ([self shouldTemperWithPSN:&psn]) {
				SameProcess(&psn, &lastFrontPsn, &same);
				if (!same) {
					pid_t cur_pid;
					GetProcessPID(&psn, &cur_pid);
					//NSLog(@"mouse focusing %d", cur_pid);
					[self focusFirstWindowOfPid:cur_pid];
					lastFrontPsn = psn;
				}
			}
		}
	}
	return event;
}

- (void) setUpEventTaps {
	CGEventMask maskKeyboard = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged);
	//| CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventOtherMouseDown);
	machPortKeyboard = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionDefault,
								maskKeyboard, MyKeyboardEventTapCallBack, self);
	machPortRunLoopSourceRefKeyboard = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPortKeyboard, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), machPortRunLoopSourceRefKeyboard, kCFRunLoopDefaultMode);

	CGEventMask maskMouse = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown) |
	CGEventMaskBit(kCGEventOtherMouseDown);
	machPortMouse = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionDefault,
										maskMouse, MyMouseEventTapCallBack, self);
	machPortRunLoopSourceRefMouse = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPortMouse, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), machPortRunLoopSourceRefMouse, kCFRunLoopDefaultMode);
}

- (void) shutDownEventTaps {
	if (machPortRunLoopSourceRefKeyboard) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), machPortRunLoopSourceRefKeyboard, kCFRunLoopDefaultMode);
		CFRelease(machPortRunLoopSourceRefKeyboard);
	}
	if (machPortKeyboard) {
		CFRelease(machPortKeyboard);
	}
	if (machPortRunLoopSourceRefMouse) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), machPortRunLoopSourceRefMouse, kCFRunLoopDefaultMode);
		CFRelease(machPortRunLoopSourceRefMouse);
	}
	if (machPortMouse) {
		CFRelease(machPortMouse);
	}
}

- (NSString *) processNameFromPSN:(ProcessSerialNumber *)psn {
	NSString *pn = nil;
	OSStatus st = CopyProcessName(psn, (CFStringRef *) &pn);
	if (st) {
		NSLog(@"%s could not get process name", __FUNCTION__);
	}
	return pn;
}

/*
- (void) cycleThroughProcesses {
	ProcessSerialNumber psn = { 0, kNoProcess };
	OSErr err = 0;
	while ((err = GetNextProcess(&psn)) != procNotFound) {
		NSString *pn = [self processNameFromPSN:&psn];
		NSLog(@"process %@", pn);
	}
}
 */

- (BOOL) shouldTemperWithPSN:(ProcessSerialNumber *)psn {
	NSString *pn = [self processNameFromPSN:psn];
	return [pn isEqual:@"World of Warcraft"];
	//return [pn isEqual:@"TextEdit"];
}

// taken from clone keys
- (void) focusFirstWindowOfPid:(pid_t)pid {
	AXUIElementRef appRef = AXUIElementCreateApplication(pid);
	
	CFArrayRef winRefs;
	AXUIElementCopyAttributeValues(appRef, kAXWindowsAttribute, 0, 255, &winRefs);
	if (!winRefs) return;
	
	for (int i = 0; i < CFArrayGetCount(winRefs); i++) {
		AXUIElementRef winRef = (AXUIElementRef)CFArrayGetValueAtIndex(winRefs, i);
		CFStringRef titleRef = NULL;
		AXUIElementCopyAttributeValue( winRef, kAXTitleAttribute, (const void**)&titleRef);
		
		char buf[1024];
		buf[0] = '\0';
		if (!titleRef) {
			strcpy(buf, "null");
		}
		if (!CFStringGetCString(titleRef, buf, 1023, kCFStringEncodingUTF8)) return;
		CFRelease(titleRef);
		
		if (strlen(buf) != 0) {
			AXError result = AXUIElementSetAttributeValue(winRef, kAXFocusedAttribute, kCFBooleanTrue);
			// CFRelease(winRef);
			// syslog(LOG_NOTICE, "result %d of setting window %s focus of pid %d", result, buf, pid);
			if (result != 0) {
				// syslog(LOG_NOTICE, "result %d of setting window %s focus of pid %d", result, buf, pid);
			}
			break;
		}
		else {
			// syslog(LOG_NOTICE, "Skipping setting window %s focus of pid %d", buf, pid);
		}
	}
	
	AXUIElementSetAttributeValue(appRef, kAXFocusedApplicationAttribute, kCFBooleanTrue);
	
	CFRelease(winRefs);
	CFRelease(appRef);
}

- (void) updateUI {
	if (ignoreEvents) {
		toggleButton.title = @"Enable";
		mainWindow.backgroundColor = [NSColor redColor];
	} else {
		toggleButton.title = @"Disable";
		mainWindow.backgroundColor = [NSColor greenColor];
	}
}

- (IBAction) enableButton:(id)sender {
	ignoreEvents = !ignoreEvents;
	[self updateUI];
}

- (NSString *) stringFromEvent:(CGEventRef)event {
	UniCharCount stringLength = 32;
	UniChar unicodeString[stringLength];
	CGEventKeyboardGetUnicodeString(event, stringLength, &stringLength, unicodeString);
	NSString *uni = [NSString stringWithCharacters:unicodeString length:stringLength];
	return uni;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSLog(@"applicationShouldTerminate");
	[self shutDownEventTaps];
	return NSTerminateNow;
}

- (void) dealloc {
	NSLog(@"dealloc");
	[super dealloc];
}

@end
