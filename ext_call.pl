#!/usr/bin/perl


#L	lamando a este fichero con el dlgid del datalogger se corren las perforaciones per
#	Ex: 
#		ext_call.pl --dlgid [my_dlgid]

use strict;

# BLOCK FOR GET PROJECT PATH AND ADD IT TO @INC
my $projectPath = '';
BEGIN {
	use File::Basename qw();
	my $folderProjectName = 'PERFORACIONES';
	my ($name, $path, $suffix) = File::Basename::fileparse($0);
	my @dir = split('/',$path);
	for (my $i = 0; $i < @dir; $i++ ) {$projectPath = "$projectPath$dir[$i]/";if($dir[$i] eq $folderProjectName){last}}
}

use Getopt::Long;

use lib "$projectPath";	
use PERF_CONFIG;		

use lib "$PERF_CONFIG::spx_process_perf";
use spx_process_perf;	
 
my $my_dlgid;	

GetOptions ('dlgid=s' => \$my_dlgid);

process_perf ($my_dlgid,'CHARGE');




