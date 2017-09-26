# -*- coding: utf-8 -*-
"""
Created on Tue Aug 18 09:34:26 2015

@author: Colin-N. Brosseau
""" 

"""
TODO
    fix file numbering while using mesureRange
    while using mesureRange, don't use save from mesure
"""
 
import U1000
import WinspecCOM as Winspec
import RacalDana
import os
import time
import importSPE
import numpy as np
import spikes
import shutil
import testMerge
import pylab as pl
import yaml
import collections

def nextFile(folder, basemane, extension):
    """
    next available (not already present) file in the 'directory' of the form
    basemane + <number> + extension
    
    If no file exist, returns
        basemane + '1' + extension
    
    ex.: 
    if test-1.txt, test-2.txt, test-5.txt  these files already exist in '.',
        nextFile('.', 'test-1', '.txt')
    returns 
        test-6.txt
    """    
    
    # We need at least one of the criteria.
    assert isinstance(folder, str)
    assert isinstance(basemane, str)
    assert isinstance(extension, str)

    highest_num = 0
    for file in os.listdir(folder):
        if file.startswith(basemane) and file.endswith(extension) :
            a = int(file.replace(basemane, '', 1).replace(extension, ''))
            if a > highest_num:
                highest_num = a
    
    return basemane + str(highest_num+1) + extension

def ordered_dump(data, stream=None, Dumper=yaml.SafeDumper, default_flow_style=None, **kwds):
    """
    convert dictionnary as yaml, ordered
    
    https://stackoverflow.com/questions/5121931/in-python-how-can-you-load-yaml-mappings-as-ordereddicts
    usage:
        ordered_dump(data)
    """
    class OrderedDumper(Dumper):
        pass
    def _dict_representer(dumper, data):
        return dumper.represent_mapping(
            yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
            data.items())
    OrderedDumper.add_representer(collections.OrderedDict, _dict_representer)
    return yaml.dump(data, stream, OrderedDumper, default_flow_style=default_flow_style, **kwds)

class Mesure():
    
    def __init__(self, position, laser=False, port='COM25', index=0, baseFilename=None):
        """
        position
            wavelength on the the display of the spectrometer (A)
        laser
            wavelength of the laser (A)
            Used for measures in cm-1
            False (default) means undefined
        """
        self.CCD = Winspec.winspec()  # CCD Detector
        try:
            self.PMT = RacalDana.RacalDana()  # PMT Detector
        except:
                pass
        self.spectrometer = U1000.U1000(port)  # Spectrometer
        self.spectrometer.displayPosition = position
        self.laser = laser
        self.index = index
        self.baseFilename = baseFilename
        if self.baseFilename is None:
            self.baseFilename = time.strftime("%y%m%d")
        
    def close(self):
        """
        Close communication port related to the spectrometer and PMT
        """
        print('Current self.spectrometer.posi(): ' + str(self.A()) + ' A')
        print('Current self.spectrometer.positionOffset: ' + str(self.spectrometer.positionOffset) + ' A')
        print('Current self.laser: ' + str(self.laser) + ' A')
        
        self.spectrometer.close()
        try:
            self.PMT.close()
        except:
            pass        

    def setLaser(self, laser):
        """
        Set laser wavelength (for measurement in cm-1) (A)
        """
        self.laser = laser
        
    def setPosition(self, position):
        """
        Set spectrometer wavelength (A)
        """
        self.spectrometer.posi(position)
        
    def wavenumber(self, wavenumber=None):
        """
        Set/Get the spectrometer to wavenumber (cm-1)
        
        wavenumber
            None (default): return current wavenumber
            number : goto to this wavenumber
        """
        if wavenumber is None:
            return self.A2wn(self.A())
        else:
            L = self.wn2A(wavenumber)  # corresponding wavelength (A)
            print(str(round(wavenumber, 2)) + ' cm-1,  ' + str(round(L, 3)) + ' A' )
            self.spectrometer.goto(L)  # goto this wavelength

    def A(self, position=None):
        """
        Set/Get the spectrometer to position (A)
        
        position
            None (default): return current position
            number : goto to this position
        """
        if position is None:
            return float(self.spectrometer.posi())
        else:
            print(str(round(position, 3)) + ' A' )
            self.spectrometer.goto(position)

    def stop(self):
        """Stop movement of the spectrometer"""
        self.spectrometer.stop()

