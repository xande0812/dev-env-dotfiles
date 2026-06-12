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
- [.chezmoiignore](.chezmoiignore) に書いたパス（現状 `README.md`, `ghostty.terminfo`）はホームに配置されない。`ghostty.terminfo` は `run_onchange_after_05` が `{{ include "ghostty.terminfo" }}` で**生読み**して tic に流す素材（ホーム配置しない・テンプレート展開しない。`.chezmoitemplates/` 配下に置くと Go template が本文の `{{ }}` を誤 parse するため通常ファイル + ignore にしている）。
- [.chezmoiexternal.toml](.chezmoiexternal.toml) → **外部（3rd-party）成果物を取得して配置**する宣言。自分が書く dotfile はここに置かず `dot_*` で管理する。upstream がメンテするファイル（例: gpakosz/.tmux 本体）だけを置く。

## run_onchange のトリガー機構（重要）

`run_onchange_*` は「スクリプト本文が変わったとき」だけ走る。そのため対象 config の**ハッシュをコメント行に埋め込む**ことで、config 変更を本文変更に化けさせている。

- [run_onchange_after_05-ghostty-terminfo.sh.tmpl](run_onchange_after_05-ghostty-terminfo.sh.tmpl): `ghostty terminfo hash: {{ include "ghostty.terminfo" | sha256sum }}` → source 変更時に `tic -x` で `xterm-ghostty` を `~/.terminfo` にコンパイル（Ghostty から SSH した tmux の起動エラー / 表示崩れ対策。詳細は同 script のコメント参照）。mise 非依存なので最も早い `05`。
- [run_onchange_after_10-mise-install.sh.tmpl](run_onchange_after_10-mise-install.sh.tmpl): `mise config hash: {{ include "dot_config/mise/config.toml" | sha256sum }}` → mise config 変更時に `mise install`
- [run_onchange_after_20-sheldon-lock.sh.tmpl](run_onchange_after_20-sheldon-lock.sh.tmpl): plugins.toml のハッシュ → 変更時に `mise exec -- sheldon lock`

`include "..."` の対象パスを変えたり config をリネームした場合は、この hash 行も追従させること。sheldon は mise 管理なので必ず `mise exec` 経由で呼ぶ（10 → 20 の順序が前提）。

## バージョン pin の運用

このリポは「環境の lock ファイル」として機能する。bump は手動・レビュー前提。

