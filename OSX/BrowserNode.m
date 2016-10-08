//
//  RootItem.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 2/20/11.
//  Copyright 2011 seriot.ch. All rights reserved.
//

#import "BrowserNode.h"
#import "RTBRuntime.h"
#import "RTBProtocol.h"
#import "RTBRuntimeHeader.h"

@implementation BrowserNode

@synthesize nodeName;
@synthesize children;

+ (BrowserNode *)rootNodeList {
	BrowserNode *rn = [[BrowserNode alloc] init];
	rn.children = [[RTBRuntime sharedInstance] sortedClassStubs];
	return rn;
}

+ (BrowserNode *)rootNodeTree {
	BrowserNode *rn = [[BrowserNode alloc] init];
	rn.children = [[RTBRuntime sharedInstance] rootClasses];
	return rn;
}

+ (BrowserNode *)rootNodeImages {
	BrowserNode *bn = [[BrowserNode alloc] init];
	
	NSDictionary *allStubsByImage = [RTBRuntime sharedInstance].allClassStubsByImagePath;
	
	NSMutableArray *images = [NSMutableArray array];
	
	for(NSString *image in [allStubsByImage allKeys]) {
		BrowserNode *node = [[BrowserNode alloc] init];
		node.nodeName = image;
		NSMutableArray *stubs = [NSMutableArray arrayWithArray:[allStubsByImage valueForKey:image]];
		[stubs sortUsingSelector:@selector(compare:)];
		node.children = stubs;
		[images addObject:node];
	}
	
	[images sortUsingSelector:@selector(compare:)]; // TODO: sort by lastPathComponent?
	
	bn.nodeName = @"Images";
	bn.children = images;
	return bn;
}

+ (BrowserNode *)rootNodeProtocols {
    BrowserNode *bn = [[BrowserNode alloc] init];
    
    bn.nodeName = @"Protocols";
    bn.children = [[RTBRuntime sharedInstance] sortedProtocolStubs];
    
    return bn;
}

- (NSImage *)icon {

    NSArray *extensions = [NSArray arrayWithObjects:@".app", @".framework", @".bundle", @".dylib", nil];
    for(NSString *ext in extensions) {
		NSRange range = [nodeName rangeOfString:ext];
		if(range.location != NSNotFound) {
			NSString *bundlePath = [nodeName substringToIndex:(range.location + [ext length])];
			return [[NSWorkspace sharedWorkspace] iconForFile:bundlePath];
		}
	}
	
	return nil;
}

+ (void)thisClassIsPartOfTheRuntimeBrowser {}

- (NSComparisonResult)compare:(BrowserNode *)otherNode {
    return [nodeName compare:[otherNode nodeName]];
}

- (NSString *)nodeInfo {
    NSArray *pathComponents = [nodeName componentsSeparatedByString:@"/"];
    return [NSString stringWithFormat:@"%@ (%lu)", [pathComponents lastObject], (unsigned long)[children count]];
}

- (BOOL)canBeSavedAsHeader {
	return NO;
}

// MARK: - Write

+ (void)writeAll {
  BrowserNode *root = [BrowserNode rootNodeImages];
  NSLog(@"Begin writing");
  for (BrowserNode *framework in root.children) {
    for (BrowserNode *class in framework.children) {
      Class kClass = NSClassFromString(class.nodeName);

      if (kClass == nil) {
        continue;
      }

      NSString *frameworkName = [self frameworkName:framework];

      if (frameworkName == nil) {
        continue;
      }

      NSString *content = [RTBRuntimeHeader headerForClass:kClass displayPropertiesDefaultValues:YES];
      [self writeFrameworkName:frameworkName className:class.nodeName content:content];
    }
  }
  NSLog(@"Finish writing");
}

+ (NSString *)frameworkName:(BrowserNode *)framework {
  for (NSString *component in [framework.nodeName componentsSeparatedByString:@"/"]) {
    if ([component containsString:@".framework"] || [component containsString:@".dylib"]) {
      return component;
    }
  }

  return nil;
}

+ (void)writeFrameworkName:(NSString *)frameworkName className:(NSString *)className content:(NSString *)content {

  NSString *folder = [NSString stringWithFormat:@"/Users/khoa/Downloads/macOS-Runtime-Headers/%@", frameworkName];
  if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:nil];
  }

  NSString *file = [NSString stringWithFormat:@"%@/%@.h", folder, className];

  [content writeToFile:file atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

@end
