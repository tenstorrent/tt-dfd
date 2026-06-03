// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#ifndef FRAMEWALKER_H
#define FRAMEWALKER_H

#include <iostream>
#include <bitset>
#include <cstring>
#include <array>
#include <vector>
#include <memory>
#include <fstream>
#include <cstdint> // for uint64_t
#include "DSTPacket.h"
#include "DSTDataPacket.h"
#include "DSTTimestampPacket.h"

const int FRAME_LENGTH=62;
const int NUMBER_OF_FRAMES=1;
const int TYPE_IS_DST_DATA     =0;
const int TYPE_IS_DST_SUPPORT_TIMESTAMP  =1;
const int TYPE_IS_DST_SUPPORT_NULL  =2;

class FrameWalker {
public:
    FrameWalker(unsigned int frame_id_in,const uint8_t *byteArray, unsigned int chunk_size,std::vector<uint8_t> ParseMap, uint64_t frame_start_timestamp, const std::string& working_directory);
    FrameWalker(unsigned int frame_id_in,const std::string &chunk_file,std::vector<uint8_t> ParseMap, uint64_t frame_start_timestamp, const std::string& working_directory);
    ~FrameWalker();
    void DisplayTimeStampAndLinkedPackets();
    void StringDisplayTimeStampAndLinkedPackets();
    std::string GetCSVFrame();
    uint64_t GetLastTimeStamp();
    size_t GetTimeStampIndexes(size_t index) const;
    uint64_t GetTimeStamp(size_t index) const;
    unsigned int GetSizeTimeStampIndexes() const;
private:
    unsigned int frame_id;
    std::string working_directory;
    std::vector<DSTPacket*> DecodedDSTPackets;
    std::vector<int> TimeStampIndexes;
    void DecodeChunk(const uint8_t *byteArray, unsigned int chunk_size,std::vector<uint8_t> ParseMap, uint64_t frame_start_timestamp);
    std::vector<uint8_t> hexStringToByteArray(const std::string& hexString);   
    unsigned int GetPktType(uint8_t header_byte0);
    void WriteCSVFile();
    
};

#endif //FRAMEWALKER_H
