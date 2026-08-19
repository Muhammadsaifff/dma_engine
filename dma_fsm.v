module dma_fsm (
    input wire clk,
    input wire rst,
    input wire start_transfer,
    input wire [31:0] src_addr_init,
    input wire [31:0] dst_addr_init,
    input wire [31:0] length_init,
    input wire bus_op_done,
    output reg [31:0] current_src_addr,
    output reg [31:0] current_dst_addr,
    output reg bus_read_req,
    output reg bus_write_req,
    output reg transfer_done,
    output reg transfer_active,
    input wire [31:0] read_data_buffer
);

    localparam STATE_IDLE = 3'b000;
    localparam STATE_READ = 3'b001;
    localparam STATE_WAIT_READ = 3'b010;
    localparam STATE_WRITE = 3'b011;
    localparam STATE_WAIT_WRITE = 3'b100;
    localparam STATE_INC_ADDR = 3'b101;
    localparam STATE_DONE = 3'b110;
    localparam STATE_ERROR = 3'b111;

    reg [2:0] state;
    reg [2:0] next_state;
    reg [31:0] transfer_count;
    reg error_detected;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_IDLE: begin
                if (start_transfer && (length_init > 0))
                    next_state = STATE_READ;
            end
            STATE_READ: next_state = STATE_WAIT_READ;
            STATE_WAIT_READ: begin
                if (bus_op_done)
                    next_state = STATE_WRITE;
            end
            STATE_WRITE: next_state = STATE_WAIT_WRITE;
            STATE_WAIT_WRITE: begin
                if (bus_op_done)
                    next_state = STATE_INC_ADDR;
            end
            STATE_INC_ADDR: begin
                if (transfer_count == 0)
                    next_state = STATE_DONE;
                else
                    next_state = STATE_READ;
            end
            STATE_DONE: next_state = STATE_IDLE;
            STATE_ERROR: begin
                if (!error_detected)
                    next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Address and counter updates
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_src_addr <= 32'b0;
            current_dst_addr <= 32'b0;
            transfer_count <= 32'b0;
            error_detected <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start_transfer) begin
                        current_src_addr <= src_addr_init;
                        current_dst_addr <= dst_addr_init;
                        transfer_count <= length_init;
                        error_detected <= 1'b0;
                    end
                end
                STATE_INC_ADDR: begin
                    current_src_addr <= current_src_addr + 4;
                    current_dst_addr <= current_dst_addr + 4;
                    transfer_count <= transfer_count - 1;
                end
                default: begin
                end
            endcase
        end
    end

    // Output control signals
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            bus_read_req <= 1'b0;
            bus_write_req <= 1'b0;
            transfer_done <= 1'b0;
            transfer_active <= 1'b0;
        end else begin
            bus_read_req <= 1'b0;
            bus_write_req <= 1'b0;
            transfer_done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    transfer_active <= 1'b0;
                end
                STATE_READ: begin
                    bus_read_req <= 1'b1;
                    transfer_active <= 1'b1;
                end
                STATE_WAIT_READ: begin
                    transfer_active <= 1'b1;
                end
                STATE_WRITE: begin
                    bus_write_req <= 1'b1;
                    transfer_active <= 1'b1;
                end
                STATE_WAIT_WRITE: begin
                    transfer_active <= 1'b1;
                end
                STATE_INC_ADDR: begin
                    transfer_active <= 1'b1;
                end
                STATE_DONE: begin
                    transfer_done <= 1'b1;
                    transfer_active <= 1'b0;
                end
                default: begin
                    transfer_active <= 1'b0;
                end
            endcase
        end
    end

endmodule
