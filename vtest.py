import os
import subprocess
import pandas as pd

# 测试目录和模拟器路径
TEST_DIR = "/home/rez/workbench/riscv-vector-tests/out/v512x64machine/bin/stage2/"
EMULATOR = "/home/rez/workbench/prtest/sail-riscv/c_emulator/riscv_sim_RV64"

# 结果列表
results = []

# 遍历 TEST_DIR 下的所有文件
for root, dirs, files in os.walk(TEST_DIR):
    for file in files:
        test_path = os.path.join(root, file)
        print(f"Running {test_path}...")

        # 运行测试并捕获输出
        try:
            result = subprocess.run([EMULATOR, test_path], capture_output=True, text=True, timeout=60)
            last_line = result.stdout.splitlines()[-1] if result.stdout else ""
        except subprocess.TimeoutExpired:
            last_line = "TIMEOUT"

        # 判断测试结果
        if "FAILURE" in last_line:
            status = "FAILED"
        elif "TIMEOUT" in last_line:
            status = "TIMEOUT"
        else:
            status = "SUCCEEDED"

        # 将测试结果保存到列表
        results.append({
            "Test File": test_path,
            "Last Line": last_line,
            "Status": status
        })

# 生成结果表格
df = pd.DataFrame(results)

# 将结果保存为 CSV 文件
df.to_csv("test_results.csv", index=False)

# 打印表格
print(df)
