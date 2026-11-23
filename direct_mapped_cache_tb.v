`timescale 1ns/1ps

module cache_tb;

    // Inputs to DUT (Device Under Test)
    reg clk;
    reg reset;
    reg access;
    reg [31:0] Address;
    reg [31:0] Write_Data;
    reg Write_Enable;

    // Outputs from DUT
    wire [31:0] Data_Out;
    wire Hit_Miss;
    wire [31:0] total_accesses;
    wire [31:0] total_misses;

    // Instantiate the cache
    direct_mapped_cache uut (
        .clk(clk),
        .reset(reset),
        .access(access),
        .Address(Address),
        .Write_Data(Write_Data),
        .Write_Enable(Write_Enable),
        .Data_Out(Data_Out),
        .Hit_Miss(Hit_Miss),
        .total_accesses(total_accesses),
        .total_misses(total_misses)
    );

    // Clock generation: toggles every 5ns (100MHz)
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        access = 0;
        Address = 0;
        Write_Data = 0;
        Write_Enable = 0;

        // Step 1: Apply reset
        #10 reset = 0;  // release reset

        // Step 2: First read (MISS expected)
        access = 1;
        Write_Enable = 0;         // read
        Address = 32'h0000_0000;  // address 0
        #10;  // wait one clock
        access = 0;
        $display("Read Addr=%h: Data_Out=%h, Hit_Miss=%b, Acc=%0d, Miss=%0d",
                 Address, Data_Out, Hit_Miss, total_accesses, total_misses);

        // Step 3: Read same address again (HIT expected)
        #10;
        access = 1;
        Address = 32'h0000_0000;
        #10;
        access = 0;
        $display("Read Addr=%h: Data_Out=%h, Hit_Miss=%b, Acc=%0d, Miss=%0d",
                 Address, Data_Out, Hit_Miss, total_accesses, total_misses);

        // Step 4: Write to a new address (MISS, then write)
        #10;
        access = 1;
        Address = 32'h0000_0010;  // address 16 (different block)
        Write_Enable = 1;         // write mode
        Write_Data = 32'hDEADBEEF;
        #10;
        access = 0;
        $display("Write Addr=%h: Data_Out=%h, Hit_Miss=%b, Acc=%0d, Miss=%0d",
                 Address, Data_Out, Hit_Miss, total_accesses, total_misses);

        // Step 5: Read back the same address (HIT, should get DEADBEEF)
        #10;
        access = 1;
        Write_Enable = 0;  // read
        Address = 32'h0000_0010;
        #10;
        access = 0;
        $display("Read Addr=%h: Data_Out=%h, Hit_Miss=%b, Acc=%0d, Miss=%0d",
                 Address, Data_Out, Hit_Miss, total_accesses, total_misses);

        // Step 6: Read another different address (MISS expected)
        #10;
        access = 1;
        Address = 32'h0000_0020;
        #10;
        access = 0;
        $display("Read Addr=%h: Data_Out=%h, Hit_Miss=%b, Acc=%0d, Miss=%0d",
                 Address, Data_Out, Hit_Miss, total_accesses, total_misses);

        // Finish simulation
        #20;
        $finish;
    end

endmodule
