#!/usr/bin/perl
#
# SCRIPT PARA EJECUTAR EL AUTOMATISMO DE LAS PERFORACIONES
#   Este script se encarga de el automatismo de las perforaciones con la configuracion y 
# opciones que el mismo define. Tambien genera toda la configuracion en la 
# REDIS para si posteriormente se quiere hacer un llamado con el archivo 
# call_spx_process_perf.pl 
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
	use lib "$PERF_CONFIG::spx_process_perf";													
	use spx_process_perf;											#AUTOMATISMO

################ VARIABLES DE CONFIGURACION ######################
#
# VARIABLES DE ENTRADA
		my $print_log = 'OK';										# VER LOS LOGS => "OK"
		my $DLGID_PERF = 'UYPC03';									# ID DEL AUTOMATISMO A LLAMAR
		#
# VARIABLES DE CONFIGURACION QUE SE GUARDAN EN REDIS
	# EN EL DLGID_PERF
		my $TYPE = 'PERF';											# TIPO DE INSTALACION {PERF_AND_TQ | PERF | TQ | OTHER }
		my $M_ERR_SENSOR_PERF = 'NO';								# SETEO MANUAL DE ERROR EN EL SENSOR DE LA PERFORACION { SI|NO }
		my $P_MAX_PERF = 10;										# MAXIMA PRESION DE IMPULSION DE LA PERFORACION PARA CASOS EN QUE HAYA SENSOR DE PRESION
		my $TPOLL_CAU = 5;											# TIEMPO EN MINUTOS DEL POLEO DEL CAUDAL EN CASO DE QUE HAYA CAUDALIMETRO CONECTADO
		my $DLGID_TQ = 'UYPCPP';									# ID DATALOGGER DEL TANQUE
		#
	# EN EL DLGID_TQ	
		my $H_MAX_TQ = 2.30;										# ALTURA DEL REBALSE DEL TANQUE
		my $N_MAX_TQ = 2.28;										# NIVEL MAXIMO AL CUAL SE PUEDE LLENAR EL TANQUE
		my $M_ERR_SENSOR_TQ = 'NO';									# SETEO MANUAL DE ERROR EN EL SENSOR DEL TANQUE { SI|NO }
#
# LLAMADO DEL PROGRAMA
process_perf ($DLGID_PERF,$TYPE,$print_log,$DLGID_TQ,$H_MAX_TQ,$N_MAX_TQ,$M_ERR_SENSOR_PERF,$M_ERR_SENSOR_TQ,$P_MAX_PERF,$TPOLL_CAU);


