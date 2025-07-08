`timescale 1ns / 1ps

module simple_tb();

    logic sysclk_i; 
    logic rst_n_i;
    logic start_enc_i;
    logic start_dec_i; 
    logic message_done_i; 
    logic [127:0] cypher_text_enc;
    logic [127:0] decrypted_text; 
    logic encryption_res_valid_o;
    logic decryption_res_valid_o;
    logic read_encryption_res;
    logic read_decryption_res;
    logic encryption_res_wrong;
    logic decryption_res_wrong;
    logic enc_wrong_flag;
    logic dec_wrong_flag;
    typedef enum bit [2:0] {ECB = 1, CBC, CFB_128, OFB, CTR} modes_of_op;
    modes_of_op mode_of_operation_i;
    typedef enum bit {ENCRYPTION = 0, DECRYPTION} req_operation_type;
    
    apb_interface top_if (.sysclk_i(sysclk_i));
    
    logic [4:0] test_idx;
    int idx;
    int i;
    int j;
    logic [127:0] aux;
    logic [31:0] small_aux;
    
    typedef struct { logic [127:0] key;
                     bit [127:0] plain [];
                     bit [127:0] cypher [];
                     bit [127:0] iv;
                     modes_of_op moo;
                    } test_vector;
    
    test_vector vectors[31:0];
   
    initial begin
        add_test_vector(.idx(0), 
                        .key('h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10), 
                        .plain({<<8{'h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10}}),
                        .cypher({<<8{'h68_1E_DF_34_D2_06_96_5E_86_B3_E9_4F_53_6E_42_46}}), 
                        .iv(0),
                        .moo(ECB)
                        );
        add_test_vector(.idx(1), 
                        .key('hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF), 
                        .plain({<<8{'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F}}),
                        .cypher({<<8{'hF7_66_67_8F_13_F0_1A_DE_AC_1B_3E_A9_55_AD_B5_94}}),
                        .iv(0),
                        .moo(ECB)
                        );
        add_test_vector(.idx(2), 
                        .key('hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF), 
                        .plain({<<8{'hAA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD_EE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB}}),
                        .cypher({<<8{'hC5_87_68_97_E4_A5_9B_BB_A7_2A_10_C8_38_72_24_5B_12_DD_90_BC_2D_20_06_92_B5_29_A4_15_5A_C9_E6_00}}),
                        .iv(0),
                        .moo(ECB)
                        );  
        add_test_vector(.idx(3), 
                        .key('h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10), 
                        .plain({<<8{'hAA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD_EE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB}}),
                        .cypher({<<8{'h5E_C8_14_3D_E5_09_CF_F7_B5_17_9F_8F_47_4B_86_19_2F_1D_30_5A_7F_B1_7D_F9_85_F8_1C_84_82_19_23_04}}),
                        .iv(0),
                        .moo(ECB)
                        ); 
        add_test_vector(.idx(4), 
                        .key('h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10), 
                        .plain({<<8{'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD}}),
                        .cypher({<<8{'h4C_B7_01_69_51_90_92_26_97_9B_0D_15_DC_6A_8F_6D_78_EB_B1_1C_C4_0B_0A_48_31_2A_AE_B2_04_02_44_CB}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(CBC)
                        );
        add_test_vector(.idx(5), 
                        .key('hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF), 
                        .plain({<<8{'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD}}),
                        .cypher({<<8{'h91_F2_C1_47_91_1A_41_44_66_5E_1F_A1_D4_0B_AE_38_0D_3A_6D_DC_2D_21_C6_98_85_72_15_58_7B_7B_B5_9A}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(CBC)
                        );
        add_test_vector(.idx(6), 
                        .key('h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10), 
                        .plain({<<8{'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD}}),
                        .cypher({<<8{'h69_D4_C5_4E_D4_33_B9_A0_34_60_09_BE_B3_7B_2B_3F_AC_32_36_CB_86_1D_D3_16_E6_41_3B_4E_3C_75_24_B7}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(CFB_128)
                        );
        add_test_vector(.idx(7), 
                        .key('hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF), 
                        .plain({<<8{'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD}}),
                        .cypher({<<8{'h0D_9B_86_FF_20_C3_BF_E1_15_FF_A0_2C_A6_19_2C_C5_5D_CC_CD_25_A8_4B_A1_65_60_D7_F2_65_88_70_68_49}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(CFB_128)
                        );
        add_test_vector(.idx(8), 
                        .key('h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10), 
                        .plain({<<8{'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD}}),
                        .cypher({<<8{'h1D_01_AC_A2_48_7C_A5_82_CB_F5_46_3E_66_98_53_9B_AC_32_36_CB_86_1D_D3_16_E6_41_3B_4E_3C_75_24_B7}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(OFB)
                        );
        add_test_vector(.idx(9), 
                        .key('hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF), 
                        .plain({<<8{'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD}}),
                        .cypher({<<8{'h33_FA_16_BD_5C_D9_C8_56_CA_CA_A1_E1_01_89_7A_97_5D_CC_CD_25_A8_4B_A1_65_60_D7_F2_65_88_70_68_49}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(OFB)
                        );
        add_test_vector(.idx(10), 
                        .key('h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10), 
                        .plain({<<8{'hAA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB_EE_EE_EE_EE_EE_EE_EE_EE_FF_FF_FF_FF_FF_FF_FF_FF_CC_CC_CC_CC_CC_CC_CC_CC_DD_DD_DD_DD_DD_DD_DD_DD_AA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB}}),
                        .cypher({<<8{'h6E_02_FC_D0_FA_A0_BA_F3_8B_29_33_85_1D_82_45_14_F2_34_BC_0E_24_C1_19_80_FD_12_86_31_0C_E3_7B_92_A3_CB_C1_87_8C_6F_30_CD_07_4C_CE_38_5C_DD_70_C7_AC_32_36_CB_97_0C_C2_07_91_36_4C_39_5A_13_42_D1}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(CTR)
                        );
        add_test_vector(.idx(11), 
                        .key('hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF), 
                        .plain({<<8{'hAA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB_EE_EE_EE_EE_EE_EE_EE_EE_FF_FF_FF_FF_FF_FF_FF_FF_CC_CC_CC_CC_CC_CC_CC_CC_DD_DD_DD_DD_DD_DD_DD_DD_AA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB}}),
                        .cypher({<<8{'h8C_B5_B8_00_91_7A_24_88_28_4B_DE_9E_16_EA_29_06_0A_E0_29_72_05_D6_27_04_17_3B_21_23_9B_88_7F_6C_8F_66_15_21_CB_BA_B4_4C_C8_71_38_44_5B_C2_9E_5C_5D_CC_CD_25_B9_5A_B0_74_17_A0_85_12_EE_16_0E_2F}}),
                        .iv('h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F),
                        .moo(CTR)
                        );
        $display("%h %h", vectors[9].plain[0], vectors[9].plain[1]);
    end
    
    initial begin
        sysclk_i = 0;
        forever #10 sysclk_i = ~sysclk_i;
    end
      
    SM4_Top_Module SM4_Top_Module(.rst_n_i(rst_n_i),
                                  .start_enc_i(start_enc_i),
                                  .start_dec_i(start_dec_i),
                                  .mode_of_operation_i(mode_of_operation_i),
                                  .top_if(top_if.secondary),
                                  .message_done_i(message_done_i),
                                  .encryption_res_valid_o(encryption_res_valid_o),
                                  .decryption_res_valid_o(decryption_res_valid_o));
                                  
//    assign ctr_width = SM4_Top_Module.COUNTER_WIDTH/32;
    
    always @(posedge read_encryption_res) begin
    
        #1;
        
//        $display("%h, %h", cypher_text_enc, vectors[test_idx].cypher[i]);
    
        if (cypher_text_enc == vectors[test_idx].cypher[i]) begin
            
            encryption_res_wrong = 0;
            $display(vectors[test_idx].moo.name(), ": Word number %0d/%0d ENCRYPTION CORRECT at time %0d.", i+1, vectors[test_idx].plain.size(), $time-1);
        
        end else begin
        
            encryption_res_wrong = 1;
            $display(vectors[test_idx].moo.name(), ": Word number %0d/%0d ENCRYPTION WRONG at time %0d.", i+1, vectors[test_idx].plain.size(), $time-1);
            
        end
    
    end
    
    always @(posedge read_decryption_res) begin
    
        #1;
        
//        $display("%h, %h", decrypted_text, vectors[test_idx].plain[i]);
    
        if (decrypted_text == vectors[test_idx].plain[i]) begin
        
            decryption_res_wrong = 0;
            $display(vectors[test_idx].moo.name(), ": Word number %0d/%0d DECRYPTION CORRECT at time %0d.", i+1, vectors[test_idx].cypher.size(), $time-1);
            
        end else begin
        
            decryption_res_wrong = 1;
            $display(vectors[test_idx].moo.name(), ": Word number %0d/%0d DECRYPTION WRONG at time %0d.", i+1, vectors[test_idx].cypher.size(), $time-1);
    
        end
        
    end
    
    
    initial begin
       
        for (test_idx = 0; test_idx <= 11; test_idx++) begin
       
            reset_module();
            
            start_new_operation(.requested_operation(ENCRYPTION),
                                .master_key(vectors[test_idx].key), 
                                .input_text(vectors[test_idx].plain),
                                .init_vector(vectors[test_idx].iv),
                                .mode_of_operation(vectors[test_idx].moo));
                
            reset_module();
            
            start_new_operation(.requested_operation(DECRYPTION),
                                .master_key(vectors[test_idx].key), 
                                .input_text(vectors[test_idx].cypher),
                                .init_vector(vectors[test_idx].iv),
                                .mode_of_operation(vectors[test_idx].moo));
            
            start_new_operation(.requested_operation(DECRYPTION),
                                .master_key(vectors[test_idx].key), 
                                .input_text(vectors[test_idx].cypher),
                                .init_vector(vectors[test_idx].iv),
                                .mode_of_operation(vectors[test_idx].moo));
                                
            start_new_operation(.requested_operation(ENCRYPTION),
                                .master_key(vectors[test_idx].key), 
                                .input_text(vectors[test_idx].plain),
                                .init_vector(vectors[test_idx].iv),
                                .mode_of_operation(vectors[test_idx].moo));
                                         
            reset_module();
            
            start_new_operation(.requested_operation(ENCRYPTION),
                                .master_key(vectors[test_idx].key), 
                                .input_text(vectors[test_idx].plain),
                                .init_vector(vectors[test_idx].iv),
                                .mode_of_operation(vectors[test_idx].moo));
               
            start_new_operation(.requested_operation(ENCRYPTION),
                                .master_key(vectors[test_idx].key), 
                                .input_text(vectors[test_idx].plain),
                                .init_vector(vectors[test_idx].iv),
                                .mode_of_operation(vectors[test_idx].moo)); 

        end            
        
        $stop;
    
    end
    
    
    task add_test_vector(input int idx, input logic [127:0] key, input byte plain [], input byte cypher [], input logic [127:0] iv, modes_of_op moo);
    
        vectors[idx].key = key;
        vectors[idx].iv = iv;
        vectors[idx].moo = moo; 
        
        vectors[idx].plain  = new[(plain.size()+15) /16]; 
        vectors[idx].cypher = new[(plain.size()+15) /16];
        
        for (i = 0; i < plain.size()/16; i++) begin
            
            for (j = 0; j < 16; j++) begin
                
                aux = 'h0 + plain[16*i + j]<<8*j;
                vectors[idx].plain[i] += aux;

                aux = 'h0 + cypher[16*i + j]<<8*j;
                vectors[idx].cypher[i] += aux;
            
            end
        end
        
    endtask 
    
        
    task reset_module();
    
        rst_n_i = 0;
        start_enc_i = 0;
        start_dec_i = 0;
        message_done_i = 0;
        mode_of_operation_i = ECB;
        cypher_text_enc = 0;
        decrypted_text = 0; 
        read_encryption_res = 0;
        read_decryption_res = 0;
        encryption_res_wrong = 0;
        decryption_res_wrong = 0;
        enc_wrong_flag = 0;
        dec_wrong_flag = 0;
        top_if.paddr_i <= 0;
        top_if.psel_i <= 0;
        top_if.penable_i <= 0;
        top_if.pwrite_i <= 0;
        top_if.pwdata_i <= 0;
    
        repeat(5) begin
            @(posedge sysclk_i);
        end 
        
        rst_n_i = 1;
    
    endtask
    
    
    task start_new_operation(req_operation_type requested_operation, input logic [127:0] master_key, input bit [127:0] input_text [], input logic [127:0] init_vector, modes_of_op mode_of_operation);
        
        enc_wrong_flag = 0;
        dec_wrong_flag = 0;
        read_encryption_res = 0;
        read_decryption_res = 0;
        
        mode_of_operation_i = mode_of_operation;
        message_done_i = 0;
        
        if (requested_operation == ENCRYPTION)
            start_enc_i = 1;
        else
            start_dec_i = 1;
            
        @(posedge sysclk_i); 
        start_enc_i = 0;
        start_dec_i = 0;
        
        j = 0;
        i = 0;
       
        if (mode_of_operation == ECB) begin

            while (j <= 7) begin
            
                if (j <= 3)
                    small_aux = master_key[j*32 +: 32];
                else if (j <= 7) begin
                    small_aux = input_text[i][(j-4)*32 +: 32];
                    
                end
                   
                top_if.write(.addr(j), .wdata(small_aux));
                 
                j += 1;
                
            end
     
        end else begin
        
            while (j <= 11) begin
            
                if (j <= 3)
                    small_aux = init_vector[j*32 +: 32];
                else if (j <= 7)
                    small_aux = master_key[(j-4)*32 +: 32];
                else
                    small_aux = input_text[i][(j-8)*32 +: 32];
                   
                top_if.write(.addr(j), .wdata(small_aux));
                 
                j += 1;
                
            end
        
        end
        
        if (requested_operation == ENCRYPTION)
            @(posedge encryption_res_valid_o);
        else if (requested_operation == DECRYPTION)
            @(posedge decryption_res_valid_o);
            
        @(posedge sysclk_i);
        
        j = 0;
        
        while (j <= 3) begin
        
            top_if.read(.addr(j), .rdata(small_aux));
            
            if (requested_operation == ENCRYPTION)
                cypher_text_enc[j*32 +: 32] = small_aux;
            else if (requested_operation == DECRYPTION)
                decrypted_text[j*32 +: 32] = small_aux;
            
            j += 1;
        
        end
        
        if (requested_operation == ENCRYPTION)
            read_encryption_res = 1;
        else if (requested_operation == DECRYPTION)
            read_decryption_res = 1;
        
        @(posedge sysclk_i);
        
        if (encryption_res_wrong == 1)
            enc_wrong_flag = 1;
            
        if (decryption_res_wrong == 1)
            dec_wrong_flag = 1;
            
        read_encryption_res = 0;
        read_decryption_res = 0;
        
        for (i = 1; i < input_text.size(); i ++) begin
        
            j = 0;
    
            while (j <= 3) begin

                small_aux = input_text[i][j*32 +: 32];
                
                top_if.write(.addr(j), .wdata(small_aux));
                
                j += 1;
            
            end
                
            if (requested_operation == ENCRYPTION)
                @(posedge encryption_res_valid_o);
            else if (requested_operation == DECRYPTION)
                @(posedge decryption_res_valid_o);
            
            @(posedge sysclk_i);
            
            j = 0;
            
            while (j <= 3) begin
            
                top_if.read(.addr(j), .rdata(small_aux));
                
                if (requested_operation == ENCRYPTION)
                    cypher_text_enc[j*32 +: 32] = small_aux;
                else if (requested_operation == DECRYPTION)
                    decrypted_text[j*32 +: 32] = small_aux;
                
                j += 1;
            
            end
            
             if (requested_operation == ENCRYPTION)
                read_encryption_res = 1;
            else if (requested_operation == DECRYPTION)
                read_decryption_res = 1;
            
            @(posedge sysclk_i);
            
            if (encryption_res_wrong == 1)
                enc_wrong_flag = 1;
                
            if (decryption_res_wrong == 1)
                dec_wrong_flag = 1;
                
            read_encryption_res = 0;
            read_decryption_res = 0;
            
        end

        message_done_i = 1;
        
        if (enc_wrong_flag == 0 && requested_operation == ENCRYPTION) 
            $display("DONE ", vectors[test_idx].moo.name(), ": Full message with index %0d has been CORRECTLY ENCRYPTED.", test_idx);
        else if (enc_wrong_flag == 1 && requested_operation == ENCRYPTION)
            $display("DONE ", vectors[test_idx].moo.name(), ": Full message with index %0d has been WRONGLY ENCRYPTED.", test_idx);
            
        if (dec_wrong_flag == 0 && requested_operation == DECRYPTION) 
            $display("DONE ", vectors[test_idx].moo.name(), ": Full message with index %0d has been CORRECTLY DECRYPTED.", test_idx);
        else if (dec_wrong_flag == 1 && requested_operation == DECRYPTION)
            $display("DONE ", vectors[test_idx].moo.name(), ": Full message with index %0d has been WRONGLY DECRYPTED.", test_idx);
            
        @(posedge sysclk_i);
    
    endtask
  
  
endmodule
