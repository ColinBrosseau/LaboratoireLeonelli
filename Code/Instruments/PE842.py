# -*- coding: utf-8 -*-
"""
Created on Fri Feb 26 09:33:05 2016

@author: Colin-N. Brosseau

Newport 842 PE powermeter
"""

import visa

class Newport842PE():
    def __init__(self, ressource='ASRL13::INSTR'):
        rm = visa.ResourceManager()
        self.instrument = rm.open_resource(ressource, baud_rate=115200, timeout=2000, data_bits=8, write_termination='\r\n')
        self.wavel = 0
        
    def close(self):
        self.instrument.close()
        
    def write(self, arg):
        return self.instrument.write(arg)

    def query(self, arg):
        return self.instrument.query(arg)

    @property
    def current(self):
        a = self.instrument.query('*CVU')
        print(a)
        I = a.find(':')
        return float(a[I+1:])
        
    @property
    def wavelength(self):
        return float(self.wavel)
        
    @wavelength.setter
    def wavelength(self, wavelength):
        self.wavel = wavelength
        return self.instrument.query('*SWA ' + str(wavelength))

                
if __name__ == '__main__':
    m = Newport842PE()
    print('Current Value:' + str(m.current))
