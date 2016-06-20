# -*- coding: utf-8 -*-
"""
@author: Colin-N. Brosseau

Controls the laser Matisse (Sirah)

Todo:
	document code
        exit wavemeter from here
"""

import visa
import time
import numpy as np

def testBit(int_type, offset):
    mask = 1 << offset
    return bool(int_type & mask)

#####

class power():
    def __init__(self, laser):
        self.laser = laser
        self.laser.baud_rate = 9600
        
    def close(self):
        self.laser.close()
        
    def write(self, arg):
        return self.laser.write(arg)

    def query(self, arg):
        try:
            a = self.laser.query(arg)
        except (visa.VisaIOError):
            a = '' 
        return a
        
    @property
    def power(self):
        return float(self.query('?P').strip().replace('W', ''))
        
    @power.setter
    def power(self, param):
        if param > 10.5:
            param = 10.5
        if param < 0:
            param = 0
        self.write('P:' + "%.2f" % param)

class MatisseComponent():
    def __init__(self, outer):
        self.outer = outer

    def query(self, arg):
        a = self.outer.query(arg)
        return a

    def write(self, arg):
        self.outer.write(arg)
        
    def read(self):
        return self.outer.read_raw()

    def queryValue(self, string):
        a = self.query(string)
        print(a)
        I = a.find(' ')
        return a[I:]
        
    def queryValueNumeric(self, string):
        return float(self.queryValue(string))

#####

class BiFi(MatisseComponent):
    def __init__(self, outer):
        super(self.__class__, self).__init__(outer)
        #self.outer = outer

    @property
    def wavelength(self):
        string = 'MOTORBIREFRINGENT:WAVELENGTH?'
        return self.queryValueNumeric(string)

    @wavelength.setter
    def wavelength(self, position):
        try:
            self.query('MOTORBIREFRINGENT:WAVELENGTH ' + str(position))
        except:
            pass
#        except (VisaIOError):
#            print('correcting error!')
#            self.query('error:clear' )
#            self.query('MOTORBIREFRINGENT:WAVELENGTH ' + str(position))
                
#        run = True
#        while run:
#            current = self.queryValueNumeric('MOTORBIREFRINGENT:WAVELENGTH?')
#            print(current)
#            print(position)
#            if abs(current - position) < .2:
#                run = False
#            time.sleep(.5)
            
#        print(self.read())
        self.waitBiFi()  # to be implemented     
        #return a

    @property
    def position(self):
        string = 'MOTORBIREFRINGENT:position?'
        return self.queryValueNumeric(string)

    @position.setter
    def position(self, position):
        a = self.query('MOTORBIREFRINGENT:position ' + str(position))
        self.waitBiFi()  # to be implemented
        return a   

    def BiFiRunning(self):
        status = int(self.queryValueNumeric('MOTORBIREFRINGENT:STATUS?' ))
        #print(" status: ")
        #print(status)
        #error = self.query('error:code?' )
        #print(" error: ")
        #print(error)
        return testBit(status, 8)

    def waitBiFi(self):
        while self.BiFiRunning():
            print('wait for BiFi ...')
            time.sleep(.5)  # 0.3 plante, 0.5 fonctionne  # timeout de 2000 ms
                            # 0.1 semble fonctionnel, 0.3 fonctionne, 0.5 fonctionne  # timeout de 5000 ms
        time.sleep(0.1)
        
#####

class ThinEtalon(MatisseComponent):
    def __init__(self, outer):
        super(self.__class__, self).__init__(outer)
        #self.outer = outer

    @property
    def dcValue(self):
        string = 'thinetalon:DCVALUE?'
        return self.queryValueNumeric(string)

    @property
    def controlStatus(self):
        string = 'thinetalon:controlstatus?'
        return 'RUN' in self.queryValue(string)

    @property
    def motorPosition(self):
        string = 'motorthinetalon:position?'
        return int(self.queryValueNumeric(string))

    @motorPosition.setter
    def motorPosition(self, position):
        a = self.query('motorthinetalon:position ' + str(int(position)))
        self.wait()  
        return a

    def running(self):
        status = int(self.queryValueNumeric('MOTORthinetalon:STATUS?' ))
        #print(" status: ")
        #print(status)
        return testBit(status, 8)

    def wait(self):
        while self.running():
            print('wait for Thin Etalon ...')
            time.sleep(.1)  # 0.3 plante, 0.5 fonctionne  # timeout de 2000 ms
                            # 0.1 semble fonctionnel, 0.3 fonctionne, 0.5 fonctionne  # timeout de 5000 ms
        time.sleep(0.1)
        
#####
        
