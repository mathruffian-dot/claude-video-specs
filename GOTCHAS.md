# GOTCHAS — 踩坑筆記

> 實戰中累積的坑，**開工前先讀一遍**。多數是跨 agent 通則，少數標注特定環境。
> 來源：在 OpenCode / Claude Code / Windows 上實際跑這套流程踩到的。

圖例：🌍 所有 agent 通則 ｜ 🪟 Windows 專屬 ｜ 🔧 特定工具

---

## A. 流程（最重要，先看）

### A-1 🌍 未先寫腳本對齊就開工
**症狀**：直接寫 HTML / 生圖，做到一半發現結構不對、重做。
**解法**：**一定先產出腳本（旁白 + 字卡 + 分鏡）給使用者確認**，再動工。對應各 spec 第 9/11 章 checklist 的前幾步。

### A-2 🌍 未先展示視覺規範就實作
**症狀**：使用者看到成品才說「字太小 / 配色不對 / 留白太多」，整支重調。
**解法**：動工前先用一頁 demo 或 spec 的風格節，**把字級、配色、版面規範展示給使用者確認**。

### A-3 🌍 預設直接開工，未前置對齊
**症狀**：agent 收到「做影片」就埋頭做 10 分鐘才回報。
**解法**：照 AGENTS.md 5 階段，**每階段確認再前進**。寧可多問一句，不要做完才發現方向錯。

---

## B. 字幕（通則）

### B-1 🌍 字幕換行 / 過長
**症狀**：字幕折成兩三行、或一行塞太多字，觀眾讀不完、版面亂。
**解法**：**單行 ≤ 25 字，以不換行為最大原則**。太長就拆成兩個 beat 或精簡文案。這是所有片型的硬規則。

---

## C. HyperFrames / GSAP 動畫

> 若使用真正的 HyperFrames CLI（GSAP 引擎）才會遇到 C-1~C-5。
> 本 repo 範例用純 CSS/JS，不受影響，但用 HF CLI 的 agent 要注意。

### C-1 🔧 `class="clip"` + `data-duration` 提前隱藏元素
**症狀**：元素還沒演完就消失。
**解法**：`data-duration` 是該 clip 的存活時間，要 **≥ 內部動畫總長**。算清楚動畫 timeline 再設。

### C-2 🔧 `data-start` 必須對齊 GSAP 動畫開始時間
**症狀**：元素出現時機與動畫不同步。
**解法**：`data-start`（clip 進場時間）要和 GSAP timeline 的 `.from()/.to()` 起點一致，否則會早出或晚出。

### C-3 🔧 CSS `transform: translate()` 被 GSAP 覆蓋
**症狀**：你在 CSS 寫的位移失效。
**解法**：GSAP 會接管 `transform`。**位移交給 GSAP（`x/y` 屬性）**，不要 CSS 和 GSAP 同時設 transform。CSS 只留靜態樣式。

### C-4 🪟🔧 HyperFrames CLI init 在 Windows + Node 24 crash
**症狀**：`npx hyperframes init` 在 Node 24 報錯。
**解法**：降到 **Node 20 LTS**，或改用本 repo 的純 HTML 範本（不依賴 HF CLI）。

### C-5 🌍🔧 字型需要 `@font-face` 宣告
**症狀**：HTML 用了源石黑體，渲染卻是預設字體。
**解法**：HTML `<style>` 內必須有 `@font-face` 指向 `.otf`，**不能只靠系統安裝**（Playwright headless 不一定吃系統字）。範例已內建宣告，改字體路徑時別漏。

---

## D. GDrive / Node / Playwright

### D-1 🌍 `npm install` 在 GDrive 內極慢、易失敗
**症狀**：在雲端硬碟資料夾裝 node_modules，卡住或檔案損毀（`Invalid package config`）。
**解法**：**Playwright 與所有 node_modules 一律裝在 `%TEMP%/cvs-render/`**（非同步資料夾）。見 `install/setup_playwright.sh`。

