`include "ctrl_signal_def.v"
`define DEBUG 1


module DM(
    input  [11:2]  Addr,    //读写对应的地址
    input  [31:0]  WD,      //写入的数据
    input          clk,     //时钟信号
    input          DMCtrl,  //高电平写入，低电平读取
    output reg [31:0] RD    //读出的数据
);

    reg [31:0] memory[0:1023];

    always @(posedge clk) begin  //信号上升沿
        if (DMCtrl) begin
            memory[Addr] <= WD;  //写入数据
        end
        else begin
            RD <= memory[Addr];  //读出数据
        end
    end

`ifdef DEBUG
        always @(*) begin
            if(DMCtrl)
            $display("%t: mem[%h]<=%h",$time,Addr,memory[Addr]);
        end 
`endif
endmodule