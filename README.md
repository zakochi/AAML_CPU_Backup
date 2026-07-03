# Description
## 關於這個平台

### 平台功用
此平台是基於教授的要求，參考我們設計的VPU形式來做的一個加速器Ports供現階段測試用。<br></br>
改動的部分是將平台改回xc7a100t-1csg324，並將所有vpu相關的instruction移除改成使用CUSTOM-0做的R-type-like擴充指令，操作方式可以參考CFU-Playground平台。<br></br>
此NPU的interface目前處於一個比較複雜的狀態，大致上可以分成兩個部分:
1. CPU interface - 這邊的介面走的是CPU內部Pipeline，可以做為傳送指令給NPU，也可以作為讀取NPU狀態。(except在我們情況下用不到，直接給0，後期會考慮直接把這個port拔掉)
2. AXI interface - 這邊的介面走的是外部AXI BUS，主要做為資料傳輸使用。由於硬體沒做資料一致性，所以如果NPU從這裡將資料寫入DRAM，記得要對CPU做cache invalidate<br></br>

此平台的參考code(main.cc)和NPU內部邏輯都是由AI生成的，只做為階段性驗證VPU改NPU的過程中沒有導致SoC故障。<br></br>
配套的Software平台還沒有很完善，需要做一些工作才能做到HW/SW結合跑TFLM的模型推論加速，但如果只是要單純測試NPU的功能性完全沒問題。<br></br>

關於此平台NPU的知識:
1. 如果沒有一定要按造P-ext的ISA規定，其實這個NPU Interface的設計就能做到P-ext要做的事，只要使用CPU interface就好。
2. 如果今天實作的NPU是SA，AXI的部分會推薦使用Burst，能讓資料以最快的速度完成讀寫DRAM
3. 如果今天實作的NPU是類似cache，短時間不會有連續的讀寫，說白了就是可能一次就只傳輸一筆128bit資料，然後不會馬上有下一筆請求，會推薦直接做單筆傳輸不用開Burst
4. 如果今天實作的NPU資料端有data width的要求，例如只能32 bit，而計算資料產出的是128 bit，會推薦開burst
5. 如果今天決定NPU不管怎樣，就只做單筆傳輸，那NPU的AXI Interface可以外包出去給AXI Wrapper Layer處理，這樣能夠簡化NPU的資料傳輸介面
6. 如之前所述，CPU有實現zicbom(CBO)，所以記得在軟體端要做資料一致性

### 環境設定
此平台的使用設定可以參照main裡面的README.md
我有將NPU.v放到Platform/hw/srcs底下，方便設計，不用去import裡面的一堆文件裡面翻。
Platform/Reference可以忽略甚至移除，我原本想把乾淨的NPU.v放裡面但好像也沒必要。

### 軟硬體協同方式
可以參考main.cc和NPU裡面的範例。
客製化指令的方式可以參考CFU Playground的方式，讓客製化指令永遠是cfu_op(rs1,rs2,func)的格式。
main裡面目前的方式也很好但如果有n條客製化NPU指令，就變成要N個指令宣告。

## 軟體需要近一步處理的東西
這裡可以參考CFU_Playground，以下我會列一些點做參考
1. Menu
2. mcycle的包裝(Performance count)
3. 客製化指令的包裝
4. 模型選擇/Input data/Output data/HW test & Verification
5. 優化分文件、檔案放置位置、File tree
6. main.c可以乾淨點
7. CBO包裝

