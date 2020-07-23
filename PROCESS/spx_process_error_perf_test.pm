package spx_process_error_perf_test;

#LIBRERIAS 
	use strict;
	use Redis;
	use Email::Send;
	use Email::Send::Gmail;
	use Email::Simple::Creator;
	#
	use lib '/';	
	use PERF_CONFIG;										#CONFIGURACION EN EL SERVIDOR	
	#
	use lib "$PERF_CONFIG::Library_PERF";												
	use Library_PERF;										#BIBLIOTECA DE LAS PERFORACIONES	

 
BEGIN {
  use Exporter ();
  use vars qw|$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS|;
 
 # $VERSION  = '1.00';  
   
  @ISA = qw|Exporter|;
 
  @EXPORT = qw|&error_perf_test|; 
 
  @EXPORT_OK = qw(); 
 
  %EXPORT_TAGS = ( ); 
 }

# DEFINICION DE VARIABLES GLOBALES PARA ESTE PAQUETE
{
	use vars qw 
	(				
		$print_log	$DLGID 
				
		$SWITCH_OUTPUTS $TEST_OUTPUTS $EVENT_DETECTION $test_emergency_system 
		$TEST_SOURCE $SERVER 
				
		$TYPE $DLGID_TQ $SEND_MAIL $TQ_NAME $PERF_NAME 
				
		$emailAddr_tq $emailAddr_perf 
				
		$FECHA_DATA	$HORA_DATA 
				
		$PPR $LTQ $CL $BAT $GA $FE $LM $BD $BP $BY $TM $ABY
		$FT $PCAU $bt $offset_bt
				
		$DO_0 $DO_1 $DO_2 $DO_3 $DO_4 $DO_5 $DO_6 $DO_7
				
		$TX_ERROR $H_TQ
				
		$redis $LAST_FECHA_DATA $last_fecha_data $last_hora_data $NUMERO_EJECUCION $STATE
		$CURR_FECHA_SYSTEM $CURR_FECHA_SHORT $error_ES_count $outputs_states
		$N_MAX_TQ $ERR_SENSOR_TQ $tq_level_mail_alarm $tq_count_mail_alarm
		$cl_low_level_mail_alarm $cl_low_count_mail_alarm $cl_high_level_mail_alarm
		$cl_high_count_mail_alarm $return_tx $outputs_change $CL_MIN_ALARM
		$CL_MAX_ALARM $CL_ALARM_STATE $L_MIN_ALARM $L_MAX_ALARM $tq_state 
				
	);
}


END { }
 
 
# El codigo del modulo
 
sub error_perf_test
{
	
	# version 1.4.8	23-07-2020
 
	# -------------------CONTROL DE VERSIONES---------------------------
	#
	#	Se implemento la funcion pw_save
	#	Se modifico la funcion tx_error para que muestre siempre cuando el equipo paso mas de 15 min caido
	#	Se modifico test outputs para que le entraran los valores {SI|NO}
	#	Se implemento el log de cambio de esto en el DLG_Performance. Se saco del script performance
	#	Se modificaron unos logs de error TX
	#	Se modificaron algunos logs en test_outputs.
	#	Se le puso una condicion para que no chequeara el sistema de emergencia con error en el sensor
	#	SE LE PUSO UNA EXCEPCION EN reset_DLG para que UYSAL010 PARA QUE NO SE REINICIARA OJOOOOO
	#	Se le hicieron algunas adaptaciones para que funcionara con el sistema de visualizacion nuevo
	#	Se implemento un offset_bt SOLO CONFIGURABLE DESDE LA REDIS para corregir las mediciones erroneas del datalogger
	#	Cuando el equipo es un OTHER se fija en el TPOLL para ver cuando hay que registrar error TX
	#	Se habilito el envio de mails para el servidor de spy
	#	Se corrigio la forma en que se escribia tq_count_mail_alarm
	#
	#-------------------------------------------------------------------


#################### VARIABLES DE CONFIGURACION ########################

		#VARIABLES DE CONFIGURACION
			$print_log = $_[0];				# VER LOS LOGS => "OK"
			$DLGID = $_[1];					# ID DATALOGGER A TESTEAR
			#
			$SWITCH_OUTPUTS = $_[2];		# ALTERNAR SALIDAS => 'OK'
			$TEST_OUTPUTS = $_[3];			# PARA TESTEAR LAS SALIDAS Y EN CASO DE TRES ERRORES CONSECUTIVOS REINICIAR => 'OK'
			$EVENT_DETECTION = $_[4];		# SE USA PARA DEJAR REGISTRADOS CIERTOS EVENTOS DE LAS PERFORACIONES { SI | NO }
			$test_emergency_system = $_[5];	# PARA TESTEAR EL SISTEMA DE EMERGENCIA ( BOYAS O TIMERS) { SI | NO }
			$TEST_SOURCE = $_[6];			# SE ELIGE SI SE QUIERE TESTEAR LA FUENTE DEL TABLERO DE LA PERFORACION { SI | NO }
			$SERVER = 'OSE';				# SERVIDOR EN DONDE SE CORRE EL SCRIPT { SPY | OSE }
			#
			$TYPE = $_[7];					# TIPO DE INSTALACION {PERF_AND_TQ | PERF | TQ | OTHER }
			$DLGID_TQ = $_[8];				# EN CASO DE QUE EL EQUIPO TESTEADO SEA UN PERFORACION SIN TANQUE SE ESPECIFICA A QUE TANQUE ESTA ASOCIADA
			$SEND_MAIL = $_[9];				# SE ELIGE SI SE QUIERE ENVIAR ALARMAS EN FORMA DE MAIL { SI | NO }
			$TQ_NAME = $_[10];				# NOMBRE DEL TANQUE QUE SE VA A MOSTAR EN LA ALARMA DE NIVEL DE TANQUE	
			$PERF_NAME = $_[11];			# NOMBRE DE LA PERFORACION QUE SE VA A MOSTAR EN LA ALARMA DE NIVEL DE TANQUE	
			#
			$emailAddr_tq = $_[12];			# MAIL AL CUAL SE LE ENVIA LA ALARMA DE NIVEL MINIMO DEL TANQUE
			$emailAddr_perf = $_[13];		# MAIL AL CUAL SE LE ENVIA LAS ALARMAS DE CLORO
			#
			#
		#ULTIMO DATO DEL DATALOGGER
		##FECHA Y HORA
			$FECHA_DATA;					# FECHA_DATA DEL ÚLTIMO DATO DE DLGID
			$HORA_DATA;						# HORA_DATA DEL ÚLTIMO DATO DE DLGID
			#
			#
		# VARIABLES UTILIZADAS PARA LEER LOS DATOS DEL DATALOGGER SIN IMPORTAR EL CANAL
		## LAS ANTIGUAS VARIABLES DEL CANAL VAN A SER ELIMINADAS CUANDO SE COMPATIBILICE EL SISTEMA
			$PPR;
			$LTQ;
			$CL;
			$BAT;
			$GA;
			$FE;
			$LM;
			$BD;
			$BP;
			$BY;
			$TM;
			$ABY;
			$FT;
			$PCAU;
			$bt;
			$offset_bt;
			#
			#
		##SALIDAS A RELE (TODAS ACTIVAS EN 1)
			$DO_0;			
			$DO_1;
			$DO_2;	
			$DO_3;
			$DO_4;
			$DO_5;
			$DO_6;
			$DO_7;
			#
			#
		# SALIDAS DE VISUALIZACION
			$TX_ERROR;
			$H_TQ;
			#
			#
		#OTRAS
			$redis=Redis->new();			# CONNECT TO REDIS
			$LAST_FECHA_DATA;				# ARREGLO DE FECHA Y HORA PARA LA VISUALIZACION
			$last_fecha_data;				# FECHA DEL DATO DE LA UTIMA CORRIDA DEL PROGRAMA
			$last_hora_data;				# HORA DEL DATO DE LA UTIMA CORRIDA DEL PROGRAMA
			$NUMERO_EJECUCION;				# NUMERO DE VECES QUE CORRE EL SCRIPT SIN REINICIO DEL SERVER
			$STATE;							# USADO PARA HACER UN CICLO DE ACTIVACION DE SALIDAS
			$CURR_FECHA_SYSTEM; 			# VARIABLE QUE ALMACENA LA FECHA Y HORA DEL SISTEMA
			$CURR_FECHA_SHORT;				# VARIABLE QUE ALMACENA LA FECHA DEL SISTEMA ( SOLO FECHA ) 
			$error_ES_count = 0;			# CONTADOR DE ERRORES PARA EL RESET DEL DATALOGGER
			$outputs_states = 0;			# ESTADOS POR LOS CUALES PASAN LAS SALIDAS
			$N_MAX_TQ;						# NIVEL MAXIMO AL CUAL SE PUEDE LLENAR EL TANQUE
			$ERR_SENSOR_TQ;					# INDICA CUANDO HAY UN ERROR EN EL SENSOR DEL TANQUE
			$tq_level_mail_alarm;			# INDICA CUANDO  SE ENVIO EL MAIL DE ALARMA DEL NIVEL DEL TANQUE
			$tq_count_mail_alarm = 0; 		# CONTADOR DE MUESTRAS DE NIVEL BAJO DEL TANQUE ANTES DEL ENVIO DE UN MAIL
			$cl_low_level_mail_alarm;		# INDICA CUANDO  SE ENVIO EL MAIL DE ALARMA DEL NIVEL BAJO DE CLORO
			$cl_low_count_mail_alarm = 0;	# CONTADOR DE MUESTRAS DE NIVEL BAJO DE CLORO ANTES DEL ENVIO DE UN MAIL
			$cl_high_level_mail_alarm;		# INDICA CUANDO  SE ENVIO EL MAIL DE ALARMA DEL NIVEL ALTO DE CLORO
			$cl_high_count_mail_alarm = 0;	# CONTADOR DE MUESTRAS DE NIVEL ALTO DE CLORO ANTES DEL ENVIO DE UN MAIL
			$return_tx;						# VARIABLE QUE DEFINE SI HUBO ERROR DE TX
			$outputs_change;				# VARIABLE QUE INDICA CUANDO EL SCRIPT DE LAS PERFORACIONES HIZO EN CAMBIO EN LAS SALIDAS
			$CL_MIN_ALARM;					# NIVEL MINIMO DE CLORO AL CUAL SE QUIERE GENERAR ALARMAS
			$CL_MAX_ALARM;					# NIVEL MAXIMO DE CLORO AL CUAL SE QUIERE GENERAR ALARMAS
			$CL_ALARM_STATE;				# ALARMA PARA INDICAR CUANDO EL CLORO SE SALE DE LOS NIVELES
			$L_MIN_ALARM;					# SI LA ALTURA DEL TANQUE ES INFERIOR DE ESTE VALOR SE GENERA UNA ALARMA
			$L_MAX_ALARM;					# SI LA ALTURA DEL TANQUE ES SUPERIOR A ESTE VALOR SE GENERA UNA ALARMA
			$tq_state;						# GUARDA EL ESTADO EN EL QUE SE ENCONTRABA EL TANQUE PARA RECUPERARLO EN CASOS DE REINICIOS DEL DATALOGGER
	
	# NOTA (OJO): Siempre que se vaya a usar una variable nueva hay que definirla como global al principio del script
	#			 y hay que indefinirla cuando se sale del programa en la funcion undef_vars	
				

############################## RUN #####################################
	#
	call_detection("$TYPE");
	no_execution();
	spx_log("DETECCION DE ERRORES_$DLGID");
	spx_log('TYPE = '.$TYPE);
	fecha_system();
	open_file();
	read_redis();
	pw_save(12.8,13.6,180);  #180
	($LTQ,$LAST_FECHA_DATA)= m_cal($DLGID,$FECHA_DATA.'_'.$HORA_DATA,$LTQ,$tq_state,$TYPE);
	test_tx();
	visual();
	event_detection();
	main();
	test_source();
	test_emergency_system();
	alarm_levels();
	quit:
	write_redis();
	undef_vars();
	close(FILE);
	close(FILE1);
	quit_all:
	#
}

######################### PROGRAMA PRINCIPAL ###########################
	sub main
	{
		test_outputs();
		if ($return_tx eq 'OK')
		{
			
			#spx_log( 'TYPE =>'.$TYPE );
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))	
			{
				# TESTEO EL ESTADO ACTUAL DE LAS SALIDAS
				
				# ALTERNO LAS SALIDAS
				switch_outputs();
			}
			elsif (($TYPE eq 'TQ') or ($TYPE eq 'OTHER'))
			{
				spx_log('NO SE TESTEAN LAS SALIDAS => $TYPE= (TQ or OTHER)');
			}
			else
			{
				spx_log('		command error in TYPE');
				print FILE1 "MAIN => command error in TYPE\n";
			}
		}
	}
	#
	
