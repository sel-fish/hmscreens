//
// Created 22 July 2010 by Hank McShane
// version 0.1
// requires Mac OS X 10.4 or higher
//
// Use hmscreens to either get information about your screens
// or for setting the main screen (the screen with the menu bar).
//
// Usage: hmscreens
// [-h] shows the help text
// [-info] shows information about the connected screens
// [-screenIDs] returns only the screen IDs for the connected screens
// [-setMainID <Screen ID>] Screen ID of the screen that you want to make the main screen
// [-othersStartingPosition <position>] left, right, top, or bottom... with -setMainID, this determines placement of other screens
//
// Examples:
// hmscreens -info
// returns information about your attached screens including the Screen ID
//
// hmscreens -setMainID 69670848 -othersStartingPosition left
// makes the screen with the Screen ID 69670848 the main screen.
// Also positions other screens to the left of the main screen as shown
// under the "Arrangement" section of the Displays preference pane.
//
// NOTE: Global Position {0, 0} coordinate (as shown under -info)
// is the lower left corner of the main screen
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void printHelp();
void displaysInfo();
void screenIDs();
void setMainScreen(NSString* screenID, NSString* othersGlobalStartingPosition);

#define MAX_DISPLAYS 32

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// get command line arguments
	NSArray* pInfo = [[NSArray alloc] initWithArray:[[NSProcessInfo processInfo] arguments]];
	
	if ([pInfo count] == 1) {
		printHelp();
	} else if ([[pInfo objectAtIndex:1] isEqualToString:@"-h"]) {
		printHelp();
	} else if ([[pInfo objectAtIndex:1] isEqualToString:@"-info"]) {
		displaysInfo();
	} else if ([[pInfo objectAtIndex:1] isEqualToString:@"-screenIDs"]) {
		screenIDs();
	} else if ([[pInfo objectAtIndex:1] isEqualToString:@"-setMainID"]) {
		NSString* screenID = [[NSUserDefaults standardUserDefaults] stringForKey:@"setMainID"];
        NSString* othersGlobalStartingPosition = [[NSUserDefaults standardUserDefaults] stringForKey:@"othersGlobalStartingPosition"];
		setMainScreen(screenID, othersGlobalStartingPosition);
	} else {
		printHelp();
	}

	[pInfo release];
	
    [pool drain];
    return 0;
}

//----------------------------------------
//            FUNCTIONS
//----------------------------------------
#pragma mark -
#pragma mark FUNCTIONS

void screenIDs() {
	CGDirectDisplayID activeDisplays[MAX_DISPLAYS];
	CGDisplayErr err;
	CGDisplayCount displayCount;
	
	// get the active displays
	err = CGGetActiveDisplayList(MAX_DISPLAYS, activeDisplays, &displayCount);
	if ( err != kCGErrorSuccess ) {
		printf("Error: cannot get displays:\n%d\n", err);
		return;
	}
	
	int i;
	for (i=0; i<displayCount; i++) {
		printf("%i\n", activeDisplays[i]);
	}
}

void setMainScreen(NSString* screenID, NSString* othersGlobalStartingPosition) {
    // check the value of othersGlobalStartingPosition first
    NSString* positionFormatErr = @"othersGlobalStartingPosition format err";

    if (othersGlobalStartingPosition == nil) {
        printf("Error: %s\n", [positionFormatErr UTF8String]);
        return;
    }

    printf("othersGlobalStartingPosition: %s\n", [othersGlobalStartingPosition UTF8String]);
    NSInteger abscissa, ordinate;

    NSArray *coordinates = [othersGlobalStartingPosition componentsSeparatedByString:@","];
    if ([coordinates count] != 2) {
        printf("Error: %s\n", [positionFormatErr UTF8String]);
        return;
    } else {
        abscissa = [[coordinates objectAtIndex:0] integerValue];
        ordinate = [[coordinates objectAtIndex:1] integerValue];
        if (abscissa == 0 || ordinate == 0) {
            printf("Error: %s\n", [positionFormatErr UTF8String]);
            return;
        }
        printf("othersGlobalStartingPosition: [%ld, %ld]\n", abscissa, ordinate);
    }

	CGDirectDisplayID activeDisplays[MAX_DISPLAYS];
	CGDisplayErr err;
	CGDisplayCount displayCount;
	CGDisplayConfigRef config;
	
	// get the active displays
	err = CGGetActiveDisplayList(MAX_DISPLAYS, activeDisplays, &displayCount);
	if ( err != kCGErrorSuccess ) {
		printf("Error: cannot get displays:\n%d\n", err);
		return;
	}

    // error if not equal to 2 displays
    // we only handle 2 as sel-fish only has 2 displays till now
    // if only use 1 display, this program is not supposed to run
    if (displayCount != 3) {
        printf("Error: hmscreens can only work with 2 screens when adjusting the main screen, but displayCount: %d\n", displayCount);
        return;
    }
	
	// validate that the screenID exists and get the index number of it
	int i, newMainScreenIndex;
	BOOL foundScreenID = NO;
	for (i=0; i<displayCount; i++) {
		CGDirectDisplayID thisDisplayID = activeDisplays[i];
		NSString* thisDisplayIDString = [NSString stringWithFormat:@"%i", thisDisplayID];
		if ([thisDisplayIDString isEqualToString:screenID]) {
			foundScreenID = YES;
			break;
		}
	}
	
	if (foundScreenID) {
		newMainScreenIndex = i;
	} else {
		printf("Error: Screen ID %s could not be found\n", [screenID UTF8String]);
		return;
	}
	
	// configure the displays
	CGBeginDisplayConfiguration(&config);
	for(i=0; i<displayCount; i++) {
        if (i == newMainScreenIndex) { // make this one the main screen
			CGConfigureDisplayOrigin(config, activeDisplays[i], 0, 0); //Set the as the new main display by positionning at 0,0
		} else {
            CGConfigureDisplayOrigin(config, activeDisplays[i], abscissa, ordinate);
		}
	}

	CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
}

