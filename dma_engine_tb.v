module dma_engine_tb;

    reg clk;
    reg rst;
    reg start_transfer;
    reg [31:0] src_addr;
    reg [31:0] dst_addr;
    reg [31:0] byte_count;
    reg [3:0] burst_size;
    reg [1:0] transfer_mode;
    wire dma_busy;
    wire dma_done;
    wire dma_error;
    wire mem_req;
    wire mem_write;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    reg [31:0] mem_rdata;
    reg mem_ack;
    reg mem_error;
    wire peri_req;
    wire [31:0] peri_addr;
    wire peri_write;
    wire [31:0] peri_wdata;
    reg [31:0] peri_rdata;
    reg peri_ack;
    reg peri_error;
    wire dma_interrupt;

    // Memory model
    reg [31:0] memory [0:63];
    
    // Peripheral model
    reg [31:0] peripheral_reg;

    dma_engine uut (
        .clk(clk),
        .rst(rst),
        .start_transfer(start_transfer),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .byte_count(byte_count),
        .burst_size(burst_size),
        .transfer_mode(transfer_mode),
        .dma_busy(dma_busy),
        .dma_done(dma_done),
        .dma_error(dma_error),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ack(mem_ack),
        .mem_error(mem_error),
        .peri_req(peri_req),
        .peri_addr(peri_addr),
        .peri_write(peri_write),
        .peri_wdata(peri_wdata),
        .peri_rdata(peri_rdata),
        .peri_ack(peri_ack),
        .peri_error(peri_error),
        .dma_interrupt(dma_interrupt)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Memory initialization
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h00000000 + i;
        end
        peripheral_reg = 32'hDEADBEEF;
    end

    // Memory interface simulation
    always @(posedge clk) begin
        mem_ack <= 1'b0;
        mem_error <= 1'b0;
        mem_rdata <= 32'b0;
        
        if (mem_req) begin
            if (mem_write) begin
                memory[mem_addr[7:2]] <= mem_wdata;
                mem_ack <= 1'b1;
            end else begin
                mem_rdata <= memory[mem_addr[7:2]];
                mem_ack <= 1'b1;
            end
        end
    end

    // Peripheral interface simulation
    always @(posedge clk) begin
        peri_ack <= 1'b0;
        peri_error <= 1'b0;
        peri_rdata <= 32'b0;
        
        if (peri_req) begin
            if (peri_write) begin
                peripheral_reg <= peri_wdata;
                peri_ack <= 1'b1;
            end else begin
                peri_rdata <= peripheral_reg;
                peri_ack <= 1'b1;
            end
        end
    end

    // Test sequence
    initial begin
        // Initialize
        rst = 0;
        start_transfer = 0;
        src_addr = 32'h00000000;
        dst_addr = 32'h00000010;
        byte_count = 32'd4;
        burst_size = 4'd4;
        transfer_mode = 2'b00;

        // Reset release
        #10 rst = 1;
        #10;

        // Test 1: Memory to Memory transfer
        $display("\n Test 1: Memory to Memory");
        memory[0] = 32'h12345678;
        memory[1] = 32'h9ABCDEF0;
        memory[2] = 32'h11223344;
        memory[3] = 32'h55667788;
        
        start_transfer = 1;
        #10 start_transfer = 0;
        
        wait(dma_done);
        #20;
        $display("Memory[4]: %h", memory[4]);
        $display("Memory[5]: %h", memory[5]);
        $display("Memory[6]: %h", memory[6]);
        $display("Memory[7]: %h", memory[7]);
        $display("DMA Done: %b, Error: %b, Interrupt: %b", dma_done, dma_error, dma_interrupt);

        // Test 2: Memory to Peripheral
        $display("\n Test 2: Memory to Peripheral");
        memory[8] = 32'hFFFFFFFF;
        memory[9] = 32'h0000AAAA;
        
        src_addr = 32'h00000020;
        dst_addr = 32'h00000000;
        byte_count = 32'd2;
        transfer_mode = 2'b10;
        start_transfer = 1;
        #10 start_transfer = 0;
        
        wait(dma_done);
        #20;
        $display("Peripheral value: %h", peripheral_reg);
        $display("DMA Done: %b, Error: %b", dma_done, dma_error);

        // Test 3: Peripheral to Memory
        $display("\n Test 3: Peripheral to Memory");
        peripheral_reg = 32'hCAFEBABE;
        
        src_addr = 32'h00000000;
        dst_addr = 32'h00000030;
        byte_count = 32'd1;
        transfer_mode = 2'b01;
        start_transfer = 1;
        #10 start_transfer = 0;
        
        wait(dma_done);
        #20;
        $display("Memory[12]: %h", memory[12]);
        $display("DMA Done: %b, Error: %b", dma_done, dma_error);

        // Test 4: Error condition
        $display("\n Test 4: Error Condition");
        mem_error = 1'b1;
        src_addr = 32'h00000040;
        dst_addr = 32'h00000050;
        byte_count = 32'd2;
        transfer_mode = 2'b00;
        start_transfer = 1;
        #10 start_transfer = 0;
        
        #50;
        $display("DMA Error: %b, Interrupt: %b", dma_error, dma_interrupt);
        mem_error = 1'b0;

        // Test 5: Burst transfer
        $display("\n Test 5: Burst Transfer");
        for (i = 0; i < 8; i = i + 1) begin
            memory[16 + i] = 32'hCCCCCCCC + i;
        end
        
        src_addr = 32'h00000040;
        dst_addr = 32'h00000060;
        byte_count = 32'd8;
        burst_size = 4'd4;
        transfer_mode = 2'b00;
        start_transfer = 1;
        #10 start_transfer = 0;
        
        wait(dma_done);
        #20;
        for (i = 0; i < 8; i = i + 1) begin
            $display("Memory[%0d]: %h", 24 + i, memory[24 + i]);
        end

        // Test 6: Single word transfer
        $display("\n Test 6: Single Word Transfer");
        memory[32] = 32'hDEADBEEF;
        src_addr = 32'h00000080;
        dst_addr = 32'h00000084;
        byte_count = 32'd1;
        burst_size = 4'd1;
        transfer_mode = 2'b00;
        start_transfer = 1;
        #10 start_transfer = 0;
        
        wait(dma_done);
        #20;
        $display("Memory[33]: %h", memory[33]);

        #50;
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t, Busy=%b, Done=%b, Error=%b, Int=%b, MemReq=%b, MemWr=%b, PeriReq=%b",
                 $time, dma_busy, dma_done, dma_error, dma_interrupt, mem_req, mem_write, peri_req);
    end

endmodule


