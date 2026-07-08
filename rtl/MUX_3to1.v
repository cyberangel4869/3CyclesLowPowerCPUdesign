`include "ctrl_signal_def.v"


module MUX_3to1(
    input  [4:0]  X,        // rd寄存器地址
    input  [4:0]  Y,        // 预留输入（rt寄存器地址）
    input  [4:0]  Z,        // 预留输入（31号寄存器地址）
    input  [1:0]  control,  // 选择控制信号
    output reg [4:0] out    // 输出选择结果
);

    always @(X or Y or Z or control) begin
        case(control)
            `RegSel_rd  : out = X;  // 选择X（rd寄存器）
            `RegSel_rt  : out = Y;  // 选择Y（rt寄存器）
            `RegSel_31  : out = Z;  // 选择Z（31号寄存器）
            `RegSel_else: out = 0;  // 默认情况输出0
        endcase
    end

endmodule