#    def acquisition(self):
#        #self.S.start()  # Start measurement
#        return self.CCD.measureSimple(exposureTime=.33, images=5)  # Perform measurement and return the filename of the new file

            
    def __positionsRange(self, start, end, window, nOverlap=2):
        """
        Calculate positions for measuring over a range of position
        
        start
            First position to be measured
        end
            Last position to be measured
        window
            width of a single measurement window
        nOverlap
            number of time a single point will be measured (form different detector position)
        """
        if end ==  start:
            return start
        else:
            #numberMeasurement = nOverlap*(end-start)/window + nOverlap - 1
            #print(numberMeasurement)
            positionStart = (.5 - (nOverlap-1)/nOverlap) * window + start    
            positionEnd = -(.5 - (nOverlap-1)/nOverlap) * window + end
            out = np.arange(positionStart, positionEnd+window/nOverlap, window/nOverlap)
            #print(out)
            #print(len(out))
            return np.array(out)
    
    def measureRange(self, Range , nOverlap=3, accTime=1, images=False, accumulations=1, unit='cm-1', maskCCD=None, plot=True, spectroSlits=10, detector='CCD', rootFilename='.', baseFilename=None, sample='', comment=''):
        """
        Measure in a range of position
        Each point is garanted to come from the have the same number of points
        
        Range
            Range of the of measurement
            [Begin, End]
            End is optionnal. If omited, will take one window centered on Start
        nOverlap
            number of time the same position will be measured 
            (the CCD detector will be centered at different positions)
            (integer)
        accTime
            accumulation time per position per image (second)
            (float)
        images
            number of measurement from the same detector centered position
            If False (default) automaticaly choose the best setting
            (integer)
        accumulations
            number of accumulation per image
            The accumulations are done by the camera itself.
            (integer)
        unit
            unit of position
                'A'
                'cm-1' (default)
        maskCCD
            valid index on the CCD detector
                [firstValidIndex, lastValidIndex] (integers)
                ex.: [175, 1125] (default)
        spectroSlits
            width (mm) of the intermediary spectrometer slits
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10
            This determine the camera maskCCD
            (integer)
        detector
            Detector name
                'CCD'
                'PMT'
            (string)
        rootFilename
            directory where to save the data
            (string)            
        baseFilename
            leading part of filename (will be numbered)
                None: get current date in format AAMMDD
            (string)
        """
        def saturation(y):
            """Return True if the is a least one pixel saturated on the camera"""
            return np.any(y>65000)
           
        tInitial = time.time()           
           
        if baseFilename is None:
            baseFilename = time.strftime("%y%m%d-")

        try:
            start = Range[0]  
            try:
                end = Range[1]
            except IndexError:
                end = Range[0]
                nOverlap = 1
        except TypeError:
            start = Range
            end = Range
            nOverlap = 1
        try:
            step = Range[2]
        except TypeError:
            step = 1
        except IndexError:
            step = 1
            
        print(str(start) + " -> " + str(end))
        
        if detector == 'CCD':
            if unit == 'cm-1':  # convert to A
                start = self.wn2A(start)
                end = self.wn2A(end)          

            if maskCCD is None:
                if spectroSlits == 10:
#                    maskCCD = [163, 1143]
#                    maskCCD = [170, 1120]  # corrige le 12 novembre 2015
                    maskCCD = [200, 1110]  # corrige le 8 septembre 2016
                elif spectroSlits == 9:
                    maskCCD = [169, 1095]
                elif spectroSlits == 8:
                    maskCCD = [220, 1041]
                elif spectroSlits == 7:
                    maskCCD = [277, 983]
                elif spectroSlits == 6:
                    maskCCD = [331, 928]
                elif spectroSlits == 5:
                    maskCCD = [391, 868]
                elif spectroSlits == 4:
                    maskCCD = [442, 815]
                elif spectroSlits == 3:
