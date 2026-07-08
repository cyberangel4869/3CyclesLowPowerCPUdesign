`timescale 1ns / 1ps

`include "ctrl_signal_def.v"
`include "instruction_def.v"

module ControlUnit(
    input rst,            //
    input clk,            //
    input zero,           //
    input [6:0] opcode,   //
    input [6:0] Funct7,   //
    input [2:0] Funct3,   //
    input [4:0] rd,        //译码得到的rd地址
    output reg [4:0] WR,        //RF写入地址
    output reg PCWrite,   //更新PC
    output reg InsMemRW,  //读取IM
    output reg IRWrite,   //指令和对应PC写入IR
    output reg RFWrite,   //写RF
    output reg DMCtrl,    //读写DM
    output reg ExtSel,    //立即数扩展
    output reg ALUSrcA,   //A输入选择
    output reg [1:0] ALUSrcB,//B输入选择
    output reg [1:0] RegSel,
    output reg [1:0] NPCOp,//下一条指令PC选择
    output reg [1:0] WDSel,//选择写回RF的数据
    output reg [3:0] ALUOp//ALU运算模式选择
);

reg [2:0] state,next_state;
reg [2:0] fun3_r;
reg zero_r;
localparam ReadIns = 3'd0;//读指令
localparam IRtypeCaculate = 3'd1;//IR类指令计算和写回，其他指令计算
localparam STOR_WB = 3'd2;//STOR指令写回
localparam LOAD_RMEM = 3'd3;//LOAD指令读内存
localparam LOAD_WB = 3'd4;//LOAD指令写回
localparam JAL_WB = 3'd5;
localparam JALR_WB = 3'd6;
localparam B_JMP = 3'd7;

//主状态机
always @(*) begin
        case (state)
            ReadIns:begin//第一条指令的缓冲阶段
                next_state=IRtypeCaculate;
            end
            IRtypeCaculate:begin//当前指令计算，上条指令写回
                case (opcode)
                    `INSTR_RTYPE_OP:next_state=IRtypeCaculate;
                    `INSTR_ITYPE_OP:next_state=IRtypeCaculate;
                    `INSTR_SW_OP:next_state=STOR_WB; 
                    `INSTR_LW_OP:next_state=LOAD_RMEM;
                    `INSTR_JAL_OP:next_state=JAL_WB;
                    `INSTR_JALR_OP:next_state=JALR_WB;
                    `INSTR_BTYPE_OP:next_state=B_JMP;
                    default:next_state=ReadIns;
                endcase
            end
            STOR_WB:begin//SW指令，
                next_state=ReadIns;//开始下一条指令
            end
            LOAD_RMEM:begin
                next_state=LOAD_WB;
            end
            JAL_WB:begin
                next_state=ReadIns;
            end
            B_JMP:begin
                next_state=ReadIns;
            end
            default:next_state<=ReadIns;
        endcase
end
always @(posedge clk or posedge rst) begin
    if(rst)state<=ReadIns;
    else state<=next_state;
end

//PC更新与IM控制逻辑
always @(*) begin
    case (state)
        ReadIns:begin//第一条指令初始化
            PCWrite=1;
            InsMemRW=1;
            IRWrite=1;
            NPCOp=`NPC_PC;
        end 
        IRtypeCaculate:begin
            case (next_state)
                IRtypeCaculate:begin//连续的IR类计算指令，流水执行
                    PCWrite=1;
                    InsMemRW=1;
                    IRWrite=1;
                    NPCOp=`NPC_PC;
                end
                JAL_WB:begin
                    PCWrite=1;
                    InsMemRW=0;
                    IRWrite=0;
                    NPCOp=`NPC_Offset20;
                end
                JALR_WB:begin
                    PCWrite=1;
                    InsMemRW=0;
                    IRWrite=0;
                    NPCOp=`NPC_rs;
                end
                default:begin//多周期工作模式
                    PCWrite=0;
                    InsMemRW=0;
                    IRWrite=0;
                    NPCOp=`NPC_PC;
                end
            endcase
        end
        B_JMP:begin
            case (fun3_r)
                `INSTR_BEQ_FUNCT:begin
                    if(zero_r)begin//更新NPC
                        PCWrite=1;
                        InsMemRW=0;
                        IRWrite=0;
                        NPCOp=`NPC_Offset12;
                    end
                    else begin//不进入分支，由readins状态控制PC加4
                        PCWrite=0;
                        InsMemRW=0;
                        IRWrite=0;
                        NPCOp=`NPC_PC;
                    end
                end
                `INSTR_BNE_FUNCT: begin
                    if(!zero_r)begin//更新NPC
                        PCWrite=1;
                        InsMemRW=0;
                        IRWrite=0;
                        NPCOp=`NPC_Offset12;
                    end
                    else begin//不进入分支，由readins控制PC加4
                        PCWrite=0;
                        InsMemRW=0;
                        IRWrite=0;
                        NPCOp=`NPC_PC;
                    end
                end
                default: ;
            endcase
        end
        default:begin
            PCWrite=0;
            InsMemRW=0;
            IRWrite=0;
            NPCOp=`NPC_PC;
        end
    endcase
