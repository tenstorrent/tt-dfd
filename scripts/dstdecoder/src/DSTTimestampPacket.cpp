// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#include "DSTTimestampPacket.h"


    DSTTimestampPacket::DSTTimestampPacket(const uint8_t* byteArray) :DSTPacket(){
        __builtin_memcpy(&DstTimestampPacket, byteArray, TIMESTAMPPACKET_HEADER_LENGTH + TIMESTAMPPACKET_DATA_LENGTH);

        PayLoadLength = TIMESTAMPPACKET_DATA_LENGTH;
    };
    DSTTimestampPacket::DSTTimestampPacket(uint64_t timestamp_in) : DSTPacket(){
        DstTimestampPacket.DstTimestampPacketHdr.NullPkt = 0;    
        DstTimestampPacket.DstTimestampPacketHdr.HdrExtended = 1;    
        DstTimestampPacket.DstTimestampPacketHdr.PktLoss = 0;    
        DstTimestampPacket.DstTimestampPacketHdr.SrcId = 0;    
        DstTimestampPacket.DstTimestampPacketHdr.PktType = 1;   
        DstTimestampPacket.DstTimestampPacketHdr.SupportInfo = 0;    
        DstTimestampPacket.DstTimestampPacketHdr.SupportForm = 0;    
        DstTimestampPacket.Timestamp = timestamp_in;
        PayLoadLength = TIMESTAMPPACKET_DATA_LENGTH;
    };
 
    unsigned int DSTTimestampPacket::GetPktType(){return DstTimestampPacket.DstTimestampPacketHdr.PktType;}
    unsigned int DSTTimestampPacket::GetPktLoss(){return DstTimestampPacket.DstTimestampPacketHdr.PktLoss;}
    unsigned int DSTTimestampPacket::GetSrc(){return DstTimestampPacket.DstTimestampPacketHdr.SrcId;}
    uint64_t     DSTTimestampPacket::GetDecodedPayload() {return DstTimestampPacket.Timestamp;}
    unsigned int DSTTimestampPacket::GetCompressedLengthInBytes(){return (PayLoadLength + TIMESTAMPPACKET_HEADER_LENGTH); }

    std::array<uint8_t, DSTPACKET_LENGTH> DSTTimestampPacket::GetPktBytes(){
        std::array<uint8_t, DSTPACKET_LENGTH> DstPkt;
        std::memcpy(DstPkt.data(), &DstTimestampPacket, sizeof(DstTimestampPacket_s));
        return DstPkt;
    }

    std::string DSTTimestampPacket::GetPktString() {
        std::array<uint8_t, DSTPACKET_LENGTH> values;
        std::memcpy(values.data(), &DstTimestampPacket, sizeof(DstTimestampPacket_s));
        char buffer[3];
        std::array<std::string, DSTPACKET_LENGTH> formattedStrings;

         for (int i = 0; i < DSTPACKET_LENGTH; i++) {
            snprintf(buffer,sizeof(buffer), "%02x", values[i]); 
            formattedStrings[i] = buffer;
         }

         // Concatenate all elements in formattedStrings into a single string
         std::ostringstream resultStream;
        for (const std::string& str : formattedStrings) {
            resultStream << str;  // Add each formatted string
       }
       resultStream << "\n";  // Add each formatted string
       std::string result = resultStream.str();
       return result;
    }


    void DSTTimestampPacket::Display() {
        printf("=============================================================\n");
        printf("NullPkt[0]      : %0x \n",DstTimestampPacket.DstTimestampPacketHdr.NullPkt);
        printf("HdrExtended[0]  : %0x \n",DstTimestampPacket.DstTimestampPacketHdr.HdrExtended);
        printf("PktLoss[0]      : %0x \n",DstTimestampPacket.DstTimestampPacketHdr.PktLoss);
        printf("SrcId[3:0]      : %0x \n",DstTimestampPacket.DstTimestampPacketHdr.SrcId);
        printf("PktType[0]      : %0x \n",DstTimestampPacket.DstTimestampPacketHdr.PktType);
        printf("SupportInfo[3:0]: %0x \n",DstTimestampPacket.DstTimestampPacketHdr.SupportInfo);
        printf("SupportForm[3:0]: %0x \n",DstTimestampPacket.DstTimestampPacketHdr.SupportForm);
        printf("Timestamp[63:0]   : 0x%" PRIx64 "\n",DstTimestampPacket.Timestamp);
        auto myArray = GetPktBytes();
        printf("Packet Bytes : ");
        for (uint8_t val: myArray) {
            printf("%02" PRIx8,val);
            printf(" ");
        }
        printf("\n");
        printf("Timestamp Packet String : %s",GetPktString().c_str());
        printf("\n");
    }
   unsigned int DSTTimestampPacket::GetPktId() {  throw std::runtime_error("PktId is not currently used for Timestamp packet as we dont print timestamp packet in the out file");return -1;}
   void DSTTimestampPacket::SetPktId(unsigned int pkt_id_in) {  throw std::runtime_error("PktId is not currently used for Timestamp packet as we dont print timestamp packet in the out file");}

   DSTTimestampPacket::~DSTTimestampPacket() {};
