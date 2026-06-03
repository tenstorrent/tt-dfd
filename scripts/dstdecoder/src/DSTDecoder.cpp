// SPDX-FileCopyrightText: Copyright 2025 Tenstorrent AI ULC
// SPDX-License-Identifier: Apache-2.0
   #include  "DSTDecoder.h"
   DSTDecoder::DSTDecoder(){ } 
   DSTDecoder::DSTDecoder(const std::string& config_file, const uint8_t *byteArray, unsigned int byte_array_size, unsigned int chunk_id, const std::string& working_directory){
         
       std::string timestamp_key; //"FramewalkList Index"_"TimeStamp Indexes within Frame"
       size_t timestamp_index,framesize_entry,next_datapacket_index;

       std::string timestamp_out_file = working_directory + "/"+"TimestampLookupForDST";
       std::ofstream outFile(timestamp_out_file, std::ios::app);
       outFile.close();

       uint64_t timestamp = findHighestTimeStampInLastChunk(chunk_id-1,timestamp_out_file);


         if (!ReadConfig(config_file)){
           std::exit(EXIT_FAILURE);
         }

         FrameWalkersList.push_back(new FrameWalker (chunk_id,byteArray,byte_array_size,DbgBusSizes,timestamp,working_directory));
         framesize_entry = FrameWalkersList.size()-1;
         timestamp = FrameWalkersList[framesize_entry]->GetLastTimeStamp();
         for (size_t j= 0; j < FrameWalkersList[framesize_entry]->GetSizeTimeStampIndexes(); j+=1){
           timestamp_index = FrameWalkersList[framesize_entry]->GetTimeStampIndexes(j);
           if (timestamp_index == sizeof(FrameWalkersList[framesize_entry])) { //If the timestamp is the last entry in frame, point to next chunk
             timestamp_key = std::to_string(chunk_id+1) + "_" + std::to_string(1);
           }
           else {
            timestamp_key = std::to_string(chunk_id) + "_" + std::to_string(1 + timestamp_index - j); //For now using math. but we should really use PktId ..
           }
           Timestamp_Map[timestamp_key] = FrameWalkersList[framesize_entry]->GetTimeStamp(timestamp_index);
        }

       AppendTimestampLookupFile(timestamp_out_file);
   }

   DSTDecoder::DSTDecoder(const std::string& config_file, const std::string& chunk_file_basename, unsigned int number_of_dst_samples,const std::string& working_directory){

         if (!ReadConfig(config_file)){
           std::exit(EXIT_FAILURE);
         }

       std::string filename;
       std::string timestamp_key; //"FramewalkList Index"_"TimeStamp Indexes within Frame"
       size_t timestamp_index;
       uint64_t timestamp = 0;

       for (size_t i=0;i<number_of_dst_samples;i+=1){
          filename = chunk_file_basename + std::to_string(i);
          FrameWalkersList.push_back(new FrameWalker (i,filename,DbgBusSizes,timestamp,working_directory));
          timestamp = FrameWalkersList[i]->GetLastTimeStamp();

       //Create Timestamp hash array
       for (size_t j= 0; j < FrameWalkersList[i]->GetSizeTimeStampIndexes(); j+=1){
           timestamp_index = FrameWalkersList[i]->GetTimeStampIndexes(j);
           timestamp_key = std::to_string(i) + "_" + std::to_string(timestamp_index);
           Timestamp_Map[timestamp_key] = FrameWalkersList[i]->GetTimeStamp(timestamp_index);
       }

       std::string timestamp_out_file = working_directory + "/"+"TimestampLookupForDST";
       AppendTimestampLookupFile(timestamp_out_file);
      } 

   }

   bool DSTDecoder::ReadConfig(const std::string& config_file){
       DSTSignalsInfo_s dst_signals_info;
       dst_signals_info = getDSTSignalsInfo(config_file);
       DbgBusSizes = dst_signals_info.SignalWidth ;
       DbgBusNames = dst_signals_info.SignalName  ;
       return (sizeof(dst_signals_info.NumberOfSignals) != 0); //retrun false if no signal names found.
    }


  DSTSignalsInfo_s DSTDecoder::getDSTSignalsInfo (const std::string& config_file){
       DSTSignalsInfo_s dst_signals_info;
       dst_signals_info.NumberOfSignals = 0;
       std::ifstream inFile(config_file);
       if (!inFile.is_open()) {
           std::cerr << "ReadConfig Error: Could not open configuration file " << config_file << std::endl;
           return dst_signals_info;
       }
   
       size_t totalBits = 0;
       std::string line;
       while (std::getline(inFile, line)) {
           std::istringstream iss(line);
           std::string column1, column2;
           if (iss>> column1>> column2) {
               size_t dbgSize = std::stoul(column1);
               std::string dbgName = column2;
               dst_signals_info.SignalWidth.push_back(dbgSize);
               dst_signals_info.SignalName.push_back(dbgName);
               totalBits += dbgSize;
           } else{
               std::cerr << "Error: Invalid value in configuration file. " << std::endl;
               return dst_signals_info;
           }
       }
   
       if (totalBits != DATAPACKET_DECODED_DATA_LENGTH*8) {
           std::cerr << "Error: Configuration values must add up to "<< DATAPACKET_DECODED_DATA_LENGTH*8 << "bits. Current total: " << totalBits << std::endl;
           return dst_signals_info;
       }

     
       if (dst_signals_info.SignalName.size() != dst_signals_info.SignalWidth.size()) {
           std::cerr << "Error: Numboer of SIngal Size" << sizeof(dst_signals_info.SignalWidth) << "!=  Number of Signal Name" << sizeof(dst_signals_info.SignalName);
           return dst_signals_info;
       }

       dst_signals_info.NumberOfSignals = dst_signals_info.SignalName.size();
       return dst_signals_info;
    }


    std::vector<std::string> DSTDecoder::SplitHexToBits(const std::string& hex) {
      uint64_t number = std::stoull(hex, nullptr, 16);
      std::bitset<64> binary(number);
  
      std::string binaryStr = binary.to_string();
      std::vector<std::string> result;
  
      size_t start = 0;
      for (const size_t& dbgSize : DbgBusSizes) {
          result.push_back(binaryStr.substr(start, dbgSize));
          start += dbgSize;
      }

      return result;
   }

   std::vector<std::string> DSTDecoder::SplitString(const std::string& str, char delimiter) {
    std::vector<std::string> result;
    std::istringstream stream(str);
    std::string token;
    while (std::getline(stream, token, delimiter)) {
        result.push_back(token);
    }

    return result;
  }

   // Function to find the key with the closest value > target
