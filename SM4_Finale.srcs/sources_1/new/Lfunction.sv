function logic [31:0] Lfunction (
    input  logic [31:0] lin
);

    int unsigned a;

    Lfunction =
          lin
        ^ rotate_left_32bit(lin,  2)
        ^ rotate_left_32bit(lin, 10)
        ^ rotate_left_32bit(lin, 18)
        ^ rotate_left_32bit(lin, 24);
        
    a = Lfunction;

endfunction
