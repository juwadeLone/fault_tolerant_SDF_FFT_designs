# 如何推到 GitHub（Private 亦可）

本地包路径：`/home/xdu/JuWade_research/tcas_public`

```bash
cd /home/xdu/JuWade_research/tcas_public
git init -b main
git add -A
git status   # 确认无 .xpr / fi_func_sim / K_*
git commit -m "Initial public RTL artifact: seven SDF FFT designs + schematics"
git remote add origin git@github.com:JUWADE/fault_tolerant_SDF_FFT_designs.git
git push -u origin main
```

若远程已有内容，改用：

```bash
git pull --rebase origin main
git push
```

投稿前把仓库改为 **Public**，与论文 *publicly available* 表述一致。
