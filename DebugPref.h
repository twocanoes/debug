//
//  DebugPref.h
//  Debug
//
//  Created by Timothy Perfitt on 11/6/09.
//  Copyright (c) 2013 twocanoes. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#include <string.h>
@interface DebugPref : NSPreferencePane 
{
    AuthorizationRef authorization;
    IBOutlet SFAuthorizationView *lockView;
    BOOL isEnabled,isDSDebugging,isLoggingDNS,isDoingNetworkTrace,isTracingDNS,
    isTracingKerberos,isTracingLDAP,isSyslogDebug,hasUnappledChanges;

}
@property BOOL isEnabled,isDSDebugging,isLoggingDNS,isDoingNetworkTrace,isTracingDNS,isTracingKerberos,
            isTracingLDAP,isSyslogDebug,hasUnappledChanges;
-(IBAction)apply:(id)sender;
- (void) mainViewDidLoad;

-(void)save;
-(IBAction)optionChanged:(id)sender;
-(void)setDefaults;
-(IBAction)revert:(id)sender;
-(IBAction)compressAndSendToDesktop:(id)sender;
@end