#                    maskCCD = [495, 762]  # ne semble plus valide
                    maskCCD = [580, 850]  # 18 avril 2016
                elif spectroSlits == 2:
                    maskCCD = [555, 706]
                elif spectroSlits == 1:
                    maskCCD = [619, 661]
            
            x = importSPE.pixel2A(np.array([maskCCD[0], maskCCD[1]]), start) 
            #print(x)
            largeurFenetre = abs(x[0] - x[1])
            #mprint(largeurFenetre)
            offset = -np.mean(x) + start  
            # small correction if maskCCD is not centered on the center of the detector
            # but we move the spectrometer assuming that the center of the detector will be the center of the detection region
            #print(offset)
            #print(start)
            #positions = self.__positionsRange(start, end, largeurFenetre, nOverlap)
            positions = self.__positionsRange(start+offset, end+offset, largeurFenetre, nOverlap)
        elif detector == 'PMT':
            positions = np.linspace(start, end, (end-start)/step+1)  
            if unit == 'cm-1':  # convert back to A
                positions = self.wn2A(positions)
                start = self.wn2A(start)
                end = self.wn2A(end)          
        
        print('A  :')
        print(str(np.round(positions, 3)))

        if unit == 'cm-1':  # convert back to cm-1
            positions = self.A2wn(positions)
            start = self.A2wn(start)
            end = self.A2wn(end)
            print('cm-1 :')
            print(str(np.round(positions, 1)))       
        
#        #test for acquisition time - images
#        testAccTime = 0.001
#        accTimeFound = False
#        while not accTimeFound:
#            print("Test accumulation time: " + str(testAccTime))
#            x, y = self.measure(positions[0], accTime=testAccTime, images=1, unit=unit, maskCCD=[0, 1339], plot=False)        
#            if saturation(y):
#                accTimeFound = True
#            else:
#                amplitude = np.max(y)
#                print('Amplitude: ' + str(amplitude))
#                if amplitude > 1000:
#                    testAccTime = testAccTime * 60000/amplitude
#                    accTimeFound = True
#                    #print(testAccTime)
#                else:
#                    testAccTime = testAccTime * 1.4
#                    #testAccTime = testAccTime * 1.01
#                    print(testAccTime)
#        print("Best accumulation time: " + str(testAccTime))
#        x, y = self.measure(positions[0], accTime=testAccTime, images=1, unit=unit, maskCCD=[0, 1339], plot=False)        
        
        #accTime        
        #images
        #accumulations
        #si le temps d'accumulation est trop petit (genre 0.001 s), utiliser plus d'une accumulation
        #s'arranger pour avoir au moins 5 images.
                
        #This should be corrected/checked
        #accTime = accTime/nOverlap
        if detector == 'CCD':
            x, y = self.measure(positions, accTime=accTime, images=images, accumulations=accumulations, unit=unit, maskCCD=maskCCD, plot=False)
            #total measurement time
            tMeasure = time.time() - tInitial        

            if end > start:
                I = np.where(np.all([x>=start, x<=end], axis=0))[0]
                #print(I)
                x = x[I]
                y = y[I]
            outFilename = nextFile(rootFilename, baseFilename, '.csv').replace('.csv', '', 1)
            #np.savez_compressed(outFilename, x=x, y=y)
            #print("Data saved in " + outFilename + ".npz" )
            toSave = np.append([x],[y], axis=0).transpose()
            np.savetxt(outFilename + ".csv", toSave, delimiter=',', fmt='%.8e', header='Position,Intensity', comments='')
            print("Data saved in " + outFilename + ".csv" )
            import zipfile
            zf = zipfile.ZipFile(outFilename + ".csv.zip", "w", zipfile.ZIP_DEFLATED); 
            zf.write(outFilename + ".csv", outFilename + ".csv")
            zf.close()
            print("Data saved in " + outFilename + ".csv.zip" )
            #export experiment conditions
            #import yaml
            #import collections
            #state = collections.OrderedDict()
            state = {}
            state['spectrometer'] = {}
            state['spectrometer']['positionOffset'] = self.spectrometer.positionOffset