end

//ALU控制逻辑，流入ALU的数据流控制
always @(*) begin
    case (state)
        IRtypeCaculate:begin//I,R类计算指令译码与计算
            case (opcode)
                `INSTR_RTYPE_OP:begin//R-type指令
                    ALUSrcA=`ALUSrcA_rs1;//rs1数据输入A
                    ALUSrcB=`ALUSrcB_B;//rs2数据输入B
                    case ({Funct7,Funct3})//依据指令的func3和func7确定运算种类
                        `INSTR_ADD_FUNCT: ALUOp=`ALUOp_ADD;
                        `INSTR_SUB_FUNCT:ALUOp=`ALUOp_SUB;
                        `INSTR_AND_FUNCT:ALUOp=`ALUOp_AND;
                        `INSTR_OR_FUNCT:ALUOp=`ALUOp_OR;
                        `INSTR_XOR_FUNCT:ALUOp=`ALUOp_XOR;
                        `INSTR_SLL_FUNCT:ALUOp=`ALUOp_SLL;
                        `INSTR_SRL_FUNCT:ALUOp=`ALUOp_SRL;
                        `INSTR_SRA_FUNCT:ALUOp=`ALUOp_SRA;
                        default:ALUOp=0;
                    endcase
                end 
                `INSTR_ITYPE_OP:begin//I-type指令
                    ALUSrcA=`ALUSrcA_rs1;//RS1数据输入A
                    ALUSrcB=`ALUSrcB_Imm;//imm数据输入B
                    case (Funct3)
                        `INSTR_ADDI_FUNCT:ALUOp=`ALUOp_ADD;
                        `INSTR_SLLI_FUNCT:ALUOp=`ALUOp_SLL;
                        `INSTR_SRLI_FUNCT:ALUOp=`ALUOp_SRL;
                        `INSTR_ORI_FUNCT:ALUOp=`ALUOp_OR;
                        `INSTR_XORI_FUNCT:ALUOp=`ALUOp_XOR; 
                        default: ALUOp=0;
                    endcase
                end
                `INSTR_SW_OP:begin//SW
                    ALUSrcA=`ALUSrcA_rs1;
                    ALUSrcB=`ALUSrcB_Imm;
                    ALUOp=`ALUOp_ADD;
                end 
                `INSTR_LW_OP:begin//LW
                    ALUSrcA=`ALUSrcA_rs1;
                    ALUSrcB=`ALUSrcB_Imm;
                    ALUOp=`ALUOp_ADD;
                end
                `INSTR_BTYPE_OP:begin//BEQ,BNE
                    ALUSrcA=`ALUSrcA_rs1;
                    ALUSrcB=`ALUSrcB_B;
                    ALUOp=`ALUOp_BR;
                end
                default:begin
                    ALUSrcA=0;
                    ALUSrcB=0;
                    ALUOp=0;
                end
            endcase
        end 
        default: begin
            ALUSrcA=0;
            ALUSrcB=0;
            ALUOp=0;
        end
    endcase
end

//RF写回控制
always @(*) begin
    case (state)
        ReadIns:begin
            WDSel=`WDSel_FromALU;
            RFWrite=0;
        end
        IRtypeCaculate:begin
            case (next_state)
                IRtypeCaculate:begin//连续的IR类运算指令，流水式写回寄存器
                    WDSel=`WDSel_FromALU;
                    RFWrite=1;
                end 
                default:begin//保证当前指令可以正确写回
                    WDSel=`WDSel_FromALU;
                    RFWrite=1;
                end
            endcase
        end
        STOR_WB:begin
            WDSel=`WDSel_Else;
            RFWrite=0;
        end
        LOAD_RMEM:begin
            WDSel=`WDSel_Else;
            RFWrite=0;
        end
        LOAD_WB:begin
            WDSel=`WDSel_FromMEM;
            RFWrite=1;
        end
        JAL_WB,JALR_WB:begin
            WDSel=`WDSel_FromPC;
            RFWrite=1;
        end
        default: begin
            WDSel=`WDSel_Else;
            RFWrite=0;
        end
    endcase
end

//DR读写控制
always @(*) begin
    case (state)
        STOR_WB:DMCtrl=1;
        default:DMCtrl=0;
    endcase
end

//WR控制
always @(posedge clk or posedge rst) begin
    if(rst)WR<=0;
    else begin
        case (state)
            ReadIns:WR<=0;
            IRtypeCaculate:begin
                case (next_state)
                    IRtypeCaculate,JAL_WB,JALR_WB:WR<=rd; 
                    default: ;
                endcase
            end
            LOAD_RMEM:WR<=rd;//为LW的写回阶段做准备
        endcase
    end
end

//分支指令判断延迟
always @(posedge clk or posedge rst) begin
    if(rst)begin
        fun3_r=0;zero_r=0;
    end
    else begin
        if(next_state==B_JMP)begin//ALU运算完成后保存译码阶段得到的信号
            fun3_r<=Funct3;
            zero_r<=zero;
        end
    end
end

endmodule