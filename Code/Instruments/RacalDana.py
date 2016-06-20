# -*- coding: utf-8 -*-
"""
Created on Tue Sep 29 14:55:38 2015

@author: Colin-N. Brosseau

Controls the RacalDana 1991 photon counter

Todo:
	document code
"""

import visa
import time
import numpy as np
from spikes import removeSpike1D

class RacalDana:
    def __init__(self, ressource='GPIB0::3::INSTR'):
        rm = visa.ResourceManager()
        #print(ressource)
        self.inst = rm.open_resource(ressource)
        self.inst.read_termination = u'\n'
        self.initialConfiguration()
        
    def close(self):
        self.inst.close()

    def initialConfiguration(self):
        """
        Default initial configuration
        """
        self.inst.write('ck')
        self.inst.write('AMN;ADC;ALI;ANS;AAD;AFD;SLA-0.02')
        self.inst.write('BMN;BDC;BLI;BPS;BAD;SLB0.5')
        self.inst.write('TA;DE;SDT0.8;T0')

    def measure(self, exposureTime=1):
        """
        """
        out = np.empty([1, exposureTime])
        for i in range(exposureTime):
            self.inst.write('RE;T1;T2;');
            time.sleep(.9)
            temp = self.inst.query('RF;')
            out[0, i] = float(temp[2:-1])
            time.sleep(.01)
        
        #print(out)
        if len(out) > 1:
            out = removeSpike1D(out)  # remove bad spikes
        return np.sum(out)
