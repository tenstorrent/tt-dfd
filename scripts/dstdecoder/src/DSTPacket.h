// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#ifndef DSTPACKET_H
#define DSTPACKET_H

#include <iostream>
#include <bitset>
#include <cstring>
#include <array>
#include <vector>
#include <string>
#include <sstream>
#include <unordered_map>
#include <cstdint> // for uint64_t

const int DSTPACKET_LENGTH=10;

class DSTPacket {
public:
    DSTPacket();
    DSTPacket *previous; //Pointer to previous DST ; useful to link packets in frame.
    DSTPacket *next; //Pointer to next DST ; useful to link packets in frame.
    virtual void Display()  ;
    virtual void WriteCSVFile()  ;
    void SetNextLinkedPackets(DSTPacket* nextDSTPacket)  ;
    void DisplayNextLinkedPackets()  ;
    std::string StringDisplayNextLinkedPackets()  ;
    std::string GetCSVStringNextLinkedPackets(); 
    virtual std::string GetPktString();
    virtual std::string GetPayloadString();
    virtual std::string GetCSVString();
    virtual unsigned int GetPktType() ;
    virtual unsigned int GetPktId() ;
    virtual void SetPktId(unsigned int pkt_id_in) ;
    virtual std::array<uint8_t, DSTPACKET_LENGTH> GetPktBytes() ;
    virtual unsigned int GetCompressedLengthInBytes() ;
    virtual uint64_t GetDecodedPayload() ;
    virtual void SetCurrentTimestamp(uint64_t timestamp_in);
    virtual uint64_t GetCurrentTimestamp();

    ~DSTPacket();
};

#endif //DSTPACKET_H
