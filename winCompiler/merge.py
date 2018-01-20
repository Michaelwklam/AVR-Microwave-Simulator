# Merges modules with project.asm

import glob
read_files = glob.glob("../modules/*.asm")

with open("project.asm", "w") as outfile:
    f = open("../project.asm", "r")
    lines = f.readlines()
    for line in lines:
        if line.find("<macros>") > -1:
            a = open("../modules/macros.asm", "r")
            alines = a.readlines()
            for aline in alines:
                outfile.write(aline)
        else:
            outfile.write(line)

    for f in read_files:
        with open(f, "r") as infile:
            if infile.name.find("macros.asm") == -1:
                outfile.write("\n; "+infile.name+" ========================\n")
                mylines = infile.readlines()
                for myline in mylines:
                    outfile.write(myline)