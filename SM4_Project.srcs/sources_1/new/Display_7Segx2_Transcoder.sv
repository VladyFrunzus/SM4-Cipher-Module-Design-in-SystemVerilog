module Display_7Segx2_Transcoder(input logic [6:0] number_in,
                                 output logic [13:0] display_out);
                                 
                             
    always_comb begin
        
        if (number_in > 99) begin
        
            display_out = 14'b11111111111111;
         
        end else begin
    
            case(number_in%10)
            
              4'd0: display_out[6:0] = 7'b1000000;
              4'd1: display_out[6:0] = 7'b1111001;
              4'd2: display_out[6:0] = 7'b0100100;
              4'd3: display_out[6:0] = 7'b0110000;
              4'd4: display_out[6:0] = 7'b0011001;
              4'd5: display_out[6:0] = 7'b0010010;
              4'd6: display_out[6:0] = 7'b0000010;
              4'd7: display_out[6:0] = 7'b1111000;
              4'd8: display_out[6:0] = 7'b0000000; 
              4'd9: display_out[6:0] = 7'b0010000;
              default: display_out[6:0] = 7'b1111111;
              
            endcase 
            
            case(number_in/10)
            
              4'd0: display_out[13:7] = 7'b1000000;
              4'd1: display_out[13:7] = 7'b1111001;
              4'd2: display_out[13:7] = 7'b0100100;
              4'd3: display_out[13:7] = 7'b0110000;
              4'd4: display_out[13:7] = 7'b0011001;
              4'd5: display_out[13:7] = 7'b0010010;
              4'd6: display_out[13:7] = 7'b0000010;
              4'd7: display_out[13:7] = 7'b1111000;
              4'd8: display_out[13:7] = 7'b0000000; 
              4'd9: display_out[13:7] = 7'b0010000;
              default: display_out[13:7] = 7'b1111111;
              
            endcase 
        
        end
    
    end
                                
endmodule
