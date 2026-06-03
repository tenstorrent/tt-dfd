// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

#include <iostream>
#include <bitset>
#include <cstring>
#include <array>
#include <vector>
#include <memory>
#include <cstdint> // for uint64_t
#include "DSTDecoderAPI.h"
#include "ram_dwords.txt"

std::vector<uint8_t> convert32BitToByteArray(const std::vector<uint32_t>& variables) {
    std::vector<uint8_t> byteArray;

    for (uint32_t var : variables) {
        // Extract each byte from the 32-bit integer
        byteArray.push_back(var & 0xFF);         // Least significant byte
        byteArray.push_back((var >> 8) & 0xFF);  // Third byte
        byteArray.push_back((var >> 16) & 0xFF); // Second byte
        byteArray.push_back((var >> 24) & 0xFF); // Most significant byte
    }

    return byteArray;
}

int main() {
     std::vector<uint8_t> parse_map = {64};
 //    std::vector<uint8_t> parse_map = {8,16,8,8,16,8};
 //   uint8_t input_array0[28] ={
 //                              0x9a, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 //                              0x18, 0xFF, 0xde, 0xc0, 0x01, 0xc0, 0x0d, 0xf0, 0xea, 0x05,
 //                              0x18, 0x03, 0xce, 0xfa,
 //                              0x18, 0x0c, 0xbe, 0xba};
 //   uint8_t input_array1[28] ={
 //                              0x18, 0xFF, 0xde, 0xc1, 0x01, 0xc0, 0x0d, 0xf0, 0xea, 0x05,
 //                              0x9a, 0xFF, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 //                              0x18, 0x30, 0x00, 0xef,
 //                              0x18, 0xc0, 0xbe, 0x00};
 //   uint8_t input_array2[38] ={0x9a, 0xFF, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 //                              0x18, 0xFF, 0xde, 0xc2, 0x01, 0xc0, 0x0d, 0xf0, 0xea, 0x05,
 //                              0x18, 0x03, 0x00, 0x11,
 //                              0x18, 0x0c, 0x22, 0x00,
 //                              0x9a, 0xFF, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
 //   std::string wd = "/proj_risc/user_dev/sjanarthanam/DST_DECODER_UPDATES/dstdecoder/test";  
 //   std::string config_file_path = "/proj_risc/user_dev/sjanarthanam/DST_DECODER_UPDATES/dstdecoder/test";
 //   decodeSideBandTrace (0,input_array0,sizeof(input_array0),config_file_path,wd);
 //   decodeSideBandTrace (1,input_array1,sizeof(input_array1),config_file_path,wd);
 //   decodeSideBandTrace (2,input_array2,sizeof(input_array2),config_file_path,wd);
//    std::vector<uint32_t> ram_dwords;
//    #include "ram_dwords.txt";
    std::vector<uint8_t> input_array0 = convert32BitToByteArray(ram_dwords);
    unsigned int j = 0;
    for (size_t var: input_array0) {
       printf("\n input_array[%d] %x",j,var);
       j = j + 1;
    }
    std::string wd = "./";
    std::string config_file_path = "./";
    printf("\n calling decodeSideBandTrace \n");
    decodeSideBandTrace (0,input_array0.data(),input_array0.size(),config_file_path,wd);

    chunkInfo_s FileInfo;
    printf("Location of file where Timestamp is > \n");
    printf("Timestamp File Line\n");
    for (unsigned int i=0;i<5;i+=1){
     FileInfo = timestampLookUp(i);
     printf("%d :  %d %d\n",i,FileInfo.chunkNumber,FileInfo.chunkLine);
    }
  
    printf("List Debug Signals in Config File \n");
    printf("Signal Name : Width \n");
    DSTSignalsInfo_s DSTSignalsInfo;
    DSTSignalsInfo = getDSTSignalsInfo(config_file_path);
    for (unsigned int i =0 ; i < DSTSignalsInfo.NumberOfSignals; i +=1){
        printf("%s : %d \n",DSTSignalsInfo.SignalName[i].c_str(), DSTSignalsInfo.SignalWidth[i]);
    }
 

    std::cout << std::endl;

    return 0;
}
