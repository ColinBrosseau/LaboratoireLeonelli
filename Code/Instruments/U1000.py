# -*- coding: utf-8 -*-
"""
@author: Colin-N. Brosseau

Controls the U1000 spectrometer thru a Arduino

Todo:
	document code
	Message avertissement lorsque trop de pas de faits
	remplacer serial -> visa ???
"""

import serial
import time
import numpy as np
#import visa

class U1000():
    def __init__(self, port='/dev/ttyACM0'):  # use serial
#    def __init__(self, ressource='ASRL13::INSTR'):  # use visa
        self.serial = serial.Serial(port)
        self.serial.baudrate = 57600
        self.serial.timeout = 1
        #self.position = None
        time.sleep(2)  # time for initialisation of the serial port
        self._positionOffset = 0  # difference between read (spectrometer display) and real wavelength        
                                 # If read=5321, real=5320 then _positionOffset = -1
        #self.position  # is always the read position (spectrometer display) NOT the actual wavelength
        #self.realPosition = self.position - self._positionOffset 
        self.stepIndex = 0  # Steps since last correction
        self._displayPositionInitialised = False  # has the user given the actual display position
        
    def close(self):
        self.serial.close()
        
    def _write(self, arg):
        """
        Write to instrument serial port
        
        :param arg: string to be writen
        :type arg: str
        """
        self.serial.write(bytes(arg, encoding="ascii") + b"\r\n")
        #self.serial.readline() # remove echo

    @property
    def positionOffset(self):
        """       
        Difference between read (spectrometer display) and real wavelength     
        If read=5321, real=5320 then = -1
        
        :getter: Returns offset = display - real
        :setter: Sets offset
        :type: float
        """
        return float(self._positionOffset)
        
    @positionOffset.setter
    def positionOffset(self, arg):
        self._positionOffset = float(arg)

    @property
    def realPosition(self):
        """
        Actual (offset corrected) position of the spectrometer (Angtroms)
        
        :getter:
        :returns: Position (Angtroms)
        :rtype: float
        """
        return self.posi() + self._positionOffset
 
    # deprecated, use realPosition
    def getRealPosition(self):
        return self.posi() + self._positionOffset
    
    def _read(self):
        """
        Read instrument serial port
        
        :rtype: str        
        """
        return self.serial.read(self.serial.inWaiting()).decode(encoding='ascii')

    def _query(self, arg):
        """
        Query instrument parameter
        
        :param arg: Parameter queried
        :type arg: str
        :rtype: str        
        """
        self._emptyCache()
        self._write(arg)
        time.sleep(.2)
        return self._read()

    def _set(self, param, value):
        """
        Set instrument parameter
        
        :param param: Parameter setted
        :type param: str
        :param value: Value of the parameter
        :type value: str, float
        """
        #print(param + ' ' + str(value))
        self._write(param + ' ' + str(value))
        
    def goto(self, destination, protection=True):
        """
        Move to another position with a backlash before movement
        
        :param destination: position to go to (Angtroms)
        :type destination: float
        :param protection: Protects from user foolness
        :type protection: bool
        """
        
        # Make sure the display position has been setted
        if not self._displayPositionInitialised:   
            raise AssertionError("U1000 display position must be used before: ex.: spectro.displayPosition = 5320")
      
        self.stepIndex = self.stepIndex + 1
        if self.stepIndex > 14:
            self.stepIndex = 0
            p = self.posi()
            self.posi(p-0.005)
        
        if destination<1000 and protection:
            # do nothing (sometimes users enter position in nm instead of A)
            raise ValueError('U1000 goto destination should be in Armstrong. To override: goto(' + str(destination) + ', protection=False)')
        elif destination>10000 and protection:
            # do nothing (sometimes users enter position in nm instead of A)
            raise ValueError('U1000 goto destination should be in Armstrong. U1000 will jam after 9300 A.')
        else:
            currentPosition = self.getRealPosition()
    #        # Move to reverse direction
    #        if destination > currentPosition:
    #            self.gotoNoBacklash(currentPosition - 1)
    #        else:
    #            self.gotoNoBacklash(currentPosition + 1)
    #        #time.sleep(.3)
    #        # Move to destination
    #        self.gotoNoBacklash(destination)        
    
            # Move a bit too much
            if destination < currentPosition:
                self._gotoNoBacklash(destination - 1)
                time.sleep(.2)
            # Move to final destination
            self._gotoNoBacklash(destination) 
    
    def _gotoNoBacklash(self, arg):
        """
        Move to another position with no backlash before movement
        
        :param destination: position to go to (Angtroms)
        :type destination: float
        """
        self._emptyCache()
        self._write('goto ' + str(arg-self._positionOffset))
        terminate = False
        while (self.serial.inWaiting() < 4) and not terminate:
            time.sleep(.1)
            if self.serial.inWaiting() == 4:
                a = self._read()
                if a[:2] == 'OK':
                    terminate = True
        #self.position = self._query('posi?')

    def _emptyCache(self):
        """
        Empty instrument serial port
        """
        self._read()

