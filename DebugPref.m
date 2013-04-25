//
//  DebugPref.m
//  Debug
//
//  Created by Timothy Perfitt on 11/6/09.
//  Copyright (c) 2013 twocanoes. All rights reserved.
//

#import "DebugPref.h"


@implementation DebugPref
@synthesize isEnabled,isDSDebugging,isLoggingDNS,isDoingNetworkTrace,isTracingDNS,
            isTracingKerberos,isTracingLDAP,isSyslogDebug,hasUnappledChanges;


-(IBAction)compressAndSendToDesktop:(id)sender{
  
    NSTask *task=[[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/zip"];
    NSString *desktopFile=@"~/Desktop/debug.zip";
    [task setArguments:[NSArray arrayWithObjects:@"-r",[desktopFile stringByExpandingTildeInPath],
                        @"/Library/Logs",@"/var/log",nil]];
    
    [task launch];
    [task waitUntilExit];
}
-(NSString *)interface{
    
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"interface"];
}
-(void)setDefaults{
    NSFileManager *fm=[NSFileManager defaultManager];
   // [self setInterface:@"en0"];
    [self setHasUnappledChanges:NO];
    
    if ([fm fileExistsAtPath:@"/Library/LaunchDaemons/com.twocanoes.debug.plist"]) [self setIsEnabled:YES];
    else [self setIsEnabled:NO];
    
    
    if ([fm fileExistsAtPath:@"/Library/Preferences/DirectoryService/.DSLogDebugAtStart"]) [self setIsDSDebugging:YES];
    else [self setIsDSDebugging:NO];
    
    if ([fm fileExistsAtPath:@"/tmp/.dnsdebugging"]) [self setIsLoggingDNS:YES];
    else [self setIsLoggingDNS:NO];
    
    if ([fm fileExistsAtPath:@"/tmp/.syslogverbose"]) [self setIsSyslogDebug:YES];
    else [self setIsSyslogDebug:NO];
    
    if ([fm fileExistsAtPath:@"/tmp/.tcpdumprunning"]) [self setIsDoingNetworkTrace:YES];
    else [self setIsDoingNetworkTrace:NO];
    
    if ([fm fileExistsAtPath:@"/tmp/.tracedns"]) [self setIsTracingDNS:YES];
    else [self setIsTracingDNS:NO];
    
    if ([fm fileExistsAtPath:@"/tmp/.tracekerberos"]) [self setIsTracingKerberos:YES];
    else [self setIsTracingKerberos:NO];
    
    
    if ([fm fileExistsAtPath:@"/tmp/.traceldap"]) [self setIsTracingLDAP:YES];
    else [self setIsTracingLDAP:NO];
    
    
}
- (void) mainViewDidLoad
{

    [lockView setDelegate:self];
    [lockView setString:"system.privilege.admin"];
    [lockView setAutoupdate:YES];
    [lockView updateStatus:self];
    authorization=nil;
    
    [self setDefaults];
   
    
}
-(IBAction)apply:(id)sender{
    [self save];
  }
-(void)save{


    NSFileManager *fm=[NSFileManager defaultManager];
    authorization=[[lockView authorization] authorizationRef];
    NSString *scriptPath;
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    scriptPath = [thisBundle pathForResource:@"debug" ofType:@"perl"];
    
    
    const char *pathToTool=[scriptPath UTF8String];
    AuthorizationFlags flags = kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed |
    kAuthorizationFlagPreAuthorize |
    kAuthorizationFlagExtendRights;
   
    
    int curArg=2;
    char **arguments = calloc(10 , sizeof(char *));

    if ([self isEnabled]==YES) {
        
        if ([self isDSDebugging]==YES) {
            NSLog(@"adding ds at %i",curArg);
            arguments[curArg++]="-ds";
        }
        if ([self isDoingNetworkTrace]==YES) {
            NSMutableArray *ports=[NSMutableArray arrayWithCapacity:4];
            arguments[curArg++]="-tcpdump";
            arguments[curArg++]=(char *)[[self interface] UTF8String];
            [fm createFileAtPath:@"/tmp/.tracedns" contents:nil attributes:nil];
            [ports addObject:@"port 53"];
            [ports addObject:@"port 5353"];
            [ports addObject:@"port 464"];
            [ports addObject:@"port 88"];
            [ports addObject:@"port 389"];
            [ports addObject:@"port 636"];
            
                        
            if ([ports count]>0) {
                arguments[curArg++]="-ports";
                NSString *optionsObject=[ports componentsJoinedByString:@" or "];
                char *options=calloc([optionsObject length]+1, sizeof (char));
                strncpy(options,(char *)[optionsObject UTF8String],sizeof(char)*([optionsObject length]+1));
                arguments[curArg++]=options;
            }
            
        }
        if ([self isLoggingDNS]==YES) {
            arguments[curArg++]="-dns";
        }
        if ([self isSyslogDebug]==YES) {
            arguments[curArg++]="-syslog";
        }
    }

   
    if (curArg==2) { 
        arguments[curArg++]="-disable";
    }
        // either disabled or nothing selected
    AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &right};
    
    OSStatus status;
    // Call AuthorizationCopyRights to determine or extend the allowable rights.
    status = AuthorizationCopyRights(authorization, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess)
        NSLog(@"Copy Rights Unsuccessful: %d", status);
    
    NSLog(@"path is %s",pathToTool);
    arguments[0]=(char *)pathToTool;
    arguments[1]="-install";
    int i;
    for (i=0;i<curArg;i++) {
        NSLog(@"arg[%i] is %s",i,arguments[i]);
    }
    status=AuthorizationExecuteWithPrivileges (
                                        authorization,
                                        "/usr/bin/perl",
                                        kAuthorizationFlagDefaults,
                                        arguments,
                                        nil);
    if (status != errAuthorizationSuccess)
        NSLog(@"AuthorizationExecuteWithPrivileges Unsuccessful: %d", status);
    
    [self setHasUnappledChanges:NO];
 /*   NSRunInformationalAlertPanel(@"Restart Required", 
                                 @"Logging will now take affect on restart.", 
                                 @"OK",  nil,nil);
  */
    
}
-(IBAction)optionChanged:(id)sender{
    [self setHasUnappledChanges:YES];
}
-(IBAction)revert:(id)sender{
    [self setDefaults];
}
@end
