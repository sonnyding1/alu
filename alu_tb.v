module alu_tb;

    logic [31:0] a, b, result;
    logic [3:0] opcode;
    logic zero_flag, sign_flag, carry_flag, overflow_flag;

    alu dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag)
    );

    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_SLT = 4'b0101;
    localparam OP_SLL = 4'b0110;
    localparam OP_SRL = 4'b0111;
    localparam OP_SRA = 4'b1000;

    logic [31:0] expected_result;
    logic expected_zero_flag, expected_sign_flag, expected_carry_flag, expected_overflow_flag;

    integer errors = 0;
    integer test_num = 0;

    task apply_and_check;
        input [31:0] in_a, in_b;
        input [3:0] in_op;
        input string comment;
        begin
            test_num++;
            a = in_a;
            b = in_b;
            opcode = in_op;

            #1;

            $alu_predict_vpi(a, b, opcode, expected_result, expected_zero_flag, expected_sign_flag, expected_carry_flag, expected_overflow_flag);

            $display("------------------------------------------------------------------------------------------");
            $display("Test #%0d: %s", test_num, comment);
            $display("Time: %0t, A: %h (%d), B: %h (%d), Opcode: %b", $time, a, signed'(a), b, signed'(b), opcode);
            $display("DUT    -> Result: %h (%d), Zero: %b, Sign: %b, Carry: %b, Overflow: %b",
             result, signed'(result), zero_flag, sign_flag, carry_flag, overflow_flag);
            $display("EXPECT -> Result: %h (%d), Zero: %b, Sign: %b, Carry: %b, Overflow: %b",
             expected_result, signed'(expected_result), expected_zero_flag, expected_sign_flag, expected_carry_flag, expected_overflow_flag);

            if (result !== expected_result) begin
                $error("MISMATCH! Result: DUT=%h, Expected=%h", result, expected_result);
                errors++;
            end
            if (zero_flag !== expected_zero_flag) begin
                $error("MISMATCH! Zero Flag: DUT=%b, Expected=%b", zero_flag, expected_zero_flag);
                errors++;
            end
            if (sign_flag !== expected_sign_flag) begin
                $error("MISMATCH! Sign Flag: DUT=%b, Expected=%b", sign_flag, expected_sign_flag);
                errors++;
            end
            if (carry_flag !== expected_carry_flag) begin
                $error("MISMATCH! Carry Flag: DUT=%b, Expected=%b", carry_flag, expected_carry_flag);
                errors++;
            end
            if (overflow_flag !== expected_overflow_flag) begin
                $error("MISMATCH! Overflow Flag: DUT=%b, Expected=%b", overflow_flag, expected_overflow_flag);
                errors++;
            end
        end
    endtask

    initial begin
        // add
        apply_and_check(32'd10, 32'd20, OP_ADD, "ADD: 10 + 20");
        apply_and_check(32'hFFFFFFFF, 32'd1, OP_ADD, "ADD: -1 + 1 (0xFFFFFFFF + 1)");
        apply_and_check(32'd1, 32'h7FFFFFFF, OP_ADD, "ADD: 1 + 2147483647 (overflow)");
        // sub
        apply_and_check(32'd20, 32'd10, OP_SUB, "SUB: 20 - 10");
        apply_and_check(32'd10, 32'd20, OP_SUB, "SUB: 10 - 20");
        apply_and_check(32'hFFFFFFFE, 32'h7FFFFFFF, OP_SUB, "SUB: -2 - 2147483647 (overflow)");
        // and
        apply_and_check(32'hF0F0F0F0, 32'h0F0F0F0F, OP_AND, "AND: 0xF0F0F0F0 & 0x0F0F0F0F");
        // or
        apply_and_check(32'hF0F0F0F0, 32'h0F0F0F0F, OP_OR, "OR: 0xF0F0F0F0 | 0x0F0F0F0F");
        // xor
        apply_and_check(32'hF0F0F0F0, 32'h0F0F0F0F, OP_XOR, "XOR: 0xF0F0F0F0 ^ 0x0F0F0F0F");
        apply_and_check(32'b1010, 32'b0011, OP_XOR, "XOR: 1010 ^ 0011");
        // slt
        apply_and_check(32'd10, 32'd20, OP_SLT, "SLT: 10 < 20");
        apply_and_check(32'd20, 32'd10, OP_SLT, "SLT: 20 < 10");
        apply_and_check(32'd10, 32'd10, OP_SLT, "SLT: 10 < 10 (equal)");
        apply_and_check(32'hFFFFFFFE, 32'hFFFFFFFF, OP_SLT, "SLT: -2 < -1");
        apply_and_check(32'hFFFFFFFF, 32'd1, OP_SLT, "SLT: -1 < 1");
        // sll
        apply_and_check(32'd1, 32'd2, OP_SLL, "SLL: 1 << 2");
        apply_and_check(32'd1, 32'd31, OP_SLL, "SLL: 1 << 31");
        apply_and_check(32'h80000000, 32'd1, OP_SLL, "SLL: 0x80000000 << 1");
        // srl
        apply_and_check(32'd4, 32'd1, OP_SRL, "SRL: 4 >> 1");
        apply_and_check(32'd4, 32'd2, OP_SRL, "SRL: 4 >> 2");
        apply_and_check(32'h80000000, 32'd1, OP_SRL, "SRL: 0x80000000 >> 1");
        apply_and_check(32'hFFFF0000, 32'd2, OP_SRL, "SRL: 0xFFFF0000 >> 2");
        // sra
        apply_and_check(32'd4, 32'd1, OP_SRA, "SRA: 4 >>> 1");
        apply_and_check(32'd4, 32'd2, OP_SRA, "SRA: 4 >>> 2");
        apply_and_check(32'h80000000, 32'd1, OP_SRA, "SRA: 0x80000000 >>> 1");
        apply_and_check(32'hFFFF0000, 32'd2, OP_SRA, "SRA: 0xFFFF0000 >>> 2");

        #20;
        if (errors == 0) begin
        $display("***********************************");
        $display("******   ALL TESTS PASSED!   ******");
        $display("***********************************");
        end else begin
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("!!!!!!  %0d ERRORS DETECTED  !!!!!!", errors);
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        end
        $finish;
    end

endmodule