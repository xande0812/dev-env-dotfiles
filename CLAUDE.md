# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの役割

Ubuntu 開発サーバ用の dotfiles を [chezmoi](https://www.chezmoi.io/) で宣言的に管理する **公開** リポジトリ（[README.md](README.md) 参照）。シェル（zsh + starship + sheldon）/ git / mise（開発ツールの版管理）を配置する。

- **公開リポなので秘密値（API キー・鍵・トークン）は一切置かない。** SSH 署名鍵は[公開鍵](dot_config/git/config.tmpl)のみ。
- ホストのプロビジョニング（OS 設定・ツール binary 導入・chezmoi 起動）はこのリポではなく**別の ansible playbook** が担う（現ブランチ `migrate/ansible` 周辺の作業）。このリポは「chezmoi が apply する中身」だけを持つ。

## chezmoi の命名規約（編集時の必須知識）

ソースファイル名がそのまま配置先と挙動を決める。ファイルを追加・リネームする際はこの規約に従う。

- `dot_zshrc` → `~/.zshrc`、`dot_config/...` → `~/.config/...`（`dot_` プレフィックスが `.` になる）
- `*.tmpl` → Go テンプレートとして展開してから配置（例 [dot_config/git/config.tmpl](dot_config/git/config.tmpl) は `{{ .chezmoi.homeDir }}` を展開）
- `run_onchange_after_NN-*.sh.tmpl` → **配置先を持たないスクリプト**。`after` は通常ファイル配置の後、`NN` は実行順、`onchange` はトリガー対象が変わったときだけ再実行。
- [.chezmoiignore](.chezmoiignore) に書いたパス（現状 `README.md`）はホームに配置されない。

## run_onchange のトリガー機構（重要）

`run_onchange_*` は「スクリプト本文が変わったとき」だけ走る。そのため対象 config の**ハッシュをコメント行に埋め込む**ことで、config 変更を本文変更に化けさせている。

- [run_onchange_after_10-mise-install.sh.tmpl](run_onchange_after_10-mise-install.sh.tmpl): `mise config hash: {{ include "dot_config/mise/config.toml" | sha256sum }}` → mise config 変更時に `mise install`
- [run_onchange_after_20-sheldon-lock.sh.tmpl](run_onchange_after_20-sheldon-lock.sh.tmpl): plugins.toml のハッシュ → 変更時に `mise exec -- sheldon lock`

`include "..."` の対象パスを変えたり config をリネームした場合は、この hash 行も追従させること。sheldon は mise 管理なので必ず `mise exec` 経由で呼ぶ（10 → 20 の順序が前提）。

## バージョン pin の運用

このリポは「環境の lock ファイル」として機能する。bump は手動・レビュー前提。

- ツール: [dot_config/mise/config.toml](dot_config/mise/config.toml) で **version 固定**。`not_found_auto_install = false` / `experimental = false` で暗黙の取得・実験機能を切っている。short name 解決できないものは backend 明示（`github:k1LoW/git-wt`, `aqua:rossmacarthur/sheldon`）。
- zsh プラグイン: [dot_config/sheldon/plugins.toml](dot_config/sheldon/plugins.toml) で **commit hash (`rev`) 固定**（mutable な tag は使わない）。
- bump 手順: version / rev を上げる → upstream の diff をレビュー → `chezmoi diff` で確認 → apply。

## ロード順序の制約（壊しやすい）

zsh の初期化は順序依存。並べ替えると補完・widget が壊れる。

**[dot_zshrc](dot_zshrc)** の順序: `mise activate`（最初／他の eval より前）→ `sheldon source` → `git-wt --init`（compinit/fzf-tab の後）→ `zsh-autosuggestions`（fzf-tab の後・syntax-highlighting の前）→ `starship init` → **`zsh-syntax-highlighting`（必ず最後）**。

**[dot_config/sheldon/plugins.toml](dot_config/sheldon/plugins.toml)** の順序: `zsh-completions`（fpath に追加のみ）→ `compinit`（inline で呼び直し）→ `fzf-tab`。plugins は記載順に出力される。alias を作るプラグインは入れない（.zshrc の alias と衝突するため）。

## よく使うコマンド

このリポを編集 → 実機に反映する流れ。**編集は必ず source 側**（`dot_*` ファイル）で行い、`~/.zshrc` 等の配置済みファイルを直接編集しない。

- `chezmoi diff` — source の変更が配置先にどう反映されるかをプレビュー（apply 前に必ず確認）
- `chezmoi apply` — 配置を実行（変更があれば `run_onchange_*` も発火）
- `chezmoi update` — リモートを pull してから apply（README の運用）
- `chezmoi execute-template < dot_config/git/config.tmpl` — `.tmpl` の展開結果だけを確認
- `chezmoi cat ~/.zshrc` — 配置先にレンダリングされる最終内容を確認

このリポ単体には test / lint / build はない（dotfiles の宣言ファイル群のため）。動作確認は上記 chezmoi コマンドで行う。
