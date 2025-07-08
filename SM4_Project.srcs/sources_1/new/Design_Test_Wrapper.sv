module Design_Test_Wrapper (input logic sysclk_i,
                            input logic rst_tests_button_i,
                            input logic run_full_button_i,
                            input logic run_single_button_i,
                            output logic [13:0] display1_o,
                            output logic [13:0] display2_o,
                            output logic [13:0] display3_o,
                            output logic [13:0] display4_o);
    
    
   
    logic rst_n_i;
    logic start_enc_i;
    logic start_dec_i;
    logic [2:0] mode_of_operation_i;
    apb_interface top_if (.sysclk_i(sysclk_i));
    logic message_done_i;
    logic encryption_res_valid_o;
    logic decryption_res_valid_o;
    typedef enum bit [2:0] {ECB = 1, CBC, CFB_128, OFB, CTR} modes_of_op;
    
    bit [6:0] left1_counter_value;
    bit [6:0] left2_counter_value;
    bit [6:0] right1_counter_value;
    bit [6:0] right2_counter_value;
    bit [6:0] correct_enc_cnt;
    bit [6:0] correct_dec_cnt;
    bit [6:0] total_enc_cnt;
    bit [6:0] total_dec_cnt;
    bit single_req_flag;
    bit full_req_flag;
    bit single_btn_is_pressed;
    bit full_btn_is_pressed;
    bit [1:0] reset_counter;
    
    bit [3:0] test_index;
    bit test_result_correct;
    
    typedef enum bit [3:0] {RST1 = 0, ENC1, RST2, DEC1, RST3, ENC2, ENC3, RST4, DEC2, DEC3, RST5, ENC4, DEC4, ENC5, DEC5, RST6} test_state_machine;
    test_state_machine test_state;
    test_state_machine initial_ts;
    
    typedef enum bit [1:0] {WRITE = 0, WAIT_DONE, READ} big_state_machine;
    big_state_machine big_state;
    bit [3:0] small_state;
    typedef enum bit [1:0] {SEL = 0, ENABLE, READY} transfer_state_machine;
    transfer_state_machine transfer_state;
    bit first_clock;
    
    bit [2:0] word_cnt;

    //**************** Define test vectors ****************//    
    
    typedef struct { logic [127:0] key;
                     bit [511:0] plain;
                     bit [511:0] cypher;
                     bit [1:0] length;
                     bit [127:0] iv;
                     modes_of_op moo;
                    } test_vector;
                    
    test_vector vectors[10:0];
    
    initial begin
    
        left1_counter_value = 0;
        left2_counter_value = 0;
        right1_counter_value = 0;
        right2_counter_value = 0;
        single_req_flag = 0;
        full_req_flag = 0;
        correct_enc_cnt = 0;
        correct_dec_cnt = 0;
        total_enc_cnt = 0;
        total_dec_cnt = 0;
        single_btn_is_pressed = 0;
        full_btn_is_pressed = 0;
        test_index = 1;
        reset_counter = 0;
        first_clock = 0;
        
        Reset_Module();
        
        vectors[1].key = 'hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF;
        vectors[1].plain = 'hAA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD_EE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB;
        vectors[1].cypher = 'hC5_87_68_97_E4_A5_9B_BB_A7_2A_10_C8_38_72_24_5B_12_DD_90_BC_2D_20_06_92_B5_29_A4_15_5A_C9_E6_00;
        vectors[1].length = 1;
        vectors[1].iv = 0;
        vectors[1].moo = ECB;
  
        vectors[2].key = 'h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10; 
        vectors[2].plain = 'hAA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD_EE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB;
        vectors[2].cypher = 'h5E_C8_14_3D_E5_09_CF_F7_B5_17_9F_8F_47_4B_86_19_2F_1D_30_5A_7F_B1_7D_F9_85_F8_1C_84_82_19_23_04;
        vectors[2].length = 1;
        vectors[2].iv = 0;
        vectors[2].moo = ECB;

        vectors[3].key = 'h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10;
        vectors[3].plain = 'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD;
        vectors[3].cypher = 'h4C_B7_01_69_51_90_92_26_97_9B_0D_15_DC_6A_8F_6D_78_EB_B1_1C_C4_0B_0A_48_31_2A_AE_B2_04_02_44_CB;
        vectors[3].length = 1;
        vectors[3].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[3].moo = CBC;
        
        vectors[4].key = 'hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF;
        vectors[4].plain = 'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD;
        vectors[4].cypher = 'h91_F2_C1_47_91_1A_41_44_66_5E_1F_A1_D4_0B_AE_38_0D_3A_6D_DC_2D_21_C6_98_85_72_15_58_7B_7B_B5_9A;
        vectors[4].length = 1;
        vectors[4].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[4].moo = CBC;
        
        vectors[5].key = 'h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10;
        vectors[5].plain = 'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD;
        vectors[5].cypher = 'h69_D4_C5_4E_D4_33_B9_A0_34_60_09_BE_B3_7B_2B_3F_AC_32_36_CB_86_1D_D3_16_E6_41_3B_4E_3C_75_24_B7;
        vectors[5].length = 1;
        vectors[5].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[5].moo = CFB_128;

        vectors[6].key = 'hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF;
        vectors[6].plain = 'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD;
        vectors[6].cypher = 'h0D_9B_86_FF_20_C3_BF_E1_15_FF_A0_2C_A6_19_2C_C5_5D_CC_CD_25_A8_4B_A1_65_60_D7_F2_65_88_70_68_49;
        vectors[6].length = 1;
        vectors[6].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[6].moo = CFB_128;

        vectors[7].key = 'h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10; 
        vectors[7].plain = 'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD;
        vectors[7].cypher = 'h1D_01_AC_A2_48_7C_A5_82_CB_F5_46_3E_66_98_53_9B_AC_32_36_CB_86_1D_D3_16_E6_41_3B_4E_3C_75_24_B7;
        vectors[7].length = 1;
        vectors[7].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[7].moo = OFB;

        vectors[8].key = 'hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF;
        vectors[8].plain = 'hEE_EE_EE_EE_FF_FF_FF_FF_AA_AA_AA_AA_BB_BB_BB_BB_AA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_DD_DD_DD_DD;
        vectors[8].cypher = 'h33_FA_16_BD_5C_D9_C8_56_CA_CA_A1_E1_01_89_7A_97_5D_CC_CD_25_A8_4B_A1_65_60_D7_F2_65_88_70_68_49;
        vectors[8].length = 1;
        vectors[8].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[8].moo = OFB;

        vectors[9].key = 'h01_23_45_67_89_AB_CD_EF_FE_DC_BA_98_76_54_32_10;
        vectors[9].plain = 'hAA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB_EE_EE_EE_EE_EE_EE_EE_EE_FF_FF_FF_FF_FF_FF_FF_FF_CC_CC_CC_CC_CC_CC_CC_CC_DD_DD_DD_DD_DD_DD_DD_DD_AA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB;
        vectors[9].cypher = 'h6E_02_FC_D0_FA_A0_BA_F3_8B_29_33_85_1D_82_45_14_F2_34_BC_0E_24_C1_19_80_FD_12_86_31_0C_E3_7B_92_A3_CB_C1_87_8C_6F_30_CD_07_4C_CE_38_5C_DD_70_C7_AC_32_36_CB_97_0C_C2_07_91_36_4C_39_5A_13_42_D1;
        vectors[9].length = 3;
        vectors[9].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[9].moo = CTR;

        vectors[10].key = 'hFE_DC_BA_98_76_54_32_10_01_23_45_67_89_AB_CD_EF;
        vectors[10].plain = 'hAA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB_EE_EE_EE_EE_EE_EE_EE_EE_FF_FF_FF_FF_FF_FF_FF_FF_CC_CC_CC_CC_CC_CC_CC_CC_DD_DD_DD_DD_DD_DD_DD_DD_AA_AA_AA_AA_AA_AA_AA_AA_BB_BB_BB_BB_BB_BB_BB_BB;
        vectors[10].cypher = 'h8C_B5_B8_00_91_7A_24_88_28_4B_DE_9E_16_EA_29_06_0A_E0_29_72_05_D6_27_04_17_3B_21_23_9B_88_7F_6C_8F_66_15_21_CB_BA_B4_4C_C8_71_38_44_5B_C2_9E_5C_5D_CC_CD_25_B9_5A_B0_74_17_A0_85_12_EE_16_0E_2F;
        vectors[10].length = 3;
        vectors[10].iv = 'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        vectors[10].moo = CTR;
              
    end
    
    //*****************************************************//  
    
    //**************** Instantiate top module ****************//         
    
    SM4_Top_Module SM4_Top_Module(.rst_n_i(rst_n_i),
                                  .start_enc_i(start_enc_i),
                                  .start_dec_i(start_dec_i),
                                  .mode_of_operation_i(mode_of_operation_i),
                                  .top_if(top_if.secondary),
                                  .message_done_i(message_done_i),
                                  .encryption_res_valid_o(encryption_res_valid_o),
                                  .decryption_res_valid_o(decryption_res_valid_o));
                                  
    Display_7Segx2_Transcoder TR1(.number_in(left1_counter_value),
                                  .display_out(display4_o));
                                   
    Display_7Segx2_Transcoder TR2(.number_in(left2_counter_value),
                                  .display_out(display3_o));
                                   
    Display_7Segx2_Transcoder TR3(.number_in(right1_counter_value),
                                  .display_out(display2_o));
                                   
    Display_7Segx2_Transcoder TR4(.number_in(right2_counter_value),
                                  .display_out(display1_o));

     ila_0 ILA1(.clk(sysclk_i), 
                .probe0(left1_counter_value),
                .probe1(run_full_button_i),
                .probe2(top_if.sysclk_i),
                .probe3(top_if.paddr_i),
                .probe4(top_if.pwrite_i),
                .probe5(top_if.psel_i),
                .probe6(top_if.penable_i),
                .probe7(top_if.pready_o),
                .probe8(top_if.pwdata_i),
                .probe9(top_if.prdata_o),
                .probe10(top_if.pslverr_o),
                .probe11(rst_n_i),
                .probe12(SM4_Top_Module.SM4_Core.EC1.round_cnt),
                .probe13(SM4_Top_Module.SM4_Core.EC1.key_state),
                .probe14(SM4_Top_Module.SM4_Core.EC1.vif.pwdata_i),
                .probe15(SM4_Top_Module.SM4_Core.EC1.x3),
                .probe16(SM4_Top_Module.SM4_Core.EC1.RKG1.tprime_o),
                .probe17(SM4_Top_Module.SM4_Core.EC1.RKG1.tprime_i),
                .probe18(SM4_Top_Module.SM4_Core.EC1.RKG1.ck_i),
                .probe19(SM4_Top_Module.SM4_Core.EC1.RKG1.ck_o),
                .probe20(SM4_Top_Module.SM4_Core.DC1.RKG2.tprime_o),
                .probe21(SM4_Top_Module.SM4_Core.DC1.RKG2.tprime_i),
                .probe22(SM4_Top_Module.SM4_Core.DC1.RKG2.ck_i),
                .probe23(SM4_Top_Module.SM4_Core.DC1.RKG2.ck_o)
                );
                                  
     //*****************************************************// 
     
     //**************** Write master logic ****************// 
    
    always @(posedge sysclk_i or posedge rst_tests_button_i) begin
     
        if (rst_tests_button_i == 1) begin
        
            left1_counter_value <= 0;
            left2_counter_value <= 0;
            right1_counter_value <= 0;
            right2_counter_value <= 0;
            correct_enc_cnt <= 0;
            correct_dec_cnt <= 0;
            total_enc_cnt <= 0;
            total_dec_cnt <= 0;
            single_req_flag <= 0;
            full_req_flag <= 0;
            full_btn_is_pressed <= 0;
            single_btn_is_pressed <= 0;
            test_index <= 1;
            reset_counter <= 0;
            first_clock <= 0;
            
            Reset_Module();
        
        end else begin
        
            start_enc_i <= 0;
            start_dec_i <= 0;
            rst_n_i <= 1;
        
