# 說明
1. 優化了boot flow，改用jtag boot
2. 此版本為arty a7專用，Nexys a7跑不了，你們把你們的code直接替換掉import裡面的，但注意看一下第6.
3. 如果CPU 70MHz下還是沒辦法收斂，可以調整看看ui_clk(我目前測了2個最好的是3077ps)
4. 如果你們能跑在75MHz，並且你們隨便改NPU.v裡面的邏輯基本上都不會炸，那建議回歸老套路讓cpu去接mig ui_clk的75MHz
5. sw裡面只有一個upload.py，那是我最新為了配合jtag boot的全新版本。其他的你們透過cp的方式把你們要測試的tflm環境搬進去測試
6. 為了配合DDR3的環境，SoC.v用我這一份，只要你們沒打算在.bd裡面新增新的IO port都沒不用去改。
7. 記得也把tflm-micro cp一下
8. arty a7和nexys a7有個不一樣的地方，就是arty a7不用按reset button就會自動boot了，我也不知道為啥。
