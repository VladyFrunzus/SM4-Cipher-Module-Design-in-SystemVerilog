module Tprimefunction(input logic sysclk_i,
                    input logic rst_n_i,
                    input logic [31:0] tin,
                    output logic [31:0] tout);
   
    logic [31:0] taux;              
    tauFunction tau2(tin,taux);
    
    always@(posedge sysclk_i or negedge rst_n_i)
        if(!rst_n_i)
            tout <= 0;
        else
            tout <= Lprimefunction(taux);
   
endmodule

