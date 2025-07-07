module alu (
  input logic [31:0] a,
  input logic [31:0] b,
  input logic [3:0] opcode,
  output logic [31:0] result,
  output logic zero_flag,
  output logic sign_flag,
  output logic carry_flag,
  output logic overflow_flag
);
  // zero flag: set if result is zero
  // sign flag: set if result is negative (most significant bit is 1)
  // carry flag: set if there is a carry out from the most significant bit
  // overflow flag: set if there is an overflow in addition or subtraction
    
  localparam OP_ADD = 4'b0000;
  localparam OP_SUB = 4'b0001;
  localparam OP_AND = 4'b0010;
  localparam OP_OR  = 4'b0011;
  localparam OP_XOR = 4'b0100;
  localparam OP_SLT = 4'b0101;
  localparam OP_SLL = 4'b0110;
  localparam OP_SRL = 4'b0111;
  localparam OP_SRA = 4'b1000;

  assign zero_flag = (result == 32'b0);
  assign sign_flag = result[31];
  
  always_comb begin
    overflow_flag = 1'b0;
    carry_flag = 1'b0;

    case (opcode)
        OP_ADD: begin
            { carry_flag, result } = { 1'b0, a } + { 1'b0, b };
            overflow_flag = (a[31] == b[31]) && (result[31] != a[31]);
        end
        OP_SUB: begin
            { carry_flag, result } = { 1'b0, a } - { 1'b0, b };
            overflow_flag = (a[31] != b[31]) && (result[31] != a[31]);
        end
        OP_AND: begin
            result = a & b;
        end
        OP_OR: begin
            result = a | b;
        end
        OP_XOR: begin
            result = a ^ b;
        end
        OP_SLT: begin
            // set less than
            result = (a < b) ? 32'b1 : 32'b0;
        end
        OP_SLL: begin
            // shift left logical
            carry_flag = (b[4:0] > 0) ? a[31] : 1'b0;
            result = a << b[4:0];
        end
        OP_SRL: begin
            // shift right logical
            result = a >> b[4:0];
        end
        OP_SRA: begin
            // shift right arithmetic
            result = $signed(a) >>> b[4:0];
        end
        default: begin
            result = 32'bx; // undefined operation
            carry_flag = 1'b0;
            overflow_flag = 1'b0;
        end
    endcase
  end
  
endmodule