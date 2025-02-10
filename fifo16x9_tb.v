module fifo16x9_tb();
reg clock, resetn, soft_reset, lfd_state, write_enb, read_enb;
reg [7:0] data_in;
wire empty, full;
wire [7:0] data_out;

parameter period = 10;
reg [7:0] parity, header;
reg [1:0] addr;
integer i;

// Instantiate the DUT (Device Under Test)
router_fifo DUT (
    .data_out(data_out),
    .full(full),
    .empty(empty),
    .clock(clock),
    .resetn(resetn),
    .soft_reset(soft_reset),
    .lfd_state(lfd_state),
    .read_enb(read_enb),
    .write_enb(write_enb),
    .data_in(data_in)
);

// Continuous clock generation
initial
begin
    clock = 0;
    forever #(period / 2) clock = ~clock; // Continuous clock generation
end

// Initialize signals
task initialize;
begin
    data_in = 0;
    write_enb = 0;
    read_enb = 0;
    soft_reset = 0;
    lfd_state = 0;
end
endtask

// Apply a reset pulse
task rst_n;
begin
    @(negedge clock)
    resetn <= 1'b0;
    @(negedge clock)
    resetn <= 1'b1;
end
endtask

// Apply a soft reset pulse
task soft_rst;
begin
    @(negedge clock)
    soft_reset <= 1'b1;
    @(negedge clock)
    soft_reset <= 1'b0;
end
endtask

// Generate a packet and write it to the FIFO
task write;
    reg[7:0] payload_data, parity, header;
    reg[5:0] payload_len;
    reg[1:0] addr;
    begin
        @(negedge clock);
        payload_len = 6'd14;
        addr = 2'b01;
        header = {payload_len, addr}; // Construct header byte
        data_in = header; // Drive header byte
        lfd_state = 1'b1;
        write_enb = 1;
        for (i = 0; i < payload_len; i = i + 1)
        begin
            @(negedge clock);
            lfd_state = 0;
            payload_data = {$random} % 256; // Payload byte
            data_in = payload_data; // Drive payload byte
        end
        @(negedge clock);
        parity = {$random} % 256; // Parity byte
        data_in = parity; // Drive parity byte
    end
endtask


// Test sequence
initial
begin
    initialize;
    rst_n; // Apply reset

    soft_rst; // Apply soft reset

    write; // Generate and write a packet
    
    // Wait a few cycles before reading
    // Read from FIFO
    read_enb = 1;
    write_enb = 0;
    
    // Wait until FIFO is empty
    @(negedge clock)
    wait (empty);
    @(negedge clock);
    
    read_enb = 0;

    #100 $finish; // End simulation
end

endmodule
