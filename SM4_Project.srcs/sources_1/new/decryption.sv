module decryption(apb_interface.principal vif,
                input logic rst_n_i,
                input logic reset_dec_n_i,
                input logic [127:0] master_key_i,
                input logic [127:0] cypher_text_i,
                input logic [1:0] encryption_dir_i,
                output logic [127:0] decrypted_text_o,
                output logic decryption_done_o);
                
    
    reg [31:0] x0,x1,x2,x3;  
    reg [2:0] key_state;
    reg [31:0] round_key;
    reg [31:0] rk_gen, rk_read;
    reg rk_source; // 0 pentru generare, 1 pentru citire de pe APB
    reg [31:0] fout;
    reg [5:0] round_cnt;
    reg [5:0] key_gen_round;
    reg enable_key_gen;
    logic gen_dec_started;
    typedef enum bit [2:0] {IDLE, SELECT, ENABLE, UNSTABLE, READY, OP_START, OP_HAPPENING, OP_DONE} DEC_FSM;
    DEC_FSM fsm_state;
    
    logic [127:0] aux_mk;
    logic [127:0] aux_ct;

    Ffunction Ffunc2(vif.sysclk_i, rst_n_i, x0, x1, x2, x3, round_key, fout);
    RoundKeyGen RKG2(vif.sysclk_i, rst_n_i, enable_key_gen, master_key_i, key_state, rk_gen);
    
    assign round_key = (rk_source == 1) ? rk_read : rk_gen;
    
    always @(posedge vif.sysclk_i or negedge rst_n_i) begin
        
        if (rst_n_i != 1) begin
        
            x0 <= cypher_text_i[127:96];
            x1 <= cypher_text_i[95:64];
            x2 <= cypher_text_i[63:32];
            x3 <= cypher_text_i[31:0];
            key_state <= 0;
            round_cnt <= 0;
            key_gen_round <= 0;
            decryption_done_o <= 0;
            fsm_state <= IDLE;
            gen_dec_started <= 0;
                    
        end else begin
        
            if (reset_dec_n_i == 0) begin
            
                reset_decryption();
            
            end
        
            if (decryption_done_o == 1) begin
            
                decryption_done_o <= 0;
            
            end
            
            if (aux_mk != master_key_i || aux_ct != cypher_text_i) begin
            
                reset_decryption();
            
            end
            
            aux_mk <= master_key_i;
            aux_ct <= cypher_text_i;

            if (vif.memory_full == 1 && encryption_dir_i == 2'b10 && decryption_done_o == 0) begin
            
                enable_key_gen <= 0;
                rk_source <= 1;
                gen_dec_started <= 0;
                decryption_done_o <= 0;
                           
                if (fsm_state == IDLE)
                    fsm_state <= SELECT;
                    
                else if (fsm_state == SELECT)
                    fsm_state <= ENABLE;
                    
                else if (fsm_state == ENABLE)
                    fsm_state <= UNSTABLE;
                    
                else if (fsm_state == UNSTABLE)
                    fsm_state <= READY;
                    
                else if (fsm_state == READY)
                    fsm_state <= OP_START;
                
                else if (fsm_state == OP_START)
                    fsm_state <= OP_HAPPENING;
                    
                else if (fsm_state == OP_HAPPENING)
                    fsm_state <= OP_DONE;
                    
                else if (fsm_state == OP_DONE)
                    fsm_state <= SELECT;
                    
                
                if (fsm_state == SELECT) begin
                    
                    vif.paddr_i <= 31-round_cnt;
                    vif.psel_i <= 1;
                    vif.pwrite_i <= 0;
                    
                end else if (fsm_state == ENABLE) begin
              
                    vif.penable_i <= 1; 
                    
                end else if (fsm_state == UNSTABLE) begin
                
                    vif.penable_i <= 0;
                    
                end else if (fsm_state == READY) begin
                            
                    if (vif.pready_o == 1 && vif.pslverr_o == 0)
                        rk_read <= vif.prdata_o; 
                
                end else if (fsm_state == OP_DONE) begin
                
                    round_cnt <= round_cnt + 1;
                    x0 <= x1;
                    x1 <= x2;
                    x2 <= x3;
                    x3 <= fout;
                
                end

            end else if (encryption_dir_i == 2'b10 && decryption_done_o == 0 && gen_dec_started == 0) begin
                    
                enable_key_gen <= 1;  
                rk_source <= 0;
                gen_dec_started <= 1;
                key_state <= 1;
                
            end
        
            if (round_cnt < 32 && encryption_dir_i == 2'b10 && enable_key_gen == 1 && decryption_done_o == 0 && gen_dec_started == 1) begin
                
                fsm_state <= IDLE;
                decryption_done_o <= 0;
                key_state <= key_state + 1;        

                if (key_state == 1) begin
                
                    vif.penable_i <= 0;
                    
                end
                
                if (key_state == 3) begin
                
                    vif.paddr_i <= key_gen_round;
                    vif.psel_i <= 1;
                    vif.pwrite_i <= 1;
                
                end
                
                if (key_state == 4) begin
                
                    vif.penable_i <= 1;
                    vif.pwdata_i <= round_key;
                    key_state <= 1;
                    key_gen_round <= key_gen_round + 1;
                
                end
                
            end
            
            if (round_cnt == 32 && encryption_dir_i == 2'b10 && decryption_done_o == 0) begin
            
                // Decryption done
                decrypted_text_o[127:0] <= {x3, x2, x1, x0};
                decryption_done_o <= 1;
                gen_dec_started <= 0;
                
            end 
            
        end
        
    end
    
    
    task reset_decryption();
    
        x0 <= cypher_text_i[127:96];
        x1 <= cypher_text_i[95:64];
        x2 <= cypher_text_i[63:32];
        x3 <= cypher_text_i[31:0];
        key_state <= 0;
        round_cnt <= 0;
        key_gen_round <= 0;
        decrypted_text_o <= 0;
        decryption_done_o <= 0;
    
    endtask
     
    
endmodule