##################### INDEFINIDOR DE VARIABLES #########################	
sub undef_vars
{
	# DESCRIPTION: Esta funcion indefine todas las variables una vez ejecutado el 
	#			script para que si el mismo se ejecuta por llamado hecho dentro de
	#			un ciclo FOR, no se arrastre para el nuevo ciclo el valor de 
	#			varibles de la corrida anterior si fuese el caso de que en el actual
	#			cliclo de corrida las mismas no tomen valores.
		#
	#VARIABLES DE CONFIGURACION
			undef $print_log;	
			undef $DLGID;			
			#
			undef $SWITCH_OUTPUTS;
			undef $TEST_OUTPUTS;
			undef $EVENT_DETECTION;
			undef $test_emergency_system;
			undef $TEST_SOURCE;
			undef $SERVER;
			#
			undef $TYPE;
			undef $DLGID_TQ;
			undef $SEND_MAIL;
			undef $TQ_NAME;	
			undef $PERF_NAME;
			#
			undef $emailAddr_tq;
			undef $emailAddr_perf;
			#
			#
		#ULTIMO DATO DEL DATALOGGER
		##FECHA Y HORA
			undef $FECHA_DATA;
			undef $HORA_DATA;				
			#
			#
		# VARIABLES UTILIZADAS PARA LEER LOS DATOS DEL DATALOGGER SIN IMPORTAR EL CANAL
		## LAS ANTIGUAS VARIABLES DEL CANAL VAN A SER ELIMINADAS CUANDO SE COMPATIBILICE EL SISTEMA
			undef $PPR;
			undef $LTQ;
			undef $CL;
			undef $BAT;
			undef $GA;
			undef $FE;
			undef $LM;
			undef $BD;
			undef $BP;
			undef $BY;
			undef $TM;
			undef $ABY;
			undef $FT;
			undef $PCAU;
			undef $bt;
			undef $offset_bt;
			#
			#
		##SALIDAS A RELE (TODAS ACTIVAS EN 1)
			undef $DO_0;			
			undef $DO_1;
			undef $DO_2;	
			undef $DO_3;
			undef $DO_4;
			undef $DO_5;
			undef $DO_6;
			undef $DO_7;
			#
			#
		# SALIDAS DE VISUALIZACION
			undef $TX_ERROR;
			undef $H_TQ;
			#
			#
		#OTRAS
			undef $redis;
			undef $LAST_FECHA_DATA;	
			undef $last_fecha_data;
			undef $last_hora_data;			
			undef $NUMERO_EJECUCION;		
			undef $STATE;						
			undef $CURR_FECHA_SYSTEM; 			
			undef $CURR_FECHA_SHORT;			
			undef $error_ES_count;
			undef $outputs_states;
			undef $N_MAX_TQ;					
			undef $ERR_SENSOR_TQ;				
			undef $tq_level_mail_alarm;		
			undef $tq_count_mail_alarm;
			undef $cl_low_level_mail_alarm;	
			undef $cl_low_count_mail_alarm;
			undef $cl_high_level_mail_alarm;		
			undef $cl_high_count_mail_alarm;
			undef $return_tx;			
			undef $outputs_change;		
			undef $CL_MIN_ALARM;			
			undef $CL_MAX_ALARM;	
			undef $CL_ALARM_STATE;	
			undef $L_MIN_ALARM;			
			undef $L_MAX_ALARM;		
			undef $tq_state;
				
}
	
	
################## DETECTOR DE ERRORES DE ALIMENTACION #################
	sub test_source
	# SE ENCARGA DE DETECTAR POSIBLES  FALLOS EN LA FUENTE DEL TABLERO Y EL CONTROLADOR DE PANEL SOLAR
	{
		# CHEQUEO SI ESTA HABILITADO EL TESTEO DE LA FUENTES DEL TABLERO DE LA PERFORACION
		if ($TEST_SOURCE eq 'SI')
		{	spx_log("TEST_SOURCE => ENABLE");
			# VERIFICO QUE SE APLIQUE LA CONDICION SOLO PARA EL CASO DEL TABLERO DE LA PERFORACION
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))	
			{
				# VERIFICO SI HAY ERROR TX
				if ($return_tx eq 'OK')
				{
					# VERIFICO QUE NO SE APLIQUE CONDICION DE ERROR DE ALIMENTACION CUANDO HAY FALLA ELECTRICA
					if ( $FE == 0 )
					{
						spx_log("TEST_SOURCE_ERRORS");
						if ( $BAT < 12.1 )
						{
							# ESCRIBO EL ERROR EN EL TXT
							spx_log("TEST_SOURSE_ERRORS => SOURSE FAIL");
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) < ERROR_SOURCE > (BAT) =>  ($BAT).\n";
						}
						else
						{
							spx_log("TEST_SOURSE_ERRORS => SOURSE OK");
						}
					}
					elsif ( $FE == 1 )
					{
						spx_log("TEST_SOURSE_ERRORS => NO SE CHEQUEA LA FUENTE POR FALLA ELECTRICA");
					}
				}
				if ($return_tx eq 'FAIL')
				{
					spx_log("TEST_SOURSE_ERRORS => NO SE CHEQUEA LA FUENTE POR ERROR TX EN LA PERFORACION");
				}
				
			}
		}
		else
		{
			spx_log("TEST_SOURCE => DISABLE");
		}
		
	}
	sub test_emergency_system
	# SE ENCARGA DE DETECTAR POSIBLES FALLOS EN EL SISTEMA DE EMERGENCIA, YA SEA EL TIMER O LA BOYA
	{
		# DESCRIPTION: 
		##
		#
		#
		#VARIABLES DE ENTRADA
		##
		if ($test_emergency_system eq 'SI')
		{
			spx_log('TEST_EMERGENCY_SYSTEM < $TYPE = '.$TYPE);
			spx_log('TEST_EMERGENCY_SYSTEM < $return_tx = '.$return_tx);
			if ($TYPE eq 'TQ')
			{
				spx_log('TEST_EMERGENCY_SYSTEM < $ERR_SENSOR_TQ = '.$ERR_SENSOR_TQ);
				spx_log('TEST_EMERGENCY_SYSTEM < $N_MAX_TQ = '.$N_MAX_TQ);
			}
				#
			if (defined $BY)
			{
				spx_log('TEST_EMERGENCY_SYSTEM < $BY = '.$BY);
			}
				#
			if (defined $TM)
			{
				spx_log('TEST_EMERGENCY_SYSTEM < $TM = '.$TM);
			}
			spx_log('TEST_EMERGENCY_SYSTEM < $LTQ = '.$LTQ);
			
		}
			#
			#
		#MAIN	
		##
		if ($test_emergency_system eq 'SI')
		{
			spx_log('TEST_EMERGENCY_SYSTEM => ENABLE');
			# SE VERIFICA EL CORRECTO FUNCIONAMIENTO DEL TIMER O LA BOYA QUE ESTAN CONECTADOS AL TABLERO DE LA PERFORACION
				# ME ASESORO DE NO TENER ERROR EN EL SENSOR DEL TANQUE
				if ($ERR_SENSOR_TQ eq 'NO')
				{
				# VERIFICO QUE SE APLIQUE LA CONDICION SOLO PARA EL CASO DE PERFORACION
					# EN EL CASO DE PERFORACION LA DETECCION DE ERRORES LA EJECUTA EL SCRIPT DEL TANQUE 
					if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))	
					{
						#spx_log('TEST_EMERGENCY_SYSTEM => EL EQUIPO TESTEADO ES UNA PERFORACION');
						# EVITO QUE SE CHEQUEE EL SISTEMA DE EMERGENCIA CON ERROR TX
						if ($return_tx eq 'OK')
						{
							#spx_log('TEST_EMERGENCY_SYSTEM => SISTEMA SIN ERROR TX');
											
							# DETECTO SI EL SISTEMA DE EMERGENCIA USADO ES UNA BOYA
							if ( defined $BY )
							{
								spx_log('TEST_EMERGENCY_SYSTEM => SISTEMA CON BOYA EN LA PERFORACION');
								# DETECTO SI LA BOYA SE ESTA ACTIVANDO CUANDO EL NIVEL DE AGUA BAJA A 1/4 DE TANQUE
								if (($LTQ < ($N_MAX_TQ/4)) and ($BY == 0))
								{
									spx_log("TEST_EMERGENCY_SYSTEM => LTQ < (N_MAX_TQ/4) AND BY = 0");
									spx_log("TEST_EMERGENCY_SYSTEM => FAIL");
									print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) < ERROR_EMERGENCY_SYSTEM > (N_MAX_TQ / LTQ / BOYA_STATE) =>  ($N_MAX_TQ / $LTQ / $BY).\n";
								}
								# DETECTO SI LA BOYA SE ESTA DESACTIVANDO CUANDO EL NIVEL DE AGUA SUBE A 10 CM DEL NIVEL MAXIMO PERMITIDO EN EL LLENADO DEL TANQUE
								elsif (($LTQ > ($N_MAX_TQ-0.1)) and ($BY == 1))
								{
									spx_log("TEST_EMERGENCY_SYSTEM => LTQ > (N_MAX_TQ-0.1) AND BY = 1");
									spx_log("TEST_EMERGENCY_SYSTEM => FAIL");
									print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) < ERROR_EMERGENCY_SYSTEM > (N_MAX_TQ / LTQ / BOYA_STATE) =>  ($N_MAX_TQ / $LTQ / $BY).\n";
								}
								else
								{
								spx_log("TEST_EMERGENCY_SYSTEM => OK");
								}
							}
							elsif (defined $TM)
							{
								spx_log('TEST_EMERGENCY_SYSTEM => SISTEMA CON TIMER EN LA PERFORACION');
							}
							else
							{
								spx_log('TEST_EMERGENCY_SYSTEM => SISTEMA SIN SISTEMA DE EMERGENCIA');
							}
						}
						else
						{
							spx_log('TEST_EMERGENCY_SYSTEM => SISTEMA CON ERROR TX');
							spx_log('TEST_EMERGENCY_SYSTEM => NO SE TESTEA EL SISTEMA DE EMERGENCIA');
						}
					}
					#
					#
				# SE VERIFICA EL CORRECTO FUNCIONAMIENTO DE LA BOYA CONECTADA AL DATALOGGER DEL TANQUE
					if ($TYPE eq 'TQ')
					{
						if ($return_tx eq 'OK')
						{
							spx_log('TEST_EMERGENCY_SYSTEM => EL EQUIPO TESTEADO ES UNA PERFORACION');
							# DETECTO SI LA BOYA SE ESTA ACTIVANDO CUANDO EL NIVEL DE AGUA BAJA A 1/4 DE TANQUE
							if (($LTQ < ($N_MAX_TQ/4)) and ($ABY < 6))        
							{
								spx_log("TEST_EMERGENCY_SYSTEM => FAIL");
								print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_EMERGENCY_SYSTEM> (N_MAX_TQ / LTQ / BOYA_STATE) =>  ($N_MAX_TQ / $LTQ / $ABY).\n";
							}
							# DETECTO SI LA BOYA SE ESTA DESACTIVANDO CUANDO EL NIVEL DE AGUA SUBE A 10 CM DEL NIVEL MAXIMO PERMITIDO EN EL LLENADO DEL TANQUE
							elsif (($LTQ > ($N_MAX_TQ-0.1)) and ($ABY > 6))
							{
								spx_log("TEST_EMERGENCY_SYSTEM => FAIL");
								print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_EMERGENCY_SYSTEM> (N_MAX_TQ / LTQ / BOYA_STATE) =>  ($N_MAX_TQ / $LTQ / $ABY).\n";
							}
							else
							{
								spx_log("TEST_EMERGENCY_SYSTEM => OK");
							}
					
						}
						elsif ($return_tx eq 'FAIL')
						{
							spx_log("TEST_EMERGENCY_SYSTEM => NO SE CHEQUEA EL SISTEMA DE EMERGENCIA POR ERROR TX EN EL TANQUE");
						}
					}
				}
				else
				{
					spx_log("TEST_EMERGENCY_SYSTEM => ERROR EN EL SENSOR DEL TANQUE");
					spx_log("TEST_EMERGENCY_SYSTEM => NO SE CHEQUEA EL SISTEMA DE EMERGENCIA");
				}
		}
		else
		{
			spx_log('TEST_EMERGENCY_SYSTEM => DESABLE');
		}
	}
	#
	######################## REGISTRO EN ARCHIVO ###########################
	sub open_file
	{
		# SE ENCARGA DE CREAR LOS HISTORICOS DE FUNCIONAMIENTO DEL DATALOGGER
			# TXT QUE REGISTRA ERRORES EN EL AUTOMATISMO
				my $historic_folder = "$PERF_CONFIG::DLG_performance";
				mkdir $historic_folder;
				chmod 0777, $historic_folder;
				#
				my $historic_folder = "$PERF_CONFIG::DLG_performance"."/$DLGID";
				#print "$historic_folder\n";
				mkdir $historic_folder;
				chmod 0777, $historic_folder;
				#
				open( FILE, ">>$PERF_CONFIG::DLG_performance"."/$DLGID"."/error_DLG_test_$DLGID-$CURR_FECHA_SHORT.txt");	
				chmod 0777, "$PERF_CONFIG::DLG_performance"."/$DLGID"."/error_DLG_test_$DLGID-$CURR_FECHA_SHORT.txt";
			
			# TXT QUE REGISTRA LA HORA DE EJECUCION DEL SCRIPT
				my $historic_folder = "$PERF_CONFIG::SCRIPT_performance";
				mkdir $historic_folder;
				chmod 0777, $historic_folder;
				#
				my $historic_folder = "$PERF_CONFIG::SCRIPT_performance"."/spx_process_error_perf_test_$DLGID";
				mkdir $historic_folder;	
				chmod 0777, $historic_folder;
				#
				open( FILE1, ">>$PERF_CONFIG::SCRIPT_performance"."/spx_process_error_perf_test_$DLGID/$DLGID-$CURR_FECHA_SHORT.txt");	
				chmod 0777, "$PERF_CONFIG::SCRIPT_performance"."/spx_process_error_perf_test_$DLGID/$DLGID-$CURR_FECHA_SHORT.txt";
				#
				# ESCRIBO EL ARCHIVO
				print FILE1 "$NUMERO_EJECUCION $CURR_FECHA_SYSTEM.\n";
	}
		#
	######################## ALTERNADOR DE SALIDAS #########################
	sub switch_outputs
	## FUNCION QUE ALTERNA LAS SALIDAS PARA DETECTAR ERRORES EN LAS MISMAS
	{
		#spx_log('SWITCH_OUTPUTS');
		# DETECTO SI ESTOY EN PRECENCIA DE UNA PERFORACION Y ESTA ACTIVADO EL SWITCH DE SALIDAS
		if ((($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF')) and ($SWITCH_OUTPUTS eq 'OK'))
		{
			spx_log('SWITCH_OUTPUTS => SE ALTERNAN LAS SALIDAS');
			# ACTIVO UNA FORMA DE SALIDA EN BASE AL ESTADO POR EL CUAL SE ESTE TRANSITANDO
			if ($outputs_states == 0)
			# ESTADO 0
			{
				$DO_0 = 0;			
				$DO_1 = 0;
				$DO_2 = 0;
				$DO_3 = 0;
			}
			elsif ($outputs_states == 1)
			# ESTADO 1
			{
				$DO_0 = 1;			
				$DO_1 = 1;
				$DO_2 = 1;
				$DO_3 = 0;
			}
			elsif ($outputs_states == 2)
			# ESTADO 2
			{
				$DO_0 = 1;			
				$DO_1 = 0;
				$DO_2 = 1;
				$DO_3 = 0;
			}
			elsif ($outputs_states == 3)
			# ESTADO 3
			{
				$DO_0 = 1;			
				$DO_1 = 0;
				$DO_2 = 1;chbr
				$DO_3 = 1;
			}
			elsif ($outputs_states == 4)
			# ESTADO 4
			{
				$DO_0 = 1;			
				$DO_1 = 0;
				$DO_2 = 1;
				$DO_3 = 0;
			}
			elsif ($outputs_states == 5)
			# ESTADO 5
			{
				$DO_0 = 1;			
				$DO_1 = 1;
				$DO_2 = 1;
				$DO_3 = 1;
			}
			if ($outputs_states == 5)
			{
				$outputs_states = 0;
			}
			else
			{
				$outputs_states = $outputs_states + 1;
			}
			
			spx_log('SWITCH_OUTPUTS > $DO_0 = '.$DO_0);
			spx_log('SWITCH_OUTPUTS > $DO_1 = '.$DO_1);
			spx_log('SWITCH_OUTPUTS > $DO_2 = '.$DO_2);
			spx_log('SWITCH_OUTPUTS > $DO_3 = '.$DO_3);
		}
		
	}




	################## DETECTA FECHA Y HORA DEL SISTEMA ####################
	sub fecha_system
	# GUARDA EN LA VARIABLE $CURR_FECHA_SYSTEM LA FECHA Y HORA DEL SISTEMA
	{
		my $ANO=`date +%Y`;
		$ANO=~s/\n//g;
		my $MES=`date +%m`;
		$MES=~s/\n//g;
		my $DIA=`date +%d`;
		$DIA=~s/\n//g;
		my $HORA=`date +%H`;
		$HORA=~s/\n//g;
		my $MINUTOS=`date +%M`;
		$MINUTOS=~s/\n//g;
		my $SEGUNDOS=`date +%S`;
		$SEGUNDOS=~s/\n//g;
		#~ spx_log ('Mi año =>' .$ANO);
		#~ spx_log ('Mi mes =>' .$MES);
		#~ spx_log ('Mi dìa =>' ."$DIA");
		#~ spx_log ('Mis hora =>' .$HORA);
		#~ spx_log ('Mis minutuos =>' .$MINUTOS);
		#~ spx_log ('Mis segundos =>' .$SEGUNDOS);
		
		$CURR_FECHA_SYSTEM = $DIA.'/'.$MES.'/'.$ANO.' '.$HORA.':'.$MINUTOS.':'.	$SEGUNDOS;
		$CURR_FECHA_SHORT = $ANO.$MES.$DIA;
		#~ spx_log ('CURR_FECHA_SYSTEM =>' .$CURR_FECHA_SYSTEM);
		#~ spx_log ('CURR_FECHA_SHORT =>' .$CURR_FECHA_SHORT);
		#~ spx_log ('NUMERO_EJECUCION =>' .$NUMERO_EJECUCION);
	}

	############ DETECTA EVENTOS IMPORTANTES PARA EL SISTEMA ###############
	sub event_detection
	{	
		if ($return_tx eq 'OK')
		{
			if ($EVENT_DETECTION eq 'SI')	
			{
				my $ERROR_SENSOR_PERF;
				# DESCRIPTION: 
				##
				#
				#
				# READ_BD
				## LEEMOS LOS LA VARIABLE $ERROR_SENSOR_PERF SI EL EQUIPO TESTEADO ES UNA PERFORACION
				if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
				{
					my $EXISTS = $redis->hexists("$DLGID", "ERROR_SENSOR_PERF");	
					if ($EXISTS == 0)
					#SI NO EXISTE LO CREO CON VALOR "NO"
					{
						# NO HAGO NADA
					}
					else 
					#LEO EL PARAMETRO
					{
						$ERROR_SENSOR_PERF = $redis->hget("$DLGID", "ERROR_SENSOR_PERF");
					}
				}
				
				#~ ## LEEMOS LA VARIABLE $ERR_SENSOR_TQ SI EL EQUIPO TESTEADO ES UN TANQUE O UNA PERFORACION CON TANQUE
				#~ if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
				#~ {
					#~ my $EXISTS = $redis->hexists("$DLGID", "ERR_SENSOR_TQ");	#
					#~ if ($EXISTS == 0)
					#~ #SI NO EXISTE LO CREO CON VALOR "NO"
					#~ {
						#~ # NO HAGO NADA
					#~ }
					#~ else 
					#~ #LEO EL PARAMETRO
					#~ {
						#~ $ERR_SENSOR_TQ = $redis->hget("$DLGID", "ERR_SENSOR_TQ");
					#~ }
				#~ }
					#
					#
				#VARIABLES DE ENTRADA
				##
					spx_log('DETECCION DE EVENTOS < $TYPE = '.$TYPE);
					spx_log('DETECCION DE EVENTOS < $DLGID = '.$DLGID);
					spx_log('DETECCION DE EVENTOS < $GA = '.$GA);
					spx_log('DETECCION DE EVENTOS < $LM = '.$LM);
					spx_log('DETECCION DE EVENTOS < $FE = '.$FE);
					spx_log('DETECCION DE EVENTOS < $FT = '.$FT);
					if (defined $ERROR_SENSOR_PERF)
					{
					spx_log('DETECCION DE EVENTOS < $ERROR_SENSOR_PERF = '.$ERROR_SENSOR_PERF);
					}
					if (defined $ERR_SENSOR_TQ)
					{
					spx_log('DETECCION DE EVENTOS < $ERR_SENSOR_TQ = '.$ERR_SENSOR_TQ);
					}
					#
				if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
				{	
					
						# DETECTO CUANDO SE ABRE LA PUERTA DEL GABINETE
						if ( $GA == 1 )
						{
							spx_log('DETECCION DE EVENTOS => PUERTA DEL GABINETE ABIERTA');
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <EVENT_DETECTION> PUERTA DEL GABINETE ABIERTA.\n";
						}
						#
						# DETECTO CUANDO PASARON A MODO LOCAL
						if ( $LM == 1 )
						{
							spx_log('DETECCION DE EVENTOS => TRABAJO EN MODO LOCAL');
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <EVENT_DETECTION> TRABAJO EN MODO LOCAL.\n";
						}
						#
						# DETECTO CUANDO HAY FALLA ELECTRICA
						if ( $FE == 1 )
						{
							spx_log('DETECCION DE EVENTOS => FALLA ELECTRICA');
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <EVENT_DETECTION> FALLA ELECTRICA.\n";
						}
						#
						# DETECTO CUANDO HAY FALLA TERMICA 1
						if ( $FT == 1 )
						{
							spx_log('DETECCION DE EVENTOS => FALLA TERMICA 1');
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <EVENT_DETECTION> FALLA TERMICA 1.\n";
						}
						#
						if (defined $ERROR_SENSOR_PERF)
						{
							# DETECTO ERROR EN EL SENSOR DE LA PERFORACION
							if ( $ERROR_SENSOR_PERF eq 'SI' )
							{
								spx_log('DETECCION DE EVENTOS => ERROR EN EL SENSOR DE LA PERFORACION');
								print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <EVENT_DETECTION> ERROR EN EL SENSOR DE LA PERFORACION.\n";
							}
						}
						
						
					
				}
				if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
				{
					if (defined $ERR_SENSOR_TQ)
					{
						# DETECTO ERROR EN EL SENSOR DE LA PERFORACION
						if ( $ERR_SENSOR_TQ eq 'SI' )
						{
							spx_log('DETECCION DE EVENTOS => ERROR EN EL SENSOR DEL TANQUE');
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <EVENT_DETECTION> ERROR EN EL SENSOR DEL TANQUE.\n";
						}
					}
					else
					{
						spx_log('DETECCION DE EVENTOS => NO SE DETECTARON EVENTOS');
					}
				}
			}
		}
	}


	##################### TESTEO DE TRANSMISION ############################
	sub test_tx
	{	
		
		my $count_error_tx;					# CONTADOR DE LOS ERRORES CONTINUOS DE TX
		my $flag_tdial;						# BANDERA QUE DICE COMO ESTA EL TIMER DIAL
		my $line;							# LINE ACTUAL DEL DATALOGGER
		my $last_line;						# LINE ANTERIOR QUE TRANSMITIO EL DATALOGGER
		
		spx_log("TEST_TX_ERRORS");
		#
		#
		# DEPENDENCIAS
		## DE LAS RESPUESTAS DE ESTA FUNCION DEPENDEN LAS SIGUIENTES FUNCIONES
			# test_source
			# test_emergency_system
			# alarm_levels
		#
		#
		# DESCRIPTION: 
		##  ESTA FUNCION SE ENCARGA DE TESTEAR LA TRANSMISION DE LOS EQUIPOS
		## CUANDO UN EXIPO LLEVA MAS DE 1 MIN SIN TRANSMITIR LA VARIABLE 
		## return_tx ES CARGADA CON VALOR FAIL. CUANDO EL EQUIPO LLEVA MAS
		## 18 MINUTOS SIN TRANSMITIR SE CARGA LA VARIABLE TX_ERROR CON EL 
		## VALOR SI. CUANDO LA TRANSMISION ES NORMAL AMBAS VARIABLES TIENEN 
		## LOS VALORES 'OK' Y 'NO' RESPECTIVAMENTE.
		#
		#
		# READ_BD
		#
		## LEO EL PARAMETRO flag_tdial Y SI NO EXISTE LE ASIGNO 0
			$flag_tdial = hget($DLGID,'flag_tdial','TEST_TX',0);
			#
		## LEO EL LINE DEL DAGTALOGGER	
			$line = $redis->hget($DLGID, 'LINE');
			#	
		
		## LEO EL PARAMETRO $last_line
			### LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "last_line");
			if ($EXISTS == 0)
			# SI NO EXISTE LE ASIGNO EL DATO ACTUAL DEL DATALOGGER
			{
				$last_line = $line;
			}
			else 
			# LEO EL PARAMETRO
			{
				$last_line = $redis->hget("ERROR_PERF_TEST_$DLGID", 'last_line');
			}	
			
		## LEO EL PARAMETRO $last_fecha_data
			### LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "last_fecha_data");
			if ($EXISTS == 0)
			# SI NO EXISTE LE ASIGNO EL DATO ACTUAL DEL DATALOGGER
			{
				$last_fecha_data = $FECHA_DATA;
			}
			else 
			# LEO EL PARAMETRO
			{
				$last_fecha_data = $redis->hget("ERROR_PERF_TEST_$DLGID", 'last_fecha_data');
			}
			
		## LEO EL PARAMETRO $last_hora_data
			### LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "last_hora_data");
			if ($EXISTS =ERROR= 0)
			# SI NO EXISTE LE ASIGNO EL DATO ACTUAL DEL DATALOGGER
			{
				$last_hora_data = $last_hora_data;
			}
			else 
			# LEO EL PARAMETRO
			{
				$last_hora_data = $redis->hget("ERROR_PERF_TEST_$DLGID", 'last_hora_data');
			}
			
			#
		## LEO EL PARAMETRO $count_error_tx
			### LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "count_error_tx");
			if ($EXISTS == 0)
			# SI NO EXISTE LO DEJO INDEFINIDO
			{
				# INDEFINO CUALQUIER INSTANCIA ANTERIOR DE LA VARIABLE POR SI SE EJECUTA EN UN CICLO FOR
				undef $count_error_tx;
			}
			else 
			# LEO EL PARAMETRO
			{
				$count_error_tx = $redis->hget("ERROR_PERF_TEST_$DLGID", 'count_error_tx');
			}
			#
			#
			
		
			
		#VARIABLES DE ENTRADA
		##
		spx_log('TEST_TX_ERRORS < $DLGID = '.$DLGID);
		spx_log('TEST_TX_ERRORS < $TYPE = '.$TYPE);
		spx_log('TEST_TX_ERRORS < $last_fecha_data = '.$last_fecha_data);
		spx_log('TEST_TX_ERRORS < $last_hora_data = '.$last_hora_data);
		spx_log('TEST_TX_ERRORS < $FECHA_DATA = '.$FECHA_DATA);
		spx_log('TEST_TX_ERRORS < $HORA_DATA = '.$HORA_DATA);
		spx_log('TEST_TX_ERRORS < $BAT = '.$BAT);
		spx_log('TEST_TX_ERRORS < $CURR_FECHA_SYSTEM = '.$CURR_FECHA_SYSTEM);
		spx_log('TEST_TX_ERRORS < $flag_tdial = '.$flag_tdial);
		if (defined $count_error_tx)
		{
		spx_log('TEST_TX_ERRORS > $count_error_tx = '.$count_error_tx);
		}
			#
			#
		#MAIN	
		#
		#SE DETECTA SI SE DETUVO LA TX MAS DE 1 MIN
		#if  (($last_fecha_data == $FECHA_DATA) and ($last_hora_data == $HORA_DATA))
			
		# SI LOS LINES SON IGUALES HAY UN ERROR DE TX
		if  ($last_line eq $line)
		{
			spx_log("TEST_TX_ERRORS => TX STOPPED");
				#
				#
			# ESCRIBO EL ERROR EN EL TXT
			if ($TYPE eq 'TQ')
			{
				# DIGO QUE LA TX ES CORRECTA Y PARA NO INHABILITAR LA ALARMA DE NIVEL DE LOS TANQUES
					$return_tx = 'OK';
			}
			else
			{
				#
				# RETORNO QUE HUBO UN ERROR DE TX
					$error_ES_count = 0;
					$return_tx = 'FAIL';
			}
				#
				#
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
			{
				# CHEQUEO SI ANTERIORMENTE HUBO ERROR TX CONSECUTIVO
				if (defined $count_error_tx)
				{
					# CHEQUEO SI HA HABIDO ERROR DE TRANSMISION POR 10 MINUTOS CONSECUTIVOS
					if ($count_error_tx >= 10)		#10
					{
						# IMPRIMO QUE EL EQUIPO LLEVA MAS DE 15 MIN CAIDO
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <MAS DE 10 MIN CAIDO> (BAT = $BAT).\n";
							#
						# RETORNO QUE HUBO UN ERROR DE TX
							$error_ES_count = 0;
							$return_tx = 'FAIL';
							#
						# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
							$TX_ERROR = 'SI';
							#
					}
					else
					{
						# INCREMENTO EL CONTADOR
							$count_error_tx = $count_error_tx + 1;
							#
						# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
							$TX_ERROR = 'NO';
							#
						# IMPRIMO QUE SE ACTIVO EL ERROR TX
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_TX> (BAT = $BAT).\n";
						
							spx_log('TEST_TX_ERRORS => INCREMENTO CONTADOR : '.$count_error_tx);
					}
				}
				else
				{
					# DEFINO EL CONTADOR Y LO INCREMENTO MANUALMENTE DE 0 A 1
						$count_error_tx = 1;
						#
					# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
						$TX_ERROR = 'NO';
						#
					# IMPRIMO QUE SE ACTIVO EL ERROR TX
						print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_TX> (BAT = $BAT).\n";
						#
				}
			}
			elsif ($TYPE eq 'TQ')
			{
				# CHEQUEO SI ANTERIORMENTE HUBO ERROR TX CONSECUTIVO
				if (defined $count_error_tx)
				{
					# CHEQUEO SI HA HABIDO ERROR DE TRANSMISION POR 10 MINUTOS CONSECUTIVOS
					if ($count_error_tx >= 18)
					{
						# IMPRIMO QUE EL EQUIPO LLEVA MAS DE 15 MIN CAIDO
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <MAS DE 18 MIN CAIDO> (BAT = $BAT).\n";
							#
						# RETORNO QUE HUBO UN ERROR DE TX
							$error_ES_count = 0;
							$return_tx = 'FAIL';
							#
						# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
							$TX_ERROR = 'SI';
							#
					}
					else
					{
						# INCREMENTO EL CONTADOR
							$count_error_tx = $count_error_tx + 1;
							#
						# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
							$TX_ERROR = 'NO';
							#
						# IMPRIMO QUE SE ACTIVO EL ERROR TX SI NO SE ESTA TRABAJANDO EN DISCRETO
						if ($flag_tdial == 0)
						{
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_TX> (BAT = $BAT).\n";
						}
						
							spx_log('TEST_TX_ERRORS => INCREMENTO CONTADOR : '.$count_error_tx);
					}
				}
				else
				{
					# DEFINO EL CONTADOR Y LO INCREMENTO MANUALMENTE DE 0 A 1
						$count_error_tx = 1;
						#
					# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
						$TX_ERROR = 'NO';
						#
					# IMPRIMO QUE SE ACTIVO EL ERROR TX SI NO SE ESTA TRABAJANDO EN DISCRETO
						if ($flag_tdial == 0)
						{
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_TX> (BAT = $BAT).\n";
						}
				}
			}
			elsif ($TYPE eq 'OTHER')
			{
				## LEO EL PARAMETRO TPOLL DE LA MySQL PARA ESTABLECER EL TOPE DE 
					my $tpoll = read_PARAM($DLGID,'GENERAL','TPOLL');
					my $count_limit = ($tpoll)/60;
					
				## VEO SI EL EQUIPO ESTA TRABAJANDO EN CONTINUO
					if ($count_limit < 1)
					# Solo muestro el log de error ERROR_TX
					{
					# IMPRIMO QUE SE ACTIVO EL ERROR TX
						print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_TX> (BAT = $BAT).\n";
					}
					# Veo si paso un tiempo mayor a tpoll para dar que hubo error tx
					else
					{
						# CHEQUEO SI ANTERIORMENTE HUBO ERROR TX CONSECUTIVO
						if (defined $count_error_tx)
						{
							# CHEQUEO SI HA HABIDO ERROR DE TRANSMISION POR 10 MINUTOS CONSECUTIVOS
							if ($count_error_tx >= $count_limit)
							{
								# IMPRIMO QUE EL EQUIPO LLEVA MAS DE 15 MIN CAIDO
									print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <MAS DE $count_limit MIN CAIDO> (BAT = $BAT).\n";
									#
								# RETORNO QUE HUBO UN ERROR DE TX
									$error_ES_count = 0;
									$return_tx = 'FAIL';
									#
								# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
									$TX_ERROR = 'SI';
									#
							}
							else
							{
								# INCREMENTO EL CONTADOR
									$count_error_tx = $count_error_tx + 1;
									#
								# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
									$TX_ERROR = 'NO';
									#
									spx_log('TEST_TX_ERRORS => INCREMENTO CONTADOR : '.$count_error_tx);
							}
						}
						else
						{
							# DEFINO EL CONTADOR Y LO INCREMENTO MANUALMENTE DE 0 A 1
								$count_error_tx = 1;
								#
							# ESCRIBO LA VARIABLE QUE SE VA A USAR EN EL SCRIPT DE LAS PERFORACIONES
								$TX_ERROR = 'NO';
								#
						}
					}
					#
			}
		}
		else 
		{
			spx_log("TEST_TX_ERRORS => TX OK");
			#
			# CHEQUEO ERROR EN EL RTC
			if (($last_fecha_data == $FECHA_DATA) and ($last_hora_data == $HORA_DATA))
			{
				spx_log("TEST_TX_ERRORS => RCT ERROR");
				print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <RTC ERROR> (BAT = $BAT).\n";
			}
			else
			{
				spx_log("TEST_TX_ERRORS => RCT OK");
			}
			
			# RESETEO EL CONTADO DE ERRORES CONTINUOS DE TX
				undef $count_error_tx;
			#
			# ESCRIBO LAS VARIABLES QUE SE VAN A USAR EN EL SCRIPT QUE ATIENDE LAS PERFORACIONES
				$TX_ERROR = 'NO';
			#
			# RETORNO QUE LA TRASMISION ESTUVO CORRECTA
				$return_tx = 'OK';
		}
			#
			#
		# VARIABLES DE SALIDA
		##
		spx_log('TEST_TX_ERRORS > $TX_ERROR = '.$TX_ERROR);
		if (defined $count_error_tx)
		{
			spx_log('TEST_TX_ERRORS > $count_error_tx = '.$count_error_tx);
		}
			spx_log('TEST_TX_ERRORS > $return_tx = '.$return_tx);
			#
			#
		# WRITE_BD 
		## CONTADOR DE ERRORES CONSECUTIVOS DE TX
			# COMPRUEBO SI HAY VALORES PARA ESCRIBIR
			if (defined $count_error_tx)
			{
				$redis->hset("ERROR_PERF_TEST_$DLGID", "count_error_tx", $count_error_tx);
			}
			else
			{
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "count_error_tx");
				if ($EXISTS == 0)
				#SI NO EXISTE NO HAGO NADA
				{
					# NO HAGO NADA
				}
				else 
				#SI EXISTE LO ELIMINO
				{
					spx_log('TEST_TX_ERRORS => ELIMINO EL CONTADOR');
					$redis->hdel("ERROR_PERF_TEST_$DLGID", "count_error_tx");
				}
			}
			#
		## ESCRIBIR $last_fecha_data Y $last_hora_data
			$redis-> hset("ERROR_PERF_TEST_$DLGID",'last_fecha_data', $FECHA_DATA);
			$redis-> hset("ERROR_PERF_TEST_$DLGID",'last_hora_data', $HORA_DATA);
			#
		## ESCRITURA DEL LINE ACTUAL COMO last_line
			$redis-> hset("ERROR_PERF_TEST_$DLGID",'last_line', $line);
			
		###ESCRIBIR EL INDICADOR DE ERROR DE TX EN LA PERFORACION
			$redis->hset( "$DLGID", TX_ERROR => "$TX_ERROR" );
	}

	##################### TESTEO DE SALIDAS #############################
	sub test_outputs
	{	
		## CHEQUEO SI ESTA SELECIONADA LA OPCION DE TESTEAR LAS SALIDAS
		if ($TEST_OUTPUTS eq 'SI')
		{
			#spx_log("TEST_OUTPUTS => ENABLE");
			
		# DESCRIPTION: 
		##
			#
			#
		
		# MAIN
			if ($return_tx eq 'OK')
			{
				# SI EL EQUIPO QUE ESTOY TESTEANDO ES UNA PERFORACION
				if (($TYPE eq 'PERF') or ($TYPE eq 'PERF_AND_TQ'))
				{
					#spx_log('TEST OUTPUTS => EL EQUIPO TESTEADO ES UNA PERFORACION');
					
					# READ_BD
					## LECTURA DE  LA VARIABLE 
					###LEO SI EXISTE EL PARAMETRO outputs_change
						my $EXISTS = $redis->hexists("$DLGID", "outputs_change");
						if ($EXISTS == 0)
						#SI NO EXISTE LO CREO CON VALOR NO
						{
							$redis->hset("$DLGID", "outputs_change", "NO");
						}
						else 
						#LEO EL PARAMETRO
						{
							$outputs_change = $redis->hget("$DLGID", "outputs_change");
						}
					
					#VARIABLES DE ENTRADA
					##
						spx_log('TEST OUTPUTS < $DLGID = '.$DLGID);
						spx_log('TEST OUTPUTS < $FE = '.$FE);
						spx_log('TEST OUTPUTS < $FT = '.$FT);
						spx_log('TEST OUTPUTS < $LM = '.$LM);
						spx_log('TEST OUTPUTS < $BD = '.$BD);
						spx_log('TEST OUTPUTS < $BP = '.$BP);
						spx_log('TEST OUTPUTS < $TYPE = '.$TYPE);
						spx_log('TEST OUTPUTS < $outputs_change = '.$outputs_change);
						spx_log('TEST OUTPUTS < $DO_0 = '.$DO_0);
						spx_log('TEST OUTPUTS < $DO_1 = '.$DO_1);
						spx_log('TEST OUTPUTS < $DO_2 = '.$DO_2);
						spx_log('TEST OUTPUTS < $DO_3 = '.$DO_3);
						if (defined $BY)
						{
							spx_log('TEST OUTPUTS < $BY = '.$BY);
						}
						elsif (defined $TM)
						{
							spx_log('TEST OUTPUTS < $TM = '.$TM);
						}
						#
						#
					## CHEQUO SI EL FRAME QUE ESTOY LEYENDO CORRESPONDE A LA RESPUESTA A UN CAMBIO DE SALIDA
					if($outputs_change eq 'SI')
					{
						spx_log('TEST OUTPUTS => SALIDAS CAMBIADAS POR spx_process_perf');
						spx_log('TEST OUTPUTS => NO SE TESTEAN LAS SALIDAS');
						# PONGO EL outputs_change EN NO PARA CHEQUEAR EL PROXIMO FRAME
						$redis->hset("$DLGID", "outputs_change", "NO");
					}
					else
					{
						spx_log('TEST OUTPUTS => FRAME QUE CORRESPONDE A ESTIMULO ANTERIOR DE SALIDAS');
						
						## SE BUSCA ERROR EN LAS SALIDAS QUE ACTIVAN LA BOMBA DE LA PERFORACION Y LA DOSIFICADORA
						#
						# SE REVISA QUE NO HAYA FALLA ELECTRICA O ESTE EN MODO LOCAL PARA TESTEAR LAS SALIDAS
						if (($FE == 1) or ($LM == 1))
						{
							spx_log('TEST OUTPUTS => SISTEMA CON FALLA ELECTRICA O TERMICA');
							spx_log('TEST OUTPUTS => NO SE TESTEAN LAS SALIDAS');
						}
						else
						{
							spx_log('TEST OUTPUTS => SISTEMA SIN FALLA ELECTRICA O TERMICA');
							spx_log('TEST OUTPUTS => SE TESTEAN LAS SALIDAS');
							#
							# REVISO SI EL SISTEMA TOMA EL CONTROL DE LA BOMBA DOSIFICADORA
							if (defined $BD)
							{
								spx_log('TEST OUTPUTS => SISTEMA CON BOMBA DOSIFICADORA');
								# SE BUSCA ERROR CUANDO LAS SALIDAS TOMEN { DO_3 = 0 , DO_2 = 1 , DO_1 = 1 , DO_0 = 1 } Y NO TENGAN LA SIGUIENTE COMBINACION DE ENTRADAS { BD = 0 , (BP = 1 o FT = 1) }
								if (($DO_3 == 0) and ($DO_2 == 1) and ($DO_1 == 1) and ($DO_0 == 1))
								{
									# STATE 1
									if (($BD == 0) and (($BP == 1) or ($FT == 1)))
									{
										spx_log("TEST OUTPUTS => OUTPUTS OK");
										# RESETEO EL CONTADOR DE ERRORES DE E/S
										$error_ES_count = 0;
									}
									else
									{
										spx_log("TEST OUTPUTS => OUTPUTS FAIL");
											#
										# IMPRIMO EN TXT EL ERROR
											#print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => DO_3 = $DO_3, DO_2 = $DO_2, DO_1 = $DO_1, DO_0 = $DO_0 <=> BD = $BD, BP = $BP, FT = $FT).\n";
											if (defined $BY)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, BY = $BY ).\n";
											}
											elsif (defined $TM)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, TM = $TM ).\n";
											}
											else
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT).\n";
											}
											#
										# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
											reset_DLG();
											#
										# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
											$SWITCH_OUTPUTS = 'NO';
									}
								}
								#
								# SE BUSCA ERROR CUANDO LAS SALIDAS TOMEN { DO_3 = 0 , DO_2 = 1 , DO_1 = 0 , DO_0 = 1 } Y NO TENGAN LA SIGUIENTE COMBINACION DE ENTRADAS { BD = 0 , BP = 0 , FT = 0) }
								if (($DO_3 == 0) and ($DO_2 == 1) and ($DO_1 == 0) and ($DO_0 == 1))
								# STATE 2 Y 4
								{
									if (($BD == 0) and ($BP == 0) and ($FT == 0))
									{
										spx_log("TEST_OUTPUTS => OUTPUTS OK");
										# RESETEO EL CONTADOR DE ERRORES DE E/S
										$error_ES_count = 0;
									}
									else
									{
										spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
										# IMPRIMO EN TXT EL ERROR
											#print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => DO_3 = $DO_3, DO_2 = $DO_2, DO_1 = $DO_1, DO_0 = $DO_0 <=> BD = $BD, BP = $BP, FT = $FT).\n";
											if (defined $BY)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, BY = $BY ).\n";
											}
											elsif (defined $TM)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, TM = $TM ).\n";
											}
											else
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT).\n";
											}
											#
										# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
											reset_DLG();
											#
										# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
											$SWITCH_OUTPUTS = 'NO';
											#
									}
								}
								#
								# SE BUSCA ERROR CUANDO LAS SALIDAS TOMEN { DO_3 = 1 , DO_2 = 1 , DO_1 = 0 , DO_0 = 1 } Y NO TENGAN LA SIGUIENTE COMBINACION DE ENTRADAS { BD = 0 , (BP = 1 o FT = 1) }
								if (($DO_3 == 1) and ($DO_2 == 1) and ($DO_1 == 0) and ($DO_0 == 1))
								{
									# STATE 3
									if (($BD == 1) and ($BP == 0) and ($FT == 0))
									{
										spx_log("TEST_OUTPUTS => OUTPUTS OK");
										# RESETEO EL CONTADOR DE ERRORES DE E/S
										$error_ES_count = 0;
									}
									else
									{
										spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
										# IMPRIMO EN TXT EL ERROR
											#print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => DO_3 = $DO_3, DO_2 = $DO_2, DO_1 = $DO_1, DO_0 = $DO_0 <=> BD = $BD, BP = $BP, FT = $FT).\n";
											if (defined $BY)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, BY = $BY ).\n";
											}
											elsif (defined $TM)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, TM = $TM ).\n";
											}
											else
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT).\n";
											}
											#
										# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
											reset_DLG();
											#
										# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
											$SWITCH_OUTPUTS = 'NO';
											#
									}
								}
								#
								# SE BUSCA ERROR CUANDO LAS SALIDAS TOMEN { DO_3 = 1 , DO_2 = 1 , DO_1 = 1 , DO_0 = 1 } Y NO TENGAN LA SIGUIENTE COMBINACION DE ENTRADAS { BD = 1 , (BP = 1 o FT = 1) }
								if (($DO_3 == 1) and ($DO_2 == 1) and ($DO_1 == 1) and ($DO_0 == 1))
								{
								# STATE 5
									if (($BD == 1) and (($BP == 1) or ($FT == 1)))
									{
										spx_log("TEST_OUTPUTS => OUTPUTS OK");
										# RESETEO EL CONTADOR DE ERRORES DE E/S
										$error_ES_count = 0;
									}
									else
									{
										spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
										
										# IMPRIMO EN TXT EL ERROR
											if (defined $BY)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, BY = $BY ).\n";
											}
											elsif (defined $TM)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, TM = $TM ).\n";
											}
											else
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT).\n";
											}
											#
										# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
											reset_DLG();
											#
										# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
											$SWITCH_OUTPUTS = 'NO';
											#
									}
								}
								# SE BUSCA ERROR CUANDO LAS SALIDAS ESTEN EN CERO
								if (($DO_3 == 0) and ($DO_2 == 0) and ($DO_1 == 0) and ($DO_0 == 0))
								{
									if (defined $BY)
									{
										if ($BY == 1)
										{
											if (($BD == 1) and (($BP == 1) or ($FT == 1)))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, BY = $BY ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
										elsif ($BY == 0)
										{
											if (($BD == 0) and ($BP == 0) and ($FT == 0))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, BY = $BY ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
										
									}
									elsif (defined $TM)
									{
										if ($TM == 1)
										{
											if (($BD == 1) and (($BP == 1) or ($FT == 1)))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
													$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, TM = $TM ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
										elsif ($TM == 0)
										{
											if (($BD == 0) and ($BP == 0) and ($FT == 0))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_3 DO_2 DO_1 DO_0) = ($DO_3 $DO_2 $DO_1 $DO_0) <=> BD = $BD, BP = $BP, FT = $FT, TM = $TM ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
									}
									else
									{
										spx_log('TEST OUTPUTS => AUTOMATISMO SIN SISTEMA DE EMERGENCIA');
									}
								}
							}
							else
							{
								spx_log('TEST OUTPUTS => SISTEMA SIN BOMBA DOSIFICADORA');
								# SE BUSCA ERROR CUANDO LAS SALIDAS TOMEN { DO_1 = 1 , DO_0 = 1 } Y NO TENGAN LA SIGUIENTE COMBINACION DE ENTRADAS { BP = 1 o FT = 1 }
								if (($DO_1 == 1) and ($DO_0 == 1))
								{
									# STATE 1
									if (($BP == 1) or ($FT == 1))
									{
										spx_log("TEST OUTPUTS => OUTPUTS OK");
										# RESETEO EL CONTADOR DE ERRORES DE E/S
										$error_ES_count = 0;
									}
									else
									{
										spx_log("TEST OUTPUTS => OUTPUTS FAIL");
										
										# IMPRIMO EN TXT EL ERROR
											if (defined $BY)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, BY = $BY ).\n";
											}
											elsif (defined $TM)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, TM = $TM ).\n";
											}
											else
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT ).\n";
											}
											#
										# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
											reset_DLG();
											#
										# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
											$SWITCH_OUTPUTS = 'NO';
											#
									}
								}
								#
								# SE BUSCA ERROR CUANDO LAS SALIDAS TOMEN { DO_1 = 0 , DO_0 = 1 } Y NO TENGAN LA SIGUIENTE COMBINACION DE ENTRADAS { BP = 0 , FT = 0) }
								if (($DO_1 == 0) and ($DO_0 == 1))
								# STATE 2 Y 4
								{
									if (($BP == 0) and ($FT == 0))
									{
										spx_log("TEST_OUTPUTS => OUTPUTS OK");
										# RESETEO EL CONTADOR DE ERRORES DE E/S
										$error_ES_count = 0;
									}
									else
									{
										spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
										
										# IMPRIMO EN TXT EL ERROR
											if (defined $BY)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, BY = $BY ).\n";
											}
											elsif (defined $TM)
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, TM = $TM ).\n";
											}
											else
											{
												print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT ).\n";
											}
											#
										# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
											reset_DLG();
											#
										# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
											$SWITCH_OUTPUTS = 'NO';
											#
									}
								}
								#
								# SE BUSCA ERROR CUANDO LAS SALIDAS ESTEN EN CERO
								if (($DO_1 == 0) and ($DO_0 == 0))
								{
									if (defined $BY)
									{
										if ($BY == 1)
										{
											if (($BP == 1) or ($FT == 1))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, BY = $BY ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
										elsif ($BY == 0)
										{
											if (($BP == 0) and ($FT == 0))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, BY = $BY ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
										
									}
									elsif (defined $TM)
									{
										if ($TM == 1)
										{
											if (($BP == 1) or ($FT == 1))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, TM = $TM ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
										elsif ($TM == 0)
										{
											if (($BP == 0) and ($FT == 0))
											{
												spx_log("TEST_OUTPUTS => OUTPUTS OK");
												# RESETEO EL CONTADOR DE ERRORES DE E/S
												$error_ES_count = 0;
											}
											else
											{
												spx_log("TEST_OUTPUTS => OUTPUTS FAIL");
												
												# IMPRIMO EN TXT EL ERROR
													print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <ERROR_E/S> => (DO_1 DO_0) = ($DO_1 $DO_0) <=> BP = $BP, FT = $FT, TM = $TM ).\n";
													#
												# MANDO A REINICIAR EL DATALOGGER, EL MISMO NO REINICIA HASTA LLAMAR TRES VECES ESTA FUNCION
													reset_DLG();
													#
												# DESACTIVO LA ALTERNACION DE SALIDAS PARA VER SI SE RECUPERA DEL ERROR Y DE NO SER ASI REINICIAR EL DATALOGGER
													$SWITCH_OUTPUTS = 'NO';
													#
											}
										}
									}
									else
									{
										spx_log('TEST OUTPUTS => AUTOMATISMO SIN SISTEMA DE EMERGENCIA');
									}
								}
							}
						}
					}
				}
				else
				{
					spx_log('TEST OUTPUTS < $TYPE = '.$TYPE);
					spx_log('TEST OUTPUTS => EL EQUIPO TESTEADO NO ES UNA PERFORACION');
					spx_log('TEST OUTPUTS => NO SE TESTEAN LAS SALIDAS');
				}	
			}
			else
			{
				spx_log('TEST OUTPUTS < $return_tx = '.$return_tx);
				spx_log('TEST OUTPUTS => HUBO ERROR TX');
				spx_log('TEST OUTPUTS => NO SE TESTEAN LAS SALIDAS');
			}
		}
		else
		{
			spx_log('TEST OUTPUTS < $TEST_OUTPUTS = '.$TEST_OUTPUTS);
			spx_log("TEST_OUTPUTS => DISABLE");
		}
	}


