module ascon_permute(
    input logic [63:0] x0_in, x1_in, x2_in, x3_in, x4_in,
    input logic [3:0] round_constant,

    output logic [63:0] x0_out, x1_out, x2_out, x3_out, x4_out
);

    logic [63:0] s0, s1, s2, s3, s4;
    logic [63:0] t0, t1, t2, t3, t4;
    logic [63:0] x0, x1, x2, x3, x4;
    logic [63:0] x2_c;

    assign x2_c = x2_in ^ {56'b0, 4'hf - round_constant, round_constant};

    //S Box
    always_comb begin

        t0 = x0_in ^ x4_in;
        t1 = x1_in;
        t2 = x2_c ^ x1_in;
        t3 = x3_in;
        t4 = x4_in ^ x3_in;

        s0 = t0 ^ (~t1 & t2);
        s1 = t1 ^ (~t2 & t3);
        s2 = t2 ^ (~t3 & t4);
        s3 = t3 ^ (~t4 & t0);
        s4 = t4 ^ (~t0 & t1);

        x0 = s0 ^ s4;
        x1 = s1 ^ s0; 
        x2 = ~s2; 
        x3 = s3 ^ s2; 
        x4 = s4;
    
    end

    // Linear Diffusion
    assign x0_out = x0 ^ {x0[18:0], x0[63:19]} ^ {x0[27:0], x0[63:28]};
    assign x1_out = x1 ^ {x1[60:0], x1[63:61]} ^ {x1[38:0], x1[63:39]};
    assign x2_out = x2 ^ {x2[0:0],  x2[63:1]}  ^ {x2[5:0],  x2[63:6]};
    assign x3_out = x3 ^ {x3[9:0],  x3[63:10]} ^ {x3[16:0], x3[63:17]};
    assign x4_out = x4 ^ {x4[6:0],  x4[63:7]}  ^ {x4[40:0], x4[63:41]};

endmodule