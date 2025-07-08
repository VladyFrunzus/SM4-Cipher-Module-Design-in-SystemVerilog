module RoundKeyGen(input logic sysclk_i,
                    input logic rst_n_i,
                    input logic enable_i,
                    input logic [127:0] master_key_i,
                    input logic [2:0] key_state_i,
                    output logic [31:0] rk_o);

    reg [31:0] k [3:0];
    reg [31:0] k_init [3:0];
    reg [31:0] tprime_i;
    reg [31:0] tprime_o;
    reg [4:0] ck_i;
    reg [31:0] ck_o;
    bit [127:0] aux_key;

    reg [31:0] fk_0;
    reg [31:0] fk_1;
    reg [31:0] fk_2;
    reg [31:0] fk_3;
    
    initial begin
    
        fk_0 = 'hA3B1BAC6;
        fk_1 = 'h56AA3350;
        fk_2 = 'h677D9197;
        fk_3 = 'hB27022DC;
    
    end
    
    assign k_init[0] = master_key_i[127:96] ^ fk_0;
    assign k_init[1] = master_key_i[95:64] ^ fk_1;
    assign k_init[2] = master_key_i[63:32] ^ fk_2;
    assign k_init[3] = master_key_i[31:0] ^ fk_3;
    
    Tprimefunction Tprime1(sysclk_i, rst_n_i, tprime_i, tprime_o);
    constantKey constKey1(ck_i, ck_o);
    
    always @(posedge sysclk_i or negedge rst_n_i) begin
    
        if(!rst_n_i) begin

            k[0] <= k_init[0];
            k[1] <= k_init[1];
            k[2] <= k_init[2];
            k[3] <= k_init[3];
            ck_i <= 5'd0;
            aux_key <= 128'd0;
            tprime_i <= 32'd0;
            rk_o <= 32'd0;
        
        end else begin
        
            if (master_key_i != aux_key) begin

                k[0] <= k_init[0];
                k[1] <= k_init[1];
                k[2] <= k_init[2];
                k[3] <= k_init[3];
                ck_i <= 0;
            
            end
            
            aux_key <= master_key_i;
        
            if (key_state_i == 1 && enable_i == 1) begin
            
                tprime_i <= k[1] ^ k[2] ^ k[3] ^ ck_o;
                ck_i <= ck_i + 1;
            
            end else if (key_state_i == 3 && enable_i == 1) begin
            
                rk_o <= k[0] ^ tprime_o;
            
            end else if (key_state_i == 4 && enable_i == 1) begin
            
                k[0] <= k[1];
                k[1] <= k[2];
                k[2] <= k[3];
                k[3] <= rk_o;
            
            end
        
        end
     
    end
  
endmodule
