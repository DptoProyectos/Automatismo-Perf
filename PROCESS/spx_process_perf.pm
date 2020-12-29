package spx_process_perf;

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
	use PERF_CONFIG;										#CONFIGURACION EN EL SERVIDOR	
	#
	use lib "$PERF_CONFIG::Library_PERF";												
	use Library_PERF;										#BIBLIOTECA DE LAS PERFORACIONES	
	#
	use Log::Handler;
	
 
BEGIN {
  use Exporter ();
  use vars qw|$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS|;
 
  $VERSION  = '1.00';  
   
  @ISA = qw|Exporter|;
 
  @EXPORT = qw|&process_perf|; 
 
  @EXPORT_OK = qw(); 
 
  %EXPORT_TAGS = ( ); 
}

# DEFINICION DE VARIABLES GLOBALES PARA ESTE PAQUETE
{
	use vars qw 
	(				
		$SW1 $SW2 $SW3	
			
		$DLGID_PERF	$TYPE $print_log $DLGID_TQ $H_MAX_TQ $N_MAX_TQ $M_ERR_SENSOR_PERF
		$M_ERR_SENSOR_TQ $P_MAX_PERF $TPOLL_CAU $MAGPP
		 
				
		$LMIN_TQ $LMAX_TQ $L_MIN_ALARM $L_MAX_ALARM 
		
		$FECHA_DATA_PERF $HORA_DATA_PERF
	
		$FECHA_DATA $HORA_DATA $FECHA_DATA_TQ $HORA_DATA_TQ								
		
		$PPR $LTQ $CL $BAT $GA $FE $LM $BD $BP $BY $TM $ABY
		$FT $PCAU $ICAU $bt
				
		$LAST_DO_0 $LAST_DO_1 $LAST_DO_2 $LAST_DO_3 
		
		$DO_0 $DO_1 $DO_2 $DO_3 $DO_4 $DO_5 $DO_6 $DO_7
		
		$GABINETE_ABIERTO $FALLA_ELECTRICA $ERR_SENSOR_PERF $ERR_SENSOR_TQ	
		$FALLA_TERMICA $EMERGENCY_STATE 
		
		$PUMP_PERF_STATE $PUMP_DOS_STATE $H_TQ $D_EXEC_PER_PUMP $M_EXEC_PER_PUMP				
		$T_EXEC_PER_PUMP $D_EXEC_DOS_PUMP $M_EXEC_DOS_PUMP $T_EXEC_DOS_PUMP 
		$P_PRESSURE	$CL_LIBRE $CAUDAL_IMP $CAUDAL_ACUM_IMP $TQ_TX_ERROR 
		$D_EXEC_PER_PUMP_ERROR $LOCAL_MODE $ALARM_STATE $ERROR_BOYA
		
		$redis $NUMERO_EJECUCION $LAST_DIA_SYSTEM $LAST_MES_SYSTEM $tq_state 
		$boya_tq_state $CURR_FECHA_SYSTEM $CURR_FECHA_SHORT $log $typeFirmware
				
	);
}
 
END { }
 
 
 
sub process_perf
{
		
################### DEFINICION DE VARIABLES #########################
#
#
# ENTRADAS DEL SOFTWARE #######################
	###ENTRADAS DE SELECCION
		$SW1 = 'AUTO';		# SWITCH { BOYA | TIMER  | REMOTO | AUTO}
		$SW2 = 'OFF';		# SWITCH MAIN PUMP {ON | OFF}		
		$SW3 = 'OFF';		# SWITCH DOSIF PUMP {ON | OFF}		
		#
		#
	###ENTRADAS DE CONFIGURACION
		$DLGID_PERF = $_[0];								# ID DATALOGGER PERFORACION 
		$TYPE = $_[1];										# TIPO DE INSTALACION {PERF_AND_TQ | PERF | TQ | OTHER }
		$print_log = $_[2];									# VER LOS LOGS => "OK"
		$DLGID_TQ = $_[3];									# ID DATALOGGER DEL TANQUE
		$H_MAX_TQ = $_[4];									# ALTURA DEL REBALSE DEL TANQUE
		$N_MAX_TQ = $_[5];									# NIVEL MAXIMO AL CUAL SE PUEDE LLENAR EL TANQUE
		$M_ERR_SENSOR_PERF = $_[6];							# SETEO MANUAL DE ERROR EN EL SENSOR DE LA PERFORACION { SI|NO }
		$M_ERR_SENSOR_TQ = $_[7];							# SETEO MANUAL DE ERROR EN EL SENSOR DEL TANQUE { SI|NO }
		$P_MAX_PERF = $_[8];								# MAXIMA PRESION DE IMPULSION DE LA PERFORACION PARA CASOS EN QUE HAYA SENSOR DE PRESION
		$TPOLL_CAU = $_[9];									# TIEMPO EN MINUTOS DEL POLEO DEL CAUDAL EN CASO DE QUE HAYA CAUDALIMETRO CONECTADO
		$MAGPP = $_[10];									#  MAGITUD QUE IDENTIFICA CUANTOS METROS CUBICOS REPRESENTAN UN PULSO {0.001 => 10 l (0.01 m3) | 0.01 => 100 l (0.1 m3) | 0.1 => 1000 l (1 m3)}
		#													# SOLO SE CONFIGURA EN CASO DE CAUDALIMETRO
		#
		#
	### CONFIGURACIONES PRESTABLECIDAS
		$LMIN_TQ = 0.5;										# NIVEL INFERIOR DE VACIADO TQ
		$LMAX_TQ = 1.0;										# NIVEL SUPERIOR DE LLENADO DEL TQ
		$L_MIN_ALARM = 0.3;									# SI LA ALTURA DEL TANQUE ES INFERIOR DE ESTE VALOR SE GENERA UNA ALARMA
		$L_MAX_ALARM = $N_MAX_TQ;							# SI LA ALTURA DEL TANQUE ES SUPERIOR DE ESTE VALOR SE GENERA UNA ALARMA	
		#
		#
	##ULTIMO DATO DEL DATALOGGER DE LA PERFORACION
	###FECHA Y HORA
		$FECHA_DATA_PERF;									# FECHA_DATA DEL ÚLTIMO DATO DE DLGID_PERF
		$HORA_DATA_PERF;									# HORA_DATA DEL ÚLTIMO DATO DE DLGID_PERF
		#
		#
	##ULTIMO DATO DEL DATALOGGER DEL TANQUE
	###FECHA Y HORA
		$FECHA_DATA_TQ;										# FECHA_DATA DEL ÚLTIMO DATO DE DLGID_TQ
		$HORA_DATA_TQ;										# HORA_DATA DEL ÚLTIMO DATO DE DLGID_TQ
		#
		#
	# ENTRADAS DEL DATALOGGER
		$FECHA_DATA;										# FECHA_DATA DEL ÚLTIMO DATO DE DLGID
		$HORA_DATA;											# HORA_DATA DEL ÚLTIMO DATO DE DLGID
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
		$ICAU;
		#
		#
	# ESTADO ANTERIOR DE LAS SALIDAS	
		$LAST_DO_0;
		$LAST_DO_1;
		$LAST_DO_2;
		$LAST_DO_3;
		#
		#
	##SALIDAS PARA EL DATALOGGER-PLC
		$DO_0;											# SALIDA CONTROL {0 -> AUTO | 1 -> REMOTO}
		$DO_1;											# BOMBA DE LA PERFORACION {0 -> OFF | 1 -> ON}	
		$DO_2;											# SALIDA CONTROL {0 -> AUTO | 1 -> REMOTO}
		$DO_3;											# BOMBA DOSIFICADORA {0 -> OFF | 1 -> ON}	
		$DO_4;											# USADA SOLO PARA LA WORD DE SALIDA
		$DO_5;											# USADA SOLO PARA LA WORD DE SALIDA	
		$DO_6;											# USADA SOLO PARA LA WORD DE SALIDA
		$DO_7;											# USADA SOLO PARA LA WORD DE SALIDA
		#				
		#
	#SALIDAS DEL SOFWARE#
	##SALIDA DE ALARMAS / TODAS ACTIVAS EN "SI"
		$GABINETE_ABIERTO = 'SI';			 	
		$FALLA_ELECTRICA = 'NO';			
		$ERR_SENSOR_PERF;
		$ERR_SENSOR_TQ;		
		$FALLA_TERMICA = 'NO';
		$EMERGENCY_STATE = 'NO';						# VARIABLE QUE SE USA PARA MOSTRAR EL BOX DE 'Trabajando con Timer'
		#
		#
	##SALIDA PARA VISUALIZACION
		$PUMP_PERF_STATE = 'ON';						# INDICA CUANDO LA BOMBA  DE LA PERFORACION ESTA ENCENDIDA (ON) O APAGADA (OFF)
		$PUMP_DOS_STATE = 'ON';							# INDICA CUANDO LA BOMBA  DOSIFICADORA ESTA ENCENDIDA (ON) O APAGADA (OFF)
		$H_TQ;											# ALTURA DEL TANQUE MEDIDA POR EL SENSOR
		$D_EXEC_PER_PUMP = 16; 							# TIEMPO DIARIO QUE HA ESTADO PRENDIDA LA BOMBA PERFORADORA
		$M_EXEC_PER_PUMP = 48; 							# TIEMPO MENSUAL QUE HA ESTADO PRENDIDA LA BOMBA PERFORADORA
		$T_EXEC_PER_PUMP = 128; 						# TIEMPO TOTAL QUE HA ESTADO PRENDIDA LA BOMBA PERFORADORA 
		$D_EXEC_DOS_PUMP = 17; 							# TIEMPO DIARIO QUE HA ESTADO PRENDIDA LA BOMBA DOSIFICADORA
		$M_EXEC_DOS_PUMP = 49;							# TIEMPO MENSUAL QUE HA ESTADO PRENDIDA LA BOMBA DOSIFICADORA
		$T_EXEC_DOS_PUMP = 129;							# TIEMPO TOTAL QUE HA ESTADO PRENDIDA LA BOMBA DOSIFICADORA
		$P_PRESSURE = 25;								# PRESION DE IMPULSION DE LA BOMBA
		$CL_LIBRE = 0.28;								# CLORO RESIDUAL LIBRE EN LINEA
		$CAUDAL_IMP = 0;								# CAUDAL INSTANTANEDO DE SALIDA DE LA BOMBA
		$CAUDAL_ACUM_IMP = 0;							# CAUDAL ACUMULADO DE SALIDA DE LA BOMBA
		$TQ_TX_ERROR = 'SI';							# INDICA CUANDO HAY ERROR DE TX EN EL TANQUE {SI|NO}		(REDIS => DLGID_TQ/TX_ERROR)
		$D_EXEC_PER_PUMP_ERROR = 'SI';					# INDICA CUANDO HAY MAS DE  18 HORAS DE FUNCIONAMIENTO DE LA BOMBA
		$LOCAL_MODE = 'SI';								# SE USA PARA SABER CUANDO SE ESTA TRABAJANDO EN  MODO LOCAL Y PODER DESACTIVAR LA INSTERFAZ DE CONFIGURACION DEL USARIO {SI|NO}
		$ALARM_STATE;									# ALARMA QUE INDICA CUANDO LA ALTURA DEL TANQUE SE VA  DE LOS VALORES QUE ESTABLECE E CLIENTE 
		$ERROR_BOYA;									# ALARMA QUE INDICA MAL FUNCIONAMIENTO EN LA BOYA 
		#
		#
	##OTRAS
		$redis=Redis->new(server => $PERF_CONFIG::rdServer, debug => 0);	# CONNECT TO REDIS
		$NUMERO_EJECUCION;								# NUMERO DE VECES QUE CORRE EL SCRIPT SIN REINICIO DEL SERVER
		$LAST_DIA_SYSTEM;								# GUARDA EL DIA DE LA ULTIMA CORRIDA DEL SCRIPT
		$LAST_MES_SYSTEM;								# GUARDA EL MES DE LA ULTIMA CORRIDA DEL SCRIPT
		$tq_state = 'EMTYING';							# GUARDA EL ESTADO EN EL QUE SE ENCONTRABA EL TANQUE PARA RECUPERARLO EN CASOS DE REINICIOS DEL DATALOGGER
		$boya_tq_state;									# GUARDA EL ESTADO DEL DE LLENADO O VACIADO DEL TANQUE CUANDO SE ESTA EN MODO BOYA
		$CURR_FECHA_SYSTEM;								# VARIABLE QUE ALMACENA LA FECHA Y HORA DEL SISTEMA
		$CURR_FECHA_SHORT;								# VARIABLE QUE ALMACENA LA FECHA DEL SISTEMA ( SOLO FECHA )
		$log = Log::Handler->new();
		


########################### MAIN RUN ###################################
#
	openLog();
	call_detection($TYPE);
	no_execution();
	fecha_system();
	read_redis();
	chequeo_alarmas();
	main();
	visual();
	count_time_pump_perf();	
	count_time_pump_dos();	
	flow_calc();
	quit:
	write_redis();
	close(FILE1);
	quit_all:
	undef_vars();
	#exit 0;
}




