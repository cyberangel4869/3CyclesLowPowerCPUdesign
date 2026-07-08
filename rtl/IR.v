`include "ctrl_signal_def.v"


// 指令寄存器(IR)模块：用于在CPU流水线中锁存当前指令
module IR(
    input  [31:0] in_ins,     // 输入指令（来自指令存储器）
    input         clk,        // 时钟信号
    input         IRWrite,    // 写使能信号（高电平允许写入）
    output reg [31:0] out_ins // 输出指令（传递给译码/执行单元）
);

    // 时钟上升沿触发写操作
    always @(posedge clk) begin
        if (IRWrite) begin
            out_ins <= in_ins;  // 写使能有效时，锁存输入指令
        end
    end

endmodule