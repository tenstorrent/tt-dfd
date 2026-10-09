module generic_vidtopid #(
    parameter int NumHarts = 8,
    parameter int NumHartsIdx = (NumHarts == 1) ? 1 : $clog2(NumHarts)
) (
    input logic [NumHarts-1:0]                   fuse_map,
    input logic [NumHarts-1:0] [NumHartsIdx-1:0] vid_map,
    input logic [NumHartsIdx-1:0]                vid,
    input  logic [NumHarts-1:0]                  vid_vector, // Indexed by Virtual ID 
    output logic [NumHartsIdx-1:0]               pid,
    output logic [NumHarts-1:0]                  pid_vector, // Indexed by PID 
    output logic                                 map_avail   // 0: Not Mapped to Any PID , 1: Mapped to a valid PID
);

    typedef struct packed {
      logic [NumHartsIdx-1:0] pid; 
      logic                   mapped;
   } vidtopid_t; 

   vidtopid_t  [NumHarts-1:0]       VIdToPId; //Indexed by Logical ID

   
    always_comb begin
        VIdToPId = '0;
        pid_vector = '0;
        for (int i = 0; i < NumHarts; i++) begin
            if (fuse_map[i]) begin
                VIdToPId[vid_map[i]].pid = (NumHartsIdx)'(i);
                VIdToPId[vid_map[i]].mapped = fuse_map[i];
            end
        end

        for (int k = 0; k < NumHarts ; k++) begin
            if (VIdToPId[k].mapped) begin
                pid_vector[VIdToPId[k].pid] = vid_vector[k]; 
            end    
        end   
        pid = VIdToPId[vid].pid;
        map_avail = VIdToPId[vid].mapped;
    end
 
endmodule