########################## MAIN PROGRAM ################################
sub main
{
	#
	# DESCRIPTION: 
	## FUNCION QUE CORRE EL AUTOMATISMO FUNDAMENTAL DE LAS PERFORACIONES
	#
	#
	#VARIABLES DE ENTRADA
	##
		spx_log('MAIN < $LM = '.$LM);
		spx_log('MAIN < $SW1 = '.$SW1);
		spx_log('MAIN < $TQ_TX_ERROR = '.$TQ_TX_ERROR);
		spx_log('MAIN < $ERR_SENSOR_TQ = '.$ERR_SENSOR_TQ);
		spx_log('MAIN < $ABY = '.$ABY);
		spx_log('MAIN < $FT = '.$FT);
		#
		#
	#MAIN	
	##
	# LLAMADO PARA CHEQUEAR EL SENSOR DE UNA PERFORACION
		spx_log('MAIN => CHEQUEO_SENSOR_PERF');
		##  Se llama la funcion para que se declare error en el sensor cuando vengas 2 muestras fallidas. Se recupera el error
		## cuando pasaron 6 horas continuas con muestras correctas. Esta funcion es llamada solo si la perforacion tiene sensor 
		## de presion a la salida de impulsion de la bomba.
		if (defined $PPR)
		{
			($ERR_SENSOR_PERF, $PPR) = chequeo_sensor($M_ERR_SENSOR_PERF, $DLGID_PERF, 'PERF', "$FECHA_DATA_PERF$HORA_DATA_PERF", $PPR, $P_MAX_PERF, 2, 60, 0);
		}
			#
			#
	# LLAMADO PARA CHEQUEAR EL SENSOR DE UN TANQUE
		spx_log('MAIN => CHEQUEO_SENSOR_TQ');
		##  Se llama la funcion para que se declare error en el sensor cuando vengas 2 muestras fallidas. Se recupera el error
		## cuando pasaron 6 horas continuas con muestras correctas.  
		($ERR_SENSOR_TQ, $LTQ) = chequeo_sensor($M_ERR_SENSOR_TQ, $DLGID_TQ, 'TQ', "$FECHA_DATA_TQ$HORA_DATA_TQ", $LTQ, $H_MAX_TQ, 2, 360, 0);
		#
		#
	# HACEMOS QUE CUANDO LA PERFORACION TENGA TANQUE LEJANO EL AUTOMATISMO TRABAJE CON LA PREDICCION DE DATOS
		if ($TYPE eq 'PERF') 	
		{
			$LTQ = $H_TQ;	
		}
		#
	# CHEQUEO SI SE ESTA TRABAJANDO EN MODO LOCAL POR EL TABLERO
		if ($LM == 1)
		#INHABILITO MODO REMOTO
		{
			spx_log('MAIN => TRABAJO EN MODO LOCAL DEL TABLERO');
			$LOCAL_MODE = 'SI';
		}
		#PERMITO EL MODO REMOTO
		elsif ($LM == 0)
		#SE TIENE SELECCIONADO EL MODO AUTOMATICO EN EL TABLERO
		{
			spx_log('MAIN => TRABAJO EN MODO AUTO DEL TABLERO');
			#
			$LOCAL_MODE = 'NO';		#SE LE DA LA POSIBILIDAD DE CONFIGURACION AL SISTEMA
			#
			#CHEQUEO QUE MODO ES EL QUE ESTA  SELECCIONADO EN EL SERVIDOR
			if ($SW1 eq "REMOTO")
			#MODO REMOTO SELECCIONADO
			{
				spx_log('MAIN => TRABAJO EN MODO REMOTO EN LA WEB');
				modo_remoto();
			}
			elsif ($SW1 eq "AUTO")
			#MODO AUTOMATICO SELECCIONADO
			{
				spx_log('MAIN => TRABAJO EN MODO AUTO EN LA WEB');
				if ($TQ_TX_ERROR eq 'NO')
				# CHEQUEO SI HUBO ERROR EN EL SENSOR DEL TANQUE
				{
					spx_log('MAIN => SIN ERROR TX EN EL TANQUE');
					#
					if ($ERR_SENSOR_TQ eq 'NO')	
					#CHEQUEO SI HUBO ERROR  EN EL SENSOR DEL TANQUE
					#EL SENSOR ESTA OK
					{	
						spx_log('MAIN => SIN ERROR DE SENSOR EN EL TANQUE');
						spx_log('MAIN => CONTROL SISTEMA');
						
						control_sistema();
					}
					#SENSOR DEL TANQUE CON ERROR
					elsif ($ERR_SENSOR_TQ eq 'SI')
					{	
						spx_log('MAIN => ERROR DE SENSOR EN EL TANQUE');
						#CHEQUEO SII ESTOY EN PRESENCIA DE UN TANQUE CERCANO O LEJANO A LA PERFORACION
						if ($DLGID_PERF eq $DLGID_TQ)
						#SISTEMA CON TANQUE CERCANO
						{	
							spx_log('MAIN => SISTEMA CON TANQUE CERCANO');
							spx_log('MAIN => TRABAJANDO CON SISTEMA DE EMERGENCIA');
							#DESACTIVO TODAS LAS SALIDAS
							$DO_0 = 0;			
							$DO_1 = 0;
							$DO_2 = 0;
							$DO_3 = 0;
						}
						else 
						#SISTEMA CON TANQUE LEJANO
						{
							spx_log('MAIN => SISTEMA CON TANQUE LEJANO');
							if (defined $ABY)
							{
								# VALIDO EL DATO DE LA BOYA REMOTA CON UN ERROR YA ANTES VISTO
								if ($ABY eq 'nan')
								{
									spx_log("MAIN => DATO EN BOYA DE RESPALDO NO VALIDO ABY = $ABY");
									spx_log("MAIN => PERF TRABAJANDO CON SISTEMA DE EMERGENCIA");
									$DO_0 = 0;			
									$DO_1 = 0;
									$DO_2 = 0;
									$DO_3 = 0;
								}
								else
								{
									spx_log('MAIN => SISTEMA CON AN_BOYA DE RESPALDO AL SENSOR');
									if ($ABY > 6)
									# SI ESTA CERRADA LA BOYA ENCIENDO LAS BOMBAS
									{
										spx_log('MAIN => AN_BOYA DE RESPALDO AL SENSOR CERRADA');
										spx_log('MAIN => PRENDO BOMBA DE LA PERFORACION');
										$DO_0 = 1;			
										$DO_1 = 1;
										$DO_2 = 1;
										#
										# VEO QUE NO HAYA FALLA ELECTRICA O TERMICA PARA DAR PASO A PRENDER LA DOSIFICADORA
										if ($FT == 1)
										{
											spx_log('MAIN => SISTEMA CON FALLA TERMICA');
											$DO_3 = 0;
											spx_log('MAIN => APAGO BOMBA DOSIFICADORA');
										}
										elsif ($FT == 0)
										{
											spx_log('MAIN => SISTEMA SIN FALLA TERMICA');
											$DO_3 = 1;
											spx_log('MAIN => PRENDO BOMBA DOSIFICADORA');
										}
										else
										{
											spx_log('		command error in FT');
										}
										#
									}
									else
									# SI ESTA ABIERTA LA BOYA APAGO LAS BOMBAS
									{
										spx_log('MAIN => BOYA DE RESPALDO AL SENSOR ABIERTA');
										spx_log('MAIN => APAGO BOMBA DE LA PERFORACION');
										spx_log('MAIN => APAGP BOMBA DOSIFICADORA');
										$DO_0 = 1;			
										$DO_1 = 0;
										$DO_2 = 1;
										$DO_3 = 0;
									}
								}	
											
							}
							elsif (defined $BY)
							{
								spx_log('MAIN => SISTEMA CON BOYA DE RESPALDO AL SENSOR');
								if ($BY == 1)
									# SI ESTA CERRADA LA BOYA ENCIENDO LAS BOMBAS
									{
										spx_log('MAIN => BOYA DE RESPALDO AL SENSOR CERRADA');
										spx_log('MAIN => PRENDO BOMBA DE LA PERFORACION');
										$DO_0 = 1;			
										$DO_1 = 1;
										$DO_2 = 1;
										#
										# VEO QUE NO HAYA FALLA ELECTRICA O TERMICA PARA DAR PASO A PRENDER LA DOSIFICADORA
										if ($FT == 1)
										{
											spx_log('MAIN => SISTEMA CON FALLA TERMICA');
											$DO_3 = 0;
											spx_log('MAIN => APAGO BOMBA DOSIFICADORA');
										}
										elsif ($FT == 0)
										{
											spx_log('MAIN => SISTEMA SIN FALLA TERMICA');
											$DO_3 = 1;
											spx_log('MAIN => PRENDO BOMBA DOSIFICADORA');
										}
										else
										{
											spx_log('		command error in FT');
										}
										#
									}
									else
									# SI ESTA ABIERTA LA BOYA APAGO LAS BOMBAS
									{
										spx_log('MAIN => BOYA DE RESPALDO AL SENSOR ABIERTA');
										spx_log('MAIN => APAGO BOMBA DE LA PERFORACION');
										spx_log('MAIN => APAGP BOMBA DOSIFICADORA');
										$DO_0 = 1;			
										$DO_1 = 0;
										$DO_2 = 1;
										$DO_3 = 0;
									}
							}
							else
							{
								spx_log('MAIN => SISTEMA SIN BOYA DE RESPALDO AL SENSOR');
								spx_log('MAIN => TRABAJO CON SISTEMA DE EMERGENCIA');
								#DESACTIVO TODAS LAS SALIDAS
								$DO_0 = 0;			
								$DO_1 = 0;
								$DO_2 = 0;
								$DO_3 = 0;
							}
							
						}
					}
					else 
					{
						spx_log('		command error in ERR_SENSOR_TQ');
					}
				}
				elsif ($TQ_TX_ERROR eq 'SI')
				{
					spx_log('MAIN => ERROR TX EN EL TANQUE');
					spx_log('MAIN => TRABAJO CON SISTEMA DE EMERGENCIA');
					# RESETEO LAS SALIDAS PARA QUE EL AUTOMATISMO TRABAJE CON SISTEMA DE EMERGENCIA
					$DO_0 = 0;			
					$DO_1 = 0;
					$DO_2 = 0;
					$DO_3 = 0;
				}
				else
				{
					spx_log('		command error in TQ_TX_ERROR');
				}
			}
			elsif ($SW1 eq "BOYA")
			#MODO BOYA SELECCIONADO
			{
				spx_log('MAIN => TRABAJO EN MODO BOYA EN LA WEB');
				$DO_0 = 0;
				$DO_1 = 0;
				$DO_2 = 0;
				$DO_3 = 0;
			}
			elsif ($SW1 eq "TIMER")
			#MODO TIMER SELECCIONADO
			{
				spx_log("	MODO TIMER");
				$DO_0 = 0;
				$DO_1 = 0;
				$DO_2 = 0;
				$DO_3 = 0;
			}
			else
			{
				spx_log('		command error in SW1');
			}
		
		}
		else
		{
			spx_log('		command error in LM');
		}
		

# VARIABLES DE SALIDA
	##
		spx_log('MAIN > $DO_0 = '.$DO_0);
		spx_log('MAIN > $DO_1 = '.$DO_1);
		spx_log('MAIN > $DO_2 = '.$DO_2);
		spx_log('MAIN > $DO_3 = '.$DO_3);
		#
		#
	# WRITE_BD 
	## CONTADOR DE ERRORES CONSECUTIVOS DE TX
		#
		#

}

##################### INDEFINIDOR DE VARIABLES #########################	
sub undef_vars
{
	# DESCRIPTION: Esta funcion indefine todas las variables una vez ejecutado el 
	#			script para que si el mismo se ejecuta por llamado hecho dentro de
	#			un ciclo FOR, no se arrastre para el nuevo ciclo el valor de 
	#			varibles de la corrida anterior si fuese el caso de que en el actual
	#			cliclo de corrida las mismas no tomen valores.
		#
		#
	##ENTRADAS DEL SOFTWARE #######################
	###ENTRADAS DE SELECCION
		undef $SW1;
		undef $SW2;		
		undef $SW3;	
		#
		#
	###ENTRADAS DE CONFIGURACION
		undef $DLGID_PERF;
		undef $TYPE;
		undef $print_log;
		undef $DLGID_TQ;
		undef $H_MAX_TQ;
		undef $N_MAX_TQ;
		undef $M_ERR_SENSOR_PERF;
		undef $M_ERR_SENSOR_TQ;
		undef $P_MAX_PERF;
		undef $TPOLL_CAU;
		undef $MAGPP;
		#
		#
	### CONFIGURACIONES PRESTABLECIDAS
		undef $LMIN_TQ;
		undef $LMAX_TQ;
		undef $L_MIN_ALARM;
		undef $L_MAX_ALARM;	
		#
		#
	##ULTIMO DATO DEL DATALOGGER DE LA PERFORACION
	###FECHA Y HORA
		
		undef $FECHA_DATA_PERF;
		undef $HORA_DATA_PERF;									
		#
		#
	##ULTIMO DATO DEL DATALOGGER DEL TANQUE
	###FECHA Y HORA
		undef $FECHA_DATA_TQ;									
		undef $HORA_DATA_TQ;									
		#
		#
	# ENTRADAS DEL DATALOGGER
		undef $FECHA_DATA;
		undef $HORA_DATA;
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
		undef $ICAU;
		#
		#
	# ESTADO ANTERIOR DE LAS SALIDAS	
		undef $LAST_DO_0;
		undef $LAST_DO_1;
		undef $LAST_DO_2;
		undef $LAST_DO_3;
		#
		#
	##SALIDAS PARA EL DATALOGGER-PLC
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
	#SALIDAS DEL SOFWARE#
	##SALIDA DE ALARMAS / TODAS ACTIVAS EN "SI"
		undef $GABINETE_ABIERTO;		 	
		undef $FALLA_ELECTRICA;		
		undef $ERR_SENSOR_PERF;
		undef $ERR_SENSOR_TQ;		
		undef $FALLA_TERMICA;
		undef $EMERGENCY_STATE;
		#
		#
	##SALIDA PARA VISUALIZACION
		undef $PUMP_PERF_STATE;
		undef $PUMP_DOS_STATE;
		undef $H_TQ;
		undef $D_EXEC_PER_PUMP;
		undef $M_EXEC_PER_PUMP;
		undef $T_EXEC_PER_PUMP;
		undef $D_EXEC_DOS_PUMP;
		undef $M_EXEC_DOS_PUMP;
		undef $T_EXEC_DOS_PUMP;
		undef $P_PRESSURE;
		undef $CL_LIBRE;
		undef $CAUDAL_IMP;
		undef $CAUDAL_ACUM_IMP;
		undef $TQ_TX_ERROR;
		undef $D_EXEC_PER_PUMP_ERROR;
		undef $LOCAL_MODE;
		undef $ALARM_STATE;							
		undef $ERROR_BOYA;							
		#
		#
	##OTRAS
		undef $redis;
		undef $NUMERO_EJECUCION;
		undef $LAST_DIA_SYSTEM;
		undef $LAST_MES_SYSTEM;
		undef $tq_state;
		undef $boya_tq_state;
		undef $CURR_FECHA_SYSTEM;
		undef $CURR_FECHA_SHORT;	
		undef $log;
		undef $typeFirmware;
}

####################### DETECCION DE LLAMADO ###########################
	sub call_detection
	{
		# DESCRIPTION: 
		##  Existen dos timpos de formas de llamar el spx_process_perf.pm:
		##		1-Por un call_spx_process_perf.pl.
		##		2-Por un spx_process_perf_DLGID.pl
		##  Esta funcion se encarga de detectar cual fue el .pl que llamo al spx_process_error_perf_test.
		## Para ello usa la variable $TYPE en donde si:
		##		TYPE = CHARGE 		=>>	 	El SCRIPT fue llamado por el call_spx_process_perf.pl
		##						 		  y entonces se lee la configuracion de la redis necesaria
		##						 		  para la ejecucion del spx_process_perf.pm
		##		TYPE = OTRO_CASO    =>>     EL script fue llamado por el spx_process_perf_DLGID 
		##								  y entonces se cargan las variables del mismo para usarlas
		##								  en la ejecucion del spx_process_perf.pm y las mismas
		##								  se actualizan en la redis para si despues quieres llamar al .pm 
		##								  con el call_spx_process_perf.pl	
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
			read_config_var($DLGID_PERF);
		}
		else
		{
			spx_log('CALL_DETECTION => LLAMADO DEL SCRIPT CON CONFIGURACION PRECARGADA');
			# LLAMO LA FUNCION read_var_in PARA CARGAR LAS VARIABLES PASADAS POR EL SCRIPT DE LLAMADA 
			spx_log('CALL_DETECTION => READ_VAR_IN');
			read_var_in();
			# ACTUALIZO LOS VALORES ESCRITOS EN LA REDIS
			spx_log('CALL_DETECTION => REDIS_KEYS_GEN');
			redis_keys_gen ($DLGID_PERF, $DLGID_TQ);
		}
	}
	
################ LECTURA DE VARIABLES PRECARGADAS ######################
	sub read_var_in
	{
		# DESCRIPTION: 
		##  Esta funcion simplemente deja al spx_process_perf.pm
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
			#$TYPE = $_[0];					# ID DATALOGGER PERFORACION 
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
			#spx_log('READ_VAR_IN < $TYPE = '.$TYPE);	
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
			spx_log('READ_VAR_IN > $DLGID_PERF = '.$DLGID_PERF);
			spx_log('READ_VAR_IN > $TYPE = '.$TYPE);
			spx_log('READ_VAR_IN > $DLGID_TQ = '.$DLGID_TQ);
			spx_log('READ_VAR_IN > $H_MAX_TQ = '.$H_MAX_TQ);
			spx_log('READ_VAR_IN > $N_MAX_TQ = '.$N_MAX_TQ);
			spx_log('READ_VAR_IN > $M_ERR_SENSOR_PERF = '.$M_ERR_SENSOR_PERF);
			spx_log('READ_VAR_IN > $M_ERR_SENSOR_TQ = '.$M_ERR_SENSOR_TQ);
			if($MAGPP ne 'P_MAX_PERF'){spx_log('READ_VAR_IN > $P_MAX_PERF = '.$P_MAX_PERF);}
			if($TPOLL_CAU ne ''){spx_log('READ_VAR_IN > $TPOLL_CAU = '.$TPOLL_CAU);}
			if($MAGPP ne ''){spx_log('READ_VAR_IN > $MAGPP = '.$MAGPP);}
			
	}	