//            // Button logic
        
            if (run_full_button_i == 1 && full_btn_is_pressed == 0 && single_btn_is_pressed == 0 && full_req_flag == 0 && single_req_flag == 0) begin
            
                full_btn_is_pressed <= 1;
                full_req_flag <= 1;
                single_req_flag <= 0;
                        
                left1_counter_value <= 0;
                left2_counter_value <= 0;
                right1_counter_value <= 0;
                right2_counter_value <= 0;
                correct_enc_cnt <= 0;
                correct_dec_cnt <= 0;
                total_enc_cnt <= 0;
                total_dec_cnt <= 0;
                test_index <= 1;
                
                test_state <= RST1;
                big_state <= WRITE;
                small_state <= 0;
                transfer_state <= SEL;
                word_cnt <= 0;
                test_result_correct <= 1;
                first_clock <= 1;
            
            end
            
            else if (run_single_button_i == 1 && full_btn_is_pressed == 0 && single_btn_is_pressed == 0 && full_req_flag == 0 && single_req_flag == 0) begin
            
                single_btn_is_pressed <= 1;
                single_req_flag <= 1;
                full_req_flag <= 0;
            
            end
            
            if (run_full_button_i == 0 && full_btn_is_pressed == 1)
                full_btn_is_pressed <= 0;
                
            if (run_single_button_i == 0 && single_btn_is_pressed == 1)
                single_btn_is_pressed <= 0;
                
