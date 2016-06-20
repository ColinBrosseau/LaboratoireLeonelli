# -*- coding: utf-8 -*-
"""
@author: Colin-N. Brosseau

Read data from .spe file
Convert pixel -> wavelength (U1000)

Todo:
        remove pixel->wavelength from this file !
        applyMask should probably go away too !
        remove test()
	document code
"""

from readSPE import PrincetonSPEFile
import numpy as np

def test():
    import pylab as pl
    x,y = importSPE.importSPE('test-35.SPE', 5555)
    try:
        xx = np.append(xx, [x], axis=0)
        yy = np.append(yy, [y], axis=0)
    except NameError:
        xx = [x]
        yy = [y]

    x,y = importSPE.importSPE('test-34.SPE', 5505)
    try:
        xx = np.append(xx, [x], axis=0)
    except NameError:
        xx = [x]

    pl.plot(xx, yy, '.')
    pl.show()

def applyMask(x, y, mask):
    """
    Apply a mask over the data (only keep index given in mask)
    """
    return x[mask], y[:, mask]

def importSPE(filename, centralWavelength, maskCCD=[175, 1125]):
    """
    Import .spe file and calculate corresponding wavelength
    """
    x, y, accTime = readSPE(filename)  # import raw data from file
    x = pixel2A(x, centralWavelength)  # convert unit from pixels to A
    maskCCD = np.arange(maskCCD[0], maskCCD[1]+1)  # mask for good pixels
    x, y = applyMask(x, y, maskCCD)  # only keep good pixels
    return x, y
    

def readSPE(filename):
    data = PrincetonSPEFile(filename)
    y = np.squeeze(data.getData(), axis=1)
    #y = y.T
    x = np.arange(0,np.size(y, 1))
    accTime = data.getAccumulationTime()
    return x, y, accTime

def pixel2A(pixel, positionSpectrometer, nameSpectrometer='U1000', errorSpectro=0, cameraName='CCD'):
    """
    Convert from pixel index to wavenumber (A)
   """
    #indexAir = 1.00029  # index of refraction of air
    disper = dispersion(positionSpectrometer, nameSpectrometer)
    #centerPixel = round(len(pixel)/2)
    centerPixel = round(numberPixel(cameraName=cameraName)/2)
    #print(centerPixel)
    #print(errorSpectro)
    A = disper * (pixel - centerPixel) + positionSpectrometer + errorSpectro
    #print(A[centerPixel])
    #return A * indexAir
    return A  # A vérifier

def dispersion(positionSpectrometer, nameSpectrometer='U1000'):
    """
    Dispersion of the spectrometer
    """
    disper = np.nan

    if nameSpectrometer == 'U1000':
        # Parametres prit integralement de la version Matlab 
        fact = 1.812402816604375e-004  # (A)
        dv = 2.341131e-001  # (B)
        # Parametres fites sur des mesures sur le pic Ne @ 6929.4673 
        #fact = 1.812402816604375e-004  # Fixe (A)
        #dv = 0.19583658  # (B)
        #fact = 1.28884458661e-09  # Fixe (A)
        #dv = 1.55055761919  # (B)
        groove = 1800  # groove/mm
        focal = 1000  # focal length (mm)
        stage = 2  # number of stages
        disper = 1e7/(groove * focal * stage) * np.cos(np.arcsin(fact*positionSpectrometer/2)+dv/2)/50

    return disper

def numberPixel(cameraName):
    if cameraName == 'CCD':
        return 1340
