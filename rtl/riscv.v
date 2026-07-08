`timescale 1ns / 1ps
////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/11/22 13:30:25
// Design Name:
// Module Name: riscv
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision: 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////
`include "instruction_def.v"

module riscv(clk, rst);
    input clk, rst;

    //控制信号
    wire RFWrite, DMCtrl, PCWrite, IRWrite, InsMemRW, ExtSel, ALUSrcA, zero;
    wire [1:0] ALUSrcB;
    wire [1:0] NPCOp, WDSel, RegSel;
    wire [3:0] ALUOp;
    wire [31:0] in_ins,out_ins;
    
    //PC数据流
    wire [31:0] PC, NPC, PCA4,PC_r,NPC_r;

    //指令译码
    wire [2:0] Funct3;
    wire [6:0] opcode;
    wire [6:0] Funct7;
    wire [4:0] rs1, rs2, rd;
    assign opcode   = out_ins[6:0];
    assign Funct3   = out_ins[14:12];
    assign Funct7   = out_ins[31:25];
    assign rs1      = out_ins[19:15];
    assign rs2      = out_ins[24:20];
    assign rd       = out_ins[11:7];

    //立即数译码
    wire [11:0] Imm12;
    wire [31:0] Imm32;
    wire [11:0] Offset12;
    wire [19:0] Offset20;
    // Itype,Stype立即数 (12位)
    assign Imm12 = (opcode==`INSTR_SW_OP)?
    {out_ins[31:25],out_ins[11:7]}://Stype立即数合成
    out_ins[31:20];//Itype立即数合成
    //BEQ,BNE的S-Btype和JALR的Itype立即数
    assign Offset12 = (opcode==`INSTR_JALR_OP)?
    Imm12://JALR也是Itype指令
    {out_ins[31],out_ins[7],out_ins[30:25],out_ins[11:8]};
    //BEQ,BNE是S-Btype立即数，末位没有补零
    
    //JAL的20位UJtype立即数，最低位没有补零
    assign Offset20 = {out_ins[31],out_ins[19:12],out_ins[20],out_ins[30:21]};

    //RF数据流
    wire [4:0] WR;//RF写入地址
    wire [31:0] RD1, RD2;//RF读出数据
    wire [31:0] WD;//RF写入数据

    //ALU数据流
    wire [31:0] ALU_A, ALU_B, ALU_result;

    //DM数据流
    wire [31:0] ALU_result_r;//读写地址
    wire [31:0] STOR_data_r;//写入数据
    wire [31:0] LOAD_data;//读出数据

    

    //======================================================IF阶段==================================================================
    PC U_PC (
        .clk(clk), .rst(rst), .PCWrite(PCWrite), .NPC(NPC), .PC(PC)
    );

    NPC U_NPC (
        .PC(PC), .NPCOp(NPCOp), .Offset12(Offset12), .Offset20(Offset20), .rs(RD1), .PCA4(PCA4), .NPC(NPC)
    );

    IM U_IM (//32位IM，四字节对齐，PC低位是00
        .addr(PC[11:2]), .Ins(in_ins), .InsMemRW(InsMemRW)
    );
    //================================================================================================================================
    //指令寄存器
    IR U_IR (
        .clk(clk), .IRWrite(IRWrite), .in_ins(in_ins), .out_ins(out_ins)
    );
    //PC寄存器
    IR U_PC_REG(
        .clk(clk), .IRWrite(IRWrite), .in_ins(PC), .out_ins(PC_r)
    );

    // 全局控制
    ControlUnit U_ControlUnit(
        .clk(clk), .rst(rst), .zero(zero), .opcode(opcode), .Funct7(Funct7), .Funct3(Funct3),
        .RFWrite(RFWrite), .DMCtrl(DMCtrl), .PCWrite(PCWrite), .IRWrite(IRWrite), .InsMemRW(InsMemRW),
        .ExtSel(ExtSel), .ALUOp(ALUOp), .NPCOp(NPCOp), .ALUSrcA(ALUSrcA),
        .WDSel(WDSel), .ALUSrcB(ALUSrcB), .RegSel(RegSel), .rd(rd), .WR(WR)
    );
    
    // 实例化 RF
    RF U_RF (
        .RR1(rs1), .RR2(rs2), .WR(WR), .WD(WD), .clk(clk),
        .RFWrite(RFWrite), .RD1(RD1), .RD2(RD2)
    );
    //==================================================数据选择与运算阶段===================================================================
    //Itype指令12位立即数扩展
    EXT U_EXT (
        .imm_in(Imm12), .imm_out(Imm32), .ExtSel(`ExtSel_SIGNED)
    );

    //data1与PC选择
    /*
    RD1---|0\
          |  |---ALU_A   
    PC----|1/
    */
    MUX_2to1_A U_MUX_A(
        .X(RD1), .Y(PC), .control(ALUSrcA), .out(ALU_A)
    );

    //data2与imm32选择
    /*
    RD2---|00\
    Imm---|01 |
          |   |---ALU_B
    0-----|10 |
    RD2---|11/
    */
    MUX_3to1_B U_MUX_B(
        .X(RD2), .Y(Imm32), .Z(12'b0), .control(ALUSrcB), .out(ALU_B)
    );

    //ALU
    /*
    ALU_A---| \
             \ |---ALU_result
             / |---zero
    ALU_B---| /
    */
    ALU U_ALU(
        .A(ALU_A), .B(ALU_B),
        .ALUOp(ALUOp),
        .zero(zero), .ALU_result(ALU_result)
    );

    //=======================================读写内存和写回阶段=================================================
    //数据寄存器
    Flopr ALU_result_REG(
        .clk(clk), .rst(rst),
        .in_data(ALU_result), .out_data(ALU_result_r)
    );
    Flopr STOR_data_REG(
        .clk(clk), .rst(rst),
        .in_data(RD2), .out_data(STOR_data_r)
    );
    Flopr NPC_REG(
        .clk(clk), .rst(rst),
        .in_data(PC_r), .out_data(NPC_r)
    );

    //内存
    DM U_DM(
        .Addr(ALU_result_r[11:2]), .clk(clk),
        .DMCtrl(DMCtrl),
        .WD(STOR_data_r),
        .RD(LOAD_data)
    );

    //写回数据选择器
    MUX_3to1_LMD U_MUX_WB(
        .X(ALU_result_r), .Y(LOAD_data), .Z(NPC_r[31:2]),
        .control(WDSel),
        .out(WD)
    );
    
    //
endmodule