############### GENERADOR DE VARIABLES DE LA REDIS #####################	
	sub redis_keys_gen
	{
		# DESCRIPTION: 
		##  Esta funcio se encarga de escribir en la redis las variables 
		## de configuracion que necesita el spx_process_perf.pm
		##
		## OJO ESTA FUNCION SE EJECUTA SOLO BAJO LAS CONDICIONES DE ESTE SCRIPT
		##
		##  La forma de llamar la funcion es la siguiente:
		## redis_keys_gen($DLGID_PERF,$DLGID_TQ);
			#
			#
		# VARIABLES DEL SISTEMA
		## VARIABLES DE ENTRADA
			$DLGID_PERF = $_[0];						# ID DATALOGGER PERFORACION 
			$DLGID_TQ = $_[1];							# ID DATALOGGER DEL TANQUE 
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
			spx_log('REDIS_KEYS_GEN < $DLGID_PERF = '.$DLGID_PERF);
			spx_log('REDIS_KEYS_GEN < $DLGID_TQ = '.$DLGID_TQ);
			#
			#
		#MAIN	
		# --------------------------------------------------------------
		## CREO EN LA REDIS TODAS LAS VARIABLES QUE VOY A UTILIZAR PARA EL SCRIPT
		#
		### VARIABLES QUE VAN EN LAS PERFORACIONES
			#### ESCRIBO LOS VALORES ENTRADOS
				#
				$redis->hset("$DLGID_PERF", 'TYPE', $TYPE);
				$redis->hset("$DLGID_PERF", 'DLGID_TQ', $DLGID_TQ);
				$redis->hset("$DLGID_TQ", 'H_MAX_TQ', $H_MAX_TQ);
				$redis->hset("$DLGID_TQ", 'N_MAX_TQ', $N_MAX_TQ);
				$redis->hset("$DLGID_PERF", 'M_ERR_SENSOR_PERF', $M_ERR_SENSOR_PERF);
				$redis->hset("$DLGID_TQ", 'M_ERR_SENSOR_TQ', $M_ERR_SENSOR_TQ);
				$redis->hset("$DLGID_PERF", 'P_MAX_PERF', $P_MAX_PERF);
				$redis->hset("$DLGID_PERF", 'TPOLL_CAU', $TPOLL_CAU);

				if ($MAGPP ne ''){$redis->hset("$DLGID_PERF", 'MAGPP', $MAGPP);}
				else{ my $EXISTS = $redis->hexists("$DLGID_PERF", "MAGPP");
					  if ($EXISTS == 1){$redis->hdel("$DLGID_PERF", 'MAGPP');}}

				if ($MAGPP ne ''){$redis->hset("$DLGID_PERF", 'TPOLL_CAU', $TPOLL_CAU);}
				else{ my $EXISTS = $redis->hexists("$DLGID_PERF", "TPOLL_CAU");
					  if ($EXISTS == 1){$redis->hdel("$DLGID_PERF", 'TPOLL_CAU');}}
				
				#
				
		# ------------------------------------------------------------------	
			#
			#
		# VARIABLES DE SALIDA
		##
		### VARIABLES QUE VAN EN LAS PERFORACIONES
			#### MUESTRO LOS VALORES ESCRITOS
				spx_log('REDIS_KEYS_GEN > TYPE = '.$TYPE);
				spx_log('REDIS_KEYS_GEN > DLGID_TQ = '.$DLGID_TQ);
				spx_log('REDIS_KEYS_GEN > H_MAX_TQ = '.$H_MAX_TQ);
				spx_log('REDIS_KEYS_GEN > N_MAX_TQ = '.$N_MAX_TQ);
				spx_log('REDIS_KEYS_GEN > M_ERR_SENSOR_PERF = '.$M_ERR_SENSOR_PERF);
				spx_log('REDIS_KEYS_GEN > M_ERR_SENSOR_TQ = '.$M_ERR_SENSOR_TQ);
				spx_log('REDIS_KEYS_GEN > P_MAX_PERF = '.$P_MAX_PERF);
				if ($TPOLL_CAU ne ''){spx_log('REDIS_KEYS_GEN > TPOLL_CAU = '.$TPOLL_CAU);}
				if ($MAGPP ne ''){spx_log('REDIS_KEYS_GEN > MAGPP = '.$MAGPP);}
				
	}
	


###################### CHEQUEO DE ALARMAS ##############################
sub chequeo_alarmas
{
	# ACTIVO LAS ALARMAS EN FUNCION DEL ESTADO DE LAS ENTRADAS DIGITALES
	spx_log( 'CHEQUEO DE ALARMAS');
	#CHEQUEO DEL ESTADO DE LA PUERTA DEL GABINETE
	if ($GA == 1)
	{
		$GABINETE_ABIERTO = 'SI';
		spx_log( "		GABINETE ABIERTO");
	}
	elsif ($GA == 0)
	{
		$GABINETE_ABIERTO = 'NO';
	}
	else
	{
		spx_log('		command error in GA');
		$GABINETE_ABIERTO = 'NO';
	}
	
	#CHEQUEO DE FALLA ELECTRICA
	if ($FE == 1)
	{
		$FALLA_ELECTRICA = 'SI';     
		spx_log( "		FALLA ELECTRICA");
	}
	elsif ($FE == 0)
	{
		$FALLA_ELECTRICA = 'NO';
	}
	else
	{
		spx_log('		command error in FE');
		$FALLA_ELECTRICA = 'NO';
	}
		#
		#
	# ------------------------------------------------------------------
	# CHEQUEO DE FALLA TERMICA
		my $last_state_falla_termica;
		## READ_BD
		### LEO EL PARAMETRO last_state_falla_termica
			my $EXISTS = $redis->hexists("$DLGID_PERF", "last_state_falla_termica");
			if ($EXISTS == 1)
			### Si exsite leo el parametro
			{
				$last_state_falla_termica = $redis->hget("$DLGID_PERF", "last_state_falla_termica");
				# Me aseguro de que no se lea un valor vacio en la Redis
				if ($last_state_falla_termica eq '')
				{
					# En caso de que exista con valor '' indefino la variable
					undef $last_state_falla_termica;
				}
			}
			#
			#
		# ESTADO DE LAS VARIABLES DE ENTRADA
		##
		spx_log('VISUAL > $DLGID_PERF = '.$DLGID_PERF);
		spx_log('VISUAL > $FT = '.$FT);
		spx_log('VISUAL > $BP = '.$BP);
		if (defined $last_state_falla_termica)
		{
			spx_log('VISUAL > $last_state_falla_termica = '.$last_state_falla_termica);
		}
			#
			#
		# MAIN	
		##
		if ($FT == 1)
		{
			$FALLA_TERMICA = "SI";
			spx_log('VISUAL => SISTEMA CON FALLA TERMICA');
			$last_state_falla_termica = 'SI';
		}
		elsif ($FT == 0)
		{
			if (defined $last_state_falla_termica)
			{
				spx_log('VISUAL => HUBO FALLA TERMICA EN EL ULTIMO ENCENDIDO DE LA BOMBA');
				if ($BP == 0)
				{
					$FALLA_TERMICA = "SI";
					spx_log('VISUAL => SISTEMA CON FALLA TERMICA');
				}
				elsif ($BP == 1)
				{
					$FALLA_TERMICA = "NO";
					undef $last_state_falla_termica;
				}
			}
			else
			{
				$FALLA_TERMICA = "NO";
				spx_log('VISUAL => SISTEMA SIN FALLA TERMICA');
			}
		}
		else
		{
			spx_log('		command error in FT');
			$FALLA_TERMICA = "NO";
		}
			#
			#
		# VARIABLES DE SALIDA
		##
		spx_log('VISUAL > $FALLA_TERMICA = '.$FALLA_TERMICA);
		if (defined $last_state_falla_termica)
		{
			spx_log('VISUAL > $last_state_falla_termica = '.$last_state_falla_termica);
		}
			#
			#
		# WRITE_BD 
		## ESCRIBO EL VALOR DE last_state_falla_termica
		if (defined $last_state_falla_termica)
		{
			$redis->hset("$DLGID_PERF", "last_state_falla_termica", 'SI');
		}
		else
		{
			my $EXISTS = $redis->hexists("$DLGID_PERF", "last_state_falla_termica");
			if ($EXISTS == 1)
			{
				$redis->hdel("$DLGID_PERF", "last_state_falla_termica");
				spx_log('VISUAL => ELIMINO EL ESTADO DE LA FALLA TERMICA');
			}
		}
	# ------------------------------------------------------------------
}

########################### MODO REMOTO ################################
sub modo_remoto
{
	# ACTIVO O APAGO LAS BOMBAS EN FUNCION DE LOS SWITCHES QUE SELECCIONA EL  USUARIO
	spx_log('	MODO REMOTO');
	$DO_0 = 1;
	$DO_2 = 1;
	if ($SW2 eq 'ON')
	{
		$DO_1 = 1;		#PRENDER LA MAIN PUMP
		spx_log('		PRENDER BOMBA PRINCIPAL');
		#
		if ($SW3 eq 'ON')
		{
			# PRENDO LA DOIFICADORA SOLO CUANDO LA BOMBA PRINCIPAL HAYA PRENDIDO
			if (($FALLA_ELECTRICA eq 'SI') or ($FALLA_TERMICA eq 'SI')) 
			{
				$DO_3 = 0;
				spx_log('		APAGO BOMBA DOSIFICADORA POR FALLA ELECTRICA O TERMICA');
			}
			else
			{
				$DO_3 = 1;
				spx_log("		PRENDO BOMBA DOSIFICADORA");
			}	
		
		}
		elsif ($SW3 eq 'OFF')
		{
			$DO_3 = 0;		#APAGAR LA BOMBA DOSIFICADORA
			spx_log('		APAGAR BOMBA DOSIFICADORA');
		}
		else
		{
			spx_log('		command error in SW3');
		}
		#
	}
	elsif ($SW2 eq "OFF")
	{
		$DO_1 = 0;		#APAGAR LA MAIN PUMP
		$DO_3 = 0;		#APAGAR LA BOMBA DOSIFICADORA
		spx_log('		APAGAR BOMBA PRINCIPAL');
		spx_log('		APAGAR BOMBA DOSIFICADORA');
	}
	else
	{
		spx_log('		command error in SW2');
	}
	
	
}

