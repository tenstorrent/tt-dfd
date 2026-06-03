// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#ifndef DSTTIMESTAMPPACKET_H
#define DSTTIMESTAMPPACKET_H

#include <iostream>
#include <bitset>
#include <array>
#include <vector>
#include <cstring>
#include <string>
#include <sstream>
#include <cstdint> // for uint64_t
#include <inttypes.h> // for uint64_t
#include "DSTPacket.h"

const int TIMESTAMPPACKET_HEADER_LENGTH = 2;
const int TIMESTAMPPACKET_DATA_LENGTH = 8;

#pragma pack(push,1)
struct DstTimestampPacketHdr_s {
    unsigned int NullPkt : 1;  
    unsigned int HdrExtended : 1;
    unsigned int PktLoss : 1;
    unsigned int SrcId : 4;
    unsigned int PktType : 1;
    unsigned int SupportInfo : 4;
    unsigned int SupportForm : 4;
};

struct DstTimestampPacket_s {
    DstTimestampPacketHdr_s DstTimestampPacketHdr;
    uint64_t Timestamp : (TIMESTAMPPACKET_DATA_LENGTH*8);
};

#pragma pack(pop)

class DSTTimestampPacket : public DSTPacket {
public:
    DstTimestampPacket_s DstTimestampPacket; 
    int PayLoadLength; 
    DSTTimestampPacket(const uint8_t* byteArray);
    DSTTimestampPacket(uint64_t timestamp_in);
    ~DSTTimestampPacket();
    unsigned int GetPktType();
    unsigned int GetPktLoss();
    unsigned int GetSrc();
    std::string  GetPktString() override;
    unsigned int GetPktId() ;
    void SetPktId(unsigned int pkt_id_in) ;
    uint64_t GetDecodedPayload() override;
    unsigned int GetCompressedLengthInBytes();
    std::array<uint8_t, DSTPACKET_LENGTH> GetPktBytes() override;

    void Display();
};

#endif // DSTTIMESTAMPPACKET_H
