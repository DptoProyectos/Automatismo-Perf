#!/usr/aut_env/bin/python3.8

'''
    ESTE SCRPT PERMITE PRENDER Y APAGAR LAS BOMBAS DEL SISTEMA DE PERFORACIONES CUANDO SE LES INDIQUE
    OJO: ANTES DE USARLO LA PERFORACION TIENE QUE ESTAR EN MODO TIMER O BOYA SEGUN CORRESPONDA
        
'''

import redis
from datetime import datetime

DLG_LST = ['PSTPERF05'];
TIME_TO_START = ['05:00'];
TIME_TO_STOP = ['23:00'];
SERVER = '192.168.0.8';               # [localhost | 192.168.0.8]


class setTime2change (object):
    """
    docstring
    """
    def __init__(self,server,dlgList,time2Star,time2Stop):
        self.server = server;
        self.dlgList = dlgList;
        self.time2Star = time2Star;
        self.time2Stop = time2Stop;

        self.connected = 'NULL'
        self.rh = 'NULL'

        try:
            self.rh = redis.Redis(self.server)
            self.connected = True
        except Exception as err_var:
            self.connected = False
    
    def turnOnPump(self):
        if self.connected:
            for dlg in self.dlgList:
                self.rh.hset( dlg, 'OUTPUTS', 15)

    def turnOffPump(self):
        if self.connected:
            for dlg in self.dlgList:
                self.rh.hset( dlg, 'OUTPUTS', 5)

    def checkTime(self):
        currTime = datetime.now().strftime('%H:%M');
        print ('CURREN TIME => {0}'.format(currTime));
    
        if currTime in self.time2Star:
            print ('PRENDO BOMBA')
            self.turnOnPump()
        elif currTime in self.time2Stop:
            print ('APAGO BOMBA')
            self.turnOffPump()
        else:
            print ('no ejecuto accion')

        
        

# MAIN
st = setTime2change(SERVER,DLG_LST,TIME_TO_START,TIME_TO_STOP)

st.checkTime();









