module fsm(input clock,resetn,pkt_valid, parity_done, soft_reset_0,soft_reset_1,soft_reset_2,fifo_full,low_pkt_valid,fifo_empty_0,fifo_empty_1,fifo_empty_2,
input [1:0]data_in,
output busy, detect_add, ld_state,laf_state, full_state,write_enb_reg,rst_int_reg,lfd_state
    );
    parameter decode_address = 4'b0001,
              wait_till_empty = 4'b0010,
              load_first_data = 4'b0011,
              load_data = 4'b0100,
              load_parity = 4'b0101,
              fifo_full_state = 4'b0110,
              load_after_full = 4'b0111,
              check_parity_error = 4'b1000;
              
    reg [3:0] state,next_state;
    reg [1:0]temp;
    
    //temp logic to decide the address of the output
    always@(posedge clock)
    begin
        if(!resetn)
            temp<=0;
        else if(detect_add)
            temp<=data_in;
    end
    
    //reset logic for states
    //idle reset state
    always@(posedge clock)
    begin
        if(!resetn)
            state<=decode_address;
        else if(soft_reset_0 && temp==2'b00)
            state<=decode_address;
        else if(soft_reset_1 && temp==2'b01)
            state<=decode_address;
        else if(soft_reset_2 && temp==2'b10)
            state<=decode_address;
        else
            state<=next_state;
    end
    
    //state machine logic
    always@(*)
    begin
        case(state)
        4'b0001:begin
                if((pkt_valid && (data_in==2'b00) && fifo_empty_0) || (pkt_valid && (data_in==2'b01) && fifo_empty_1) || (pkt_valid && (data_in==2'b10) && fifo_empty_2))
                    next_state<=load_first_data;
                else if((pkt_valid && (data_in==2'b00) && !fifo_empty_0) || (pkt_valid && (data_in==2'b01) && !fifo_empty_1) || (pkt_valid && (data_in==2'b10) && !fifo_empty_2))
                    next_state<=wait_till_empty;
                else
                next_state<=decode_address;
        end
        
        4'b0011:begin
            next_state<=load_data; //lfd_state
        end
        
        4'b0001:begin //wait_till_empty
            if((fifo_empty_0 && (temp==2'b00)) || (fifo_empty_1 && (temp==2'b01)) || (fifo_empty_2 && (temp==2'b10)))
                next_state<=load_first_data;
            else
                next_state<=wait_till_empty;
        end
        
        4'b0100:begin //load_data
            if(fifo_full==1'b1)
                next_state<=fifo_full_state;
            else begin
            if(!fifo_full && !pkt_valid)
                next_state<=load_parity;
            else
                next_state<=load_data;
            end
        end
        
        4'b0110:begin // fifo full state
            if(fifo_full==0)
                next_state<=load_after_full;
            else
                next_state<=fifo_full_state;
        end
        
			4'b0111:         	// load after full state
			begin
				if(!parity_done && low_pkt_valid)
					next_state<=load_parity;
				else if(!parity_done && !low_pkt_valid)
					next_state<=load_data;
	
				else 
					begin 
						if(parity_done==1'b1)
							next_state<=decode_address;
						else
							next_state<=load_after_full;
					end
				
			end
//-------------------------------------------------------------------------------------------------------------------------------------------
			4'b0101:                 // load parity state
			begin
				next_state<=check_parity_error;
			end
//-------------------------------------------------------------------------------------------------------------------------------------------
			4'b1000:			// check parity error
			begin
				if(!fifo_full)
					next_state<=decode_address;
				else
					next_state<=fifo_full_state;
			end
//--------------------------------------------------------------------------------------------------------------------------------------------
			default:					//default state
				next_state<=decode_address; 

		endcase																					// state machine completed
	end        

assign busy=((state==load_first_data)||(state==load_parity)||(state==fifo_full_state)||(state==load_after_full)||(state==wait_till_empty)||(state==check_parity_error))?1:0;
assign detect_add=((state==decode_address))?1:0;
assign lfd_state=((state==load_first_data))?1:0;
assign ld_state=((state==load_data))?1:0;
assign write_enb_reg=((state==load_data)||(state==load_after_full)||(state==load_parity))?1:0;
assign full_state=((state==fifo_full_state))?1:0;
assign laf_state=((state==load_after_full))?1:0;
assign rst_int_reg=((state==check_parity_error))?1:0;

endmodule        
              
