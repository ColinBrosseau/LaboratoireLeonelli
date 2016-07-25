#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Created on Wed Sep  9 15:04:23 2015

@originalauthor: http://people.seas.harvard.edu/~krussell/html-tutorial/com_interface.html
@author: Colin-N Brosseau
"""

""" 
    Acquire a spectrum using Winspec through the COM interface.
    This script actually gets the data from Winspec and then
    plots it within python.
    
    !!! Right now, one must manually set (in Winspec):
        long in Data File > Data Type
        ROI (on can set it from this function, but need to be confirmed in Winspec)
"""

"""
    Here are some details explaining how I (Colin-N Brosseau) built this file.
    
    We begin by using makepy.py from win32com package.
    From command line:
        python makepy.py
    Then in the menu list, choose "Roper Scientific's WinX32"
    It will "compile" and make a file like 
        1A762221-D8BA-11CF-AFC2-508201C10000x0x3x11.py
    This file contain informations to use Winspec with Python thru COM.
    Locate the first line  beginning by 
        CLSID = IID('{
    In my case, I have:
        CLSID = IID('{1A762221-D8BA-11CF-AFC2-508201C10000}')
    The string '{1A762221-D8BA-11CF-AFC2-508201C10000}' is to be used to "import" the module.
    We also need MajorVersion and MinorVersion 
    These three informations are needed to write (see below) the line 
        cc.GetModule(('regkey', majorversion, minorversion))
    In my case, I have
        cc.GetModule( ('{1A762221-D8BA-11CF-AFC2-508201C10000}',3,11))
        
    The remaining of the file contains informations about variables and classes
"""

#import pylab

import comtypes.client as cc
import comtypes.gen.WINX32Lib as WinSpecLib
import time
import win32com.client as w32c
#from win32com.client import constants

#from ctypes import byref, pointer, c_long, c_float, c_bool
from ctypes import c_long
#import types 
import numpy as np

class winspec:
    def __init__(self, baseFilename='test', filenameIndex=0):
        cc.GetModule( ('{1A762221-D8BA-11CF-AFC2-508201C10000}', 3, 11))  # comes from regedit (look for IWinx32App2), major version, minor version
        w32c.pythoncom.CoInitialize()
        self.WinspecDoc = w32c.Dispatch("WinX32.DocFile")
        self.WinspecExpt = w32c.Dispatch("WinX32.ExpSetup")
        self.WinspecROI = w32c.Dispatch("WinX32.ROIRect")
        # For measurement filename        
        self.baseFilename = baseFilename
        self.filenameIndex = filenameIndex
        self.initialConfiguration()
        self.readOutTime = 0.037  # second

    def initialConfiguration(self):
        """
        Default initial configuration
        """
        self.cosmicMode('spatial')
        self.cosmicSensitivity(50)
        self.setTemperature(-100)
        self.dataType('long')

    def measureSimple(self, exposureTime=1, images=1, accumulations=1, filename=False):
        """
        
        """
        #print(filename)
        if not filename:
            self.filenameIndex = self.filenameIndex + 1
            filename = self.baseFilename + '-' + str(self.filenameIndex)
#        import time
#        time.sleep(.5)
#        time.sleep(.5)
        #print(filename)
        self.filename(filename)  # set measurement outpur file
        self.exposureUnit('s')  # set exposure unit
        self.exposure(exposureTime)  # set exposure time
        self.nAccumulations(accumulations)
#        import time
#        print(self.nImages())
#        print(self.nImages())
#            self.nImagesTest(images)  # set number of images

        #TODO preallocation de x et y pour accelerer l'acquisition        
        
        i = 0
        x, y = self.measure(filename + '-1')
        for i in np.arange(2, images+1):
            xtemp, ytemp = self.measure(filename + '-' + str(i))  # start measurement
#            y = np.concatenate((y, ytemp))
            y = np.vstack((y, ytemp))
            
        # y will be of dimension (image, sizeOfDetector)
        # This is neaded for images=1
        y = np.atleast_2d(y)
        
        return x, y, filename + '.SPE'

    def stop(self):
        """Stop current measurement"""        
        self.WinspecExpt.Stop()
        
    def measure(self, filename='filename.SPE'):
        """
        Do a measurement.
        
        filename
            
        """
        self.stop()
        if self.WinspecExpt.Start(self.WinspecDoc)[0]: # start the experiment
            # Wait for acquisition to finish (and check for errors continually)
            # If we didn't care about errors, we could just run WinspecExpt.WaitForExperiment()
        
            expt_is_running, status = self.isRunning()
        
            maxElapsed = (self.readOutTime + self.exposure()[0]) * self.nAccumulations()[0] + 15
            t = time.time()
#            endNow = False
            #while expt_is_running and status == 0 and not endNow:
            while expt_is_running and status == 0:
                time.sleep(.1)
                expt_is_running, status = self.isRunning()
                #print(expt_is_running + " " + status)
                elapsed = time.time() - t
                #print(elapsed)
                if elapsed > maxElapsed:  # prevent infinite measurement (it appends rarely)
                    self.stop()
                    print("Stop manuel")
                    #endNow = True
        
            if status != 0:
                print('MsgBox ("Error running experiment.")')
        
            # Save the file from winspec
            # self.WinspecDoc.SaveAs(filename)        

            # The remaining plot data by reading directly from winspec
            """ Pass a pointer to Winspec so it can put the spectrum in a place in
                memory where python will be able to find it. """
#            datapointer = c_float()
# test 13 janvier 2016 pour faire fonctionner nAccumulations
            datapointer = c_long()
            y = self.WinspecDoc.GetFrame( 1, datapointer )  # seems to return just the first frame
            #calibration = WinspecDoc.GetCalibration()
            #if calibration.Order != 2:
            #    raise ValueError('Cannot handle current winspec wavelength calibration...')
            #import numpy as np
            #print(np.shape(y))
                
            """ Winspec doesn't actually store the wavelength information as an array but
                instead calculates it every time you plot using the calibration information
                stored with the spectrum. """
            #p = pylab.array([ calibration.PolyCoeffs(2),
            #                  calibration.PolyCoeffs(1),
            #                  calibration.PolyCoeffs(0) ])
        
            #wavelen = pylab.polyval( p, xrange( 1, 1+len(spectrum) ) )
        
            #pylab.plot( y )
            #pylab.show()   
            
            x = np.arange(0, len(y))
            
            return x, np.squeeze(y)
        
        else:
            print("Could not initiate acquisition.")
#
#    def loadConfig(self, filename):
#       self.WinspecExpt.Load(filename)

    def getParamAll(self, filename='WinspecConfig.py.txt'):
        """
        Export and print Winspec internal variables values
        Some unknown variable types are not printed as values but just variable type
        """
        f = open(filename,"w")
        l = WinSpecLib.__all__
        #print(l)
        for i in l:
            print(i)
            param = getattr(WinSpecLib, i)
            #print(param)
            if isinstance(param, int):
                temp, status = self.WinspecExpt.GetParam(param)
                f.write("%s %s\n" % (i, temp))
                print(i, temp)
            else:
                print(i, type(param))
                f.write("%s %s\n" % (i, type(param)))
        f.close() 
            
    def getParam(self, param):
        """Get an internal winspec variable"""
        result, status = self.WinspecExpt.GetParam(param)
        return result, status
        
    def setParam(self, param, value):
        """Set an internal winspec variable"""
        return self.WinspecExpt.SetParam(param, value)
         
    class experimentParam(object):
        """This class is used as a decorator to get/set internal variables"""
        def __init__(self, value, dic=None):
            #pass
            self.value = value
            self.dic = dic
            
        def __call__(self, original_func):
            decorator_self = self
            def wrappee( *args, **kwargs): 
                param = decorator_self.value
                valueDict = decorator_self.dic
                if valueDict is not None:
                    DictInvert = dict([(v, k) for k, v in valueDict.items()])
                #param = self.value
                #print(param)
                #print('in decorator before wrapee with flag ',param)
                obj = original_func(*args,**kwargs)
                if len(args) == 1:
                    #print("get parameter", param)
                    out =  list(obj.getParam(param))
                    #print(out)
                    if valueDict is not None:
                        out[0] = DictInvert[out[0]]
                    return out
                else:
                    #print("set parameter", param, "=", args[1])
                    #self.setParam(param, value)
                    value = args[1]
                    if valueDict is not None:
                        value = valueDict[value]
                    #    out = DictInvert[out]
                    out =  obj.setParam(param, value)
                    #print(out)
                    
                    return out
    
            return wrappee
        
# Background
    @experimentParam(WinSpecLib.EXP_BBACKSUBTRACT, {True:1, False:0})
    def removeBackground(self, a=None):
        """Substract (or not) a background from measurement"""
        return self

    @experimentParam(WinSpecLib.EXP_DARKNAME)
    def filenameBackground(self, a=None):
        """File used as a background"""
        return self

    def acquireBackground(self):
        """Acquire the background"""
        self.WinspecExpt.AcquireBackground()
    
# Temperature 
    @experimentParam(WinSpecLib.EXP_ACTUAL_TEMP)
    def actualTemperature(self, a=None):
        "actual detector temperature (C)"
        return self
        
    @experimentParam(WinSpecLib.EXP_TEMPERATURE)
    def setTemperature(self, a=None):
        "detector set temperature (C)"
        return self
        
# Cosmic rays
    @experimentParam(WinSpecLib.EXP_DOCOSMIC, {'off':0, 'temporal':1, 'spatial':2})
    def cosmicMode(self, a=None):
        "cosmic removal mode"
        return self       
        
    @experimentParam(WinSpecLib.EXP_COSMICSENS)
    def cosmicSensitivity(self, a=None):
        "cosmic ray thershold"
        return self

# Filename    
    @experimentParam(WinSpecLib.EXP_DATFILENAME)
    def filename(self, a=None):
        "filename"
        return self

    @experimentParam(WinSpecLib.EXP_FILEINCENABLE, {True:1, False:0})
    def filenameIncrementEnable(self, a=None):
        """do filename increment (or not)"""
        return self
        
    @experimentParam(WinSpecLib.EXP_FILEINCCOUNT)
    def filenameIncrementCount(self, a=None):
        """current file increment index"""
        return self
        
    @experimentParam(WinSpecLib.EXP_FILEACCESS, {'overwrite':1, 'append':2})
    def filenameAccess(self, a=None):
        """file write mode"""
        return self
        
    @experimentParam(WinSpecLib.EXP_AUTOSAVE, {'ask':1, 'yes':2, 'no':3})
    def autoSave(self, a=None):
        """
        file auto save
        'ask', 'yes', 'no'
        """
        return self
        
# Acquisition time/images/accumulation
    @experimentParam(WinSpecLib.EXP_EXPOSURE)
    def exposure(self, a=None):
        "exposure"
        return self
        
    @experimentParam(WinSpecLib.EXP_EXPOSURETIME_UNITS, {'ms':2, 's':3, 'min':4, 'h':5})
    def exposureUnit(self, a=None):
        "exposure unit"
        return self
        
    #This doesn't seem to work
    @experimentParam(WinSpecLib.EXP_SEQUENTS)
    def nImages(self, a=None):
        "number of images"
        return self
        
    @experimentParam(WinSpecLib.EXP_ACCUMS)
    def nAccumulations(self, a=None):
        "number of accumulations"
        return self
        
    #This doesn't seem to work
    def nImagesTest(self, a=None):
       #following it a list of all variables changed by number of images in Winspec
       #none seems to work to set the number of images
       self.setParam(WinSpecLib.TRIGCNT_MAIN_BURST, a) 
       self.setParam(WinSpecLib.dt_TIFF, a) 
       self.setParam(WinSpecLib.ABS_DUAL, a) 
       self.setParam(WinSpecLib.X_LONG, a) 
       self.setParam(WinSpecLib.PROCERR_BADINPUTA, a) 
       self.setParam(WinSpecLib.SRC_DATATYPE, a) 
       self.setParam(WinSpecLib.PRC_AUTOSAVE, a) 
       self.setParam(WinSpecLib.WRONG_WAVELENGTH, a) 
       self.setParam(WinSpecLib.EC_PITG_ILLEGAL_VALUE, a) 
       self.setParam(WinSpecLib.MORPHOLOGICAL_ERODE, a) 
       self.setParam(WinSpecLib.INSTCOMM, a) 
       self.setParam(WinSpecLib.INC_EXPONENTIAL, a) 
       self.setParam(WinSpecLib.ZCROSS, a) 
       self.setParam(WinSpecLib.EXP_ERR_READONLY, a) 
       self.setParam(WinSpecLib.LUT_PROCESS_BINARY, a) 
       self.setParam(WinSpecLib.SPT_TYPE, a) 
       self.setParam(WinSpecLib.XW_DATA, a) 
       self.setParam(WinSpecLib.EXP_READ_N_WRITE, a) 
       self.setParam(WinSpecLib.DM_YDIMDET, a) 
       self.setParam(WinSpecLib.WINX_STRIPCHART, a) 
       self.setParam(WinSpecLib.USE_SINGLESHOT, a) 
       self.setParam(WinSpecLib.CALIB_MANUAL, a) 
       self.setParam(WinSpecLib.CLIP_LOW, a) 
       self.setParam(WinSpecLib.BLEMISH_REMOVAL, a) 
       self.setParam(WinSpecLib.PRCFA_OVERWRITE, a) 
       self.setParam(WinSpecLib.PRCAS_AUTO, a) 
       self.setParam(WinSpecLib.DCNG_WAITING, a) 
       self.setParam(WinSpecLib.EXP_SEQUENTS, a) 
       self.setParam(WinSpecLib.SPTP_SET_MIRROR_POS, a) 
       self.setParam(WinSpecLib.XW_COUNTS, a) 
       self.setParam(WinSpecLib.IMAGEMATH_AND, a) 
       self.setParam(WinSpecLib.SPEX_TYPE, a) 
       self.setParam(WinSpecLib.DI_PALETTE_TYPE, a) 
       self.setParam(WinSpecLib.EXPFA_APPEND, a) 
       self.setParam(WinSpecLib.EXPAS_AUTO, a) 
       self.setParam(WinSpecLib.PI_PTG, a) 
       self.setParam(WinSpecLib.COS_SPATIAL, a) 

# Data Type 
    @experimentParam(WinSpecLib.EXP_DATATYPE, {'long':2, 'byte':5, 'int16':1, 'uint16':6, 'float':3})
    def dataType(self, a=None):
        "data type"
        return self

# ADC
    @experimentParam(WinSpecLib.EXP_ADC_RATE, {'100 kHz':6, '1 MHz':11})
    def adcSpeed(self, a=None):
        "ADC speed"
        return self
        
# ROI
    @experimentParam(WinSpecLib.EXP_USEROI, {True:1, False:0})
    def useROI(self, a=None):
        """Use Roi or not (full chip)"""
        return self
        
    def ROI(self, index=1, newRoi=None):
        """
        CCD ROI (region of interest)
        
        index    index of the ROI 1,2,3...
        roiList  (xmin, xmax, xgroup, ymin, ymax, ygroup)
        """
        if newRoi is None:
            roiClass = self.WinspecExpt.GetROI(index)  
            roiList = roiClass.Get()
            return [int(i) for i in [roiList[1], roiList[3], roiList[4], roiList[0], roiList[2], roiList[5]]]
        else:
            self.clearROI()  # have to clear all ROIs because it create a new one. have not found how to just replace one
            self.useROI(True)  # clear automaticaly put in full chip. So we need to but it back to ROI
            roiClass = self.WinspecROI
            roiClass.Set(newRoi[3], newRoi[0], newRoi[4], newRoi[1], newRoi[2], newRoi[5])
            self.WinspecExpt.SetROI(roiClass)  
            
    def clearROI(self):
        self.WinspecExpt.ClearROIs()
        
#Timing
#   DM_SHUTTERCONTROL  ?
#   EXP_TIMING_MODE 
#       1  freerun
#       3  external sync
#   EXP_SHUTTER_CONTROL
#       2  disablesd closed
#       1  normal
#       3  disabled open

#    def isRunning(self):
#        #expt_is_running, status = self.WinspecExpt.GetParam( WinSpecLib.EXP_RUNNING )
#        #return expt_is_running, status
#        return self.getParam(WinSpecLib.EXP_RUNNING)
        
    def isRunning(self):
        EXP_RUNNING, status = self.getParam(WinSpecLib.EXP_RUNNING)
        EXP_RUNNING = EXP_RUNNING == True
        #print(EXP_RUNNING)
        #print(self.getParam(WinSpecLib.EXP_DATA_ACQ_STATE ))
        EXP_RUNNING_EXPERIMENT = self.getParam(WinSpecLib.EXP_RUNNING_EXPERIMENT)[0] == True
        #print(EXP_RUNNING_EXPERIMENT)
        #print(EXP_RUNNING and EXP_RUNNING_EXPERIMENT)
        return EXP_RUNNING and EXP_RUNNING_EXPERIMENT, status
        #print(self.getParam(WinSpecLib.EXP_RUNNING_APP ))
