// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

#ifndef DSTDECODERAPI_H
#define DSTDECODERAPI_H

#include <iostream>
#include <bitset>
#include <cstring>
#include <array>
#include <vector>
#include <memory>
#include <cstdint>
#include "DstDecoderAPIDataType.h" 
#pragma once

// Define export/import macros for Windows
#ifdef _WIN32
    #ifdef DSTDECODER_EXPORTS
        #define DSTDECODER_API __declspec(dllexport)
    #else
        #define DSTDECODER_API __declspec(dllimport)
    #endif
#else
    #define DSTDECODER_API
#endif

extern "C" {
//returns success/failure, Decodes the i_buffer and writes the result to a file named as decodedDST<chunkNbr>
    DSTDECODER_API bool decodeSideBandTrace (unsigned int chunkNbr, uint8_t* i_buffer, int i_buffer_size, const std::string& config_file_path =".", const std::string& working_directory = ".");
// returns chunkInfo which consist of chunk number (C) and trace line index [which will be mapped to line number inside the decoded chunk file (L)] of the first timestamp which is >= requested input timestamp.
    DSTDECODER_API chunkInfo_s timestampLookUp (uint64_t timestamp, const std::string& working_directory = ".");
// returns Debug Signal Information
    DSTDECODER_API DSTSignalsInfo_s getDSTSignalsInfo (const std::string& config_file_path);
}

#endif //DSTDECODERAPI_H
