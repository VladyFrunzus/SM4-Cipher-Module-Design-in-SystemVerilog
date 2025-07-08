module tauFunction(input logic [31:0] tau_i,
                   output logic [31:0] tau_o);
                 
               
    sbox sbox_i_1(tau_i[31:24],tau_o[31:24]);
    sbox sbox_i_2(tau_i[23:16],tau_o[23:16]);
    sbox sbox_i_3(tau_i[15:8],tau_o[15:8]);
    sbox sbox_i_4(tau_i[7:0], tau_o[7:0]);
    
endmodule
