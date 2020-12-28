#!/usr/bin/perl
#
# SCRIPT PARA EJECUTAR EL AUTOMATISMO DE LAS PERFORACIONES
#   Para la ejecucion de este script de forma correcta tiene que existir en
# la redis, dentro del key DLGID un paramtro TYPE cuyo valor sea PERF_AND_TQ
# o PERF. 
# EJEMPLO:
# 	DLGID01 
#		TYPE
#			PERF
#	or
#
# 	DLGID 
#		TYPE
#			PERF_AND_TQ
#
#  Tambien dentro del keys DLGID tienen que estar las siguientes variables de 
# configuracion que son particulares para cada perforacion
# # EJEMPLO
#	DLGID01
#		TYPE
#		LOCALIDAD
#		PERF_NAME
#		DLGID_TQ
#		H_MAX_TQ
#		N_MAX_TQ
#		M_ERR_SENSOR_PERF
#		P_MAX_PERF
#		CL_LIBRE_OFFSET
#		SERVER
#		TPOLL_CAU
#		MAGPP
#
#  En caso de que alguna de estas variables no aparezca no se ejecuta el script.

# BLOCK FOR GET PROJECT PATH AND ADD IT TO @INC
my $projectPath = '';
BEGIN {
	use File::Basename qw();
	my $folderProjectName = 'PERFORACIONES';
	use FindBin qw( $RealBin );
	my @dir = split('/',$RealBin);
	for (my $i = 0; $i < @dir; $i++ ) {$projectPath = "$projectPath$dir[$i]/";if($dir[$i] eq $folderProjectName){last}}
}

#LIBRERIAS
	use strict;
	use Redis;
	#	
	use lib "$projectPath";		
	use PERF_CONFIG;												#CONFIGURACION EN EL SERVIDOR
	#					
	use lib "$PERF_CONFIG::spx_process_perf";													
	use spx_process_perf;											#AUTOMATISMO


############################ VARIABLES #################################

	#VARIABLES DE CONFIGURACION
		my $print_log = "OK";										# VER LOS LOGS => "OK"
		my $DLGID_PERF = 'UYPC03';								# ID DATALOGGER PERFORACION
		my $TYPE = 'CHARGE';										# CUANDO TIENE LE VALOR CHARGE LE INDICA AL spx_process_perf CARGAR CONFIG DE LA REDIS
		#
		#
		#
		#
		#
# LLAMADO DEL PROGRAMA
	process_perf ($DLGID_PERF,$TYPE,$print_log);


