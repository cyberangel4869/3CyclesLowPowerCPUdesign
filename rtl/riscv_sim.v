`timescale 1ns / 1ps

module riscv_sim ();
    // Inputs
    reg clk, rst;

    riscv U_RISCV(
        .clk(clk), 
        .rst(rst)
    );

    initial begin
        // 初始化指令存储器
        $readmemh("../hex/code.hex", U_RISCV.U_IM.memory);
        $display("Instruction memory initialized at time %t", $time);
        
        // 初始化信号
        clk = 0;
        rst = 0;
        
        // 显示仿真开始信息
        $display("=== RISC-V Simulation Start ===");
        $display("Time     PC         Instruction");
        $display("--------------------------------");
        
        // 监控信号
        $monitor("%t PC_r= 0x%8X  out_ins= 0x%8X", $time, U_RISCV.PC_r, U_RISCV.out_ins);
        
        // 生成VCD波形文件（iverilog支持）
        $dumpfile("riscv_sim.vcd");
        $dumpvars(0, riscv_sim);
        
        // 复位时序
        #10 rst = 1;
        #10 rst=0;
        # 50000;
        
        $display("=== Simulation Finished ===");
        $finish;
    end

    // 时钟生成
    always begin
        #25 clk = ~clk;//50000ps一个周期
    end

endmodule