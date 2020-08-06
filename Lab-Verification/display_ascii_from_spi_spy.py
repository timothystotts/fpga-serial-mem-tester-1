# -*- coding: utf-8 -*-
"""
Created on Tue Jul 28 16:44:13 2020

@author: timot
"""

import io
import sys
import re

class AnalogDiscoverySpiSpyParser:
    EscCharacters = ["1B",]
    PartsCopi = ["c", "cp"]
    PartsCipo = ["p", "cp"]
    rexData = re.compile(r"^Data[:][ ]")

    def __init__(self, fileName):
        self._currentLine = None
        self._ioParts = None
        self._fh = open(fileName, "r")
  
    def readCurrentLine(self):
        self._currentLine = self._fh.readline()
        if self._currentLine:
            return True
        else:
            return False
        
    def parseDataParts(self):
        if self._currentLine:
            if self.rexData.match(self._currentLine):
                dataParts = self._currentLine.split(":")
                lineParts = dataParts[1].split(",")
                self._ioParts = []
                for linePart in lineParts:
                    self._ioParts.append(linePart.split("|"))
                return True
            else:
                return False
        else:
            return False
    
    def close(self):
        self._fh.close()
        
    def getIoParts(self):
        return self._ioParts
    
    def getIoPartsAsAscii(self):
        self._strCopi = ""
        self._strCipo = ""
        cCopiEsc = []
        cCipoEsc = []
        self._asciiCopi = ""
        self._asciiCipo = ""
        
        for ioPart in self.getIoParts():
            if (len(ioPart) == 2):
                cCopi = ioPart[0].strip()
                cCipo = ioPart[1].strip()
                
                if (cCopi not in self.EscCharacters):
                    self._strCopi += cCopi
                else:
                    cCopiEsc.append(len(self._strCopi))
                    
                if (cCipo not in self.EscCharacters):
                    self._strCipo += cCipo
                else:
                    cCipoEsc.append(len(self._strCipo))
    
        ba = str(bytearray.fromhex(self._strCopi).decode())
        for b in range(len(ba)):
            if (len(cCopiEsc) > 0):
                l = cCopiEsc[0]
                while(b == l):
                    cCopiEsc.pop(0)
                    self._asciiCopi += r"\x"
                    if (len(cCopiEsc) > 0):
                        l = cCopiEsc[0]
                    else:
                        l = -1
                
            self._asciiCopi += ba[b]

        ba = bytearray.fromhex(self._strCipo).decode()
        for b in range(len(ba)):
            if (len(cCipoEsc) > 0):
                l = cCipoEsc[0]
                while(b == l):
                    cCipoEsc.pop(0)
                    self._asciiCipo += r"\x"
                    if (len(cCipoEsc) > 0):
                        l = cCipoEsc[0]
                    else:
                        l = -1
                
            self._asciiCipo += ba[b]

    def getCurrentLine(self):
        return self._currentLine
    
    def getStrCopi(self):
        return self._strCopi
    
    def getStrCipo(self):
        return self._strCipo
    
    def getAsciiCopi(self):
        return self._asciiCopi
    
    def getAsciiCipo(self):
        return self._asciiCipo
        

def usage():
    print("%s : <c | p | cp> <filename.txt>" % (sys.argv[0], ))
    sys.exit(1)

def main(filename, partFlag):
    fh2 = io.open(filename + "_parse.txt", "w")
    i = 0
    
    adssp = AnalogDiscoverySpiSpyParser(filename)
    
    while(adssp.readCurrentLine()):
        i = i + 1
        if adssp.parseDataParts():            
            adssp.getIoPartsAsAscii()
            
            if (partFlag in adssp.PartsCopi):                
                fh2.write(adssp.getStrCopi())
                fh2.write("\n")
                fh2.write(adssp.getAsciiCopi())
                fh2.write("\n")

            if (partFlag in adssp.PartsCipo):
                fh2.write(adssp.getStrCipo())
                fh2.write("\n")
                fh2.write(adssp.getAsciiCipo())
                fh2.write("\n")

            fh2.write("\n")
            
    adssp.close()
    fh2.close()

if __name__ == "__main__":
    if (len(sys.argv) == 3):
        main(sys.argv[2], sys.argv[1])
    elif (len(sys.argv) == 1):
        partFlag = "c"
        fileNames = ["SF-Tester-Design-AXI/CLS SPI Spy Capture of Boot-Time Display at ext_spi_clk SCK.txt",
                     "SF-Tester-Design-AXI/CLS SPI Spy Capture of First-Iteration Display at ext_spi_clk SCK.txt",
                     "SF-Tester-Design-VHDL/CLS SPI Spy Capture of Boot-Time Display at 50 KHz SCK.txt",
                     "SF-Tester-Design-VHDL/CLS SPI Spy Capture of First-Iteration Display at 50 KHz SCK.txt"]
        
        for fileName in fileNames:
            #try:
                main(fileName, partFlag)
            #except Exception as ex:
            #    print("Exception raised {}, {} : {}".format(fileName, type(ex), str(ex)))
            
    else:
        usage()