###################### CHEQUEO DE SENSORES #############################
sub chequeo_sensor
{
	# DESCRIPTION: 
	##  Esta funcion se encarga de detectar errores en los sensores. Lo forma de 
	## deteccion es comparar la lectura del mismo y ver si esta por debajo de -0.1 
	## o si esta 0.5 unidades por encima de un valor prefijado (max_value). Cualquiera 
	## de estas situaciones van a hacer que se comience un proceso de alarmado del sensor
	## que culmina seteando una alamarma (alarma_error = 'SI') despues de haber ocurrido
	## un numero consecutivo de muestras con error (sample_with_error). Una vez alarmado 
	## el sensor por mal funcionamiento, si el mismo comienza a medir de forma correcta
	## se comienza un proceso de restablecimiento del sensor que culmuna levantando la
	## alarma de error (alarma_error = 'NO') despues de haber pasado un numero de muestras 
	## (sample_without_error) consecutivas sin error. Cuando se detecta una muestra con error
	## se mantiene el valor a la salida que habia anteriormente. Cuando se activa la alarma 
	## de error del sensor el valor a la salida toma el valor que se le entro en value_error.
	##
	##  La forma de llamar la funcion es la siguiente:
	## ($alarma_error, $valor_out) = chequeo_sensor($M_ERR_SENSOR_TQ, $KEY, $suffix, $value, $max_value, $sample_with_error, $sample_without_error, $value_error);
	## donde:
	## ENTRADA
	## -M_ERR_SENSOR_TQ			=>		{ SI | NO }
	##									Es una variable que va a permitir setear un error
	##									en el sensor de forma manual. Esto puede ser util 
	##									cuando sabemos que el sensor esta trabajando mal, 
	##									sin embargo no se trata de un error detectable en esta
	##									rutina. Tambien es util cuando despues de cambiar el 
	##									sensor necesitamos eliminar a alarma y no esperar el
	##									el tiempo de restablecimiento. Para este caso simplemente,
	##									una vez cambiado el sensor pasamos esta variable a 'SI', 
	##									corremos el programa y luego la pasamos a 'NO'. Con esto
	##									queda eliminada la alarma.
	## -KEY						=>		{ name_KEY }
	##									Es la Keys de la redis en donde se van a guardar todas las
	##									variables en memoria que usa este script.
	## -suffix					=>      { name_suffix }
	##									Es un sufijo que se le van a poner a todas las variables 
	##									que este script guarda en la REDIS. Esto con el objetivo de 
	##									poder hacer el chequeo de mas de un sensor en un mismo script
	##									y que estos no interfieran.
	## -data_id					=>		{ fecha_hora }
	##									Valor que identifica a cada dato y que permite difereciar entre
	##									un dato nuevo y el mismo dato {Se recomienda fecha y hora}. 
	## 									Cuando se le setea un valor de '-1' este parametro no se tiene 
	##									en cuenta.
	## -value					=>		{ sensor_read }
	##									Lectura actual del sensor.
	## -max_value				=>		{ max_read_sensor }
	##									Maximo valor que pudiera dar el sensor segun las condiciones
	##  								de instalacion del mismo.
	## -sample_with_error		=>		{ 1 | 2 | .... n }
	##									Numero de muestras continuas con error que van a provocar que
	##									se alarme el sensor.
	## -sample_without_error	=>		{ 1 | 2 | .... n }
	##									Numero de muestras continuas sin error que van a provocar que
	##									se levante la alarma del sensor.
	## -value_error				=>		{ value_error }		
	##									Valor que va a retornar la salida de la funcion (valor_out) en 
	##									caso de ocurrir alarma en el sensor  	
	## DALIDA
	## -alarma_error			=>		{ SI | NO }
	##									Si le asigna a esta variable el valor 'SI' cuando se detecta un
	##									error en el sensor.
	## -valor_out				=>      { valor_out }
	##									Este valor es el valor de entrada del sensor siempre que no se 
	##									error en el sensor. En caso de detectarse error en el sensor en
	##									esta variable se carga el valor de entrada (value).
	##
	## EJEMPLO REAL DE LLAMADO
	## ($ERR_SENSOR_TQ, $LTQ) 		= chequeo_sensor($M_ERR_SENSOR_TQ, $DLGID_TQ, $type, $LTQ, $H_MAX_TQ, 2, 360, 0);
	## ($ERR_SENSOR_PERF, $PPR) = chequeo_sensor($M_ERR_SENSOR_PERF, $DLGID_PERF, 'PERF', "$FECHA_DATA_PERF$HORA_DATA_PERF", $PPR, $P_MAX_PERF, 2, 60, 0);
	
		#
		#
	# VARIABLES DEL SISTEMA
	## VARIABLES DE ENTRADA
	my $M_ERR_SENSOR = $_[0];
	my $DLGID = $_[1];
	my $suffix = $_[2];
	my $data_id = $_[3];
	my $value = $_[4];
	my $max_value = $_[5];
	my $sample_with_error = $_[6];
	my $sample_without_error =  $_[7];
	my $error_value = $_[8];
		#
	##  VARIABLES USADAS EN LA FUNCION
	my $last_data_id;
	my $cont_error_sensor;
	my $cont_fix_error_sensor;
	my $ERR_SENSOR;
	my $value_out;
	my $last_m_err_sensor;
	my $last_value;
		#
		#
	# READ_BD
	## SI NO EL IDENTIFICADOR DEL DATO ES NO ES '-1' LEO EL DATO
	if ($data_id != '-1')
	{
		## LEO EL PARAMETRO last_data_id
		my $EXISTS = $redis->hexists("$DLGID", "last_data_id_$suffix");
		if ($EXISTS == 1)
		### Si exsite leo el parametro
		{
			$last_data_id = $redis->hget("$DLGID", "last_data_id_$suffix");
			# Me aseguro de que no se lea un valor vacio en la Redis
			if ($last_data_id == '')
			{
				# En caso de valor vacio le asigno una fecha para iniciar de forma correcta la comparacion
				$last_data_id = '19900825013000';
			}
		}
	}
	### Si no existe le asigno una fecha para iniciar la comparacion
	else
	{
		$last_data_id = '19900825_013000';
	}
		#
	## LEO EL PARAMETRO last_m_err_sensor
	my $EXISTS = $redis->hexists("$DLGID", "last_m_err_sensor_$suffix");
	if ($EXISTS == 1)
	### Si exsite leo el parametro
	{
		$last_m_err_sensor = $redis->hget("$DLGID", "last_m_err_sensor_$suffix");
		# Me aseguro de que no se lea un valor vacio en la Redis
		if ($last_m_err_sensor == '')
		{
			$last_m_err_sensor = 'NO';
		}
	}
		#
	## LEO EL PARAMETRO cont_error_sensor
	my $EXISTS = $redis->hexists("$DLGID", "cont_error_sensor_$suffix");
	if ($EXISTS == 1)
	### Si exsite leo el parametro
	{
		$cont_error_sensor = $redis->hget("$DLGID", "cont_error_sensor_$suffix");
		# Me aseguro de que no se lea un valor vacio en la Redis
		if ($cont_error_sensor == '')
		{
			$cont_error_sensor = 0;
		}
	}
		#
	## LEO EL PARAMETRO cont_fix_error_sensor
	my $EXISTS = $redis->hexists("$DLGID", "cont_fix_error_sensor_$suffix");
	if ($EXISTS == 1)
	### Si exsite leo el parametro
	{
		$cont_fix_error_sensor = $redis->hget("$DLGID", "cont_fix_error_sensor_$suffix");
		# Me aseguro de que no se lea un valor vacio en la Redis
		if ($cont_fix_error_sensor == '')
		{
			$cont_fix_error_sensor = 0;
		}
	}
		#
	## LEO EL PARAMETRO last_value
	my $EXISTS = $redis->hexists("$DLGID", "last_value_$suffix");
	if ($EXISTS == 1)
	### Si exsite leo el parametro
	{
		$last_value = $redis->hget("$DLGID", "last_value_$suffix");
	}
		#
	## LEO EL PARAMETRO ERR_SENSOR
	my $EXISTS = $redis->hexists("$DLGID", "ERR_SENSOR_$suffix");
	if ($EXISTS == 1)
	### Si exsite leo el parametro
	{
		$ERR_SENSOR = $redis->hget("$DLGID", "ERR_SENSOR_$suffix");
		# Me aseguro de que no se lea un valor vacio en la Redis
		if ($ERR_SENSOR eq '')
		{
			$ERR_SENSOR = 'NO';
		}
	}
	### Si no existe lo creo con valor NO
	else
	{
		$redis->hset("$DLGID", "ERR_SENSOR_$suffix", 'NO');
		$ERR_SENSOR = 'NO';
	}
		#
		#
	# ESTADO DE LAS VARIABLES DE ENTRADA
	##
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < '.'$DLGID_'."$suffix".' = '.$DLGID);
		if (defined $last_m_err_sensor)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' < $last_m_err_sensor_'."$suffix".' = '.$last_m_err_sensor);
		}
		if (defined $cont_fix_error_sensor)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' < $cont_fix_error_sensor_'."$suffix".' = '.$cont_fix_error_sensor);
		}
		if (defined $cont_fix_error_sensor)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' < $cont_fix_error_sensor_'."$suffix".' = '.$cont_fix_error_sensor);
		}
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $ERR_SENSOR_'."$suffix".' = '.$ERR_SENSOR);
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $M_ERR_SENSOR_'."$suffix".' = '.$M_ERR_SENSOR);
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $data_id_'."$suffix".' = '.$data_id);
		if (defined $last_data_id)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' < $last_data_id_'."$suffix".' = '.$last_data_id);
		}
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $VALUE_SENSOR_'."$suffix".' = '.$value);
		if (defined $last_value)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' < $last_value_'."$suffix".' = '.$last_value);
		}
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $MAX_VALUE_SENSOR_'."$suffix".' = '.$max_value);
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $sample_with_error = '.$sample_with_error);
		spx_log('CHEQUEO_SENSOR_'.$suffix.' < $sample_without_error = '.$sample_without_error);
		#
		#
	#MAIN	
	# ------------------------------------------------------------------
	##
			# CHEQUEO SI ESTA ACTIVADO EL SETEO MANUAL DEL ERROR DEL SENSOR
			if ($M_ERR_SENSOR eq 'SI')
			{
				spx_log("CHEQUEO_SENSOR_$suffix => SENSOR $suffix CON ERROR MANUAL");
				$ERR_SENSOR = 'SI';
				$last_m_err_sensor = 'SI'
				
			}
			elsif ($M_ERR_SENSOR eq 'NO')
			{
				spx_log("CHEQUEO_SENSOR_$suffix => SENSOR $suffix SIN ERROR MANUAL");
				if (defined $last_m_err_sensor)
				{
					spx_log("CHEQUEO_SENSOR_$suffix => SE ESTABLECIO MANUALMENTE QUE NO HAY ERROR DE SENSOR");
					# se elimina el contador de recuperacion del sensor porque aparecio un nuevo error.
					## leo si existe el contador
					my $EXISTS = $redis->hexists("$DLGID", "last_m_err_sensor_$suffix");
					if ($EXISTS == 1)
					### elimino el contador
					{
						$redis->hdel("$DLGID", "last_m_err_sensor_$suffix");
						spx_log("CHEQUEO_SENSOR_$suffix => ELIMINO EL LAST STATE last_m_err_sensor_$suffix");
						undef $last_m_err_sensor;
						# seteo la alarma de error del sensor
						$ERR_SENSOR = 'NO';
					}
				}
				else
				{
					# CHEQUEO SI EL DATO QUE ESTOY LEYENDO EN UN DATO NUEVO O ESTA DESACTIVADA ESTA FUNCION POR EL USUARIO
					if (($last_data_id != $data_id ) or ( $data_id eq '-1'))
					{	
						if ($last_data_id != $data_id )
						{
							spx_log("CHEQUEO_SENSOR_$suffix => DATO NUEVO");
						}
						if ( $data_id eq '-1')
						{
							spx_log("CHEQUEO_SENSOR_$suffix => ID DEL DATO IGUAL A -1");
						}
						
						spx_log("CHEQUEO_SENSOR_$suffix => SE CHEQUEA EL SENSOR EN BUSCA DE ERRORES");
							#
							#
						# CHEQUEO SI EL VALOR DEL SENSOR ES MAYOR de 50cm del max_value O 0.1 cm MENOR QUE CERO
						if (($value < -0.1) or ($value > ($max_value+0.5)) or ($value eq 'inf'))
						{
							# Guardo el valor del sensor que esta generando la activacion del la alarma.
							$redis->hset("$DLGID","value_error_sensor_$suffix", $value);
							
							spx_log("CHEQUEO_SENSOR_$suffix => MUESTRA DEL SENSOR $suffix CON ERROR [sensor = $value]");
							# mantengo a la salida el valor del dato anterior
							$value_out = $last_value;
								#
							# se elimina el contador de recuperacion del sensor porque aparecio un nuevo error.
							## leo si existe el contador
							my $EXISTS = $redis->hexists("$DLGID", "cont_fix_error_sensor_$suffix");
							if ($EXISTS == 1)
							### elimino el contador
							{
								$redis->hdel("$DLGID", "cont_fix_error_sensor_$suffix");
								spx_log("CHEQUEO_SENSOR_$suffix => ELIMINO EL CONTADOR cont_fix_error_sensor_$suffix");
								undef $cont_fix_error_sensor;
							}
								#
							if ($ERR_SENSOR eq 'NO')
							{
								spx_log("CHEQUEO_SENSOR_$suffix => SE INICIA PROCESO PARA ACTIVAR LA ALARMA DEL SENSOR");
								if (defined $cont_error_sensor)
								{
									if ($cont_error_sensor >= ($sample_with_error-1))
									{
										spx_log("CHEQUEO_SENSOR_$suffix => SE ACTIVA LA ALARMA DEL SENSOR $suffix");
										$ERR_SENSOR = 'SI';
									}
									else 
									{
										$cont_error_sensor = $cont_error_sensor+1;
										spx_log("CHEQUEO_SENSOR_$suffix => INCREMENTO CONTADOR DE ERRORES DEL SENSOR");
										spx_log("CHEQUEO_SENSOR_$suffix => CONTADOR DE ERRORES DEL SENSOR $suffix = [$cont_error_sensor]");
									}
									
								}
								else
								{
									$cont_error_sensor = 1;
									spx_log("CHEQUEO_SENSOR_$suffix => INCREMENTO CONTADOR DE ERRORES DEL SENSOR");
									spx_log("CHEQUEO_SENSOR_$suffix => CONTADOR DE ERRORES DEL SENSOR $suffix = [$cont_error_sensor]");
								}
							}
							elsif ($ERR_SENSOR eq 'SI')
							{
								spx_log("CHEQUEO_SENSOR_$suffix => SENSOR $suffix CON ERROR");
									#
								# se elimina el contador de muestras con errores del sensor porque mando muestras sin error
								## leo si existe el contador
								my $EXISTS = $redis->hexists("$DLGID", "cont_error_sensor_$suffix");
								if ($EXISTS == 1)
								### elimino el contador
								{
									$redis->hdel("$DLGID", "cont_error_sensor_$suffix");
									undef $cont_error_sensor;
									spx_log("CHEQUEO_SENSOR_$suffix => ELIMINO EL CONTADOR cont_error_sensor_$suffix");
								}

							}
							else
							{
								spx_log('		command error in ERR_SENSOR_'."$suffix");
							}
						}
						else
						{
							spx_log("CHEQUEO_SENSOR_$suffix => MUESTRA DEL SENSOR $suffix SIN ERROR [$value]");
								#
							# Escribo el valor del dato analizado para tenerlo en casos futuras de fallas
							$redis->hset("$DLGID", "last_value_$suffix", $value);
								#
							# se elimina el contador de muestras con errores del sensor porque mando muestras sin error
							## leo si existe el contador
							my $EXISTS = $redis->hexists("$DLGID", "cont_error_sensor_$suffix");
							if ($EXISTS == 1)
							### elimino el contador
							{
								$redis->hdel("$DLGID", "cont_error_sensor_$suffix");
								undef $cont_error_sensor;
								spx_log("CHEQUEO_SENSOR_$suffix => ELIMINO EL CONTADOR cont_error_sensor_$suffix");
							}
							# PREGUNTO SI ANTERIORMENTE HUBO ERROR EN EL SENSOR
							if ($ERR_SENSOR eq 'SI')
							{
								spx_log("CHEQUEO_SENSOR_$suffix => SE INICIA PROCESO DE RECUPERACION DEL SENSOR");
								if (defined $cont_fix_error_sensor)
								{
									if ($cont_fix_error_sensor >= ($sample_without_error-1))
									{
										spx_log("CHEQUEO_SENSOR_$suffix => SE RECUPERA LA ALARMA DEL SENSOR $suffix");
										$ERR_SENSOR = 'NO';
									}
									else 
									{
										$cont_fix_error_sensor = $cont_fix_error_sensor+1;
										spx_log("CHEQUEO_SENSOR_$suffix => INCREMENTO CONTADOR DE RECUPERACION DEL SENSOR");
										spx_log("CHEQUEO_SENSOR_$suffix => CONTADOR DE RECUPERACION DEL SENSOR $suffix = [$cont_fix_error_sensor]");
									}
								}
								else
								{
									$cont_fix_error_sensor = 1;
									spx_log("CHEQUEO_SENSOR_$suffix => INCREMENTO CONTADOR DE RECUPERACION DEL SENSOR");
									spx_log("CHEQUEO_SENSOR_$suffix => CONTADOR DE RECUPERACION DEL SENSOR $suffix = [$cont_fix_error_sensor]");
								}
							}
							elsif ($ERR_SENSOR eq 'NO')
							{
								spx_log("CHEQUEO_SENSOR_$suffix => SENSOR $suffix SIN ERROR");
									#
								# se elimina el contador de recuperacion del sensor porque aparecio un nuevo error.
								## leo si existe el contador
								my $EXISTS = $redis->hexists("$DLGID", "cont_fix_error_sensor_$suffix");
								if ($EXISTS == 1)
								### elimino el contador
								{
									$redis->hdel("$DLGID", "cont_fix_error_sensor_$suffix");
									spx_log("CHEQUEO_SENSOR_$suffix => ELIMINO EL CONTADOR cont_fix_error_sensor_$suffix");
									undef $cont_fix_error_sensor;
								}
							}
						}
					}
					else
					{
						spx_log("CHEQUEO_SENSOR_$suffix => IDENTIFICADOR DEL DATO IGUAL QUE EL ANTERIOR");
						spx_log("CHEQUEO_SENSOR_$suffix => NO SE CHEQUEA EL SENSOR EN BUSCA DE ERRORES");
					}
				}
			}
			else
			{
				spx_log('		command error in M_ERR_SENSOR_'."$suffix");
			}
				#
				#
			# SI HAY ERROR EN EL SENSOR PONGO EL VALOR DE LA SALIDA EN EL VALOR DE ERROR
			if ($ERR_SENSOR eq 'SI')
			{
				# ponemos el valor de salida del sensor en el valor de error
				$value_out = $error_value;
			}
			else
			{
				# si no hay error en el sensor asigno el valor de salida solo si ya no se le habia asignado antes en el programa
				if (defined $value_out){}
				else
				{
					# ponemos el valor de salida del sensor el mismo valor de entrada
					$value_out = $value;
				}
			}
		
	# ------------------------------------------------------------------	
		#
		#
	# VARIABLES DE SALIDA
	##
		if (defined $last_m_err_sensor)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' < $last_m_err_sensor_'."$suffix".' = '.$last_m_err_sensor);
		}
		spx_log('CHEQUEO_SENSOR_'.$suffix.' > $ERR_SENSOR_'."$suffix".' = '.$ERR_SENSOR);
		spx_log('CHEQUEO_SENSOR_'.$suffix.' > $VALUE_SENSOR_'."$suffix".' = '.$value_out);	
		if (defined $cont_error_sensor)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' > $cont_error_sensor_'."$suffix".' = '.$cont_error_sensor);
		}
		if (defined $cont_fix_error_sensor)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' > $cont_fix_error_sensor_'."$suffix".' = '.$cont_fix_error_sensor);
		}
		if ($data_id != '-1')
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' > $last_data_id_'."$suffix".' = '.$data_id);
		}
		if (defined $last_value)
		{
			spx_log('CHEQUEO_SENSOR_'.$suffix.' > $last_value_'."$suffix".' = '.$last_value);
		}
		#
		#
	# WRITE_BD 
		### ESCRIBO EL VALOR DE last_data_id
		#### Analizo si el usuario le paso el valor de -1
		if ($data_id != '-1')
		{
			# escribo el valor del id del dato que acabamos de analizar
			$redis->hset("$DLGID", "last_data_id_$suffix", "$data_id" );
		}
		else
		{
			# Si el valor existe en la redis y se le cargo -1 al id elimino el valor de la redis
			my $EXISTS = $redis->hexists("$DLGID", "last_data_id_$suffix");
			if ($EXISTS == 1)
			{
				spx_log("CHEQUEO_SENSOR_$suffix => VALOR ID DEL DATO '-1'");
				spx_log("CHEQUEO_SENSOR_$suffix => ELIMINO EL ID DEL DATO ANALIZADO DE LA REDIS");
				$redis->hdel("$DLGID", "last_data_id_$suffix");
			}
		}
			#
		### ESCRIBO EN REDIS EL VALOR DE ERR_SENSOR_TQ
		$redis->hset("$DLGID", "ERR_SENSOR_$suffix", "$ERR_SENSOR");
			#
			#
		### ESCRIBO EN REDIS EL VALOR DE last_m_err_sensor_tq
		if (defined $last_m_err_sensor)
		{
			$redis->hset("$DLGID", "last_m_err_sensor_$suffix", $last_m_err_sensor);
		}
		### ESCRIBO EN REDIS EL VALOR DE cont_error_sensor
		if (defined $cont_error_sensor)
		{
			$redis->hset("$DLGID", "cont_error_sensor_$suffix", $cont_error_sensor );
		}
		### ESCRIBO EN REDIS EL VALOR DE cont_fix_error_sensor
		if (defined $cont_fix_error_sensor)
		{
			$redis->hset("$DLGID", "cont_fix_error_sensor_$suffix", $cont_fix_error_sensor );
		}
	return ($ERR_SENSOR,$value_out);
}