####################### DETECCION DE LLAMADO ###########################
	sub call_detection
	{
		# DESCRIPTION: 
		##  Existen dos timpos de formas de llamar el spx_process_error_perf_test:
		##		1-Por un call_error_perf_test.pl.
		##		2-Por un error_perf_test_DLGID.
		##  Esta funcion se encarga de detectar cual fue el .pl que llamo al spx_process_error_perf_test.
		## Para ello usa la variable $TYPE en donde si:
		##		TYPE = CHARGE 		=>>	 	El SCRIPT fue llamado por el call_error_perf_test.pl
		##						 		  y entonces se lee la configuracion de la redis necesaria
		##						 		  para la ejecucion del spx_process_error_perf_test.pm
		##		TYPE = OTRO_CASO    =>>     EL script fue llamado por el error_perf_test_DLGID 
		##								  y entonces se cargan las variables del mismo para usarlas
		##								  en la ejecucion del spx_process_error_perf_test.pm y las mismas
		##								  se actualizan en la redis para si depues quieres llamar al .pm 
		##								  con el call_error_perf_test.pl	
		##
		## OJO ESTA FUNCION SE EJECUTA SOLO BAJO LAS CONDICIONES DE ESTE SCRIPT
		##
		##  La forma de llamar la funcion es la siguiente:
		## call_detection($TYPE);
			#
			#
		# VARIABLES DEL SISTEMA
		## VARIABLES DE ENTRADA
			$TYPE = $_[0];					# ID DATALOGGER PERFORACION 
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
			spx_log('CALL_DETECTION < $TYPE = '.$TYPE);
			#
			#
		#MAIN	
		# --------------------------------------------------------------
		## CHEQUEO SI ME ESTA LLEGUANO LA VARIABLE TYPE CON VALOR CHARGE
		if ($TYPE eq 'CHARGE')
		{
			spx_log('CALL_DETECTION => LLAMADO DEL SCRIPT CON CONFIGURACION EN REDIS');
			spx_log('CALL_DETECTION => READ CONFIG VAR');
			# LLAMO A LA FUNCION read_config_var PARA CARGAR DE LA REDIS LA CONFIGURACION NECESARIA
			read_config_var("$DLGID");
		}
		else
		{
			spx_log('CALL_DETECTION => LLAMADO DEL SCRIPT CON CONFIGURACION PRECARGADA');
			# LLAMO LA FUNCION read_var_in PARA CARGAR LAS VARIABLES PASADAS POR EL SCRIPT DE LLAMADA 
			spx_log('CALL_DETECTION => READ_VAR_IN');
			read_var_in($TYPE);
			# ACTUALIZO LOS VALORES ESCRITOS EN LA REDIS
			spx_log('CALL_DETECTION => REDIS_KEYS_GEN');
			redis_keys_gen ($DLGID);
		}
	}
	
