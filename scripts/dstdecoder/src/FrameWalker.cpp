// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
#include "FrameWalker.h"

    FrameWalker::FrameWalker(unsigned int frame_id_in,const uint8_t *byteArray, unsigned int chunk_size,std::vector<uint8_t> ParseMap, uint64_t frame_start_timestamp,const std::string& working_directory_in){
         working_directory = working_directory_in;
         frame_id = frame_id_in;
         DecodeChunk(byteArray,chunk_size,ParseMap,frame_start_timestamp);
         WriteCSVFile();
    }

    FrameWalker::FrameWalker(unsigned int frame_id_in,const std::string &chunk_file,std::vector<uint8_t> ParseMap, uint64_t frame_start_timestamp,const std::string& working_directory_in){
        frame_id = frame_id_in;
        working_directory = working_directory_in;
        std::ifstream inputFile(working_directory + "/" + chunk_file);
        std::vector<uint8_t> byteArray;
        std::string hexString, line, err_message;
        //Note on chunk file format:
        // memlocation[0] memlocation [1] memlocation[2] ..... memlocation[10]
        // memlocation[11] memlocation[12]
        // memlocation[13] ...
        if (!inputFile) {
            err_message = "Framewalker could not open file" + chunk_file;
            throw std::runtime_error(err_message);
        }
  
        while (std::getline(inputFile, line)){
          for (char ch : line) {
             if (!std::isspace(ch)) //Ignore whitespace
               hexString += ch;
          }
        }
        inputFile.close();
        byteArray = hexStringToByteArray(hexString);
        for (size_t i = 0; i < byteArray.size(); ++i) {
        }
        
        DecodeChunk(byteArray.data(), byteArray.size(),ParseMap,frame_start_timestamp);
        WriteCSVFile();
    }
    void FrameWalker::DecodeChunk(const uint8_t *byteArray, unsigned int chunk_size,std::vector<uint8_t> ParseMap, uint64_t frame_start_timestamp){
    uint64_t DecodeSeed = -1;
    size_t   dst_packet_index = 0;
    unsigned int   dst_data_packet_id = 0;
    uint64_t CurrentTimestamp = frame_start_timestamp;  
       //NO Timestamp packet in the start of the frame, add a  Timestamp Packet
       if (GetPktType(byteArray[0]) != TYPE_IS_DST_SUPPORT_TIMESTAMP){  
          DecodedDSTPackets.push_back(new DSTTimestampPacket(CurrentTimestamp));
          TimeStampIndexes.push_back(dst_packet_index);
          dst_packet_index += 1;
       }

       for (size_t i = 0; i < chunk_size;) {
          if (GetPktType(byteArray[i]) == TYPE_IS_DST_DATA){
             DecodedDSTPackets.push_back(new DSTDataPacket(&byteArray[i],DecodeSeed,ParseMap));
             DecodeSeed = DecodedDSTPackets[dst_packet_index]->GetDecodedPayload();
             DecodedDSTPackets[dst_packet_index]->SetCurrentTimestamp(CurrentTimestamp);
             DecodedDSTPackets[dst_packet_index]->SetPktId(dst_data_packet_id);
             dst_data_packet_id += 1;
             if (dst_packet_index != 0) {
              DecodedDSTPackets[dst_packet_index-1]->SetNextLinkedPackets(DecodedDSTPackets[dst_packet_index]);
             }
          }
          else if (GetPktType(byteArray[i]) == TYPE_IS_DST_SUPPORT_TIMESTAMP){  
             DecodedDSTPackets.push_back(new DSTTimestampPacket(&byteArray[i]));
             TimeStampIndexes.push_back(dst_packet_index);
             CurrentTimestamp = DecodedDSTPackets[dst_packet_index]->GetDecodedPayload();
          } 

          if (GetPktType(byteArray[i]) != TYPE_IS_DST_SUPPORT_NULL){
           i += DecodedDSTPackets[dst_packet_index]->GetCompressedLengthInBytes();
           dst_packet_index += 1;
          } else {
            i += 1;
          }
        }
    }

    FrameWalker::~FrameWalker(){};

    unsigned int FrameWalker::GetPktType(uint8_t header_byte0){
       if ((header_byte0 & 0x80) == 0)
          return TYPE_IS_DST_DATA;
       else if ((header_byte0 & 0x01) == 1)
          return TYPE_IS_DST_SUPPORT_NULL;
       else  
          return TYPE_IS_DST_SUPPORT_TIMESTAMP;
    };

    uint64_t FrameWalker::GetLastTimeStamp(){
        return ((DecodedDSTPackets[TimeStampIndexes[TimeStampIndexes.size()-1]])->GetDecodedPayload());
    }

   // Use for Diagnostics..
    void FrameWalker::DisplayTimeStampAndLinkedPackets(){
       for (unsigned int i =0 ; i < TimeStampIndexes.size(); i++)
       {
         DecodedDSTPackets[TimeStampIndexes[i]]->DisplayNextLinkedPackets();
       }
    }
    void FrameWalker::StringDisplayTimeStampAndLinkedPackets(){
       for (unsigned int i =0 ; i < TimeStampIndexes.size(); i++)
       {
         printf("%s",DecodedDSTPackets[TimeStampIndexes[i]]->StringDisplayNextLinkedPackets().c_str());
       }
    }

    // Use for CVS print
   std::string FrameWalker::GetCSVFrame() {
        std::vector<std::string> CSVStrings;
        std::string timestamp_string;
       //Decoded DST packet is always a timestamp. See DecodeChunk function.
       for (unsigned int i =0 ; i < TimeStampIndexes.size(); i++) {
           CSVStrings.push_back(DecodedDSTPackets[TimeStampIndexes[i]]->GetCSVStringNextLinkedPackets().c_str()); 
        }

       // Concatenate all elements in formattedStrings into a single string
         std::ostringstream resultStream;
        for (const std::string& str : CSVStrings) {
            resultStream << str;  // Add each formatted string
       }
       resultStream << "\n";
       std::string result = resultStream.str();
       return result;
    }

    std::vector<uint8_t> FrameWalker::hexStringToByteArray(const std::string& hexString) {

    std::vector<uint8_t> byteArray;
    // Process each pair of hex characters
    for (size_t i = 0; i < hexString.length(); i += 2) {
        std::string byteString = hexString.substr(i, 2);
        uint8_t byte = static_cast<uint8_t>(std::stoi(byteString, nullptr, 16));
        byteArray.push_back(byte);
    }

    return byteArray;
    }

    //Function to write the CSV file 
    void FrameWalker::WriteCSVFile(){
       std::string out_file = working_directory + "/" + "decodedDST" + std::to_string(frame_id);
       std::string err_message;
       std::ofstream outFile(out_file);
        if (!outFile) {
            err_message = "WriteCSV File Could not open file" + out_file;
            throw std::runtime_error(err_message);
        }

        outFile << GetCSVFrame().c_str() <<std::endl;
  
        outFile.close();
    
    }

  size_t       FrameWalker::GetTimeStampIndexes(size_t index) const { return TimeStampIndexes[index]; }
  unsigned int FrameWalker::GetSizeTimeStampIndexes()         const { return TimeStampIndexes.size(); }
  uint64_t     FrameWalker::GetTimeStamp(size_t index)        const { return DecodedDSTPackets[index]->GetDecodedPayload(); }
