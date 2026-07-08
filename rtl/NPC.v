`include "ctrl_signal_def.v"
`include "instruction_def.v"

module NPC(
    input  [1:0]   NPCOp,      // 控制信号
    input  [11:0]  Offset12,   // 比较指令的跳转偏移量
    input  [19:0]  Offset20,   // 跳转指令的跳转偏移量
    input  [31:0]  PC,         // 本条指令的地址
    input  [31:0]  rs,         // 跳转到子程序的地址
    output reg [31:0] PCA4,    // PC+4
    output reg [31:0] NPC      // 下一条指令的地址
);

always@(*) begin
    case(NPCOp)
        `NPC_PC:        NPC = PC + 4;                    // 顺序执行
        // BEQ,BNE指令跳转，需要在立即数末位补零对齐，符号位扩展
        `NPC_Offset12:  NPC = PC + {{19{Offset12[11]}},Offset12, 1'b0}-3'd4;  
        // JALR指令跳转，立即数符号位扩展，不需要低位对齐
        `NPC_rs:        NPC = rs + {{20{Offset12[11]}},Offset12};
        // JAL指令跳转，立即数末位补零对齐，符号位扩展
        `NPC_Offset20:  NPC = PC + {{11{Offset20[19]}},Offset20,1'b0}-3'd4;
        //JAL指令译码计算时，PC已经被加4，需要扣除
    endcase
    PCA4 = PC + 4;  // 始终计算PC+4，用于链接寄存器保存返回地址
end

endmodule