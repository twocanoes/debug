#!/usr/bin/perl
# debug.perl
# Debug
#
# Created by Timothy Perfitt on 11/6/09.
# Copyright 2013 Twocanoes. All rights reserved.
use Getopt::Long;
use File::Slurp qw(write_file);
use File::Copy;


if ($> >0) { 
    print STDERR "Not running as root. Running as $>. Exiting\n";
    sleep 50;
    exit 0; 
}
#set EUID and RUID to the same (should be 0);
$< = $>;
print STDERR "debug.perl starting\n";
$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin:/usr/sbin';

my $result=GetOptions("dns!" => \$dns,
"ds!" => \$ds,
"tcpdump=s" => \$tcpdump,
"syslog!"=>\$syslog,
"install!"=>\$install,
"ports=s"=>\$ports,
"disable!"=>\$disable);

if (!$result) {  die "usage: debug.perl [-dns] [-tcpdump <interface>] [-ds]" } ;

if ($install) {
    
    if ($disable) {
        print STDERR "disabling\n";        
        system("rm /var/scripts/debug.perl");

        if (-e "/Library/LaunchDaemons/com.twocanoes.debug.plist") {
            system("launchctl unload -w /Library/LaunchDaemons/com.twocanoes.debug.plist");
            system("rm /Library/LaunchDaemons/com.twocanoes.debug.plist");    
            system("launchctl remove com.twocanoes.tcpdump");
        }
        if (-e "/tmp/.dnsdebugging") {
            system("rm /tmp/.dnsdebugging");
            system("killall -USR2 mDNSResponder");   
        }
        if (-e "/tmp/.syslogverbose") {
            system("rm /tmp/.syslogverbose");
            print "setting syslog master filter to off\n";
            system ("syslog -c 0 off; syslog -c syslog info");
        }
        if (-e "/tmp/.tcpdumprunning"){
            system("rm /tmp/.tcpdumprunning");
            system("launchctl remove com.twocanoes.tcpdump");
        }
            
        print "setting opendirectoryd logging level back to default \n";
		system("/usr/bin/odutil set log default");
		
        exit 0;
    }
    print "installing\n";
    my $installargs="";
    if ($dns) { $installargs=$installargs."<string>-dns</string>" };
    if ($ds) { $installargs=$installargs."<string>-ds</string>" };
    if ($tcpdump && $ports) { $installargs=$installargs."<string>-tcpdump</string><string>$tcpdump</string><string>-ports</string><string>$ports</string>" };
    if ($syslog) { $installargs=$installargs."<string>-syslog</string>" };

    my $launchditem = <<HERE;
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
	<key>Label</key>
	<string>com.twocanoes.debug</string>
	<key>ProgramArguments</key>
	<array>
    <string>/usr/bin/perl</string>
    <string>/var/scripts/debug.perl</string>
    $installargs
	</array>
	<key>RunAtLoad</key>
	<true/>
    </dict>
    </plist>

HERE
    my $mode = 0755;
    if (!(-e "/var/scripts")) {
        mkdir "/var/scripts";
        chmod $mode,"/var/scripts";
        chown 0,0,"/var/scripts";
    }
    
    copy("$0","/var/scripts/debug.perl");
    $mode = 0755;
    chmod $mode,"/var/scripts/debug.perl";
    chown 0,0,"/var/scripts/debug.perl";
    
    #    if (-e "/Library/LaunchDaemons/com.twocanoes.debug.plist") {
    print STDERR "unloading old launchd item\n";
               system("launchctl unload -w /Library/LaunchDaemons/com.twocanoes.debug.plist");
    #    }
    write_file('/Library/LaunchDaemons/com.twocanoes.debug.plist', $launchditem);
    if (-e "/var/scripts/debug.perl" ) { print STDERR "we have foujnd the file!\n";}
    else {print STDERR "no file found\n";}
    print STDERR "loading new launchd item\n";

    system("launchctl load -w  /Library/LaunchDaemons/com.twocanoes.debug.plist");
    
    
    exit 0;
}

if ($ds) {
    print "opendirectoryd debugging requested to be turned on\n";

    system("/usr/bin/odutil set log debug");
}
else {
    print "opendirectoryd debugging requested to be turned off\n";
    system("/usr/bin/odutil set log default");
    
}



if ($dns){
    if (-e "/tmp/.dnsdebugging") {
        print "DNS Debugging is already on!\n";
    }
    else {
        my $cnt=0;
        while (not -e "/var/run/mDNSResponder") {
            print "waiting for mDNSResponder\n";
            sleep 1;
            $cnt++;
            if ($cn>30) {
                print "giving up on mDNSResponder starting\n";
                last;
            }
        }
        
        print "setting DNS Debugging\n";
        system("syslog -c mDNSResponder -d");
        system("killall -INFO mDNSResponder");
        system("killall -USR2 mDNSResponder");
        system("touch /tmp/.dnsdebugging");
    }
}
else {
        if (-e "/tmp/.dnsdebugging") {
            print "Turning off DNS logging\n";
            system("rm /tmp/.dnsdebugging");
            system("killall -USR2 mDNSResponder");
        }
        else {
            print "DNS Debugging already off\n";
        }
}
    
if ($syslog){
    system("touch /tmp/.syslogverbose");
    print "setting syslog to debug level\n";
    system ("syslog -c 0 -d; syslog -c syslog -d");
}
else {
    system("rm /tmp/.syslogverbose");
    print "setting syslog master filter to off\n";
    system ("syslog -c 0 off; syslog -c syslog info");
}

if ($tcpdump && $ports) {
    
    print "!!!!!!!!";
    system("touch /tmp/.tcpdumprunning");
    print STDERR "setting tcpdump Debugging\n";
    my $now=`date +%Y%h%d%H%M%S`;
    chomp($now);
    
    if (-e "/var/scripts/.interface") {
        $tcpdump=`cat /var/scripts/.interface`;
        chomp($tcpdump);
    }
    system("launchctl remove com.twocanoes.tcpdump");


    print "running system(\"launchctl submit -l com.twocanoes.tcpdump tcpdump -i ${tcpdump} -s 0 -K -w /var/log/tcpdump.$now.dmp $ports\")";
    system("launchctl submit -l com.twocanoes.tcpdump tcpdump -i ${tcpdump} -s 0 -K -w /var/log/tcpdump.$now.dmp port $ports");

  
}
else {
    system("launchctl remove com.twocanoes.tcpdump");
    system("rm /tmp/.tcpdumprunning");

    
}
