PROYECTO DE PERFORACIONES CON AUTOMATISMOS

FLOWCHART: https://drive.google.com/file/d/1wjtxVVZvLQIw-X38AjfmsNmtHm8Q2VMS/view?usp=sharing

Esquema de merge en el proyecto: https://drive.google.com/file/d/1thu4vOA1LuvVQASj-vXybY7XpvqsOtMQ/view?usp=sharing



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





