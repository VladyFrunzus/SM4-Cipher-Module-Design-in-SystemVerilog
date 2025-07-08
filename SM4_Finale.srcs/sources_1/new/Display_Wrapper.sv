module Display_Wrapper(input logic sysclk_i,
                       input logic rst_tests_button_i,
                       input logic run_full_button_i,
                       input logic run_single_button_i, 
                       output logic [3:0] sel_left_o,
                       output logic [3:0] sel_right_o,
                       output logic [7:0] segments_left_o,
                       output logic [7:0] segments_right_o);
    
    
    logic [27:0] display_left;
    logic [27:0] display_right;
    reg state;
    reg [1:0] count;
    logic [19:0] freq_divider;
    
    assign segments_left_o[7:1] = display_left[27:21];
    assign segments_right_o[7:1] = display_right[27:21];
    assign segments_left_o[0] = (sel_left_o == 4'b1011) ? 0:1;
    assign segments_right_o[0] = (sel_right_o == 4'b1011) ? 0:1;
    
    Design_Test_Wrapper DTW1(.sysclk_i(sysclk_i),
                             .rst_tests_button_i(rst_tests_button_i),
                             .run_full_button_i(run_full_button_i),
                             .run_single_button_i(run_single_button_i));
                             
    ila_1 ILA2(.clk(sysclk_i), 
               .probe0(sel_left_o),
               .probe1(sel_right_o),
               .probe2(segments_left_o),
               .probe3(segments_right_o),
               .probe4(DTW1.left1_counter_value),
               .probe5(DTW1.correct_enc_cnt),
               .probe6(DTW1.right1_counter_value),
               .probe7(DTW1.correct_dec_cnt));
                             
                             
    always @(posedge sysclk_i) begin
    
        case (state)
        
            0: begin
            
                sel_left_o <= 4'b0111;
                sel_right_o <= 4'b0111;
                display_left <= {DTW1.display4_o, DTW1.display3_o};
                display_right <= {DTW1.display2_o, DTW1.display1_o};
                count <= 0;
                freq_divider <= 0;
                state <= 1;
                
            end
            
            1: begin
            
                if(count == 3 && freq_divider == 200000)
                    state <= 0;
                else if (freq_divider == 200000) begin
                    count <= count + 1;
                    freq_divider <= 0;
                end
                    
                if (freq_divider == 199999) begin
                
                    display_left <= display_left << 7;
                    display_right <= display_right << 7;
                    sel_left_o <= {1'b1, sel_left_o[3:1]};
                    sel_right_o <= {1'b1, sel_right_o[3:1]};
                    
                end
                
                if (freq_divider != 200000)
                    freq_divider <= freq_divider + 1;
               
            end
        
            default : state <= 0;
            
        endcase
    
    end
    
    
endmodule