###################### CONTROL DEL SISTEMA #############################
sub control_sistema
#  CUANDO SE LE SEDE EL CONTRO AL SISTEMA, SE PRENDEN LAS BOMBAS DE LA PERFORACION Y LA DOSIFICADORA CUANDO 
# EL NIVEL DEL AGUA DEL TANQUE BAJA POR DEBAJO DE NIVEL MINIMO SELECCIONADO POR EL CLIENTE. LAS MISMAS APAGAN
# CUANDO EL NIVEL DE AGUA ALCANZA EL NIVEL MAXIMO SELECCIONADO POR EL CLIENTE.
{
	#VARIABLES DE ENTRADA
	##
		spx_log('CONTROL SISTEMA < $LTQ = '.$LTQ);
		spx_log('CONTROL SISTEMA < $LMIN_TQ = '.$LMIN_TQ);
		spx_log('CONTROL SISTEMA < $FT = '.$FT);
		spx_log('CONTROL SISTEMA < $LMAX_TQ = '.$LMAX_TQ);
		spx_log('CONTROL SISTEMA < $tq_state = '.$tq_state);
		#
		#
	# ACRIVAMOS LAS SALIDAS DE CONTROL
		$DO_0 = 1;	#EL CONTROL LO TOMA EL SISTEMA
		$DO_2 = 1;	#EL CONTROL LO TOMA EL SISTEMA
		#
		#
	#CONDICION DE ENCENDIDO DE LA BOMBA
	if ($LTQ < $LMIN_TQ)
	#ENCIENDO LA BOMBA PORQUE BAJO EL NIVEL DEL AGUA
	{
		spx_log('CONTROL SISTEMA => LTQ < LMIN_TQ');
		$DO_1 = 1;
		spx_log('CONTROL SISTEMA => PRENDO BOMBA DE LA PERFORACION');
		#
		# VEO QUE NO HAYA FALLA TERMICA PARA DAR PASO A PRENDER LA DOSIFICADORA
		if ($FT == 1) 
		{
			spx_log('CONTROL SISTEMA => SISTEMA CON FALLA TERMICA');
			$DO_3 = 0;
			spx_log('CONTROL SISTEMA => APAGO BOMBA DOSIFICADORA');
		}
		elsif ($FT == 0) 
		{
			spx_log('CONTROL SISTEMA => SISTEMA SIN FALLA TERMICA');
			$DO_3 = 1;
			spx_log('CONTROL_SISTEMA => PRENDO BOMBA DOSIFICADORA');
		}
		else
		{
			spx_log('		command error in FT');
		}
		#		
		# GUARDO QUE EL TANQUE COMIENZA UN PROCESO DE LLENADO
		$tq_state = 'FILLING';
	}
	#CONDICION DE APAGADO DE LA BOMBA
	elsif ($LTQ > $LMAX_TQ)
	#APAGO LA BOMBA PORQUE EL NIVEL DEL TANQUE ESTA ALTO
	{
		spx_log('CONTROL SISTEMA => LTQ > LMAX_TQ');
		$DO_1 = 0;
		spx_log('CONTROL SISTEMA => APAGO BOMBA DE LA PERFORACION');
		$DO_3 = 0;
		spx_log('CONTROL SISTEMA => APAGO BOMBA DOSIFICADORA');
		# GUARDO QUE EL TANQUE COMIENZA UN PROCESO DE VACIADO
		$tq_state = 'EMTYING';
	}
	else
	{
		spx_log('CONTROL SISTEMA => LMIN_TQ < LTQ < LMAX_TQ');
		# RESTABLEZO EL ESTADO DE LAS SALIDAS
		if ($tq_state eq 'EMTYING')
		{
			spx_log('CONTROL SISTEMA => APAGO BOMBA DE LA PERFORACION');
			spx_log('CONTROL SISTEMA => APAGO BOMBA DOSIFICADORA');
			$DO_0 = 1;
			$DO_1 = 0;
			$DO_2 = 1;
			$DO_3 = 0;
		}
		elsif ($tq_state eq 'FILLING')
		{
			spx_log('CONTROL SISTEMA => PRENDO BOMBA DE LA PERFORACION');
			$DO_0 = 1;
			$DO_1 = 1;
			$DO_2 = 1;
			#
			# VEO QUE NO HAYA FALLA TERMICA PARA DAR PASO A PRENDER LA DOSIFICADORA
				if ($FT == 1) 
				{
					$DO_3 = 0;
					spx_log('CONTROL SISTEMA => APAGO BOMBA DOSIFICADORA');
				}
				elsif ($FT == 0) 
				{
					$DO_3 = 1;
					spx_log('CONTROL SISTEMA => PRENDO BOMBA DOSIFICADORA');
				}
				else
				{
					spx_log('		command error in FT');
				}
		}
		else
		{
			spx_log('		command error in tq_state');
		}
		
	}
	
	# VARIABLES DE SALIDA
	##
		spx_log('CONTROL SISTEMA > $DO_0 = '.$DO_0);
		spx_log('CONTROL SISTEMA > $DO_1 = '.$DO_1);
		spx_log('CONTROL SISTEMA > $DO_2 = '.$DO_2);
		spx_log('CONTROL SISTEMA > $DO_3 = '.$DO_3);
		spx_log('CONTROL SISTEMA > $tq_state = '.$tq_state)
		#
		#
}
#
############### LEER VARIABLES DE CONFIGURACION ########################
sub read_config_var
{
	# DESCRIPTION: 
	##  Esta funcion se encarga de cargar las variables de configuracion que 
	## va a necesitar el script para que funcione correctamente. Solo se 
	## ejecuta el scritp si cuando se le pasa el nombre del datalogger al 
	## llamar la funcion, esta lee en la redis en el KEYS de ese mismo nombre
	## y existe una variable llamada TYPE cuyo valor es PERF_AND_TQ o PERF.
	## En caso de que no ocurra lo anterior la funcion traslada su puntero hacia
	## una etiqueta llamada 'quit' que te saca del programa.
	## OJO ESTA FUNCION SE EJECUTA SOLO BAJO LAS CONDICIONES DE ESTE SCRIPT
	##
	##  La forma de llamar la funcion es la siguiente:
	## read_config_var(KEY);
	## donde:
	## ENTRADA
	## -KEY			=>		{ DLGID }
	##						Es la KEY de la redis en donde van a estar guardadas
	##						todas la variables de configuracion, incluyendo la 
	##						variable TYPE que es va a decir si se ejecuta el script
	##						o no.
	##
	## EJEMPLO REAL DE LLAMADO
	## read_config_var($DLGID_PERF);
		#
		#
	# VARIABLES DEL SISTEMA
	## VARIABLES DE ENTRADA
		my $DLGID_PERF = $_[0];					# ID DATALOGGER PERFORACION 
		#
		#
	# READ_BD
	#~ ##LEO EL PARAMETRO print_log
		#~ ###LEO SI EXISTE EL PARAMETRO
		#~ my $EXISTS = $redis->hexists("$DLGID_PERF", "print_log");
		#~ if ($EXISTS == 1)
		#~ #LEO EL PARAMETRO
		#~ {
			#~ $print_log = $redis->hget("$DLGID_PERF", "print_log");
		#~ }
		#~ else
		#~ {
			#~ # SI NO EXISTE NO MUESTRO LOS LOGS
			#~ $print_log = 'NO';
		#~ }
		
	# ESTADO DE LAS VARIABLES DE ENTRADA
	##
		spx_log('READ CONFIG VAR < $DLGID_PERF = '.$DLGID_PERF);
		#
		#
	#MAIN	
	# ------------------------------------------------------------------
	##
	# CHEQUEO SI EL LLAMADO DE LA FUNCION CORRESPONDE A UN DATALOGGER QUE ESTA EN UNA PERFORACION
		##LEO EL PARAMETRO TYPE
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "TYPE");
			if ($EXISTS == 0)
			#SI NO EXISTE NO EJECUTAMOS EL SCRIPT
			{
				# NO SE EJECUTA EL SCRIPT
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE TYPE');
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO Y CHEQUEO SI EL EQUIPO ES UNA PERFORACION
			{
				$TYPE = $redis->hget("$DLGID_PERF", "TYPE");
				if (($TYPE ne 'PERF_AND_TQ') and ($TYPE ne 'PERF'))
				{
					spx_log('READ CONFIG VAR => EL EQUIPO TESTEADO NO ES UNA PERFORACION');
					spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
					goto quit_all
				}
			}
			#
			#
		##LEO EL PARAMETRO DLGID_TQ
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "DLGID_TQ");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE DLGID_TQ');
				#
				#
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$DLGID_TQ = $redis->hget("$DLGID_PERF", "DLGID_TQ");
			}
			#
		##LEO EL PARAMETRO H_MAX_TQ
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_TQ", "H_MAX_TQ");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE H_MAX_TQ');
				#
				#
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$H_MAX_TQ = $redis->hget("$DLGID_TQ", "H_MAX_TQ");
			}
			#
		##LEO EL PARAMETRO N_MAX_TQ
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_TQ", "N_MAX_TQ");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE N_MAX_TQ');
				#
				#
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$N_MAX_TQ = $redis->hget("$DLGID_TQ", "N_MAX_TQ");
			}
			#
		##LEO EL PARAMETRO M_ERR_SENSOR_PERF
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "M_ERR_SENSOR_PERF");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE M_ERR_SENSOR_PERF');
				#
				#
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$M_ERR_SENSOR_PERF = $redis->hget("$DLGID_PERF", "M_ERR_SENSOR_PERF");
			}
			#
		##LEO EL PARAMETRO M_ERR_SENSOR_TQ
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_TQ", "M_ERR_SENSOR_TQ");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE M_ERR_SENSOR_TQ');
				#
				#
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$M_ERR_SENSOR_TQ = $redis->hget("$DLGID_TQ", "M_ERR_SENSOR_TQ");
			}
			#
		##LEO EL PARAMETRO P_MAX_PERF
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "P_MAX_PERF");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE P_MAX_PERF');
				#
				#
				#spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				#goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$P_MAX_PERF = $redis->hget("$DLGID_PERF", "P_MAX_PERF");
			}
			#
		##LEO EL PARAMETRO TPOLL_CAU
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "TPOLL_CAU");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				#spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE TPOLL_CAU');
				#
				#
				#spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				#goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$TPOLL_CAU = $redis->hget("$DLGID_PERF", "TPOLL_CAU");
			}
			#
		##LEO EL PARAMETRO MAGPP
			###LEO SI EXISTE EL PARAMETRO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "MAGPP");
			if ($EXISTS == 0)
			#SI NO EXISTE INDICO PARA QUE SE CARGUE
			{
				spx_log('READ CONFIG VAR => NO EXISTE LA VARIABLE MAGPP');
				#
				#
				spx_log('READ CONFIG VAR => NO SE EJECUTA EL SCRIPT');
				goto quit_all
			}
			else 
			#LEO EL PARAMETRO
			{
				$MAGPP = $redis->hget("$DLGID_PERF", "MAGPP");
			}
	# ------------------------------------------------------------------	
		#
		#
	# VARIABLES DE SALIDA
	##
	# MUESTRAS LAS VARIABLES DE CONFIGURACION	
	spx_log('READ CONFIG VAR > $print_log = '.$print_log);
	spx_log('READ CONFIG VAR > $TYPE = '.$TYPE);
	spx_log('READ CONFIG VAR > $DLGID_TQ = '.$DLGID_TQ);
	spx_log('READ CONFIG VAR > $H_MAX_TQ = '.$H_MAX_TQ);
	spx_log('READ CONFIG VAR > $N_MAX_TQ = '.$N_MAX_TQ);
	spx_log('READ CONFIG VAR > $M_ERR_SENSOR_PERF = '.$M_ERR_SENSOR_PERF);
	spx_log('READ CONFIG VAR > $M_ERR_SENSOR_TQ = '.$M_ERR_SENSOR_TQ);
	spx_log('READ CONFIG VAR > $P_MAX_PERF = '.$P_MAX_PERF);
	if (defined $TPOLL_CAU){spx_log('READ CONFIG VAR > $TPOLL_CAU = '.$TPOLL_CAU);}
	if (defined $MAGPP){spx_log('READ CONFIG VAR > $MAGPP = '.$MAGPP);}
	
	
	
}		
#
#################### LEER EN BASE REDIS ################################
sub read_redis
{   
##LECTURA DE PARAMETROS DE PERFORACION
#
##LEO EL PARAMETRO SW1
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "SW1");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO 
	{
		$redis->hset("$DLGID_PERF", "SW1", "$SW1");
	}
	else 
	#LEO EL PARAMETRO
	{
		$SW1 = $redis->hget("$DLGID_PERF", "SW1");
	}
	#
##LEO EL PARAMETRO SW2
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "SW2");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO
	{
		$redis->hset("$DLGID_PERF", "SW2", "$SW2");
	}
	else 
	#LEO EL PARAMETRO
	{
		$SW2 = $redis->hget("$DLGID_PERF", "SW2");
	}
	#
##LEO EL PARAMETRO SW3
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "SW3");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO
	{
		$redis->hset("$DLGID_PERF", "SW3", "$SW3");
	}
	else 
	#LEO EL PARAMETRO
	{
		$SW3 = $redis->hget("$DLGID_PERF", "SW3");
	}
	#
##LEO EL PARAMETRO H_TQ
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_TQ", "H_TQ");
	if ($EXISTS == 1)
	#LEO EL PARAMETRO
	{
		$H_TQ = $redis->hget("$DLGID_TQ", "H_TQ");
	}
	#	
##LEO EL PARAMETRO LMIN_TQ
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "LMIN_TQ");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "$LMIN_TQ"
	{
		$redis->hset("$DLGID_PERF", "LMIN_TQ", "$LMIN_TQ");
	}
	else 
	#LEO EL PARAMETRO
	{
		$LMIN_TQ = $redis->hget("$DLGID_PERF", "LMIN_TQ");
	}
	#
##LEO EL PARAMETRO LMAX_TQ
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "LMAX_TQ");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "$LMAX_TQ"
	{
		$redis->hset("$DLGID_PERF", "LMAX_TQ", "$LMAX_TQ");
	}
	else 
	#LEO EL PARAMETRO
	{
		$LMAX_TQ = $redis->hget("$DLGID_PERF", "LMAX_TQ");
		# VERIFICO QUE EL VALOR LEIDO NO SEA MAYOR QUE LA ALTURA A LA CUAL SE PUEDE LLENAR EL TANQUE
		if ($LMAX_TQ > $N_MAX_TQ)
		{
			#spx_log(' CORRIJO LA ALTURA MAXIMA DEL TANQUE ');
			# COMO LE VALOR ES MAYOR LE ASIGNO LA ALTURA MAXIMA DEL TANQUE
			$LMAX_TQ = $N_MAX_TQ;
		}
	}
	
##LEO EL PARAMETRO L_MIN_ALARM
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_TQ", "L_MIN_ALARM");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "$L_MIN_ALARM"
	{
		$redis->hset("$DLGID_TQ", "L_MIN_ALARM", "$L_MIN_ALARM");
	}
	else 
	#LEO EL PARAMETRO
	{
		$L_MIN_ALARM = $redis->hget("$DLGID_TQ", "L_MIN_ALARM");
	}
	
##LEO EL PARAMETRO L_MAX_ALARM
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_TQ", "L_MAX_ALARM");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "$L_MIN_ALARM"
	{
		$redis->hset("$DLGID_TQ", "L_MAX_ALARM", "$L_MAX_ALARM");
	}
	else 
	#LEO EL PARAMETRO
	{
		$L_MAX_ALARM = $redis->hget("$DLGID_TQ", "L_MAX_ALARM");
		# VERIFICO QUE EL VALOR LEIDO NO SEA MAYOR QUE LA ALTURA A LA CUAL SE PUEDE LLENAR EL TANQUE
		if ($L_MAX_ALARM > $N_MAX_TQ)
		{
			#spx_log(' CORRIJO EL VALOR DE ALARMA SUPERIOR ');
			# COMO EL VALOR ES MAYOR LE ASIGNO LA ALTURA MAXIMA A LA QUE SE PUEDE LLENAR EL TANQUE
			$L_MAX_ALARM = $N_MAX_TQ;
		}
	}
	
##ELIMINO EL PARAMETRO PUMP_DOS_STATE EN CASO DE QUE EXISTA EN LA REDIS CUANDO NO HAYA UNA DOSIFICADORA CONECTADA A LA PERFORACION
	if (defined $BD)
	{
		# NO HAGO NADA
	}
	else
	{
		# COMPRUEBO SI EL PARAMETRO EXISTE
		my $EXISTS = $redis->hexists("$DLGID_PERF", "PUMP_DOS_STATE");
		if ($EXISTS == 1)
		#SI EXISTE LO BORRO PARA QUE NO SE VISUALICE
		{
		$redis->hdel("$DLGID_PERF", "PUMP_DOS_STATE");
		}
	}
	#
	
