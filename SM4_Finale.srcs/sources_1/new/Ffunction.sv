module Ffunction(input logic sysclk_i,
                input logic rst_n_i,
                input logic [31:0] x0_i,
                input logic [31:0] x1_i,
                input logic [31:0] x2_i,
                input logic [31:0] x3_i,
                input logic [31:0] rk_i,
                output logic [31:0] fout);
    
    wire [31:0] targ;
    wire [31:0] faux;
    
    assign targ = x1_i ^ x2_i ^ x3_i ^ rk_i;
    
    Tfunction T1(sysclk_i, rst_n_i, targ, faux);         
	
    always@(posedge sysclk_i or negedge rst_n_i)
        if(!rst_n_i)
           fout <= 0;    
	    else
	       fout <= x0_i ^ faux;

endmodule