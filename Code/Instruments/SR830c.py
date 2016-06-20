# -*- coding: utf-8 -*-
"""
Created on Mai 2 2016

@author: Colin-N. Brosseau

Controls the Standford Research SR830 lockin

Todo:
	document code
"""

import visa
import time
import numpy as np
import struct

class SR830c():
    def __init__(self, adress=6):
	"""
	Default to GPIB first controller adress 6
	"""
        rm = visa.ResourceManager()
        self.instrument = rm.open_resource('GPIB0::' + str(adress) + '::INSTR')
        
    def close(self):
        self.instrument.close()
        
    def write(self, arg):
        return self.instrument.write(arg)

    def query(self, arg):
        return self.instrument.query(arg)

    def query_binary_values(self, arg):
        return self.instrument.query_binary_values(arg)

    @property
    def frequency(self):
        a = self.instrument.query('freq?')
        print(a)
        #I = a.find(':')
        return float(a)
        
    @frequency.setter
    def frequency(self, parameter):
        return self.instrument.write('freq ' + str(parameter))

    @property
    def sampleRate(self):
        a = self.instrument.query('srat?')
        return int(a)
        
    @sampleRate.setter
    def sampleRate(self, parameter):
        return self.instrument.write('srat ' + str(parameter))
             
    @property
    def referenceSource(self):
        a = self.instrument.query('fmod?')
        return int(a)
        
    @referenceSource.setter
    def referenceSource(self, parameter):
        return self.instrument.write('fmod ' + str(parameter))
             
    @property
    def mesurePause(self):  
        self.instrument.write('paus')
        
    @property
    def mesureClear(self):  
        self.instrument.write('rest')
        
    @property
    def mesureStart(self):  
        self.instrument.write('strt')
        
    @property
    def mesureN(self):  
        return int(self.instrument.query('spts?'))
        
    def mesureRead(self, canal=[1,2]):
        self.mesurePause
        N = self.mesureN
        #print(N)
        out = [0, 0]
        #j = 0
        #for i in canal:
        out = self.query('trca? ' + str(canal) + ',0,' + str(N)); 
        #print(out)
        out = np.array([float(i) for i in out.strip().split(',')[:-2]])
        #    j += 1
        return np.mean(out), np.std(out)
            
    def mesureReadBinary(self, canal):
        def convertBinarySR830toFloat(value):
            def convertSingleValue(value):
                return struct.unpack('!f', bytearray(value[::-1]))[0]
        
            N = int(len(value)/4)
            out = np.empty(N)
            for i in range(N):
                out[i] = convertSingleValue(value[(i*4)+0:(i*4)+4])
        
            return out
            
        self.mesurePause
        N = self.mesureN
        out = [0, 0]
        
        self.write('trcb? ' + str(canal) + ',0,' + str(N))
        binary = self.instrument.read_raw()
        out = convertBinarySR830toFloat(binary)
        
        return np.mean(out), np.std(out)
            
                
    def mesure(self, measurementTime):
        A = 0
        B = 0
        if measurementTime > 30:
            n = np.round(measurementTime)
            for i in range(n):
                #print(i)
                self.mesureClear
                self.mesureStart
                time.sleep(1) 
                a = self.mesureReadBinary(canal=1)                 
                b = self.mesureReadBinary(canal=2)      
                A += a[0]
                B += b[0]
            A /= n
            B /= n
        else:
            self.mesureClear
            self.mesureStart
            time.sleep(measurementTime) 
            a = self.mesureReadBinary(canal=1)                 
            b = self.mesureReadBinary(canal=2)      
            A += a[0]
            B += b[0]
        return A, B           
            
if __name__ == '__main__':
    m = SR830c()
    print('Frequency' + str(m.frequency))