chunkInfo_s DSTDecoder::timestampLookUp(uint64_t target,bool use_timestamp_lookup_file, const std::string& working_directory){
    std::string closest_key;
    chunkInfo_s result;
    std::unordered_map<std::string, uint64_t> timestamp_map_in_use;

    result.chunkNumber = std::numeric_limits<unsigned int>::max();
    result.chunkLine = std::numeric_limits<unsigned int>::max();
    uint64_t closest_diff = std::numeric_limits<uint64_t>::max();  // Initialize with a large value

    timestamp_map_in_use = Timestamp_Map;  
    if (use_timestamp_lookup_file == 1) {
         timestamp_map_in_use = ReadFileToHashMap(working_directory + "/" + "TimestampLookupForDST");}

    bool found_closest_value = 0;

    // Iterate through the map
    for (const auto& pair : timestamp_map_in_use) {
        // Check if the value is > target
        if (pair.second > target) {
            uint64_t diff = pair.second - target;  // Calculate the difference
            // Update if this value is closer
            if (diff < closest_diff) {
                closest_diff = diff;
                closest_key = pair.first;
                found_closest_value = 1;
            }
        }
    }
    char delimiter = '_';
    if (found_closest_value) {
     std::vector<std::string> parts = SplitString(closest_key.c_str(), delimiter);
     result.chunkNumber = std::stoi(parts[0]);
     result.chunkLine   = std::stoi(parts[1]);
    } else 
    { 
      result.chunkNumber = -1;
      result.chunkLine = 0;
    }  
    return result; 

 }

//Function to write the CSV file 
void DSTDecoder::AppendTimestampLookupFile(const std::string& filename){
       std::string err_message;
       std::size_t timestamp_index;
       std::uint64_t timestamp;
       std::string file_and_line_number, timestamp_string,timestamp_index_string;
       std::string timestamp_map_file_entry = "";

       std::string timestamp_out_file = filename;
       std::ofstream outFile(timestamp_out_file, std::ios::app);
        if (!outFile) {
            err_message = "DSTDecoder::AppendTimestampLookupFile Could not open file" + timestamp_out_file;
            throw std::runtime_error(err_message);
        }
       if (Timestamp_Map.empty()){
            err_message = "Timestamp Map is Empty. There must be always a time-stamp \n";
            throw std::runtime_error(err_message);
       }

       for (const auto& pair : Timestamp_Map) {
          timestamp_map_file_entry += std::string(pair.first.c_str()) + " " + std::to_string(pair.second) + "\n";
       }
      
       outFile << timestamp_map_file_entry.c_str(); 
  
       outFile.close();
    
}

void DSTDecoder::PrintTimetamp_map(){
      for (const auto& pair : Timestamp_Map) {
       printf ("Key %s : value %lx \n", pair.first.c_str(), pair.second);
      }
}

uint64_t DSTDecoder::findHighestTimeStampInLastChunk(unsigned int chunk_id_in, const std::string& filename) {

    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("DSTDecoder::findHighestTimeStampInLastChunk Could not open file: TimestampLookupForDST.");
    }

    unsigned int last_line = std::numeric_limits<uint64_t>::min(); // Keeps track of the last line
    int64_t last_timestamp = 0;                                       // Corresponding value for timestamp
    bool found = false;

    std::string line;
    while (std::getline(file, line)) {
        // Trim leading and trailing whitespace
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        // Skip empty lines
        if (line.empty()) { continue; }
        std::istringstream lineStream(line);
        unsigned int chunk_id, line_number;
        uint64_t  value;

        // Parse the line
        char delimiter; // To hold the '_' delimiter
        if (!(lineStream >> chunk_id >> delimiter >> line_number >> value) || delimiter != '_') {
            throw std::runtime_error("Invalid file format.");
        }

        // Check if chunk_id matches the input and update if line number is higher
        if (chunk_id == chunk_id_in) {
            found = true;
            if (line_number > last_line) {
                last_line = line_number;
                last_timestamp = value;
            }
        }
    }

    file.close();

    return last_timestamp;
 }

 std::unordered_map<std::string, uint64_t> DSTDecoder::ReadFileToHashMap(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("DSTDecoder::ReadFileToHashMap Could not open file.");
    }
    std::unordered_map<std::string, uint64_t> hashMap;
    std::string line;
    while (std::getline(file, line)) {
        // Trim leading and trailing whitespace
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        // Skip empty or whitespace-only lines
        if (line.empty()) { continue; }
        std::istringstream lineStream(line);
        std::string key;
        uint64_t value;
        // Read the key and value
        if (!(lineStream >> key >> value)) {
            throw std::runtime_error("Invalid line format: " + line);
        }
        hashMap[key] = value; // Insert the key-value pair into the hash map
    }
    file.close();
    return hashMap;
}
