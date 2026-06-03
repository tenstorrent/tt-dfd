// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
   #include "DSTDataPacket.h"


    DSTDataPacket::DSTDataPacket(const uint8_t* byteArray,uint64_t DecodeSeed, std::vector<uint8_t> ParseMap) :DSTPacket(){
        unsigned int iteration;
        int byte_position;
        uint8_t PayLoadArray[DATAPACKET_DECODED_DATA_LENGTH];
        uint8_t DecodedSeedArray[DATAPACKET_DECODED_DATA_LENGTH];
        for (size_t i = 0; i < DATAPACKET_DECODED_DATA_LENGTH; i+=1) {
          DecodedSeedArray[i] = ((DecodeSeed >> (i * 8)) & 0xFF); // Extract each byte
        }

        __builtin_memcpy(&DstDataPacket.DstDataPacketHdr, byteArray, DATAPACKET_HEADER_LENGTH);

        PayLoadLength = 0;
        iteration = DstDataPacket.DstDataPacketHdr.ByteEnables;
        byte_position = 0;
        while (byte_position <= 7) {
           PayLoadArray[byte_position] = DecodedSeedArray[byte_position];
           if (iteration %2){
             PayLoadArray[byte_position] = byteArray[DATAPACKET_HEADER_LENGTH + PayLoadLength];
             PayLoadLength += iteration % 2;
           }
           iteration >>= 1;  
           byte_position += 1;
        }
        DstDataPacket.DecodedPayload = 0;
        for (int i = 0; i < DATAPACKET_DECODED_DATA_LENGTH; i+=1) {
           DstDataPacket.DecodedPayload = DstDataPacket.DecodedPayload | static_cast<uint64_t>(PayLoadArray[i]) << (i * 8); // Shift and combine
        }

        MapAndParsePayload(ParseMap);
//        printf("Parsed Payload \n ");
//        for (uint64_t value: DstDataPacket.ParsedPayload){
//           printf("%lx ",value);
//        }
       
    };

    unsigned int DSTDataPacket::GetPktType(){return DstDataPacket.DstDataPacketHdr.PktType;}
    unsigned int DSTDataPacket::GetPktLoss(){return DstDataPacket.DstDataPacketHdr.PktLoss;}
    unsigned int DSTDataPacket::GetSrc(){return DstDataPacket.DstDataPacketHdr.SrcId;}
    uint64_t     DSTDataPacket::GetCurrentTimestamp() {return CurrentTimestamp;}
    void         DSTDataPacket::SetCurrentTimestamp(uint64_t timestamp_in) {CurrentTimestamp = timestamp_in;}
    uint64_t     DSTDataPacket::GetDecodedPayload() {return DstDataPacket.DecodedPayload;}
    unsigned int DSTDataPacket::GetCompressedLengthInBytes(){return (PayLoadLength + DATAPACKET_HEADER_LENGTH); }

    std::array<uint8_t, DSTPACKET_LENGTH> DSTDataPacket::GetPktBytes(){
        std::array<uint8_t, DSTPACKET_LENGTH> DstPkt;
        std::memcpy(DstPkt.data(), &DstDataPacket, sizeof(DstDataPacket_s));
        return DstPkt;
    }

    std::string DSTDataPacket::GetCSVString() {
        std::vector<std::string> formattedStrings;
        int buffer_entry = 0;
        char buffer[1024];

        snprintf(buffer,sizeof(buffer), "%lx ", CurrentTimestamp); 
        formattedStrings.push_back(buffer); 

        snprintf(buffer,sizeof(buffer), "%x ", DstDataPacket.DstDataPacketHdr.SrcId); 
        formattedStrings.push_back(buffer); 

        snprintf(buffer,sizeof(buffer), "%x ", DstDataPacket.DstDataPacketHdr.PktLoss); 
        formattedStrings.push_back(buffer); 

        snprintf(buffer,sizeof(buffer), "%x ", DstDataPacket.DstDataPacketHdr.TraceInfo); 
        formattedStrings.push_back(buffer); 

        for (uint64_t value: DstDataPacket.ParsedPayload){
           snprintf(buffer,sizeof(buffer), "%lx ", value);
           formattedStrings.push_back(buffer); 
        }

         // Concatenate all elements in formattedStrings into a single string
         std::ostringstream resultStream;
        for (const std::string& str : formattedStrings) {
            resultStream << str;  // Add each formatted string
       }
       resultStream << "\n";
       std::string result = resultStream.str();
       return result;
    }

    std::string DSTDataPacket::GetPktString() {
        std::array<uint8_t, DSTPACKET_LENGTH> values;
        std::memcpy(values.data(), &DstDataPacket, sizeof(DstDataPacket_s));
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
       resultStream << "\n";
       std::string result = resultStream.str();
       return result;
    }

    
    void DSTDataPacket::Display() {
        printf("=============================================================\n");
        printf("TraceInfo[1:0]  : %0x \n" ,DstDataPacket.DstDataPacketHdr.TraceInfo);
        printf("PktLoss[0]      : %0x \n" ,DstDataPacket.DstDataPacketHdr.PktLoss);
        printf("SrcId[3:0]      : %0x \n" ,DstDataPacket.DstDataPacketHdr.SrcId);
        printf("PktType[0]      : %0x \n" ,DstDataPacket.DstDataPacketHdr.PktType);
        printf("ByteEnables[7:0]: %0x \n",DstDataPacket.DstDataPacketHdr.ByteEnables);
        printf("Payload[63:0]   : 0x%" PRIx64 "\n",DstDataPacket.DecodedPayload);
        auto myArray = GetPktBytes();
        printf("Packet Bytes : ");
        for (uint8_t val: myArray) {
            printf("%02" PRIx8,val);
            printf(" ");
        }
        printf("\n");

        printf("Data Packet String : %s",GetPktString().c_str());
        printf("\n");
        
    }

    void DSTDataPacket::MapAndParsePayload(const std::vector<uint8_t>& SignalWidthVector){
        std::vector<uint64_t> result;
        uint64_t curr_start = 0;
        uint64_t data = DstDataPacket.DecodedPayload;
        NumberOfSignals = 0;
        for (int curr_width : SignalWidthVector) {
          DstDataPacket.ParsedPayload.push_back(bitSelect(data,curr_start,curr_width));
          curr_start += curr_width;
          NumberOfSignals += 1;
        } 
        
    }

    // Function to perform bit selection
    uint64_t DSTDataPacket::bitSelect(uint64_t value, int start, int width) {
     // Ensure inputs are valid
     if (start < 0 || width <= 0 || start + width > 64) {
         std::cerr << "Error: Invalid bit range. Ensure 0 <= start < 64 and width <= remaining bits.\n";
         return 0;
     }
     // Create a bitmask of 'width' bits
     uint64_t mask = (1ULL << width) - 1;
     // Shift value right by 'start' bits and apply the mask
     return (value >> start) & mask;
    }

    unsigned int DSTDataPacket::GetPktId() {return PktId;} ;
    void DSTDataPacket::SetPktId(unsigned int pkt_id_in) {PktId = pkt_id_in;};
 
    DSTDataPacket::~DSTDataPacket() {};
