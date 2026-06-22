#!/usr/bin/env bash
# Claude Code ステータスライン (Linux / dev-server 向け)
#
# 設計の元ネタ: https://zenn.dev/takna/articles/claude-code-statusline-design
#   - 区切りを 2 階層 (グループ内 ", " / グループ間 " | ") にして読みやすさを保つ
#   - think / fast は ON のときだけ出す (条件表示)
# 本スクリプトの差分:
#   - macOS 専用の `date -j` を除去し Linux の `date -d` に統一
#   - 料金は単価ハードコード計算ではなく公式値 .cost.total_cost_usd を使用
#   - 経過時間は transcript の「先頭行」ではなく timestamp を持つ最初の行から算出
#
# 入力: stdin に Claude Code がセッション状態の JSON を流す
# 出力: 1 行のステータス文字列
#
# 表示例:
#   3m12s | in:114.5k/out:1.7k $2.02 | ctx:11% | Opus 4.8 (1M), high, think | ~/ghq/.../dev-env | main | sid:97f7c684-...

input=$(cat)

# --- モデル名 (" context)" → ")" に短縮) ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
model="${model/ context)/)}"

# --- reasoning effort / thinking / fast_mode (1 回の jq でまとめて取得) ---
# 1 行 1 値で出力し行単位で read する (@tsv だと空フィールド先頭で値がずれる罠を回避)
{ read -r effort; read -r thinking; read -r fast_mode; } < <(
  printf '%s' "$input" | jq -r '.effort.level // "", (.thinking.enabled // false | tostring), (.fast_mode // false | tostring)'
)

# --- セッション ID (横断参照・ログ特定用にフル表示) ---
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')

# --- カレントディレクトリ (HOME を ~ に短縮) ---
# 注: ${cwd/#$HOME/~} は bash のバージョン/モードによっては置換文字列 "~" が
#     チルダ展開されて $HOME に化け短縮が効かないため case + 接頭辞除去で確実に行う
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
cwd_short="$cwd"
if [ -n "$cwd" ] && [ -n "$HOME" ]; then
  case "$cwd" in
    "$HOME")   cwd_short="~" ;;
    "$HOME"/*) cwd_short="~${cwd#"$HOME"}" ;;
  esac
fi

# --- git ブランチ ---
# 注: commit.gpgsign=true + gpg.format=ssh(1Password SSH agent)環境では git プロセスの
#     起動が 1Password 認証を誘発しうる。statusLine は数百ms毎に走るため、git コマンドを
#     一切使わず .git/HEAD を直接読んでブランチ名を得る(認証を発生させない)。
branch=""
if [ -n "$cwd" ]; then
  d="$cwd"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    gitloc="$d/.git"
    headfile=""
    if [ -d "$gitloc" ]; then
      headfile="$gitloc/HEAD"
    elif [ -f "$gitloc" ]; then
      # worktree/submodule: ".git" は "gitdir: <path>" を指すファイル
      gd=$(sed -n 's/^gitdir: //p' "$gitloc" 2>/dev/null)
      case "$gd" in
        /*) headfile="$gd/HEAD" ;;
        ?*) headfile="$d/$gd/HEAD" ;;
      esac
    fi
    if [ -n "$headfile" ]; then
      # "ref: refs/heads/<branch>" ならブランチ名、detached HEAD(生SHA)なら空
      [ -f "$headfile" ] && branch=$(sed -n 's@^ref: refs/heads/@@p' "$headfile" 2>/dev/null)
      break
    fi
    d="${d%/*}"
  done
fi

# --- セッション経過時間 (transcript で timestamp を持つ最初の行から算出) ---
elapsed=""
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  first_ts=$(jq -r 'select(.timestamp != null) | .timestamp' "$transcript" 2>/dev/null | head -n1)
  if [ -n "$first_ts" ]; then
    start_epoch=$(date -d "$first_ts" "+%s" 2>/dev/null)
    if [ -n "$start_epoch" ]; then
      now_epoch=$(date "+%s")
      diff_sec=$(( now_epoch - start_epoch ))
      [ "$diff_sec" -lt 0 ] && diff_sec=0
      h=$(( diff_sec / 3600 )); m=$(( (diff_sec % 3600) / 60 )); s=$(( diff_sec % 60 ))
      if [ "$h" -gt 0 ]; then elapsed=$(printf '%dh%02dm' "$h" "$m")
      else elapsed=$(printf '%dm%02ds' "$m" "$s"); fi
    fi
  fi
fi

# --- トークン数 (累計, 1000 単位で k 表記) ---
total_in=$(printf '%s'  "$input" | jq -r '.context_window.total_input_tokens  // 0')
total_out=$(printf '%s' "$input" | jq -r '.context_window.total_output_tokens // 0')

fmt_tokens() {
  local n="$1"
  if [ "$n" -ge 1000 ] 2>/dev/null; then
    printf '%s' "$n" | awk '{printf "%.1fk", $1/1000}'
  else
    printf '%s' "$n"
  fi
}
tok_in=$(fmt_tokens "$total_in")
tok_out=$(fmt_tokens "$total_out")

# --- 料金 (公式値。0.01 ドル未満は <$0.01 表示で序盤の $0.00 連発を避ける) ---
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0' | awk '{
  c = $1
  if (c > 0 && c < 0.01) { printf "<$0.01" }
  else { printf "$%.2f", c }
}')

# --- コンテキスト使用率 (used_percentage は messages が無いと null) ---
ctx_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
ctx_str=""
[ -n "$ctx_pct" ] && ctx_str=$(printf 'ctx:%.0f%%' "$ctx_pct")

# --- 組み立て ---
# 配列を区切り文字で連結するヘルパー (join_by SEP ELEM...)
join_by() {
  local sep="$1"; shift
  local out="" x
  for x in "$@"; do
    if [ -z "$out" ]; then out="$x"; else out="${out}${sep}${x}"; fi
  done
  printf '%s' "$out"
}

parts=()
[ -n "$elapsed" ] && parts+=("$elapsed")
parts+=("in:${tok_in}/out:${tok_out} ${cost}")
[ -n "$ctx_str" ] && parts+=("$ctx_str")

# モデル / effort / think / fast を ", " 区切りで 1 グループに
mgroup=()
[ -n "$model" ]      && mgroup+=("$model")
[ -n "$effort" ]     && mgroup+=("$effort")
[ "$thinking" = "true" ] && mgroup+=("think")
[ "$fast_mode" = "true" ] && mgroup+=("fast")
[ "${#mgroup[@]}" -gt 0 ] && parts+=("$(join_by ", " "${mgroup[@]}")")

[ -n "$cwd_short" ]  && parts+=("$cwd_short")
[ -n "$branch" ]     && parts+=("$branch")
[ -n "$session_id" ] && parts+=("sid:$session_id")

join_by " | " "${parts[@]}"
echo
