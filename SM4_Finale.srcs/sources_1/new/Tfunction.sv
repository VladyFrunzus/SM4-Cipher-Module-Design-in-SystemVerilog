module Tfunction(input logic sysclk_i,
                input logic rst_n_i,
                input logic [31:0] tin,
                output logic [31:0] tout);
   
    logic [31:0] taux;              
    tauFunction tau1(tin,taux);
    
    always@(posedge sysclk_i or negedge rst_n_i)
        if(!rst_n_i) 
	       tout <= 0;
        else
           tout <= Lfunction(taux);
   
endmodule