##ELIMINO EL PARAMETRO P_PRESSURE EN CASO DE QUE EXISTA EN LA REDIS CUANDO NO HAYA UN SENSADO DE LA PRESION DE IMPULSION DE LA BOMBA

	if (defined $PPR)
	{
		# NO HAGO NADA
	}
	else
	{
		# COMPRUEBO SI EL PARAMETRO EXISTE
		my $EXISTS = $redis->hexists("$DLGID_PERF", "P_PRESSURE");
		if ($EXISTS == 1)
		#SI EXISTE LO BORRO PARA QUE NO SE VISUALICE
		{
		$redis->hdel("$DLGID_PERF", "P_PRESSURE");
		}
	}
	#
	## LEER LOS DATOS DEL DATALOGGER DEL TANQUE
		read_dlg_data("$DLGID_TQ");
		#
		$FECHA_DATA_TQ = $FECHA_DATA;
		$HORA_DATA_TQ = $HORA_DATA;
	# CHEQUEO QUE ME ESTE LLEGANDO EL PARAMETRO BY
	if (defined $BY)
	{
		# SI ME ESTA LLEGANDO LO INDEFINO PARA QUE NO ME INTERFIERA EN CASO DE TENER UNA PERFORACION
		#CON TIMER Y QUE LA MISMA BOMBEE AGUA PARA UN TANQUE QUE ESTE CONECTADO A OTRA PERFORACION Y ESTA TENGA BOYAS
		#undef $BY;
	}
		#
		#
	## LEER LOS DATOS DEL DATALOGGER DE LA PERFORACION
	read_dlg_data("$DLGID_PERF");
	#
	$FECHA_DATA_PERF = $FECHA_DATA;
	$HORA_DATA_PERF = $HORA_DATA;
		#
		#
	##ELIMINO PARAMETROS DE CAUDAL EN CASO DE QUE EXISTA EN LA REDIS CUANDO NO HAYA UN SENSADO DEL CAUDAL DE IMPULSION DE LA BOMBA
	if ((defined $PCAU)|(defined $ICAU))
	{

	###LEO SI EXISTE EL PARAMETRO CAUDAL_IMP
		my $EXISTS = $redis->hexists("$DLGID_PERF", "CAUDAL_IMP");
		if ($EXISTS == 0)
		#SI NO EXISTE LO CREO CON VALOR "$CAUDAL_IMP"
		{
			$redis->hset("$DLGID_PERF", "CAUDAL_IMP", "$CAUDAL_IMP");
		}
		else 
		#LEO EL PARAMETRO
		{
			$CAUDAL_IMP = $redis->hget("$DLGID_PERF", "CAUDAL_IMP");
		}
	###LEO SI EXISTE EL PARAMETRO CAUDAL_ACUM_IMP
		my $EXISTS = $redis->hexists("$DLGID_PERF", "CAUDAL_ACUM_IMP");
		if ($EXISTS == 0)
		#SI NO EXISTE LO CREO CON VALOR "$CAUDAL_IMP"
		{
			$redis->hset("$DLGID_PERF", "CAUDAL_ACUM_IMP", "$CAUDAL_ACUM_IMP");
		}
		else 
		#LEO EL PARAMETRO
		{
			$CAUDAL_ACUM_IMP = $redis->hget("$DLGID_PERF", "CAUDAL_ACUM_IMP");
		}
	}
	else
	{
		# COMPRUEBO SI EL PARAMETRO CAUDAL_IMP EXISTE
		my $EXISTS = $redis->hexists("$DLGID_PERF", "CAUDAL_IMP");
		if ($EXISTS == 1)
		#SI EXISTE LO BORRO PARA QUE NO SE VISUALICE
		{
		$redis->hdel("$DLGID_PERF", "CAUDAL_IMP");
		}
		
		# COMPRUEBO SI EL PARAMETRO TPOLL_CAU EXISTE
		#my $EXISTS = $redis->hexists("$DLGID_PERF", "TPOLL_CAU");
		#if ($EXISTS == 1)
		#SI EXISTE LO BORRO PARA QUE NO SE VISUALICE
		#{
		#$redis->hdel("$DLGID_PERF", "TPOLL_CAU");
		#}

		# COMPRUEBO SI EL PARAMETRO MAGPP EXISTE
		#my $EXISTS = $redis->hexists("$DLGID_PERF", "MAGPP");
		#if ($EXISTS == 1)
		#SI EXISTE LO BORRO PARA QUE NO SE VISUALICE
		#{
		#$redis->hdel("$DLGID_PERF", "MAGPP");
		#}
		
		# COMPRUEBO SI EL PARAMETRO CAUDAL_ACUM_IMP EXISTE
		my $EXISTS = $redis->hexists("$DLGID_PERF", "CAUDAL_ACUM_IMP");
		if ($EXISTS == 1)
		#SI EXISTE LO BORRO PARA QUE NO SE VISUALICE
		{
		$redis->hdel("$DLGID_PERF", "CAUDAL_ACUM_IMP");
		}
	}
		#
		#
	#LECTURA DEL ESTADO ANTERIOR DE LAS ALARMAS
	##LEO EL PARAMETRO GABINETE_ABIERTO
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "GABINETE_ABIERTO");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "NO"
	{
		$GABINETE_ABIERTO = "NO";	
		$redis->hset("$DLGID_PERF", "GABINETE_ABIERTO", "$GABINETE_ABIERTO");
	}
	else 
	#LEO EL PARAMETRO
	{
		$GABINETE_ABIERTO = $redis->hget("$DLGID_PERF", "GABINETE_ABIERTO");
	}
	#
	##LEO EL PARAMETRO FALLA ELECTRICA
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_PERF", "FALLA_ELECTRICA");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "NO"
	{
		$FALLA_ELECTRICA = "NO";	
		$redis->hset("$DLGID_PERF", "FALLA_ELECTRICA", "$FALLA_ELECTRICA");
	}
	else 
	#LEO EL PARAMETRO
	{
		$FALLA_ELECTRICA = $redis->hget("$DLGID_PERF", "FALLA_ELECTRICA");
	}
	#
	#~ ##LEO EL PARAMETRO ERROR_SENSOR_PERF	#
	#~ ###LEO SI EXISTE EL PARAMETRO
	#~ my $EXISTS = $redis->hexists("$DLGID_PERF", "ERROR_SENSOR_PERF");	#
	#~ if ($EXISTS == 0)
	#~ #SI NO EXISTE LO CREO CON VALOR "NO"
	#~ {
		#~ $ERROR_SENSOR_PERF = "NO";		#
		#~ $redis->hset("$DLGID_PERF", "ERROR_SENSOR_PERF", "$ERROR_SENSOR_PERF");
	#~ }
	#~ else 
	#~ #LEO EL PARAMETRO
	#~ {
		#~ $ERROR_SENSOR_PERF = $redis->hget("$DLGID_PERF", "ERROR_SENSOR_PERF");
	#~ }
	#
	##LEO EL PARAMETRO ERR_SENSOR_TQ
	###LEO SI EXISTE EL PARAMETRO
	my $EXISTS = $redis->hexists("$DLGID_TQ", "ERR_SENSOR_TQ");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR "NO"
	{
		$ERR_SENSOR_TQ = "NO";	
		$redis->hset("$DLGID_TQ", "ERR_SENSOR_TQ", "$ERR_SENSOR_TQ");
	}
	else 
	#LEO EL PARAMETRO
	{
		$ERR_SENSOR_TQ = $redis->hget("$DLGID_TQ", "ERR_SENSOR_TQ");
	}
	#
	#
#LEO EL ESTADO DE LAS SALIDAS
	##LEO EL PARAMETRO DE LA REDIS Y LO CONVIERTO A BINARIO
	my $OUTPUTS_DEC = $redis->hget($DLGID_PERF,'OUTPUTS');
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
	# REGISTRO EL VALOR DE LAS SALIDAS ANTES DE QUE CAMBIEN PARA VER SI CUANDO 
	#CORRE EL PROGRAMA LAS MISMAS CAMBIAN.
	$LAST_DO_0 = @OUTPUTS[8];
	$LAST_DO_1 = @OUTPUTS[7];
	$LAST_DO_2 = @OUTPUTS[6];
	$LAST_DO_3 = @OUTPUTS[5];
	#
	#~ spx_log ("DO_0 = $DO_0");
	#~ spx_log ("DO_1 = $DO_1");
	#~ spx_log ("DO_2 = $DO_2");
	#~ spx_log ("DO_3 = $DO_3");
	#~ spx_log ("DO_4 = $DO_4");
	#~ spx_log ("DO_5 = $DO_5");
	#~ spx_log ("DO_6 = $DO_6");
	#~ spx_log ("DO_7 = $DO_7");
	#
	# LECTURA DEL DIA DE LA ULTIMA CORRIDA DEL SISTEMA
	my $EXISTS = $redis->hexists("$DLGID_PERF", "LAST_DIA_SYSTEM");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON EL DIA ACTUAL
	{
		$LAST_DIA_SYSTEM = `date +%d`;	
		$redis->hset("$DLGID_PERF", "LAST_DIA_SYSTEM", "$LAST_DIA_SYSTEM");
	}
	else 
	#LEO EL PARAMETRO
	{
		$LAST_DIA_SYSTEM = $redis->hget("$DLGID_PERF", "LAST_DIA_SYSTEM");
	}
	#
	# LECTURA DEL MES DE LA ULTIMA CORRIDA DEL SISTEMA
		my $EXISTS = $redis->hexists("$DLGID_PERF", "LAST_MES_SYSTEM");
		if ($EXISTS == 0)
		#SI NO EXISTE LO CREO CON EL MES ACTUAL
		{
			$LAST_MES_SYSTEM = `date +%m`;	
			$redis->hset("$DLGID_PERF", "LAST_MES_SYSTEM", "$LAST_MES_SYSTEM");
		}
		else 
		#LEO EL PARAMETRO
		{
			$LAST_MES_SYSTEM = $redis->hget("$DLGID_PERF", "LAST_MES_SYSTEM");
		}
		#
	#LECTURA DEL ESTADO DE TX DEL DATALOGGER DEL TANQUE
		my $EXISTS = $redis->hexists("$DLGID_TQ", "TX_ERROR");
		if ($EXISTS == 0)
		#SI NO EXISTE LO CREO CON VALOR NO
		{
			$TQ_TX_ERROR = 'NO';
			$TQ_TX_ERROR = $redis->hset("$DLGID_TQ", 'TX_ERROR', $TQ_TX_ERROR );
		}
		else
		{
			$TQ_TX_ERROR = $redis->hget("$DLGID_TQ", 'TX_ERROR' );
		}
	
	#
	# LECTURA DEL PARAMETRO DE ESTADO ANTERIOR DEL TANQUE
	my $EXISTS = $redis->hexists("$DLGID_PERF", "tq_state");
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON EL MES ACTUAL
	{
		$redis->hset("$DLGID_PERF", 'tq_state', "$tq_state");
	}
	else 
	#LEO EL PARAMETRO
	{
		$tq_state = $redis->hget("$DLGID_PERF", 'tq_state');
	}
	
}
##################### ESCRIBIR EN BASE REDIS ###########################
sub write_redis
{
	#ESCRIBIR DIA Y MES DE LA CORRIDA ACTUAL
		$LAST_DIA_SYSTEM = `date +%d`;
		$LAST_MES_SYSTEM = `date +%m`;
		# LIMPIO CARACTERES DE NUEVA LINEA
		$LAST_DIA_SYSTEM=~s/\n//g;
		# LIMPIO CARACTERES DE NUEVA LINEA
		$LAST_MES_SYSTEM=~s/\n//g;
		$redis->hset("$DLGID_PERF", "LAST_DIA_SYSTEM", "$LAST_DIA_SYSTEM");
		$redis->hset("$DLGID_PERF", "LAST_MES_SYSTEM", "$LAST_MES_SYSTEM");
		
	# ESCRIBIR EL VALOR DEL ESTADO ANTERIOR DEL TANQUE
		$redis->hset("$DLGID_PERF", 'tq_state', "$tq_state");	
	
	# SE ESCRIBE EL UNA VARIABLE CON EL TIPO DE SISTEMA DE EMERGENCIA UTILIZADO
		if (defined $BY)
		{
			$redis->hset("$DLGID_PERF", "EMERGENCY_SYSTEM", 'BOYA');
		}
		elsif (defined $TM)
		{
			$redis->hset("$DLGID_PERF", "EMERGENCY_SYSTEM", 'TIMER');
		}
		else
		{
			my $EXISTS = $redis->hexists("$DLGID_PERF", 'EMERGENCY_SYSTEM');
			# SI EXISTE LA VARIABLE LA ELIMINO PARA QUE NO ESTE EN LA REDIS
			if ($EXISTS != 0)
			{
				$redis->hdel("$DLGID_PERF", 'EMERGENCY_SYSTEM');
			}
		}
		#
		#
	# SE ESCRIBE EL VALOR DE N_MAX_TQ EN EL TANQUE 
		$redis->hset("$DLGID_TQ", "N_MAX_TQ", "$N_MAX_TQ");
	
	#ESCRIBIR LAS ALARMAS EN LA REDIS#
		###ALARMA DE GABINETE ABIERTO
		$redis->hset( "$DLGID_PERF", GABINETE_ABIERTO => "$GABINETE_ABIERTO" );
		###ALARMA DE FALLA ELECTRICA
		$redis->hset( "$DLGID_PERF", FALLA_ELECTRICA => "$FALLA_ELECTRICA" );
		#~ ###ALARMA DE ERROR DE SENSOR DEL TANQUE
    	#~ $redis->hset( "$DLGID_TQ", ERR_SENSOR_TQ => "$ERR_SENSOR_TQ" );
    	###ALARMA DE FALLA TERMINCA
		$redis->hset( "$DLGID_PERF", FALLA_TERMICA => "$FALLA_TERMICA" );
		###ALARMA DE EMERGENCY_STATE
		$redis->hset( "$DLGID_PERF", EMERGENCY_STATE => "$EMERGENCY_STATE" );
		
	#ESCRIBIR SALIDAS PARA VISUALIZACION
		###ESCRIBIR LA ALTURA MAXIMA DEL TANQUE
		$redis->hset( "$DLGID_TQ", H_MAX_TQ => $H_MAX_TQ );
		###ESTADO DE LA BOMBA DE LA PERFORACION
		$redis->hset( "$DLGID_PERF", PUMP_PERF_STATE => "$PUMP_PERF_STATE" );
		###ESTADO DE LA BOMBA DOSIFICADORA SI LA LA PERFORACION ES DEL TIPO "CON DOSIFICADORA"
		if (defined $BD)
		{
			$redis->hset( "$DLGID_PERF", PUMP_DOS_STATE => "$PUMP_DOS_STATE" );
		}
		#
		###ESCRIBIR LA ALTURA DEL TANQUE SI EL EQUIPO ES UNA PERFORACION CON TANQUE
		if ($TYPE eq 'PERF_AND_TQ') 
		{
			if (defined $H_TQ)
			{
				$redis->hset( "$DLGID_TQ", H_TQ => "$H_TQ" );
			}
		}
		#
		###ESCRIBIR EL TIEMPO DE ENCENDIDO DIARIO DE LA BOMBA DE LA PERFORACION
		$redis->hset( "$DLGID_PERF", D_EXEC_PER_PUMP => "$D_EXEC_PER_PUMP" );
		###ESCRIBIR EL TIEMPO DE ENCENDIDO MENSUAL DE LA BOMBA DE LA PERFORACION
		$redis->hset( "$DLGID_PERF", M_EXEC_PER_PUMP => "$M_EXEC_PER_PUMP" );
		###ESCRIBIR EL TIEMPO DE ENCENDIDO TOTAL DE LA BOMBA DE LA PERFORACION
		$redis->hset( "$DLGID_PERF", T_EXEC_PER_PUMP => "$T_EXEC_PER_PUMP" );
		###ESCRIBIR EL TIEMPO DE ENCENDIDO DIARIO DE LA BOMBA DOSIFICADORA
		$redis->hset( "$DLGID_PERF", D_EXEC_DOS_PUMP => "$D_EXEC_DOS_PUMP" );
		###ESCRIBIR EL TIEMPO DE ENCENDIDO MENSUAL DE LA BOMBA DOSIFICADORA
		$redis->hset( "$DLGID_PERF", M_EXEC_DOS_PUMP => "$M_EXEC_DOS_PUMP" );
		###ESCRIBIR EL TIEMPO DE ENCENDIDO TOTAL DE LA BOMBA DOSIFICADORA
		$redis->hset( "$DLGID_PERF", T_EXEC_DOS_PUMP => "$T_EXEC_DOS_PUMP" );
		###ESCRIBIR EL VALOR DE PRESION A LA SALIDA DE LA BOMBA Y LA ALARMA DE ERROR DEL SENSOR SI LA PERFORACION ES DEL TIPO "CON SENSOR"
		if (defined $PPR)
		{
			$redis->hset( "$DLGID_PERF", P_PRESSURE => "$P_PRESSURE" );
			$redis->hset( "$DLGID_PERF", ERROR_SENSOR_PERF => "$ERR_SENSOR_PERF" );
		}
		else 
		{
			### LEO EL PARAMETRO ERROR_SENSOR_PERF Y SI EXISTE LO ELIMINO
			my $EXISTS = $redis->hexists("$DLGID_PERF", "ERROR_SENSOR_PERF");
			if ($EXISTS == 1)
			{
				$redis->hdel("$DLGID_PERF", "ERROR_SENSOR_PERF");
			}
		}
		#
		###ESCRIBIR EL VALOR DE CLORO A LA SALIDA DE LA BOMBA DE LA PERORACION SI ES EL CASO DE UNA PERFORACION DON MEDIDOR DE CLORO
		if (defined $CL)
		{
			$redis->hset( "$DLGID_PERF", CL_LIBRE => "$CL_LIBRE" );
		}
		#
		###ESCRIBIR EL VALOR DE CAUDAL A LA SALIDA DE LA BOMBA DE LA PERORACION
		if (defined $PCAU)
		{
			$redis->hset( "$DLGID_PERF", CAUDAL_IMP => "$CAUDAL_IMP" );
			$redis->hset( "$DLGID_PERF", TPOLL_CAU => "$TPOLL_CAU" );
			$redis->hset( "$DLGID_PERF", CAUDAL_ACUM_IMP => "$CAUDAL_ACUM_IMP" );
			$redis->hset( "$DLGID_PERF", MAGPP => "$MAGPP" );
		}
		###ESCRIBIR EL INDICADOR DE EXCESO DE FUNCIONAMIENTO DIARIO DE LA BOMBA DE LA PERFORACION
			$redis->hset( "$DLGID_PERF", D_EXEC_PER_PUMP_ERROR => "$D_EXEC_PER_PUMP_ERROR" );
			#
		###ESCRIBIR EL INDICADOR DE TRABAJO EN MODO LOCAL
			$redis->hset( "$DLGID_PERF", LOCAL_MODE => "$LOCAL_MODE" );
			#
		### ESCRIBO EL VALOR DEL ULTIMO DATO DEL DATALOGGER EN $LAST_FECHA_DATA
			$redis->hset( "$DLGID_PERF", LAST_FECHA_DATA => $FECHA_DATA_PERF.'_'.$HORA_DATA_PERF );
			#$redis->hset( "$DLGID_TQ", LAST_FECHA_DATA => $FECHA_DATA_TQ.'_'.$HORA_DATA_TQ );
			#
		# ESCRIBO EL VALOR DE LMAX_TQ EN LA REDIS PARA LOS CASOS EN QUE SE SELECCIONE POR EL USUARIO UN NIVEL MAYOR QUE N_MAX_TQ QUEDE VISUALIZADO EL NIVEL PERMISIBLE
			$redis->hset( "$DLGID_PERF", LMAX_TQ => $LMAX_TQ );
			#
		# ESCRIBO EL ESTADO DE LA ALARMA DEL TANQUE.
			$redis->hset( "$DLGID_TQ", ALARM_STATE => $ALARM_STATE );
			#
		# ESCRIBO EL VALOR DE L_MAX_ALARM EN LA REDIS PARA LOS CASOS EN QUE SE SELECCIONE POR EL USUARIO UN NIVEL MAYOR QUE N_MAX_TQ QUEDE VISUALIZADO EL NIVEL PERMISIBLE
			$redis->hset( "$DLGID_TQ", L_MAX_ALARM => $L_MAX_ALARM );
			#
			#
	
	# DETECTO SI HUBO CAMBIO O NO EN LAS SALIDAS UNA VEZ CORRIDO EL SCRIPT		    
    if (($DO_0 == $LAST_DO_0) and ($DO_1 == $LAST_DO_1) and ($DO_2 == $LAST_DO_2) and ($DO_3 == $LAST_DO_3))
    {
		# REGISTRO EN LA REDIS QUE NO HUBO CAMBIO EN LAS SALIDAS
		$redis->hset( "$DLGID_PERF", outputs_change => 'NO' );
	}
	else
	{
		# REGISTRO EN LA REDIS QUE HUBO CAMBIO EN LAS SALIDAS PARA ADVERTIR QUE 
		#EL ESTADO DE LAS ENTRADAS QUE APARECEN EN LINE NO CORRESPONDEN AL ESTADO DE LAS SALIDAS
		$redis->hset( "$DLGID_PERF", outputs_change => 'SI' );
	}
    
    
    
    #ESCRIBIR LAS SALIDAS PARA EL DATALOGGER
		#~ $DO_0 = 0;
		#~ $DO_1 = 0;
		#~ $DO_2 = 0;
		#~ $DO_3 = 0;
		$DO_4 = 0;
		$DO_5 = 0;
		$DO_6 = 0;
		$DO_7 = 0;
		my $OUTPUTS_WORD_BIN = "$DO_7$DO_6$DO_5$DO_4$DO_3$DO_2$DO_1$DO_0";
		my $OUTPUTS_WORD_DEC = bin2dec($OUTPUTS_WORD_BIN); 
		$redis->hset( $DLGID_PERF, "OUTPUTS", $OUTPUTS_WORD_DEC );
		#~ spx_log ("DO_0 = $DO_0");
		#~ spx_log ("DO_1 = $DO_1");
		#~ spx_log ("DO_2 = $DO_2");
		#~ spx_log ("DO_3 = $DO_3");
		#~ spx_log ("DO_4 = $DO_4");
		#~ spx_log ("DO_5 = $DO_5");
		#~ spx_log ("DO_6 = $DO_6");
		#~ spx_log ("DO_7 = $DO_7");
		
		
	
	
}


