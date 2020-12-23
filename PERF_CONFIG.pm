package PERF_CONFIG;
 
use strict;

	use vars qw 
	(				
		$spx_process_perf
		$spx_process_error_perf_test
		$SCRIPT_performance
		$DLG_performance
		$Library_PERF
		
		$smtpserver
		$smtpport
		$smtpuser
		$smtppassword
		
		$dbuser
		$dbpasswd
		$host
		$dbase
	);

	
	# version 1.4.4	20-12-2019

# A CONTINUACION SE DEFINEN LAS CONFIGURACIONES PARA EL TRABAJO DEL SISTEMA
	# ADDRESS
		$spx_process_perf = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
		$spx_process_error_perf_test = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
		$SCRIPT_performance = '/datos/cgi-bin/spx/PERFORACIONES/SCRIPT_performance';
		$DLG_performance = '/datos/cgi-bin/spx/PERFORACIONES/DLG_performance';
		$Library_PERF = '/datos/cgi-bin/spx/PERFORACIONES/PROCESS';
	
	# MAIL CONFIG
		$smtpserver = 'Gmail';						# SE DEFINE EL TIPO DE SERVIDOR DE CORREO ( localhost | Gmail)
		$smtpport = 25;
		$smtpuser = 'spymovil@spymovil.com';
		$smtppassword = 'pexco456';
	
	# POSTGRE CONFIG
		$dbuser = "admin";
		$dbpasswd = "pexco599";
		$host="192.168.0.6";
		$dbase="GDA";
 	

1;