- ツール: [dot_config/mise/config.toml](dot_config/mise/config.toml) で **version 固定**。`not_found_auto_install = false` / `experimental = false` で暗黙の取得・実験機能を切っている。short name 解決できないものは backend 明示（`github:k1LoW/git-wt`, `aqua:rossmacarthur/sheldon`）。
- zsh プラグイン: [dot_config/sheldon/plugins.toml](dot_config/sheldon/plugins.toml) で **commit hash (`rev`) 固定**（mutable な tag は使わない）。
- 外部成果物: [.chezmoiexternal.toml](.chezmoiexternal.toml) で **commit SHA を URL に埋めて固定 + `checksum.sha256` を必須**（flake.lock の rev + narHash 相当）。bump は SHA と sha256 を同時更新し upstream diff をレビュー。現状 gpakosz/.tmux の `.tmux.conf`（rev `af33f07`）と samber/cc-skills-golang の skill 群（rev `2e24bfb`）。
- AI agent skill: [.chezmoiexternal.toml](.chezmoiexternal.toml) で samber/cc-skills-golang を `type="archive"` + **commit SHA pin + sha256** で取得し、`~/.claude/skills` と `~/.codex/skills` の **2 か所へ同一 archive を展開**（claude/codex は同一 SKILL.md 形式・別ディレクトリ。DL は URL 単位で cache されるので fetch は 1 回）。skill は agent の context に load される指示文なので prompt-injection 面でもあり、外部成果物と同じ pin + diff レビュー規律で扱う。`type="git-repo"` は apply 時に `git clone` を走らせ「git network は手動」原則と衝突するので使わない（archive は chezmoi 内蔵 HTTP が squid 経由で取得）。`stripComponents=2` + `include=["*/skills/**"]` で skills サブツリーだけを各 `skills/` 直下へ展開し、`exact` は付けない（自作 skill を巻き込み削除しないため）。取得先 `codeload.github.com` は squid allowlist への追加が必要。bump は SHA と sha256 を同時更新し upstream diff をレビュー。
- AI agent CLI: [dot_config/mise/config.toml](dot_config/mise/config.toml) で claude（`aqua:anthropics/claude-code`）/ codex（`aqua:openai/codex`）/ rtk（`aqua:rtk-ai/rtk`）を **version 固定 + aqua backend 明示**（公式 release の checksum 検証経路を担保）。rtk は短縮名が aqua に解決でき PATH 上で reachingforthejack/rtk と名前衝突しうるため backend を明示固定する。bump は version を上げ upstream release を確認してから apply。
- Neovim plugin: [dot_config/nvim/lazy-lock.json](dot_config/nvim/lazy-lock.json) で **commit hash 固定**。lazy.nvim は実行時に GitHub からプラグインを取得し、nvim 起動時に sandbox 外のログインシェル文脈で評価する（sheldon / tmux-gpakosz / direnv .envrc と同種の信頼境界）。bump は `:Lazy update` を手動実行 → `chezmoi re-add ~/.config/nvim/lazy-lock.json` で source へ取り込み → diff レビュー → commit（自動追従させない）。`lua/plugins/*.lua` に `curl | sh` 相当や秘密値を書かない。
- ghostty terminfo: `ghostty.terminfo`（`.chezmoiignore` 済・ホーム非配置）に **local Ghostty の `infocmp -x xterm-ghostty` 出力を埋め込み**（dev-server 側には xterm-ghostty terminfo が無いのを補う / GitHub pin は WebFetch allowlist 外で checksum 経路が無いため local 出力を正とする）。bump は Ghostty 更新時に local で `infocmp -x xterm-ghostty` を取り直し source を差し替え → `chezmoi diff` → apply（自動追従させない）。

## AI agent の設定（bwrap sandbox 連携）

claude / codex は別 ansible playbook（`dev-env-playbook` の `bwrap_wrappers`）が配置する bwrap wrapper（`claude-sandboxed` / `codex-sandboxed` 等）経由で起動する。このリポはその **設定ファイルと version pin** だけを持つ。

- [dot_claude/settings.json](dot_claude/settings.json): 権限（secret path / curl 等 / git network の deny、WebFetch は domain allowlist のみ）。**`WebFetch(domain:...)` を増減するときは egress proxy（squid）の allowlist も同じ変更で更新する**（`dev-env-playbook` の `roles/squid/files/allowlist.txt`）。片方だけ変えても効かない。
- [dot_claude/CLAUDE.md](dot_claude/CLAUDE.md) / [dot_codex/AGENTS.md](dot_codex/AGENTS.md): user-global rule（外部情報を信頼しない・secret に触れない・git network は手動）。`dot_claude/CLAUDE.md` 末尾の `@RTK.md` は [dot_claude/RTK.md](dot_claude/RTK.md)（rtk のコマンド早見表）を import する。RTK.md は session の context に load される指示文なので、skill 同様 pin + diff レビュー規律で扱う（rtk の version bump 時に `rtk init` 等で再生成されたら `chezmoi re-add ~/.claude/RTK.md` で source へ取り込みレビュー）。
- [dot_claude/settings.json](dot_claude/settings.json) の `hooks.PreToolUse(Bash)` で `rtk hook claude` を実行する。rtk が全 Bash コマンドを `rtk ...`（token 圧縮 proxy）へ書き換える経路で、agent の挙動に効く信頼境界面。コマンド書き換え hook なので deny ルール（curl/git network 等）との整合を bump 時に確認する。
- codex の `config.toml` は**置かない**（codex 自身が所有する writable な config に project trust を runtime 永続化させるため。hardening は wrapper の `-c` フラグで強制）。
- CLI バイナリは mise が `$HOME` 配下に install する。wrapper は `mise which` で実体パスを解決し、sandbox の `--tmpfs /home` 下でも `~/.local/share/mise` の ro-bind 経由で到達させる。
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
