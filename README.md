# Description
## 關於這個平台

### 平台功用
此平台是基於教授的要求，參考我們設計的VPU形式來做的一個加速器Ports供現階段測試用。<br></br>
改動的部分是將平台改回xc7a100t-1csg324，並將所有vpu相關的instruction移除改成使用CUSTOM-0做的R-type-like擴充指令，操作方式可以參考CFU-Playground平台。<br></br>
此平台不只限定於 NPU，也可以作為其他 custom ML accelerator 的軟硬體協同測試平台。目前範例 accelerator 的 interface 大致上可以分成兩個部分:
1. CPU interface - 這邊的介面走的是CPU內部Pipeline，可以做為傳送指令給 accelerator，也可以作為讀取 accelerator 狀態。(except在我們情況下用不到，直接給0，後期會考慮直接把這個port拔掉)
2. AXI interface - 這邊的介面走的是外部AXI BUS，主要做為資料傳輸使用。由於硬體沒做資料一致性，所以如果 accelerator 從這裡將資料寫入DRAM，記得要對CPU做cache invalidate<br></br>

此平台的參考code(main.cc)和目前 NPU 範例邏輯都是由AI生成的，只做為階段性驗證VPU改 custom accelerator 的過程中沒有導致SoC故障。<br></br>
配套的Software平台現在整理成比較容易擴充的架構，可用於 HW/SW 結合跑 TFLM 的模型推論加速，也能單純測試 custom accelerator 的功能性。<br></br>

關於此平台 accelerator interface 的知識:
1. 如果沒有一定要按造P-ext的ISA規定，其實這個 accelerator interface 的設計就能做到P-ext要做的事，只要使用CPU interface就好。
2. 如果今天實作的 accelerator 是 SA，AXI的部分會推薦使用Burst，能讓資料以最快的速度完成讀寫DRAM
3. 如果今天實作的 accelerator 是類似cache，短時間不會有連續的讀寫，說白了就是可能一次就只傳輸一筆128bit資料，然後不會馬上有下一筆請求，會推薦直接做單筆傳輸不用開Burst
4. 如果今天實作的 accelerator 資料端有data width的要求，例如只能32 bit，而計算資料產出的是128 bit，會推薦開burst
5. 如果今天決定 accelerator 不管怎樣，就只做單筆傳輸，那 accelerator 的 AXI Interface 可以外包出去給AXI Wrapper Layer處理，這樣能夠簡化資料傳輸介面
6. 如之前所述，CPU有實現zicbom(CBO)，所以記得在軟體端要做資料一致性

### 環境設定
此平台的使用設定可以參照main裡面的README.md
目前範例 `NPU.v` 放在 `Platform/hw/srcs` 底下，方便設計，不用去import裡面的一堆文件裡面翻。其他 custom ML accelerator 也可以用同樣位置和 CUSTOM-0 軟體介面整合。
Platform/Reference可以忽略甚至移除，我原本想把乾淨的NPU.v放裡面但好像也沒必要。

### 軟硬體協同方式
可以參考main.cc和目前 NPU/custom accelerator 範例。
客製化指令的方式可以參考CFU Playground的方式，讓客製化指令永遠是cfu_op(rs1,rs2,func)的格式。
main裡面目前的方式也很好但如果有n條客製化 accelerator 指令，就變成要N個指令宣告。

## 軟體需要進一步處理的東西
這裡可以參考CFU_Playground，以下我會列一些點做參考
1. Menu
2. mcycle的包裝(Performance count)
3. 客製化指令的包裝
4. 模型選擇/Input data/Output data/HW test & Verification
5. 優化分文件、檔案放置位置、File tree
6. main.c可以乾淨點
7. CBO包裝

### 目前軟體結構
`Platform/sw` 已依照 CFU-Playground 的方向整理成較小的模組:
1. `main.cc` 只保留主選單、系統資訊和重啟入口。
2. `app/menu.*` 提供 CFU-Playground 風格的 UART menu。
3. `app/perf.*` 包裝 `mcycle/mcycleh` 和簡單量測選單。
4. `app/cfu.*` 將 CUSTOM-0 指令統一成 `cfu_op(rs1, rs2, func)`。
5. `app/cbo.h` 包裝 Zicbom clean/invalidate 和 range helper。
6. `project/accel_ops.h` 和 `project/accel_tests.*` 放 accelerator 語意包裝、functional/stress 測試。
7. `project/user_menu.*` 是新增實驗和 demo 的主要入口。
8. `app/tflm_runner.*` 放 TFLM 模型載入和 cycle 量測。
9. `models/<profile>_profile.cc` 放模型專用的 input fixture / output verification，避免修改 common runner。

模型可以在 build 時指定，例如:
```sh
cd Platform/sw
make config
make validate
make MODEL_FILE=ad01_int8.tflite
make MODEL_FILE=ad01_int8.tflite MODEL_PROFILE=ad01
```
常用設定也可以 copy `project.mk.example` 成 `project.mk` 後固定下來。
更多軟體開發方式可以看 `Platform/sw/README.md`，裡面有 build target、模型/profile 選擇、templates、menu 擴充、CUSTOM-0 helper 和 CBO 使用方式。

## 硬體優化目標
1. 移除FPU
2. 移除FPU遺留邏輯
3. 移除BP遺留邏輯
4. 移除所有CSR，只保留mcycle, mcycleh
5. 建議移除MUL/DIV(實際上應用環境用不到)
6. 移除多餘的VP/pt等邏輯
7. 看榮俊能不能進一步精簡LSU/MMU