############### GENERADOR DE VARIABLES DE LA REDIS #####################	
	sub redis_keys_gen
	{
		# DESCRIPTION: 
		##  Esta funcio se encarga de escribir en la redis las variables 
		## de configuracion que necesita el spx_process_error_perf_test.pm
		##
		## OJO ESTA FUNCION SE EJECUTA SOLO BAJO LAS CONDICIONES DE ESTE SCRIPT
		##
		##  La forma de llamar la funcion es la siguiente:
		## redis_keys_gen($DLGID);
			#
			#
		# VARIABLES DEL SISTEMA
		## VARIABLES DE ENTRADA
			$DLGID = $_[0];					# ID DATALOGGER PERFORACION 
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
			spx_log('REDIS_KEYS_GEN < $DLGID = '.$DLGID);
			#
			#
		#MAIN	
		# --------------------------------------------------------------
		## CREO EN LA REDIS TODAS LAS VARIABLES QUE VOY A UTILIZAR PARA EL SCRIPT
		#
		### VARIABLES QUE VAN EN TODOS LOS EQUIPOS
			#### ESCRIBO LOS VALORES ENTRADOS
				$redis->hset("$DLGID", 'TYPE', $TYPE);
				$redis->hset("$DLGID", 'SEND_MAIL', $SEND_MAIL);
		#
		### VARIABLES QUE VAN SOLO EN LA PERFORACION
		if ($TYPE eq 'PERF')
		{
			#### ESCRIBO LOS VALORES ENTRADOS	
				$redis->hset("$DLGID", 'PERF_NAME', $PERF_NAME);
				$redis->hset("$DLGID", 'DLGID', $DLGID_TQ);
				$redis->hset("$DLGID", 'emailAddr_perf', $emailAddr_perf);
				$redis->hset("$DLGID", 'TEST_OUTPUTS', $TEST_OUTPUTS);
		}
		### VARIABLES QUE SE ESCRIBEN CUANDO LA PERFORACION Y EL TANQUE ESTAN JUNTOS
		if ($TYPE eq 'PERF_AND_TQ')
		{
			#### ESCRIBO LOS VALORES ENTRADOS	
				$redis->hset("$DLGID", 'PERF_NAME', $PERF_NAME);
				$redis->hset("$DLGID", 'DLGID_TQ', $DLGID_TQ);
				$redis->hset("$DLGID", 'emailAddr_perf', $emailAddr_perf);
				$redis->hset("$DLGID", 'TQ_NAME', $TQ_NAME);
				$redis->hset("$DLGID", 'emailAddr_tq', $emailAddr_tq);
				$redis->hset("$DLGID", 'TEST_OUTPUTS', $TEST_OUTPUTS);
				$redis->hset("$DLGID", 'EVENT_DETECTION', $EVENT_DETECTION);
				$redis->hset("$DLGID", 'test_emergency_system', $test_emergency_system);
				$redis->hset("$DLGID", 'TEST_SOURCE', $TEST_SOURCE);
		}
		#
		### VARIABLES QUE VAN SOLO EN EL TANQUE
		if ($TYPE eq 'TQ')
		{
			#### ESCRIBO LOS VALORES ENTRADOS
				$redis->hset("$DLGID", 'TQ_NAME', $TQ_NAME);
				$redis->hset("$DLGID", 'emailAddr_tq', $emailAddr_tq);
		}
		# ------------------------------------------------------------------	
			#
			#
		# VARIABLES DE SALIDA
		##
		### VARIABLES QUE VAN EN TODOS LOS EQUIPOS
			#### MUESTRO LOS VALORES ESCRITOS
				spx_log('REDIS_KEYS_GEN > TYPE = '.$TYPE);
				spx_log('REDIS_KEYS_GEN > SEND_MAIL = '.$SEND_MAIL);
			#
		### VARIABLES QUE VAN SOLO EN LA PERFORACION
		if ($TYPE eq 'PERF')
		{
			#### MUESTRO LOS VALORES ESCRITOS
				spx_log('REDIS_KEYS_GEN > PERF_NAME = '.$PERF_NAME);
				spx_log('REDIS_KEYS_GEN > DLGID_TQ = '.$DLGID_TQ);
				spx_log('REDIS_KEYS_GEN > emailAddr_perf = '.$emailAddr_perf);
				spx_log('REDIS_KEYS_GEN > TEST_OUTPUTS = '.$TEST_OUTPUTS);
				spx_log('REDIS_KEYS_GEN > EVENT_DETECTION = '.$EVENT_DETECTION);
				spx_log('REDIS_KEYS_GEN > test_emergency_system = '.$test_emergency_system);
				spx_log('REDIS_KEYS_GEN > TEST_SOURCE = '.$TEST_SOURCE);
		}
			#
		### VARIABLES QUE SE ESCRIBEN CUANDO LA PERFORACION Y EL TANQUE ESTAN JUNTOS
		if ($TYPE eq 'PERF_AND_TQ')
		{
			#### MUESTRO LOS VALORES ESCRITOS
				spx_log('REDIS_KEYS_GEN > PERF_NAME = '.$PERF_NAME);
				spx_log('REDIS_KEYS_GEN > DLGID_TQ = '.$DLGID_TQ);
				spx_log('REDIS_KEYS_GEN > emailAddr_perf = '.$emailAddr_perf);
				spx_log('REDIS_KEYS_GEN > TQ_NAME = '.$TQ_NAME);
				spx_log('REDIS_KEYS_GEN > emailAddr_tq = '.$emailAddr_tq);
				spx_log('REDIS_KEYS_GEN > TEST_OUTPUTS = '.$TEST_OUTPUTS);
				spx_log('REDIS_KEYS_GEN > EVENT_DETECTION = '.$EVENT_DETECTION);
				spx_log('REDIS_KEYS_GEN > test_emergency_system = '.$test_emergency_system);
				spx_log('REDIS_KEYS_GEN > TEST_SOURCE = '.$TEST_SOURCE);
		}
			#
		### VARIABLES QUE VAN SOLO EN EL TANQUE
		if ($TYPE eq 'TQ')
		{
			#### MUESTRO LOS VALORES ESCRITOS
				spx_log('REDIS_KEYS_GEN > TQ_NAME = '.$TQ_NAME);
				spx_log('REDIS_KEYS_GEN > emailAddr_tq = '.$emailAddr_tq);
		}
	}
	
	
################ LECTURA DE VARIABLES PRECARGADAS ######################
	sub read_var_in
	{
		# DESCRIPTION: 
		##  Esta funcion simplemente deja al spx_process_error_perf_test.pm
		## trabajando con las variables que inicialmente el habia cargado,
		## NO LAS MODIFICA. Tambien muestra el estado de estas variables
		##
		## OJO ESTA FUNCION SE EJECUTA SOLO BAJO LAS CONDICIONES DE ESTE SCRIPT
		##
		##  La forma de llamar la funcion es la siguiente:
		## read_var_in($TYPE);
			#
			#
		# VARIABLES DEL SISTEMA
		## VARIABLES DE ENTRADA
			$TYPE = $_[0];					# ID DATALOGGER PERFORACION 
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
			spx_log('READ_VAR_IN < $TYPE = '.$TYPE);	
			#
			#
	#MAIN	
	# ------------------------------------------------------------------
		# MANTENGO LA CONFIGURACION CARGADA POR LAS VARIABLES AL INCIO DEL PROGRAMA
	# ------------------------------------------------------------------	
			#
			#
		# VARIABLES DE SALIDA
		##
		# MUESTRAS LAS VARIABLES DE CONFIGURACION	
			spx_log('READ_VAR_IN > $print_log = '.$print_log);
			spx_log('READ_VAR_IN > $DLGID = '.$DLGID);
			spx_log('READ_VAR_IN > $SWITCH_OUTPUTS = '.$SWITCH_OUTPUTS);
			spx_log('READ_VAR_IN > $TEST_OUTPUTS = '.$TEST_OUTPUTS);
			spx_log('READ_VAR_IN > $TYPE = '.$TYPE);
			spx_log('READ_VAR_IN > $EVENT_DETECTION = '.$EVENT_DETECTION);
			spx_log('READ_VAR_IN > $test_emergency_system = '.$test_emergency_system);
			spx_log('READ_VAR_IN > $TEST_SOURCE = '.$TEST_SOURCE);
			spx_log('READ_VAR_IN > $SEND_MAIL = '.$SEND_MAIL);
		if ($TYPE eq 'PERF')
		{
			spx_log('READ_VAR_IN > $PERF_NAME = '.$PERF_NAME);
			spx_log('READ_VAR_IN > $DLGID_TQ = '.$DLGID_TQ);
			spx_log('READ_VAR_IN > $emailAddr_perf = '.$emailAddr_perf);
		}
		if ($TYPE eq 'PERF_AND_TQ')
		{
			spx_log('READ_VAR_IN > $PERF_NAME = '.$PERF_NAME);
			spx_log('READ_VAR_IN > $DLGID_TQ = '.$DLGID_TQ);
			spx_log('READ_VAR_IN > $emailAddr_perf = '.$emailAddr_perf);
			spx_log('READ_VAR_IN > $TQ_NAME = '.$TQ_NAME);
			spx_log('READ_VAR_IN > $emailAddr_tq = '.$emailAddr_tq);
		}
		if ($TYPE eq 'TQ')
		{
			spx_log('READ_VAR_IN > $TQ_NAME = '.$TQ_NAME);
			spx_log('READ_VAR_IN > $emailAddr_tq = '.$emailAddr_tq);
		}
	}	
	
################# LEER VARIABLES DE CONFIGURACION ######################
	sub read_config_var
	{
		# DESCRIPTION: 
		##  Esta funcion se encarga de cargar de la REDIS las variables de configuracion que 
		## va a necesitar el script para que funcione correctamente. 
		##
		## OJO ESTA FUNCION SE EJECUTA SOLO BAJO LAS CONDICIONES DE ESTE SCRIPT
		##
		##  La forma de llamar la funcion es la siguiente:
		## read_config_var(KEY);
		## donde:
		## ENTRADA
		## -KEY			=>		{ DLGID }
		##						Es la KEY de la redis en donde van a estar guardadas
		##						todas la variables de configuracion, incluyendo la 
		##						variable TYPE que para este caso es la que decide las 
		##						variables de configuracion que se necesitan
		##
		## EJEMPLO REAL DE LLAMADO
		## read_config_var($DLGID);
			#
			#
		# VARIABLES DEL SISTEMA
		## VARIABLES DE ENTRADA
			$DLGID = $_[0];					# ID DATALOGGER PERFORACION 
			#
			#
		# READ_BD
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
			spx_log('READ_CONFIG_VAR < $DLGID = '.$DLGID);
			#
			#
		#MAIN	
		# ------------------------------------------------------------------
		##
		# LEO LAS VARIABLES DE ENTRADA DE CONFIGURACION 
			##LEO EL PARAMETRO TYPE
				###LEO SI EXISTE EL PARAMETRO
				
				my $EXISTS = $redis->hexists("$DLGID", "TYPE");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TYPE');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$TYPE = $redis->hget("$DLGID", "TYPE");
				}
			##LEO EL PARAMETRO SEND_MAIL
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "SEND_MAIL");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE SEND_MAIL');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$SEND_MAIL = $redis->hget("$DLGID", "SEND_MAIL");
				}
				#
				#
				#
	# LEO LAS VARIABLES DE CONFIGURACION SEGUN EL TIPO DE EQUIPO TESTEADO
		## CASO DE QUE EL EQUIPO TESTADO SEA UNA PERFORACION
		if ($TYPE eq 'PERF')
		{
			##LEO EL PARAMETRO PERF_NAME
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "PERF_NAME");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE PERF_NAME');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$PERF_NAME = $redis->hget("$DLGID", "PERF_NAME");
				}
				#
			##LEO EL PARAMETRO DLGID_TQ
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "DLGID_TQ");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE DLGID_TQ');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$DLGID_TQ = $redis->hget("$DLGID", "DLGID_TQ");
				}
				#
			##LEO EL PARAMETRO emailAddr_perf
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "emailAddr_perf");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE emailAddr_perf');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$emailAddr_perf = $redis->hget("$DLGID", "emailAddr_perf");
				}
				#
			
			##LEO EL PARAMETRO TEST_OUTPUTS
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "TEST_OUTPUTS");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TEST_OUTPUTS');
					$TEST_OUTPUTS = 'SI';
					spx_log("READ_CONFIG_VAR => CREO TEST_OUTPUTS = $TEST_OUTPUTS");
					$redis->hset("$DLGID", 'TEST_OUTPUTS', $TEST_OUTPUTS);
				}
				else 
				#LEO EL PARAMETRO
				{
					$TEST_OUTPUTS = $redis->hget("$DLGID", "TEST_OUTPUTS");
				}
				#
			##LEO EL PARAMETRO EVENT_DETECTION
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "EVENT_DETECTION");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE EVENT_DETECTION');
					$EVENT_DETECTION = 'SI';
					spx_log("READ_CONFIG_VAR => CREO EVENT_DETECTION = $EVENT_DETECTION");
					$redis->hset("$DLGID", 'EVENT_DETECTION', $EVENT_DETECTION);
				}
				else 
				#LEO EL PARAMETRO
				{
					$EVENT_DETECTION = $redis->hget("$DLGID", "EVENT_DETECTION");
				}
				#	
			##LEO EL PARAMETRO test_emergency_system
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "test_emergency_system");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE test_emergency_system');
					$test_emergency_system = 'SI';
					spx_log("READ_CONFIG_VAR => CREO test_emergency_system = $test_emergency_system");
					$redis->hset("$DLGID", 'test_emergency_system', $test_emergency_system);
				}
				else 
				#LEO EL PARAMETRO
				{
					$test_emergency_system = $redis->hget("$DLGID", "test_emergency_system");
				}
				#	
			##LEO EL PARAMETRO TEST_SOURCE
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "TEST_SOURCE");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TEST_SOURCE');
					$TEST_SOURCE = 'SI';
					spx_log("READ_CONFIG_VAR => CREO TEST_SOURCE = $TEST_SOURCE");
					$redis->hset("$DLGID", 'TEST_SOURCE', $TEST_SOURCE);
				}
				else 
				#LEO EL PARAMETRO
				{
					$TEST_SOURCE = $redis->hget("$DLGID", "TEST_SOURCE");
				}
				#
				
		}
		## CASO DE QUE EL EQUIPO TESTADO SEA UNA PERFORACION CON TANQUE
		if ($TYPE eq 'PERF_AND_TQ')
		{
			##LEO EL PARAMETRO PERF_NAME
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "PERF_NAME");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE PERF_NAME');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$PERF_NAME = $redis->hget("$DLGID", "PERF_NAME");
				}
				#
			##LEO EL PARAMETRO DLGID_TQ
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "DLGID_TQ");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE DLGID_TQ');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$DLGID_TQ = $redis->hget("$DLGID", "DLGID_TQ");
				}
				#
			##LEO EL PARAMETRO emailAddr_perf
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "emailAddr_perf");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE emailAddr_perf');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$emailAddr_perf = $redis->hget("$DLGID", "emailAddr_perf");
				}
				#
			##LEO EL PARAMETRO TQ_NAME
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "TQ_NAME");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TQ_NAME');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$TQ_NAME = $redis->hget("$DLGID", "TQ_NAME");
				}
				#
			##LEO EL PARAMETRO emailAddr_tq
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "emailAddr_tq");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE emailAddr_tq');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit
				}
				else 
				#LEO EL PARAMETRO
				{
					$emailAddr_tq = $redis->hget("$DLGID", "emailAddr_tq");
				}
				#
			##LEO EL PARAMETRO TEST_OUTPUTS
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "TEST_OUTPUTS");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TEST_OUTPUTS');
					$TEST_OUTPUTS = 'SI';
					spx_log("READ_CONFIG_VAR => CREO TEST_OUTPUTS = $TEST_OUTPUTS");
					$redis->hset("$DLGID", 'TEST_OUTPUTS', $TEST_OUTPUTS);
				}
				else 
				#LEO EL PARAMETRO
				{
					$TEST_OUTPUTS = $redis->hget("$DLGID", "TEST_OUTPUTS");
				}
				#
			##LEO EL PARAMETRO EVENT_DETECTION
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "EVENT_DETECTION");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE EVENT_DETECTION');
					$EVENT_DETECTION = 'SI';
					spx_log("READ_CONFIG_VAR => CREO EVENT_DETECTION = $EVENT_DETECTION");
					$redis->hset("$DLGID", 'EVENT_DETECTION', $EVENT_DETECTION);
				}
				else 
				#LEO EL PARAMETRO
				{
					$EVENT_DETECTION = $redis->hget("$DLGID", "EVENT_DETECTION");
				}
				#	
			##LEO EL PARAMETRO test_emergency_system
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "test_emergency_system");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE test_emergency_system');
					$test_emergency_system = 'SI';
					spx_log("READ_CONFIG_VAR => CREO test_emergency_system = $test_emergency_system");
					$redis->hset("$DLGID", 'test_emergency_system', $test_emergency_system);
				}
				else 
				#LEO EL PARAMETRO
				{
					$test_emergency_system = $redis->hget("$DLGID", "test_emergency_system");
				}
				#	
			##LEO EL PARAMETRO TEST_SOURCE
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "TEST_SOURCE");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TEST_SOURCE');
					$TEST_SOURCE = 'SI';
					spx_log("READ_CONFIG_VAR => CREO TEST_SOURCE = $TEST_SOURCE");
					$redis->hset("$DLGID", 'TEST_SOURCE', $TEST_SOURCE);
				}
				else 
				#LEO EL PARAMETRO
				{
					$TEST_SOURCE = $redis->hget("$DLGID", "TEST_SOURCE");
				}
				#
		}
		if ($TYPE eq 'TQ')
		{	
			##LEO EL PARAMETRO TQ_NAME
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "TQ_NAME");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE TQ_NAME');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
				else 
				#LEO EL PARAMETRO
				{
					$TQ_NAME = $redis->hget("$DLGID", "TQ_NAME");
				}
				#
			
			##LEO EL PARAMETRO emailAddr_tq
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "emailAddr_tq");
				if ($EXISTS == 0)
				#SI NO EXISTE INDICO PARA QUE SE CARGUE
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE emailAddr_tq');
					#
					#
					spx_log('READ_CONFIG_VAR => NO SE EJECUTA EL SCRIPT');
					goto quit
				}
				else 
				#LEO EL PARAMETRO
				{
					$emailAddr_tq = $redis->hget("$DLGID", "emailAddr_tq");
				}
				#
		}	
		# ------------------------------------------------------------------	
			#
			#
		# VARIABLES DE SALIDA
		##
		# MUESTRAS LAS VARIABLES DE CONFIGURACION	
			spx_log('READ_CONFIG_VAR > $print_log = '.$print_log);
			spx_log('READ_CONFIG_VAR > $DLGID = '.$DLGID);
			spx_log('READ_CONFIG_VAR > $SWITCH_OUTPUTS = '.$SWITCH_OUTPUTS);
			spx_log('READ_CONFIG_VAR > $TEST_OUTPUTS = '.$TEST_OUTPUTS);
			spx_log('READ_CONFIG_VAR > $TYPE = '.$TYPE);
			spx_log('READ_CONFIG_VAR > $EVENT_DETECTION = '.$EVENT_DETECTION);
			spx_log('READ_CONFIG_VAR > $test_emergency_system = '.$test_emergency_system);
			spx_log('READ_CONFIG_VAR > $TEST_SOURCE = '.$TEST_SOURCE);
			spx_log('READ_CONFIG_VAR > $SEND_MAIL = '.$SEND_MAIL);
		if ($TYPE eq 'PERF')
		{
			spx_log('READ_CONFIG_VAR > $PERF_NAME = '.$PERF_NAME);
			spx_log('READ_CONFIG_VAR > $DLGID_TQ = '.$DLGID_TQ);
			spx_log('READ_CONFIG_VAR > $emailAddr_perf = '.$emailAddr_perf);
		}
		if ($TYPE eq 'PERF_AND_TQ')
		{
			spx_log('READ_CONFIG_VAR > $PERF_NAME = '.$PERF_NAME);
			spx_log('READ_CONFIG_VAR > $DLGID_TQ = '.$DLGID_TQ);
			spx_log('READ_CONFIG_VAR > $emailAddr_perf = '.$emailAddr_perf);
			spx_log('READ_CONFIG_VAR > $TQ_NAME = '.$TQ_NAME);
			spx_log('READ_CONFIG_VAR > $emailAddr_tq = '.$emailAddr_tq);
		}
		if ($TYPE eq 'TQ')
		{
			spx_log('READ_CONFIG_VAR > $TQ_NAME = '.$TQ_NAME);
			spx_log('READ_CONFIG_VAR > $emailAddr_tq = '.$emailAddr_tq);
		}
	}	






