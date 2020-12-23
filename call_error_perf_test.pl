#!/usr/bin/perl
#
# SCRIPT PARA TESTEAR LOS DATALOGGERS
#   Para la ejecucion de este script de forma correcta tiene que existir en 
# la redis un KEYS llamado ERROR_PERF_TEST y dentro del mismo un paramtro 
# SCAN cuyos valores sean todos los KEYS de la REDIS en donde estan guardadas
# las configuraciones asi como la linea LINE con los datos que recibe el servidor
# desde el equipo. 
# EJEMPLO:
#	ERROR_PERF_TEST
#		SCAN
#			DLGID01;DLGID02....DLGID..n
# Dentro de cada DLGID deben estar las siguentes variables de configuracion.
# EJEMPLO
#	DLGID01
#		TYPE
#		SEND_MAIL
#	Si TYPE = PERF
#		PERF_NAME
#		DLGID_TQ
#		emailAddr_perf
#		CL_MIN_ALARM
#		CL_MAX_ALARM
#	Si TYPE = PERF AND TQ
#		PERF_NAME
#		DLGID_TQ
#		emailAddr_perf
#		CL_MIN_ALARM
#		CL_MAX_ALARM
#		TQ_NAME
#		emailAddr_tq
#	Si TYPE = TQ
#		TQ_NAME
#		emailAddr_tq
#
#

	# version 1.4.4	19-09-2019


#LIBRERIAS
	use strict;	
	use Redis;
	#	
	use lib '/';	
	use PERF_CONFIG;												#CONFIGURACION EN EL SERVIDOR
	#					
	use lib "$PERF_CONFIG::spx_process_error_perf_test";													
	use spx_process_error_perf_test;								#AUTOMATISMO



############################ VARIABLES #################################

	#VARIABLES DE CONFIGURACION
		my $print_log = 'OK';				# VER LOS LOGS => "OK"
		my $DLGID;							# ID DATALOGGER A TESTEAR
		my $TYPE = 'CHARGE';				# CHANDO TIENE LE VALOR CHARGE LE INDICA AL error_perf_test CARGAR CONFIG DE LA REDIS
		#
		my $SWITCH_OUTPUTS = 'NO';			# ALTERNAR SALIDAS => 'OK'
		my $TEST_OUTPUTS = 'SI';			# PARA TESTEAR LAS SALIDAS Y EN CASO DE TRES ERRORES CONSECUTIVOS REINICIAR => 'OK'
		my $EVENT_DETECTION = 'SI';			# SE USA PARA DEJAR REGISTRADOS CIERTOS EVENTOS DE LAS PERFORACIONES { SI | NO }
		my $test_emergency_system = 'SI';	# PARA TESTEAR EL SISTEMA DE EMERGENCIA ( BOYAS O TIMERS) { SI | NO }
		my $TEST_SOURCE = 'SI';				# SE ELIGE SI SE QUIERE TESTEAR LA FUENTE DEL TABLERO DE LA PERFORACION { SI | NO }
		my $SERVER = 'OSE';					# SERVIDOR EN DONDE SE CORRE EL SCRIPT { SPY | OSE }
		#
		#
	##OTRAS
		my $redis=Redis->new(server => '192.168.0.8:6379', debug => 0);				# CONNECT TO REDIS
		my $SCAN;							# VERIABLE CON LOS DATALOGGERS A SCANEAR

########################## MAIN PROGRAM ################################

	##LEO EL PARAMETRO $SCAN
		###LEO SI EXISTE EL PARAMETRO
		my $EXISTS = $redis->hexists("PERFORACIONES_DLG_ERROR_TEST", "SCAN");
		if ($EXISTS == 1)
		#LEO EL PARAMETRO
		{
			$SCAN = $redis->hget("PERFORACIONES_DLG_ERROR_TEST", 'SCAN');
		}
		else
		{
			print "NO EXISTE EN REDIS EL KEYS PERFORACIONES_DLG_ERROR_TEST => SCAN\n";
		}
		#print "$SCAN\n";
		my @params = split(/;/,$SCAN);
		#print "@params\n";
		my $i;
		for($i = 0; $i < @params; $i++) 
		{
			$DLGID = $params[$i];
			print "RUN => 	$DLGID\n";
			error_perf_test ($print_log,$DLGID,$SWITCH_OUTPUTS,$TEST_OUTPUTS,$EVENT_DETECTION,$test_emergency_system,$TEST_SOURCE,$TYPE);
		}
		
exit 0;