#-----------------------------------------------------------------------

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
	#$print_log = 'OK';

	my $logStr = $_[0];
	$log->info("[processPerf] [$DLGID_PERF] $_[0]");				# write a log file

	##print FILE1 "$logStr\n";
	
	if ($print_log eq "OK")
	{
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
####################### NUMERO DE EJECICION ############################
sub no_execution
{
#ESCRIBIR EN LA REDIS
	#spx_log('NO_EXECUTION');
	#ESCRIBIR NUMERO DE EJECUCION DEL SCRIPT SIN REINICIO DE LA REDIS
	my $EXISTS = $redis->hexists("$DLGID_PERF", 'NUMERO_EJECUCION');
	#my $EXISTS = $redis->hexists("$DLGID_TQ", 'NUMERO_EJECUCION');
	if ($EXISTS == 0)
	#SI NO EXISTE LO CREO CON VALOR 0
	{
		$NUMERO_EJECUCION = 0;	
		$redis->hset("$DLGID_PERF", 'NUMERO_EJECUCION', $NUMERO_EJECUCION);
		#$redis->hset("$DLGID_TQ", 'NUMERO_EJECUCION', $NUMERO_EJECUCION);
	}
	else
	{
		$redis->hincrby("$DLGID_PERF", 'NUMERO_EJECUCION', 1);
		#~ if ($DLGID_PERF ne $DLGID_TQ)
		#~ {
			#~ $redis->hincrby("$DLGID_TQ", 'NUMERO_EJECUCION', 1);
		#~ }
		#LEO EL NUMERO DE EJECUCION
		$NUMERO_EJECUCION = $redis->hget("$DLGID_PERF",'NUMERO_EJECUCION');
		
	}
	#spx_log('$NUMERO_EJECUCION => '.$NUMERO_EJECUCION);
	#TESTEADA 19/01/2019
}

################ MUESTRA PARAMETROS DE VISUALIZACION ###################
sub visual
{	
### SE ECUENTRAN LAS TAREAS RELACIONADAS CON LA VISUALIZACION
	#
# ASIGNO LA ALTURA DEL TANQUE A H_TQ SI LA PERFORACION TIENE UN TANQUE ASOCIADO
	if ($TYPE eq 'PERF_AND_TQ') 
	{
		if ($LTQ < 0)
		{
			$H_TQ = 0;
		}
		else 
		{
			$H_TQ = $LTQ;
		}
	}
	
	
	#
# ASIGNO LA LA PRESION DE SALIDA DE LA BOMBA A P_PRESSURE
	if ($PPR < 0)
	{
		$P_PRESSURE = 0;
	}
	else 
	{
		$P_PRESSURE = $PPR;
	}
	
	
	#
# ASIGNO LA MAGNITUD DE CLORO LIBRE A CL_LIBRE SI ES UNA PERFORACION CON MEDIDOR DE CLORO
	if (defined $CL)
	{
		if ($CL < 0)
		{
			$CL_LIBRE = 0;
		}
		else 
		{
			$CL_LIBRE = $CL;
		}
	}
	#
# ASIGNO EL ESTADO DE ENCENDIDO DE LA BOMBA DE LA PERFORACION
	if ($BP == 1)
	{
		$PUMP_PERF_STATE = 'ON';
	}
	elsif($BP == 0)
	{
		$PUMP_PERF_STATE = 'OFF';
	}
	else
	{
		spx_log('		command error in $BP');
	}
	#
# ASIGNO EL ESTADO DE ENCENDIDO DE LA BOMBA DOSIFICADORA
	if (defined $BD)
	{
		if ($BD == 1)
		{
			if ($BP == 1)
			{
				$PUMP_DOS_STATE = 'ON';
			}
			else
			{
				$PUMP_DOS_STATE = 'OFF';
			}
		}
		elsif($BD == 0)
		{
			$PUMP_DOS_STATE = 'OFF';
		}
		else
		{
			spx_log('		command error in $BD');
		}
	}
	#
	#
# ALARMA DEL NIVEL DEL TANQUE
	if (($LTQ < $L_MIN_ALARM) or ($LTQ > $L_MAX_ALARM))
	{
		$ALARM_STATE = 'SI';
		spx_log('	LOS NIVELES DE AGUA ESTAN FUERA DE LOS VALORES QUE SELECCIONA EL CLIENTE');
	}
	else
	{
		$ALARM_STATE = 'NO';
	}
	#
	#
# MOSTRAR BOX DE TRABAJO CON EL SISTEMA DE EMERGENCIA CUANDO HAY ERROR TX EN EL TANQUE
	if ($TQ_TX_ERROR eq 'SI')
	{
		$redis->hset("$DLGID_PERF",'EMERGENCY_STATE','SI');
	}
	else
	{
		$redis->hset("$DLGID_PERF",'EMERGENCY_STATE','NO');
	}
}

sub count_time_pump_perf	
{
	# ESTABLEZCO LOS TIEMPOS DE TRABAJO DE LA BOMBA DE LA PERFORACION
	##CHEQUEO QUE ESTEN CREADAS LAS VARIABLES A USAR PARA EL CONTEO DE TIEMPO EN LA BOMBA DE LA PERFORACION
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_15seg_perf');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_15seg_perf", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_min_perf');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_min_perf", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_hour_perf');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_hour_perf", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_month_perf');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_month_perf", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_total_perf');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_total_perf", 0);
		}
		#
	## CONTADOR DE 15 SEGUNDOS DE LA BOMBA PRENDIDA
	if ($BP == 1)
	# VEO SI LA BOMBA ESTA PRENDIDA
	{
		#~ spx_log("PASO  15 SEGUNDO CON LA BOMBA ENCENDIDA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_15seg_perf', 1);
	}
	#
	## CONTADOR DE MINUTOS DE LA BOMBA PRENDIDA
	### LEO EL CONTADOR DE 15 SEGUNDOS DE PERIODOS ENCENDIDA
	my $count_time_15seg_perf = $redis->hget("$DLGID_PERF", 'count_time_15seg_perf');
	#### CHEQUEO SI SE CUMPLIO UN MINUTO DE LA BOMBA PRENDIDA
	if ($count_time_15seg_perf >= 1)
	{
		#~ spx_log("PASO UN MINUTO CON LA BOMBA ENCENDIDA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_min_perf', 1);
		# RESETEO EL CONTADOR PARA CONTAR UN NUEVO MINUTO
		$redis->hset("$DLGID_PERF", "count_time_15seg_perf", 0);
	}
	#
	#
	## CONTADOR DE HORAS DE LA BOMBA PRENDIDA
	### LEO EL CONTADOR DE MINUTOS DE LA BOMBA PRENDIDA
	my $count_time_min_perf = $redis->hget("$DLGID_PERF", 'count_time_min_perf');
	#### CHEQUEO SI SE CUMPLIO UNA HORA DE LA BOMBA PRENDIDA
    my $CURR_DIA_SYSTEM = `date +%d`;
    # LIMPIO CARACTERES DE NUEVA LINEA
    $CURR_DIA_SYSTEM=~s/\n//g;
	#~ spx_log ('$CURR_DIA_SYSTEM =>' .$CURR_DIA_SYSTEM);
	my $CURR_MES_SYSTEM = `date +%m`;
	# LIMPIO CARACTERES DE NUEVA LINEA
	$CURR_MES_SYSTEM=~s/\n//g;
	#~ spx_log ('$CURR_MES_SYSTEM =>' .$CURR_MES_SYSTEM);
	#
	# VEO SI YA PASO UNA HORA
	if ($count_time_min_perf > 59)
	{	
		#spx_log("PASO UNA HORA CON LA BOMBA ENCENDIDA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_hour_perf', 1);
		
		#spx_log("PASO UNA HORA MENSUAL CON LA BOMBA ENCENDIDA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_month_perf', 1);
		
		#spx_log("PASO UNA HORA TOTAL DE FUNCIONAMIENTO DE LA BOMBA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_total_perf', 1);
		
		# RESETEO EL CONTADOR DE MINUTOS PARA CONTAR UNA NUEVA HORA
		$redis->hset("$DLGID_PERF", "count_time_min_perf", 0);
	}
	#
	# CHEQUEO CUANDO HAY UN CAMBIO DE DIA
	#~ spx_log ('$CURR_DIA_SYSTEM =>' .$CURR_DIA_SYSTEM);
	#~ spx_log ('$LAST_DIA_SYSTEM =>' .$LAST_DIA_SYSTEM);
	#~ spx_log ('$CURR_MES_SYSTEM =>' .$CURR_MES_SYSTEM);
	#~ spx_log ('$LAST_MES_SYSTEM =>' .$LAST_MES_SYSTEM);
	if ($CURR_DIA_SYSTEM != $LAST_DIA_SYSTEM)
	## HUBO CAMBIO DE DIA, RESETEO EL CONTADOR DE HORAS Y MINUTOS DEL DIA
	{
		$redis->hset("$DLGID_PERF", 'count_time_min_perf', 0);
		$redis->hset("$DLGID_PERF", 'count_time_hour_perf', 0);
	}
	#
	# CHEQUEO CUANDO HAY UN CAMBIO DE MES
	if ($CURR_MES_SYSTEM != $LAST_MES_SYSTEM)
	## HUBO CAMBIO DE MES, RESETEO EL CONTADOR DE HORAS Y MINUTOS DEL DIA Y EL DE HORAS DEL MES
	{
		$redis->hset("$DLGID_PERF", 'count_time_min_perf', 0);
		$redis->hset("$DLGID_PERF", 'count_time_hour_perf', 0);
		$redis->hset("$DLGID_PERF", 'count_time_month_perf', 0);
	}
	#	
	# ASIGNO VALORES A LAS VARIABLES DE VISUALIZACION
	## ASIGNO FECHA Y HORA A LA VARIABLE $D_EXEC_PER_PUMP
	my $count_time_min_perf = $redis->hget("$DLGID_PERF", 'count_time_min_perf');
	my $count_time_hour_perf = $redis->hget("$DLGID_PERF", 'count_time_hour_perf');
	### LE PONGO EL CERO QUE LE FALTA PARA EL FORMATO DE HORA Y QUE QUEDE 00:00 
	if ($count_time_min_perf < 10)
	{
		$count_time_min_perf = '0'.$redis->hget("$DLGID_PERF", 'count_time_min_perf');
	}
	else
	{
		$count_time_min_perf = $redis->hget("$DLGID_PERF", 'count_time_min_perf');
	}
	if ($count_time_hour_perf < 10)
	{
		$count_time_hour_perf = '0'.$redis->hget("$DLGID_PERF", 'count_time_hour_perf');
	}
	else
	{
		$count_time_hour_perf = $redis->hget("$DLGID_PERF", 'count_time_hour_perf');
	}
	#
	$D_EXEC_PER_PUMP = "$count_time_hour_perf".'h '."$count_time_min_perf".'m';
	#
	# ACTIVO LA ALARMA DE LIMITE DE EJECUCION DIARIO DE LA BOMBA CUANDO PASAN 18 HORAS DE FUNCIONAMIENTO DIARIO
	## spx_log('count_time_hour_perf => '.$count_time_hour_perf);
	if ($count_time_hour_perf > 17)
	# PASARON 18 HORAS DE FUNCIONAMIENTO DIARIO DE LA BOMBA
	{
		$D_EXEC_PER_PUMP_ERROR = 'SI';
	}
	else
	{
		$D_EXEC_PER_PUMP_ERROR = 'NO';
	}
	#
	## ASIGNO EL CONTADOR MENSUAL DE HORAS A $M_EXEC_PER_PUMP
	my $count_time_month_perf = $redis->hget("$DLGID_PERF", 'count_time_month_perf');
	#~ spx_log('$count_time_month_perf => '.$count_time_month_perf);
	$count_time_month_perf = $redis->hget("$DLGID_PERF", 'count_time_month_perf');
#	$count_time_month_dos = $redis->hget("$DLGID_PERF", 'count_time_month_perf');
	$M_EXEC_PER_PUMP = $count_time_month_perf.' horas' ;
	#
	## ASIGNO EL CONTADOR TOTAL DE HORAS A $T_EXEC_PER_PUMP
	my $count_time_total_perf = $redis->hget("$DLGID_PERF", 'count_time_total_perf');
	#~ spx_log('$count_time_total_perf => '.$count_time_total_perf);
	#	
	if ($count_time_total_perf > 9999998)
		{
			my $count_time_total_perf = $redis->hset("$DLGID_PERF", 'count_time_total_perf', 0);
		}
	$count_time_total_perf = $redis->hget("$DLGID_PERF", 'count_time_total_perf');
	$T_EXEC_PER_PUMP = $count_time_total_perf.' horas';
	#
}

