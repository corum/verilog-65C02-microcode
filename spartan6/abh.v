/*
 * abh -- calculates next value of ABH (Address Bus High)
 *
 * (C) Arlet Ottens <arlet@c-scape.nl> 
 */
module abh( 
    input clk,
    input CI,               // carry input from ABL module
    input [7:0] DB,         // Data Bus
    input [3:0] op,         // operation
    input ld_pc,            // load PC 
    input inc_pc,           // increment PC
    output [7:0] PCH,       // Program Counter high
    output [7:0] ADH        // unregistered version of ABH
);

wire [7:0] ABH;
wire [7:0] ADD0;
wire [7:0] ADD1;
wire [7:0] PCH1;

/*   
 * op  |  function
 * ==================== 
 * 0?? |  00  + 00 + CI
 * 100 |  ABH + 00 + CI
 * 101 |  ABH + FF + CI
 * 110 |  PCH + 00 + CI 
 * 111 |  DB  + 00 + CI
 */ 

add8_3 #(.INIT(64'hccf055aa0000aa00)) adh_add0(
    .I0(ABH),
    .I1(DB),
    .I2(PCH),
    .op({1'b1,op[1:0]}),
    .CI(0),
    .O(ADD0) );

add8_3 #(.INIT(64'hccf055aa0000aa00)) adh_add1(
    .I0(ABH),
    .I1(DB),
    .I2(PCH),
    .op({1'b1,op[1:0]}),
    .CI(1),
    .O(ADD1) );

always @(*)
    case( op[3:2] )
        2'b00:      ADH = 8'h00;
        2'b01:      ADH = 8'h01;
        2'b10:      ADH = CI ? ADD1 : ADD0; 
        2'b11:      ADH = 8'hff;
    endcase

/* 
 * ABH register
 *
 * ABH <= ADH
 */ 
reg8 abh( 
    .clk(clk),
    .EN(1),
    .RST(0),
    .D(ADH),
    .Q(ABH) );

/*
 * update PCH (program counter high)
 * 
 * if( ld_pc )
 *     PCH <= ABH + inc_pc
 */
add8_3 #(.INIT(64'haaaaaaaa00000000)) pch_inc(
    .CI(inc_pc),
    .I0(ABH),
    .I1(0),
    .I2(0),
    .op(3'b100),
    .O(PCH1) );

/* 
 * PCL register
 */
reg8 pch( 
    .clk(clk),
    .EN(ld_pc),
    .RST(0),
    .D(PCH1),
    .Q(PCH) );

endmodule