module register(
    input clock,resetn,pkt_valid,fifo_full,rst_int_reg,detect_add,ld_state,laf_state,full_state,lfd_state,
    input [7:0] data_in,
    output reg parity_done,err,low_pkt_valid,
    output reg [7:0] dout
    );
    
    reg [7:0]header_byte;
    reg [7:0]fifo_full_reg;
    reg [7:0]internal_parity;
    reg [7:0]packet_parity; 
    
    
    //logic for dout
    always@(posedge clock)
    begin
        if(resetn)
        begin
            dout<=8'd0;
        end
        else
        begin
            if(detect_add && pkt_valid) //for storing the header byte
                header_byte<=data_in;
            else if(lfd_state)      //loading the first data as the header byte
                dout<=header_byte;
            else if(ld_state && !fifo_full)     //loading the payload directly to dout when fifo is empty 
                dout<=data_in;
            else if(ld_state && fifo_full)      //loading onto a fifo full register as the fifo is full
                fifo_full_reg<=data_in;
            else if(laf_state)                  //loading the fifo byte out to dout
                dout<=fifo_full_reg;
        end
    end
    
    //logic for packet parity
    always@(posedge clock)
    begin
        if(resetn)
        packet_parity<=8'd0;
        else
        begin
            if(!pkt_valid && ld_state)
                packet_parity<=data_in;
        end
    end
    
    //logic for internal parity
    always@(posedge clock)
    begin
        if(resetn)
            internal_parity<=8'd0;
        else
        begin
            if(lfd_state)
                internal_parity<=internal_parity^header_byte;
            else if(ld_state && pkt_valid && !fifo_full)
                internal_parity<=internal_parity^data_in;
            else if(detect_add)
                internal_parity<=8'd0;
        end
    end
        
    //logic for error 
    always@(posedge clock)
    begin
        if(resetn)
            err<=1'b0;
        else
        begin
            if(parity_done)
            begin
                if(internal_parity != packet_parity)
                    err<=1'b1;
                else
                    err<=1'b0;
            end
        end
    end
    
    //logic for parity done
    always@(posedge clock)
    begin
        if(resetn)
            parity_done<=1'b0;
        else if(detect_add)
            parity_done<=0;
        else
        begin
            if((ld_state && !fifo_full && !pkt_valid) || (laf_state && low_pkt_valid && !parity_done))
                parity_done<=1'b1;
        end
    end
            
    //logic for low packet valid
    	always@(posedge clock)
	   		begin
              if(!resetn)
	 				low_pkt_valid<=0; 
         		else if(rst_int_reg)
	 				low_pkt_valid<=0;

              else if(ld_state && !pkt_valid) 
         			low_pkt_valid<=1;
			end
endmodule
