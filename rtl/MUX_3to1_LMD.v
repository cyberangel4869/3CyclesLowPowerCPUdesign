`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/11/25 09:52:17
// Design Name:
// Module Name: MUX_3to1_LMD
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "ctrl_signal_def.v"

module MUX_3to1_LMD(
    input  [31:0]  X,        //临时寄存器ALU0中的内容
    input  [31:0]  Y,        //临时寄存器LMD中的内容
    input  [31:2]  Z,        //PC
    input  [1:0]   control,  //选择控制信号
    output reg [31:0] out    //输出选择结果
);

    always @(X or Y or Z or control) begin
        case(control)
            `WDSel_FromALU : out = X;  //选择ALU计算结果
            `WDSel_FromMEM : out = Y;  //选择数据存储器读出数据
            `WDSel_FromPC  : out = {Z, 2'b00}+4;  //选择PC+4，补位对齐32位
            `WDSel_Else    : out = 0;   //默认情况输出0
        endcase
    end

endmodule