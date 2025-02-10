module sync(input detect_add,clock,resetn,read_enb_0,read_enb_1,read_enb_2,empty_0,empty_1,empty_2,full_0,full_1,full_2,write_enb_reg, 
    input [1:0]data_in,
    output reg soft_reset_0,soft_reset_1,soft_reset_2,fifo_full,
    output valid_0,valid_1,valid_2,
    output reg [2:0]write_enb
    );
     reg [1:0]data_in_temp;
     reg [4:0]count_0,count_1,count_2;//to count till 30
     
     //data address block
     always@(posedge clock)
     begin
        if(!resetn)
        data_in_temp<=0;
        else
        data_in_temp<=data_in;
     end
     
     //A combinational block for fifo_full. The input full_0,1,2 are coming from the FIFOs and based on these signals, fifo full is assigned w.r.t the data value
    always@(*)
    begin
        case(data_in_temp)
            2'b00:fifo_full=full_0;
            2'b01:fifo_full=full_1;
            2'b10:fifo_full=full_2;
            default:fifo_full=0;
        endcase
    end
    
    //A combinational block for write_enb. This signal is a 3 bit signal directed towards each of the 3 FIFOs by hot encoding w.r.t. data_in value
    always@(*)
    begin
        if(write_enb_reg)
        begin
            case(data_in_temp)
            2'b00:write_enb=3'b001;
            2'b00:write_enb=3'b010;
            2'b00:write_enb=3'b100;
            default:write_enb=0;
            endcase
        end
        else
            write_enb=0;
    end
    
    /*valid_out block. This block is designed to check if the FIFO is empty then there is no data. 
    If it is not empty then there is data for the valid output to be valid which inturn drives the read_enb signal.*/
    assign valid_0=!empty_0;
    assign valid_1=!empty_1;
    assign valid_2=!empty_2;
    
    /*soft_reset signal.
    Asserts a 30 clock counter. If valid is 1 then it checks for the read_enb. If the read_enb is high then count is set to 0 which meand the data is being read. 
    If the read_enb is low then count is incremented till 30 with an If statement and soft_reset is 1 and cout is 0.*/
    always@(posedge clock)
    begin
        if(!resetn)
        begin
            soft_reset_0<=0;
            count_0<=5'b0;
        end
        else
        if(valid_0)
        begin
            if(!read_enb_0)
            begin
                if(count_0==5'd30)
                begin
                    soft_reset_0<=1;
                    count_0<=0;
                end
                else
                begin
                    count_0<=count_0+1'b1;
                    soft_reset_0<=0;
                end
            end
            else
            begin
                soft_reset_0<=0;
                count_0<=0;
            end
        end
        else
            count_0<=0;
    end
    
    always@(posedge clock)
    begin
        if(!resetn)
        begin
            soft_reset_1<=0;
            count_1<=5'b0;
        end
        else
        if(valid_1)
        begin
            if(!read_enb_1)
            begin
                if(count_1==5'd30)
                begin
                    soft_reset_1<=1;
                    count_1<=0;
                end
                else
                begin
                    count_1<=count_1+1'b1;
                    soft_reset_1<=0;
                end
            end
            else
            begin
                soft_reset_1<=0;
                count_1<=0;
            end
        end
        else
            count_1<=0;
    end

    always@(posedge clock)
    begin
        if(!resetn)
        begin
            soft_reset_2<=0;
            count_2<=5'b0;
        end
        else
        if(valid_2)
        begin
            if(!read_enb_2)
            begin
                if(count_2==5'd30)
                begin
                    soft_reset_2<=1;
                    count_2<=0;
                end
                else
                begin
                    count_2<=count_2+1;
                    soft_reset_2<=0;
                end
            end
            else
            begin
                soft_reset_2<=0;
                count_2<=0;
            end
        end
        else
            count_2<=0;
    end        
          
endmodule