###################### LEER EN BASE REDIS ##############################
	sub read_redis
	{
		spx_log('READ_REDIS');
		#	
	# LEO PARAMETROS SOLO SI SE TRATA DE UNA PERFORACION	
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
		{		
		#
		#
		##LEO EL PARAMETRO $error_ES_count
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "error_ES_count");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR "0"
			{
				$error_ES_count = 0;	
				$redis->hset("ERROR_PERF_TEST_$DLGID", "error_ES_count", $error_ES_count);
			}
			else 
			#LEO EL PARAMETRO
			{
				$error_ES_count = $redis->hget("ERROR_PERF_TEST_$DLGID", 'error_ES_count');
			}
			
		##LEO EL PARAMETRO $outputs_states
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", "outputs_states");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR "0"
			{
				$outputs_states = 0;	
				$redis->hset("ERROR_PERF_TEST_$DLGID", "outputs_states", $outputs_states);
			}
			else 
			#LEO EL PARAMETRO
			{
				$outputs_states = $redis->hget("ERROR_PERF_TEST_$DLGID", 'outputs_states');
			}
		}
	# LEO EL VALOR DE $N_MAX_TQ
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))	
			{
				$N_MAX_TQ = $redis->hget("$DLGID_TQ", 'N_MAX_TQ');
			}
			elsif ($TYPE eq 'TQ')
			{
				$N_MAX_TQ = $redis->hget("$DLGID", 'N_MAX_TQ');
			}
		#
	# LEO EL PARAMETRO L_MIN_ALARM SI EL EQUIPO TESTEADO ES UNA PERFORACION CON TANQUE O UN TANQUE
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "L_MIN_ALARM");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON UN VALOR PREDEFINIDO
			{
				# PREDEFINO QUE L_MIN_ALARM VA A SER 1/5 DE LA ALTURA MAXIMA A LA CUAL SE PUEDE LLENAR EL TANQUE
				$L_MIN_ALARM = ($N_MAX_TQ/5);
				$redis->hset("$DLGID", "L_MIN_ALARM", "$L_MIN_ALARM");
			}
			else 
			#LEO EL PARAMETRO
			{
				$L_MIN_ALARM = $redis->hget("$DLGID", "L_MIN_ALARM");
			}
			
		}
	# LEO EL PARAMETRO L_MAX_ALARM SI EL EQUIPO TESTEADO ES UNA PERFORACION CON TANQUE O UN TANQUE
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "L_MAX_ALARM");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON UN VALOR PREDEFINIDO
			{
				# PREDEFINO QUE L_MAX_ALARM VA A SER PARA LLEGAR A LA ALTURA MAXIMA A LA CUAL SE PUEDE LLENAR EL TANQUE
				$L_MAX_ALARM = ($N_MAX_TQ-0.1);
				$redis->hset("$DLGID", "L_MIN_ALARM", "$L_MAX_ALARM");
			}
			else 
			#LEO EL PARAMETRO
			{
				$L_MAX_ALARM = $redis->hget("$DLGID", "L_MAX_ALARM");
			}
			
		}
		#
	# LEO EL PARAMETRO tq_level_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION CON TANQUE O UN TANQUE
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "tq_level_mail_alarm");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR 'NO'
			{
				$tq_level_mail_alarm = 'NO';
				$redis->hset("$DLGID", "tq_level_mail_alarm", "$tq_level_mail_alarm");
			}
			else 
			#LEO EL PARAMETRO
			{
				$tq_level_mail_alarm = $redis->hget("$DLGID", "tq_level_mail_alarm");
			}
			
		}
		
	# LEO EL PARAMETRO CL_MIN_ALARM SI EL EQUIPO TESTEADO ES UNA PERFORACION CON TANQUE O UN TANQUE
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))	
			{
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "CL_MIN_ALARM");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE CL_MIN_ALARM');
					$CL_MIN_ALARM = 0.5;
					spx_log("READ_CONFIG_VAR => CREO CL_MIN_ALARM = $CL_MIN_ALARM");
					$redis->hset("$DLGID", 'CL_MIN_ALARM', $CL_MIN_ALARM);
				}
				else 
				#LEO EL PARAMETRO
				{
					$CL_MIN_ALARM = $redis->hget("$DLGID", "CL_MIN_ALARM");
				}
			}
			#
	# LEO EL PARAMETRO CL_MAX_ALARM SI EL EQUIPO TESTEADO ES UNA PERFORACION CON TANQUE O UN TANQUE
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))	
			{
				###LEO SI EXISTE EL PARAMETRO
				my $EXISTS = $redis->hexists("$DLGID", "CL_MAX_ALARM");
				if ($EXISTS == 0)
				#SI NO EXISTE LA CREO CON UN VALOR INICIAL
				{
					spx_log('READ_CONFIG_VAR => NO EXISTE LA VARIABLE CL_MAX_ALARM');
					$CL_MAX_ALARM = 1.5;
					spx_log("READ_CONFIG_VAR => CREO CL_MAX_ALARM = $CL_MAX_ALARM");
					$redis->hset("$DLGID", 'CL_MAX_ALARM', $CL_MAX_ALARM);
				}
				else 
				#LEO EL PARAMETRO
				{
					$CL_MAX_ALARM = $redis->hget("$DLGID", "CL_MAX_ALARM");
				}
			}
			#
	# LEO EL PARAMETRO tq_count_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION CON TANQUE O UN TANQUE
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "tq_count_mail_alarm");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR '0'
			{
				$tq_count_mail_alarm = 0;
				$redis->hset("$DLGID", "tq_count_mail_alarm", "$tq_count_mail_alarm");
			}
			else 
			#LEO EL PARAMETRO
			{
				$tq_count_mail_alarm = $redis->hget("$DLGID", "tq_count_mail_alarm");
			}
			
		}
		
	# LEO EL PARAMETRO cl_low_level_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION 
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "cl_low_level_mail_alarm");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR 'NO'
			{
				$cl_low_level_mail_alarm = 'NO';
				$redis->hset("$DLGID", "cl_low_level_mail_alarm", "$cl_low_level_mail_alarm");
			}
			else 
			#LEO EL PARAMETRO
			{
				$cl_low_level_mail_alarm = $redis->hget("$DLGID", "cl_low_level_mail_alarm");
			}
			
		}
		
	# LEO EL PARAMETRO cl_low_count_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION 
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "cl_low_count_mail_alarm");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR 'NO'
			{
				$cl_low_count_mail_alarm = 0;
				$redis->hset("$DLGID", "cl_low_count_mail_alarm", "$cl_low_count_mail_alarm");
			}
			else 
			#LEO EL PARAMETRO
			{
				$cl_low_count_mail_alarm = $redis->hget("$DLGID", "cl_low_count_mail_alarm");
			}
			
		}
		
	# LEO EL PARAMETRO cl_high_level_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION 
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "cl_high_level_mail_alarm");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR 'NO'
			{
				$cl_high_level_mail_alarm = 'NO';
				$redis->hset("$DLGID", "cl_high_level_mail_alarm", "$cl_high_level_mail_alarm");
			}
			else 
			#LEO EL PARAMETRO
			{
				$cl_high_level_mail_alarm = $redis->hget("$DLGID", "cl_high_level_mail_alarm");
			}
			
		}
		
	# LEO EL PARAMETRO cl_high_count_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION 
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
		{
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID", "cl_high_count_mail_alarm");
			if ($EXISTS == 0)
			#SI NO EXISTE LO CREO CON VALOR 'NO'
			{
				$cl_high_count_mail_alarm = 0;
				$redis->hset("$DLGID", "cl_high_count_mail_alarm", "$cl_high_count_mail_alarm");
			}
			else 
			#LEO EL PARAMETRO
			{
				$cl_high_count_mail_alarm = $redis->hget("$DLGID", "cl_high_count_mail_alarm");
			}
			
		}
			
		# LEO LOS DATOS DEL DATALOGGER
			# SI EL EQUIPO TESTEADO ES UNA PERFORACION LEO EL VALOR DE LA ALTURA DEL TANQUE PARA TESTEAR EL SISTEMA DE EMERGENCIA
				# SI EL SISTEMA TESTEADO ES UNA PERFORACION SE CARGA LA ALTURA DEL TANQUE EN EL OTRO DATALOGGER
				if ($TYPE eq 'PERF')
				{
					##LECTURA DE LOS DATOS DEL DATALOGGER
					read_dlg_data("$DLGID_TQ");
					#
					# CHEQUEO QUE ME ESTE LLEGANDO EL PARAMETRO BY
					if (defined $BY)
					{
						# SI ME ESTA LLEGANDO LO INDEFINO PARA QUE NO ME INTERFIERA EN CASO DE TENER UNA PERFORACION
						#CON TIMER Y QUE LA MISMA BOMBEE AGUA PARA UN TANQUE QUE ESTE CONECTADO A OTRA PERFORACION Y ESTA TENGA BOYAS
						undef $BY;
					}
				}	
				#
				#
			# LECTURA DE LOS DATOS DEL DATALOGGER
				read_dlg_data("$DLGID");
				#
				#
			# SI EL EQUIPO TESTEADO ES UN TANQUE IGUALAMOS bt  A BAT PARA QUE NO HAYAN
				#CONFLICTOS CUANDO SE ESCRIBA ERROR TX
				if (($TYPE eq 'TQ') or ($TYPE eq 'OTHER'))
				# SI ES TANQUE ESTA EN
				{
					$BAT = $bt + $offset_bt;;
				}
				#
				#
		# LEO EL ESTADO DE LAS SALIDAS
			##LEO EL PARAMETRO DE LA REDIS Y LO CONVIERTO A BINARIO
			my $OUTPUTS_DEC = $redis->hget($DLGID,'OUTPUTS');
			#~ my $OUTPUTS_DEC =2;
			my $OUTPUTS_DEC_8bits = $OUTPUTS_DEC+256;
			#spx_log('$OUTPUTS_DEC => '.$OUTPUTS_DEC);
			my $OUTPUTS_BIN = dec2bin($OUTPUTS_DEC_8bits);
			#spx_log('$OUTPUTS_BIN => '.$OUTPUTS_BIN);
			my @OUTPUTS = split ('',$OUTPUTS_BIN );
			#spx_log	('DO_7 DO_6 DO_5 DO_4 DO_3 DO_2 DO_1 DO_0 => '. "@OUTPUTS");
			#
			#spx_log('@OUTPUTS[8] => '."$OUTPUTS[8]");
			#spx_log('@OUTPUTS[7] => '."$OUTPUTS[7]");
			#
			$DO_0 = @OUTPUTS[8];
			$DO_1 = @OUTPUTS[7];
			$DO_2 = @OUTPUTS[6];
			$DO_3 = @OUTPUTS[5];
			$DO_4 = @OUTPUTS[4];
			$DO_5 = @OUTPUTS[3];
			$DO_6 = @OUTPUTS[2];
			$DO_7 = @OUTPUTS[1];
			#
			#
			#PRINT_RESULT
			#~ spx_log ("DO_0 = $DO_0");
			#~ spx_log ("DO_1 = $DO_1");
			#~ spx_log ("DO_2 = $DO_2");
			#~ spx_log ("DO_3 = $DO_3");
			#~ spx_log ("DO_4 = $DO_4");
			#~ spx_log ("DO_5 = $DO_5");
			#~ spx_log ("DO_6 = $DO_6");
			#~ spx_log ("DO_7 = $DO_7");
			#
			#
		# LEO EL VALOR DE $ERR_SENSOR_TQ
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))	
			{
				$ERR_SENSOR_TQ = $redis->hget("$DLGID", 'ERR_SENSOR_TQ');
			}
			elsif ($TYPE eq 'PERF')
			{
				$ERR_SENSOR_TQ = $redis->hget("$DLGID_TQ", 'ERR_SENSOR_TQ');
			}
			#
		# LEO EL VALOR DE $tq_state
			$tq_state = hget($DLGID,'tq_state','READ_REDIS');
			#
		# LEO EL VALOR DE $tq_state
			$offset_bt = hget($DLGID,'offset_bt','READ_REDIS',0);
			
		
	}
	
sub pw_save
{
	#  ESTA FUNCION GARANTIZA QUE CUANDO SE ESTE DESCARGANDO LA BATERIA EL EQUIPO  
	# COMIENCE A TRABAJAR EN MODO DISCRETO. CUANDO LA BATERIA SE RECUPERA VUELE A 
	# MODO CONTINUO
		
	# DECLARACION DE VARIABLES
		my $v_low = $_[0];
		my $v_hight = $_[1];
		my $time_hight = $_[2];
		
		my $flag_tdial;
		my $count_VL;
		my $count_VH;
		my $EXISTS;
	
	# ONLY FOR TEST	
		#my $bt = 15;
		
	# ESTE OFFSET DEBERIA ESTAR CORREGIDO EN LA CALIBRACION INICIAL DEL EQUIPO
		if ($TYPE eq 'TQ')
		{
			spx_log("PW_SAVE < \$bt = $bt");
			spx_log("PW_SAVE < \$offset_bt = $offset_bt");
			my $bt = $bt + $offset_bt;
			spx_log("PW_SAVE < \$bt = $bt");
		}
			
	# VARIABLES DE ENTRADA
		spx_log("PW_SAVE < \$TYPE = $TYPE");
		spx_log("PW_SAVE < \$v_low = $v_low");
		spx_log("PW_SAVE < \$v_hight = $v_hight");
		spx_log("PW_SAVE < \$time_hight = $time_hight");
		spx_log("PW_SAVE < \$DLGID = $DLGID");
		
		
	# READ_BD
	## LEO EL PARAMETRO flag_tdial Y SI NO EXISTE LE ASIGNO 0
		$flag_tdial = hget($DLGID,'flag_tdial','PW_SAVE',0);
		#	
	## LEO EL PARAMETRO count_VL
		$count_VL = hget($DLGID,'count_VL','PW_SAVE');
		#
	## LEO EL PARAMETRO count_VL
		$count_VH = hget($DLGID,'count_VH','PW_SAVE');
		#

		
	# MAIN
	if ($TYPE eq 'TQ')
	{
		spx_log("PW_SAVE < \$bt = $bt");
		if ($bt < $v_low)
		{
			# MUESTRO LAS CONDICIONES DE ENTRADA
				spx_log("PW_SAVE => BATERIA BAJA");
				spx_log("PW_SAVE => bt < v_low");
				spx_log("PW_SAVE => $bt < $v_low");
				#
			# VEO SI ME ENCUENTRO CON TDIAL 0
				if ($flag_tdial == 0)
				{
					if ( $count_VL >= 2 )
					{
						spx_log("PW_SAVE => SE SETEA TDIAL = 900");
							#
						# SE SETEA EL TDIAL A 900
							ubdate_PARAM($DLGID,'GENERAL','TDIAL',900);
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <PW_SAVE> SE PASA EL SISTEMA A MODO DISCRETO { bt = $bt }\n";
							#
						# SE SETEA EL PWRS_MODO A 0 POR PRECAUCION
							ubdate_PARAM($DLGID,'GENERAL','PWRS_MODO',0);
							#
						# SE MANDA A REINICIAR EL DATALOGGER PARA QUE TOME LA CONFIGURACION
							hset("$DLGID",'RESET','TRUE','PW_SAVE');
							spx_log("PW_SAVE => SE REINICIA EL DATALOGGER");
							#
							#
						# ACTUALIZAMOS LA BANDERA PW_SAVE PARA NO TENER QUE LEER LA MYSQL CADA VEZ QUE SE CORRA EL SCRIPT
							hset("$DLGID",'flag_tdial', 900,'PW_SAVE');
							#
					}
					else
					{
						spx_log("PW_SAVE => INCREMENTO EL CONTADOR DE BATERIA BAJA");
						$EXISTS = hexist("$DLGID",'count_VL','PW_SAVE');
						if ($EXISTS == 1)
						{
							$count_VL = $count_VL + 1;
							hset("$DLGID",'count_VL', $count_VL,'PW_SAVE');
						}
						else
						{
							hset("$DLGID",'count_VL', 1,'PW_SAVE');
							$count_VL = 1;
						}
						spx_log("PW_SAVE => \$count_VL = $count_VL");
					}
				}
				else
				{
					spx_log("PW_SAVE => EL TIMER DIAL ESTA SETEADO EN 900");
					#
					# SE ELIMINA EL CONTADOR count_VL SI EXISTE
					$EXISTS = hexist("$DLGID",'count_VL','PW_SAVE');
					if ($EXISTS == 1)
					{
						spx_log("PW_SAVE => SE ELIMINA EL CONTADOR count_VL");
						hdel("$DLGID",'count_VL','PW_SAVE');
					}
				}
		}
		elsif ($bt > $v_hight)
		{
			# MUESTRO LAS CONDICIONES DE ENTRADA
				spx_log("PW_SAVE => BATERIA FULL");
				spx_log("PW_SAVE => bt > v_hight");
				spx_log("PW_SAVE => $bt > $v_hight");
				#
			# SE ELIMINA EL CONTADOR count_VL SI EXISTE PARA GARANTIZAR CONTEO CONTINUO
				$EXISTS = hexist("$DLGID",'count_VL','PW_SAVE');
				if ($EXISTS == 1)
				{
					spx_log("PW_SAVE => SE ELIMINA EL CONTADOR count_VL");
					hdel("$DLGID",'count_VL','PW_SAVE');
				}
				#
			# VEO SI ME ENCUENTRO CON TDIAL 900
				if ($flag_tdial == 900)
				{
					if ( $count_VH >= ($time_hight-1) )
					{
						spx_log("PW_SAVE => SE SETEA TDIAL = 0");
							#
						# SE SETEA EL TDIAL A 0
							ubdate_PARAM($DLGID,'GENERAL','TDIAL',0);
							print FILE "$CURR_FECHA_SYSTEM - ($FECHA_DATA-$HORA_DATA) <PW_SAVE> SE PASA EL SISTEMA A MODO CONTINUO { bt = $bt }\n";
							#
						# SE SETEA EL PWRS_MODO A 0 POR PRECAUCION
							ubdate_PARAM($DLGID,'GENERAL','PWRS_MODO',0);
							#
						# SE MANDA A REINICIAR EL DATALOGGER PARA QUE TOME LA CONFIGURACION
							hset("$DLGID",'RESET','TRUE','PW_SAVE');
							spx_log("PW_SAVE => SE REINICIA EL DATALOGGER");
							#
							#
						# ACTUALIZAMOS LA BANDERA PW_SAVE PARA NO TENER QUE LEER LA MYSQL CADA VEZ QUE SE CORRA EL SCRIPT
							hset("$DLGID",'flag_tdial', 0,'PW_SAVE');
							#
						
					}
					else
					{
						spx_log("PW_SAVE => INCREMENTO EL CONTADOR DE BATERIA FULL");
						$EXISTS = hexist("$DLGID",'count_VH','PW_SAVE');
						if ($EXISTS == 1)
						{
							$count_VH = $count_VH + 1;
							hset("$DLGID",'count_VH', $count_VH,'PW_SAVE');
						}
						else
						{
							hset("$DLGID",'count_VH', 1,'PW_SAVE');
							$count_VH = 1;
						}
						spx_log("PW_SAVE => \$count_VH = $count_VH");
					}
				}
				else
				{
					spx_log("PW_SAVE => EL TIMER DIAL ESTA SETEADO EN 0");
					#
					# SE ELIMINA EL CONTADOR count_VH SI EXISTE
					$EXISTS = hexist("$DLGID",'count_VH','PW_SAVE');
					if ($EXISTS == 1)
					{
						spx_log("PW_SAVE => SE ELIMINA EL CONTADOR count_VH");
						hdel("$DLGID",'count_VH','PW_SAVE');
					}
				}
		}	
		else
		{
			# MUESTRO LAS CONDICIONES DE ENTRADA
				spx_log("PW_SAVE => BATERIA OK");
				spx_log("PW_SAVE => v_low < bt < v_hight");
				spx_log("PW_SAVE => $v_low < $bt < $v_hight");
				#
			# SE ELIMINA EL CONTADOR count_VL SI EXISTE PARA GARANTIZAR CONTEO CONTINUO
				$EXISTS = hexist("$DLGID",'count_VL','PW_SAVE');
				if ($EXISTS == 1)
				{
					spx_log("PW_SAVE => SE ELIMINA EL CONTADOR count_VL");
					hdel("$DLGID",'count_VL','PW_SAVE');
				}
				#
			# SE ELIMINA EL CONTADOR count_VH SI EXISTE PARA GARANTIZAR CONTEO CONTINUO
				$EXISTS = hexist("$DLGID",'count_VH','PW_SAVE');
				if ($EXISTS == 1)
				{
					spx_log("PW_SAVE => SE ELIMINA EL CONTADOR count_VH");
					hdel("$DLGID",'count_VH','PW_SAVE');
				}
				#
		}
		
	# MUESTRO EN LA VISUALIZACION QUE ESTOY EN MODO PWSAVE
		if ($flag_tdial == 900)
		{
			hset("$DLGID",'PWR_SAVE','SI','PW_SAVE');
		}
		else
		{
			hset("$DLGID",'PWR_SAVE','NO','PW_SAVE');
		}
		#
	}
	else
	{
		spx_log('PW_SAVE => NO SE CHEQUEA EL NIVEL DE LA BATERIA');
		spx_log('PW_SAVE => EL EQUIPO TESTEADO NO ES UN TANQUE');
		hset("$DLGID",'PWR_SAVE','NO','PW_SAVE');
	}
	
	

}




