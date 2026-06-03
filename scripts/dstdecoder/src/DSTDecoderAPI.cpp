// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#include <iostream>
#include <bitset>
#include <cstring>
#include <array>
#include <vector>
#include <memory>
#include <cstdint> 
#include "DSTPacket.h"
#include "DSTDataPacket.h"
#include "DSTTimestampPacket.h"
#include "FrameWalker.h"
#include "DSTDecoder.h"
#include "DSTDecoderAPI.h"

//returns success/failure, Decodes the i_buffer and writes the result to a file named as decodedDST<chunkNbr>
bool decodeSideBandTrace (unsigned int chunkNbr, uint8_t* i_buffer, int i_buffer_size,
                          const std::string& configfile_path, const std::string& working_directory) {
   bool result = 1;
   std::string configfile = configfile_path + "/" + "configfile.dst";
   DSTDecoder* DSTDecoder1 = new DSTDecoder(configfile,i_buffer,i_buffer_size,chunkNbr,working_directory);
   result = 0;
   return result;
} 

// returns chunkInfo which consist of chunk number (C) and trace line index [which will be mapped to line number inside the decoded chunk file (L)] of the first timestamp which is >= requested input timestamp.
chunkInfo_s timestampLookUp (uint64_t timestamp,
                             const std::string& working_directory) {
   DSTDecoder* DSTDecoder1 = new DSTDecoder();
   return DSTDecoder1->timestampLookUp(timestamp,1,working_directory);
}

//rtrung Debug Signal Information
DSTSignalsInfo_s getDSTSignalsInfo (const std::string& configfile_path){
   std::string configfile = configfile_path + "/" + "configfile.dst";
   return DSTDecoder::getDSTSignalsInfo(configfile);
}