//            Test requested
                
            if (full_req_flag == 1 || single_req_flag == 1) begin
            
                if (test_index == 11) begin
                
                    full_req_flag <= 0;
                    left1_counter_value <= correct_enc_cnt;
                    left2_counter_value <= total_enc_cnt;
                    right1_counter_value <= correct_dec_cnt;
                    right2_counter_value <= total_dec_cnt;
                    test_index <= 1;
                    
                end else begin
                
                    if (test_state inside {RST1, RST2, RST3, RST4, RST5, RST6}) begin
 
                        reset_counter <= reset_counter + 1;
                        
                        if (reset_counter == 2'b11) begin
                        
                            if (test_state == RST6)          
                                test_index <= test_index + 1;
                            
                            test_state <= test_state.next;
                            reset_counter <= 0;
                            rst_n_i <= 1;
                                
                        end else begin
                        
                            Reset_Module();
                        
                        end
                    
                    end else if (test_state inside {ENC1, ENC2, ENC3, ENC4, ENC5}) begin
                    
                        if (word_cnt <= vectors[test_index].length) begin
                        
                            if (first_clock == 1) begin
                                
                                start_enc_i <= 1;
                                mode_of_operation_i <= vectors[test_index].moo;
                                message_done_i <= 0;
                                first_clock <= 0;
                                
                            end
                    
                            if (big_state == WRITE) begin
                            
                                if (transfer_state == ENABLE) begin
                                
                                    top_if.penable_i <= 1;
                                
                                end else if (transfer_state == READY) begin
                                
                                    top_if.penable_i <= 0;
                                
                                end else if (transfer_state == SEL) begin
                                    
                                    top_if.psel_i <= 1;
                                    top_if.penable_i <= 0;
                                    top_if.paddr_i <= small_state;
                                    top_if.pwrite_i <= 1;
                                    
                                    if (word_cnt == 0) begin
                                
                                        if (vectors[test_index].moo == ECB) begin
                                        
                                            if (small_state <= 3)
                                                top_if.pwdata_i <= vectors[test_index].key[small_state*32 +: 32];
                                            else if (small_state <= 7)
                                                top_if.pwdata_i <= vectors[test_index].plain[(small_state-4)*32 +: 32];
                                        
                                        end else begin
                                        
                                            if (small_state <= 3)
                                                top_if.pwdata_i <= vectors[test_index].iv[small_state*32 +: 32];
                                            else if (small_state <= 7)
                                                top_if.pwdata_i <= vectors[test_index].key[(small_state-4)*32 +: 32];
                                            else if (small_state <= 11)
                                                top_if.pwdata_i <= vectors[test_index].plain[(small_state-8)*32 +: 32];
                                        
                                        end
                                    
                                    end else if (word_cnt > 0) begin
                                    
                                        if (small_state <= 3)
                                            top_if.pwdata_i <= vectors[test_index].plain[128*word_cnt + small_state*32 +: 32];
                                    
                                    end
                                
                                end
                            
                                if (transfer_state == SEL) begin
                                
                                    transfer_state <= ENABLE;
                                
                                end else if (transfer_state == ENABLE) begin
                                
                                    transfer_state <= READY;
                                    
                                end else if (transfer_state == READY) begin
                                
                                    transfer_state <= SEL;
                                    small_state <= small_state + 1;
                                
                                end
                                
                                if ((word_cnt == 0 && vectors[test_index].moo == ECB && small_state == 8) || 
                                    (word_cnt == 0 && vectors[test_index].moo != ECB && small_state == 12) ||
                                    (word_cnt > 0 && small_state == 4)) begin
                                    
                                    small_state <= 0;
                                    big_state <= WAIT_DONE;
                                
                                end
                            
                            end else if (big_state == WAIT_DONE) begin
                            
                                top_if.penable_i <= 0;
                                
                                if (encryption_res_valid_o == 1)
                                    big_state <= READ;
                                
                                transfer_state <= SEL;
                            
                            end else if (big_state == READ) begin
                            
                                if (transfer_state == READY) begin
                                
                                    top_if.penable_i <= 0;
                                    
                                    if (small_state != 0) begin
                                    
                                        if (top_if.prdata_o != vectors[test_index].cypher[128*word_cnt + 32*(small_state-1) +: 32])
                                            test_result_correct <= 0;
                                       
                                    end
                                
                                end else if (transfer_state == ENABLE) begin
                                
                                    if (small_state < 4)
                                        top_if.penable_i <= 1;
                                
                                end else if (transfer_state == SEL) begin
                                    
                                    if (small_state <= 4) begin
                                        
                                        top_if.psel_i <= 1;
                                        top_if.penable_i <= 0;
                                        top_if.paddr_i <= small_state;
                                        top_if.pwrite_i <= 0;
                                    
                                    end
                                
                                end
                                
                                if (small_state == 5 && transfer_state == SEL) begin
                                    
                                    small_state <= 0;
                                    big_state <= WRITE;
                                    word_cnt <= word_cnt + 1;
                                
                                end else
                            
                                if (transfer_state == SEL) begin
                                
                                    transfer_state <= ENABLE;
                                
                                end else if (transfer_state == ENABLE) begin
                                
                                    transfer_state <= READY;
                                    
                                end else if (transfer_state == READY) begin
                                
                                    transfer_state <= SEL;
                                    small_state <= small_state + 1;
                                
                                end
                            
                            end
                            
                        end else if (word_cnt > vectors[test_index].length) begin
                            
                            message_done_i <= 1;
                            small_state <= 0;
                            big_state <= WRITE;
                            transfer_state <= SEL;
                            first_clock <= 1;
                            word_cnt <= 0;
                            
                            test_state <= test_state.next;
                            
                            if (test_result_correct == 1)
                                correct_enc_cnt <= correct_enc_cnt + 1;  
                            
                            total_enc_cnt <= total_enc_cnt + 1;
                            
                            test_result_correct <= 1;
                        
                        end
                    
                    end else if (test_state inside {DEC1, DEC2, DEC3, DEC4, DEC5}) begin
                    
                        if (word_cnt <= vectors[test_index].length) begin
                        
                            if (first_clock == 1) begin
                                
                                start_dec_i <= 1;
                                mode_of_operation_i <= vectors[test_index].moo;
                                message_done_i <= 0;
                                first_clock <= 0;
                                
                            end 
                            
                            if (big_state == WRITE) begin
                            
                                if (transfer_state == ENABLE) begin
                                
                                    top_if.penable_i <= 1;
                                
                                end else if (transfer_state == READY) begin
                                
                                    top_if.penable_i <= 0;
                                
                                end else if (transfer_state == SEL) begin
                                    
                                    top_if.psel_i <= 1;
                                    top_if.penable_i <= 0;
                                    top_if.paddr_i <= small_state;
                                    top_if.pwrite_i <= 1;
                                    
                                    if (word_cnt == 0) begin
                                
                                        if (vectors[test_index].moo == ECB) begin
                                        
                                            if (small_state <= 3)
                                                top_if.pwdata_i <= vectors[test_index].key[small_state*32 +: 32];
                                            else if (small_state <= 7)
                                                top_if.pwdata_i <= vectors[test_index].cypher[(small_state-4)*32 +: 32];
                                        
                                        end else begin
                                        
                                            if (small_state <= 3)
                                                top_if.pwdata_i <= vectors[test_index].iv[small_state*32 +: 32];
                                            else if (small_state <= 7)
                                                top_if.pwdata_i <= vectors[test_index].key[(small_state-4)*32 +: 32];
                                            else if (small_state <= 11)
                                                top_if.pwdata_i <= vectors[test_index].cypher[(small_state-8)*32 +: 32];
                                        
                                        end
                                    
                                    end else if (word_cnt > 0) begin
                                    
                                        if (small_state <= 3)
                                            top_if.pwdata_i <= vectors[test_index].cypher[128*word_cnt + small_state*32 +: 32];
                                    
                                    end
                                
                                end
                            
                                if (transfer_state == SEL) begin
                                
                                    transfer_state <= ENABLE;
                                
                                end else if (transfer_state == ENABLE) begin
                                
                                    transfer_state <= READY;
                                    
                                end else if (transfer_state == READY) begin
                                
                                    transfer_state <= SEL;
                                    small_state <= small_state + 1;
                                
                                end
                                
                                if ((word_cnt == 0 && vectors[test_index].moo == ECB && small_state == 8) || 
                                    (word_cnt == 0 && vectors[test_index].moo != ECB && small_state == 12) ||
                                    (word_cnt > 0 && small_state == 4)) begin
                                    
                                    small_state <= 0;
                                    big_state <= WAIT_DONE;
                                
                                end
                            
                            end else if (big_state == WAIT_DONE) begin
                            
                                top_if.penable_i <= 0;
                                
                                if (decryption_res_valid_o == 1)
                                    big_state <= READ;
                                    
                                transfer_state <= SEL;

                            end else if (big_state == READ) begin
        
                                if (transfer_state == READY) begin
                                
                                    top_if.penable_i <= 0;
                                    
                                    if (small_state != 0) begin
                                    
                                        if (top_if.prdata_o != vectors[test_index].plain[128*word_cnt + 32*(small_state-1) +: 32])
                                            test_result_correct <= 0;
                                     
                                    end
                                
                                end else if (transfer_state == ENABLE) begin
                                
                                     if (small_state < 4)
                                        top_if.penable_i <= 1;
                                
                                end else if (transfer_state == SEL) begin
                                    
                                    if (small_state <= 4) begin
                                    
                                        top_if.psel_i <= 1;
                                        top_if.penable_i <= 0;
                                        top_if.paddr_i <= small_state;
                                        top_if.pwrite_i <= 0;
                                        
                                    end
                                
                                end
                            
                                if (small_state == 5 && transfer_state == SEL) begin
                                    
                                    small_state <= 0;
                                    big_state <= WRITE;
                                    word_cnt <= word_cnt + 1;
                                
                                end else
                            
                                if (transfer_state == SEL) begin
                                
                                    transfer_state <= ENABLE;
                                
                                end else if (transfer_state == ENABLE) begin
                                
                                    transfer_state <= READY;
                                    
                                end else if (transfer_state == READY) begin
                                
                                    transfer_state <= SEL;
                                    small_state <= small_state + 1;
                                
                                end
                            
                            end
                            
                        end else if (word_cnt > vectors[test_index].length) begin
                        
                            message_done_i <= 1;
                            small_state <= 0;
                            big_state <= WRITE;
                            transfer_state <= SEL;
                            first_clock <= 1;
                            word_cnt <= 0;
                            
                            test_state <= test_state.next;
                            
                            if (test_result_correct == 1)
                                correct_dec_cnt <= correct_dec_cnt + 1;  
                            
                            total_dec_cnt <= total_dec_cnt + 1;
                            
                            test_result_correct <= 1;
                        
                        end
                    
                    end
				
				end
            
            end
        
        end
    
    
    end
    
    //*****************************************************// 
    
    //**************** Reset SM4 Module Function ****************// 
    
    function void Reset_Module();
    
        rst_n_i <= 0;
        start_enc_i <= 0;
        start_dec_i <= 0;
        message_done_i <= 0;
        
        top_if.paddr_i <= 0;
        top_if.psel_i <= 0;
        top_if.penable_i <= 0;
        top_if.pwrite_i <= 0;
        top_if.pwdata_i <= 0;
    
    endfunction
    
    //*****************************************************// 
    
endmodule
