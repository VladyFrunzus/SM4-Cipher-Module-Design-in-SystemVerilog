module RoundKeyStorage(apb_interface.secondary vif,
                       input logic rst_n_i,
                       input logic [127:0] master_key_i);

    
    logic [31:0] rk_mem [0:31];
    int i;
    static logic memory_full = 0;
    static logic memory_wait = 0;
    static logic [31:0] app_array;
    
    logic [127:0] aux_mk;
    
    assign vif.memory_full = memory_full;
    
    always_ff @(posedge vif.sysclk_i or negedge rst_n_i) begin
                
        if (rst_n_i != 1) begin
        
            for (i = 0; i < 32; i++) begin
                rk_mem[i]    <= 0;
                app_array[i] <= 1'b0;
            end
                
            vif.pready_o <= 0;
            vif.prdata_o <= 0;
            vif.pslverr_o <= 0;
            memory_full <= 1'b0;
            memory_wait <= 1'b0;
    
        end else begin 
        
            // Reset all pulses to inactive values
            vif.pready_o <= 0;
            vif.pslverr_o <= 0;     
            
            if (aux_mk != master_key_i) begin
            
                reset_memory();
            
            end
            
            aux_mk = master_key_i;

            if (vif.psel_i == 1 && vif.penable_i == 1) begin
            
                vif.pready_o <= 1;
    
                if (!vif.pwrite_i) begin
                
                    vif.prdata_o <= rk_mem[vif.paddr_i];
                    
                    if (app_array[vif.paddr_i] == 1)
                        vif.pslverr_o <= 1'b0;
                    else
                        vif.pslverr_o <= 1'b1;
    
                end else if (vif.pwrite_i && app_array[vif.paddr_i] == 0) begin
                
                    rk_mem[vif.paddr_i] <= vif.pwdata_i;
                    app_array[vif.paddr_i] <= 1'b1;
                    
                    if (rk_mem[vif.paddr_i] == vif.pwdata_i)
                        vif.pslverr_o <= 1'b0;
                    else
                        vif.pslverr_o <= 1'b1;
                        
                    // De adaugat partea cu suprascriere = eroare, nuj daca vreau
     
                end
           
            end
        
        if (memory_wait == 1)
            memory_full <= 1'b1;
    
        if (&app_array)             
            memory_wait <= 1'b1;
            
            
        end
    
    end
        
    
    task reset_memory();
    
        for (i = 0; i < 32; i++) begin
            rk_mem[i]    <= 0;
            app_array[i] <= 1'b0;
        end
        
        memory_full <= 1'b0;
        memory_wait <= 1'b0;
    
    endtask  
    
    
endmodule