#            state['spectrometer']['speedSlow'] = self.spectrometer.speedSlow()
#            state['spectrometer']['speedFast'] = self.spectrometer.speedFast()
            state['spectrometer']['speedSlow'] = self.spectrometer.speedSlow
            state['spectrometer']['speedFast'] = self.spectrometer.speedFast
            state['detector'] = {}
            state['detector']['name'] = detector
            state['detector']['actualTemperature'] = self.CCD.actualTemperature()[0]
            state['detector']['setTemperature'] = self.CCD.setTemperature()[0]
            state['detector']['adcSpeed'] = self.CCD.adcSpeed()[0]
            state['detector']['cosmicMode'] = self.CCD.cosmicMode()[0]
            state['detector']['cosmicSensitivity'] = self.CCD.cosmicSensitivity()[0]
            state['outFilename'] = outFilename + ".csv"
            state['configFilename'] = outFilename + ".yaml"
            state['Range'] = Range
            state['nOverlap'] = nOverlap
            state['accTime_s'] = accTime
            state['images'] = images
            state['accumulations'] = accumulations
            state['unit'] = unit
            state['maskCCD'] = maskCCD
            state['plot'] = plot
            state['spectroSlits_mm'] = spectroSlits
            state['sample'] = sample
            state['comment'] = comment
            state['date'] = time.strftime('%Y%m%d%H%M%S')
            state['measureTime_s'] = tMeasure
            state['laser_A'] = self.laser
            print(ordered_dump(state))
            with open(outFilename + ".yaml", 'w') as outfile:
                outfile.write(ordered_dump(state))
        elif detector == 'PMT':
            x, y = self.measurePMT(positions, accTime=accTime, unit=unit, plot=False)

        #y = y * nOverlap
        if plot:
            pl.cla()
            pl.plot(x,y)
            pl.xlabel(unit)

        return x, y

    def measurePMT(self, positions, accTime=1, unit='cm-1', plot=True):
        """
        Perform a measurements at positions for accTime (per position)
        Filter data from spikes (if images >=5)
        Calculate position (unit).
        Merge all windows to one single array. It is not garanted that each point will have the same number of merged points
        
        positions
            array of positions to measure
            ex.: [5000, 5020, 5040]
            ex.: numpy.arange(5000, 5100, 20)
        accTime
            acquisition time per position (per image) (s)
        unit
            positions unit
            'A', 'cm-1'
        plot
            plot result or not
        """
        self.log = open("log.txt","w") #opens file with name of "test.txt"
        self.log.write("#position(A), filename" + "\n")
               
        if len(np.shape(positions)) < 1:  # Special case if there is just one position
            positions = np.array([positions])
        #print(positions)
        self.index = self.index + 1
        detectorBaseFilename = self.baseFilename + '-' + str(self.index)

        x = np.empty_like(positions)
        y = np.empty_like(positions)
        for i in range(len(positions)):
            if unit == 'cm-1':
                self.wavenumber(positions[i])
            elif unit == 'A':
                self.A(positions[i])
            y[i] = self.PMT.measure(exposureTime=accTime)  # Perform measurement
            message = str(self.spectrometer.posi())
            self.log.write(message)
            x[i] = self.spectrometer.getRealPosition() # Replace that by a getRealPosition in Spectrometer class
 
            #y = spikes.removeSpike1D(y, threshold=3, kernelSize=5)  # remove spikes (bad pixels)
        
        if unit == 'cm-1':
