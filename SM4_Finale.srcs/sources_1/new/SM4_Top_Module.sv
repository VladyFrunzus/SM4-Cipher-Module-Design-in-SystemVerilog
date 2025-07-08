module SM4_Top_Module (input logic rst_n_i,
                       input logic start_enc_i,
                       input logic start_dec_i,
                       input bit [2:0] mode_of_operation_i,
                       apb_interface.secondary top_if,
                       input logic message_done_i,
                       output logic encryption_res_valid_o,
                       output logic decryption_res_valid_o
                       );
            
   
    
    logic encryption_done_o;
    logic decryption_done_o;
    logic start_read;
    logic enc_req_i;
    logic dec_req_i;
    logic enc_in_prog;
    logic dec_in_prog;
    logic first_access;
    logic data_stream_done;
    logic wait_clock;
    logic [127:0] init_vector;
    logic [127:0] aux_iv;
    logic [127:0] master_key;
    logic [127:0] plain_text;
    logic [127:0] cypher_text_dec;
    logic [127:0] cypher_text_enc; 
    logic [127:0] decrypted_text;
    
    typedef enum bit [1:0] {SEL = 0, ENABLE, READY} apb_states;
    apb_states apb_state;
   
   apb_interface core_if (.sysclk_i(top_if.sysclk_i));
   
   SM4_Core SM4_Core(.rst_n_i(rst_n_i),
                     .enc_req_i(enc_req_i),
                     .dec_req_i(dec_req_i),
                     .core_if(core_if.secondary),
                     .encryption_done_o(encryption_done_o), 
                     .decryption_done_o(decryption_done_o));          
    
    always @(posedge top_if.sysclk_i or negedge rst_n_i) begin
    
        if (!rst_n_i) begin
        
            enc_req_i <= 0;
            dec_req_i <= 0;
            enc_in_prog <= 0;
            dec_in_prog <= 0;
            first_access <= 0;
            data_stream_done <= 0;
            wait_clock <= 0;
            start_read <= 0;
            init_vector <= 0;
            aux_iv <= 0;
            master_key <= 0;
            plain_text <= 0;
            cypher_text_dec <= 0;
            cypher_text_enc <= 0; 
            decrypted_text <= 0;
            top_if.pready_o <= 0;
            top_if.pslverr_o <= 0;
            top_if.prdata_o <= 0;
            core_if.paddr_i <= 0;
            core_if.pwrite_i <= 0;
            core_if.psel_i <= 0;
            core_if.penable_i <= 0;
            core_if.pwdata_i <= 0;
        
        end else begin
        
            top_if.pready_o <= 0;
            top_if.pslverr_o <= 0;
            encryption_res_valid_o <= 0;
            decryption_res_valid_o <= 0;
        
            if (start_enc_i == 1 && enc_in_prog == 0) begin
            
                enc_in_prog <= 1;
                first_access <= 1;
                data_stream_done <= 0;
                start_read <= 0;
                    
           end
                
            if (start_dec_i == 1 && dec_in_prog == 0) begin
            
                dec_in_prog <= 1;
                first_access <= 1;
                data_stream_done <= 0;
                start_read <= 0;
        
            end
             
            if ((enc_in_prog ^ dec_in_prog == 1) && top_if.psel_i == 1 && top_if.pwrite_i == 1 && top_if.penable_i == 1 && data_stream_done == 0 && message_done_i == 0) begin
              
                top_if.pready_o <= 1;
                top_if.pslverr_o <= 0;
                
                if (mode_of_operation_i == 1 && first_access == 1) begin
                
                    if (top_if.paddr_i <= 3) begin
                    
                        master_key[top_if.paddr_i*32 +: 32] <= top_if.pwdata_i;
                    
                    end 
                    
                    if (top_if.paddr_i >= 4 && top_if.paddr_i <= 7) begin
                    
                        if (enc_in_prog == 1)
                            plain_text[(top_if.paddr_i-4)*32 +: 32] <= top_if.pwdata_i;
                        else
                            cypher_text_dec[(top_if.paddr_i-4)*32 +: 32] <= top_if.pwdata_i;
                    
                    end
                    
                    if (top_if.paddr_i == 7) begin
                        
                        wait_clock <= 1;
                
                    end
                
                end else if (first_access == 1) begin
                
                    if (top_if.paddr_i <= 3) begin 
                
                        init_vector[top_if.paddr_i*32 +: 32] <= top_if.pwdata_i;
                    
                    end 
                    
                    if (top_if.paddr_i >= 4 && top_if.paddr_i <= 7) begin
                    
                        master_key[(top_if.paddr_i-4)*32 +: 32] <= top_if.pwdata_i;
                    
                    end
                    
                    if (top_if.paddr_i >= 8 && top_if.paddr_i <= 11) begin
                    
                        if (enc_in_prog == 1)
                            plain_text[(top_if.paddr_i-8)*32 +: 32] <= top_if.pwdata_i;
                        else
                            cypher_text_dec[(top_if.paddr_i-8)*32 +: 32] <= top_if.pwdata_i;
                    
                    end
                    
                    if (top_if.paddr_i == 11) begin
                        
                        wait_clock <= 1;
                
                    end
                
                end else if (first_access == 0) begin
                
                    if (top_if.paddr_i <= 3) begin
                    
                        if (enc_in_prog == 1)
                            plain_text[top_if.paddr_i*32 +: 32] <= top_if.pwdata_i;
                        else
                            cypher_text_dec[top_if.paddr_i*32 +: 32] <= top_if.pwdata_i;
                    
                    end
                    
                    if (top_if.paddr_i == 3) begin
                        
                        wait_clock <= 1;
                
                    end
                
                end
                     
            end else if (wait_clock == 1) begin

                wait_clock <= 0;
                data_stream_done <= 1;
                core_if.paddr_i <= 5'b11111;    
                apb_state <= SEL;
            
            end else if (enc_in_prog == 1 && dec_in_prog == 1) begin
            
                top_if.pslverr_o <= 1;
                
            end else if (message_done_i == 1 && top_if.psel_i == 1 && top_if.penable_i == 1) begin
            
                top_if.pslverr_o <= 1;
            
            end else if (data_stream_done == 1 && (core_if.paddr_i <= 7 || core_if.paddr_i == 5'b11111) && message_done_i == 0) begin
                
                if (mode_of_operation_i inside {[1:2]}) begin
                
                    if (enc_in_prog == 1)
                        enc_req_i <= 1;
                    else if (dec_in_prog == 1)
                        dec_req_i <= 1;
                                          
                end else if (mode_of_operation_i inside {[3:5]}) begin
                
                    enc_req_i <= 1;
     
                end
                
                if (mode_of_operation_i inside {[2:4]} && first_access == 1) begin
                
                    aux_iv <= init_vector;
                    
                end else if (mode_of_operation_i == 3 && enc_in_prog == 1) begin
                
                    aux_iv <= cypher_text_enc;
                
                end
                
                if (apb_state == SEL) begin
                    
                    core_if.psel_i <= 1;
                    core_if.penable_i <= 0;
                    core_if.paddr_i += 1;
                    core_if.pwrite_i <= 1;
                    
                    if (core_if.paddr_i <= 3) begin
                    
                        core_if.pwdata_i <= master_key[core_if.paddr_i*32 +: 32];
                    
                    end else if (core_if.paddr_i <= 7 && core_if.paddr_i >= 4) begin
                    
                        if (mode_of_operation_i == 1) begin
                        
                            if (enc_in_prog == 1)
                                core_if.pwdata_i <= plain_text[(core_if.paddr_i-4)*32 +: 32];
                            else if (dec_in_prog == 1)
                                core_if.pwdata_i <= cypher_text_dec[(core_if.paddr_i-4)*32 +: 32];
                            
                        end
                        
                        if (mode_of_operation_i == 2) begin
                        
                            if (enc_in_prog == 1)
                                core_if.pwdata_i <= plain_text[(core_if.paddr_i-4)*32 +: 32] ^ aux_iv[(core_if.paddr_i-4)*32 +: 32];
                            else if (dec_in_prog == 1)
                                core_if.pwdata_i <= cypher_text_dec[(core_if.paddr_i-4)*32 +: 32];
                         
                        end
                        
                        if (mode_of_operation_i == 3) begin

                            core_if.pwdata_i <= aux_iv[(core_if.paddr_i-4)*32 +: 32];
                          
                        end
                        
                        if (mode_of_operation_i == 4) begin

                            core_if.pwdata_i <= aux_iv[(core_if.paddr_i-4)*32 +: 32];
                          
                        end
                        
                        if (mode_of_operation_i == 5) begin
                        
                            core_if.pwdata_i <= init_vector[(core_if.paddr_i-4)*32 +: 32];
                            
                        end
                    
                    end
                    
                    apb_state <= ENABLE;
                              
                end else if (apb_state == ENABLE) begin
                
                    core_if.penable_i <= 1;
                    apb_state <= READY;
                
                end else if (apb_state == READY) begin
                
                    core_if.penable_i <= 0;
                    apb_state <= SEL;
                
                end
            
            end else if ((encryption_done_o == 1 || decryption_done_o == 1) && message_done_i == 0) begin
                
                    first_access <= 0;
                    start_read <= 1;
                    apb_state <= SEL;
                    data_stream_done <= 0;
                    dec_req_i <= 0;
                    enc_req_i <= 0;
                    core_if.paddr_i <= 5'b11111;
            
            end else if (start_read == 1 && (core_if.paddr_i <= 3 || core_if.paddr_i == 5'b11111) && message_done_i == 0) begin
               
               if (apb_state == SEL) begin
                    
                    if (core_if.pready_o == 1) begin
                    
                        if (enc_in_prog == 1) begin
                            cypher_text_enc[core_if.paddr_i*32 +: 32] <= core_if.prdata_o; 
                        end
                        else if (dec_in_prog == 1)
                            decrypted_text[core_if.paddr_i*32 +: 32] <= core_if.prdata_o;
                        
                    end
                        
                    core_if.psel_i <= 1;
                    core_if.penable_i <= 0;
                    core_if.paddr_i += 1;
                    core_if.pwrite_i <= 0;
                    
                    apb_state = ENABLE;
                              
                end else if (apb_state == ENABLE) begin
                
                    core_if.penable_i <= 1;
                    apb_state <= READY;
                
                end else if (apb_state == READY) begin
                
                    core_if.penable_i <= 0;
                    apb_state <= SEL;
                
                end
            
            end else if (start_read == 1 && (core_if.paddr_i == 4 || core_if.paddr_i == 5'b10100) && message_done_i == 0) begin
            
                if (enc_in_prog == 1)
                    encryption_res_valid_o <= 1;
                else if (dec_in_prog == 1)
                    decryption_res_valid_o <= 1;
                    
                if (mode_of_operation_i == 2) begin
                 
                    if (enc_in_prog == 1) begin
                    
                        aux_iv <= cypher_text_enc;
                    
                    end
                    
                    else if (dec_in_prog == 1) begin
                    
                        decrypted_text <= decrypted_text ^ aux_iv;
                        aux_iv <= cypher_text_dec;
                        
                    end 
                
                end
                
                if (mode_of_operation_i == 3) begin
                
                    if (enc_in_prog == 1) begin
                    
                        cypher_text_enc <= cypher_text_enc ^ plain_text;
                    
                    end
                    
                    else if (dec_in_prog == 1) begin
                    
                        decrypted_text <= decrypted_text ^ cypher_text_dec;
                        aux_iv <= cypher_text_dec;
                        
                    end 
            
                end
                
                if (mode_of_operation_i == 4) begin
                
                    if (enc_in_prog == 1) begin
                   
                        aux_iv <= cypher_text_enc;
                        cypher_text_enc <= cypher_text_enc ^ plain_text;
                    
                    end
                    
                    else if (dec_in_prog == 1) begin
                    
                        aux_iv <= decrypted_text;
                        decrypted_text <= decrypted_text ^ cypher_text_dec;
                        
                    end 
            
                end
                
                
                if (mode_of_operation_i == 5) begin
                
                    if (enc_in_prog == 1)
                        cypher_text_enc <= cypher_text_enc ^ plain_text; 
                    else if (dec_in_prog == 1)
                        decrypted_text <= decrypted_text ^ cypher_text_dec;
                        
                    init_vector += 1;
            
                end
                
                start_read <= 0;
                data_stream_done <= 0;
            
            end else if (top_if.psel_i == 1 && top_if.penable_i == 1 && top_if.pwrite_i == 0 && message_done_i == 0) begin
                
                top_if.pready_o <= 1;
                top_if.pslverr_o <= 0;
                   
                if (enc_in_prog == 1) 
                    top_if.prdata_o <= cypher_text_enc[top_if.paddr_i*32 +: 32];
                else if (dec_in_prog == 1)
                    top_if.prdata_o <= decrypted_text[top_if.paddr_i*32 +: 32];
                
            end else if (message_done_i == 1) begin
            
                init_vector <= 0;
                enc_in_prog <= 0;
                dec_in_prog <= 0;

            end
        
        end
    
    end
   
    
endmodule
