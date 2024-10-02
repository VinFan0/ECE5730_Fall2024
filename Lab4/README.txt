Simulated Annealing
 ECE 5730 / Lab 4 / 10/10/24
 Ryan Beck, Jared Bronson

 Compiling Code
----------------------------
The code complies via g++
    g++ -o build place.cpp

 Running Program
----------------------------
The program is run via command line
    Windows:
    ./build.exe
    Linux: 
    ./build

The default grid created for placing nodes is 5x5 with 5 nodes. 
The user may include a single integer commandline argument to change the number of nodes.i.e.
    ./build.exe 4   would create a 5x5 with 4 nodes.
