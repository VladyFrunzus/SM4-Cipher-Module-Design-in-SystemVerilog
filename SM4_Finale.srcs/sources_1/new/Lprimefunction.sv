function logic [31:0] Lprimefunction (
    input  logic [31:0] lin
);
            
    Lprimefunction =
          lin
        ^ rotate_left_32bit(lin, 13)
        ^ rotate_left_32bit(lin, 23);

endfunction
