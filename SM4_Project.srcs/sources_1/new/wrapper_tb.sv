`timescale 1ns / 1ps

module wrapper_tb();

    logic sysclk_i; 
    logic rst_tests_button_i;
    logic run_full_button_i;
    logic run_single_button_i;
    logic [13:0] display_o [3:0];
    logic [6:0] segments_left_o;
    logic [6:0] segments_right_o;
    logic [3:0] sel_left_o;
    logic [3:0] sel_right_o;
    
//    Design_Test_Wrapper DTW1(.sysclk_i(sysclk_i),
//                             .rst_tests_button_i(rst_tests_button_i),
//                             .run_full_button_i(run_full_button_i),
//                             .run_single_button_i(run_single_button_i),
//                             .display1_o(display_o[0]),
//                             .display2_o(display_o[1]),
//                             .display3_o(display_o[2]),
//                             .display4_o(display_o[3]));

    Display_Wrapper DW1(.sysclk_i(sysclk_i),
                        .rst_tests_button_i(rst_tests_button_i),
                        .run_full_button_i(run_full_button_i),
                        .run_single_button_i(run_single_button_i),
                        .sel_left_o(sel_left_o),
                        .sel_right_o(sel_right_o),
                        .segments_left_o(segments_left_o),
                        .segments_right_o(segments_right_o));
                             
    initial begin
        sysclk_i = 0;
        forever #10 sysclk_i = ~sysclk_i;
    end
    
    
    initial begin
        
        rst_tests_button_i = 1;
        run_full_button_i = 0;
        run_single_button_i = 0;
        
        #20;
        
        rst_tests_button_i = 0;
        
        #20;
        
        run_full_button_i = 1;
        
        #50000000;
        
        $stop;    
    
    end

endmodule
