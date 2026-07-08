`include "ctrl_signal_def.v"
`include "instruction_def.v"

module ALU(A, B, ALUOp, zero, ALU_result);
    input signed [31:0] A;
    input signed [31:0] B;
    input [3:0] ALUOp;
    output zero;
    output reg signed [31:0] ALU_result;
    
    assign zero = (ALU_result == 32'b0);
    
    always @(*) begin
        case (ALUOp)
            `ALUOp_ADD: ALU_result = A + B;
            `ALUOp_SUB: ALU_result = A - B;
            `ALUOp_AND: ALU_result = A & B;
            `ALUOp_OR:  ALU_result = A | B;
            `ALUOp_XOR: ALU_result = A ^ B;
            `ALUOp_SRA: ALU_result = $signed(A) >>> B[4:0];
            `ALUOp_SLL: ALU_result = A << B[4:0];
            `ALUOp_SRL: ALU_result = A >> B[4:0];
            `ALUOp_BR:  ALU_result = A - B;//分支指令用减法做比较，A==B则Zero=1
            default:    ALU_result = 32'b0;
        endcase
    end
    
endmodule