// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#ifndef DSTDATAPACKET_H
#define DSTDATAPACKET_H

#include <iostream>
#include <bitset>
#include <array>
#include <vector>
#include <cstring>
#include <cstdint> // for uint64_t
#include <inttypes.h> // for uint64_t
#include <string>
#include <sstream>
#include "DSTPacket.h"

const int DATAPACKET_HEADER_LENGTH = 2;
const int DATAPACKET_DECODED_DATA_LENGTH = 8;

#pragma pack(push,1)
struct DstDataPacketHdr_s {
    unsigned int TraceInfo : 2;  
    unsigned int PktLoss : 1;
    unsigned int SrcId : 4;
    unsigned int PktType : 1;
    unsigned int ByteEnables : 8;
};

struct DstDataPacket_s {
    DstDataPacketHdr_s DstDataPacketHdr;
    uint64_t DecodedPayload : (DATAPACKET_DECODED_DATA_LENGTH*8);
    std::vector<uint64_t> ParsedPayload;
};

#pragma pack(pop)

class DSTDataPacket : public DSTPacket {
public:
    DstDataPacket_s DstDataPacket; 
    int PayLoadLength; 
    int NumberOfSignals;
    DSTDataPacket(const uint8_t* byteArray,uint64_t DecodeSeed,std::vector<uint8_t> ParseMap);
    ~DSTDataPacket();
    unsigned int GetPktType();
    unsigned int GetPktLoss();
    unsigned int GetSrc();
    uint64_t GetCurrentTimestamp();
    void SetCurrentTimestamp(uint64_t timestamp_in);
    uint64_t GetDecodedPayload() override;
    std::string  GetPktString() override;
    std::string  GetCSVString() override;
    unsigned int GetPktId() ;
    void SetPktId(unsigned int pkt_id_in) ;
    unsigned int GetCompressedLengthInBytes();
    std::array<uint8_t, DSTPACKET_LENGTH> GetPktBytes() override;
    void Display();
    void DisplayLinkedPackets();
private:
    void MapAndParsePayload(const std::vector<uint8_t>& SignalWidthVector);
    uint64_t bitSelect(uint64_t value, int start, int width);
    uint64_t CurrentTimestamp;
    unsigned int PktId; //The packet id is a global number within a chunk (collection of frames). The number is incremented every time a new Data Packet is added from chunk.

};

#endif //DSTDATAPACKET_H
