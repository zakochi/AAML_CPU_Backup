`timescale 1ns / 1ps

module tb_Frontend_top();

    // 系統訊號
    reg clk;
    reg rst_n;

    // 分支/跳轉 (Redirect)
    reg        redirect_valid_i;
    reg [31:0] redirect_pc_i;

    // Fence.i
    reg        invalidate_i;
    wire       invalid_complete;

    // ID Stage 模擬 (Backend)
    reg        req_inst_i;
    wire       inst_rdy_o;
    wire [31:0] inst_pc_o;
    wire [31:0] inst_o;

    // 外部記憶體 模擬 (AXI/AHB mock)
    reg         rm_rdy;
    reg         rm_success;
    reg         rm_complete;
    reg [255:0] rm_data;
    wire        req_rm;
    wire [31:0] rm_addr;

    // 例化待測物 (DUT)
    Frontend_top DUT (
        .clk              (clk),
        .rst_n            (rst_n),
        .redirect_valid_i (redirect_valid_i),
        .redirect_pc_i    (redirect_pc_i),
        .invalidate_i     (invalidate_i),
        .invalid_complete (invalid_complete),
        .req_inst_i       (req_inst_i),
        .inst_rdy_o       (inst_rdy_o),
        .inst_pc_o        (inst_pc_o),
        .inst_o           (inst_o),
        .rm_rdy           (rm_rdy),
        .rm_success       (rm_success),
        .rm_complete      (rm_complete),
        .rm_data          (rm_data),
        .req_rm           (req_rm),
        .rm_addr          (rm_addr)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // Backend (ID Stage) 模擬不斷 Pop Queue
    always @(posedge clk) begin
        if (!rst_n) 
            req_inst_i <= 0;
        else 
            // 只要 Queue 裡面有東西，就立刻 Pop
            req_inst_i <= inst_rdy_o; 
    end

    // External Memory (Mock Cache Miss Behavior)
    always @(posedge clk) begin
        if (!rst_n) begin
            rm_rdy <= 1;
            rm_complete <= 0;
            rm_success <= 0;
            rm_data <= 0;
        end else begin
            if (req_rm) begin
                rm_rdy <= 0; // 模擬記憶體忙碌
                // 延遲 3 個 Cycle 後回傳假資料
                repeat(3) @(posedge clk);
                rm_complete <= 1;
                rm_success <= 1;
                rm_data <= {8{32'hDEADBEEF}}; // 塞滿 Cacheline
                
                @(posedge clk);
                rm_complete <= 0;
                rm_success <= 0;
                rm_rdy <= 1; // 恢復 Ready
            end
        end
    end

    // Test Sequence
    initial begin
        // 初始狀態
        clk = 0;
        rst_n = 0;
        redirect_valid_i = 0;
        redirect_pc_i = 0;
        invalidate_i = 0;

        // 解除 Reset
        #15 rst_n = 1;
        
        $display("=== [TEST 1] 連續 Fetch (觸發 Cache Miss 後 Hit) ===");
        // 觀察前幾個 Cycle 的波形，一開始必定觸發 Miss (req_rm 變為 1)
        // 隨後外部記憶體響應後，Frontend 會開始連續送出指令
        #100;
        
        $display("=== [TEST 2] 觸發 Branch (測試 Flush Pending 遮罩) ===");
        // 模擬 EX Stage 發生跳轉
        @(posedge clk);
        redirect_valid_i = 1;
        redirect_pc_i = 32'h6000_0100; // 跳轉到一個新位址
        @(posedge clk);
        redirect_valid_i = 0;

        // 觀察 Queue 是否被清空，且新的 PC 是否正確更新為 6000_0100
        #150;

        $display("=== [TEST 3] 測試 Invalidate (Fence.i) ===");
        @(posedge clk);
        invalidate_i = 1;
        
        // 等待 invalidate 完成
        wait(invalid_complete == 1);
        @(posedge clk);
        invalidate_i = 0;

        #100;
        $display("=== 測試結束 ===");
        $finish;
    end

    // 波形檔輸出 (相容 Vivado 或 Verilator)
    initial begin
        $dumpfile("frontend_wave.vcd");
        $dumpvars(0, tb_Frontend_top);
    end

endmodule