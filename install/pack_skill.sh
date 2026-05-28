#!/usr/bin/env bash
# 把當前的影片製作流程打包成 Claude Code Skill
# 用法：bash install/pack_skill.sh <skill-name> <video-type 01|02|03>
set -e

NAME="${1:-video-maker}"
TYPE="${2:-02}"

case "$TYPE" in
  01) TITLE="活動紀錄影片"; TRIGGER="做一支活動紀錄/婚禮/研習/比賽影片" ;;
  02) TITLE="教學影片";     TRIGGER="做一支教學影片/學科解釋影片" ;;
  03) TITLE="社群科普影片"; TRIGGER="做一支社群科普/IG/YouTube Shorts 短片" ;;
  *)  echo "Type 必須是 01 / 02 / 03"; exit 1 ;;
esac

# 決定 Claude skills 目錄
case "$(uname -s)" in
  MINGW*|CYGWIN*|MSYS*) SKILL_DIR="$HOME/.claude/skills/$NAME" ;;
  *)                    SKILL_DIR="$HOME/.claude/skills/$NAME" ;;
esac

mkdir -p "$SKILL_DIR"
REPO_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

cat > "$SKILL_DIR/SKILL.md" <<EOF
# $TITLE 生成技能（$NAME）

## 用途
依照 claude-video-specs 第 $TYPE 類規範製作 $TITLE。

## 觸發情境
使用者說：
- 「$TRIGGER」
- 「按照規範做一支 $TITLE」
- 「跑 $NAME 工作流」

## 工作流
1. 確認主題、片長、素材狀況
2. 讀規範：\`$REPO_ROOT/specs/$TYPE-*.md\`
3. fork 範本：\`cp -r $REPO_ROOT/examples/$TYPE-*/ <work-dir>/\`
4. 跑該 spec 第 9 章 checklist
5. Edge-TTS 生成旁白（序列）
6. 用 Playwright（在 %TEMP%/cvs-render/）錄製 webm
7. ffmpeg mux master_audio → mp4
8. 給使用者預覽 → 確認後存檔

## 規範路徑
\`$REPO_ROOT/specs/$TYPE-*.md\`

## 範本路徑
\`$REPO_ROOT/examples/$TYPE-*/\`

## 主要工具
- Edge-TTS（zh-TW-YunJheNeural）
- KaTeX（數學）
- Playwright + ffmpeg（渲染）
- 源石黑體（已透過 install/install_fonts.sh 安裝）

## 注意
- Playwright node_modules 必須在 %TEMP%，不能在 GDrive
- Edge-TTS 並行會被斷線，序列 + retry
- 字體引用相對路徑 \`../../assets/fonts/\`（依 fork 後位置調整）
EOF

echo "✓ Skill 已建立於：$SKILL_DIR"
echo "  觸發詞：「$TRIGGER」"
echo ""
echo "  下次只要在 Claude Code 說這句話，就會啟動本工作流。"
