// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#ifndef DSTDECODER_H
#define DSTDECODER_H

#include <iostream>
#include <bitset>
#include <cstring>
#include <array>
#include <vector>
#include <memory>
#include <fstream>
#include <string>
#include <unordered_map>
#include <limits>
#include <cstdint> // for uint64_t
#include "FrameWalker.h"
#include "DstDecoderAPIDataType.h" 


class DSTDecoder {

public:
    DSTDecoder();
    DSTDecoder(const std::string& config_file, const std::string& chunk_file_basename, unsigned int number_of_dst_samples,const std::string& working_directory);
    DSTDecoder(const std::string& config_file, const uint8_t *byteArray, unsigned int byte_array_size, unsigned int frame_id ,const std::string& working_directory);
    ~DSTDecoder() = default;
    // When timestampLookUp is called with a timestamp value (T1), then the 
    // ChunkInfo corresponding to the first timestamp which is >T1 has to be returned
    
    chunkInfo_s timestampLookUp(uint64_t target, bool use_timestamp_lookup_file,const std::string& working_directory);
    static DSTSignalsInfo_s getDSTSignalsInfo (const std::string& config_file);

private:
   std::vector<uint8_t> DbgBusSizes;
   std::vector<std::string> DbgBusNames;
   std::vector<FrameWalker*> FrameWalkersList;
   std::unordered_map<std::string, uint64_t> Timestamp_Map;
   bool ReadConfig(const std::string& config_file);
   std::vector<std::string> SplitHexToBits(const std::string& hex) ;
   std::vector<std::string> SplitString(const std::string& str, char delimiter) ; 
   void AppendTimestampLookupFile(const std::string& filename);
   void PrintTimetamp_map();
   uint64_t findHighestTimeStampInLastChunk(unsigned int chunk_id_in,const std::string& filename);
   std::unordered_map<std::string, uint64_t> ReadFileToHashMap(const std::string& filename);




};

#endif // DSTDECODER_H
