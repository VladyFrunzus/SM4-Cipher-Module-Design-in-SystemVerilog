module encryption(apb_interface.principal vif,
                input logic rst_n_i,
                input logic reset_enc_n_i,
                input logic [127:0] master_key_i,
                input logic [127:0] plain_text_i,
                input logic [1:0] encryption_dir_i,
                output logic [127:0] cypher_text_o,
                output logic encryption_done_o);
                
    
    reg [31:0] x0,x1,x2,x3;  
    reg [2:0] key_state;
    reg [31:0] round_key;
    reg [31:0] rk_gen, rk_read;
    reg rk_source; // 0 pentru generare, 1 pentru citire de pe APB
    reg [31:0] fout;
    reg [5:0] round_cnt;
    reg enable_key_gen;
    logic wait_clock;
    logic fast_enc_started;
    logic fast_enc_finished;
    typedef enum bit [2:0] {IDLE, SELECT, ENABLE, UNSTABLE, READY, OP_START, OP_HAPPENING, OP_DONE} ENC_FSM;
    ENC_FSM fsm_state;
    
    logic [127:0] aux_mk;
    logic [127:0] aux_pt;

    Ffunction Ffunc1(vif.sysclk_i, rst_n_i, x0, x1, x2, x3, round_key, fout);
    RoundKeyGen RKG1(vif.sysclk_i, rst_n_i, enable_key_gen, master_key_i, key_state, rk_gen);
    
    assign round_key = (rk_source == 1) ? rk_read : rk_gen;
    
    always @(posedge vif.sysclk_i or negedge rst_n_i) begin
        
        if (rst_n_i != 1) begin
        
            x0 <= plain_text_i[127:96];
            x1 <= plain_text_i[95:64];
            x2 <= plain_text_i[63:32];
            x3 <= plain_text_i[31:0];
            key_state <= 0;
            round_cnt <= 0;
            encryption_done_o <= 0;
            fsm_state <= IDLE;
            fast_enc_started <= 0;
            fast_enc_finished <= 0;
            wait_clock <= 0;
            
            vif.paddr_i <= 0;
            vif.psel_i <= 0;
            vif.penable_i <= 0;
            vif.pwrite_i <= 0;
            vif.pwdata_i <= 0;
                    
        end else begin
        
            if (reset_enc_n_i == 0) begin
            
                reset_encryption();
            
            end
        
            if (encryption_done_o == 1) begin
            
                encryption_done_o <= 0;
            
            end
            
            if (aux_mk != master_key_i || aux_pt != plain_text_i) begin
            
                reset_encryption();
            
            end
            
            aux_mk <= master_key_i;
            aux_pt <= plain_text_i;

            if (vif.memory_full == 1 && encryption_dir_i == 2'b11 && encryption_done_o == 0) begin
            
                enable_key_gen <= 0;
                rk_source <= 1;
                fast_enc_started <= 0;
                fast_enc_finished <= 0;
                encryption_done_o <= 0;
                wait_clock <= 0;
                           
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
                    
                    vif.paddr_i <= round_cnt;
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
                
                if (round_cnt == 32 && fast_enc_started == 0 && encryption_dir_i == 2'b11 && encryption_done_o == 0) begin
            
                    // Encryption done
                    cypher_text_o[127:0] <= {x3, x2, x1, x0};
                    encryption_done_o <= 1;
                    fast_enc_started <= 0;
                
                end 

            end else if (encryption_dir_i == 2'b11 && encryption_done_o == 0 && fast_enc_started == 0) begin
                    
                enable_key_gen <= 1;  
                rk_source <= 0;
                fast_enc_started <= 1;
                key_state <= 1;
                
            end
        
            if (round_cnt < 32 && encryption_dir_i == 2'b11 && enable_key_gen == 1 && encryption_done_o == 0 && fast_enc_started == 1) begin
                
                fsm_state <= IDLE;
                encryption_done_o <= 0;
                key_state <= key_state + 1;
    
                if (key_state == 1) begin
                    
                    vif.penable_i <= 0;
                    
                end
                
                if (key_state == 2 && round_cnt > 0) begin
                
                    x0 <= x1;
                    x1 <= x2;
                    x2 <= x3;
                    x3 <= fout;
                
                end

                if (key_state == 3) begin
                    
                    vif.paddr_i <= round_cnt;
                    vif.psel_i <= 1;
                    vif.pwrite_i <= 1;

                end
                
                if (key_state == 4) begin
                
                    vif.pwdata_i <= round_key;
                    vif.penable_i <= 1;
                    key_state <= 1;
                    round_cnt <= round_cnt + 1;
                    
                end
                
            end else if (round_cnt == 32 && encryption_dir_i == 2'b11 && enable_key_gen == 1 && encryption_done_o == 0 && fast_enc_started == 1 && wait_clock == 0 && fast_enc_finished == 0) begin
            
                wait_clock <= 1;
            
            end else if (round_cnt == 32 && encryption_dir_i == 2'b11 && enable_key_gen == 1 && encryption_done_o == 0 && fast_enc_started == 1 && wait_clock == 1 && fast_enc_finished == 0) begin
                
                wait_clock <= 0;
                x0 <= x1;
                x1 <= x2;
                x2 <= x3;
                x3 <= fout;
                fast_enc_finished <= 1;
            
            end else if (fast_enc_finished == 1) begin
            
                fast_enc_finished <= 0;
                cypher_text_o[127:0] <= {x3, x2, x1, x0};
                encryption_done_o <= 1;
                fast_enc_started <= 0;
            
            end
                   
        end
        
    end
    
    
    task reset_encryption();
    
        x0 <= plain_text_i[127:96];
        x1 <= plain_text_i[95:64];
        x2 <= plain_text_i[63:32];
        x3 <= plain_text_i[31:0];
        key_state <= 0;
        round_cnt <= 0;
        cypher_text_o <= 0;
        encryption_done_o <= 0;
    
    endtask
    
endmodule
