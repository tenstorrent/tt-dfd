# SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
# SPDX-License-Identifier: Apache-2.0
# Compiler and flags
CXX = g++
CXXFLAGS = -Wall -std=c++11

# Srcdir
SRCDIR = ./src

# Target executable
TARGET = DstCppDecoder

# Source files
SRCS = Main.cpp DSTPacket.cpp DSTDataPacket.cpp DSTTimestampPacket.cpp FrameWalker.cpp DSTDecoder.cpp DSTDecoderAPI.cpp

# Object files
OBJS = $(SRCS:.cpp=.o)

# Default target to build the executable
all: $(TARGET)

# Link object files to create the executable
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

# Compile each .cpp file into a .o file
%.o: $(SRCDIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Clean up object files and the executable
clean:
	rm -f $(OBJS) $(TARGET)