sub count_time_pump_dos	
{
	
	# ESTABLEZCO LOS TIEMPOS DE TRABAJO DE LA BOMBA PERFORADORA
	##CHEQUEO QUE ESTEN CREADAS LAS VARIABLES A USAR PARA EL CONTEO DE TIEMPO EN LA BOMBA PERFORADORA
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_15seg_dos');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_15seg_dos", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_min_dos');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_min_dos", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_hour_dos');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_hour_dos", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_month_dos');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_month_dos", 0);
		}
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_total_dos');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_total_dos", 0);
		}
	#	
	## CONTADOR DE 15 SEGUNDOS DE LA BOMBA PRENDIDA
	if (defined $BD)
	{
		if ($BD == 1)
		# VEO SI LA BOMBA ESTA PRENDIDA
		{
			#~ spx_log("PASO  15 SEGUNDO CON LA BOMBA ENCENDIDA");	
			$redis->hincrby("$DLGID_PERF", 'count_time_15seg_dos', 1);
		}
	}
	#
	## CONTADOR DE MINUTOS DE LA BOMBA PRENDIDA
	### LEO EL CONTADOR DE 15 SEGUNDOS DE PERIODOS ENCENDIDA
	my $count_time_15seg_dos = $redis->hget("$DLGID_PERF", 'count_time_15seg_dos');
	#### CHEQUEO SI SE CUMPLIO UN MINUTO DE LA BOMBA PRENDIDA
	if ($count_time_15seg_dos >= 1)
	{
		#~ spx_log("PASO UN MINUTO CON LA BOMBA ENCENDIDA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_min_dos', 1);
		# RESETEO EL CONTADOR PARA CONTAR UN NUEVO MINUTO
		$redis->hset("$DLGID_PERF", "count_time_15seg_dos", 0);
	}
	#
	#
	## CONTADOR DE HORAS DE LA BOMBA PRENDIDA
	### LEO EL CONTADOR DE MINUTOS DE LA BOMBA PRENDIDA
	my $count_time_min_dos = $redis->hget("$DLGID_PERF", 'count_time_min_dos');
	#### CHEQUEO SI SE CUMPLIO UNA HORA DE LA BOMBA PRENDIDA
    my $CURR_DIA_SYSTEM = `date +%d`;
    # LIMPIO CARACTERES DE NUEVA LINEA
    $CURR_DIA_SYSTEM=~s/\n//g;
	#~ spx_log ('$CURR_DIA_SYSTEM =>' .$CURR_DIA_SYSTEM);
	my $CURR_MES_SYSTEM = `date +%m`;
	# LIMPIO CARACTERES DE NUEVA LINEA
	$CURR_MES_SYSTEM=~s/\n//g;
	#~ spx_log ('$CURR_MES_SYSTEM =>' .$CURR_MES_SYSTEM);
	#
	# VEO SI YA PASO UNA HORA
	if ($count_time_min_dos > 59)
	{	
		#spx_log("PASO UNA HORA CON LA BOMBA ENCENDIDA");	
		$redis->hincrby("$DLGID_PERF", 'count_time_hour_dos', 1);
			#
		# ESTABLEZCO PROTECCION PARA QUE LA BOMBA DOSIFICADORA NO ACUMULE UN TIEMPO MAYOR 
		## QUE EL DE LA BOMBA DE LA PREFORACION.
		my $count_time_month_dos = $redis->hget("$DLGID_PERF", 'count_time_month_dos');
		my $count_time_month_perf = $redis->hget("$DLGID_PERF", 'count_time_month_perf');
		if ($count_time_month_dos >= $count_time_month_perf)
		{
			my $count_time_month_perf = $redis->hget("$DLGID_PERF", 'count_time_month_perf');
			$redis->hset("$DLGID_PERF", "count_time_month_dos", $count_time_month_perf);
		}
		else
		{
			#spx_log("PASO UNA HORA MENSUAL CON LA BOMBA ENCENDIDA");	
			$redis->hincrby("$DLGID_PERF", 'count_time_month_dos', 1);
		}
		my $count_time_total_dos = $redis->hget("$DLGID_PERF", 'count_time_total_dos');
		my $count_time_total_perf = $redis->hget("$DLGID_PERF", 'count_time_total_perf');	
		if ($count_time_total_dos >= $count_time_total_perf)	
		{
			my $count_time_total_perf = $redis->hget("$DLGID_PERF", 'count_time_total_perf');	
			$redis->hset("$DLGID_PERF", "count_time_total_dos", $count_time_total_perf);
		}
		else
		{
			#spx_log("PASO UNA HORA TOTAL DE FUNCIONAMIENTO DE LA BOMBA");	
			$redis->hincrby("$DLGID_PERF", 'count_time_total_dos', 1);
		}
			#
			#
		# RESETEO EL CONTADOR DE MINUTOS PARA CONTAR UNA NUEVA HORA
		$redis->hset("$DLGID_PERF", "count_time_min_dos", 0);
	}
	#
	# CHEQUEO CUANDO HAY UN CAMBIO DE DIA
	#~ spx_log ('$CURR_DIA_SYSTEM =>' .$CURR_DIA_SYSTEM);
	#~ spx_log ('$LAST_DIA_SYSTEM =>' .$LAST_DIA_SYSTEM);
	#~ spx_log ('$CURR_MES_SYSTEM =>' .$CURR_MES_SYSTEM);
	#~ spx_log ('$LAST_MES_SYSTEM =>' .$LAST_MES_SYSTEM);
	if ($CURR_DIA_SYSTEM != $LAST_DIA_SYSTEM)
	## HUBO CAMBIO DE DIA, RESETEO EL CONTADOR DE HORAS Y MINUTOS DEL DIA
	{
		$redis->hset("$DLGID_PERF", 'count_time_min_dos', 0);
		$redis->hset("$DLGID_PERF", 'count_time_hour_dos', 0);
	}
	#
	# CHEQUEO CUANDO HAY UN CAMBIO DE MES
	if ($CURR_MES_SYSTEM != $LAST_MES_SYSTEM)
	## HUBO CAMBIO DE DIA, RESETEO EL CONTADOR DE HORAS Y MINUTOS DEL DIA Y EL DE HORAS DEL MES
	{
		$redis->hset("$DLGID_PERF", 'count_time_min_dos', 0);
		$redis->hset("$DLGID_PERF", 'count_time_hour_dos', 0);
		$redis->hset("$DLGID_PERF", 'count_time_month_dos', 0);
	}
	#		
	# ASIGNO VALORES A LAS VARIABLES DE VISUALIZACION
	## ASIGNO FECHA Y HORA A LA VARIABLE $D_EXEC_PER_PUMP
	my $count_time_min_dos = $redis->hget("$DLGID_PERF", 'count_time_min_dos');
	my $count_time_hour_dos = $redis->hget("$DLGID_PERF", 'count_time_hour_dos');
	### LE PONGO EL CERO QUE LE FALTA PARA EL FORMATO DE HORA Y QUE QUEDE 00:00 
	if ($count_time_min_dos < 10)
	{
		$count_time_min_dos = '0'.$redis->hget("$DLGID_PERF", 'count_time_min_dos');
	}
	else
	{
		$count_time_min_dos = $redis->hget("$DLGID_PERF", 'count_time_min_dos');
	}
	if ($count_time_hour_dos < 10)
	{
		$count_time_hour_dos = '0'.$redis->hget("$DLGID_PERF", 'count_time_hour_dos');
	}
	else
	{
		$count_time_hour_dos = $redis->hget("$DLGID_PERF", 'count_time_hour_dos');
	}
	#
	$D_EXEC_DOS_PUMP = "$count_time_hour_dos".'h '."$count_time_min_dos".'m';
	#
	## ASIGNO EL CONTADOR MENSUAL DE HORAS A $M_EXEC_PER_PUMP
	my $count_time_month_dos = $redis->hget("$DLGID_PERF", 'count_time_month_dos');
	$M_EXEC_DOS_PUMP = $count_time_month_dos.' horas' ;
	#
	## ASIGNO EL CONTADOR TOTAL DE HORAS A $T_EXEC_PER_PUMP
	my $count_time_total_dos = $redis->hget("$DLGID_PERF", 'count_time_total_dos');
	#~ spx_log('$count_time_total_dos => '.$count_time_total_dos);
	#	
	if ($count_time_total_dos > 9999998)
		{
			my $count_time_total_dos = $redis->hset("$DLGID_PERF", 'count_time_total_dos', 0);
		}
	$count_time_total_dos = $redis->hget("$DLGID_PERF", 'count_time_total_dos');
	$T_EXEC_DOS_PUMP = $count_time_total_dos.' horas';
}

sub flow_calc
{
	# CALCULO DEL CAUDAL DE SALIDA DE LA BOMBA
		my $count_pulses_cau;
		my $count_pulses_cau_acum;

	# 
	#
	#CHEQUEO SI ESTOY EN UN CASO DE PERFORACION CON CAUDALIMETRO CONECTADO.
	if (defined $PCAU)
	{
		spx_log('CALCULO DE CAUDAL => PERF. CON CAUD DE PULSOS');
		#INCIALIZO EN LA REDIS LAS VARIABLES QUE VOY A USAR
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_15seg_cau');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_15seg_cau", 0);
		}
		#
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_time_min_cau');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_time_min_cau", 0);
		}
		#
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_pulses_cau');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_pulses_cau", 0);
		}
		#
		my $EXISTS = $redis->hexists("$DLGID_PERF", 'count_pulses_cau_acum');
		if ($EXISTS == 0)
		# SI NO EXISTE LO CREO CON VALOR CERO
		{
			$redis->hset("$DLGID_PERF", "count_pulses_cau_acum", 0);
		}
			#
			#
		# CHEQUEO SI LA BOMBA DE LA PERFORACION ESTA PRENDIDA
		if ($BP == 1)
		{
			spx_log('CALCULO DE CAUDAL < $CAUDAL_IMP = '.$CAUDAL_IMP);
			# GUARDO LOS PULSOS PARA CALCULO DE CAUDAL INSTANTANEO
				$count_pulses_cau = $redis->hget("$DLGID_PERF", 'count_pulses_cau');
				$count_pulses_cau = $count_pulses_cau + $PCAU;
				$redis->hset("$DLGID_PERF", "count_pulses_cau", $count_pulses_cau);
				#~ spx_log('count_pulses_cau'.$count_pulses_cau);
				
				
			# GUARDO LOS PULSOS PARA CALCULO DE CAUDAL ACUMULADO
				$count_pulses_cau_acum = $redis->hget("$DLGID_PERF", 'count_pulses_cau_acum');
				$count_pulses_cau_acum = $count_pulses_cau_acum + $PCAU;
				$redis->hset("$DLGID_PERF", "count_pulses_cau_acum", $count_pulses_cau_acum);
				#~ spx_log('count_pulses_cau_acum = '.$count_pulses_cau_acum);
			
			# INCREMENTO EL CONTADOR DE 15s DEL POLEO DEL CAUDAL
			$redis->hincrby("$DLGID_PERF", 'count_time_15seg_cau', 1);
			# LEO EL PARAMETRO
			my $count_time_15seg_cau = $redis->hget("$DLGID_PERF", 'count_time_15seg_cau');
			#spx_log('$count_time_15seg_cau = '.$count_time_15seg_cau);
			# CHEQUEO SI PASO UN MINUTO PARA REGISTRARLO COMO TIEMPO DE POLEO
			if ($count_time_15seg_cau >= 1)
			{
				$redis->hincrby("$DLGID_PERF", 'count_time_min_cau', 1);
				# RESETEO EL CONTADOR PARA CONTAR UN NUEVO MINUTO
				$redis->hset("$DLGID_PERF", "count_time_15seg_cau", 0);
			}
			# LEO EL PARAMETRO
			my $count_time_min_cau = $redis->hget("$DLGID_PERF", 'count_time_min_cau');
			#spx_log('$count_time_min_cau = '.$count_time_min_cau);
			# CHEQUEO SI PASO UN TIEMPO DE POLEO
			if ($count_time_min_cau >= $TPOLL_CAU)
			{
				spx_log('CALCULO DE CAUDAL => TPOLL_CAU = '.$TPOLL_CAU);
			#	
				#spx_log('count_pulses_cau = '.$count_pulses_cau);

				# INICIO UN NUEVO TIEMPO DE POLEO
				$redis->hset("$DLGID_PERF", "count_time_min_cau", 0);
				#
				if ($typeFirmware eq 'old'){
					# CALCULO DEL CAUDAL INSTANTANEO ANTES
					spx_log('CALCULO DE CAUDAL => PERF CON FIRMWARE VIEJO');
					spx_log('CALCULO DE CAUDAL => MAGPP = '.$MAGPP);
					$CAUDAL_IMP = (($count_pulses_cau * $MAGPP * 600) / $TPOLL_CAU);
					spx_log('CALCULO DE CAUDAL => CAUDAL = '.$CAUDAL_IMP);
				}
				else{
					# CALCULO DEL CAUDAL INSTANTANEO AHORA
					spx_log('CALCULO DE CAUDAL => PERF CON FIRMWARE NUEVO');
					$CAUDAL_IMP = (($count_pulses_cau * 60) / $TPOLL_CAU);
					spx_log('CALCULO DE CAUDAL => CAUDAL = '.$CAUDAL_IMP);
					#
				}
				# RESETEO EL CONTADOR DE PULSOS
				$redis->hset("$DLGID_PERF", "count_pulses_cau", 0);
			}
			else
			{
				spx_log('CALCULO DE CAUDAL => CAUDAL = '.$CAUDAL_IMP.' {SE MANTIENE}');
			}
			
			if ($typeFirmware eq 'old'){
				# CALCULO EL CAUDAL ACUMULADO ANTES
				$CAUDAL_ACUM_IMP = ($count_pulses_cau_acum * $MAGPP * 10);
				spx_log('CALCULO DE CAUDAL => CAUDAL ACUMULADO = '.$CAUDAL_ACUM_IMP);
				#
			}
			else{
				# CALCULO EL CAUDAL ACUMULADO AHORA
				$CAUDAL_ACUM_IMP = $count_pulses_cau_acum;
				spx_log('CALCULO DE CAUDAL => CAUDAL ACUMULADO = '.$CAUDAL_ACUM_IMP);
			}
			
			# DETECTO SI HUBO CAMBIO DE MES	
			my $CURR_MES_SYSTEM = `date +%m`;
			if ($CURR_MES_SYSTEM != $LAST_MES_SYSTEM)
			## HUBO CAMBIO DE MES, RESETEO EL CONTADOR DE PULSOS DEL CAUDAL ACUMULADO
			{
				$redis->hset("$DLGID_PERF", 'count_pulses_cau_acum', 0);
				$CAUDAL_ACUM_IMP = 0;
			}
		}
		elsif ($BP == 0)
		{
			$CAUDAL_IMP = 0;
			$redis->hset("$DLGID_PERF", "count_pulses_cau", 0);
			spx_log('CALCULO DE CAUDAL => CAUDAL = 0 {BOMBA DE LA PERFORACION APAGADA}');
			spx_log('CALCULO DE CAUDAL => CAUDAL ACUMULADO = '.$CAUDAL_ACUM_IMP);
		}
		else
		{
			spx_log('	command error in $BP');
		}
		
	}
	elsif (defined $ICAU)
	{
		spx_log('CALCULO DE CAUDAL => PERF. CON CAUD DE CORRIENTE');
		if ($BP == 1){
			$redis->hset("$DLGID_PERF", "CAUDAL_IMP", $ICAU);
		}
		else{
			$redis->hset("$DLGID_PERF", "CAUDAL_IMP", 0);
		}
	}
	else
	{
		spx_log('CALCULO DE CAUDAL => NO SE CALCULA {PERFORACION SIN CAUDALIMETRO}');
	}
	spx_log('CALCULO DE CAUDAL < $CAUDAL_IMP = '.$CAUDAL_IMP);
}


######################## REGISTRO EN ARCHIVO ###########################
sub open_file
{
	# SE ENCARGA DE CREAR LOS HISTORICOS DE FUNCIONAMIENTO DEL DATALOGGER
	
		# TXT QUE REGISTRA LA HORA DE EJECUCION DEL SCRIPT
		my $historic_folder = "$PERF_CONFIG::SCRIPT_performance";
		mkdir $historic_folder;
		chmod 0777, $historic_folder;
		#
		my $historic_folder = "$PERF_CONFIG::SCRIPT_performance"."/spx_process_perf_test_$DLGID_PERF";
		mkdir $historic_folder;	
		chmod 0777, $historic_folder;
		#
		open( FILE1, ">>$PERF_CONFIG::SCRIPT_performance"."/spx_process_perf_test_$DLGID_PERF/$DLGID_PERF-$CURR_FECHA_SHORT.txt");	
		chmod 0777, "$PERF_CONFIG::SCRIPT_performance"."/spx_process_perf_test_$DLGID_PERF/$DLGID_PERF-$CURR_FECHA_SHORT.txt";
		#
		#
} 

######################## LOG WRITING ###########################
sub openLog {
	# function for create and open a log file with debug level
	
	
	$log->add(
		file => {
			filename => "$PERF_CONFIG::fileLogPath",
			maxlevel => "debug",
			minlevel => "warning",
			mode     => 'append',
			newline  => 1,
		}
	);
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

################### LEER LOS DATOS DEL DATALOGGER ######################
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
			#print FILE1 "LINE => [$DLGID] $line.\n";  # DEBUG
			
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
			   $typeFirmware = 'new';
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
				$typeFirmware = 'old';
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
				elsif ($value[0] eq 'ICAU')
				{
					$ICAU = $value[1];
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
	if (defined $ICAU)
	{
	spx_log('READ_DLG_DATA > $ICAU = '.$ICAU);
	}
	if (defined $bt)
	{
	spx_log('READ_DLG_DATA > $bt = '.$bt);
	}

}




### Finalizar retornando un valor `verdadero'
1;
