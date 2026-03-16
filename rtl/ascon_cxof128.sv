module ascon_cxof (
    input logic clk,
    input logic reset,
    input logic [103:0] tuple_in, //IPv4 MAC Header + IP Payload
    input logic start,

    output logic [63:0] digest,
    output logic done
);

    //localparam logic [63:0] ASCON_HASH_IV = 64'h00400c0000000100;
    localparam logic [319:0] INIT_PRECOMPUTE = 320'hb57e273b814cd4162b51042562ae242066a3a7768ddf22185aad0a7a8153650c4f3e0e32539493b6;
    //320'hee9398aadb67f03d8bb21831c60f1002b48a92db98d5da6243189921b8f8e3e8348fa5c9d525e140; <- This is for ACSON-HASH
    localparam ROUND_DELAY = 2;

    typedef enum logic [2:0] { //1-Hot
        IDLE    = 3'b001,
        ABSORB  = 3'b010,
        SQUEEZE = 3'b100
    } state_t;
    
    state_t state;

    logic [319:0] state_reg;
    logic [319:0] perm_in, perm_out;
    logic [2:0] delay_cnt;
    logic [2:0] round_cnt;
    
    logic [63:0] block [0:3]
    assign block[0] = 64'd64;
    assign block[1] = 64'h734abc2033060120; //Secret Key
    assign block[2] = tuple_in[103:40];
    assign block[3] = {tuple_in[39:0], 1'b1, 23'h0};

    
    ascon_permute ascon_core (
        .clk(clk),
        .reset(reset),
        .state_in(perm_in),
        .state_out(perm_out)
    );

   always_ff @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            state_reg <= INIT_PRECOMPUTE;
            delay_cnt <= 0;
            round_cnt <= 0;
            digest <= 64'h0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= ABSORB;
                        delay_cnt <= 0;
                    end
                end

                ABSORB: begin
                    done <= 1'b0;
                    if (delay_cnt == ROUND_DELAY) begin
                        state_reg <= perm_out;
                        delay_cnt <= 0;

                        if (round_cnt == 3) begin
                            state <= SQUEEZE;
                            round_cnt <= 0;
                        end else begin
                            round_cnt <= round_cnt + 1;
                        end
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                SQUEEZE: begin
                    if (delay_cnt == ROUND_DELAY) begin
                        digest <= perm_out[319:256];
                        done <= 1'b1;                  
                        if (start) begin
                            state <= ABSORB;
                            delay_cnt <= 0;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    always_comb begin
        if  (state == IDLE ||
            (state == ABSORB_1 && delay_cnt < ROUND_DELAY) ||
            (state == SQUEEZE && delay_cnt == ROUND_DELAY && start == 1)) begin
            perm_in = INIT_PRECOMPUTE ^ {block[0], 256'b0};
        end else if (state == ABSORB && delay_cnt == ROUND_DELAY) begin
            perm_in = perm_out ^ {block[round_cnt], 256'b0};
        end else begin
            perm_in = state_reg ^ {block[0], 256'b0};
        end
    end

    // assign done   = (state == SQUEEZE && delay_cnt == ROUND_DELAY);
    // assign digest = (state == SQUEEZE && delay_cnt == ROUND_DELAY) ? perm_out[319:256] : 64'h0;

endmodule