class Matisse():  
    
    def __init__(self, ressource='USB0::0x17E7::0x0102::11-43-30::INSTR'):
        rm = visa.ResourceManager()
        self.instrument = rm.open_resource(ressource)
        self.instrument.timeout = 5000
        self.instrument.query_delay = 0 # needed to prevent craching once in a while
                                # this value could potentialy be reduced
                                # 0.1 no problem over 400 steps
        # open instrument
        # timeout 5000 is from an example in programmer's manual
        self.wavemeter = rm.open_resource('ASRL91::INSTR', baud_rate=57600, data_bits=8, timeout=5000, read_termination='\r')
        try:
            self.pump = power(rm.open_resource('ASRL32::INSTR'))
            #self.millenia = rm.open_resource('ASRL32::INSTR')
            
        except:
            pass  # usb 2 rs232 unplugged. Should add something here
        self.thinEtalon = ThinEtalon(self.instrument)        
        self.BiFi = BiFi(self.instrument)        
        
    def close(self):
        self.instrument.close()
        self.wavemeter.close()
        
    def write(self, arg):
        return self.instrument.write(arg)

    def getRealPosition(self):
        return self.posi() + self.positionOffset
    
    def query(self, arg):
        try:
            a = self.instrument.query(arg)
        except (visa.VisaIOError):
            print("ERROR: recall...")
            a = self.query(arg)
        return a

    def queryValue(self, string):
        a = self.query(string)
        I = a.find(' ')
        return a[I:]
        
    def queryValueNumeric(self, string):
        return float(self.queryValue(string))

    @property
    def realWavelength(self):
        """
        Real wavelength (nm, in vaccum) of the laser from the wavementer
        """
        def getNAvailable():
            """
            Number of available reading in the buffer
            """
            L = self.wavemeter.bytes_in_buffer  # number of caracters in buffer
            #print(L)
            n = int(L/9)  # number of reading in buffer
            #print(n)
            return n
        n = getNAvailable()  # number of measure abvailable
        while n == 0:  # no measure available, wait and test again
            time.sleep(.1)
            n = getNAvailable()
            
        for i in range(n):
            wavelength = self.wavemeter.read()
            #print(str(i) + " : " + str(wavelength))
#        self.wavemeter.clear()
#        a = self.wavemeter.read()
        print(wavelength)    
        wavelength = float(wavelength.replace(',', '.'))
        print(wavelength)
        if wavelength < 100:  # correct an error that happens sometimes
            wavelength = self.realWavelength
        return wavelength
 
    # Obsolete
    @property
    def BiFiWavelength(self):
        a = self.instrument.query('MOTORBIREFRINGENT:WAVELENGTH?' )
        print(a)
        I = a.find(' ')
        return float(a[I:])
        
    # Obsolete
    @BiFiWavelength.setter
    def BiFiWavelength(self, wavelength):
        a = self.instrument.query('MOTORBIREFRINGENT:WAVELENGTH ' + str(wavelength))
        print("a: ")
        print(a)
        self.waitBiFi()        
        return a
        
    # Obsolete
    @property
    def BiFiPosition(self):
        a = self.instrument.query('MOTORBIREFRINGENT:position?' )
        #print(a)
        I = a.find(' ')
        return float(a[I:])
        
    # Obsolete
    @BiFiPosition.setter
    def BiFiPosition(self, wavelength):
        a = self.instrument.query('MOTORBIREFRINGENT:position ' + str(wavelength))
        #print(a)
        self.waitBiFi()        
        return a
        
    @property
    def diodePowerDC(self):
        a = self.instrument.query('DIODEPOWER:DCVALUE?' )
        #print(a)
        I = a.find(' ')
        return float(a[I:])
        
    # To be Obsolete
    def BiFiRunning(self):
        status = self.instrument.query('MOTORBIREFRINGENT:STATUS?' )
        print(" status: ")
        print(status)
        I = status.find(' ')
        status = int(status[I:])
        #print(status)
        return testBit(status, 8)

    # To be Obsolete
    def waitBiFi(self):
        while self.BiFiRunning():
            print('wait...')
            time.sleep(.5)  # 0.3 plante, 0.5 fonctionne
        time.sleep(0.5)
        
if __name__ == '__main__':
    laser = Matisse()
#    wl = m.BiFiWavelength
#    print('BiFi wavelength:' + str(wl))
#    print('increase wavelength by 2 nm')
#    m.BiFiWavelength = wl + 2
#    wl = m.BiFiWavelength
#    print('BiFi wavelength:' + str(wl))
    
    # scan thin etalon
    x = np.arange(7000, 17000, 50)    
    y = np.empty_like(x, dtype=float)
    for i in range(len(x)):
        laser.thinEtalon.motorPosition = x[i]
        print(x[i])
        print(laser.thinEtalon.motorPosition)
        y[i] = laser.realWavelength/1.000275
        
    
    
