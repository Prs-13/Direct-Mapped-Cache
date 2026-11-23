`timescale 1ns / 1ps
module direct_mapped_cache(
    input        clk,
    input        reset,
    input        access,
    input [31:0] Address, // byte address
    input [31:0] Write_Data, // data to write
    input        Write_Enable, // 1 = write, 0 = read
    output reg [31:0] Data_Out,
    output reg        Hit_Miss, // 1 = hit, 0 = miss
    output reg [31:0] total_accesses,
    output reg [31:0] total_misses
    //output reg [31:0] total_hits;
);

    // Parameters (localparam = constant variable)
    localparam TAG_BITS = 26; // tag bits
    localparam LINE_BITS = 4; // 16 lines
    localparam WORD_BITS = 2; // 4 words per line
    localparam NUM_LINES = 16;
    localparam WORDS_PER_LINE = 4;
    localparam MEM_SIZE_BYTES = 1024; // 1KB

    // Bbyte-addressable main memory
    reg [7:0] memory [0:MEM_SIZE_BYTES-1];

    // Cache storage
    reg [31:0] cache_data [0:NUM_LINES-1][0:WORDS_PER_LINE-1];
    reg [TAG_BITS-1:0] cache_tags [0:NUM_LINES-1];
    reg valid [0:NUM_LINES-1];

    // Address fields
    wire [TAG_BITS-1:0] tag = Address[31:6];
    wire [LINE_BITS-1:0] line = Address[5:2];
    wire [WORD_BITS-1:0] word = Address[1:0];

    // Word base byte address
    wire [31:0] addr = {Address[31:2], 2'b00}; // finding nearest address divisible by 4 for CPU input (Address[31:2]*4)


    integer i, j;

    initial begin
        $readmemb("memory.mem", memory);

        for (i = 0; i < NUM_LINES; i = i + 1) begin
            valid[i] = 0;
            cache_tags[i] = 24'b0;
            for (j = 0; j < WORDS_PER_LINE; j = j + 1) begin
                cache_data[i][j] = 0;
            end
        end
        total_accesses = 32'b0;
        total_misses = 32'b0;
        //total_hits = 32'b0;
        Hit_Miss = 0;
        Data_Out = 32'b0;
    end


    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid[i] <= 0;
                cache_tags[i] <= 24'b0;
                for (j = 0; j < WORDS_PER_LINE; j = j + 1) begin
                    cache_data[i][j] <= 0;
                end
            end
            total_accesses <= 32'b0;
            total_misses <= 32'b0;
            //total_hits = 32'b0;
            Hit_Miss <= 0;
            Data_Out <= 32'b0;
        end
        else if (access) begin
            total_accesses <= total_accesses + 1;

            if (valid[line] && cache_tags[line] == tag) begin

                // HIT

                Hit_Miss <= 1;

                //total_hits <= total_hits + 1; 

                if (Write_Enable) begin
                    cache_data[line][word] <= Write_Data;
                    memory[addr + 0] <= Write_Data[7:0]; // LSB
                    memory[addr + 1] <= Write_Data[15:8];
                    memory[addr + 2] <= Write_Data[23:16];
                    memory[addr + 3] <= Write_Data[31:24]; // MSB
                    Data_Out <= Write_Data;
                end

                else begin
                    Data_Out <= cache_data[line][word];
                end

            end
            else begin

                // MISS

                Hit_Miss <= 0;

                total_misses <= total_misses + 1;

                // loading the whole block from memory wether write or read
                for (i = 0; i < WORDS_PER_LINE; i = i + 1) begin // uploading each word adress in a line to cache_data
                    cache_data[line][i] <= { memory[(Address[9:2]*4) + (i*4) + 3], // MSB byte3
                                             memory[(Address[9:2]*4) + (i*4) + 2], // memory[{Address[9:2], 2'b00} + {i, 2'b00} + 2]
                                             memory[(Address[9:2]*4) + (i*4) + 1], // memory[(Address[9:2] << 2) + (i << 2) + 1]
                                             memory[(Address[9:2]*4) + (i*4) + 0] // LSB byte0
                                           }; // glueing numbers together     
                end

                cache_tags[line] <= tag;
                valid[line] <= 1;


                if (Write_Enable) begin
                    cache_data[line][word] <= Write_Data;
                    memory[addr + 0] <= Write_Data[7:0]; // LSB
                    memory[addr + 1] <= Write_Data[15:8];
                    memory[addr + 2] <= Write_Data[23:16];
                    memory[addr + 3] <= Write_Data[31:24]; // MSB
                    Data_Out <= Write_Data;
                end

                else begin
                    Data_Out <= cache_data[line][word];
                end

            end

        end
    end
endmodule
