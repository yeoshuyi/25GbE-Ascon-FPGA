module ascon_permute (
    input logic clk,
    input logic reset,
    input logic [319:0] state_in,
    
    output logic [319:0] state_out
); 
    localparam logic [12*8-1:0] ROUND_CONSTS = {
        8'hf0, 8'he1, 8'hd2, 8'hc3, 
        8'hb4, 8'ha5, 8'h96, 8'h87, 
        8'h78, 8'h69, 8'h5a, 8'h4b
    };

    logic [63:0] s0[0:2], s1[0:2], s2[0:2], s3[0:2], s4[0:2];

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         {s0[0], s1[0], s2[0], s3[0], s4[0]} <= '0;
    //     end else begin
    //         {s0[0], s1[0], s2[0], s3[0], s4[0]} <= state_in;
    //     end
    // end

    always_comb begin
        {s0[0], s1[0], s2[0], s3[0], s4[0]} = state_in;
    end

    genvar i;
    generate
        for (i = 0; i < 2; i++) begin

            logic [63:0]    n0_0, n0_1, n0_2, n0_3, n0_4, 
                            n1_0, n1_1, n1_2, n1_3, n1_4, 
                            n2_0, n2_1, n2_2, n2_3, n2_4,
                            n3_0, n3_1, n3_2, n3_3, n3_4,
                            n4_0, n4_1, n4_2, n4_3, n4_4,
                            n5_0, n5_1, n5_2, n5_3, n5_4;
            always_ff @(posedge clk) begin
                if (reset) {s0[i+1], s1[i+1], s2[i+1], s3[i+1], s4[i+1]} <= '0;
                //else {s0[i+1], s1[i+1], s2[i+1], s3[i+1], s4[i+1]} <= {n3_0, n3_1, n3_2, n3_3, n3_4};
                //else {s0[i+1], s1[i+1], s2[i+1], s3[i+1], s4[i+1]} <= {n1_0, n1_1, n1_2, n1_3, n1_4};
                else {s0[i+1], s1[i+1], s2[i+1], s3[i+1], s4[i+1]} <= {n5_0, n5_1, n5_2, n5_3, n5_4};
            end

            ascon_round round_inst0(
                .x0(s0[i]), .x1(s1[i]), .x2(s2[i]), .x3(s3[i]), .x4(s4[i]),
                .round_const(ROUND_CONSTS[(11-(i*6))*8 +: 8]),
                .y0(n0_0), .y1(n0_1), .y2(n0_2), .y3(n0_3), .y4(n0_4)
            );

            ascon_round round_inst1(
                .x0(n0_0), .x1(n0_1), .x2(n0_2), .x3(n0_3), .x4(n0_4),
                .round_const(ROUND_CONSTS[(11-(i*6+1))*8 +: 8]),
                .y0(n1_0), .y1(n1_1), .y2(n1_2), .y3(n1_3), .y4(n1_4)
            );

            ascon_round round_inst2(
                .x0(n1_0), .x1(n1_1), .x2(n1_2), .x3(n1_3), .x4(n1_4),
                .round_const(ROUND_CONSTS[(11-(i*6+2))*8 +: 8]),
                .y0(n2_0), .y1(n2_1), .y2(n2_2), .y3(n2_3), .y4(n2_4)
            );

            ascon_round round_inst3(
                .x0(n2_0), .x1(n2_1), .x2(n2_2), .x3(n2_3), .x4(n2_4),
                .round_const(ROUND_CONSTS[(11-(i*6+3))*8 +: 8]),
                .y0(n3_0), .y1(n3_1), .y2(n3_2), .y3(n3_3), .y4(n3_4)
            );

            ascon_round round_inst4(
                .x0(n3_0), .x1(n3_1), .x2(n3_2), .x3(n3_3), .x4(n3_4),
                .round_const(ROUND_CONSTS[(11-(i*6+4))*8 +: 8]),
                .y0(n4_0), .y1(n4_1), .y2(n4_2), .y3(n4_3), .y4(n4_4)
            );

            ascon_round round_inst5(
                .x0(n4_0), .x1(n4_1), .x2(n4_2), .x3(n4_3), .x4(n4_4),
                .round_const(ROUND_CONSTS[(11-(i*6+5))*8 +: 8]),
                .y0(n5_0), .y1(n5_1), .y2(n5_2), .y3(n5_3), .y4(n5_4)
            );
        end
    endgenerate

    assign state_out = {s0[2], s1[2], s2[2], s3[2], s4[2]};
endmodule