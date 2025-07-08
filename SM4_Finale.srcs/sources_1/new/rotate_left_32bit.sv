function automatic logic [31:0] rotate_left_32bit (input logic [31:0] v, 
                                                   input int unsigned s);
				
        int unsigned res;
        int unsigned s_mod = s & 31; // modulo 31, a.i. sa nu avem 0 la iesire
        rotate_left_32bit = (v << s_mod) | (v >> (32 - s_mod));
        res = rotate_left_32bit;

endfunction
