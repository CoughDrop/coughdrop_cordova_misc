//
//  CoughDropMisc.m
//  CoughDrop
//
//  Created by Brian Whitmer on 5/12/16.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
// #import "AudioTogglePlugin.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h>

@interface _NoInputAccessoryView : NSObject
@end

@implementation _NoInputAccessoryView {}
- (id)inputAccessoryView {
    return nil;
}
@end

@interface CoughDropMisc : CDVPlugin
@end

@implementation CoughDropMisc {
    NSString* changeCallbackId;
}


- (void)status:(CDVInvokedUrlCommand*)command
{
    // return success({ready: true}) or error({ready:false}) depending on whether init has been called
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"ok"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)listFiles:(CDVInvokedUrlCommand*)command
{
    
    // just testing with reading in values from a hash object and returning a hash result
    
    NSDictionary* options = nil;
    options = [command argumentAtIndex:0];
    NSString* dir = [options objectForKey:@"dir"];

    NSMutableDictionary* result = [self recursivePathsForResourcesOfType:nil inDirectory:dir];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)bundleId:(CDVInvokedUrlCommand *)command
{
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    [result setObject:bundleId forKey:@"bundle_id"];
    [result setObject:version forKey:@"version"];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setSystemVolume:(CDVInvokedUrlCommand *)command 
{
    NSDictionary *JSONArgument = [command argumentAtIndex:0];
    float volume = 1.0;
    NSNumber *volumeNumber = JSONArgument[@"volume"];
    if (volumeNumber) {
        volume = volumeNumber.floatValue;
    }
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    [result setObject:[NSNumber numberWithFloat:volume] forKey:@"volume"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

static IMP UIOriginalImp;
static IMP WKOriginalImp;
- (void) setKeyboardShortcutBar: (UIView *)view show:(BOOL)show
{
    for (UIView *sub in view.subviews) {
        [self setKeyboardShortcutBar:sub show:show];
        if ([NSStringFromClass([sub class]) isEqualToString:@"UIWebBrowserView"]) {
            Method method = class_getInstanceMethod(sub.class, @selector(inputAccessoryView));
            if(show) {
                method_setImplementation(method, UIOriginalImp);
            } else {
                if(!UIOriginalImp) {
                    UIOriginalImp = method_getImplementation(method);
                }
                IMP newImp = imp_implementationWithBlock(^(id _s) {
                    if ([sub respondsToSelector:@selector(inputAssistantItem)]) {
                        UITextInputAssistantItem *inputAssistantItem = [sub inputAssistantItem];
                        inputAssistantItem.leadingBarButtonGroups = @[];
                        inputAssistantItem.trailingBarButtonGroups = @[];
                    }
                    return nil;
                });
                method_setImplementation(method, newImp);
            }
        }
    }
}

- (void)toggleKeyboardAccessoryBar:(CDVInvokedUrlCommand *)command
{

    WKWebView *webView = [self webView];

// - (void)removeInputAccessoryViewFromWKWebView:(WKWebView *)webView {
    UIView *targetView;

    for (UIView *view in webView.scrollView.subviews) {
        if([[view.class description] hasPrefix:@"WKContent"]) {
            targetView = view;
        }
    }

    if (!targetView) {
        return;
    }

    NSString *noInputAccessoryViewClassName = [NSString stringWithFormat:@"%@_NoInputAccessoryView", targetView.class.superclass];
    Class newClass = NSClassFromString(noInputAccessoryViewClassName);

    if(newClass == nil) {
        newClass = objc_allocateClassPair(targetView.class, [noInputAccessoryViewClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        if(!newClass) {
            return;
        }

        Method method = class_getInstanceMethod([_NoInputAccessoryView class], @selector(inputAccessoryView));

        class_addMethod(newClass, @selector(inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method));

        objc_registerClassPair(newClass);
    }

    object_setClass(targetView, newClass);
// }


    BOOL show = false;
    if (command.arguments.count > 0) {
        id value = [command.arguments objectAtIndex:0];
        if (!([value isKindOfClass:[NSNumber class]])) {
            value = [NSNumber numberWithBool:NO];
        }
        show = [value boolValue];
    }

    NSString* UIClassString = [@[@"UI"] componentsJoinedByString:@""];
    UIView *view = (UIView *)NSClassFromString(UIClassString);
    [self setKeyboardShortcutBar:[self webView] show:show];

    // NSString* UIClassString = [@[@"UI", @"Web", @"Browser", @"View"] componentsJoinedByString:@""];
    // NSString* WKClassString = [@[@"WK", @"Content", @"View"] componentsJoinedByString:@""];

    // Method UIMethod = class_getInstanceMethod(NSClassFromString(UIClassString), @selector(inputAccessoryView));
    // Method WKMethod = class_getInstanceMethod(NSClassFromString(WKClassString), @selector(inputAccessoryView));

    // if (hideFormAccessoryBar) {
    //     UIView *sub = (UIView *)NSClassFromString(UIClassString);
    //     UIOriginalImp = method_getImplementation(UIMethod);
    //     WKOriginalImp = method_getImplementation(WKMethod);

    //     IMP newImp = imp_implementationWithBlock(^(id _s) {
    //         if ([sub respondsToSelector:@selector(inputAssistantItem)]) {
    //             UITextInputAssistantItem *inputAssistantItem = [sub inputAssistantItem];
    //             inputAssistantItem.leadingBarButtonGroups = @[];
    //             inputAssistantItem.trailingBarButtonGroups = @[];
    //         }
    //         return nil;
    //     });

    //     method_setImplementation(UIMethod, newImp);
    //     // method_setImplementation(WKMethod, newImp);
    // } else {
    //     method_setImplementation(UIMethod, UIOriginalImp);
    //     method_setImplementation(WKMethod, WKOriginalImp);
    // }   
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:show]
                                callbackId:command.callbackId]; 
}

- (void)setAudioMode:(CDVInvokedUrlCommand *)command
{
    NSString* mode = [command.arguments objectAtIndex:0];
    NSError* error;
    BOOL success;
    CDVPluginResult* pluginResult;

    AVAudioSession* session = [AVAudioSession sharedInstance];

    NSMutableArray *devices = [[NSMutableArray alloc] init];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];

    // make sure the AVAudioSession is properly configured
    [session setActive: YES error: nil];

    if (mode != nil) {
        BOOL bluetooth = false;
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        for(AVAudioSessionPortDescription* desc in [session.currentRoute outputs]) {
            [devices addObject:desc.portType];
            if ([desc.portType isEqualToString:AVAudioSessionPortBluetoothA2DP] || [desc.portType isEqualToString:AVAudioSessionPortBluetoothLE] || [desc.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
                bluetooth = true;
            }
        }
        [result setObject:devices forKey:@"devices"];
        [result setObject:mode forKey:@"mode"];

        if(bluetooth && ([mode isEqualToString:@"bluetooth"] || [mode isEqualToString:@"default"])) {
            [session setCategory:AVAudioSessionCategoryPlayback error:nil];
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
            NSNumber *newNum = [NSNumber numberWithInt:500];
            [result setObject:newNum forKey:@"delay"];
            [result setObject:@"set for bluetooth" forKey:@"status"];
        } else {
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            if ([mode isEqualToString:@"speaker"]) {
                success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
                [result setObject:@"set for speaker" forKey:@"status"];
            } else {
                success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
                [result setObject:@"set for default" forKey:@"status"];
            }
        }
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsDictionary:result];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error setting audio target"];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"'target' was null"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getAudioDevices:(CDVInvokedUrlCommand*)command
{
    
    // just testing with reading in values from a hash object and returning a hash result
    
    NSMutableArray *devices = [[NSMutableArray alloc] init];

    // add speaker
    [devices addObject:@"speaker"];
    AVAudioSession* session = [AVAudioSession sharedInstance];
    AVAudioSessionCategory cat = [session category];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    AVAudioSessionRouteDescription* route = [session currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        NSString* portType = [desc portType];
        if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [devices addObject:@"headset"];
        } else if ([portType isEqualToString:AVAudioSessionPortBluetoothA2DP] || [portType isEqualToString:AVAudioSessionPortBluetoothLE] || [portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            [devices addObject:@"bluetooth"];
        } else if ([portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
            // already a given
        } else {
            [devices addObject:desc.portType];
        }
    }
    [session setCategory:cat error:nil];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:devices];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSMutableDictionary *)recursivePathsForResourcesOfType:(NSString *)type inDirectory:(NSString *)directoryPath{
    NSMutableDictionary* result = [[NSMutableDictionary alloc]init];
    
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    long total_size = 0;
    
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject]) != nil){
        NSString* full_path = [directoryPath stringByAppendingPathComponent:filePath];
        long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:full_path error:nil][NSFileSize] longValue];
        total_size = total_size + fileSize;
        [filePaths addObject:full_path];
    }

    [result setObject:filePaths forKey:@"files"];
    [result setObject:[NSNumber numberWithLong:total_size] forKey:@"size"];

    return result;
}

@end
