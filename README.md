# dev-env-dotfiles

Ubuntu 開発サーバ用の dotfiles を [chezmoi](https://www.chezmoi.io/) で管理する **公開** リポジトリ。シェル（zsh + starship + sheldon）/ git / mise（開発ツールの版管理）などを宣言的に配置する。

このリポは公開。**秘密値（API キー・鍵・トークン）は一切置かない**。

## 適用

```bash
# chezmoi 導入済みなら
chezmoi init --apply https://github.com/xande0812/dev-env-dotfiles.git

# 更新
chezmoi update
```

ホストのプロビジョニング（OS 設定・ツール binary 導入・chezmoi 起動）は別の playbook が担い、そこから上記が自動実行される。

## 構成

| source | 配置先 | 役割 |
|---|---|---|
| [dot_zshrc](dot_zshrc) | `~/.zshrc` | zsh 本体設定（mise activate / sheldon / starship / eza / git-wt / ghq）|
| [dot_config/sheldon/plugins.toml](dot_config/sheldon/plugins.toml) | `~/.config/sheldon/plugins.toml` | zsh プラグイン（rev pin）|
| [dot_config/git/config.tmpl](dot_config/git/config.tmpl) | `~/.config/git/config` | git 設定（SSH 署名 / ghq.root）|
| [dot_config/mise/config.toml](dot_config/mise/config.toml) | `~/.config/mise/config.toml` | mise グローバルツール（版 pin）|
| [dot_config/tmux/tmux.conf.local](dot_config/tmux/tmux.conf.local) | `~/.config/tmux/tmux.conf.local` | tmux カスタマイズ（gpakosz/.tmux の上書き）|
| [.chezmoiexternal.toml](.chezmoiexternal.toml) | `~/.config/tmux/tmux.conf` | gpakosz/.tmux 本体を commit pin + sha256 で取得 |
| `run_onchange_after_10-mise-install.sh.tmpl` | — | mise config 変更時に `mise install` |
| `run_onchange_after_20-sheldon-lock.sh.tmpl` | — | plugins 変更時に `sheldon lock` |

tmux バイナリ本体は dotfiles ではなく ansible（apt）が導入する。本リポは設定だけを持つ。

`run_onchange_*` は chezmoi が対象設定の変更を検知したときだけ実行する。
