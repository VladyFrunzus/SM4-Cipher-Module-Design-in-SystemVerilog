module SM4_Core(input logic rst_n_i,
                input logic enc_req_i,
                input logic dec_req_i,
                apb_interface.secondary core_if,
                output logic encryption_done_o,
                output logic decryption_done_o);

    
    logic enc_in_prog;
    logic dec_in_prog;
    logic reset_enc_n_i;
    logic reset_dec_n_i;
    logic [1:0] encryption_dir = 2'b00;
    logic [127:0] master_key_i;
    logic [127:0] plain_text_i;
    logic [127:0] cypher_text_dec_i;
    logic [127:0] cypher_text_enc_o; 
    logic [127:0] decrypted_text_o;
    
    apb_interface rk_if_mem (.sysclk_i(core_if.sysclk_i));
    apb_interface rk_if_ec (.sysclk_i(core_if.sysclk_i));
    apb_interface rk_if_dc (.sysclk_i(core_if.sysclk_i));
    
    encryption EC1(rk_if_ec.principal, rst_n_i, reset_enc_n_i, master_key_i, plain_text_i, encryption_dir, cypher_text_enc_o, encryption_done_o);
    decryption DC1(rk_if_dc.principal, rst_n_i, reset_dec_n_i, master_key_i, cypher_text_dec_i, encryption_dir, decrypted_text_o, decryption_done_o);
    RoundKeyStorage RKS1(rk_if_mem.secondary, rst_n_i, master_key_i);
    
    assign rk_if_mem.paddr_i   = (encryption_dir == 2'b11) ? rk_if_ec.paddr_i :
                                 (encryption_dir == 2'b10) ? rk_if_dc.paddr_i : 5'd0;
    assign rk_if_mem.pwrite_i   = (encryption_dir == 2'b11) ? rk_if_ec.pwrite_i :
                                  (encryption_dir == 2'b10) ? rk_if_dc.pwrite_i : 1'd0;
    assign rk_if_mem.psel_i   = (encryption_dir == 2'b11) ? rk_if_ec.psel_i :
                                (encryption_dir == 2'b10) ? rk_if_dc.psel_i : 1'd0;
    assign rk_if_mem.penable_i   = (encryption_dir == 2'b11) ? rk_if_ec.penable_i :
                                   (encryption_dir == 2'b10) ? rk_if_dc.penable_i : 1'd0;
    assign rk_if_mem.pwdata_i   = (encryption_dir == 2'b11) ? rk_if_ec.pwdata_i :
                                  (encryption_dir == 2'b10) ? rk_if_dc.pwdata_i : 32'd0;
                                  
    assign rk_if_ec.pready_o   = rk_if_mem.pready_o;
    assign rk_if_ec.prdata_o   = rk_if_mem.prdata_o;
    assign rk_if_ec.pslverr_o  = rk_if_mem.pslverr_o;
    assign rk_if_ec.memory_full = rk_if_mem.memory_full;
    
    assign rk_if_dc.pready_o   = rk_if_mem.pready_o;
    assign rk_if_dc.prdata_o   = rk_if_mem.prdata_o;
    assign rk_if_dc.pslverr_o  = rk_if_mem.pslverr_o;
    assign rk_if_dc.memory_full = rk_if_mem.memory_full;
    
    always @(posedge core_if.sysclk_i or negedge rst_n_i) begin
    
        if (!rst_n_i) begin
        
            encryption_dir <= 2'b00;
            enc_in_prog <= 0;
            dec_in_prog <= 0;
            core_if.pready_o <= 0;
            core_if.prdata_o <= 0;
            core_if.pslverr_o <= 0;
        
        end else begin
        
            // Reset all pulses to inactive values
            reset_enc_n_i <= 1; 
            reset_dec_n_i <= 1;
            core_if.pready_o <= 0;
            core_if.pslverr_o <= 0;
            
            if (enc_req_i == 1)
                enc_in_prog <= 1;
                
            if (dec_req_i == 1)
                dec_in_prog <= 1;
            
            if (enc_req_i == 1 && core_if.pwrite_i == 1 && dec_req_i == 0 && core_if.psel_i == 1 && core_if.penable_i == 1) begin
            
                core_if.pready_o <= 1;
                core_if.pslverr_o <= 0;
            
                if (core_if.pwrite_i == 1 && core_if.paddr_i <= 3)
                    master_key_i[core_if.paddr_i*32 +: 32] <= core_if.pwdata_i;
                
                if (core_if.pwrite_i == 1 && core_if.paddr_i >= 4 && core_if.paddr_i <= 7)
                    plain_text_i[(core_if.paddr_i-4)*32 +: 32] <= core_if.pwdata_i;
                
                if (core_if.pwrite_i == 1 && core_if.paddr_i == 7) begin
                
                    encryption_dir <= 2'b11;
                    reset_enc_n_i <= 0;
                    
                end
            
            end else if (dec_req_i == 1 && core_if.pwrite_i == 1 && enc_req_i == 0 && core_if.psel_i == 1 && core_if.penable_i == 1) begin
            
                core_if.pready_o <= 1;
                core_if.pslverr_o <= 0; 
                
                if (core_if.paddr_i <= 3)
                    master_key_i[core_if.paddr_i*32 +: 32] <= core_if.pwdata_i;

                if (core_if.paddr_i >= 4 && core_if.paddr_i <= 7)
                    cypher_text_dec_i[(core_if.paddr_i-4)*32 +: 32] <= core_if.pwdata_i;
                
                if (core_if.paddr_i == 7) begin
                
                    encryption_dir <= 2'b10;
                    reset_dec_n_i <= 0;
                    
                end

            end else if (enc_req_i == 1 && dec_req_i == 1 && core_if.psel_i == 1 && core_if.penable_i == 1) begin
            
                core_if.pslverr_o <= 1;
                
            end else if (core_if.paddr_i <= 3 && core_if.psel_i == 1 && core_if.penable_i == 1 && core_if.pwrite_i == 0) begin
                
                core_if.pready_o <= 1;
                core_if.pslverr_o <= 0;
                
                if (enc_in_prog == 1) 
                    core_if.prdata_o <= cypher_text_enc_o[core_if.paddr_i*32 +: 32];
                else if (dec_in_prog == 1)
                    core_if.prdata_o <= decrypted_text_o[core_if.paddr_i*32 +: 32];
                    
                if (core_if.paddr_i == 3) begin
                
                    enc_in_prog <= 0;
                    dec_in_prog <= 0;
                    
                end
                
            end else if (encryption_done_o == 1 || decryption_done_o == 1) begin
            
                encryption_dir <= 2'b00;
                
            end

        end
          
    end
    
endmodule
