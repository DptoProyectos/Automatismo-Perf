PROYECTO DE PERFORACIONES CON AUTOMATISMOS

FLOWCHART: https://drive.google.com/file/d/1wjtxVVZvLQIw-X38AjfmsNmtHm8Q2VMS/view?usp=sharing

 
# FORMA DE LLAMADA DEDE EL SERVIDOR:
## DETECCION DE ERRORES DESDE EL CRONTAB
/var/etc/crontab => 
	*/1 * * * * root /drbd/www/cgi-bin/spx/PERFORACIONES/call_error_perf_test.pl > /dev/null 2>&1
	
	NOTA: EN EL CRONTAB SE EJECUTA TODO LO RELACIONADO A DETECCION DE ERRORES CADA 1 MINUTO


## PROCESS DEL AUTOMATIMSO DESDE EL SERVIDOR EN PERL
//drbd/www/cgi-bin/spx/SPY_CALLBKS.pm =>
	use lib '/drbd/www/cgi-bin/spx/PERFORACIONES/PROCESS';				#SPY
	use spx_process_perf;	.
	
	process_perf ($dlgid,'CHARGE');
	
	NOTA: CADA VEZ QUE UN DATALOGGER CON EL FIRMWARE VIEJO TRANSMITE SE LLAMA A LA FUNCION process_perf Y SE LE PASA EL DATALOGGER ID


## PROCESS DEL AUTOMATIMSO DESDE EL SERVIDOR EN PYTHON.
//drbd/www/cgi-bin/spx/AUTOMATISMOS/serv_APP_selection.py.py =>
	
	# SE CORRE EL PROCESO DE LAS PERFORACIONES EN PERL
	run_perforation_process(DLGID_CTRL)
	
	NOTA: CADA VEZ QUE UN DATALOGGER CON EL FIRMWARE NUEVO TRANSMITE SE LLAMA A LA FUNCION run_perforation_process desde serv_error_APP_selection.
	
	
# FORMA DE LLAMADA MANUAL:
## DESDE EL call_spx_process_perf.pl
	
	Se edita el fichero con el datalogger que se quiere llamar y si se quieren ve los logs o no.
	
	NOTA: 
	con este tipo de llamada se lee la configuracion almacenada en la Redis antes para con la misma ejecutar el script.
	ver los logs o no no afecta en nada la llamada del script desde el servidor.
	
