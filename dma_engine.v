module dma_engine (
    input wire clk,
    input wire rst,

    input wire start_transfer,
    input wire [31:0] src_addr,
    input wire [31:0] dst_addr,
    input wire [31:0] byte_count,
    input wire [3:0] burst_size,
    input wire [1:0] transfer_mode, 

    output reg dma_busy,
    output reg dma_done,
    output reg dma_error,
 
    output reg mem_req,
    output reg mem_write,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    input wire mem_ack,
    input wire mem_error,

    output reg peri_req,
    output reg [31:0] peri_addr,
    output reg peri_write,
    output reg [31:0] peri_wdata,
    input wire [31:0] peri_rdata,
    input wire peri_ack,
    input wire peri_error,

    output reg dma_interrupt
);

    wire [31:0] current_src_addr;
    wire [31:0] current_dst_addr;
    wire bus_read_req;
    wire bus_write_req;
    wire transfer_done;
    wire transfer_active;

    dma_fsm dma_fsm_inst (
        .clk(clk),
        .rst(rst),
        .start_transfer(start_transfer),
        .src_addr_init(src_addr),
        .dst_addr_init(dst_addr),
        .length_init(byte_count),
        .bus_op_done(mem_ack || peri_ack),
        .current_src_addr(current_src_addr),
        .current_dst_addr(current_dst_addr),
        .bus_read_req(bus_read_req),
        .bus_write_req(bus_write_req),
        .transfer_done(transfer_done),
        .transfer_active(transfer_active),
        .read_data_buffer(mem_rdata)
    );

    reg [31:0] dma_buffer;
    reg [3:0] burst_counter;
    reg [3:0] burst_max;
    reg [31:0] remaining_bytes;
    reg [1:0] current_mode;
    reg error_occurred;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            burst_counter <= 4'b0;
            burst_max <= 4'b0;
            remaining_bytes <= 32'b0;
            current_mode <= 2'b00;
            error_occurred <= 1'b0;
            dma_buffer <= 32'b0;
        end else if (start_transfer) begin
            burst_max <= burst_size;
            remaining_bytes <= byte_count;
            current_mode <= transfer_mode;
            error_occurred <= 1'b0;
            burst_counter <= 4'b0;
        end else if (transfer_done) begin
            burst_counter <= 4'b0;
        end else if (bus_read_req && (mem_ack || peri_ack)) begin
      
            if (current_mode == 2'b00 || current_mode == 2'b10) begin
                dma_buffer <= mem_rdata;
            end else begin
                dma_buffer <= peri_rdata;
            end
        end else if (bus_write_req && (mem_ack || peri_ack)) begin
            if (burst_counter < burst_max - 1) begin
                burst_counter <= burst_counter + 1;
            end else begin
                burst_counter <= 4'b0;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            error_occurred <= 1'b0;
        end else if (mem_error || peri_error) begin
            error_occurred <= 1'b1;
        end else if (transfer_done) begin
            error_occurred <= 1'b0;
        end
    end

    always @(*) begin
        mem_req = 1'b0;
        mem_write = 1'b0;
        mem_addr = 32'b0;
        mem_wdata = 32'b0;

        if (bus_read_req && (current_mode == 2'b00 || current_mode == 2'b10)) begin
            // Memory read
            mem_req = 1'b1;
            mem_write = 1'b0;
            mem_addr = current_src_addr;
            mem_wdata = 32'b0;
        end else if (bus_write_req && (current_mode == 2'b00 || current_mode == 2'b01)) begin
            // Memory write
            mem_req = 1'b1;
            mem_write = 1'b1;
            mem_addr = current_dst_addr;
            mem_wdata = dma_buffer;
        end else if (bus_read_req && current_mode == 2'b01) begin
            // Peripheral read (not using memory)
            mem_req = 1'b0;
        end else if (bus_write_req && current_mode == 2'b10) begin
            // Peripheral write (not using memory)
            mem_req = 1'b0;
        end
    end

    always @(*) begin
        peri_req = 1'b0;
        peri_write = 1'b0;
        peri_addr = 32'b0;
        peri_wdata = 32'b0;

        if (bus_read_req && current_mode == 2'b01) begin
            // Peripheral read
            peri_req = 1'b1;
            peri_write = 1'b0;
            peri_addr = current_src_addr;
            peri_wdata = 32'b0;
        end else if (bus_write_req && current_mode == 2'b10) begin
            // Peripheral write
            peri_req = 1'b1;
            peri_write = 1'b1;
            peri_addr = current_dst_addr;
            peri_wdata = dma_buffer;
        end else if (bus_read_req && (current_mode == 2'b00 || current_mode == 2'b10)) begin
            // Memory read (not using peripheral)
            peri_req = 1'b0;
        end else if (bus_write_req && (current_mode == 2'b00 || current_mode == 2'b01)) begin
            // Memory write (not using peripheral)
            peri_req = 1'b0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dma_busy <= 1'b0;
            dma_done <= 1'b0;
            dma_error <= 1'b0;
            dma_interrupt <= 1'b0;
        end else begin
            dma_busy <= transfer_active;
            dma_done <= transfer_done;
            dma_error <= error_occurred || (mem_error || peri_error);
            
            if (transfer_done || error_occurred || mem_error || peri_error) begin
                dma_interrupt <= 1'b1;
            end else begin
                dma_interrupt <= 1'b0;
            end
        end
    end

endmodule
