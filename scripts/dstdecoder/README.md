# DSTDecoder

DST Trace Decoder

Build Steps
-----------
mkdir build; cd build;
cmake ..;
make clean;
make;

Integeration Tests
------------------
cd ../test;
g++ -o app Main.cpp ../build/lib/libdstdecoder.so -std=c++11 -I ../include;
bash; export LD_LIBRARY_PATH=../build/lib:$LD_LIBRARY_PATH;
./app 

Files to share w/ external vendors:
----------------------------------
./build/lib/libdstdecoder.so
./include/*.h (include directory avoids internal header files, internal header files are kept in src directory)
from test directory:
configfile.dst (vendors may not have a ready config file to parse the debug bus, this serves as an example)
Main.cpp : this file shows API Usage.

## Support
sjanarthanam@tenstorrent.com

## License
Plan to open source in near future.

## Format of Config File
The configuration files consist of multiple rows, each containing multiple columns separated by whitespace. Each row represents signal parameters organized as follows:
 Column 1: Signal Width
 Column 2: Signal Name
Additional details:
Add inline comments at the end of each line using the # symbol.
Signals are listed row by row, starting with the least significant bit (LSB). The positional mapping is as follows:
Row 1: The signal in this row corresponds to the position [Row1:Column1-1:0].
Row 2: The signal in this row corresponds to the position [Row2:Column1-1:Row1:Column1].
And so on for subsequent rows.

