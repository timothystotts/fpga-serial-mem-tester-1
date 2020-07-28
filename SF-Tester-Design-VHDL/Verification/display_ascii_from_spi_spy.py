# -*- coding: utf-8 -*-
"""
Created on Tue Jul 28 16:44:13 2020

@author: timot
"""

import io
import sys
import re

EscCharacters = ["1B",]
PartsCopi = ["c", "cp"]
PartsCipo = ["p", "cp"]
rexData = re.compile(r"^Data[:][ ]")

def usage():
    print("%s : <c | p | cp> <filename.txt>" % (sys.argv[0], ))
    sys.exit(1)

def main(filename, partFlag):
    fh = io.open(filename, "r")
    fh2 = io.open(filename + "_parse.txt", "w")
    lines = fh.readlines()
    i = 0
    
    for line in lines:
        strCopi = ""
        strCipo = ""
        i = i + 1
        if rexData.match(line):
            fh2.write("Line %d" % (i,))
            fh2.write("\n")
            dataParts = line.split(":")
            lineParts = dataParts[1].split(",")
            ioParts = []
            for linePart in lineParts:
                ioParts.append(linePart.split("|"))
            
            for ioPart in ioParts:
                if (len(ioPart) == 2):
                    cCopi = ioPart[0].strip()
                    cCipo = ioPart[1].strip()
                    
                    if (cCopi not in EscCharacters):
                        strCopi += cCopi
                    # else:
                    #     strCopi += "ESC"
                        
                    if (cCipo not in EscCharacters):
                        strCipo += cCipo
                    # else:
                    #     strCipo += "ESC"
            
            if (partFlag in PartsCopi):
                fh2.write(strCopi)
                fh2.write("\n")
                fh2.write(bytearray.fromhex(strCopi).decode())
                fh2.write("\n")
            if (partFlag in PartsCipo):
                fh2.write(strCipo)
                fh2.write("\n")
                fh2.write(bytearray.fromhex(strCipo).decode())
                fh2.write("\n")
            fh2.write("\n")
            
    fh.close()
    fh2.close()

if __name__ == "__main__":
    if (len(sys.argv) > 2):
        main(sys.argv[2], sys.argv[1])
    else:
        usage()