### D-2 🔧 Playwright 需 `NODE_PATH` 指向非 GDrive 的 node_modules
**症狀**：錄製腳本 `require('playwright')` 找不到模組。
**解法**：在 `%TEMP%/cvs-render/` 內執行 `node record.cjs`，或設 `NODE_PATH=%TEMP%\cvs-render\node_modules`。範例 record 腳本預設就放那。

### D-3 🔧 開場「點擊播放」畫面殘留
**症狀**：錄出來的影片第一幀還停在 start-screen 遮罩。
**解法**：`page.click('#startScreen')` 後**多等 0.5–1s** 再開始計時錄製；並確認遮罩用 `display:none`（`.hidden`）徹底移除，不是只調 opacity。

---

## E. FFmpeg

### E-1 🌍 `afade` 的 `ss` vs `st` 搞錯
**症狀**：淡出時間點不對。
**解法**：淡出用 **`st`（start time，秒）**：`afade=t=out:st=45:d=5`（第 45 秒開始、淡 5 秒）。`ss` 是輸入 seek，不是淡出起點。

### E-2 🌍 Mux 時空白音訊流覆蓋（缺 `-map`）
**症狀**：影片有畫面但沒聲音，或聲音被 webm 的空音軌蓋掉。
**解法**：明確指定串流：
```bash
ffmpeg -y -i video.webm -i master_audio.mp3 \
  -map 0:v:0 -map 1:a:0 \
  -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest out.mp4
```

### E-3 🪟 concat demuxer 無法讀中文路徑
**症狀**：`ffmpeg -f concat -i concat.txt` 在中文路徑下報錯或找不到檔。
**解法**：
- `concat.txt` 內用**相對路徑**且在該目錄下執行；或
- 改用 filter_complex concat；或
- 先把分段 mp3 複製到純英文 temp 目錄再 concat。

---

## F. Windows / PowerShell / 編碼

### F-1 🪟 CP950 編碼導致 Python 崩潰
**症狀**：Python `print()` 或寫檔含中文時 `UnicodeEncodeError`。
**解法**：設環境變數 `PYTHONUTF8=1`（或 `PYTHONIOENCODING=utf-8`）；寫檔一律 `open(..., encoding="utf-8")`。範例 `setup.py` 寫檔已帶 `encoding="utf-8"`。

### F-2 🪟 `Copy-Item "中文路徑\*"` 靜默失敗
**症狀**：PowerShell 複製含中文路徑的萬用字元，沒報錯但沒複製到。
**解法**：用 `Get-ChildItem "中文路徑" | Copy-Item -Destination ...`，或改用 bash `cp`，或逐檔指定完整路徑。

### F-3 🪟 變數內嵌路徑冒號衝突
**症狀**：PowerShell `"$var:something"` 把 `:` 當 scope 修飾字，路徑爆掉（如 `C:` 後接變數）。
**解法**：用 `${var}` 明確界定：`"${drive}:\path"`；或用單引號 + 串接。

---

## G. Python

### G-1 🌍 `generate_narration.py` 相對路徑依賴 cwd
**症狀**：從別的目錄執行，音檔生到錯的地方或報找不到。
**解法**：腳本內用 `Path(__file__).parent` 定位輸出，**不要用相對 cwd 的路徑**。範例已這樣寫，自己改腳本時別退化成 `./assets/...`。

---

## 快速自檢（開工前 30 秒）

- [ ] 已先寫腳本給使用者確認？（A-1）
- [ ] 已展示視覺規範？（A-2）
- [ ] 字幕單行 ≤ 25 字、不換行？（B-1）
- [ ] Playwright 裝在 `%TEMP%` 不是 GDrive？（D-1）
- [ ] ffmpeg mux 有加 `-map 0:v:0 -map 1:a:0`？（E-2）
- [ ] ffmpeg 淡出用 `st` 不是 `ss`？（E-1）
- [ ] Windows 設了 `PYTHONUTF8=1`？（F-1）
- [ ] HTML 有 `@font-face` 宣告？（C-5）
- [ ] concat 在純英文路徑或相對路徑下執行？（E-3）