############### GENERAR DATOS USANDO LA PENDIENTE ######################
sub m_cal
{
	#m_cal($dlgid,$time,$ltq,$tq_state)
	# DESCRIPTION: 
		##
		#
	# DEFINICION DE VARIABLES
		my $dlgid;
		my $time;
		my $ltq;
		my $EXISTS;
		my $P1;
		my $time_P1;
		my $P2;
		my $time_P2;
		my $delta_time;
		my $last_data;
		my $next_data;
		my $next_time;
		my $tq_state;
		my $last_tq_state;
		my $type;
		my $time_count;
		my $M;
		#
	# VARIABLES DE LA FUNCION
		$dlgid = $_[0];
		$time = $_[1];
		$ltq = $_[2];
		$tq_state = $_[3];
		$type = $_[4];
		#
	# GARANTIZO HACER ESTE PROCEDIMIENTO SOLO PARA EQUIPOS QUE SEAN TANQUES
	if ($type eq 'TQ')
	{
		# READ_BD
			## LEO EL PARAMETRO P1
				$P1 = hget("$dlgid", 'P1','M_CAL');
				#	
			## LEO EL PARAMETRO time_P1
				$time_P1 = hget("$dlgid", 'time_P1','M_CAL');
				#
			## LEO EL PARAMETRO P2
				$P2 = hget("$dlgid", 'P2','M_CAL');
				#
			## LEO EL PARAMETRO time_P2
				$time_P2 = hget("$dlgid", 'time_P2','M_CAL');
				#
			## LEO EL PARAMETRO last_data
				$last_data = hget("$dlgid", 'last_data','M_CAL');
				#
			## LEO EL PARAMETRO M
				$M = hget("$dlgid", 'M','M_CAL');
				#
				#
			## LEO EL PARAMETRO last_tq_state
				$last_tq_state = hget("$dlgid", 'last_tq_state','M_CAL');
				#
				#
			## LEO EL PARAMETRO M
				$M = hget("$dlgid", 'M','M_CAL');
				#
				#
			## LEO EL PARAMETRO time_count
				$time_count = hget("$dlgid", 'time_count','M_CAL');
				#
				#
				
		#VARIABLES DE ENTRADA
		##
			spx_log('M_CAL < $DLGID = '.$dlgid);
			spx_log('M_CAL < $time = '.$time);
			spx_log('M_CAL < $LTQ = '.$ltq);
			spx_log('M_CAL < $tq_state = '.$tq_state);
			spx_log('M_CAL < $type = '.$type);
			#
			$EXISTS = hexist("$dlgid",'P1','M_CAL');
			if ($EXISTS == 1)
			{
				spx_log('M_CAL < $P1 = '.$P1);
			}
			#
			$EXISTS = hexist("$dlgid",'time_P1','M_CAL');
			if ($EXISTS == 1)
			{
				spx_log('M_CAL < $time_P1 = '.$time_P1);
			}
			#
			$EXISTS = hexist("$dlgid",'P2','M_CAL');
			if ($EXISTS == 1)
			{
				spx_log('M_CAL < $P2 = '.$P2);
			}
			#
			$EXISTS = hexist("$dlgid",'time_P2','M_CAL');
			if ($EXISTS == 1)
			{
				spx_log('M_CAL < $time_P2 = '.$time_P2);
			}
			#
			spx_log('M_CAL < $last_tq_state = '.$last_tq_state);
			#
			$EXISTS = hexist("$dlgid",'M','M_CAL');
			if ($EXISTS == 1)
			{
				spx_log('M_CAL < $M = '.$M);
			}
			#
		#MAIN	
		##
			$EXISTS = hexist("$dlgid", 'P1','M_CAL');
			if ($EXISTS == 0)
			#SI NO EXISTE LE ASIGNO EL VALOR A P1
			{
				spx_log('M_CAL => NO EXISTE EL PUNTO 1');
				#
				#
				# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
					spx_log('M_CAL => SE ESTABLECE EL PUNTO 1');
					hset("$dlgid",'P1', $ltq,'M_CAL');
					spx_log("M_CAL => P1 = $ltq");
					hset("$dlgid",'time_P1', $time,'M_CAL');
					spx_log("M_CAL => time_P1 = $time");
					# 
				# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
					$next_data = $ltq;
					$next_time = $time;
					hset("$dlgid", 'last_data', $next_data, 'M_CAL');
					#
				# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
					hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
					#
				
			}
			elsif ($EXISTS == 1)
			{
				$delta_time = delta_time($time,$time_P1,'m','M_CAL');
				# CHEQUEAMOS QUE EL DATO NO SEA EL MISMO
				if($delta_time != 0)
				{
					# CHEQUEAMOS SI EL DATO ACTUAL DIFIERE DE P1 POR MAS DE 12 MINUTOS
					if($delta_time > 11)
					{
						if($delta_time < 19)
						{
							#
							spx_log("M_CAL => 13 < delta_time < 17");
							#
							$EXISTS = hexist("$dlgid",'P2','M_CAL');
							if ($EXISTS == 0)
							{
									# ESTABLECEMOS EL PUNTO 2 CON SU TIEMPO
										spx_log('M_CAL => SE ESTABLECE EL PUNTO 2');
										hset("$dlgid",'P2', $ltq,'M_CAL');
										$P2 = $ltq;
										spx_log("M_CAL => P2 = $ltq");
										hset("$dlgid",'time_P2', $time,'M_CAL');
										$time_P2 = $time;
										spx_log("M_CAL => time_P2 = $time");
										#
										#
									# RESETEAMOS EL CONTADOR DE TIEMPO EN CERO
										hset("$dlgid",'time_count', 0,'M_CAL');	
										#
										#
									# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
										$next_data = $ltq;
										$next_time = $time;
										hset("$dlgid", 'last_data', $next_data, 'M_CAL');
										#
										#
									# CALCULAMOS LA PENDIENTE
										$M = ($P2-$P1)/(delta_time($time_P2,$time_P1,'m','M_CAL'));
										hset("$dlgid",'M', $M,'M_CAL');
										spx_log("M_CAL => M = $M");
										#
										#
									# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
										hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
										#
										#
								
							}
							else
							{
								# CHEQUEO SI EL CONTADOR DE MUESTRAS PREDECIDAS LLEGO A 17
								if ($time_count >= 19)
								{
									spx_log("M_CAL => time_count >= 19");
									spx_log("M_CAL => ERROR TX");
									spx_log("M_CAL => SE CONSERVA EL ULTIMO DATO CALCULADO");
									#
									# NO SE DEBEN PREDECIR MAS DATOS YA QUE YA SE PREDIGERON 17
									# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
										$next_data = $last_data;
										hset("$dlgid", 'last_data', $next_data, 'M_CAL'); 
										#
									# ANADO EL CONTADOR DE TIEMPOS 
										$next_time = add_time($time_P2,'minutes',$time_count);
										#
										#
									# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
										hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
										#
										#
								}
								else
								{
									spx_log("M_CAL => delta_time < 17");
									# CHEQUEO SI HUBO UN CAMBIO DE PENDIENTE
									if ($last_tq_state eq $tq_state)
									{
										# DEVOLVEMOS EL VALOR DE LA ALTURA DEL TANQUE PERO CALCULADO POR LA PENDIENTE
											$next_data = $last_data + $M;
											hset("$dlgid", 'last_data', $next_data, 'M_CAL');
											#
										# INCREMENTAMOS EL CONTADOR DE TIEMPO 
											$time_count = $time_count + 1;
											spx_log("M_CAL => time_count = $time_count");		
											hset("$dlgid",'time_count', $time_count,'M_CAL');
											#
										# ANADO EL CONTADOR DE TIEMPOS 
											$next_time = add_time($time_P2,'minutes',$time_count);
										#
										# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
											hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
										#
									}
									else
									{
										#
										spx_log("M_CAL => HUBO CAMBIO DE PENDIENTE");
										spx_log("M_CAL => SE MANTIENE EL ULTIMO DATO CALCULADO");
										#
										# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
											$next_data = $last_data;
											hset("$dlgid", 'last_data', $next_data, 'M_CAL'); 
											#
										# ANADO EL CONTADOR DE TIEMPOS 
											$next_time = add_time($time_P2,'minutes',$time_count);
											#
										
									}
								}	
							}
						}
						else
						# EL DATO ACTUAL DIFIERE DE P1 POR MAS DE 17 MINUTOS (PROBABLEMENTE SE TRATE DE UN NUEVO DATO A ANALIZAR)
						{
							if($delta_time > 34)
							{
								# EL DATO ACTUAL DIFIERE DE P1 POR MAS DE 17 MINUTOS (PROBABLEMENTE SE TRATE DE UN NUEVO DATO A ANALIZAR)
									spx_log('M_CAL => delta_time > 32');
									spx_log('M_CAL => EL EQUIPO ESTUVO CAIDO MAS DE 15 MINUTOS');
								# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
									spx_log('M_CAL => SE ESTABLECE EL PUNTO 1');
									hset("$dlgid",'P1', $ltq,'M_CAL');
									spx_log("M_CAL => P1 = $ltq");
									hset("$dlgid",'time_P1', $time,'M_CAL');
									spx_log("M_CAL => time_P1 = $time");
									# 
								# ELIMINAMOS EL PUNTO 2
									hdel("$dlgid",'P2','M_CAL');
									hdel("$dlgid",'time_P2','M_CAL');
									spx_log("M_CAL => ELIMINAMOS P2");
									#				
								# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
									$next_data = $ltq;
									$next_time = $time;
									hset("$dlgid", 'last_data', $next_data, 'M_CAL');
									#
								# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
									hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
									#
							}
							else
							{
								spx_log('M_CAL => delta_time < 32');
								#
								$EXISTS = hexist("$dlgid",'P2','M_CAL');
								if ($EXISTS == 0)
								{
									# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
										spx_log('M_CAL => SE ESTABLECE EL PUNTO 1');
										hset("$dlgid",'P1', $ltq,'M_CAL');
										spx_log("M_CAL => P1 = $ltq");
										hset("$dlgid",'time_P1', $time,'M_CAL');
										spx_log("M_CAL => time_P1 = $time");
										#
										#
									# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
										$next_data = $ltq;
										$next_time = $time;
										hset("$dlgid", 'last_data', $next_data, 'M_CAL');
										#
									# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
										hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
										#
								}
								elsif ($EXISTS == 1)
								{
									# CHEQUEO SI HUBO UN CAMBIO DE PENDIENTE
									if ($last_tq_state eq $tq_state)
									{
										# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
											spx_log('M_CAL => SE INTERCAMBIA EL ANTIGUO PUNTO 2 POR ACTUAL PUNTO 1');
											hset("$dlgid",'P1', $P2,'M_CAL');
											$P1=$P2;
											spx_log("M_CAL => P1 = $P1");
											hset("$dlgid",'time_P1', $time_P2,'M_CAL');
											$time_P1 = $time_P2;
											spx_log("M_CAL => time_P1 = $time_P1");
										# 
										# ELIMINAMOS EL PUNTO 2
											hdel("$dlgid",'P2','M_CAL');
											hdel("$dlgid",'time_P2','M_CAL');
											spx_log("M_CAL => ELIMINAMOS P2");
											#
										# CHEQUEMOS SI EL DATO ESTA ENTRE 13 Y 17 MINUTOS RESPECTO A P1
										$delta_time = delta_time($time,$time_P1,'m','M_CAL');
										if (($delta_time < 19) and ($delta_time > 11))
										{
											#
											spx_log('M_CAL => 13 < delta_time < 17');
											#
											# ESTABLECEMOS EL PUNTO 2 CON SU TIEMPO
												spx_log('M_CAL => SE ESTABLECE EL PUNTO 2');
												hset("$dlgid",'P2', $ltq,'M_CAL');
												$P2 = $ltq;
												spx_log("M_CAL => P2 = $ltq");
												hset("$dlgid",'time_P2', $time,'M_CAL');
												$time_P2 = $time;
												spx_log("M_CAL => time_P2 = $time");
											# 
											# GUARDAMOS EL PUNTO ACTUAL
												hset("$dlgid",'last_data', $ltq,'M_CAL');
											#
											# RESETEAMOS EL CONTADOR DE TIEMPO EN CERO
												hset("$dlgid",'time_count', 0,'M_CAL');
											#
											# CALCULAMOS LA PENDIENTE
												$M = ($P2-$P1)/(delta_time($time_P2,$time_P1,'m','M_CAL'));
												hset("$dlgid",'M', $M,'M_CAL');
												spx_log("M_CAL => M = $M");
											#
											# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
												$next_data = $ltq;
												$next_time = $time;
												hset("$dlgid", 'last_data', $next_data, 'M_CAL');
											#
											# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
												hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
											
										}
										else
										{
											# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
												spx_log('M_CAL => SE ESTABLECE EL PUNTO 1');
												hset("$dlgid",'P1', $ltq,'M_CAL');
												spx_log("M_CAL => P1 = $ltq");
												hset("$dlgid",'time_P1', $time,'M_CAL');
												spx_log("M_CAL => time_P1 = $time");
											# 
											# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
												$next_data = $ltq;
												$next_time = $time;
												hset("$dlgid", 'last_data', $next_data, 'M_CAL');
											#
											# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
												hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
											#	
											# ELIMINAMOS EL PUNTO 2
												hdel("$dlgid",'P2','M_CAL');
												hdel("$dlgid",'time_P2','M_CAL');
												spx_log("M_CAL => ELIMINAMOS P2");
												#
										}
										
									}
									else
									# HUBO UN CAMBIO DE PENDIENTE POR CAMBIO DE ACCION SOBRE LA BOMBA
									{
										spx_log("M_CAL => HUBO CAMBIO DE PENDIENTE");
										# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
											spx_log('M_CAL => SE ESTABLECE EL PUNTO 1');
											hset("$dlgid",'P1', $ltq,'M_CAL');
											spx_log("M_CAL => P1 = $ltq");
											hset("$dlgid",'time_P1', $time,'M_CAL');
											spx_log("M_CAL => time_P1 = $time");
											# 
										# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
											$next_data = $ltq;
											$next_time = $time;
											hset("$dlgid", 'last_data', $next_data, 'M_CAL');
											#
										# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
											hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
											#	
										# ELIMINAMOS EL PUNTO 2
											hdel("$dlgid",'P2','M_CAL');
											hdel("$dlgid",'time_P2','M_CAL');
											spx_log("M_CAL => ELIMINAMOS P2");
											#
										
									}
								}
								else
								{
									spx_log('M_CAL => command error in EXISTS/P2');
									print FILE1 "M_CAL => command error in EXISTS/P2\n";
								}
							}
						}
					}
					else
					# EL DATO ACTUAL DIFIERE DE P1 POR MENOS DE 13 MINUTOS (PROBABLEMENTE SE TRATE DE UN EQUIPO TRABAJANDO CONTINUO)
					{
						
						spx_log("M_CAL => delta_time < 13");
						#
						# ESTABLECEMOS EL PUNTO 1 CON SU TIEMPO
							spx_log('M_CAL => SE ESTABLECE EL PUNTO 1');
							hset("$dlgid",'P1', $ltq,'M_CAL');
							spx_log("M_CAL => P1 = $ltq");
							hset("$dlgid",'time_P1', $time,'M_CAL');
							spx_log("M_CAL => time_P1 = $time");
						# 
						# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
							$next_data = $ltq;
							$next_time = $time;
							hset("$dlgid", 'last_data', $next_data, 'M_CAL');
						#
						# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
							hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
						#	
						# ELIMINAMOS EL PUNTO 2
							hdel("$dlgid",'P2','M_CAL');
							hdel("$dlgid",'time_P2','M_CAL');
							spx_log("M_CAL => ELIMINAMOS P2");
							#
					}
				}
				else
				{
					spx_log("M_CAL => NO HA HABIDO CAMBIO DE DATO");
					# 
					# DEVOLVEMOS EL VALOR ACTUAL DE LA ALTURA DEL TANQUE 
					$next_data = $ltq;
					$next_time = $time;
					hset("$dlgid", 'last_data', $next_data, 'M_CAL');
					#
					# SE GUARDA EL ESTADO ACTUAL DEL TANQUE PARA COMPARARLO EN LA PROXIMA CORRIDA DEL PROGRAMA
					hset("$dlgid",'last_tq_state', $tq_state,'M_CAL');
					#
				}
			}
			else
			{
				spx_log('M_CAL => command error in EXISTS/P1');
				print FILE1 "M_CAL => command error in EXISTS/P1\n";
			}
		
		# VARIABLES DE SALIDA
		##						
			#spx_log("M_CAL => \$next_data = $next_data");	
			$next_data = sprintf("%.2f", $next_data);
			spx_log("M_CAL => \$next_data = $next_data");	
			spx_log("M_CAL => \$next_time = $next_time");	
			return $next_data, $next_time;	
	}
	else
	{
		# Elimino los parametros P1 y P2 en caso de que existan.
		hdel("$dlgid", 'P1', 'M_CAL');
		hdel("$dlgid", 'P2', 'M_CAL');
		#
		spx_log('M_CAL => NO SE CALCULA LA PENDIENTE');
		spx_log('M_CAL => EL EQUIPO TESTEADO NO ES UN TANQUE');
		return $ltq, $time;	
	}
}



	#################### ESCRIBIR EN BASE REDIS #########################
	sub write_redis
	{
		spx_log("WRITE REDIS");
				
		# ESCRIBIR LAS SALIDAS PARA EL DATALOGGER
			#~ $DO_0 = 0;
			#~ $DO_1 = 0;
			#~ $DO_2 = 0;
			#~ $DO_3 = 0;
			$DO_4 = 0;
			$DO_5 = 0;
			$DO_6 = 0;
			$DO_7 = 0;
			#
			my $OUTPUTS_WORD_BIN = "$DO_7$DO_6$DO_5$DO_4$DO_3$DO_2$DO_1$DO_0";
			my $OUTPUTS_WORD_DEC = bin2dec($OUTPUTS_WORD_BIN); 
			#
			$redis->hset( $DLGID, "OUTPUTS", $OUTPUTS_WORD_DEC );
		
		

		# ESCRIBO LA FECHA Y HORA PARA EL CASO DE QUE SEA UN TANQUE
		## ME FIJO EN EL TIPO DE INSTALACION QUE TENGO
			if ($TYPE eq 'TQ')
			{
				# SE ESCRIBE EL VALOR DEL ULTIMO DATO LLEGADO AL SERVIDOR PARA ACTUALIZARLO EN LA VISUALIZACION DEL TANQUE
				#$redis->hset( "$DLGID", LAST_FECHA_DATA => $FECHA_DATA.'_'.$HORA_DATA );
				$redis->hset( "$DLGID", LAST_FECHA_DATA => $LAST_FECHA_DATA );
			}	
		
		# ESCRIBO EL VALOR de $error_ES_count (CONTADOR DE ERRORES PARA EL RESET)
			$redis->hset("ERROR_PERF_TEST_$DLGID", "error_ES_count", $error_ES_count);
			
		# ESCRIBO LA ALTURA DEL TANQUE CUANDO EL EQUIPO TESTEADO ES UN TANQUE
		# CHEQUEO SI ESTAMOS EN PRESENCIA DE UN TANQUE
		if (($TYPE eq 'TQ') or ($TYPE eq 'PERF_AND_TQ'))
		{
			if (defined $H_TQ)
			{
				# ESCRIBIMOS LA ALTURA DEL TANQUE PARA QUE SE VISUALICE AUNQUE FALLE EL TABLERO DE LA PERFORACION
				$redis->hset( "$DLGID", H_TQ => "$H_TQ" );
			}
		}	
		
	# ESCRIBO EL VALOR DE tq_level_mail_alarm  Y tq_count_mail_alarm SI HAY UN TANQUE CONECTADO EL EQUIPO TESTEADO
		if (($TYPE eq 'TQ') or ($TYPE eq 'PERF_AND_TQ'))
		{
			# ESCRIBIMOS LA ALTURA DEL TANQUE PARA QUE SE VISUALICE AUNQUE FALLE EL TABLERO DE LA PERFORACION
			#~ $redis->hset( "$DLGID_TQ", tq_level_mail_alarm => "$tq_level_mail_alarm" );
			#~ $redis->hset( "$DLGID_TQ", tq_count_mail_alarm => "$tq_count_mail_alarm" );
			$redis->hset( "$DLGID", tq_level_mail_alarm => "$tq_level_mail_alarm" );
			$redis->hset( "$DLGID", tq_count_mail_alarm => "$tq_count_mail_alarm" );
		}	
		
	# ESCRIBO EL VALOR DE cl_low_level_mail_alarm Y cl_low_count_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION 
		if (($TYPE eq 'PERF') or ($TYPE eq 'PERF_AND_TQ'))
		{
			# ESCRIBIMOS LO RELACIONADO CON EL ENVIO DE MAILS POR ALARMAS DE CLORO
			$redis->hset( "$DLGID", cl_low_level_mail_alarm => "$cl_low_level_mail_alarm" );
			$redis->hset( "$DLGID", cl_low_count_mail_alarm => "$cl_low_count_mail_alarm" );
			$redis->hset( "$DLGID", CL_ALARM_STATE => "$CL_ALARM_STATE" );
		}	
		
	# ESCRIBO EL VALOR DE cl_high_count_mail_alarm Y cl_high_count_mail_alarm SI EL EQUIPO TESTEADO ES UNA PERFORACION 
		if (($TYPE eq 'PERF') or ($TYPE eq 'PERF_AND_TQ'))
		{
			# ESCRIBIMOS LA ALTURA DEL TANQUE PARA QUE SE VISUALICE AUNQUE FALLE EL TABLERO DE LA PERFORACION
			$redis->hset( "$DLGID", cl_high_level_mail_alarm => "$cl_high_level_mail_alarm" );
			$redis->hset( "$DLGID", cl_high_count_mail_alarm => "$cl_high_count_mail_alarm" );
		}
		
	# ESCRIBO EL VALOR DE $outputs_states
			#spx_log('$outputs_states = '.$outputs_states);
			$redis->hset("ERROR_PERF_TEST_$DLGID", "outputs_states", $outputs_states);
		
	}

	######################### RESET DEL DATALOGGER #########################
	sub reset_DLG
	{
		if ($DLGID ne 'UYSAL010')												#OJOOOOO###
		{
		
		# RESETEO EL DATALOGGER CUANDO EL ERROR PERMANECE POR MAS DE 3 MIN
		if ($error_ES_count >= 2)
		{
			# FUNCION QUE REINICA EL DATALOGGER EN CASO DE FALLAS
			$error_ES_count = 0;
			$redis-> hset("$DLGID",'RESET','TRUE');
			spx_log(' SE APLICA RESET AL DATALOGGER');
			print FILE "SE APLICA RESET AL DATALOGGER.\n";
			goto quit;
		}
			else
		{
			# SE INCREMENTA LA VARIABLE CONTADOR
			spx_log('SE INCREMENTA EL CONTADOR DE ERRORES DE SALIDA');
			$error_ES_count = $error_ES_count + 1;
		}
		
		}
		
	}

	#################### CONVERTIR BINARIO A DECIMAL #######################	
	sub bin2dec 
	{
		return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
	}
	#################### CONVERTIR DECIMAL A BINARIO #######################
	sub dec2bin 
	{
		my $str = unpack("B32", pack("N", shift));
		$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
		return $str;
	}

	####################### MOSTRAR EN CONSOLA #############################
	sub spx_log
	{
		if ($print_log eq "OK")
		{
		my $logStr = $_[0];
		
		chomp($logStr);
		my $msg = "";
		if ( $logStr ne "") 
		{
			$msg = "[$NUMERO_EJECUCION][$logStr]";
		} 
		print "$msg\n";
		return;
		}
	}

	####################### NUMERO DE EJECUCION ############################
	sub no_execution
	{
	#ESCRIBIR EN LA REDIS
			
		#ESCRIBIR NUMERO DE EJECUCION DEL SCRIPT SIN REINICIO DE LA REDIS
		my $EXISTS = $redis->hexists("ERROR_PERF_TEST_$DLGID", 'NUMERO_EJECUCION');
		if ($EXISTS == 0)
		#SI NO EXISTE LO CREO CON VALOR 0
		{
			$NUMERO_EJECUCION = 0;	
			$redis->hset("ERROR_PERF_TEST_$DLGID", 'NUMERO_EJECUCION', $NUMERO_EJECUCION);
		}
		else
		{
			#LEO EL NUMERO DE EJECUCION
			$NUMERO_EJECUCION = $redis->hget("ERROR_PERF_TEST_$DLGID","NUMERO_EJECUCION");
			$NUMERO_EJECUCION = $NUMERO_EJECUCION + 1;
			$redis-> hset("ERROR_PERF_TEST_$DLGID",'NUMERO_EJECUCION', $NUMERO_EJECUCION);
			#$redis->hincrby("ERROR_PERF_TEST_$DLGID", NUMERO_EJECUCION, 1);
		}
	}
	########################## VISUALIZACION ###############################
	sub visual
	{
		# SE ENCARGA DE VISUALIZAR LA ALTURA DEL TANQUE PARA QUE SE MANTENGA ACTUALIZADA EN CASOS DE FALLOS EN EL DLG DE LA PERFORACION
		if ($ERR_SENSOR_TQ eq 'NO')
		{
		# ASIGNO LA ALTURA DEL TANQUE A H_TQ
			if ($LTQ < 0)
			{
				$H_TQ = 0;
			}
			else 
			{
				$H_TQ = $LTQ;
			}
		}
		if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
		{
			if (($CL < $CL_MIN_ALARM) or ($CL > $CL_MAX_ALARM))
			{
				$CL_ALARM_STATE = 'SI';
			}
			else
			{
				$CL_ALARM_STATE = 'NO';
			}
		}
		# MOSTRAR BOX DE TRABAJO CON EL SISTEMA DE EMERGENCIA CUANDO HAY ERROR TX EN LA PERFORACION
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))	
			{
				if ($TX_ERROR eq 'SI')
				{
					$redis->hset("$DLGID",'EMERGENCY_STATE','SI');
				}
				else
				{
					$redis->hset("$DLGID",'EMERGENCY_STATE','NO');
				}
			}
	}
	
	
	

	######################### ENVIAR EL MAIL ###############################
	sub alarm_levels
	# SE ENCARGA DE GENERAR LOS EVENTOS QUE ENVIAN MAILS
	{	
		#~ spx_log('$LTQ = '.$LTQ);
		#$LTQ = 0.01; 
		#~ $return_tx = 'OK';
		#~ spx_log('SEND_MAIL => '.$SEND_MAIL);
		#~ spx_log('L_MIN_ALARM => '.$L_MIN_ALARM);
		#~ spx_log('LTQ => '.$LTQ);
		#~ #spx_log('PER_TX_ERROR => '.$PER_TX_ERROR);
		#~ spx_log('ERR_SENSOR_TQ => '.$ERR_SENSOR_TQ);
		#
		spx_log('TEST_ALARM_LEVEL');
		#
		## LE DAMOS FORMATO A LA FECHA Y HORA DEL DATO PARA PODER ESCRIBIRLO EN EL MAIL DE LAS ALARMAS
		my @DATE = split ('',$FECHA_DATA );
		#spx_log('@DATE = '."@DATE");
		my $formatted_FECHA_DATA = $DATE[6].$DATE[7].'/'.$DATE[4].$DATE[5].'/'.$DATE[0].$DATE[1].$DATE[2].$DATE[3];
		#spx_log('$formatted_FECHA_DATA = '.$formatted_FECHA_DATA);
		my @DATE = split ('',$HORA_DATA );
		#spx_log('@DATE = '."@DATE");
		my $formatted_HORA_DATA = $DATE[0].$DATE[1].':'.$DATE[2].$DATE[3].':'.$DATE[4].$DATE[5];
		#spx_log('$formatted_HORA_DATA = '.$formatted_HORA_DATA);
		#
		
	## ALARMA DE NIVEL MINIMO DE TANQUE	
		# VERIFICO QUE ESTE ACTIVADA LA OPCION DE ENVIAR MAILS
		if ($SEND_MAIL eq 'SI')
		{	
			#~ spx_log('TYPE = '.$TYPE);
			# VERIFICO SI SE ESTA TESTANDO UN EQUIPO QUE TIENE TANQUE CONECTADO
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'TQ'))
			{
				# VERIFICO SI HUBO ERROR TX
				if ($return_tx eq 'OK')
				{
					# VERIFICO QUE EL SENSOR DEL TANQUE ESTE OK PARA NO EMITIR ALARMAS FALSAS
					if ($ERR_SENSOR_TQ eq 'NO')
					{
						#print "LTQ = $LTQ\n";
						#print "L_MIN_ALARM = $L_MIN_ALARM\n";	
						# HABILITO NUEVAMENTE EL ENVIO DE MAIL CUANDO LA ALTURA DEL TANQUE PASO LOS 20 CM DEL NIVEL MINIMO DE ALARMA
						
						if ($LTQ > ($L_MIN_ALARM + 0.15))
						{
							$tq_level_mail_alarm = 'NO';
							$tq_count_mail_alarm = 0; 	#RESETEO EL CONTADOR
							spx_log('TEST_ALARM_LEVEL => NIVEL DEL TANQUE OK');
						}
						else
						{
							# ALARMA DEL TANQUE VACIO
							if ($LTQ < $L_MIN_ALARM)
							{
								$tq_count_mail_alarm = $tq_count_mail_alarm + 1;
								
								# DEFINO LA CANTIDAD DE MUESTRAS QUE QUIERO QUE ME LLEGUEN ANTES DE MANDAR EL MAIL
																
								if ($tq_count_mail_alarm >=3)
								{
									#$tq_count_mail_alarm = 0; 	#RESETEO EL CONTADOR
									# VERIFICO SI YA SE MANDO EL MAIL DE ALARMA DEK NIVEL DEL TANQUE
									if ($tq_level_mail_alarm eq 'NO')
									{
										spx_log('TEST_ALARM_LEVEL => NIVEL DEL TANQUE MUY BAJO');
										# CONFORMO EL MAIL
										my $emailSubject = "ALARMA DE NIVEL DEL TANQUE $TQ_NAME \n";
										my $emailBody = " ---------------------------SPYMOVIL-----------------------------\n";
										$emailBody .= "           ALARMA DE NIVEL MINIMO DEL TANQUE\n";
										$emailBody .= "\n";
										$emailBody .= "ID DEL EQUIPO = $DLGID\n";
										$emailBody .= "NOMBRE DEL TANQUE = $TQ_NAME\n";
										$emailBody .= "NIVEL DE ALARMA SELECCIONADO = $L_MIN_ALARM mca\n";
										$emailBody .= "FECHA DEL DATO = $formatted_FECHA_DATA\n";		
										$emailBody .= "HORA DEL DATO = $formatted_HORA_DATA\n";	
										$emailBody .= "ALTURA ACTUAL DEL TANQUE = $LTQ mca\n";
										$emailBody .= "\n";
										$emailBody .= "\n";
										$emailBody .= "\n";
										#$emailBody .= "##### ESTE MAIL ES UNA PRUEBA #####\n";
										#
									&sendEmail($emailSubject,$emailAddr_tq,$emailBody);
							
										$tq_level_mail_alarm = 'SI';
									}
									else
									{
										spx_log('TEST_ALARM_LEVEL => YA SE ENVIO EL MAIL');
									}
								}
								else
								{
									spx_log('TEST_ALARM_LEVEL => INCREMENTO CONTADOR DE MUESTRAS ANTES DE MANDAR EL MAIL');
									spx_log('TEST_ALARM_LEVEL => COUNT = '.$tq_count_mail_alarm);
								}
							}
							else
							{
								spx_log('TEST_ALARM_LEVEL => NIVEL MIN DEL TANQUE OK');
								$tq_count_mail_alarm = 0;
							}
						}	
					}
					else
					{
						spx_log('TEST_ALARM_LEVEL => ERROR DE SENSOR');
						spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MIN DEL TANQUE');
					}
				}
				else
				{
					spx_log('TEST_ALARM_LEVEL => ERROR TX');
					spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA NIVEL MIN DEL TANQUE');
				}
			}
			else
			{
				spx_log('TEST_ALARM_LEVEL => SIN PRESENCIA DE TANQUE');
				spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MIN DEL TANQUE');
			}
		}
		else
		{
			spx_log('TEST_ALARM_LEVEL => ENVIO DE MAIL DESHABILITADO');
		}
		#
		#
	## ALARMA DE NIVEL MINIMO DE CLORO
		#~ $BP = 1; 
		#~ $CL = 0.1; 
		#~ $PER_TX_ERROR = 'NO';
		#~ spx_log('PER_TX_ERROR => '.$PER_TX_ERROR);
		#~ spx_log('$BP = '.$BP);
		#~ spx_log('CL_MIN_ALARM => '.$CL_MIN_ALARM);
		#~ spx_log('CL => '.$CL);
		#~ spx_log('PER_TX_ERROR => '.$PER_TX_ERROR);
		#~ spx_log('ERR_SENSOR_TQ => '.$ERR_SENSOR_TQ);


		# VERIFICO QUE ESTE ACTIVADA LA OPCION DE ENVIAR MAILS
		if ($SEND_MAIL eq 'SI')
		{	
			#~ spx_log('TYPE = '.$TYPE);
			# VERIFICO SI SE ESTA TESTANDO UN EQUIPO QUE TIENE TANQUE CONECTADO
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
			{
				# VERIFICO SI HUBO ERROR TX
				if ($return_tx eq 'OK') 
				{
					# VERIFICO QUE LA BOMBA ESTE PRENDIDA
					if ($BP == 1)
					{
						# HABILITO NUEVAMENTE EL ENVIO DE MAIL CUANDO LA MAGNITUD DEL CLORO PASO LAS 0.25 PPM DEL NIVEL DE ALARMA
						if ($CL > ($CL_MIN_ALARM + 0.25))
						{
							$cl_low_level_mail_alarm = 'NO';
							$cl_low_count_mail_alarm = 0; 	#RESETEO EL CONTADOR
							spx_log('TEST_ALARM_LEVEL => NIVEL DE CLORO OK');
						}
						else
						{
							# ALARMA DE NIVEL MINIMO DE CLORO
							if ($CL < $CL_MIN_ALARM)
							{
								$cl_low_count_mail_alarm = $cl_low_count_mail_alarm + 1;
								
								# DEFINO LA CANTIDAD DE MUESTRAS QUE QUIERO QUE ME LLEGUEN ANTES DE MANDAR EL MAIL
								if ($cl_low_count_mail_alarm >=3)
								{
									#$tq_count_mail_alarm = 0; 	#RESETEO EL CONTADOR
									# VERIFICO SI YA SE MANDO EL MAIL DE ALARMA 
									if ($cl_low_level_mail_alarm eq 'NO')
									{
										spx_log('TEST_ALARM_LEVEL => NIVEL DEL CLORO MUY BAJO');
										# CONFORMO EL MAIL
										my $emailSubject = "ALARMA DE NIVEL BAJO DE CLORO DE LA PERFORACIO $PERF_NAME \n";
										my $emailBody = " ---------------------------SPYMOVIL-----------------------------\n";
										$emailBody .= "           ALARMA DE NIVEL BAJO DE CLORO\n";
										$emailBody .= "\n";
										$emailBody .= "ID DEL EQUIPO = $DLGID\n";
										$emailBody .= "NIVEL MINIMO DE ALARMA SELECCIONADO = $CL_MIN_ALARM ppm\n";
										$emailBody .= "NIVEL MAXIMO DE ALARMA SELECCIONADO = $CL_MAX_ALARM ppm\n";
										$emailBody .= "FECHA DEL DATO = $formatted_FECHA_DATA\n";		
										$emailBody .= "HORA DEL DATO = $formatted_HORA_DATA\n";	
										$emailBody .= "NIVEL DE CLORO = $CL ppm\n";
										$emailBody .= "\n";
										$emailBody .= "\n";
										$emailBody .= "\n";
									&sendEmail($emailSubject,$emailAddr_perf,$emailBody);
							
										$cl_low_level_mail_alarm = 'SI';
									}
									else
									{
										spx_log('TEST_ALARM_LEVEL => YA SE ENVIO EL MAIL POR NIVEL MINIMO DE CLORO');
									}
								}
								else
								{
									spx_log('TEST_ALARM_LEVEL => INCREMENTO CONTADOR DE MUESTRAS ANTES DE MANDAR EL MAIL');
									spx_log('TEST_ALARM_LEVEL => COUNT = '.$cl_low_count_mail_alarm);
								}
							}
							else
							{
								spx_log('TEST_ALARM_LEVEL => NIVEL MINIMO DE CLORO OK');
								$cl_low_count_mail_alarm = 0;
							}
						}	
					}
					else
					{
						#spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL DEL TANQUE POR ERROR DE SENSOR');
						spx_log('TEST_ALARM_LEVEL => BOMBA APAGADA');
						spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MIN DE CLORO');
					}
				}
				else
				{
					spx_log('TEST_ALARM_LEVEL => ERROR TX EN LA PERFORACION');
					spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MIN DE CLORO');
				}
			}
			else
			{
				spx_log('TEST_ALARM_LEVEL => EL SISTEMA TESTEADO ES UN TANQUE');
				spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MIN DE CLORO');
			}
		}
		else
		{
			spx_log('TEST_ALARM_LEVEL => ENVIO DE MAIL DESHABILITADO');
		}
	#
	#
	## ALARMA DE NIVEL MAXIMO DE CLORO
	
		#~ $BP = 1; 
		#~ $CL = 8; 
		#~ $PER_TX_ERROR = 'NO';
		#~ spx_log('PER_TX_ERROR => '.$PER_TX_ERROR);
		#~ spx_log('$BP = '.$BP);
		#~ spx_log('CL_MAX_ALARM => '.$CL_MAX_ALARM);
		#~ spx_log('CL => '.$CL);
		#~ spx_log('PER_TX_ERROR => '.$PER_TX_ERROR);
		
		# VERIFICO QUE ESTE ACTIVADA LA OPCION DE ENVIAR MAILS
		if ($SEND_MAIL eq 'SI')
		{	
			#~ spx_log('TYPE = '.$TYPE);
			# VERIFICO SI SE ESTA TESTANDO UN EQUIPO QUE TIENE TANQUE CONECTADO
			if (($TYPE eq 'PERF_AND_TQ') or ($TYPE eq 'PERF'))
			{
				# VERIFICO SI HUBO ERROR TX
				if ($return_tx eq 'OK') 
				{
					# VERIFICO QUE LA BOMBA ESTE PRENDIDA
					if ($BP == 1)
					{
						# HABILITO NUEVAMENTE EL ENVIO DE MAIL CUANDO LA MAGNITUD DEL CLORO PASO LAS 0.25 PPM DEL NIVEL DE ALARMA
						if ($CL < ($CL_MAX_ALARM - 0.25))
						{
							$cl_high_level_mail_alarm = 'NO';
							$cl_high_count_mail_alarm = 0; 	#RESETEO EL CONTADOR
							spx_log('TEST_ALARM_LEVEL => NIVEL DE CLORO OK');
						}
						else
						{
							# ALARMA DE NIVEL MINIMO DE CLORO
							if ($CL > $CL_MAX_ALARM)
							{
								$cl_high_count_mail_alarm = $cl_high_count_mail_alarm + 1;
								
								# DEFINO LA CANTIDAD DE MUESTRAS QUE QUIERO QUE ME LLEGUEN ANTES DE MANDAR EL MAIL
								if ($cl_high_count_mail_alarm >=3)
								{
									# VERIFICO SI YA SE MANDO EL MAIL DE ALARMA 
									if ($cl_high_level_mail_alarm eq 'NO')
									{
										spx_log('TEST_ALARM_LEVEL => NIVEL DEL CLORO MUY ALTO');
										# CONFORMO EL MAIL
										my $emailSubject = "ALARMA DE NIVEL ALTO DE CLORO DE LA PERFORACIO $PERF_NAME \n";
										my $emailBody = " ---------------------------SPYMOVIL-----------------------------\n";
										$emailBody .= "           ALARMA DE NIVEL ALTO DE CLORO\n";
										$emailBody .= "\n";
										$emailBody .= "ID DEL EQUIPO = $DLGID\n";
										$emailBody .= "NIVEL MINIMO DE ALARMA SELECCIONADO = $CL_MIN_ALARM ppm\n";
										$emailBody .= "NIVEL MAXIMO DE ALARMA SELECCIONADO = $CL_MAX_ALARM ppm\n";
										$emailBody .= "FECHA DEL DATO = $formatted_FECHA_DATA\n";		
										$emailBody .= "HORA DEL DATO = $formatted_HORA_DATA\n";	
										$emailBody .= "NIVEL DE CLORO = $CL ppm\n";
										$emailBody .= "\n";
										$emailBody .= "\n";
										$emailBody .= "\n";
									&sendEmail($emailSubject,$emailAddr_perf,$emailBody);
							
										$cl_high_level_mail_alarm = 'SI';
									}
									else
									{
										spx_log('TEST_ALARM_LEVEL => YA SE ENVIO EL MAIL POR NIVEL ALTO DE CLORO');
									}
								}
								else
								{
									spx_log('TEST_ALARM_LEVEL => INCREMENTO CONTADOR DE MUESTRAS ANTES DE MANDAR EL MAIL');
									spx_log('TEST_ALARM_LEVEL => COUNT = '.$cl_high_count_mail_alarm);
								}
							}
							else
							{
								spx_log('TEST_ALARM_LEVEL => NIVEL DE CLORO OK');
								$cl_high_count_mail_alarm = 0;
							}
						}	
					}
					else
					{
						#spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL DEL TANQUE POR ERROR DE SENSOR');
						spx_log('TEST_ALARM_LEVEL => BOMBA APAGADA');
						spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MAX DE CLORO');
					}
				}
				else
				{
					spx_log('TEST_ALARM_LEVEL => ERROR TX EN LA PERFORACION');
					spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MAX DE CLORO');
				}
			}
			else
			{
				spx_log('TEST_ALARM_LEVEL => EL SISTEMA TESTEADO ES UN TANQUE');
				spx_log('TEST_ALARM_LEVEL => NO SE CHEQUEA EL NIVEL MAX DE CLORO');
			}
		}
		else
		{
			spx_log('TEST_ALARM_LEVEL => ENVIO DE MAIL DESHABILITADO');
		}
		
		
	
	
		
	}

	######################### ENVIAR EL MAIL ###############################
		sub sendEmail()
	{
			spx_log('SE ENVIA MAIL DE ALARMA');					
			my $emailSubject = $_[0];
			my $emailAddr = $_[1];
			my $emailBody = $_[2];
			
			my $smtpserver = $PERF_CONFIG::smtpserver;			
			my $smtpport = $PERF_CONFIG::smtpport;				
			my $smtpuser   = $PERF_CONFIG::smtpuser;			
			my $smtppassword = $PERF_CONFIG::smtppassword;		
			
			if ($smtpserver eq 'localhost')
			{
				# MOODULO DE SCRIPT PARA ENVIO DE MAILS CON SERVIDORES LOCALES
				print "SERVIDOR DE CORREOS LOCAL\n";
				spx_log("sendEmail begin");
				spx_log("sendEmail begin");
				#$emailAddr .= ",alain.rodriguez\@spymovil.com"; 			#COPIA A ESTA DIRECCION 
				my $eAddr;													#LO PUSE YO
				my @address = split(/,|;/, $emailAddr);
					foreach $eAddr ( @address) 
					{
						my $smtp = Net::SMTP->new($smtpserver, Port=>$smtpport, Timeout => 10, Debug => 1);
						die "Could not connect to server!\n" unless $smtp;

						$smtp->auth($smtpuser, $smtppassword);
						$smtp->mail($smtpuser);
						$smtp->to($eAddr);
						$smtp->data();
						$smtp->datasend("Subject: ".$emailSubject."\n");
						$smtp->datasend($emailBody);
						$smtp->quit;

						spx_log("\tTO:$eAddr");
					}
			spx_log("$emailBody");
			spx_log("sendEmail end");
				
			}
			elsif ($smtpserver eq 'Gmail')
			{
				# MOODULO DE SCRIPT PARA ENVIO DE MAILS CON SERVIDORES GMAIL
				print "SERVIDOR DE CORREOS GMAIL\n";
				# COMPATIBILIDAD DE VARIABLES PARA LA CONFIGURACION
				my $mailer = $smtpserver;
				my $username = $smtpuser;
				my $password = $smtppassword;
				
				
				print "sendEmail begin\n";
				
				#DEBUG 
			#	$emailAddr .= ",ppeluffo\@spymovil.com";

				my @address = split(/,|;/, $emailAddr);
				my $eAddr;
				foreach $eAddr ( @address) {
					my $email = Email::Simple->create(
							header => [
							From    => 'spymovil@spymovil.com',
							To      => $eAddr,
							#To		=> 'ppeluffo@spymovil.com',
							Subject => $emailSubject,
							],
							body => $emailBody ,
							);

					my $sender = Email::Send->new(
								{   mailer      => $mailer,
									mailer_args => [
									username => $smtpuser,
									password => $password,
									]
								}
							);
					print "\tTO:$eAddr\n";
					eval { $sender->send($email) };
					if ($@) {
						print "Error sending email: $@ \n"
					}
				}
				#print "$emailBody\n";
				print "sendEmail end\n";
				
			}
			else
			{
				print "NO SE DEFINIO DE FORMA CORRECTA EL SERVIDOR DE CORREO []";
			}
			
		
	}  
	  
	################### LEER LOS DATOS DEL DATALOGGER ##################
	sub read_dlg_data
	{
		my $DLGID = $_[0];
		my @params;
		my $head = 'LINE=DATE';			# TEXTO QUE SE ENCUENTRA EN EL LINE DE LOS DATALOGGER CON FIRMWARE NUEVO
		my $second_split;
		
		
		# DESCRIPTION: 
			# ESTA FUNCION ES LA ENCARGADA DE LEER LOS DATOS DEL DATALOGGER
			#
		# READ_BD
			#VARIABLES DE ENTRADA
			spx_log('READ_DLG_DATA < $DLGID = '.$DLGID);
			#
		#MAIN	
		#
		##LECTURA DE LOS DATOS DEL DATALOGGER
			my $i;
			my $EXISTS = $redis->hexists("$DLGID", "LINE");	
			if ($EXISTS == 0)
			{
				spx_log('READ_DLG_DATA => NO EXISTE EL LINE DEL DATALOGGER');
				spx_log('READ_DLG_DATA => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else
			{
				my $line = $redis->hget( $DLGID, 'LINE' );
				
				# CHEQUEO QUE EL LINE TIENE VALORES VALIDOS
				if ($line eq 'NUL')
				{
					spx_log('READ_DLG_DATA => LINE DEL DATALOGGER CON VALOR INVALIDO');
					#
					my $EXISTS = $redis->hexists("$DLGID", "LAST_LINE");
					if ($EXISTS == 1)
					{
						# RECUPERO EL LINE A PARTIR DEL ULTIMO GUARDADO
						my $last_line = $redis->hget( $DLGID, 'LAST_LINE' );
						$redis->hset( $DLGID, 'LINE', $last_line);
						#
						spx_log('READ_DLG_DATA => SE RECUPERA EL LINE A PARTIR DE LAST_LINE');
					}
					else
					{
						spx_log('READ_DLG_DATA => NO SE EJECUTA EL SCRIPT');
						goto quit
					}
							
				}
				else
				{
					# GUARDO EL VALOR DEL ULTIMO LINE VALIDO
					$redis->hset( $DLGID, 'LAST_LINE', $line );
				}
				
				my $line = $redis->hget( $DLGID, 'LINE' );
				
				# DETECTO QUE TIPO DE LINE SE ESTA UILIZANDO
				if ($line =~  /\b$head/)				#spx_log ('FECHA_DATA => '."$FECHA_DATA");
				{
				   spx_log('READ_DLG_DATA => LINE DEL FIRMWARE NUEVO');
				   @params = split(/;/,$line);
				   my @value = split(/:/,$params[0]);
				   $FECHA_DATA = $value[1];
				   my @value = split(/:/,$params[1]);
				   $HORA_DATA = $value[1];
				   
				   # LAS VARIABLES Y LOS VALORES SE SEPARAN CON ':'
				   $second_split = ':';
				}
				else
				{
					spx_log('READ_DLG_DATA => LINE DEL FIRMWARE VIEJO');
					@params = split(/,/,$line);
					my @value = split(/=/,$params[0]);
					$FECHA_DATA = $value[1];
					$HORA_DATA = $params[1];
					
					# LAS VARIABLES Y LOS VALORES SE SEPARAN CON '='
					$second_split = '=';
					
				}
						
				for($i = 2; $i < @params; $i++) 
				{
					#~ spx_log('i = '.$i);
					my @value = split(/$second_split/,$params[$i]);
					#spx_log('value = '."@value" );
					
					if ($value[0] eq 'PPR')
					{
						$PPR = $value[1];
					} 
					elsif ($value[0] eq 'LTQ')
					{
						$LTQ = $value[1];
					} 
					elsif ($value[0] eq 'CL')
					{
						$CL = $value[1];
					}
					elsif ($value[0] eq 'BAT')
					{
						$BAT = $value[1];
					}
					elsif ($value[0] eq 'GA')
					{
						$GA = $value[1];
					}
					elsif ($value[0] eq 'FE')
					{
						$FE = $value[1];
					}
					elsif ($value[0] eq 'LM')
					{
						$LM = $value[1];
					}
					elsif ($value[0] eq 'BD')
					{
						$BD = $value[1];
					}
					elsif ($value[0] eq 'BP')
					{
						$BP = $value[1];
					}
					elsif ($value[0] eq 'BY')
					{
						$BY = $value[1];
					}
					elsif ($value[0] eq 'TM')
					{
						$TM = $value[1];
					}
					elsif ($value[0] eq 'ABY')
					{
						$ABY = $value[1];
					}
					elsif ($value[0] eq 'FT')
					{
						$FT = $value[1];
					}
					elsif ($value[0] eq 'PCAU')
					{
						$PCAU = $value[1];
					}
					elsif ($value[0] eq 'bt')
					{
						$bt = $value[1];		
					}
				}
			}
		
		# VARIABLES DE SALIDA
		##
		spx_log('READ_DLG_DATA > $FECHA_DATA = '.$FECHA_DATA);
		spx_log('READ_DLG_DATA > $HORA_DATA = '.$HORA_DATA);
		if (defined $PPR)
		{
		spx_log('READ_DLG_DATA > $PPR = '.$PPR);
		}
		if (defined $LTQ)
		{
		spx_log('READ_DLG_DATA > $LTQ = '.$LTQ);
		}
		if (defined $CL)
		{
		spx_log('READ_DLG_DATA > $CL = '.$CL);
		}
		if (defined $BAT)
		{
		spx_log('READ_DLG_DATA > $BAT = '.$BAT);
		}
		if (defined $GA)
		{
		spx_log('READ_DLG_DATA > $GA = '.$GA);
		}
		if (defined $FE)
		{
		spx_log('READ_DLG_DATA > $FE = '.$FE);
		}
		if (defined $LM)
		{
		spx_log('READ_DLG_DATA > $FE = '.$LM);
		}
		if (defined $BD)
		{
		spx_log('READ_DLG_DATA > $BD = '.$BD);
		}
		if (defined $BP)
		{
		spx_log('READ_DLG_DATA > $BP = '.$BP);
		}
		if (defined $BY)
		{
		spx_log('READ_DLG_DATA > $BY = '.$BY);
		}
		if (defined $TM)
		{
		spx_log('READ_DLG_DATA > $TM = '.$TM);
		}
		if (defined $ABY)
		{
		spx_log('READ_DLG_DATA > $ABY = '.$ABY);
		}
		if (defined $FT)
		{
		spx_log('READ_DLG_DATA > $FT = '.$FT);
		}
		if (defined $PCAU)
		{
		spx_log('READ_DLG_DATA > $PCAU = '.$PCAU);
		}
		if (defined $bt)
		{
		spx_log('READ_DLG_DATA > $bt = '.$bt);
		}

	}
		
		#~ sub read_dlg_data
		#~ {
			#~ my $DLGID = $_[0];
			#~ # DESCRIPTION: 
				#~ # ESTA FUNCION ES LA ENCARGADA DE LEER LOS DATOS DEL DATALOGGER
				#~ #
			#~ # READ_BD
				#~ #VARIABLES DE ENTRADA
				#~ spx_log('READ_DLG_DATA < $DLGID = '.$DLGID);
				#~ #
			#~ #MAIN	
			#~ #
			#~ ##LECTURA DE LOS DATOS DEL DATALOGGER
			#~ my $i;
			#~ my $EXISTS = $redis->hexists("$DLGID", "LINE");	
			#~ if ($EXISTS == 0)
			#~ {
				#~ spx_log('READ_DLG_DATA => NO EXISTE EL LINE DEL DATALOGGER');
				#~ spx_log('READ_DLG_DATA => NO SE EJECUTA EL SCRIPT');
				#~ goto quit_all
			#~ }
			#~ else
			#~ {
				#~ my $line;
				#~ $line = $redis->hget( $DLGID, 'LINE' );
				#~ #spx_log ('line => '."$line");
				
				#~ # CHEQUEO QUE EL LINE TIENE VALORES VALIDOS
				#~ if ($line == 'NUL')
				
				#~ {
					#~ spx_log('READ_DLG_DATA => LINE DEL DATALOGGER CON VALOR INVALIDO');
					#~ #
					#~ #
					#~ my $EXISTS = $redis->hexists("$DLGID", "LAST_LINE");
					#~ if ($EXISTS == 1)
					#~ {
						#~ # RECUPERO EL LINE A PARTIR DEL ULTIMO GUARDADO
						#~ my $last_line = $redis->hget( $DLGID, 'LAST_LINE' );
						#~ $redis->hset( $DLGID, 'LINE', $last_line);
						#~ #
						#~ spx_log('READ_DLG_DATA => SE RECUPERA EL LINE A PARTIR DE LAST_LINE');
					#~ }
					#~ else
					#~ {
						#~ spx_log('READ_DLG_DATA => NO SE EJECUTA EL SCRIPT');
						#~ goto quit
					#~ }
							
				#~ }
				#~ else
				#~ {
					#~ # GUARDO EL VALOR DEL ULTIMO LINE VALIDO
					#~ $redis->hset( $DLGID, 'LAST_LINE', $line );
				#~ }
			
				#~ my $line = $redis->hget( $DLGID, 'LINE' );
								
				#~ #PARSEO
				#~ my @params = split(/,/,$line);
				#~ #spx_log ('PARSEO_LINE => '."@params");
				#~ ##LECTURA DE FECHA Y HORA DEL DATO
				#~ ###FECHA
				#~ my @value = split(/=/,$params[0]);
				#~ $FECHA_DATA = $value[1];
				#~ ###HORA
				#~ $HORA_DATA = $params[1];
				#~ for($i = 2; $i < @params; $i++) 
				#~ {
					#spx_log('i = '.$i);
					#~ my @value = split(/=/,$params[$i]);
					#~ #spx_log('value = '."@value" );
					
					#~ if ($value[0] eq 'PPR')
					#~ {
						#~ $PPR = $value[1];
					#~ } 
					#~ elsif ($value[0] eq 'LTQ')
					#~ {
						#~ $LTQ = $value[1];
					#~ } 
					#~ elsif ($value[0] eq 'CL')
					#~ {
						#~ $CL = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'BAT')
					#~ {
						#~ $BAT = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'GA')
					#~ {
						#~ $GA = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'FE')
					#~ {
						#~ $FE = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'LM')
					#~ {
						#~ $LM = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'BD')
					#~ {
						#~ $BD = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'BP')
					#~ {
						#~ $BP = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'BY')
					#~ {
						#~ $BY = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'TM')
					#~ {
						#~ $TM = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'ABY')
					#~ {
						#~ $ABY = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'FT')
					#~ {
						#~ $FT = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'PCAU')
					#~ {
						#~ $PCAU = $value[1];
					#~ }
					#~ elsif ($value[0] eq 'bt')
					#~ {
						#~ $bt = $value[1];
					#~ }
				#~ }
			#~ }
			#~ spx_log('READ_DLG_DATA => READ DATA');
			#~ # VARIABLES DE SALIDA
			#~ ##
			#~ spx_log('READ_DLG_DATA > $FECHA_DATA = '.$FECHA_DATA);
			#~ spx_log('READ_DLG_DATA > $HORA_DATA = '.$HORA_DATA);
			#~ if (defined $PPR)
			#~ {
			#~ spx_log('READ_DLG_DATA > $PPR = '.$PPR);
			#~ }
			#~ if (defined $LTQ)
			#~ {
			#~ spx_log('READ_DLG_DATA > $LTQ = '.$LTQ);
			#~ }
			#~ if (defined $CL)
			#~ {
			#~ spx_log('READ_DLG_DATA > $CL = '.$CL);
			#~ }
			#~ if (defined $BAT)
			#~ {
			#~ spx_log('READ_DLG_DATA > $BAT = '.$BAT);
			#~ }
			#~ if (defined $GA)
			#~ {
			#~ spx_log('READ_DLG_DATA > $GA = '.$GA);
			#~ }
			#~ if (defined $FE)
			#~ {
			#~ spx_log('READ_DLG_DATA > $FE = '.$FE);
			#~ }
			#~ if (defined $LM)
			#~ {
			#~ spx_log('READ_DLG_DATA > $FE = '.$LM);
			#~ }
			#~ if (defined $BD)
			#~ {
			#~ spx_log('READ_DLG_DATA > $BD = '.$BD);
			#~ }
			#~ if (defined $BP)
			#~ {
			#~ spx_log('READ_DLG_DATA > $BP = '.$BP);
			#~ }
			#~ if (defined $BY)
			#~ {
			#~ spx_log('READ_DLG_DATA > $BY = '.$BY);
			#~ }
			#~ if (defined $TM)
			#~ {
			#~ spx_log('READ_DLG_DATA > $BY = '.$TM);
			#~ }
			#~ if (defined $ABY)
			#~ {
			#~ spx_log('READ_DLG_DATA > $ABY = '.$ABY);
			#~ }
			#~ if (defined $FT)
			#~ {
			#~ spx_log('READ_DLG_DATA > $FT = '.$FT);
			#~ }
			#~ if (defined $PCAU)
			#~ {
			#~ spx_log('READ_DLG_DATA > $PCAU = '.$PCAU);
			#~ }
			#~ if (defined $bt)
			#~ {
			#~ spx_log('READ_DLG_DATA > $bt = '.$bt);
			#~ }

		#~ }	             
 
 
	################### ESCRIBIR DATOS EN LA REDIS #####################
	sub hset
	{
		#hset($keys,$param,$value,$identifier);
		#
		 my $redis=Redis->new();		
		 my $keys = $_[0];
		 my $param = $_[1];
		 my $value = $_[2];
		 my $identifier = $_[3];
		
				
		if ((defined $keys) and (defined $param) and (defined $value))	
		{
			if (($keys ne 'NAN') or ($param ne 'NAN') or ($value ne 'NAN'))	
			{
				if (($keys ne 'nan') or ($param ne 'nan') or ($value ne 'nan'))	
				{
					if (($keys ne 'inf') or ($param ne 'inf') or ($value ne 'inf'))	
					{
						$redis->hset("$keys", "$param", $value);
					}
					else
					{
						print FILE1 "$identifier => hset: error var {\$keys = $keys}.\n";
						print FILE1 "$identifier => hset: error var {\$param = $param}.\n";
						print FILE1 "$identifier => hset: error var {\$value = $value}.\n";
						#
						spx_log("$identifier => hset: error var {\$keys = $keys}");
						spx_log("$identifier => hset: error var {\$param = $param}");
						spx_log("$identifier => hset: error var {\$value = $value}");
					}
				}
				else
				{
					print FILE1 "$identifier => hset: error var {\$keys = $keys}.\n";
					print FILE1 "$identifier => hset: error var {\$param = $param}.\n";
					print FILE1 "$identifier => hset: error var {\$value = $value}.\n";
					#
					spx_log("$identifier => hset: error var {\$keys = $keys}");
					spx_log("$identifier => hset: error var {\$param = $param}");
					spx_log("$identifier => hset: error var {\$value = $value}");
				}
			}	
			else
			{
				print FILE1 "$identifier => hset: error var {\$keys = $keys}.\n";
				print FILE1 "$identifier => hset: error var {\$param = $param}.\n";
				print FILE1 "$identifier => hset: error var {\$value = $value}.\n";
				#
				spx_log("$identifier => hset: error var {\$keys = $keys}");
				spx_log("$identifier => hset: error var {\$param = $param}");
				spx_log("$identifier => hset: error var {\$value = $value}");
			}
		}
		else
		{
			print FILE1 "$identifier => hset: missing var {\$keys = $keys}.\n";
			print FILE1 "$identifier => hset: missing var {\$param = $param}.\n";
			print FILE1 "$identifier => hset: missing var {\$value = $value}.\n";
			#
			spx_log("$identifier => hset: missing var {\$keys = $keys}");
			spx_log("$identifier => hset: missing var {\$param = $param}");
			spx_log("$identifier => hset: missing var {\$value = $value}");
		}
	}
	
	############### VER SI EXISTE UN PARAMETRO EN REDIS ################
	sub hexist
	{
		#out = hexist($keys,$param,$identifier);
		#out = 1 => exits
		#	 = 0 => don't exist
		 my $redis=Redis->new();		
		 my $keys = $_[0];
		 my $param = $_[1];
		 my $identifier = $_[2];
		 my $EXISTS;
		 
		 if ((defined $keys) and (defined $param))	
		{
			if (($keys ne 'NAN') or ($param ne 'NAN'))	
			{
				if (($keys ne 'nan') or ($param ne 'nan'))	
				{
					if (($keys ne 'inf') or ($param ne 'inf'))	
					{
						$EXISTS = $redis->hexists("$keys", "$param");
						return ($EXISTS);
					}
					else
					{
						print FILE1 "$identifier => hexist: error var {\$keys = $keys}.\n";
						print FILE1 "$identifier => hexist: error var {\$param = $param}.\n";
						#
						spx_log("$identifier => hexist: error var {\$keys = $keys}");
						spx_log("$identifier => hexist: error var {\$param = $param}");
					}
				}
				else
				{
					print FILE1 "$identifier => hexist: error var {\$keys = $keys}.\n";
					print FILE1 "$identifier => hexist: error var {\$param = $param}.\n";
					#
					spx_log("$identifier => hexist: error var {\$keys = $keys}");
					spx_log("$identifier => hexist: error var {\$param = $param}");
				}
			}
			else
			{
				print FILE1 "$identifier => hexist: error var {\$keys = $keys}.\n";
				print FILE1 "$identifier => hexist: error var {\$param = $param}.\n";
				#
				spx_log("$identifier => hexist: error var {\$keys = $keys}");
				spx_log("$identifier => hexist: error var {\$param = $param}");
			}
		}
		else
		{	
			print FILE1 "$identifier => hexist: missing var {\$keys = $keys}.\n";
			print FILE1 "$identifier => hexist: missing var {\$param = $param}.\n";
			#
			spx_log("$identifier => hexist: missing var {\$keys = $keys}");
			spx_log("$identifier => hexist: missing var {\$param = $param}");
		}
	 }
	 
	#################### LEER UN PARAMETRO EN REDIS ####################
	sub hget
	{
		#out = hget($keys,$param,$identifier,$default);
		#
		 my $redis=Redis->new();		
		 my $keys = $_[0];
		 my $param = $_[1];
		 my $identifier = $_[2];
		 my $default = $_[3];
		 my $out;
		 my $EXISTS;
		 
		 if ((defined $keys) and (defined $param))	
		{
			if (($keys ne 'NAN') or ($param ne 'NAN'))	
			{
				if (($keys ne 'nan') or ($param ne 'nan'))	
				{
					if (($keys ne 'inf') or ($param ne 'inf'))	
					{
						$EXISTS = $redis->hexists("$keys", "$param");
						if ($EXISTS == 1)
						{
							$out = $redis->hget("$keys", "$param");
							
							if ($out eq '')
							{
								$redis->hdel("$keys", "$param");
								print FILE1 "$identifier => hget: error var {\$out = $out}.\n";
							}
							else
							{
								return ($out);
							}
						}
						else
						{
							if (defined $default)
							{
								$redis->hset("$keys", "$param", $default);
								return ($default);
							}
						}
					}
					else
					{
						print FILE1 "$identifier => hget: error var {\$keys = $keys}.\n";
						print FILE1 "$identifier => hget: error var {\$param = $param}.\n";
						#
						spx_log("$identifier => hget: error var {\$keys = $keys}");
						spx_log("$identifier => hget: error var {\$param = $param}");
					}
				}
				else
				{
					print FILE1 "$identifier => hget: error var {\$keys = $keys}.\n";
					print FILE1 "$identifier => hget: error var {\$param = $param}.\n";
					#
					spx_log("$identifier => hget: error var {\$keys = $keys}");
					spx_log("$identifier => hget: error var {\$param = $param}");
				}
			}
			else
			{
				print FILE1 "$identifier => hget: error var {\$keys = $keys}.\n";
				print FILE1 "$identifier => hget: error var {\$param = $param}.\n";
				#
				spx_log("$identifier => hget: error var {\$keys = $keys}");
				spx_log("$identifier => hget: error var {\$param = $param}");
			}
		}
		else
		{	
			print FILE1 "$identifier => hget: missing var {\$keys = $keys}.\n";
			print FILE1 "$identifier => hget: missing var {\$param = $param}.\n";
			#
			spx_log("$identifier => hget: missing var {\$keys = $keys}");
			spx_log("$identifier => hget: missing var {\$param = $param}");
		}
	 }
	 
	############### VER SI EXISTE UN PARAMETRO EN REDIS ################
		sub hdel
		{
			#out = hdel($keys,$param,$identifier);
			 my $redis=Redis->new();		
			 my $keys = $_[0];
			 my $param = $_[1];
			 my $identifier = $_[2];
			 my $EXISTS;
				 
			if ((defined $keys) and (defined $param))	
			{
				if (($keys ne 'NAN') or ($param ne 'NAN'))	
				{
					if (($keys ne 'nan') or ($param ne 'nan'))	
					{
						if (($keys ne 'inf') or ($param ne 'inf'))	
						{
							$EXISTS = $redis->hexists("$keys", "$param");
							if ($EXISTS == 1)
							{
								$redis->hdel("$keys","$param");	
							}
						}
						else
						{
							print FILE1 "$identifier => hdel: error var {\$keys = $keys}.\n";
							print FILE1 "$identifier => hdel: error var {\$param = $param}.\n";
							#
							spx_log("$identifier => hdel: error var {\$keys = $keys}");
							spx_log("$identifier => hdel: error var {\$param = $param}");
						}
					}
					else
					{
						print FILE1 "$identifier => hdel: error var {\$keys = $keys}.\n";
						print FILE1 "$identifier => hdel: error var {\$param = $param}.\n";
						#
						spx_log("$identifier => hdel: error var {\$keys = $keys}");
						spx_log("$identifier => hdel: error var {\$param = $param}");
					}
				}
				else
				{
					print FILE1 "$identifier => hdel: error var {\$keys = $keys}.\n";
					print FILE1 "$identifier => hdel: error var {\$param = $param}.\n";
					#
					spx_log("$identifier => hdel: error var {\$keys = $keys}");
					spx_log("$identifier => hdel: error var {\$param = $param}");
				}
			}
			else
			{	
				print FILE1 "$identifier => hdel: missing var {\$keys = $keys}.\n";
				print FILE1 "$identifier => hdel: missing var {\$param = $param}.\n";
				#
				spx_log("$identifier => hdel: missing var {\$keys = $keys}");
				spx_log("$identifier => hdel: missing var {\$param = $param}");
			}
		 }
	 #
	 #
	 ################### CALCULA DIFERENCIA DE TIEMPO ####################
	 sub delta_time
	 {
		#use Date::Calc;
		use Date::Manip;
		
		my $time_1;
		my $time_2;
		my $mag;
		my $identifier;
		
		$time_1 = $_[0];
		$time_2 = $_[1];
		$mag = $_[2];
		$identifier = $_[3];
		
		my $date_time_1;
		my $time_time_1;
		my $date_time_2;
		my $time_time_2;
				
		# SEPARACION DE PARAMETROS DE $time_1
			#spx_log ("\$time_1 = $time_1");
			my @params = split(/_/,$time_1);
			#spx_log ('PARSEO_LINE => '."@params");
			$date_time_1 = $params[0];
			#spx_log ("\$date_time_1 = $date_time_1");
			my @params = split(//,$date_time_1);
			#spx_log ('PARSEO_LINE => '."@params");
			$date_time_1 = $params[0].$params[1].$params[2].$params[3].'-'.$params[4].$params[5].'-'.$params[6].$params[7];
			#spx_log ("\$date_time_1 = $date_time_1");
			my @params = split(/_/,$time_1);
			#spx_log ('PARSEO_LINE => '."@params");
			$time_time_1 = $params[1];
			#spx_log ("\$time_time_1 = $time_time_1");
			my @params = split(//,$time_time_1);
			#spx_log ('PARSEO_LINE => '."@params");
			$time_time_1 = $params[0].$params[1].':'.$params[2].$params[3].':'.$params[4].$params[5];
			#spx_log ("\$time_time_1 = $time_time_1");
			$time_1 = $date_time_1.' '.$time_time_1;
			#spx_log ("\$time_1 = $time_1");
			#
		# SEPARACION DE PARAMETROS DE $time_2
			#spx_log ("\$time_2 = $time_2");
			my @params = split(/_/,$time_2);
			#spx_log ('PARSEO_LINE => '."@params");
			$date_time_2 = $params[0];
			#spx_log ("\$date_time_2 = $date_time_2");
			my @params = split(//,$date_time_2);
			#spx_log ('PARSEO_LINE => '."@params");
			$date_time_2 = $params[0].$params[1].$params[2].$params[3].'-'.$params[4].$params[5].'-'.$params[6].$params[7];
			#spx_log ("\$date_time_2 = $date_time_2");
			my @params = split(/_/,$time_2);
			#spx_log ('PARSEO_LINE => '."@params");
			$time_time_2 = $params[1];
			#spx_log ("\$time_time_2 = $time_time_2");
			my @params = split(//,$time_time_2);
			#spx_log ('PARSEO_LINE => '."@params");
			$time_time_2 = $params[0].$params[1].':'.$params[2].$params[3].':'.$params[4].$params[5];
			#spx_log ("\$time_time_2 = $time_time_2");
			$time_2 = $date_time_2.' '.$time_time_2;
			#spx_log ("\$time_2 = $time_2");
		
		# APLICO FORMATO A LAS VARIABLES DE ENTRADA 
			my $format_time_1 = ParseDate("$time_1");
			my $format_time_2 = ParseDate("$time_2");

		# CALCULO LA DIFERENCIA DE TIEMPOS
			my $delta = DateCalc($time_2 ,$time_1);
			 
		# SELECCIONO EN QUE VOY A DAR LA DIFERENCIA
			if ($mag eq 's')
			{
				$delta = int Delta_Format($delta, 1 ,"%st");
			}
			elsif ($mag eq 'm')
			{
				$delta = int Delta_Format($delta, 1 ,"%mt");
			}
			elsif ($mag eq 'h')
			{
				$delta = int Delta_Format($delta, 1 ,"%ht");
			}
			else
			{
				
			}
			
		# RETORNO LA SALIDA
			return $delta;
		 
		 
	 }
	 #
	 
	######################### ANADIR TIEMPOS ############################
	sub add_time
	{
	# PARA SUMAR TIEMPOS
	#
	use DateTime::Format::ISO8601; 	
	#
	#$out = add_time($fecha_hora,$param,add);
	#param => 	minutes
	#			hours
	#			seconds
	#			days
	#			months
	#			years
	
	# DEFINICION DE VARIABLES
		my $fecha_hora;
		my $param;
		my $fecha;
		my $hora;
		my $formated_fecha_hora;
		my $ISO_fecha_hora;
		my $out;
		my $add;
		
	# VARIABLES DE ENTRADA
		$fecha_hora = $_[0];
		$param = $_[1];
		$add = $_[2];
	
	#print "add_time < $fecha_hora\n";
	
	# MAIN
		# CONVERSION DEL FORMATO 20190809_195834 PARA 2005-09-28T21:19:44
		# SEPARACION DE PARAMETROS DE $time_1
			#spx_log ("\$time_1 = $time_1");
			my @params = split(/_/,$fecha_hora);
			#spx_log ('PARSEO_LINE => '."@params");
			$fecha = $params[0];
			#spx_log ("\$date_time_1 = $date_time_1");
			my @params = split(//,$fecha);
			#spx_log ('PARSEO_LINE => '."@params");
			$fecha = $params[0].$params[1].$params[2].$params[3].'-'.$params[4].$params[5].'-'.$params[6].$params[7];
			#spx_log ("\$date_time_1 = $date_time_1");
			my @params = split(/_/,$fecha_hora);
			#spx_log ('PARSEO_LINE => '."@params");
			$hora = $params[1];
			#spx_log ("\$time_time_1 = $time_time_1");
			my @params = split(//,$hora);
			#spx_log ('PARSEO_LINE => '."@params");
			$hora = $params[0].$params[1].':'.$params[2].$params[3].':'.$params[4].$params[5];
			#spx_log ("\$time_time_1 = $time_time_1");
			$formated_fecha_hora = $fecha.'T'.$hora;
			#print "\$formated_fecha_hora = $formated_fecha_hora\n";
			#
	
	# CONVERSION AL FORMATO ISO8601
			$ISO_fecha_hora = DateTime::Format::ISO8601->parse_datetime( $formated_fecha_hora ); 

	# SUMO EL TIEMPO NECESARIO
			#print "$fechadt\n";
			#$fechadt-> add( hours => 3 ); 
			$ISO_fecha_hora-> add( $param => $add ); 
			#print "$ISO_fecha_hora\n";
			
	# CONVERSION DEL FORMATO 20190809_195834 PARA 2005-09-28T21:19:44
			my @params = split(/T/,$ISO_fecha_hora);
			#print "PARSEO_LINE => @params\n";
			$fecha = $params[0];
			#print "PARSEO_LINE => $fecha\n";
			my @params = split(/-/,$fecha);
			#print "PARSEO_LINE => @params\n";
			$fecha = "$params[0]$params[1]$params[2]";
			#print "PARSEO_LINE => $fecha\n";
			my @params = split(/T/,$ISO_fecha_hora);
			#print "PARSEO_LINE => @params\n";
			$hora = $params[1];
			#print "PARSEO_LINE => $hora\n";
			my @params = split(/:/,$hora);
			#print "PARSEO_LINE => @params\n";
			$hora = "$params[0]$params[1]$params[2]";
			#print "PARSEO_LINE => $hora\n";
			#
			$out = $fecha.'_'.$hora;
	
	#VARIABLE DE SALIDA
			#print "add_time > $out\n";
			return $out;
	}
	
### Finalizar retornando un valor `verdadero'
1;
