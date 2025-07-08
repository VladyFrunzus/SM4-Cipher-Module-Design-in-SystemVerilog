module constantKey(input [4:0] cin,output reg [31:0] cout);

    always_comb
    
        case (cin)
        
            5'd0 : cout = 32'h0007_0E15;
            5'd1 : cout = 32'h1C23_2A31;
            5'd2 : cout = 32'h383F_464D;
            5'd3 : cout = 32'h545B_6269;
            5'd4 : cout = 32'h7077_7E85;
            5'd5 : cout = 32'h8C93_9AA1;
            5'd6 : cout = 32'hA8AF_B6BD;
            5'd7 : cout = 32'hC4CB_D2D9;
            5'd8 : cout = 32'hE0E7_EEF5;
            5'd9 : cout = 32'hFC03_0A11;
            5'd10 : cout = 32'h181F_262D;
            5'd11 : cout = 32'h343B_4249;
            5'd12 : cout = 32'h5057_5E65;
            5'd13 : cout = 32'h6C73_7A81;
            5'd14 : cout = 32'h888F_969D;
            5'd15 : cout = 32'hA4AB_B2B9;
            5'd16 : cout = 32'hC0C7_CED5;
            5'd17 : cout = 32'hDCE3_EAF1;
            5'd18 : cout = 32'hF8FF_060D;
            5'd19 : cout = 32'h141B_2229;
            5'd20 : cout = 32'h3037_3E45;
            5'd21 : cout = 32'h4C53_5A61;
            5'd22 : cout = 32'h686F_767D;
            5'd23 : cout = 32'h848B_9299;
            5'd24 : cout = 32'hA0A7_AEB5;
            5'd25 : cout = 32'hBCC3_CAD1;
            5'd26 : cout = 32'hD8DF_E6ED;
            5'd27 : cout = 32'hF4FB_0209;
            5'd28 : cout = 32'h1017_1E25;
            5'd29 : cout = 32'h2C33_3A41;
            5'd30 : cout = 32'h484F_565D;
            5'd31 : cout = 32'h646B_7279;
            
        endcase
        
endmodule
