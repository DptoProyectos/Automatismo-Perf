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
//drbd/www/cgi-bin/spx/AUTOMATISMOS/serv_error_APP_selection.py =>
	
	# SE CORRE EL PROCESO DE LAS PERFORACIONES EN PERL
	run_perforation_process(DLGID_CTRL)
	
	NOTA: CADA VEZ QUE UN DATALOGGER CON EL FIRMWARE NUEVO TRANSMITE SE LLAMA A LA FUNCION run_perforation_process desde serv_error_APP_selection.
	
	
# FORMA DE LLAMADA MANUAL:
## DESDE EL call_spx_process_perf.pl
	
	Se edita el fichero con el datalogger que se quiere llamar y si se quieren ve los logs o no.
	
	NOTA: 
	con este tipo de llamada se lee la configuracion almacenada en la Redis antes para con la misma ejecutar el script.
	ver los logs o no no afecta en nada la llamada del script desde el servidor.
	
	



TASKS

SPY
    *salvar mi proyecto de la pc y subirlo
    *descargar el proyecto del servidor y subirlo a mine
    *descargar el proyecto del servidor y subirlo a spy
    *probar que el automatismo funcione
    *descargar el sistema que esta en .0.9 para otra carpeta
    *crear y trabajar sobre el brach merge97
    *comparar cada archivo:
        *Library_PERF
        *spx_process_error_perf_test   (hubo que implementar funcionalidades para seleccionar que bases de datos leer)
        *spx_process_perf
        *PERF_CONFIG
        *call_error_perf_test
        *call_spx_process_perf
        *ext_call
    -implementar logs en makeLogs
        *implementar un log unico manteniendo el sistema de logs anterior
        *eliminar el sistema de logs anterior de script performance
        *testear y comprobar el sistema nuevo
        -eliminar el sistema de logs anterior de dlg_performance
OSE
    *salvar mi proyecto de la pc y hacer commit
    *descargar el sistema que esta en OSE y hacer commit
    *probar que el automatismo funcione
    *hacer un merge entre las versiones que estan en OSE.
        *error_perf_test_UYSAL001 y error_perf_test_UYPC03
        *error_perf_test_UYSAL001 y error_perf_test_UYSAL002
        *spx_process_error_perf_test y spx_process_error_perf_test1
        *Library_PERF
        *spx_process_perf_UYSAL001 y spx_process_perf_UYPC03
        *call_error_perf_test
        *spx_process_perf_UYSAL001 y spx_process_perf_UYSAL002
        *spx_process_perf
        *PERF_CONFIG
        *call_error_perf_test
        *call_spx_process_perf
        *ext_call
    *crear y trabajar sobre el brach logs

 OTHERS   
*hacer que se pueda leer el PERF_CONFIG desde el directorio local al tener una llamada externa
-hacer un modo debug en donde se lean los estimulos pero no se generen respuestas
*hacer un modo LOCAL/REMOTO en donde se seleccione de donde se van a tomar los datos de los estimulos y las respuestas
*implementar un easy log a modo de deshabilitar los logs de la carpeta dlg_performnace





