---
description: 指定内容を Obsidian vault (~/obvault/AI) に Markdown ノートとして記録/更新する
argument-hint: [記録したい内容の指示]
allowed-tools: Write, Read, Edit, Bash(ls:*), Bash(date:*), Bash(pwd:*), Bash(echo:*)
---
ユーザーの指示: $ARGUMENTS

記録元の情報（frontmatter にそのまま転記する。空なら自分で `pwd` / `echo "$CLAUDE_CODE_SESSION_ID"` を実行して取得する）:
- 記録元フルパス: !`pwd`
- セッションID: !`echo "$CLAUDE_CODE_SESSION_ID"`

上記に従い `~/obvault/AI/` 配下に Obsidian 用 Markdown ノートを作成（既存があれば更新）してください。

規約:
- 保存先は必ず `~/obvault/AI/` 配下。`~/obvault/` 直下（個人ノート）には書かない・読まない前提。
- ファイル名は `YYYY-MM-DD-<内容の英小文字 kebab スラッグ>.md`。日付は `date +%Y-%m-%d`。
- 同主題の既存ノートがあれば新規作成せず追記/更新する（先に `ls ~/obvault/AI/` で確認）。
- 冒頭に YAML frontmatter:
    ---
    date: <YYYY-MM-DD>
    source: claude-code
    source_path: <記録元フルパス（上記 pwd の値）>
    session_id: <セッションID（上記 CLAUDE_CODE_SESSION_ID の値）>
    tags: [ai-note]
    ---
  - 既存ノートを更新する場合で `source_path` / `session_id` が無ければ追記する（既存値は消さない）。
- 本文は後で読んで分かる粒度で簡潔に。コマンド例はコードブロックで。
- 機密値（API キー・トークン・鍵・.env の値）は書かない。
- 完了後、作成/更新したファイルの絶対パスを報告する。
