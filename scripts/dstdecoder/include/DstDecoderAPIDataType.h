// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0

#ifndef DSTDECODERAPIDATATYPE_H
#define DSTDECODERAPIDATATYPE_H

#pragma pack(push,1)
struct chunkInfo_s {
    unsigned int chunkNumber;
    unsigned int chunkLine;
};

struct DSTSignalsInfo_s {
    int NumberOfSignals;
    std::vector<uint8_t> SignalWidth;
    std::vector<std::string> SignalName;
};
#pragma pack(pop)

#endif // DSTDECODERAPIDATATYPE_H