interface apb_interface (input sysclk_i);

    logic [4:0] paddr_i; 
	logic psel_i;
	logic penable_i;
	logic pwrite_i;
	logic pready_o;
	logic [31:0] pwdata_i;
	logic [31:0] prdata_o;
	logic pslverr_o;
	logic memory_full;
	
	modport principal (input sysclk_i, pready_o, prdata_o, pslverr_o, memory_full, 
	                   output paddr_i, psel_i, penable_i, pwrite_i, pwdata_i);
	                 
    modport secondary (input sysclk_i, paddr_i, psel_i, penable_i, pwrite_i, pwdata_i, 
                       output pready_o, prdata_o, pslverr_o, memory_full);
                       
    task write (input logic [31:0] addr, input logic [31:0] wdata);
    
        paddr_i = addr;
        psel_i = 1;
        pwrite_i = 1;
        pwdata_i = wdata;
        
        @(posedge sysclk_i);
        
        penable_i = 1;
                 
        @(posedge sysclk_i);
        
        penable_i = 0;
    
    endtask
    
    task read (input logic [31:0] addr, output logic [31:0] rdata);
    
        paddr_i = addr;
        psel_i = 1;
        pwrite_i = 0;
        
        @(posedge sysclk_i);
        
        penable_i = 1;
        
        if (pready_o == 0)  
            @(posedge pready_o);
        
        @(posedge sysclk_i);
        
        penable_i = 0;
        rdata = prdata_o;
    
    endtask
    
endinterface