# displayed position (on physical spectrometer's counter) in Angstroms
    @property
    def displayPosition(self):
        """
        Wavelength on spectrometer display (Angtroms)        
        
        :getter: 
        :setter: 
        :type: float
        """
        assert self._displayPositionInitialised, "U1000 displayPosition not initialised"
        position = self._query('posi?')
        #print(position)
        return float(position)
        
    @displayPosition.setter
    def displayPosition(self, arg):
        self._set('posi', arg)
        self._displayPositionInitialised = True
        #print(arg)
        time.sleep(.1)

    # Deprecated, use displayPosition
    def posi(self, arg=None):
        if arg is None:
            #self.position = self._query('posi?')
            #print("ici ca marche pas: " + str(self.position))
            position = self._query('posi?')
            #print(position)
            return float(position)
        else: 
            #print('write')
            #print(arg)
            self._set('posi', arg)
            #print(arg)
            time.sleep(.1)
            #print(self._read())  #  purge the OK
            #self.position = self._query('posi?')
            #print(self.position)

    @property
    def speedSlow(self):
        """
        Slowest move speed     
        
        :getter: 
        :setter: 
        :type: int
        """
        return float(self._query('SLOW?'))

    @speedSlow.setter
    def speedSlow(self, arg):
        self._set('SLOW', arg)
        
    # deprecated, use speedSlow
    def _speedSlow(self, arg=None):
        if arg is None:
            return float(self._query('SLOW?'))
        else:
            self._set('SLOW', arg)     
            
    def _status(self):
        """
        Spectrometer internal parameters
        """
        self._write('PARAM')
        time.sleep(.6)
        return self._read()
    
    @property
    def speedFast(self):
        """
        Fastest move speed     
        
        :getter: 
        :setter: 
        :type: int
        """
        return float(self._query('speed?'))

    @speedFast.setter
    def speedFast(self, arg):
        self._set('speed', arg)
        
    # deprecated, use speedFast
    def _speedFast(self, arg=None):
        if arg is None:
            return float(self._query('speed?'))
        else:
            self._set('speed', arg)     
    
    def stop(self):
        """
        Stop movement immediately
        """
        self._write('stop')
        
    def pixel2A(self, position = None):
        """
        Convert pixel index to wavelength
        (This works only for the Si CCD already installed on the spectrometer.)
        
        :param position: Position of the spectrometer (Angtroms). If omited, use current one.
        :type position: float
        :returns: Wavelength of each pixels
        :rtype: numpy array        
        """
        if position is None:
            position = self._query('posi?')

        # Parametres prit integralement de la version Matlab 
        #        dv = 2.341131e-001;
        #        fact = 1.812402816604375e-004;
        # Parametres ajustes sur des mesures sur le pic Ne @ 6929.4673 
        dv = 0.19583658
        fact = 1.812402816604375e-004  # Fixe
        dispersion = 1e7 / 3.6e6 * np.cos(np.asin(fact*position/2)+dv/2) / 50

        a = position - dispersion * 670
        x = np.arange(1340)
        x = a + dispersion * x
        #x = claser - 1e8 / x / n_air
        return x
        
    def pixel2wavenumber(self, laser, position = None):
        """
        Convert pixel index to wavenumbers (cm-1)
        (This works only for the Si CCD already installed on the spectrometer.)
        
        :param laser: Wavelgnth of the laser (Angtroms). 
        :type laser: float
        :param position: Position of the spectrometer (Angtroms). If omited, use current one.
        :type position: float
        :returns: Wavenumbers (cm-1) for each pixel
        :rtype: numpy array        
        """
        n_air = 1.00028  #indice de refraction de l'air
        claser = 1e8/(laser*n_air)
        x = self.pixel2A(position)
        x = claser - 1e8 / (x * n_air)
        return x
    
# deprecated, see cm12A
def cibleram(wavenumber, laser):
    return cm12A(wavenumber, laser)

def cm12A(wavenumber, laser):
    """
    Wavelength corresponding to a relative wavenumber
    
    :param wavenumber: (relative) Wavenumber (cm-1)
    :type wavenumber: float
    :param laser: Wavelength of the laser (Angtroms)
    :type laser: float
    :returns: Wavelength (Angtroms)
    :rtype: float        
    """   
    n_air = 1.00028  #air refraction index
    claser = 1e8*n_air/laser
    spectro = 1e8*n_air/(claser-wavenumber)
    return spectro          

def A2cm1(wavelength, laser):
    """
    (relative) Wavenumber corresponding to a Wavelength
    
    :param wavelength: Wavelength (Angtroms)
    :type wavelength: float
    :param laser: Wavelength of the laser (Angtroms)
    :type laser: float
    :returns: (relative) Wavenumber (cm-1)
    :rtype: float        
    """   
    n_air = 1.00028  #air refraction index
    return 1e8 * n_air *  (1/laser - 1/wavelength)