void printHelp() {
	NSString* a = @"Use hmscreens to either get information about your screens";
	NSString* b = @"or for setting the main screen (the screen with the menu bar).";
	
	NSString* c = @"Usage: hmscreens";
	NSString* d = @"[-h] shows the help text";
	NSString* e = @"[-info] shows information about the connected screens";
	NSString* f = @"[-screenIDs] returns only the screen IDs for the connected screens";
	NSString* g = @"[-setMainID <Screen ID>] Screen ID of the screen that you want to make the main screen";
	NSString* h = @"[-othersStartingPosition <position>] left, right, top, or bottom";
	NSString* i = @"\t\tuse this with -setMainID to determine placement of other screens";
	
	NSString* j = @"Examples:";
	NSString* k = @"hmscreens -info";
	NSString* l = @"\treturns information about your attached screens including the Screen ID";
	
	NSString* m = @"hmscreens -setMainID 69670848 -othersStartingPosition left";
	NSString* n = @"\tmakes the screen with the Screen ID 69670848 the main screen.";
	NSString* o = @"\tAlso positions other screens to the left of the main screen as shown";
	NSString* p = @"\tunder the \"Arrangement\" section of the Displays preference pane.";
	
	NSString* q = @"NOTE: Global Position {0, 0} coordinate (as shown under -info)";
	NSString* r = @"\tis the lower left corner of the main screen";
	
	NSString* z = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n\n%@\n%@\n%@\n\n%@\n%@\n%@\n%@\n\n%@\n%@\n",a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r];
	printf("%s\n", [z UTF8String]);
}

void displaysInfo() {
	NSArray* allScreens = [NSScreen screens];
	
	int i;
	for (i=0; i<[allScreens count]; i++) {
		NSScreen* thisScreen = [allScreens objectAtIndex:i];
		NSDictionary* deviceDescription = [thisScreen deviceDescription];
		//NSLog(@"deviceDescription: %@", deviceDescription);
		
		// screen id
		NSNumber* screenID = [deviceDescription valueForKey:@"NSScreenNumber"];
		CGDirectDisplayID cgScreenID = (CGDirectDisplayID)[screenID intValue];
		printf("Screen ID: %i\n", [screenID intValue]);
		
		// size
		NSSize size = [[deviceDescription objectForKey:NSDeviceSize] sizeValue];
		printf("Size: %s\n", [NSStringFromSize(size) UTF8String]);
		
		// global position
		NSRect frame = [thisScreen frame];
		int x1 = frame.origin.x;
		int y1 = frame.origin.y;
		int x2 = x1 + frame.size.width;
		int y2 = y1 + frame.size.height;
		printf("Global Position: {{%i, %i}, {%i, %i}}\n", x1, y1, x2, y2);
		
		// color space
		NSString* colorSpace = [deviceDescription valueForKey:NSDeviceColorSpaceName];
		printf("Color Space: %s\n", [colorSpace UTF8String]);
		
		// depth ie. 32 is millions of colors, 16 is thousands, 8 is 256
		long bpp = CGDisplayBitsPerPixel(cgScreenID);
		printf("BitsPerPixel: %ldd\n", bpp);
		
		// resolution
		NSSize resolution = [[deviceDescription objectForKey:NSDeviceResolution] sizeValue];
		printf("Resolution(dpi): %s\n", [NSStringFromSize(resolution) UTF8String]);
		
		// refresh rate
		long refresh;
		CFNumberRef number = CFDictionaryGetValue(CGDisplayCurrentMode(cgScreenID), kCGDisplayRefreshRate); 
		CFNumberGetValue(number, kCFNumberLongType, &refresh);
		printf("Refresh Rate: %ldd\n", refresh);
		
		// usesQuartzExtreme
		BOOL usesQuartzExtreme = CGDisplayUsesOpenGLAcceleration(cgScreenID);
		if (usesQuartzExtreme) {
			printf("Uses Quartz Extreme: YES\n");
		} else {
			printf("Uses Quartz Extreme: NO\n");
		}
		
		printf("\n");
	}
}
