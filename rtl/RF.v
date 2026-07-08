
`include "ctrl_signal_def.v"
`include "global_def.v"


module RF(
    input  [4:0]  RR1,        // 读取寄存器1地址
    input  [4:0]  RR2,        // 读取寄存器2地址
    input  [4:0]  WR,         // 写入寄存器地址
    input  [31:0] WD,         // 写入数据
    input        RFWrite,      // 寄存器写使能信号
    input        clk,          // 时钟信号
    output [31:0] RD1,        // 读取寄存器1数据
    output [31:0] RD2         // 读取寄存器2数据
);

reg [31:0] register [0:31];   // 32个32位寄存器

// 硬编码x0寄存器为0，忽略对x0的写入
always @(clk) begin
    register[0] = 32'h0;
end

always @(posedge clk) begin
    // 当写使能有效且写入地址非0时，执行写入操作
    if ((WR != 0) && (RFWrite == 1)) begin
        register[WR] <= WD;
    end
end


// 组合逻辑读取寄存器数据
assign RD1 = (WR==RR1&&WR!=0)?WD:register[RR1];
assign RD2 = (WR==RR2&&WR!=0)?WD:register[RR2];


`ifdef DEBUG
    always @(*) begin
        // DEBUG模式下打印寄存器组状态
        $display("%t",$time);
        $display("R[00-07]=%8X %8X %8X %8X %8X %8X %8X %8X",
                 register[0], register[1], register[2], register[3],
                 register[4], register[5], register[6], register[7]);
        $display("R[08-15]=%8X %8X %8X %8X %8X %8X %8X %8X",
                 register[8], register[9], register[10], register[11],
                 register[12], register[13], register[14], register[15]);
        $display("R[16-23]=%8X %8X %8X %8X %8X %8X %8X %8X",
                 register[16], register[17], register[18], register[19],
                 register[20], register[21], register[22], register[23]);
        $display("R[24-31]=%8X %8X %8X %8X %8X %8X %8X %8X",
                 register[24], register[25], register[26], register[27],
                 register[28], register[29], register[30], register[31]);
    end
`endif

endmodule