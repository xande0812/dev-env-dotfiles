---
description: 指定内容を Obsidian vault (~/obvault/AI) に Markdown ノートとして記録/更新する
argument-hint: [記録したい内容の指示]
allowed-tools: Write, Read, Edit, Bash(ls:*), Bash(date:*)
---
ユーザーの指示: $ARGUMENTS

上記に従い `~/obvault/AI/` 配下に Obsidian 用 Markdown ノートを作成（既存があれば更新）してください。

規約:
- 保存先は必ず `~/obvault/AI/` 配下。`~/obvault/` 直下（個人ノート）には書かない・読まない前提。
- ファイル名は `YYYY-MM-DD-<内容の英小文字 kebab スラッグ>.md`。日付は `date +%Y-%m-%d`。
- 同主題の既存ノートがあれば新規作成せず追記/更新する（先に `ls ~/obvault/AI/` で確認）。
- 冒頭に YAML frontmatter:
    ---
    date: <YYYY-MM-DD>
    source: claude-code
    tags: [ai-note]
    ---
- 本文は後で読んで分かる粒度で簡潔に。コマンド例はコードブロックで。
- 機密値（API キー・トークン・鍵・.env の値）は書かない。
- 完了後、作成/更新したファイルの絶対パスを報告する。