#            x = 1e8 * (1/self.laser - 1/x)  # convert to A
            x = self.A2wn(x)  # convert to A
        
        if plot:
            pl.cla()
            pl.plot(x,y)
            pl.xlabel(unit)
            #time.sleep(1)
        
        outFilename = detectorBaseFilename
        np.savez_compressed(outFilename, x=x, y=y)
        print("Data saved in " + outFilename + ".npz" )
        toSave = np.append([x],[y], axis=0).transpose()
        np.savetxt(outFilename + ".txt", toSave)
        print("Data saved in " + outFilename + ".txt" )

        self.log.close()
        logFile = outFilename + ".log"
        shutil.copy("log.txt", logFile)       
        print("Logfile in    " + logFile )
        return x, y

    def measure(self, positions, accTime=1, images=False, accumulations=1, unit='cm-1', maskCCD=[175, 1125], plot=True, saveFile=False):
        """
        Perform a measurements at positions for accTime (per position)
        Filter data from spikes (if images >=5)
        Calculate position (unit).
        Merge all windows to one single array. It is not garanted that each point will have the same number of merged points
        
        positions
            array of positions to measure
            ex.: [5000, 5020, 5040]
            ex.: numpy.arange(5000, 5100, 20)
        accTime
            acquisition time per position (per image) (s)
        images
            (integer)
            number of images per position
            starting at 5, there will be a nice despike feature activated
            if False (default), will guess best value. Total accumulation time per position will be kept to accTime
        accumulations
            number of accumulation per image
            The accumulations are done by the camera itself.
            (integer)
        unit
            positions unit
            'A', 'cm-1'
        maskCCD
            first and last valid pixels on the CCD
        plot
            plot result or not
        """
        self.log = open("log.txt","w") #opens file with name of "test.txt"
        self.log.write("#position(A), filename" + "\n")

        # If images is False, calculate itsbest values for both accTime and images
        if not images:
            if accTime <= 60:
                images = 1
            elif accTime <= 25*60:
                accTime = accTime/5
                images = 5
            else:
                images = int(np.round(accTime/(5*60)))
                accTime = accTime/images
                
        maskCCD = np.arange(maskCCD[0], maskCCD[1]+1)  # mask for good pixels
        
        #if len(np.array(positions)) > 1:
        #    print("Positions de mesure: " + str(positions))
        # self.index = self.index + 1
        #self.CCD.baseFilename = self.baseFilename + '-' + str(self.index)
        #self.CCD.filenameIndex = 0
            
        #print(np.shape(positions))
        if len(np.shape(positions)) < 1:  # Special case if there is just one position
            positions = np.array([positions])
        #print(positions)
        for i in positions:
            self.CCD.stop()
            #print("Goto: " + str(i))
            if unit == 'cm-1':
                self.wavenumber(i)
            elif unit == 'A':
                self.A(i)
            #self.acquisition()  
            #time.sleep(accTime + 2)
            #lastFile = self.getLastFileName()
            self.index = self.index + 1
            #print("new measure")
            detectorBaseFilename = self.baseFilename + '-' + str(self.index)
            x, y, lastFile = self.CCD.measureSimple(exposureTime=accTime, images=images, accumulations=accumulations, filename=detectorBaseFilename)  # Perform measurement and return the filename of the new file
            #print(np.shape(x))
            #print(np.shape(y))
            #print("lastfile: " + lastFile)
            message = str(self.spectrometer.posi()) + ", "  + lastFile + "\n"
            self.log.write(message)
            realPosition = self.spectrometer.getRealPosition() # Replace that by a getRealPosition in Spectrometer class
 
            #x,y = importSPE.importSPE(lastFile, realPosition, maskCCD=maskCCD)
            #print(realPosition)
            x = importSPE.pixel2A(x, realPosition)  # convert unit from pixels to A
            #Apply mask for good pixels         
            x, y = importSPE.applyMask(x, y, maskCCD)  # only keep good pixels
            #print(str(x[0]) + "  " +  str(x[-1]))

            y = spikes.cleanSpikes(y)  # remove spikes (different images)
            y = spikes.removeSpike1D(y, threshold=3, kernelSize=5)  # remove spikes (bad pixels)
            try:
                xx = np.append(xx, [x], axis=0)
                yy = np.append(yy, [y], axis=0)
            except NameError:
                xx = [x]
                yy = [y]
                
        # export raw data
        #np.save('dumpX.npy', xx)        
        #np.save('dumpY.npy', yy)  
        np.savez('dumpXY.npz', x=xx, y=yy)
                
        x,y = testMerge.merge(xx, yy)
        
        if unit == 'cm-1':
#            x = 1e8 * (1/self.laser - 1/x)  # convert to A
            x = self.A2wn(x)  # convert to A
        
        if plot:
            pl.cla()
            pl.plot(x,y)
            pl.xlabel(unit)
            #time.sleep(1)
        
        if saveFile:
            outFilename = lastFile.replace('.SPE', '')
            np.savez_compressed(outFilename, x=x, y=y)
            print("Data saved in " + outFilename + ".npz" )
            toSave = np.append([x],[y], axis=0).transpose()
            np.savetxt(outFilename + ".txt", toSave)
            print("Data saved in " + outFilename + ".txt" )
            
            self.log.close()
            logFile = outFilename + ".log"
            shutil.copy("log.txt", logFile)       
            print("Logfile in    " + logFile )
            return x, y, outFilename
        else:
            return x, y

    def wn2A(self, energy):
        """
        Convert energy (cm-1) to spectrometer position
        """
        return U1000.cm12A(energy, self.laser)

    def A2wn(self, position):
        """
        Convert spectrometer position (A) to energy (cm-1)
        """
        return U1000.A2cm1(position, self.laser)

        
    def calibrateOffset(self, referencePosition, approximativeOffset=False):
        """
        Calibrate the spectrometer position with a known (strong) peak
        referencePosition    wavelgnth of the peak
        """
        import calibrateSpectrometer as cal 
        
        if approximativeOffset:
            # Get approximative offset
            self.spectrometer.positionOffset = 0
            x, y = self.measure(referencePosition, .1, images=5, unit='A')
            I = y.argmax()
            readPosition = x[I]
            approximativeOffset = referencePosition - readPosition
            
        self.spectrometer.positionOffset = 0
        self.spectrometer.positionOffset = cal.getSpectrometerOffset(referencePosition, self, approximativeOffset=approximativeOffset)
        
    #Following two function will be used (in future) by the GUI
    #Need to be rewrited to match measureRange
