// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#include "DSTPacket.h"

    DSTPacket::DSTPacket(){ previous = nullptr; next = nullptr; };

    DSTPacket::~DSTPacket(){};

    void DSTPacket::Display()  {};
    void DSTPacket::WriteCSVFile()  {};
    uint64_t DSTPacket::GetDecodedPayload() { return 0; };

    std::array<uint8_t, DSTPACKET_LENGTH> DSTPacket::GetPktBytes() {return std::array<uint8_t, DSTPACKET_LENGTH>();};
    std::string DSTPacket::GetPktString() {return std::string();};
    std::string DSTPacket::GetCSVString() {return std::string();};
    unsigned int DSTPacket::GetPktId() {return 0;};
    void DSTPacket::SetPktId(unsigned int pkt_id_in) {};
    std::string DSTPacket::GetPayloadString() {return std::string();};
    void DSTPacket::SetCurrentTimestamp(uint64_t timestamp_in){};
    uint64_t DSTPacket::GetCurrentTimestamp() { return 0;};

    unsigned int DSTPacket::GetPktType() { return 0;};
    unsigned int DSTPacket::GetCompressedLengthInBytes() { return 0;};
    void DSTPacket::SetNextLinkedPackets (DSTPacket* nextDSTPacket){
      this -> next = nextDSTPacket;
    };
    void DSTPacket::DisplayNextLinkedPackets()  {
       DSTPacket* current = this;
       while (current != nullptr) {
           printf("Display Next Linked Packet \n");
           current -> Display();
           current -> GetPktString();
           printf("\n");
           current -> GetCSVString();
           current = current -> next;
       }
    };

    std::string DSTPacket::StringDisplayNextLinkedPackets()  {
       std::ostringstream resultStream;
       std::vector<std::string> formattedStrings;

       DSTPacket* current = this;
       while (current != nullptr) {
           formattedStrings.push_back(current -> GetPktString().c_str());
           formattedStrings.push_back(current -> GetCSVString().c_str());
           current = current -> next;
       }
        for (const std::string& str : formattedStrings) {
            resultStream << str;  // Add each formatted string
       }
       std::string result = resultStream.str();
       return result;

    };

    std::string DSTPacket::GetCSVStringNextLinkedPackets() {
       std::ostringstream resultStream;
       std::vector<std::string> formattedStrings;

       DSTPacket* current = this;
       while (current != nullptr) {
//           printf("Debug\n");
//           current->Display();
           formattedStrings.push_back(current -> GetCSVString().c_str());
           current = current -> next;
       }
        for (const std::string& str : formattedStrings) {
            resultStream << str;  // Add each formatted string
       }
       std::string result = resultStream.str();
       return result;
        
     };
