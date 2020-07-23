#!/usr/bin/perl
#
# SCRIPT PARA TESTEAR LOS DATALOGGERS
#   Este script se encarga de testar los datalogger con la configuracion y 
# opciones que el mismo define. Tambien genera toda la configuracion en la 
# REDIS para si posteriormente se quiere hacer un llamado con el archivo 
# call_error_perf_test.pl 
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


################ VARIABLES DE CONFIGURACION ######################

#VARIABLES DE CONFIGURACION QUE SE GUARDAN EN REDIS
	my $DLGID = "UYPC03";									# ID DATALOGGER A TESTEAR
	my $TYPE = 'PERF';										# TIPO DE INSTALACION {PERF_AND_TQ | PERF | TQ | OTHER }
	my $DLGID_TQ = 'UYPC04';								# EN CASO DE QUE EL EQUIPO TESTEADO SEA UN PERFORACION SIN TANQUE SE ESPECIFICA A QUE TANQUE ESTA ASOCIADA
	my $SEND_MAIL = 'NO';									# SE ELIGE SI SE QUIERE ENVIAR ALARMAS EN FORMA DE MAIL { SI | NO }
	my $TQ_NAME = '75.4.0.19 Castillo';						# NOMBRE DEL TANQUE QUE SE VA A MOSTAR EN LA ALARMA DE NIVEL DE TANQUE	
	my $PERF_NAME = '75.4.0.19 Castillo';					# NOMBRE DE LA PERFORACION QUE SE VA A MOSTAR EN LA ALARMA DE NIVEL DE TANQUE	
	my $emailAddr_tq = '';									# MAIL A LOS CUALES SE VA A ENVIAR LA ALARMA DE NIVEL DE LOS TANQUES
	my $emailAddr_perf = '';								# MAIL A LOS CUALES SE ENVIA ALARMAS DE EVENTOS EN LAS PERFORACIONES
	#
	#
#VARIABLES DE CONFIGURACION QUE SE CARGAN
	my $print_log = "OK";									# VER LOS LOGS => "OK"
    my $SWITCH_OUTPUTS = 'NO';								# ALTERNAR SALIDAS => 'OK'
	my $TEST_OUTPUTS = 'SI';								# PARA TESTEAR LAS SALIDAS Y EN CASO DE TRES ERRORES CONSECUTIVOS REINICIAR => 'OK'
	my $EVENT_DETECTION = 'SI';								# SE USA PARA DEJAR REGISTRADOS CIERTOS EVENTOS DE LAS PERFORACIONES { SI | NO }
	my $test_emergency_system = 'SI';						# PARA TESTEAR EL SISTEMA DE EMERGENCIA ( BOYAS O TIMERS) { SI | NO }
	my $TEST_SOURCE = 'SI';									# SE ELIGE SI SE QUIERE TESTEAR LA FUENTE DEL TABLERO DE LA PERFORACION { SI | NO }
	#
	#
# LLAMADO DEL PROGRAMA
	error_perf_test ($print_log,$DLGID,$SWITCH_OUTPUTS,$TEST_OUTPUTS,$EVENT_DETECTION,$test_emergency_system,$TEST_SOURCE,$TYPE,$DLGID_TQ,$SEND_MAIL,$TQ_NAME,$PERF_NAME,$emailAddr_tq,$emailAddr_perf);