#    def measureFull(self,  positions, accTime, images=False, unit='cm-1'):
#        self.log = open("log.txt","w") #opens file with name of "test.txt"
#        self.log.write("#position(A), filename" + "\n")
#        
#        gen = self.measureGenerator(self, positions, accTime, images, unit)  
#        #x, y, message = next(gen)
#        
#        for x, y, message in gen():
#            # test for possible pause (for example in a GUI)
#            # test for stop (exit this loop but save data)
#            self.log.write(message)
#            try:
#                xx = np.append(xx, [x], axis=0)
#                yy = np.append(yy, [y], axis=0)
#            except NameError:
#                xx = [x]
#                yy = [y]
#                    
#        x,y = testMerge.merge(xx,yy)
#        
#        np.savez_compressed(self.CCD.baseFilename, x=x, y=y)
#        print("Data saved in " + self.CCD.baseFilename + ".npz" )
#
#        self.log.close()
#        logFile = self.CCD.baseFilename + ".log"
#        shutil.copy("log.txt", logFile)       
#        print("Logfile in    " + logFile )
#        
#    def measureGenerator(self, positions, accTime, images=False, unit='cm-1'):
#        # If images is False, calculate itsbest values for both accTime and images
#        if not images:
#            if accTime <= 60:
#                images = 1
#            elif accTime <= 25*60:
#                accTime = accTime/5
#                images = 5
#            else:
#                images = np.round(accTime/(5*60))
#                accTime = accTime/images
#                
#        print(positions)
#        self.index = self.index + 1
#        self.CCD.baseFilename = self.baseFilename + '-' + str(self.index)
#        self.CCD.filenameIndex = 0
#                
#        for i in positions:
#            if unit == 'cm-1':
#                self.wavenumber(i)
#            elif unit == 'A':
#                self.A(i)
#            #self.acquisition()  
#            #time.sleep(accTime + 2)
#            #lastFile = self.getLastFileName()
#            lastFile = self.CCD.measureSimple(exposureTime=accTime, images=images)  # Perform measurement and return the filename of the new file
#            print(lastFile)
#            message = str(self.spectrometer.posi()) + ", "  + lastFile + "\n"
#            x,y = importSPE.importSPE(lastFile, self.spectrometer.posi())
#            y = spikes.cleanSpikes(y)  # remove spikes
#            yield x, y, message            


#    def getLastFileName(self):
#        a = [(x[0], time.ctime(x[1].st_ctime)) for x in sorted([(fn, os.stat(fn)) for fn in os.listdir(".")], key = lambda x: x[1].st_ctime)]
#        return a[-1][0]


#OLD unused function
#    def calibrate(self, referencePosition, accTime=1, images=False, unit='A'):
#        """
#        Calibrate the spectrometer position with a know (strong) peak
#        """
#        self.spectrometer.positionOffset = 0
#        print("spectrometer.posi() " + str(self.spectrometer.posi()))
#        x, y = self.measure(referencePosition, accTime, images=images, unit=unit)
#        
#        from lmfit import  Model
#        def gaussian(x, amplitude, position, width):
#            "1-d gaussian: gaussian(x, amplitude, position, width)"
#            return (amplitude/(np.sqrt(2*np.pi)*width)) * np.exp(-(x-position)**2 /(2*width**2))
#        mod = Model(gaussian)
#        I = y.argmax()
#        result = mod.fit(y, x=x, amplitude=y[I], position=x[I], width=1)
#        readPosition = result.best_values['position']
#         
#        #I = np.argmax(y)  # Index of the maximum
#        #readPosition = x[I]  # 
#        
#        print('read position: ' + str(readPosition))
#        print('referencePosition position: ' + str(referencePosition))
#        self.spectrometer.positionOffset = referencePosition - readPosition
#        print("spectrometer.posi() " + str(self.spectrometer.posi()))
#        print('positionOffset: ' + str(self.spectrometer.positionOffset))
#        
#        return x, y

