package PERF_CONFIG;
 
use strict;
use Switch;

	use vars qw (				
		$spx_process_perf
		$spx_process_error_perf_test
		$SCRIPT_performance
		$DLG_performance
		$Library_PERF
		$fileLogPath
		
		$smtpserver
		$smtpport
		$smtpuser
		$smtppassword
		
		$rdServer

		$dbuser
		$dbpasswd
		$host
		$dbase
	);

# SERVERS CONFIG
	my $SERVER_TAG = 'LOCAL';				# SERVER CONFIG SELECTION 	{ LOCAL | SPY_9 | SPY_7 | OSE }			
	


#################### PARTICULAR CONFIGURATIONS FOR EACH SERVER ####################

switch($SERVER_TAG){

	case 'LOCAL' {
		# ADDRESS
			$spx_process_perf = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$spx_process_error_perf_test = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$SCRIPT_performance = '/datos/cgi-bin/spx/PERFORACIONES/SCRIPT_performance';
			$DLG_performance = '/datos/cgi-bin/spx/PERFORACIONES/DLG_performance';
			$Library_PERF = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$fileLogPath = '/var/log/aut_perf.log';
		# MAIL
			$smtpserver = 'Gmail';						
			$smtpport = 25;
			$smtpuser = 'spymovil@spymovil.com';
			$smtppassword = 'pexco456';
		# REDIS
			$rdServer = '127.0.0.1:6379';
		# POSTGRE
			$dbuser = 'postgres';
			$dbpasswd = "pexco599";
			$host="127.0.0.1";
			$dbase="GDA";
	}
	case 'SPY_7' {
		# ADDRESS
			$spx_process_perf = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$spx_process_error_perf_test = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$SCRIPT_performance = '/datos/cgi-bin/spx/PERFORACIONES/SCRIPT_performance';
			$DLG_performance = '/datos/cgi-bin/spx/PERFORACIONES/DLG_performance';
			$Library_PERF = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$fileLogPath = '/var/log/aut_perf.log';
		# MAIL
			$smtpserver = 'Gmail';						
			$smtpport = 25;
			$smtpuser = 'spymovil@spymovil.com';
			$smtppassword = 'pexco456';
		# REDIS
			$rdServer = '192.168.0.8:6379';
		# POSTGRE
			$dbuser = "admin";
			$dbpasswd = "pexco599";
			$host="192.168.0.6";
			$dbase="GDA";
	}
	case 'SPY_9' {
		# ADDRESS
			$spx_process_perf = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$spx_process_error_perf_test = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$SCRIPT_performance = '/datos/cgi-bin/spx/PERFORACIONES/SCRIPT_performance';
			$DLG_performance = '/datos/cgi-bin/spx/PERFORACIONES/DLG_performance';
			$Library_PERF = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
			$fileLogPath = '/var/log/aut_perf.log';
		# MAIL
			$smtpserver = 'Gmail';						
			$smtpport = 25;
			$smtpuser = 'spymovil@spymovil.com';
			$smtppassword = 'pexco456';
		# REDIS
			$rdServer = '127.0.0.1:6379';
		# POSTGRE
			$dbuser = "admin";
			$dbpasswd = "pexco599";
			$host="192.168.0.6";
			$dbase="GDA";
	}



}

	
 	

1;
