module router_fifo(data_in,clock,resetn,soft_reset,write_enb,read_enb,lfd_state,data_out,full,empty);
input [7:0]data_in;
input resetn,clock;
input soft_reset;
input write_enb,read_enb;
input lfd_state;
output reg [7:0]data_out;
output full,empty;
reg [7:0]mem[15:0];
reg [4:0]wr_pntr,rd_pntr;
reg lfd_state_s;
reg [6:0]fifo_counter;
integer i;
/*
write and read pointer logic,
write logic
read logic
lfd_state logic
fifo counter logic
full and empty logic 
*/

//write and read pointer
always@(posedge clock)
begin
    if(!resetn)
    begin
        wr_pntr<=0;
        rd_pntr<=0;
    end
    else if(soft_reset)
    begin
        wr_pntr<=0;
        rd_pntr<=0;
    end
    else
    begin
        if(write_enb && !full)
        begin
            wr_pntr<=wr_pntr+1;
        end
        else
            wr_pntr<=wr_pntr;
        if(read_enb && !empty)
        begin
            rd_pntr<=rd_pntr+1;
        end
        else
            rd_pntr<=rd_pntr;
    end
end

//write logic
always@(posedge clock)
begin
    if(!resetn)
    begin
        for(i=0;i<16;i=i+1)
        begin
        mem[i]<=0;
        end
    end
    else if(soft_reset)
    begin
        for(i=0;i<16;i=i+1)
        begin
        mem[i]<=0;
        end
    end
    else if(write_enb && !full)
    begin
        mem[wr_pntr[3:0]]<={lfd_state_s,data_in}; //total of 1+8 bits
    end
end

//read logic
always@(posedge clock)
begin
    if(!resetn)
    begin
        data_out<=8'd0;
    end
    else if(soft_reset)
    begin
        data_out<=8'hz;
    end
    else if(read_enb && !empty)
    begin
        data_out<=mem[rd_pntr[3:0]];
    end
end

//lfd_state logic
always@(posedge clock)
begin
    if(!resetn)
        lfd_state_s<=0;
    else
    lfd_state_s<=lfd_state;
end
    
//fifo counter logic
/*the design of the counter if to specify if the fifo is full or empty.
This logic is read operation dependent. A header file consists of the payload length.
Based on the payload length, the counter has to decrement until it is pointing at the 0th memory location.
This is achieved by first reading the payload length and then counting down.
6 bits from 7 to 2 (MSB to LSB) are considered with an addition of 1 bit for parity.
*/

always@(posedge clock)
begin
    if(!resetn)
    begin
        fifo_counter<=0;
    end
    else if(soft_reset)
    begin
        fifo_counter<=0;
    end
    else if(read_enb && !empty)
    begin
    if(mem[rd_pntr[3:0]][8]==1)
        fifo_counter<=mem[rd_pntr[3:0]][7:2] +1'b1;
    else if(fifo_counter!=0)
        fifo_counter<=fifo_counter-1'b1;
    end
end

//full and empty logic
/*
Both the operations never run simultaneuosly.
For full condition, the 16x9 FIFO is full at wr_pntr=10000.  
and rd_pntr=00000. The logic is defined in this understanding.
For empty condition, the rd_pntr is at 0 along with the wr_pntr.
*/


assign full=(wr_pntr[3:0] == rd_pntr[3:0])&&(wr_pntr[4] != rd_pntr[4]);
assign empty=(wr_pntr==rd_pntr);

endmodule
